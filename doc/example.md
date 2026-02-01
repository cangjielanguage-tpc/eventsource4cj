### 完整示例代码

```cangjie
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
import std.time.*
import stdx.log.*
import stdx.net.http.*

let clients = ArrayList<SseEmitterBroker>()
let messageCount = AtomicInt64(0)
let endpoint = "/bus"

main(): Int64 {
    println("hello world")

    // 启动服务端
    spawn {
        serve()
    }

    // 启动客户端
    let eventsource1 = EventSource("http://127.0.0.1:8080/bus?token=c1-89uy93r")
    eventsource1.setExceptionHandler(
        {
            ex, buffer =>
                println("[客户端1]-接收消息错误：${ex.message}")
                println("[客户端1]-异常数据：${buffer}")
        }
    )
    let eventsource2 = EventSource("http://127.0.0.1:8080/bus?token=c2-394j590&sse-tag=GA")

    // 注册事件处理函数
    eventsource1.onMessage(
        {
            msg =>
                println("[客户端1]-默认处理消息----------------->")
                println("[客户端1]-" + msg.toMessageString())
        }
    )
    eventsource1.onEvent(
        "test-event",
        {
            msg =>
                println("[客户端1]-处理消息----------------->")
                println("[客户端1]-" + msg.toMessageString())
        }
    )
    eventsource2.onMessage(
        {
            msg =>
                println("[客户端2]-默认处理消息=========>")
                println("[客户端2]-" + msg.toMessageString())
        }
    )
    eventsource2.onEvent(
        "test-event",
        {
            msg =>
                println("[客户端2]-处理消息=========>")
                println("[客户端2]-" + msg.toMessageString())
        }
    )

    // 开始订阅消息
    let future = eventsource1.subscribe()
    eventsource2.subscribe()

    // 阻塞主线程以便观察效果
    future.get()

    return 0
}

func serve(): Int64 {
    println("hello eventsource4cj!!!")

    let sseServer = SseServer("127.0.0.1", 8080)

    sseServer.getHttpServer().logger.level = LogLevel.DEBUG

    // 添加一个示例页面，可以在浏览器访问"127.0.0.1:8080/hello"来测试消息订阅
    addExamplePage(sseServer.getHttpServer())

    sseServer.publish(endpoint, checkAndInit)

    sseServer.publish("/bus2")

    doBusiness()

    sseServer.serveForever()

    return 0
}

/**
 * 连接检查与初始化
 */
func checkAndInit(broker: SseEmitterBroker): Bool {
    let requestContext = broker.httpContext

    // 模拟权限校验等检查
    let token = requestContext.request.headers.get("token")

    // 业务处理。例如记录已连接请求，然后在相关业务中调用发送方法
    clients.add(broker)

    return true
}

/**
 * 模拟业务端异步发送消息
 */
func doBusiness(): Unit {
    Timer.repeat(
        0 * Duration.second,
        5 * Duration.second,
        {
            =>
                // 遍历全部客户端发送消息
                clients.iterator().forEach(
                    {
                        broker =>
                            let index = messageCount.fetchAdd(1)
                            let message = MessageBuilder()
                                .event("test-event")
                                .id("id-${index}-1")
                                .data("数据行1-${DateTime.nowUTC().toString()}")
                                .data("数据行2-${DateTime.nowUTC().toString()}")
                                .data("数据行3-${DateTime.nowUTC().toString()}")
                                .build()
                            println("向端点上所有连接发送消息->${message.toMessageString()}\n")
                            broker.send(message)
                    }
                )

                // 按请求参数过滤后发送
                let emitter = SseEmitter.getEmitter("/bus").getOrThrow()
                let message = MessageBuilder()
                    .data("给所有请求参数sse-tag=GA客户端的消息-${DateTime.nowUTC().toString()}")
                    .build()
                emitter.send(message, SseEmitter.defaultBrokerFilterByRequestParameterValue("sse-tag", "GA"))
        }
    )
}

func addExamplePage(httpServer: Server) {
    httpServer.distributor.register(
        "/hello",
        {
            context =>
                let body = StringBuilder()
                body.append("<html><head></head><body>test server send event!!!!<div id='msgbox'></div></body><script>")
                body.append("console.log('load sse ...');")
                body.append(
                    "const evtsource = new EventSource('http://127.0.0.1:8080/bus?clientId=clientId-1&sse-tag=user8080');")
                body.append("evtsource.onmessage = function(ctx) {console.log(ctx)};")
                body.append("evtsource.addEventListener('test-event', function(ctx) {")
                body.append("    console.log(ctx);")
                body.append("    const boxer = document.getElementById('msgbox');")
                body.append("    const p = document.createElement('p');")
                body.append("    p.innerText = ctx.lastEventId + ':' + ctx.data;")
                body.append("    boxer.appendChild(p);")
                body.append("});")
                body.append("</script></html>")
                context.responseBuilder.header("Content-Type", "text/html").body(body.toString().toArray())
        }
    )
}
```