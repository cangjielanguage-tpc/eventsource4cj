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
import std.collection.*
import stdx.net.http.*
import std.net.*
import ohos.hilog.Hilog

public class EventSource {
    let client: Client
    let url: String
    let bufferSize: Int64
    let handlers = HashMap<String, (Message) -> Unit>()
    let customHeaders = HashMap<String, String>()
    var retryInMills: UInt16 = 30_000
    var lastMessageId: Option<String> = Option.None
    var defaultMessageHandler = {_: Message =>}
    var exceptionHandler = {e: Exception, _: Array<UInt8> => log(e)}
    var socket: ?ObseredSocket = None
    var requestBody: Option<String> = Option.None
    var requestBodyBytes: Option<Array<UInt8>> = Option.None
    let TcpSocketConnector = {
        sa: SocketAddress =>
            var tcpSocket = TcpSocket(sa)
            tcpSocket.noDelay = true
            var socket = ObseredSocket(tcpSocket)
            this.socket = socket
            log("Socket reset")
            socket.connect()
            return socket
    }
    public init(url: String) {
        let client = ClientBuilder().connector(TcpSocketConnector).readTimeout(365 * 100 * Duration.day).build()
        this.client = client
        this.url = url
        this.bufferSize = 1024 * 8
    }

    public init(url: String, bufferSize: Int64) {
        let client = ClientBuilder().connector(TcpSocketConnector).readTimeout(365 * 100 * Duration.day).build()
        this.client = client
        this.url = url
        this.bufferSize = bufferSize
    }

    public init(url: String, body: String) {
        let client = ClientBuilder().connector(TcpSocketConnector).readTimeout(365 * 100 * Duration.day).build()
        this.client = client
        this.url = url
        this.bufferSize = 1024 * 8
        this.requestBody = Option.Some(body)
    }

    public init(url: String, body: String, bufferSize: Int64) {
        let client = ClientBuilder().connector(TcpSocketConnector).readTimeout(365 * 100 * Duration.day).build()
        this.client = client
        this.url = url
        this.bufferSize = bufferSize
        this.requestBody = Option.Some(body)
    }

    public init(url: String, body: Array<UInt8>) {
        let client = ClientBuilder().connector(TcpSocketConnector).readTimeout(365 * 100 * Duration.day).build()
        this.client = client
        this.url = url
        this.bufferSize = 1024 * 8
        this.requestBodyBytes = Option.Some(body)
    }

    public init(url: String, body: Array<UInt8>, bufferSize: Int64) {
        let client = ClientBuilder().connector(TcpSocketConnector).readTimeout(365 * 100 * Duration.day).build()
        this.client = client
        this.url = url
        this.bufferSize = bufferSize
        this.requestBodyBytes = Option.Some(body)
    }

    public func setBody(body: String): Unit {
        this.requestBody = Option.Some(body)
        this.requestBodyBytes = Option.None
    }

    public func setBody(body: Array<UInt8>): Unit {
        this.requestBodyBytes = Option.Some(body)
        this.requestBody = Option.None
    }

    public func clearBody(): Unit {
        this.requestBody = Option.None
        this.requestBodyBytes = Option.None
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
        this.defaultMessageHandler = handler
    }

    public func onEvent(event: String, handler: (Message) -> Unit): Unit {
        let listener = {
            message: Message => if (message.eventType.isSome() && event == message.eventType.getOrThrow()) {
                handler(message)
            }
        }
        handlers.add(event, listener)
    }

    public func subscribe(): Future<Unit> {
        return spawn {
            while (true) {
                try {
                    let stat = connect(this.lastMessageId)
                    if (stat == 0) {
                        return
                    }
                } catch (ex: Exception) {
                    log(ex)
                    sleep(Int64(retryInMills) * Duration.millisecond)
                }
            }
        }
    }

