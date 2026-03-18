// EXEC: cjc %import-path %L %l %f
// EXEC: ./main

package eventsource4jexample

import eventsource4cj.client.*
import eventsource4cj.model.*
import eventsource4cj.server.*
import std.collection.*
import std.collection.ArrayList
import std.collection.concurrent.*
import std.io.*
import std.random.*
import std.sync.*
import std.time.*
import std.time.*
import stdx.log.*
import stdx.net.http.*

let clients = ArrayList<SseEmitterBroker>()
let messageCount = AtomicInt64(0)
let endpoint = "/bus"

main(): Int64 {
    println("hello world")

    // Start server
    spawn {
        serve()
    }

    // Start client
    let eventsource1 = EventSource("http://127.0.0.1:8080/bus?token=c1-89uy93r")
    eventsource1.setExceptionHandler(
        {
            ex, buffer =>
                println("[Client 1] - Message receive error: ${ex.message}")
                println("[Client 1] - Exception data: ${buffer}")
        }
    )
    let eventsource2 = EventSource("http://127.0.0.1:8080/bus?token=c2-394j590&sse-tag=GA")

    // Register event handler
    eventsource1.onMessage(
        {
            msg =>
                println("[Client 1] - Default message handler ----------------->")
                println("[Client 1] - " + msg.toMessageString())
        }
    )
    eventsource1.onEvent(
        "test-event",
        {
            msg =>
                println("[Client 1] - Handle message ----------------->")
                println("[Client 1] - " + msg.toMessageString())
        }
    )
    eventsource2.onMessage(
        {
            msg =>
                println("[Client 2] - Default message handler =========>")
                println("[Client 2] - " + msg.toMessageString())
        }
    )
    eventsource2.onEvent(
        "test-event",
        {
            msg =>
                println("[Client 2] - Handle message =========>")
                println("[Client 2] - " + msg.toMessageString())
        }
    )

    // Start message subscription
    let future = eventsource1.subscribe()
    eventsource2.subscribe()

    // Block main thread for 10s to observe results
    try {
        future.get(Duration.second * 10)
    } catch (_: TimeoutException) {
        // ignore
    }

    return 0
}

func serve(): Int64 {
    println("hello eventsource4cj!!!")

    let sseServer = SseServer("127.0.0.1", 8080)

    sseServer.getHttpServer().logger.level = LogLevel.DEBUG

    // Add an example page, visit "127.0.0.1:8080/hello" in browser to test message subscription
    addExamplePage(sseServer.getHttpServer())

    sseServer.publish(endpoint, checkAndInit)

    sseServer.publish("/bus2")

    doBusiness()

    sseServer.serveForever()

    return 0
}

/**
 * Connection check and initialization
 */
func checkAndInit(broker: SseEmitterBroker): Bool {
    let requestContext = broker.httpContext

    // Simulate permission check and other validations
    let token = requestContext.request.headers.get("token")

    // Business processing. For example, record connected requests, then call send method in related business
    clients.add(broker)

    return true
}

/**
 * Simulate business side asynchronously sending messages
 */
func doBusiness(): Unit {
    Timer.repeat(
        0 * Duration.second,
        5 * Duration.second,
        {
            =>
                // Iterate all clients and send messages
                clients.iterator().forEach(
                    {
                        broker =>
                            let index = messageCount.fetchAdd(1)
                            let message = MessageBuilder()
                                .event("test-event")
                                .id("id-${index}-1")
                                .data("Data line 1-${DateTime.nowUTC().toString()}")
                                .data("Data line 2-${DateTime.nowUTC().toString()}")
                                .data("Data line 3-${DateTime.nowUTC().toString()}")
                                .build()
                            println("Send message to all connections on endpoint->${message.toMessageString()}\n")
                            broker.send(message)
                    }
                )

                // Filter by request parameter and send
                let emitter = SseEmitter.getEmitter("/bus").getOrThrow()
                let message = MessageBuilder()
                    .data("Message to all clients with request parameter sse-tag=GA-${DateTime.nowUTC().toString()}")
                    .build()
                emitter.send(message, SseEmitter.defaultBrokerFilterByRequestParameterValue("sse-tag", "GA"))
        }
    )
}

func addExamplePage(httpServer: Server) {
    httpServer.distributor.register(
        "/hello",
        {
            context =>
                let body = StringBuilder()
                body.append("<html><head></head><body>test server send event!!!!<div id='msgbox'></div></body><script>")
                body.append("console.log('load sse ...')")
                body.append(
                    "const evtsource = new EventSource('http://127.0.0.1:8080/bus?clientId=clientId-1&sse-tag=user8080')")
                body.append("evtsource.onmessage = function(ctx) {console.log(ctx)}")
                body.append("evtsource.addEventListener('test-event', function(ctx) {")
                body.append("    console.log(ctx)")
                body.append("    const boxer = document.getElementById('msgbox')")
                body.append("    const p = document.createElement('p')")
                body.append("    p.innerText = ctx.lastEventId + ':' + ctx.data")
                body.append("    boxer.appendChild(p)")
                body.append("})")
                body.append("</script></html>")
                context.responseBuilder.header("Content-Type", "text/html").body(body.toString().toArray())
        }
    )
}
