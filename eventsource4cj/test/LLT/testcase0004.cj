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
let endpoint = "/secure-bus"

main(): Int64 {
    println("===== Cangjie SSE Client Custom Headers Test =====")

    // Start server (with headers validation)
    spawn {
        serveWithAuth()
    }

    // Wait for server to start
    sleep(Duration.second * 1)

    // Test 1: Without headers (should be rejected)
    println("\n[Test 1] Connection without auth headers (expected to fail)")
    testWithoutHeaders()

    // Wait
    sleep(Duration.second * 2)

    // Test 2: Use setHeader to set single header
    println("\n[Test 2] Set auth headers using setHeader")
    testWithSingleHeaders()

    // Wait
    sleep(Duration.second * 2)

    // Test 3: Use setHeaders for batch setting
    println("\n[Test 3] Batch set headers using setHeaders")
    testWithBatchHeaders()

    // Wait
    sleep(Duration.second * 2)

    // Test 4: Headers management (add, remove, update)
    println("\n[Test 4] Headers management functionality test")
    testHeadersManagement()

    // Block main thread to observe results
    sleep(Duration.second * 5)

    println("\n===== Test completed =====")
    return 0
}

// Test 1: Without headers
func testWithoutHeaders(): Unit {
    try {
        let es = EventSource("http://127.0.0.1:8081/secure-bus")
        es.setExceptionHandler(
            { ex, buffer =>
                println("  [Error] Connection failed: ${ex.message}")
            }
        )
        es.onMessage(
            { msg =>
                println("  [Message] ${msg.data.getOrThrow()}")
            }
        )
        es.subscribe()
        sleep(Duration.second * 1)
    } catch (e: Exception) {
        println("  [Exception] ${e.message}")
    }
}

// Test 2: Use setHeader to set single header
func testWithSingleHeaders(): Unit {
    try {
        let es = EventSource("http://127.0.0.1:8081/secure-bus?client=single-header-client")

        // Use setHeader to set one by one
        es.setHeader("X-Auth-Token", "valid-token-12345")
        es.setHeader("X-Client-Id", "cangjie-client-001")

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

// Test 3: Use setHeaders for batch setting
func testWithBatchHeaders(): Unit {
    try {
        let es = EventSource("http://127.0.0.1:8081/secure-bus?client=batch-header-client")

        // Batch set headers
        let headers = HashMap<String, String>()
        headers.add("X-Auth-Token", "valid-token-67890")
        headers.add("X-Client-Id", "cangjie-client-002")
        headers.add("X-Api-Key", "api-key-12345")
        headers.add("X-Custom-Header", "custom-value")
        es.setHeaders(headers)

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

// Test 4: Headers management
func testHeadersManagement(): Unit {
    try {
        let es = EventSource("http://127.0.0.1:8081/secure-bus?client=mgmt-client")

        // 1. Set temporary headers
        es.setHeader("X-Auth-Token", "temp-token")
        es.setHeader("X-Client-Id", "temp-client")
        es.setHeader("X-Temp-Header", "will-be-removed")
        println("  [Step 1] Set temporary headers")

        // 2. Remove unwanted header
        es.removeHeader("X-Temp-Header")
        println("  [Step 2] Removed X-Temp-Header")

        // 3. Update header values
        es.setHeader("X-Auth-Token", "valid-token-mgmt")
        es.setHeader("X-Client-Id", "cangjie-client-003")
        println("  [Step 3] Updated auth info")

        // 4. Add extra header
        es.setHeader("X-Api-Key", "api-key-mgmt")
        println("  [Step 4] Added API Key")

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
    println("[Server] Starting SSE service with header validation...")

    let sseServer = SseServer("127.0.0.1", 8081)
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
    let apiKey = headers.get("X-Api-Key")

    println("  [Server] Received connection request:")
    println("    X-Auth-Token: ${authToken.getOrDefault("Not provided")}")
    println("    X-Client-Id: ${clientId.getOrDefault("Not provided")}")
    println("    X-Api-Key: ${apiKey.getOrDefault("Not provided")}")

    // Validate required headers
    if (authToken.isNone() || clientId.isNone()) {
        println("    [Rejected] Missing required headers")
        return false
    }

    println("    [Accepted] Client ${clientId.getOrThrow()} connected successfully")
    clients.add(broker)
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
