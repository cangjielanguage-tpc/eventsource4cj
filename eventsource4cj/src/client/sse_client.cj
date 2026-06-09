/**
Copyright (c) 2025 hashli
eventsource4cj is licensed under Mulan PSL v2.
You can use this software according to the terms and conditions of the Mulan PSL v2.
You may obtain a copy of Mulan PSL v2 at:
        http://license.coscl.org.cn/MulanPSL2
THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
See the Mulan PSL v2 for more details.
 */
package eventsource4cj.client

import eventsource4cj.model.*
import eventsource4cj.util.*
import std.collection.*
import stdx.net.http.*
import std.net.*
import std.io.InputStream
import stdx.net.tls.*
import stdx.compress.zlib.*
import std.sync.AtomicBool
import std.sync.Mutex
import std.sync.Condition
import stdx.encoding.url.URL
import brotli4cj.*
import stdx.net.tls.common.CertificateVerifyMode

public class EventSource {
    static const DEFAULT_BUFFER_SIZE = 1024 * 8
    static let NEXT_LINE_FLAG = UInt8(b'\n')
    static let DEFAULT_READ_TIMEOUT = Duration.day * 365 * 100
    let client: Client
    let url: String
    let handlers = HashMap<String, (Message) -> Unit>()
    let customHeaders = HashMap<String, String>()
    var retry: Duration = Duration.millisecond * 10000
    var lastMessageId: Option<String> = Option.None
    var messageHandler = {_: Message =>}
    var exceptionHandler = {e: Exception, _: Array<UInt8> => log(e)}
    var onOpenHandler = {_: String =>}
    var onOpenFired = false
    var socket: ?TcpSocket = None
    var requestBody: Option<RequestBody> = Option.None
    var requestBodyCompressType: Option<CompressType> = Option.None
    var acceptCompressTypes: Array<CompressType> = []
    var lastByteWasNewline: Bool = false
    var closed: AtomicBool = AtomicBool(false)
    var future: Option<Future<Unit>> = Option.None
    let mutex = Mutex()
    let condition: Condition

    public init(url: String) {
        var urlObj = URL.parse(url)
        this.url = if (urlObj.scheme == "https" && urlObj.port.isEmpty()) {
            urlObj.replace(port: "443")
            urlObj.toString()
        } else {
            url
        }
        let TcpSocketConnector = {
            sa: SocketAddress =>
                let socket = TcpSocket(sa)
                socket.noDelay = true
                this.socket = socket
                log("Socket connecting")
                socket.connect()
                log("Socket connected ${socket.toString()}")
                return socket
        }
        let clientBuilder = ClientBuilder().connector(TcpSocketConnector).readTimeout(DEFAULT_READ_TIMEOUT)
        if (url.startsWith("https://")) {
            var tlsConfig = TlsClientConfig()
            tlsConfig.verifyMode = CertificateVerifyMode.TrustAll
            tlsConfig.supportedAlpnProtocols = ["http/1.1", "h2"]
            clientBuilder.tlsConfig(tlsConfig)
        }
        this.client = clientBuilder.build()
        this.mutex.lock()
        this.condition = mutex.condition()
        this.mutex.unlock()
    }

    public func setBody(body: String): Unit {
        this.requestBody = StringBody(body)
    }

    public func setBody(body: Array<UInt8>): Unit {
        this.requestBody = StreamBody(body)
    }

    public func clearBody(): Unit {
        this.requestBody = Option.None
    }

    // 0: raw data, 1: gzip compressed data, 2: brotli compressed data
    public func setRequestCompressType(compress: Int64): Unit {
        if (compress == 1) {
            this.requestBodyCompressType = Gzip
        } else if (compress == 2) {
            this.requestBodyCompressType = Brotli
        } else {
            this.requestBodyCompressType = Option.None
        }
    }

    public func getRequestCompressType(): Int64 {
        return match (this.requestBodyCompressType) {
            case Some(compress) =>
                match (compress) {
                    case Gzip => 1
                    case Brotli => 2
                }
            case None => 0
        }
    }

    // 0: no "Accept-Encoding", 1: "Accept-Encoding: gzip", 2: "Accept-Encoding: br", 3: "Accept-Encoding: gzip, br"
    public func setAcceptCompressType(compress: Int64): Unit {
        if (compress == 1) {
            this.acceptCompressTypes = [Gzip]
        } else if (compress == 2) {
            this.acceptCompressTypes = [Brotli]
        } else if (compress == 3 ){
            this.acceptCompressTypes = [Gzip, Brotli]
        } else {
            this.acceptCompressTypes = []
        }
    }

    public func getAcceptCompressType(): Int64 {
        var compress = 0
        for (item in this.acceptCompressTypes) {
            compress += match (item) {
                case Gzip => 1
                case Brotli => 2
            }
        }
        return compress
    }

    public func setHeader(name: String, value: String): Unit {
        this.customHeaders.add(name, value)
    }

    public func setHeaders(headers: HashMap<String, String>): Unit {
        for ((name, value) in headers) {
            this.customHeaders.add(name, value)
        }
    }