    private func connect(lastMessageId: Option<String>): Int {
        let headers = HttpHeaders()
        headers.add("Accept", "text/event-stream")
        if (lastMessageId.isSome()) {
            headers.add("Last-Event-ID", lastMessageId.getOrThrow())
        }
        // Add custom headers
        for ((name, value) in this.customHeaders) {
            headers.add(name, value)
        }

        let endpoint = url
        let req: HttpRequest
        if (this.requestBody.isSome()) {
            // POST request with String body
            let body = this.requestBody.getOrThrow()
            req = HttpRequestBuilder().url(endpoint).addHeaders(headers).body(body).post().build()
        } else if (this.requestBodyBytes.isSome()) {
            // POST request with Array<UInt8> body
            let body = this.requestBodyBytes.getOrThrow()
            req = HttpRequestBuilder().url(endpoint).addHeaders(headers).body(body).post().build()
        } else {
            // GET request
            req = HttpRequestBuilder().url(endpoint).addHeaders(headers).get().build()
        }
        let rsp = client.send(req)
        let isEventStream = rsp.headers.iterator().any({
            head => head[0].toAsciiLower() == "content-type" && head[1].iterator().at(0).getOrThrow().toAsciiLower() ==
                "text/event-stream"
        })
        if (!isEventStream) {
            let a = rsp.headers.iterator() |> map(
                {h: (String, Collection<String>) => "${h[0]}:${h[1] |> collectString(delimiter: ",")}"}) |>
                collectString(delimiter: "\n")
            throw Exception("Server response type error: Content-Type is incorrect! ${rsp.toString()}")
        }

        // Process response stream
        let nextLine = UInt8(b'\n')
        let stream = rsp.body
        let messageaHolder = ArrayList<UInt8>()
        let buffer = Array<UInt8>(bufferSize, {_ => 0})
        while (true) {
            var len = stream.read(buffer)
            if (len == 0) {
                return 0 // Chunked stream ended, connection closed
            }
//            log(
//                "mdebug0:${String.fromUtf8(buffer[0..len]).replace('\r', 'Ř').replace('\n', 'Ň').replace('\t', 'Ť').replace(' ', 'ø')}")
            for (byte in buffer[0..len]) {
                if (byte != nextLine) {
                    messageaHolder.add(byte)
                    continue
                }

                let lastByte = messageaHolder.get(messageaHolder.size - 1)

                if (lastByte.isNone() || lastByte != nextLine) {
                    messageaHolder.add(byte)
                    continue
                }

                try {
                    // Complete message cached
                    messageaHolder.add(byte)
                    let msg = messageaHolder.toArray()
                    let message = MessageBuilder.resolve(msg)

                    // Set retry time if specified in message
                    if (message.retryInMills.isSome()) {
                        this.retryInMills = message.retryInMills.getOrThrow()
                    }

                    // Call message handler
                    if (message.eventType.isNone()) {
                        this.defaultMessageHandler(message)
                    } else {
                        let event = message.eventType.getOrThrow()
                        let handler = this.handlers.get(event)
                        if (handler.isNone()) {
                            this.defaultMessageHandler(message)
                        } else {
                            handler.getOrThrow()(message)
                        }
                    }

                    if (message.msgId.isSome()) {
                        this.lastMessageId = message.msgId
                    }
                } catch (e: Exception) {
                    exceptionHandler(e, buffer)
                } finally {
                    messageaHolder.clear()
                }
            }
        }
        return -1
    }
}

public class ObseredSocket <: StreamingSocket {
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
    public static let socket_string_read = StringBuilder()
    public static let socket_string_write = StringBuilder()
    public func read(buffer: Array<UInt8>): Int64 {
        let len = socket.read(buffer)
        socket_string_read.append(
            "${String.fromUtf8(buffer[..len]).replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")}")
        return len
    }
    public func write(buffer: Array<UInt8>): Unit {
        socket_string_write.append(
            "${String.fromUtf8(buffer).replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")}")
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

var logid = 100

func log(s: ToString): Unit {    Hilog.warn(0, 'mdebug', "${s.toString()}")
    logid += 1
}

func log(s: Exception): Unit {
    Hilog.error(0, 'mdebug', "${getStackTrace(s)}")
    logid += 1
}

func getStackTrace(thrown: ?Exception): String {
    var res: String = ""
    match (thrown) {
        case None => return res
        case Some(v) =>
            res = "\n${v.toString()}\n"
            var arr = v.getStackTrace()
            for (line in arr) {
                res += "      at ${line.declaringClass}.${line.methodName}(${line.fileName}:${line.lineNumber})\n"
            }
            return res
    }
}
