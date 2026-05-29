package eventsource4cj.client

import std.sync.*
import std.unittest.*
import std.unittest.testmacro.*
import eventsource4cj.model.*

@Test
class EventSourceCloseTest {
    let SSE_BASE_URL = "http://127.0.0.1:9000"

    // Test: close() closes the underlying socket, causing stream.read() to
    // return immediately. The subscribe Future should complete promptly after close().
    // This is the key difference from close() — close interrupts active stream reading.
    @TestCase
    func closeForciblyTerminatesSubscriptionImmediately() {
        let messageCount = AtomicInt64(0)
        let es = EventSource("${SSE_BASE_URL}/sse/range/1/1000/500")

        es.onEvent("range", { msg =>
            messageCount.fetchAdd(1)
        })

        let future = es.subscribe()
        sleep(Duration.millisecond * 2000)
        let countBeforeClose = messageCount.load()
        @Assert(countBeforeClose > 0)

        es.close()
        future.get(Duration.second * 5)

        let countAfterClose = messageCount.load()
        @Assert(countAfterClose == countBeforeClose)
    }

    // Test: calling subscribe() after close() should throw IllegalStateException
    @TestCase
    func subscribeAfterCloseForciblyThrowsException() {
        let es = EventSource("${SSE_BASE_URL}/sse/range/1/1/10")

        es.close()

        var exceptionThrown = false
        try {
            es.subscribe()
        } catch (e: IllegalStateException) {
            exceptionThrown = true
        }

        @Assert(exceptionThrown)
    }

    // Test: close() wakes up the retry wait (same as close)
    @TestCase
    func closeForciblyInterruptsRetryWait() {
        let es = EventSource("http://127.0.0.1:1/sse")
        es.retry = Duration.millisecond * 30000

        let future = es.subscribe()
        sleep(Duration.millisecond * 200)

        es.close()
        future.get(Duration.second * 3)

        @Assert(true)
    }
}