    public func removeHeader(name: String): Unit {
        this.customHeaders.remove(name)
    }

    public func clearHeaders(): Unit {
        this.customHeaders.clear()
    }

    public func setExceptionHandler(handler: (Exception, Array<UInt8>) -> Unit): Unit {
        exceptionHandler = handler
    }

    public func onMessage(handler: (Message) -> Unit): Unit {
        this.messageHandler = handler
    }

    public func onEvent(event: String, handler: (Message) -> Unit): Unit {
        let listener = {
            message: Message => if (message.eventType.isSome() && event == message.eventType.getOrThrow()) {
                handler(message)
            }
        }
        handlers.add(event, listener)
    }

    public func onOpen(handler: (String) -> Unit): Unit {
        this.onOpenHandler = handler
    }

    public func subscribe(): Future<Unit> {
        if (closed.load()) {
            throw IllegalStateException("EventSource already closed")
        }
        this.future = spawn {
            while (!closed.load()) {
                var stat = -1
                try {
                    stat = connect(this.lastMessageId)
                    if (stat == 0) {
                        log("connection finish")
                        break
                    }
                } catch (ex: Exception) {
                    log(ex)
                    this.exceptionHandler(ex)
                } finally {
                    if (closed.load() || stat == 0) {
                        this.client.close()
                        log("connection closed")
                        break
                    } else {
                        log("connect retry after ${this.retry}")
                        this.onOpenFired = false
                        mutex.lock()
                        condition.wait(timeout: this.retry)
                        mutex.unlock()
                    }
                }
            }
        }
        return this.future.getOrThrow()
    }

    public func close(): Unit {
        closed.store(true)
        mutex.lock()
        condition.notifyAll()
        mutex.unlock()
        // Close the underlying socket to interrupt blocking stream.read()
        if (let Some(socket) <- this.socket) {
            socket.close()
        }
    }

    private func getHeaders(lastMessageId: Option<String>): HttpHeaders {
        let headers = HttpHeaders()
        headers.add("accept", "text/event-stream")

        if (lastMessageId.isSome()) {
            headers.add("Last-Event-ID", lastMessageId.getOrThrow())
        }

        // Build Accept-Encoding header based on enabled compression types
        let acceptEncodings = this.acceptCompressTypes.map { it => it.name }
        if (acceptEncodings.size > 0) {
            let encodingStr = acceptEncodings.iterator() |> collectString(delimiter: ", ")
            headers.add("Accept-Encoding", encodingStr)
        }

        // Add custom headers
        for ((name, value) in this.customHeaders) {
            headers.add(name, value)
        }

        if (this.requestBody.isSome() && let Some(compressType) <- this.requestBodyCompressType) {
            headers.add("Content-Encoding", compressType.name)
        }
        return headers
    }

    private func checkContentType(rsp: HttpResponse): Bool {
        if (let Some(ct) <- rsp.headers.getFirst("content-type")) {
            if (ct.toAsciiLower().startsWith("text/event-stream")) {
                return true
            }
        }
        let exception = IllegalArgumentException("Server response error: status is ${rsp.status}!\n${rsp.toString()}")
        let data = readStreamToEnd(rsp.body)
        log(exception.message)
        this.exceptionHandler(exception, data)
        return false
    }

    private func getResponseCompressType(headers: HttpHeaders): Option<CompressType> {
        let encodings = headers.get("content-encoding")
        if (encodings.iterator().any({v => v.toAsciiLower() == "gzip"})) {
            return Gzip
        }
        if (encodings.iterator().any({v => v.toAsciiLower() == "br"})) {
            return Brotli
        }
        return None
    }

    private func headersToJsonString(headers: HttpHeaders): String {
        var json = "{"
        var first = true
        for ((name, values) in headers) {
            let valuesJson = values.iterator() |> collectString(delimiter: ",")
            if (!first) {
                json += ","
            } else {
                first = false
            }
            json += "\"${name}\":\"${valuesJson}\""
        }
        json += "}"
        return json
    }

    private func readStreamToEnd(stream: InputStream): Array<UInt8> {
        let buffer = Array<UInt8>(DEFAULT_BUFFER_SIZE, {_ => 0})
        let data = ArrayList<UInt8>()
        while (true) {
            var len = stream.read(buffer)
            if (len == 0) {
                break
            }
            data.add(all: buffer[0..len])
        }
        return unsafe { data.getRawArray()[..data.size] }
    }

    private func handleMessage(messageHolder: ArrayList<UInt8>): Unit {
        // Zero-copy: use getRawArray slice instead of toArray (which creates a full copy)
        let msg = unsafe { messageHolder.getRawArray()[..messageHolder.size] }
        try {
            let message = MessageBuilder.resolve(msg)

            // Set retry time if specified in message
            if (let Some(retry) <- message.retryInMills) {
                this.retry = Duration.millisecond * Int64(retry)
            }

            // Call message handler
            if (let Some(eventType) <- message.eventType) {
                if (let Some(handler) <- this.handlers.get(eventType)) {
                    handler(message)
                } else {
                    this.messageHandler(message)
                }
            } else {
                this.messageHandler(message)
            }

            if (message.msgId.isSome()) {
                this.lastMessageId = message.msgId
            }
        } catch (e: Exception) {
            log(e)
            this.exceptionHandler(e, msg)
        } finally {
            messageHolder.clear()
        }
    }

