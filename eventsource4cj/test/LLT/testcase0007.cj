// EXEC: cjc %import-path %L %l %f
// EXEC: ./main

package eventsource4jexample

import eventsource4cj.client.*
import eventsource4cj.model.*
import eventsource4cj.server.*
import eventsource4cj.util.GzipUtil
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
let endpoint = "/gzip-bus"

main(): Int64 {
    println("===== Cangjie SSE Client GZIP Compression Test =====")

    // Test GzipUtil first
    println("\n[Pre-test] Testing GzipUtil compression/decompression")
    testGzipUtil()

    // Start server (with headers validation)
    spawn {
        serveWithAuth()
    }

    // Wait for server to start
    sleep(Duration.second * 1)

    // Test 1: POST with GZIP compressed request body
    println("\n[Test 1] POST connection with GZIP compressed request body")
    testPostWithGzipBody()

    // Wait
    sleep(Duration.second * 2)

    // Test 2: POST with GZIP and custom headers
    println("\n[Test 2] POST connection with GZIP and custom headers")
    testPostWithGzipAndHeaders()

    // Wait
    sleep(Duration.second * 2)

    // Test 3: GZIP with Array<UInt8> body
    println("\n[Test 3] POST connection with GZIP compressed Array<UInt8> body")
    testPostWithGzipBytesBody()

    // Wait
    sleep(Duration.second * 2)

    // Test 4: GZIP enable/disable toggle
    println("\n[Test 4] GZIP enable/disable toggle test")
    testGzipToggle()

    // Block main thread to observe results
    sleep(Duration.second * 5)

    println("\n===== Test completed =====")
    return 0
}

// Pre-test: Test GzipUtil functionality
func testGzipUtil(): Unit {
    try {
        let original = "Hello, GZIP compression test! This is a test string."
        let originalBytes = Array<UInt8>(original.toArray())
        
        // Compress
        let compressed = GzipUtil.compress(originalBytes)
        println("  Original size: ${originalBytes.size} bytes")
        println("  Compressed size: ${compressed.size} bytes")
        
        // Verify GZIP magic number
        if (GzipUtil.isGzip(compressed)) {
            println("  GZIP format verified: OK")
        } else {
            println("  GZIP format verified: FAILED")
        }
        
        // Decompress
        let decompressed = GzipUtil.decompress(compressed)
        let decompressedStr = String.fromUtf8(decompressed)
        
        if (decompressedStr == original) {
            println("  Decompression result: MATCH")
        } else {
            println("  Decompression result: MISMATCH")
            println("    Expected: ${original}")
            println("    Got: ${decompressedStr}")
        }
        
    } catch (e: Exception) {
        println("  [Exception] ${e.message}")
    }
}

// Test 1: POST with GZIP compressed request body
func testPostWithGzipBody(): Unit {
    try {
        let requestBody = "{\"query\": \"gzip test\", \"timestamp\": \"${DateTime.nowUTC().toString()}\"}"
        let es = EventSource("http://127.0.0.1:8084/gzip-bus?client=gzip-client", requestBody)

        // Enable GZIP compression for request body
        es.setCompressRequestBody(true)
        println("  GZIP enabled: ${es.isGzipEnabled()}")
        println("  Request body compression: ${es.isRequestBodyCompressionEnabled()}")

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

// Test 2: POST with GZIP and custom headers
func testPostWithGzipAndHeaders(): Unit {
    try {
        let requestBody = "{\"query\": \"secure gzip\", \"clientType\": \"cangjie-gzip\"}"
        let es = EventSource("http://127.0.0.1:8084/gzip-bus?client=gzip-secure-client", requestBody)

        // Enable GZIP compression
        es.setCompressRequestBody(true)

        // Set custom headers
        es.setHeader("X-Auth-Token", "valid-token-gzip")
        es.setHeader("X-Client-Id", "cangjie-gzip-client")
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

// Test 3: GZIP with Array<UInt8> body
func testPostWithGzipBytesBody(): Unit {
    try {
        let jsonStr = "{\"query\": \"binary gzip\", \"timestamp\": \"${DateTime.nowUTC().toString()}\"}"
        let bodyBytes = Array<UInt8>(jsonStr.toArray())

        let es = EventSource("http://127.0.0.1:8084/gzip-bus?client=gzip-bytes-client", bodyBytes)

        // Enable GZIP compression
        es.setCompressRequestBody(true)

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

// Test 4: GZIP enable/disable toggle
func testGzipToggle(): Unit {
    try {
        let es = EventSource("http://127.0.0.1:8084/gzip-bus?client=gzip-toggle-client")

        // Step 1: Initially GZIP is disabled
        println("  [Step 1] Initial GZIP state: enabled=${es.isGzipEnabled()}")

        // Step 2: Enable GZIP for response decompression only
        es.setEnableGzip(true)
        println("  [Step 2] After setEnableGzip(true): enabled=${es.isGzipEnabled()}, compress=${es.isRequestBodyCompressionEnabled()}")

        // Step 3: Enable request body compression (also enables GZIP)
        es.setCompressRequestBody(true)
        println("  [Step 3] After setCompressRequestBody(true): enabled=${es.isGzipEnabled()}, compress=${es.isRequestBodyCompressionEnabled()}")

        // Step 4: Set body and test
        es.setBody("{\"step\": 4, \"data\": \"gzip toggle test\"}")

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
    println("[Server] Starting SSE service with GZIP support...")

    let sseServer = SseServer("127.0.0.1", 8084)
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
    let contentEncoding = headers.get("Content-Encoding")

    println("  [Server] Received connection request:")
    println("    X-Auth-Token: ${authToken.getOrDefault("Not provided")}")
    println("    X-Client-Id: ${clientId.getOrDefault("Not provided")}")
    println("    Content-Encoding: ${contentEncoding.getOrDefault("Not specified")}")
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
