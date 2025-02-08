/**
Copyright (c) 2025 hashli
eventsource4cj is licensed under Mulan PSL v2.
You can use this software according to the terms and conditions of the Mulan PSL v2. 
You may obtain a copy of Mulan PSL v2 at:
        http://license.coscl.org.cn/MulanPSL2 
THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.  
See the Mulan PSL v2 for more details.
*/
package eventsource4cj.server

import eventsource4cj.model.*
import net.http.*
import std.collection.*
import std.collection.concurrent.*
import std.random.*
import std.regex.*
import std.sync.*
import std.time.*
import std.unicode.UnicodeExtension


public class SseServer {
    let server: Server
    var future: Option<Future<Unit>>

    public init(address: String, port: UInt16) {
        this.server = ServerBuilder()
            .addr(address)
            .port(port)
            .build();
        this.future = Option.None
    }

    public init(server: Server) {
        this.server = server
        this.future = Option.None
    }

    public func getHttpServer(): Server {
        return this.server
    }

    public func serveForever() {
        let future = spawn {
            server.serve()
        }
        this.future = Option.Some(future)
        future.get()
    }

    public func terminate() {
        try {
            if (future.isSome()) {
                future.getOrThrow().cancel()
            }
        } finally {
            server.closeGracefully()
        }
    }

    public func publish(endpoint: String): SseEmitter {
        let emitter = SseEmitter.createIfAbsent(endpoint)

        server.distributor.register(endpoint, {context =>
            let broker = SseEmitterBroker(endpoint, SseEmitter.defaultMessageFilterByTag(context));
            emitter.register(broker)

            broker.serve(context)
        })

        return emitter;
    }
}

public class SseEmitter {
    private static let PARAMETER_MESSAGE_TAG = "sse-tag"

    private static let lock = ReentrantMutex()

    private static let emitterMap = ConcurrentHashMap<String, SseEmitter>(32)

    private let endpoint: String

    private let brokerMap = ConcurrentHashMap<String, SseEmitterBroker>(32)

    private init(endpoint: String) {
        let key = getKey(endpoint)
        this.endpoint = key
    }

    // private func getBroker(filter: (SseEmitterBroker) -> Bool): ArrayList<SseEmitterBroker> {
    //     let brokers = ArrayList<SseEmitterBroker>(0)
    //     //TODO iterator没有collect方法？
    //     let iter = brokerMap.iterator().filter({t=>filter(t[1])}).enumerate();
    //     for ((k, v) in brokerMap) {
    //         brokers.append(v)
    //     }

    //     return brokers;
    // }

    public func sendAll(message: Message) {
        //TODO 优化批量发送
        for ((k, v) in brokerMap) {
            v.send(message)
        }
    }

    public func sendByTag(message: Message) {
        //TODO 优化批量发送
        for ((k, v) in brokerMap) {
            v.sendWithFilter(message)
        }
    }

    public func sendByRequestParameter(message: Message, parameterName: String, parameterValue: String) {
        let filter = defaultBrokerFilterByRequestParameterValue(parameterName, parameterValue);
        send(message, filter)
    }

    public func send(message: Message, brokerFilter: (SseEmitterBroker) -> Bool) {
        //TODO 优化批量发送
        for ((k, v) in brokerMap) {
            if (brokerFilter(v)) {
                v.send(message)
            }
        }
    }

    public static func getEmitter(endpoint: String): Option<SseEmitter> {
        let key = getKey(endpoint)
        return emitterMap.get(key)
    }

    protected static func defaultBrokerFilterByRequestParameterValue(parameterName: String, parameterValue: String): (SseEmitterBroker) -> Bool {
        return {broker: SseEmitterBroker=>
            let val = broker.httpContext.request.form.get(parameterName);
            if (val.isNone()) {
                return false;
            } else {
                let pv = val.getOrDefault({=>""});
                return pv.trim() == parameterValue;
            }
        }
    }

    protected static func defaultMessageFilterByTag(httpContext: HttpContext): (message: Message) -> Bool {
        return {message: Message=>
            let val = httpContext.request.form.get(PARAMETER_MESSAGE_TAG);
            if (val.isNone()) {
                return true;
            } else {
                let pv = val.getOrDefault({=>""});
                return message.extention.messageTag.isNone() || pv.trim() == message.extention.messageTag.getOrThrow();
            }
        }
    }

    protected static func createIfAbsent(endpoint: String): SseEmitter {
        let key = getKey(endpoint)

        if (emitterMap.contains(key)) {
            return emitterMap.get(key).getOrThrow();
        } else {
            lock.lock()
            try {
                if (!emitterMap.contains(key)) {
                    let em = SseEmitter(endpoint);
                    emitterMap.put(key, em);
                }
                
                return emitterMap.get(key).getOrThrow();
            } finally {
                lock.unlock()
            }
        }
    }

    protected func register(emitter: SseEmitterBroker) {
        let key = getKey(emitter.endpoint)
        emitterMap.get(key).getOrThrow().brokerMap.put(emitter.sid, emitter)
    }

    protected static func deregister(emitter: SseEmitterBroker) {
        let key = getKey(emitter.endpoint)
        let value = emitterMap.get(key)
        if (value.isSome()) {
            value.getOrThrow().brokerMap.remove(emitter.sid)
        }
    }

    private static func getKey(endpoint: String): String {
        return Regex("[/]*$").matcher(endpoint).replace("");
    }
}

public class SseEmitterBroker {
    let sid: String

    let endpoint: String

    var context: Option<HttpContext>

    var response: Option<HttpResponseWriter>

    //TODO 优化队列空间、消息积压
    var queue = ArrayBlockingQueue(95536, Array<String>())

    var messageFilter = {message: Message=>true}

    public init(endpoint: String) {
        this.sid = "${DateTime.nowUTC().nanosecond}.${Random().nextInt8()}"
        this.endpoint = endpoint
        this.context = Option.None
        this.response = Option.None
    }

    public init(endpoint: String, messageFilter: (Message)->Bool) {
        this(endpoint)
        this.messageFilter = messageFilter
    }

    public prop httpContext: HttpContext {
        get() {
            return this.context.getOrThrow()
        }
    }

    protected func serve(context: HttpContext) {
        if (this.context.isSome()) {
            throw Exception("事件发送器已经绑定至连接，禁止重复绑定！")
        }
        this.context = Option.Some(context)
        this.response = Option.Some(HttpResponseWriter(context))

        // 开始发送事件
        //TODO 优化发送性能
        this.context.getOrThrow().responseBuilder
            .header("Transfer-encoding", "chunked")
            .header("Content-Type", "text/event-stream")
            .header("Cache-Control", "no-cache")
            .header("Connection", "keep-alive")
        while (true) {
            let msg = queue.dequeue();
            try {
                response.getOrThrow().write(msg.toArray())
            } catch (ex: Exception) {
                ex.printStackTrace()
                SseEmitter.deregister(this)
                break
            }
        }
    }

    protected func send(message: Message) {
        let msg = message.toMessageString();
        queue.enqueue(msg)
    }

    protected func sendWithFilter(message: Message) {
        if (this.messageFilter(message)) {
            send(message)
        }
    }
}