    private func processBytes(bytes: Array<UInt8>, len: Int64, messageHolder: ArrayList<UInt8>): Unit {
        // Scan for newline positions to batch non-\n segments
        var segStart = 0
        for (i in 0..len) {
            let byte = bytes[i]
            if (byte == NEXT_LINE_FLAG) {
                // Append batch of non-\n bytes before this \n
                if (i > segStart) {
                    messageHolder.add(all: bytes[segStart..i])
                }
                // Add the \n byte first
                messageHolder.add(NEXT_LINE_FLAG)
                // Check if previous byte was also \n (double \n = message boundary)
                if (this.lastByteWasNewline) {
                    // Complete message: two consecutive \n
                    handleMessage(messageHolder)
                    // After handleMessage, holder is cleared, next \n is a new "first \n"
                    this.lastByteWasNewline = false
                } else {
                    // This is the first \n, mark it for next boundary check
                    this.lastByteWasNewline = true
                }
                segStart = i + 1
            } else {
                this.lastByteWasNewline = false
            }
        }
        // Append remaining non-\n bytes at end of chunk
        if (len > Int64(segStart)) {
            messageHolder.add(all: bytes[segStart..len])
            this.lastByteWasNewline = false
        }
    }

    private func handleCompressResponse(rsp: HttpResponse, compressType: CompressType): Unit {
        let messageHolder = ArrayList<UInt8>()
        this.lastByteWasNewline = false

        let decompressStream: InputStream = match (compressType) {
            case Gzip => DecompressInputStream(rsp.body, wrap: GzipFormat, bufLen: DEFAULT_BUFFER_SIZE)
            case Brotli => BrotliInputStream(rsp.body)
        }

        decompress(decompressStream, messageHolder)
    }

    private func decompress(decompressStream: InputStream, messageHolder: ArrayList<UInt8>): Unit {
        // Stream decompression: DecompressInputStream wraps the network stream directly,
        // producing decompressed output incrementally as compressed data arrives.
        let buffer = Array<UInt8>(DEFAULT_BUFFER_SIZE, {_ => 0})
        try {
            var len = decompressStream.read(buffer)
            while (len > 0) {
                processBytes(buffer, len, messageHolder)
                len = decompressStream.read(buffer)
            }
        } finally {
            if (let Some(resource) <- (decompressStream as Resource)) {
                resource.close()
            }
        }
    }

    private func handleNoCompressResponse(rsp: HttpResponse): Unit {
        // Normal non-GZIP streaming processing
        let stream = rsp.body
        let messageHolder = ArrayList<UInt8>()
        this.lastByteWasNewline = false
        let buffer = Array<UInt8>(DEFAULT_BUFFER_SIZE, {_ => 0})
        var len = stream.read(buffer)
        while (len > 0) {
            processBytes(buffer, len, messageHolder)
            len = stream.read(buffer)
        }
    }

    private func handleResponse(rsp: HttpResponse): Int {
        // Check content-type, if not "text/event-stream", don't handle response
        if (!checkContentType(rsp)) {
            return -1
        }

        // Fire onOpen callback only once on first successful SSE response
        if (!this.onOpenFired) {
            this.onOpenFired = true
            this.onOpenHandler(headersToJsonString(rsp.headers))
        }

        // For compressed response, we need to buffer and decompress
        // Note: SSE streams are typically not compressed due to streaming nature
        // This implementation handles both cases
        if (let Some(compressType) <- getResponseCompressType(rsp.headers)) {
            handleCompressResponse(rsp, compressType)
        } else {
            handleNoCompressResponse(rsp)
        }
        return 0
    }

    private func connect(lastMessageId: Option<String>): Int {
        let headers = getHeaders(lastMessageId)

        let requestBuilder: HttpRequestBuilder = if (let Some(body) <- this.requestBody) {
            // POST body
            var bodyBytes = match (body) {
                case StringBody(str) => str.toArray()
                case StreamBody(buf) => buf
            }
            if (let Some(compressType) <- this.requestBodyCompressType) {
                match (compressType) {
                    case Gzip => bodyBytes = GzipUtil.compress(bodyBytes)
                    case Brotli => bodyBytes = BrotliUtil.compress(bodyBytes)
                }
            }
            // POST request
            HttpRequestBuilder().url(this.url).addHeaders(headers).body(bodyBytes).post()
        } else {
            // GET request
            HttpRequestBuilder().url(this.url).addHeaders(headers).get()
        }

        let req: HttpRequest = if (this.url.startsWith("https://")) {
            requestBuilder.version(HTTP2_0).build()
//            requestBuilder.build()
        } else {
            requestBuilder.build()
        }
        log("send to url ${this.url}")
        log("send request ${req.toString()}")
        let rsp = client.send(req)

        return handleResponse(rsp)
    }
}
