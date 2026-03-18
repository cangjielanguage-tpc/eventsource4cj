// EXEC: cjc %import-path %L %l %f --test
// EXEC: ./main

package eventsource4cj.test

import eventsource4cj.server.*
import eventsource4cj.client.*
import eventsource4cj.model.*

func sseServer(): Unit {
    let sseServer = SseServer("127.0.0.1", 8080)
    spawn {
        sseServer.serveForever()
    }

    let endpoint = "/bus"

    // Publish endpoint (client connection event handler callback)
    sseServer.publish(
        endpoint,
        {
            broker: SseEmitterBroker =>
                println("Client connection event handler callback invoked")
                true
        }
    )

    // Publish endpoint (without client connection event handler callback)
    //sseServer.publish(endpoint)

    // Get emitter bound to the endpoint
    let emitter = SseEmitter.getEmitter(endpoint).getOrThrow()

    // Send message to all connections on this endpoint
    let message = MessageBuilder().data("hello world").build()
    spawn {
        while (true) {
            emitter.sendAll(message)
        }
    }
}

func sseClient(): Unit {
    // Create message source
    let eventsource = EventSource("http://127.0.0.1:8080/bus")

    // Set message handler
    eventsource.onMessage({msg => println("Default message handler: ${msg.toMessageString()}")})
    eventsource.onEvent("test-event", {msg => println("Handle message: ${msg.toMessageString()}")})

    // Start message subscription (async operation)
    let future = eventsource.subscribe()

    try {
        future.get(Duration.millisecond)
    } catch (_: TimeoutException) {
        // ignore
    }
}

@Test
func cs1(): Unit {
    sseServer()
    sseClient()
}
