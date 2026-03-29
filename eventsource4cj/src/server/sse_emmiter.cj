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
import std.collection.concurrent.*
import std.random.*
import std.regex.*
import std.sync.*
import std.time.*
import std.unicode.*
import stdx.net.http.*

public class SseServer {
    let server: Server
    var future: Option<Future<Unit>>

    public init(address: String, port: UInt16) {
        this.server = ServerBuilder().addr(address).port(port).build()
        this.future = Option.None
    }

    public init(server: Server) {
        this.server = server
        this.future = Option.None
    }

    public func getHttpServer(): Server {
        return this.server
    }

    public func serveForever(): Unit {
        let future = spawn {
            server.serve()
        }
        this.future = Option.Some(future)
        future.get()
    }

    public func terminate(): Unit {
        try {
            future?.cancel()
        } finally {
            server.closeGracefully()
        }
    }

    public func publish(endpoint: String): SseEmitter {
        return publish(endpoint, {_ => true})
    }

    public func publish(endpoint: String, clientConnectedHandler: (SseEmitterBroker) -> Bool): SseEmitter {
        let emitter = SseEmitter.createIfAbsent(endpoint)

        server.distributor.register(
            endpoint,
            {
                context =>
                    let broker = SseEmitterBroker(endpoint, context)
                    emitter.register(broker)
                    let checked = clientConnectedHandler(broker)
                    if (!checked) {
                        throw Exception("Server failed to process connection event!")
                    }
                    broker.serve()
            }
        )

        return emitter
    }
}

public class SseEmitter {
    private static let REG_ENDPOINT_ID = Regex("[/]{2,}")

    private static let lock = Mutex()

    private static let emitterMap = ConcurrentHashMap<String, SseEmitter>(32)

    private let endpoint: String

    private let brokerMap = ConcurrentHashMap<String, SseEmitterBroker>(32)

    private init(endpoint: String) {
        let endpointId = getEndpointId(endpoint)
        this.endpoint = endpointId
    }

    public func sendAll(message: Message): Unit {
        for ((k, v) in brokerMap) {
            v.send(message)
        }
    }

    public func send(message: Message, brokerFilter: (SseEmitterBroker) -> Bool): Unit {
        for ((k, v) in brokerMap) {
            if (brokerFilter(v)) {
                v.send(message)
            }
        }
    }

    public static func getEmitter(endpoint: String): Option<SseEmitter> {
        let endpointId = getEndpointId(endpoint)
        return emitterMap.get(endpointId)
    }

    public static func defaultBrokerFilterByRequestParameterValue(parameterName: String, parameterValue: String): (SseEmitterBroker) -> Bool {
        return {
            broker: SseEmitterBroker =>
                let val = broker.httpContext.request.form.get(parameterName)
                if (val.isNone()) {
                    return false
                } else {
                    let pv = val.getOrDefault({=> ""})
                    return pv.trim() == parameterValue
                }
        }
    }

    protected static func createIfAbsent(endpoint: String): SseEmitter {
        let endpointId = getEndpointId(endpoint)

        if (emitterMap.contains(endpointId)) {
            return emitterMap.get(endpointId).getOrThrow()
        } else {
            synchronized(lock) {
                if (!emitterMap.contains(endpointId)) {
                    let em = SseEmitter(endpoint)
                    emitterMap.add(endpointId, em)
                }

                return emitterMap.get(endpointId).getOrThrow()
            }
        }
    }

    protected func register(emitter: SseEmitterBroker) {
        let endpointId = getEndpointId(emitter.endpoint)
        emitterMap.get(endpointId).getOrThrow().brokerMap.add(emitter.sid, emitter)
    }

    protected static func deregister(emitter: SseEmitterBroker) {
        let endpointId = getEndpointId(emitter.endpoint)
        let value = emitterMap.get(endpointId)
        if (value.isSome()) {
            value.getOrThrow().brokerMap.remove(emitter.sid)
        }
    }

    private static func getEndpointId(endpoint: String): String {
        return REG_ENDPOINT_ID.replace("/" + endpoint, "/")
    }
}

public class SseEmitterBroker {
    let sid: String

    let endpoint: String

    var context: HttpContext

    var response: Option<HttpResponseWriter> = Option.None

    var queue = ArrayBlockingQueue<String>(95536)

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

        // Start sending events
        this
            .context
            .responseBuilder
            .header("Transfer-encoding", "chunked")
            .header("Content-Type", "text/event-stream")
            .header("Cache-Control", "no-cache")
            .header("Connection", "keep-alive")
        while (true) {
            let msg = queue.remove()
            try {
                response.getOrThrow().write(msg.toArray())
            } catch (ex: Exception) {
                ex.printStackTrace()
                SseEmitter.deregister(this)
                break
            }
        }
    }

    public func send(message: Message): Unit {
        let msg = message.toMessageString()
        queue.add(msg)
    }
}
