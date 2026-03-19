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
import stdx.log.*
import stdx.net.http.*

let clients = ArrayList<SseEmitterBroker>()
let messageCount = AtomicInt64(0)
let endpoint = "/post-bus"

main(): Int64 {
    println("===== Cangjie SSE Client POST Method Test =====")

    // Start server (with headers validation)
    spawn {
        serveWithAuth()
    }

    // Wait for server to start
    sleep(Duration.second * 1)

    // Test 1: POST without body (similar to GET)
    println("\n[Test 1] POST connection without body")
    testPostWithoutBody()

    // Wait
    sleep(Duration.second * 2)

    // Test 2: POST with body
    println("\n[Test 2] POST connection with request body")
    testPostWithBody()

    // Wait
    sleep(Duration.second * 2)

    // Test 3: POST with body and custom headers
    println("\n[Test 3] POST connection with body and custom headers")
    testPostWithBodyAndHeaders()

    // Wait
    sleep(Duration.second * 2)

    // Test 4: POST with body management (setBody, clearBody)
    println("\n[Test 4] POST body management test")
    testPostBodyManagement()

    // Block main thread to observe results
    sleep(Duration.second * 5)

    println("\n===== Test completed =====")
    return 0
}

// Test 1: POST without body
func testPostWithoutBody(): Unit {
    try {
        let es = EventSource("http://127.0.0.1:8082/post-bus")
        es.setExceptionHandler(
            { ex, buffer =>
                println("  [Error] Connection failed: ${ex.message}")
            }
        )
        es.onMessage(
            { msg =>
                println("  [Message] Received: ${msg.data.getOrThrow()}")
            }
        )
        es.subscribe()
        sleep(Duration.second * 1)
    } catch (e: Exception) {
        println("  [Exception] ${e.message}")
    }
}

// Test 2: POST with body
func testPostWithBody(): Unit {
    try {
        let requestBody = "{\"query\": \"test data\", \"timestamp\": \"${DateTime.nowUTC().toString()}\"}"
        let es = EventSource("http://127.0.0.1:8082/post-bus?client=post-body-client", requestBody)

        es.setExceptionHandler(
            { ex, buffer =>
                println("  [Error] ${ex.message}")
            }
        )
        es.onMessage(
            { msg =>
                println("  [Message] Received: ${msg.data.getOrThrow()}")
            }
        )
        es.subscribe()
        sleep(Duration.second * 2)
    } catch (e: Exception) {
        println("  [Exception] ${e.message}")
    }
}

// Test 3: POST with body and custom headers
func testPostWithBodyAndHeaders(): Unit {
    try {
        let requestBody = "{\"query\": \"secure data\", \"clientType\": \"cangjie\"}"
        let es = EventSource("http://127.0.0.1:8082/post-bus?client=post-secure-client", requestBody)

        // Set custom headers
        es.setHeader("X-Auth-Token", "valid-token-post")
        es.setHeader("X-Client-Id", "cangjie-post-client")
        es.setHeader("Content-Type", "application/json")

        es.setExceptionHandler(
            { ex, buffer =>
                println("  [Error] ${ex.message}")
            }
        )
        es.onMessage(
            { msg =>
                println("  [Message] Received: ${msg.data.getOrThrow()}")
            }
        )
        es.subscribe()
        sleep(Duration.second * 2)
    } catch (e: Exception) {
        println("  [Exception] ${e.message}")
    }
}

// Test 4: POST body management
func testPostBodyManagement(): Unit {
    try {
        // Step 1: Create EventSource without body
        let es = EventSource("http://127.0.0.1:8082/post-bus?client=post-mgmt-client")
        println("  [Step 1] Created EventSource without body (will use GET)")

        // Step 2: Set body using setBody
        es.setBody("{\"initial\": \"data\"}")
        println("  [Step 2] Set body using setBody()")

        // Step 3: Update body
        es.setBody("{\"updated\": \"data\", \"step\": 3}")
        println("  [Step 3] Updated body with new content")

        // Step 4: Clear body (will revert to GET)
        es.clearBody()
        println("  [Step 4] Cleared body (will use GET)")

        // Step 5: Set body again
        es.setBody("{\"final\": \"data\"}")
        println("  [Step 5] Set body again for POST request")

        es.setExceptionHandler(
            { ex, buffer =>
                println("  [Error] ${ex.message}")
            }
        )
        es.onMessage(
            { msg =>
                println("  [Message] Received: ${msg.data.getOrThrow()}")
            }
        )
        es.subscribe()
        sleep(Duration.second * 2)
    } catch (e: Exception) {
        println("  [Exception] ${e.message}")
    }
}

// Start server with authentication
func serveWithAuth(): Int64 {
    println("[Server] Starting SSE service with POST support...")

    let sseServer = SseServer("127.0.0.1", 8082)
    sseServer.getHttpServer().logger.level = LogLevel.ERROR

    // Add endpoint with authentication
    sseServer.publish(endpoint, checkAuthAndInit)

    // Start scheduled message sending
    spawn {
        doBusinessWithAuth()
    }

    sseServer.serveForever()
    return 0
}

// Authentication check
func checkAuthAndInit(broker: SseEmitterBroker): Bool {
    let requestContext = broker.httpContext
    let headers = requestContext.request.headers

    // Get auth headers
    let authToken = headers.get("X-Auth-Token")
    let clientId = headers.get("X-Client-Id")

    println("  [Server] Received connection request:")
    println("    X-Auth-Token: ${authToken.getOrDefault("Not provided")}")
    println("    X-Client-Id: ${clientId.getOrDefault("Not provided")}")
    println("    Method: ${requestContext.request.method}")

    clients.add(broker)
    println("    [Accepted] Client connected successfully")
    return true
}

// Send messages
func doBusinessWithAuth(): Unit {
    // Wait for client connection
    sleep(Duration.second * 2)

    var count = 0
    while (count < 10) {
        sleep(Duration.second * 1)

        if (clients.isEmpty()) {
            continue
        }

        clients.iterator().forEach(
            { broker =>
                let index = messageCount.fetchAdd(1)
                let message = MessageBuilder()
                    .id("msg-${index}")
                    .data("Server message #${index} - Time: ${DateTime.nowUTC().toString()}")
                    .build()
                broker.send(message)
            }
        )
        count++
    }
}
