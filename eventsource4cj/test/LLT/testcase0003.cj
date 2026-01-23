// EXEC: cjc %import-path %L %l %f 
// EXEC: pwsh -command "cp ../../../target/release/eventsource4cj/*.dll ."
// EXEC: pwsh -command "cp $Env:CANGJIE_STDX_PATH/windows_x86_64_llvm/dynamic/stdx/*.dll ."
// EXEC: ./main

package eventsource4cj.test

import eventsource4cj.server.*
import eventsource4cj.model.*
import eventsource4cj.model.*
import std.collection.*
import stdx.net.http.*
import std.net.*

public class EventSource {
    let client: Client
    let url: String
    let bufferSize: Int64
    let handlers = HashMap<String, (Message) -> Unit>()
    var retryInMills: UInt16 = 30_000
    var lastMessageId: Option<String> = Option.None
    var defaultMessageHandler = {_: Message =>}
    var exceptionHandler = {e: Exception, _: Array<UInt8> => e.printStackTrace()}
    var socket: ?ObseredSocket = None
    let TcpSocketConnector = {
        sa: SocketAddress =>
            var tcpSocket = TcpSocket(sa)
            tcpSocket.noDelay = true
            var socket = ObseredSocket(tcpSocket)
            this.socket = socket
            println("重置了socket")
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
                    ex.printStackTrace()
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

        let endpoint = url
        let req = HttpRequestBuilder().url(endpoint).addHeaders(headers).get().build()
        let rsp = client.send(req)
        let isEventStream = rsp.headers.iterator().any({
            head => head[0].toAsciiLower() == "content-type" && head[1].iterator().at(0).getOrThrow().toAsciiLower() ==
                "text/event-stream"
        })
        if (!isEventStream) {
            throw Exception("服务端响应类型错误:Content-Type不正确!")
        }

        // 处理响应流
        let nextLine = UInt8(b'\n')
        let stream = rsp.body
        let messageaHolder = ArrayList<UInt8>()
        let buffer = Array<UInt8>(bufferSize, {_ => 0})
        while (true) {
            var len = stream.read(buffer)
            if (len == 0) {
                return 0 // chuned流结束 连接关闭
            }
            // println("mdebug0:"+String.fromUtf8(buffer[0..len]).replace('\r', 'Ř').replace('\n', 'Ň').replace('\t', 'Ť').replace(' ', 'ø'))
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
                    // 已缓存了完整消息
                    messageaHolder.add(byte)
                    let msg = messageaHolder.toArray()
                    let message = MessageBuilder.resolve(msg)

                    // 消息指定了重试时间则按指定值设置
                    if (message.retryInMills.isSome()) {
                        this.retryInMills = message.retryInMills.getOrThrow()
                    }

                    // 调用消息处理函数
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
        // for (b in buffer[0..len]) {
        //     // print("${b}-${b.toString(radix: 16)}-${Rune(UInt32(b)).toString().replace("\n", "\\n")} ")
        //     print("${Rune(UInt32(b)).toString().replace("\n", "\\n")} ")
        // }
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


func sseClient(): Unit {
    // 创建消息源
    let eventsource = EventSource("http://127.0.0.1:9000/sse/range/10/1/100/2")

    // 设置消息处理函数
    eventsource.onMessage({msg => println("默认处理消息：${msg.toMessageString()}")})
    // eventsource.onEvent("test-event", {msg => println("处理消息：${msg.toMessageString()}")})

    try {
        // 开始订阅消息（异步操作）
        let future = eventsource.subscribe()
        future.get(Duration.second * 10)
    } catch (_: TimeoutException) {
    // ignore
    } finally {
        println(ObseredSocket.socket_string_read)
        println(ObseredSocket.socket_string_write)
    }
    // println(socket_string_write)
    // println(socket_string_read)
    // println(response_string)
}

main(): Unit {
    sseClient()
}
