package eventsource4cj.client

import std.collection.*
import std.sync.*
import std.unittest.*
import std.unittest.testmacro.*
import eventsource4cj.model.*



@Test
class EventSourceClientCompressTest {
    let SSE_BASE_URL = "http://127.0.0.1:9000"

    @TestCase
    func gzipStreamDecompressionReceivesAllMessages() {
        let streamCount = AtomicInt64(0)
        let streamDataSeen = AtomicBool(false)
        let es = EventSource("${SSE_BASE_URL}/sse/gzip-stream/test/1/3/50")
        es.setAcceptCompressType(1)
        es.onEvent("gzip-stream", { msg =>
            streamCount.fetchAdd(1)
            if (msg.data.isSome() && msg.data.getOrThrow().contains("stream-msg")) {
                streamDataSeen.store(true)
            }
        })
        es.subscribe().get()

        @Assert(streamCount.load(), 3)
        @Assert(streamDataSeen.load())
    }

    @TestCase
    func gzipStreamDecompressionWithMultiPageMessages() {
        let streamCount = AtomicInt64(0)
        let es = EventSource("${SSE_BASE_URL}/sse/gzip-stream/test/2/3/50")
        es.setAcceptCompressType(1)
        es.onEvent("gzip-stream", { _ => streamCount.fetchAdd(1) })
        es.subscribe().get()

        // page=2, count=3 → 2 messages per interval × 3 intervals = 6 total
        @Assert(streamCount.load(), 6)
    }

    // AI streaming response with large repetitive JSON payload — simulates LLM streaming
    // Decompressed total size exceeds 8KB (DEFAULT_BUFFER_SIZE), forcing multiple read() calls
    @TestCase
    func gzipAiStreamDecompressionRequiresMultipleReads() {
        let aiCount = AtomicInt64(0)
        let contentSeen = AtomicBool(false)
        // page=5, count=10 → 10 intervals × 5 messages per interval = 50 total events
        // Each event ~400 bytes decompressed → 50 × 400 = ~20000 bytes >> 8KB buffer
        let es = EventSource("${SSE_BASE_URL}/sse/gzip-stream/ai/5/10/50")
        es.setAcceptCompressType(1)
        es.onEvent("ai-stream", { msg =>
            aiCount.fetchAdd(1)
            if (msg.data.isSome() && msg.data.getOrThrow().contains("claude-4-sonnet")) {
                contentSeen.store(true)
            } else {
                contentSeen.store(false)
            }
        })
        es.subscribe().get()

        @Assert(aiCount.load(), 50)
        @Assert(contentSeen.load())
    }

    // ============== Brotli streaming decompression tests ==============

    @TestCase
    func brotliStreamDecompressionReceivesAllMessages() {
        let streamCount = AtomicInt64(0)
        let streamDataSeen = AtomicBool(false)
        let es = EventSource("${SSE_BASE_URL}/sse/brotli-stream/test/1/3/50")
        es.setAcceptCompressType(2)
        es.onEvent("brotli-stream", { msg =>
            streamCount.fetchAdd(1)
            if (msg.data.isSome() && msg.data.getOrThrow().contains("stream-msg")) {
                streamDataSeen.store(true)
            }
        })
        es.subscribe().get()

        @Assert(streamCount.load(), 3)
        @Assert(streamDataSeen.load())
    }

    @TestCase
    func brotliStreamDecompressionWithMultiPageMessages() {
        let streamCount = AtomicInt64(0)
        let es = EventSource("${SSE_BASE_URL}/sse/brotli-stream/test/2/3/50")
        es.setAcceptCompressType(2)
        es.onEvent("brotli-stream", { _ => streamCount.fetchAdd(1) })
        es.subscribe().get()

        // page=2, count=3 → 2 messages per interval × 3 intervals = 6 total
        @Assert(streamCount.load(), 6)
    }

    // AI streaming response with Brotli compression — simulates LLM streaming
    // BrotliInputStream wraps network stream directly, decompresses incrementally
    @TestCase
    func brotliAiStreamDecompressionRequiresMultipleReads() {
        let aiCount = AtomicInt64(0)
        let contentSeen = AtomicBool(false)
        let es = EventSource("${SSE_BASE_URL}/sse/brotli-stream/ai/5/10/50")
        es.setAcceptCompressType(2)
        es.onEvent("ai-stream", { msg =>
            aiCount.fetchAdd(1)
            if (msg.data.isSome() && msg.data.getOrThrow().contains("claude-4-sonnet")) {
                contentSeen.store(true)
            } else {
                contentSeen.store(false)
            }
        })
        es.subscribe().get()

        @Assert(aiCount.load(), 50)
        @Assert(contentSeen.load())
    }
}
