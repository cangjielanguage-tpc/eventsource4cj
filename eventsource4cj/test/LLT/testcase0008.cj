// EXEC: cjc %import-path %L %l %f
// EXEC: ./main

package eventsource4jexample

import eventsource4cj.client.*
import eventsource4cj.model.*
import eventsource4cj.server.*
import eventsource4cj.util.BrotliUtil
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
let endpoint = "/brotli-bus"

main(): Int64 {
    println("===== Cangjie SSE Client Brotli Compression Test =====")

    // Test BrotliUtil first
    println("\n[Pre-test] Testing BrotliUtil compression/decompression")
    testBrotliUtil()

    // Start server (with headers validation)
    spawn {
        serveWithAuth()
    }

    // Wait for server to start
    sleep(Duration.second * 1)

    // Test 1: POST with Brotli compressed request body
    println("\n[Test 1] POST connection with Brotli compressed request body")
    testPostWithBrotliBody()

    // Wait
    sleep(Duration.second * 2)

    // Test 2: POST with Brotli and custom headers
    println("\n[Test 2] POST connection with Brotli and custom headers")
    testPostWithBrotliAndHeaders()

    // Wait
    sleep(Duration.second * 2)

    // Test 3: Brotli with Array<UInt8> body
    println("\n[Test 3] POST connection with Brotli compressed Array<UInt8> body")
    testPostWithBrotliBytesBody()

    // Wait
    sleep(Duration.second * 2)

    // Test 4: Brotli enable/disable toggle
    println("\n[Test 4] Brotli enable/disable toggle test")
    testBrotliToggle()

    // Wait
    sleep(Duration.second * 2)

    // Test 5: Brotli response decompression
    println("\n[Test 5] Brotli response decompression test")
    testBrotliResponseDecompression()

    // Block main thread to observe results
    sleep(Duration.second * 5)

    println("\n===== Test completed =====")
    return 0
}

// Pre-test: Test BrotliUtil functionality
func testBrotliUtil(): Unit {
    try {
        let original = "Hello, Brotli compression test! This is a test string for Brotli."
        let originalBytes = Array<UInt8>(original.toArray())
        
        // Compress
        let compressed = BrotliUtil.compress(originalBytes)
        println("  Original size: ${originalBytes.size} bytes")
        println("  Compressed size: ${compressed.size} bytes")
        
        // Decompress
        let decompressed = BrotliUtil.decompress(compressed)
        let decompressedStr = String.fromUtf8(decompressed)
        
        if (decompressedStr == original) {
            println("  Decompression result: MATCH")
        } else {
            println("  Decompression result: MISMATCH")
            println("    Expected: ${original}")
            println("    Got: ${decompressedStr}")
        }
        
        // Test with quality parameter
        let compressedQ11 = BrotliUtil.compress(originalBytes, 11)
        println("  Compressed with quality 11: ${compressedQ11.size} bytes")
        
    } catch (e: Exception) {
        println("  [Exception] ${e.message}")
    }
}

// Test 1: POST with Brotli compressed request body
func testPostWithBrotliBody(): Unit {
    try {
        let requestBody = "{\"query\": \"brotli test\", \"timestamp\": \"${DateTime.nowUTC().toString()}\"}"
        let es = EventSource("http://127.0.0.1:8085/brotli-bus?client=brotli-client", requestBody)

        // Enable Brotli compression for request body
        es.setCompressRequestBodyWithBrotli(true)
        println("  Brotli enabled: ${es.isBrotliEnabled()}")
        println("  Request body compression: ${es.isRequestBodyBrotliCompressionEnabled()}")

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

// Test 2: POST with Brotli and custom headers
func testPostWithBrotliAndHeaders(): Unit {
    try {
        let requestBody = "{\"query\": \"secure brotli\", \"clientType\": \"cangjie-brotli\"}"
        let es = EventSource("http://127.0.0.1:8085/brotli-bus?client=brotli-secure-client", requestBody)

        // Enable Brotli compression
        es.setCompressRequestBodyWithBrotli(true)

        // Set custom headers
        es.setHeader("X-Auth-Token", "valid-token-brotli")
        es.setHeader("X-Client-Id", "cangjie-brotli-client")
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

// Test 3: Brotli with Array<UInt8> body
func testPostWithBrotliBytesBody(): Unit {
    try {
        let jsonStr = "{\"query\": \"binary brotli\", \"timestamp\": \"${DateTime.nowUTC().toString()}\"}"
        let bodyBytes = Array<UInt8>(jsonStr.toArray())

        let es = EventSource("http://127.0.0.1:8085/brotli-bus?client=brotli-bytes-client", bodyBytes)

        // Enable Brotli compression
        es.setCompressRequestBodyWithBrotli(true)

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

// Test 4: Brotli enable/disable toggle
func testBrotliToggle(): Unit {
    try {
        let es = EventSource("http://127.0.0.1:8085/brotli-bus?client=brotli-toggle-client")

        // Step 1: Initially Brotli is disabled
        println("  [Step 1] Initial Brotli state: enabled=${es.isBrotliEnabled()}")

        // Step 2: Enable Brotli for response decompression only
        es.setEnableBrotli(true)
        println("  [Step 2] After setEnableBrotli(true): enabled=${es.isBrotliEnabled()}, compress=${es.isRequestBodyBrotliCompressionEnabled()}")

        // Step 3: Enable request body compression (also enables Brotli)
        es.setCompressRequestBodyWithBrotli(true)
        println("  [Step 3] After setCompressRequestBodyWithBrotli(true): enabled=${es.isBrotliEnabled()}, compress=${es.isRequestBodyBrotliCompressionEnabled()}")

        // Step 4: Set body and test
        es.setBody("{\"step\": 4, \"data\": \"brotli toggle test\"}")

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

// Test 5: Brotli response decompression
func testBrotliResponseDecompression(): Unit {
    try {
        let es = EventSource("http://127.0.0.1:8085/brotli-bus?client=brotli-response-client")

        // Enable Brotli for response decompression
        es.setEnableBrotli(true)
        println("  Brotli response decompression enabled: ${es.isBrotliEnabled()}")

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
    println("[Server] Starting SSE service with Brotli support...")

    let sseServer = SseServer("127.0.0.1", 8085)
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
