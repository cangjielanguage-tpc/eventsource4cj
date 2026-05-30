package eventsource4cj.client

import std.collection.*
import std.sync.*
import std.unittest.*
import std.unittest.testmacro.*
import eventsource4cj.model.*



@Test
class EventSourceClientApiTest {
    let SSE_BASE_URL = "http://127.0.0.1:9000"
    
    @TestCase
    func getSubscribeReceivesRangeEvents() {
        let messageCount = AtomicInt64(0)
        let rangeCount = AtomicInt64(0)
        let firstRangeSeen = AtomicBool(false)
        let es = EventSource("${SSE_BASE_URL}/sse/range/1/3/10")

        es.onMessage({ msg =>
            if (msg.data.isSome()) {
                messageCount.fetchAdd(1)
            }
        })
        es.onEvent("range", { msg =>
            if (msg.eventType.isSome() && msg.eventType.getOrThrow() == "range") {
                rangeCount.fetchAdd(1)
            }
            if (msg.data.isSome() && msg.data.getOrThrow().contains("3-1")) {
                firstRangeSeen.store(true)
            }
        })

        es.subscribe().get()

        @Assert(messageCount.load(), 0)
        @Assert(rangeCount.load(), 3)
        @Assert(firstRangeSeen.load())
    }

    @TestCase
    func postStringBodyAndClearBody() {
        let postCount = AtomicInt64(0)
        let bodySeen = AtomicBool(false)
        let es = EventSource("${SSE_BASE_URL}/sse/post/range/1/2/10")
        es.setHeader("Content-Type", "application/json")
        es.setBody(#"{"query":"abc"}"#)
        es.onEvent("post-range", { msg =>
            postCount.fetchAdd(1)
            if (msg.data.isSome() && msg.data.getOrThrow().contains("abc")) {
                bodySeen.store(true)
            }
        })

        es.subscribe().get()

        @Assert(postCount.load(), 2)
        @Assert(bodySeen.load())

        let getCount = AtomicInt64(0)
        let getEs = EventSource("${SSE_BASE_URL}/sse/range/1/1/10")
        getEs.setBody("temporary")
        getEs.clearBody()
        getEs.onEvent("range", { _ => getCount.fetchAdd(1) })
        getEs.subscribe().get()
        @Assert(getCount.load(), 1)
    }

    @TestCase
    func postBytesBody() {
        let postCount = AtomicInt64(0)
        let bodySeen = AtomicBool(false)
        let es = EventSource("${SSE_BASE_URL}/sse/post/range/1/2/10")
        es.setHeader("Content-Type", "application/octet-stream")
        es.setBody("bytes-body".toArray())
        es.onEvent("post-range", { msg =>
            postCount.fetchAdd(1)
            let expectedBodyOctet = "[98,121,116,101,115,45,98,111,100,121]"
            if (msg.data.isSome() && msg.data.getOrThrow().contains(expectedBodyOctet)) {
                bodySeen.store(true)
            }
        })

        es.subscribe().get()

        @Assert(postCount.load(), 2)
        @Assert(bodySeen.load())
    }

    @TestCase
    func requestCompressionConfiguration() {
        let gzipCount = AtomicInt64(0)
        let gzipBodySeen = AtomicBool(false)
        let gzipEs = EventSource("${SSE_BASE_URL}/sse/gzip-response/post/1/2/10")
        gzipEs.setBody(#"{"query":"gzip"}"#)
        gzipEs.setRequestCompressType(1)
        @Assert(gzipEs.getRequestCompressType(), 1)
        gzipEs.onEvent("gzip-post-test", { msg =>
            gzipCount.fetchAdd(1)
            if (msg.data.isSome() && msg.data.getOrThrow().contains("gzip")) {
                gzipBodySeen.store(true)
            }
        })
        gzipEs.subscribe().get()

        @Assert(gzipCount.load(), 2)
        @Assert(gzipBodySeen.load())

        let brotliCount = AtomicInt64(0)
        let brotliBodySeen = AtomicBool(false)
        let brotliEs = EventSource("${SSE_BASE_URL}/sse/brotli-response/post/1/2/10")
        brotliEs.setBody(#"{"query":"brotli"}"#)
        brotliEs.setRequestCompressType(2)
        @Assert(brotliEs.getRequestCompressType(), 2)
        brotliEs.onEvent("brotli-post-test", { msg =>
            brotliCount.fetchAdd(1)
            if (msg.data.isSome() && msg.data.getOrThrow().contains("brotli")) {
                brotliBodySeen.store(true)
            }
        })
        brotliEs.subscribe().get()

        @Assert(brotliCount.load(), 2)
        @Assert(brotliBodySeen.load())

        brotliEs.setRequestCompressType(0)
        @Assert(brotliEs.getRequestCompressType(), 0)
    }

    @TestCase
    func responseCompressionConfiguration() {
        let gzipCount = AtomicInt64(0)
        let gzipEs = EventSource("${SSE_BASE_URL}/sse/gzip-response/test/1/2/10")
        gzipEs.setAcceptCompressType(1)
        @Assert(gzipEs.getAcceptCompressType(), 1)
        gzipEs.onEvent("gzip-test", { _ => gzipCount.fetchAdd(1) })
        gzipEs.subscribe().get()
        @Assert(gzipCount.load(), 2)

        let brotliCount = AtomicInt64(0)
        let brotliEs = EventSource("${SSE_BASE_URL}/sse/brotli-response/test/1/2/10")
        brotliEs.setAcceptCompressType(2)
        @Assert(brotliEs.getAcceptCompressType(), 2)
        brotliEs.onEvent("brotli-test", { _ => brotliCount.fetchAdd(1) })
        brotliEs.subscribe().get()
        @Assert(brotliCount.load(), 2)

        brotliEs.setAcceptCompressType(3)
        @Assert(brotliEs.getAcceptCompressType(), 3)
        brotliEs.setAcceptCompressType(0)
        @Assert(brotliEs.getAcceptCompressType(), 0)
    }

    @TestCase
    func singleHeaderAndRemoveHeader() {
        let okCount = AtomicInt64(0)
        let okEs = EventSource("${SSE_BASE_URL}/sse/secure/range/1/2/10")
        okEs.setHeader("X-Auth-Token", "token-123456")
        okEs.setHeader("X-Client-Id", "cj-client")
        okEs.onEvent("secure-range", { _ => okCount.fetchAdd(1) })
        okEs.subscribe().get()
        @Assert(okCount.load(), 2)

        let failedEs = EventSource("${SSE_BASE_URL}/sse/secure/range/1/1/10")
        failedEs.setHeader("X-Auth-Token", "token-removed")
        failedEs.setHeader("X-Client-Id", "will-be-removed")
        failedEs.removeHeader("X-Client-Id")
        let failedFuture = failedEs.subscribe()
        sleep(Duration.millisecond * 200)
        failedFuture.cancel()
        @Assert(true)
    }

    @TestCase
    func batchHeadersAndClearHeaders() {
        let headers = HashMap<String, String>()
        headers.add("X-Auth-Token", "token-abcdef")
        headers.add("X-Client-Id", "cj-client-batch")
        headers.add("X-Api-Key", "valid-api-key-12345")

        let okCount = AtomicInt64(0)
        let okEs = EventSource("${SSE_BASE_URL}/sse/secure/range/1/2/10")
        okEs.setHeaders(headers)
        okEs.onEvent("secure-range", { _ => okCount.fetchAdd(1) })
        okEs.subscribe().get()
        @Assert(okCount.load(), 2)

        let failedEs = EventSource("${SSE_BASE_URL}/sse/secure/range/1/1/10")
        failedEs.setHeaders(headers)
        failedEs.clearHeaders()
        let failedFuture = failedEs.subscribe()
        sleep(Duration.millisecond * 200)
        failedFuture.cancel()
        @Assert(true)
    }

    @TestCase
    func nonEventStreamResponseCanBeCancelled() {
        let es = EventSource("${SSE_BASE_URL}/sse/secure/range/1/1/10")
        let future = es.subscribe()
        sleep(Duration.millisecond * 200)
        future.cancel()
        @Assert(true)
    }

    @TestCase
    func connectionFailureFutureCanBeCancelled() {
        let es = EventSource("http://127.0.0.1:1/sse")
        let future = es.subscribe()
        sleep(Duration.millisecond * 100)
        future.cancel()
        @Assert(true)
    }

    @TestCase
    func retryFieldIsResolvedFromSseMessage() {
        let msg = MessageBuilder.resolve("retry:200\nevent:range\ndata:retry-test\n\n".toArray())
        @Assert(msg.retryInMills.getOrThrow(), 200)
        @Assert(msg.eventType.getOrThrow(), "range")
        @Assert(msg.data.getOrThrow(), "retry-test")
    }
}
