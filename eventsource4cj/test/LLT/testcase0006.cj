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
let endpoint = "/bytes-bus"

main(): Int64 {
    println("===== Cangjie SSE Client Array<UInt8> Body Test =====")

    // Start server (with headers validation)
    spawn {
        serveWithAuth()
    }

    // Wait for server to start
    sleep(Duration.second * 1)

    // Test 1: POST with Array<UInt8> body
    println("\n[Test 1] POST connection with Array<UInt8> body")
    testPostWithBytesBody()

    // Wait
    sleep(Duration.second * 2)

    // Test 2: POST with Array<UInt8> body and custom headers
    println("\n[Test 2] POST connection with Array<UInt8> body and custom headers")
    testPostWithBytesBodyAndHeaders()

    // Wait
    sleep(Duration.second * 2)

    // Test 3: Array<UInt8> body management
    println("\n[Test 3] Array<UInt8> body management test")
    testBytesBodyManagement()

    // Wait
    sleep(Duration.second * 2)

    // Test 4: Switch between String and Array<UInt8> body
    println("\n[Test 4] Switch between String and Array<UInt8> body")
    testBodyTypeSwitch()

    // Block main thread to observe results
    sleep(Duration.second * 5)

    println("\n===== Test completed =====")
    return 0
}

// Test 1: POST with Array<UInt8> body
func testPostWithBytesBody(): Unit {
    try {
        // Create binary data (UTF-8 encoded JSON)
        let jsonStr = "{\"query\": \"binary data\", \"timestamp\": \"${DateTime.nowUTC().toString()}\"}"
        let bodyBytes = Array<UInt8>(jsonStr.toArray())

        let es = EventSource("http://127.0.0.1:8083/bytes-bus?client=bytes-client", bodyBytes)

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

// Test 2: POST with Array<UInt8> body and custom headers
func testPostWithBytesBodyAndHeaders(): Unit {
    try {
        // Create binary data
        let jsonStr = "{\"query\": \"secure binary\", \"clientType\": \"cangjie-binary\"}"
        let bodyBytes = Array<UInt8>(jsonStr.toArray())

        let es = EventSource("http://127.0.0.1:8083/bytes-bus?client=bytes-secure-client", bodyBytes)

        // Set custom headers
        es.setHeader("X-Auth-Token", "valid-token-bytes")
        es.setHeader("X-Client-Id", "cangjie-bytes-client")
        es.setHeader("Content-Type", "application/octet-stream")

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

// Test 3: Array<UInt8> body management
func testBytesBodyManagement(): Unit {
    try {
        let es = EventSource("http://127.0.0.1:8083/bytes-bus?client=bytes-mgmt-client")

        // Step 1: Set Array<UInt8> body using setBody
        let body1 = Array<UInt8>("{\"step\": 1, \"data\": \"initial bytes\"}".toArray())
        es.setBody(body1)
        println("  [Step 1] Set Array<UInt8> body using setBody()")

        // Step 2: Update body with new binary data
        let body2 = Array<UInt8>("{\"step\": 2, \"data\": \"updated bytes\"}".toArray())
        es.setBody(body2)
        println("  [Step 2] Updated Array<UInt8> body with new content")

        // Step 3: Clear body (will revert to GET)
        es.clearBody()
        println("  [Step 3] Cleared body (will use GET)")

        // Step 4: Set body again for POST request
        let body4 = Array<UInt8>("{\"step\": 4, \"data\": \"final bytes\"}".toArray())
        es.setBody(body4)
        println("  [Step 4] Set Array<UInt8> body again for POST request")

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

// Test 4: Switch between String and Array<UInt8> body
func testBodyTypeSwitch(): Unit {
    try {
        let es = EventSource("http://127.0.0.1:8083/bytes-bus?client=switch-client")

        // Step 1: Set String body
        es.setBody("{\"type\": \"string\"}")
        println("  [Step 1] Set String body")

        // Step 2: Switch to Array<UInt8> body (should replace String body)
        let bytesBody = Array<UInt8>("{\"type\": \"bytes\"}".toArray())
        es.setBody(bytesBody)
        println("  [Step 2] Switched to Array<UInt8> body")

        // Step 3: Switch back to String body
        es.setBody("{\"type\": \"string again\"}")
        println("  [Step 3] Switched back to String body")

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
    println("[Server] Starting SSE service with Array<UInt8> body support...")

    let sseServer = SseServer("127.0.0.1", 8083)
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
    println("    Content-Type: ${headers.get("Content-Type").getOrDefault("Not specified")}")

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
