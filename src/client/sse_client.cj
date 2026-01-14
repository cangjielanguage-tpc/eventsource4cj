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

public class EventSource {
    let client: Client
    let url: String
    let bufferSize: Int64
    let handlers = HashMap<String, (Message) -> Unit>()
    var retryInMills: UInt16 = 30_000
    var lastMessageId: Option<String> = Option.None
    var defaultMessageHandler = {_: Message =>}
    var exceptionHandler = {e: Exception, _: Array<UInt8> => e.printStackTrace()}

    public init(url: String) {
        let client = ClientBuilder().readTimeout(365 * 100 * Duration.day).build()
        this.client = client
        this.url = url
        this.bufferSize = 1024 * 8
    }

    public init(url: String, bufferSize: Int64) {
        let client = ClientBuilder().readTimeout(365 * 100 * Duration.day).build()
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
