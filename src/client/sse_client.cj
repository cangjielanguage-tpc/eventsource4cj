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

import net.http.*
import std.collection.*
import std.sync.*
import std.time.*

import eventsource4cj.model.*

public class EventSource {
    let client: Client
    let url: String
    var retryInMills : UInt16 = 30_000
    var lastMessageId: Option<String> = Option.None
    var defaultMessageHandler = {message: Message=>}
    let handlers = HashMap<String, (Message)->Unit>()

    public init(url: String) {
        let client = ClientBuilder().readTimeout(365 * 100 * Duration.day).build();
        this.client = client
        this.url = url
    }

    public func onMessage(handler: (Message)->Unit) {
        this.defaultMessageHandler = handler
    }

    public func onEvent(event: String, handler: (Message)->Unit) {
        let listener = {message: Message=>
            if (message.eventType.isSome() && event == message.eventType.getOrThrow()) {
                handler(message)
            }
        }
        handlers.put(event, listener)
    }

    public func subscribe(): Future<Unit> {
        return spawn {
            while (true) {
                try {
                    connect(this.lastMessageId)
                } catch (ex: Exception) {
                    ex.printStackTrace()
                    sleep(Int64(retryInMills) * Duration.millisecond)
                }
            }
        }
    }

    private func connect(lastMessageId: Option<String>) {
        let headers = HttpHeaders();
        headers.add("Accept", "text/event-stream")
        if (lastMessageId.isSome()) {
            headers.add("Last-Event-ID", lastMessageId.getOrThrow())
        }

        let endpoint = url
        let req = HttpRequestBuilder()
            .url(endpoint)
            .addHeaders(headers)
            .get()
            .build();
        let rsp = client.send(req)
        let isEventStream = rsp.headers.iterator()
            .any({head => head[0].toAsciiLower() == "content-type" && head[1].iterator().at(0) == "text/event-stream"})
        if (!isEventStream) {
            throw Exception("服务端响应类型错误:Content-Type不正确!")
        }

        // 处理响应流
        let nextLine = UInt8(b'\n')
        let stream = rsp.body
        let messageaHolder = ArrayList<UInt8>();
        let buffer = Array<UInt8>(512, {_=>0})
        while (true) {
            var len = stream.read(buffer);
            for (byte in buffer[0..len]) {
                if (byte != nextLine) {
                    messageaHolder.append(byte)
                    continue
                }

                let lastByte = messageaHolder.get(messageaHolder.size - 1)

                if (lastByte.isNone() || lastByte != nextLine) {
                    messageaHolder.append(byte)
                    continue
                }

                // 已缓存了完整消息
                messageaHolder.append(byte)
                let msg = messageaHolder.toArray();
                let message = MessageBuilder.resolve(msg);

                // 消息指定了重试时间则按指定值设置
                if (message.retryInMills.isSome()) {
                    this.retryInMills = message.retryInMills.getOrThrow()
                }
                
                // 调用消息处理函数
                try {
                    if (message.eventType.isNone()) {
                        this.defaultMessageHandler(message)
                    } else {
                        let event = message.eventType.getOrThrow()
                        let handler = this.handlers.get(event);
                        if (handler.isNone()) {
                            this.defaultMessageHandler(message)
                        } else {
                            handler.getOrThrow()(message)
                        }
                    }

                    if (message.msgId.isSome()) {
                        this.lastMessageId = message.msgId
                    }
                } catch(e: Exception) {
                    e.printStackTrace();
                } finally {
                    messageaHolder.clear()
                }
            }
        }
    }
}