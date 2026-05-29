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
import std.sync.AtomicBool
import std.sync.Mutex
import std.sync.Condition
import stdx.encoding.url.URL

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
    var socket: ?ObseredSocket = None
    var requestBody: Option<RequestBody> = Option.None
    var requestBodyCompressType: Option<CompressType> = Option.None
    var acceptCompressTypes: Array<CompressType> = []
    var closed: AtomicBool = AtomicBool(false)
    var future: Option<Future<Unit>> = Option.None
    let mutex = Mutex()
    let condition: Condition

    public init(url: String) {
        var urlObj = URL.parse(url)
        let realUrl = if (urlObj.scheme == "https" && urlObj.port.isEmpty()) {
            urlObj.replace(port: "443")
            urlObj.toString()
        } else {
            url
        }
        let TcpSocketConnector = {
            sa: SocketAddress =>
                var tcpSocket = TcpSocket(sa)
                tcpSocket.noDelay = true
                var socket = ObseredSocket(tcpSocket)
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
            tlsConfig.alpnProtocolsList = ["h2"]
//            tlsConfig.keylogCallback = { socket, key =>
//                log("key log: ${key}")
//            }
            clientBuilder.tlsConfig(tlsConfig)
        }
        this.client = clientBuilder.build()
        this.url = realUrl
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
        if (!headers.get("accept").iterator().any { value => value == "text/event-stream" }) {
            headers.add("accept", "text/event-stream")
        }
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
        let isEventStream = rsp.headers.iterator().any({
            head => head[0].toAsciiLower() == "content-type" &&
                head[1].iterator().at(0).getOrThrow().toAsciiLower().startsWith("text/event-stream")
        })
        if (!isEventStream) {
            let exception = Exception("Server response error: status is ${rsp.status}!\n${rsp.toString()}")
            let data = readStreamToEnd(rsp.body)
            log(exception.message)
            this.exceptionHandler(exception, data)
        }
        return isEventStream
    }

    private func getResponseCompressType(headers: HttpHeaders): Option<CompressType> {
        return if (headers.iterator().any({
            head => head[0].toAsciiLower() == "content-encoding" &&
                    head[1].iterator().any({v => v.toAsciiLower() == "gzip"})
        })) {
            Gzip
        } else if (headers.iterator().any({
            head => head[0].toAsciiLower() == "content-encoding" &&
                    head[1].iterator().any({v => v.toAsciiLower() == "br"})
        })) {
            Brotli
        } else {
            None
        }
    }

    private func headersToJsonString(headers: HttpHeaders): String {
        var json = "{"
        let iter = headers.iterator()
        var first = true
        var next = iter.next()
        while (next.isSome()) {
            let item = next.getOrThrow()
            let name = item[0]
            let values = item[1].iterator() |> collectString(delimiter: ",")
            if (!first) {
                json += ","
            } else {
                first = false
            }
            json += "\"${name}\":\"${values}\""
            next = iter.next()
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
            for (byte in buffer[0..len]) {
                data.add(byte)
            }
        }
        return data.toArray()
    }

    private func handleMessage(messageHolder: ArrayList<UInt8>): Unit {
        try {
            let msg = messageHolder.toArray()
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
            this.exceptionHandler(e, messageHolder.toArray())
        } finally {
            messageHolder.clear()
        }
    }

    private func processByte(byte: UInt8, messageHolder: ArrayList<UInt8>): Unit {
        if (byte != NEXT_LINE_FLAG) {
            messageHolder.add(byte)
            return
        }

        let lastByte = messageHolder.get(messageHolder.size - 1)
        if (lastByte.isNone() || lastByte != NEXT_LINE_FLAG) {
            messageHolder.add(byte)
            return
        }

        // Complete message cached
        messageHolder.add(byte)
        handleMessage(messageHolder)
        return
    }

    private func handleCompressResponse(rsp: HttpResponse, compressType: CompressType): Int {
        // Process response stream
        let stream = rsp.body
        let messageHolder = ArrayList<UInt8>()
        // Buffer the entire response for decompression
        let compressBuffer = readStreamToEnd(stream)

        // Decompress data
        let decompressed = match (compressType) {
            case Gzip => GzipUtil.decompress(compressBuffer)
            case Brotli => BrotliUtil.decompress(compressBuffer)
        }

        // Process decompressed data
        for (byte in decompressed) {
            processByte(byte, messageHolder)
        }
        return 0
    }

    private func handleNoCompressResponse(rsp: HttpResponse): Int {
        // Normal non-GZIP streaming processing
        let stream = rsp.body
        let messageHolder = ArrayList<UInt8>()
        let buffer = Array<UInt8>(DEFAULT_BUFFER_SIZE, {_ => 0})
        while (true) {
            var len = stream.read(buffer)
            if (len == 0) {
                return 0 // Chunked stream ended, connection closed
            }
            for (byte in buffer[0..len]) {
                processByte(byte, messageHolder)
            }
        }
        return -1
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

        // Process response stream
        // let stream = rsp.body
        let messageHolder = ArrayList<UInt8>()
        // let buffer = Array<UInt8>(DEFAULT_BUFFER_SIZE, {_ => 0})

        // For compressed response, we need to buffer and decompress
        // Note: SSE streams are typically not compressed due to streaming nature
        // This implementation handles both cases
        return if (let Some(compressType) <- getResponseCompressType(rsp.headers)) {
            handleCompressResponse(rsp, compressType)
        } else {
            handleNoCompressResponse(rsp)
        }
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

public class ObseredSocket <: StreamingSocket {
    public let socket_string_read = StringBuilder()
    public let socket_string_write = StringBuilder()

    ObseredSocket(let socket: TcpSocket) {
        socket_string_read.reset()
        socket_string_write.reset()
    }
    public prop localAddress: SocketAddress {
        get() {
            return socket.localAddress
        }
    }
    public prop remoteAddress: SocketAddress {
        get() {
            return socket.remoteAddress
        }
    }
    public mut prop readTimeout: ?Duration {
        get() {
            return socket.readTimeout
        }
        set(value) {
            socket.readTimeout = value
        }
    }
    public mut prop writeTimeout: ?Duration {
        get() {
            return socket.writeTimeout
        }
        set(value) {
            socket.writeTimeout = value
        }
    }

    public func read(buffer: Array<UInt8>): Int64 {
        let len = socket.read(buffer)
        if (String.checkUtf8Encoding(buffer)) {
            socket_string_read.append(
                "${String.fromUtf8(buffer[..len]).replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")}")
        }
        return len
    }
    public func write(buffer: Array<UInt8>): Unit {
        if (String.checkUtf8Encoding(buffer)) {
            socket_string_write.append(
                "${String.fromUtf8(buffer).replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")}")
        }
        return socket.write(buffer)
    }
    public func close(): Unit {
        socket.close()
    }
    public func isClosed(): Bool {
        return socket.isClosed()
    }
    public func toString(): String {
        return socket.toString()
    }
    public func connect(): Unit {
        socket.connect()
    }
}
