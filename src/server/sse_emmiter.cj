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
        return publish(endpoint, {_=>true})
    }

    public func publish(endpoint: String, clientConnectedHandler: (SseEmitterBroker)->Bool): SseEmitter {
        let emitter = SseEmitter.createIfAbsent(endpoint)

        server.distributor.register(endpoint, {context =>
            let broker = SseEmitterBroker(endpoint, context)
            emitter.register(broker)
            let checked = clientConnectedHandler(broker)
            if (!checked) {
                throw Exception("服务端处理连接事件失败!")
            }
            broker.serve()
        })

        return emitter;
    }
}

public class SseEmitter {
    private static let REG_ENDPOINT_ID = Regex("[/]{2,}");

    private static let lock = ReentrantMutex()

    private static let emitterMap = ConcurrentHashMap<String, SseEmitter>(32)

    private let endpoint: String

    private let brokerMap = ConcurrentHashMap<String, SseEmitterBroker>(32)

    private init(endpoint: String) {
        let key = getEndpointId(endpoint)
        this.endpoint = key
    }

    public func sendAll(message: Message) {
        for ((k, v) in brokerMap) {
            v.send(message)
        }
    }

    public func send(message: Message, brokerFilter: (SseEmitterBroker) -> Bool) {
        for ((k, v) in brokerMap) {
            if (brokerFilter(v)) {
                v.send(message)
            }
        }
    }

    public static func getEmitter(endpoint: String): Option<SseEmitter> {
        let key = getEndpointId(endpoint)
        return emitterMap.get(key)
    }

    public static func defaultBrokerFilterByRequestParameterValue(parameterName: String, parameterValue: String): (SseEmitterBroker) -> Bool {
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

    protected static func createIfAbsent(endpoint: String): SseEmitter {
        let key = getEndpointId(endpoint)

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
        let key = getEndpointId(emitter.endpoint)
        emitterMap.get(key).getOrThrow().brokerMap.put(emitter.sid, emitter)
    }

    protected static func deregister(emitter: SseEmitterBroker) {
        let key = getEndpointId(emitter.endpoint)
        let value = emitterMap.get(key)
        if (value.isSome()) {
            value.getOrThrow().brokerMap.remove(emitter.sid)
        }
    }

    private static func getEndpointId(endpoint: String): String {
        return REG_ENDPOINT_ID.matcher("/" + endpoint).replace("/");
    }
}

public class SseEmitterBroker {
    let sid: String

    let endpoint: String

    var context: HttpContext

    var response: Option<HttpResponseWriter> = Option.None

    var queue = ArrayBlockingQueue(95536, Array<String>())

    public init(endpoint: String, context: HttpContext) {
        this.sid = "${DateTime.nowUTC().nanosecond}.${Random().nextUInt16()}"
        this.endpoint = endpoint
        this.context = context
    }

    public prop httpContext: HttpContext {
        get() {
            return this.context
        }
    }

    public prop lastEventId: Option<String> {
        get() {
            return this.context.request.headers.getFirst("Last-Event-ID")
        }
    }

    protected func serve() {
        this.response = Option.Some(HttpResponseWriter(this.context))

        // 开始发送事件
        this.context.responseBuilder
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

    public func send(message: Message) {
        let msg = message.toMessageString();
        queue.enqueue(msg)
    }
}