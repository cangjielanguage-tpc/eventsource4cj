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

    // 发布端点(客户端连接事件处理回调函数)
    sseServer.publish(
        endpoint,
        {
            broker: SseEmitterBroker =>
                println("客户端连接事件处理回调函数被调用")
                true
        }
    )

    // 发布端点(不传客户端连接事件处理回调函数)
    //sseServer.publish(endpoint)

    // 获取端点绑定的消息发送器
    let emitter = SseEmitter.getEmitter(endpoint).getOrThrow()

    // 向该端点上的全部连接发送消息
    let message = MessageBuilder().data("hello world").build()
    spawn {
        while (true) {
            emitter.sendAll(message)
        }
    }
}

func sseClient(): Unit {
    // 创建消息源
    let eventsource = EventSource("http://127.0.0.1:8080/bus")

    // 设置消息处理函数
    eventsource.onMessage({msg => println("默认处理消息：${msg.toMessageString()}")})
    eventsource.onEvent("test-event", {msg => println("处理消息：${msg.toMessageString()}")})

    // 开始订阅消息（异步操作）
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
