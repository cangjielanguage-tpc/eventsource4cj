### 完整示例代码

```cangjie

package eventsource4jexample

import net.http.*
import std.time.*
import std.collection.*
import std.collection.ArrayList
import net.http.*
import std.log.*
import std.random.*
import std.sync.*
import std.time.*
import std.io.*
import std.collection.concurrent.*

import eventsource4cj.model.*
import eventsource4cj.server.*
import eventsource4cj.client.*


main(): Int64 {
    println("hello world")

    let x = spawn {
        serve()
    }


    let eventsource= EventSource("http://127.0.0.1:8080/bus", "user8080");    

    eventsource.onMessage({msg=>println("默认处理消息----------------->");println(msg.toMessageString())})

    eventsource.onEvent("test-event", {msg=>println("处理消息----------------->");println(msg.toMessageString())})

    eventsource.onEvent("test-event2", {msg=>println("处理消息22222----------------->");println(msg.toMessageString())})

    let future = eventsource.subscribe()

    future.get()

    return 0
}


func serve(): Int64 {
    println("hello eventsource4cj!!!")

    let sseServer = SseServer("127.0.0.1", 8080);

    sseServer.getHttpServer().logger.level = LogLevel.DEBUG

    let endpoint = "/bus";

    sseServer.publish(endpoint)

    sseServer.getHttpServer().distributor.register("/hello", {context => 
        let body = """
        <html><head></head><body>test server send event!!!!<div id='msgbox'></div></body><script>
        console.log('load sse ...');
        const evtsource = new EventSource('http://127.0.0.1:8080/bus?clientId=clientId-1&sse-tag=user8080');
        evtsource.onmessage = function(ctx) {console.log(ctx)};
        evtsource.addEventListener('test-event', function(ctx) {
            console.log(ctx);
            const boxer = document.getElementById('msgbox');
            const p = document.createElement('p');
            p.innerText = ctx.lastEventId + ':' + ctx.data;
            boxer.appendChild(p);
        })
        </script></html>
        """
        context.responseBuilder.header("Content-Type", "text/html").body(body.toArray())
    })

    

    let messageCount = AtomicInt64(0)
    Timer.repeat(0 * Duration.second, 5 * Duration.second, {=>
        let index = messageCount.fetchAdd(1);
        let message = MessageBuilder()
            .tag("user8080")
            .comment("注释123")
            .event("test-event")
            .id("id-${index + 1}")
            .retry(5000)
            .data("数据行1-${DateTime.nowUTC().toString()}")
            .data("数据行2-${DateTime.nowUTC().toString()}")
            .data("数据行3-${DateTime.nowUTC().toString()}")
            .build();
        println("add message-------------${message.toMessageString()}\n")

        let message2 = MessageBuilder()
            .tag("user8080")
            .comment("注释99999999999999")
            .event("test-event2")
            .id("id-${index + 1}")
            .retry(15000)
            .data("2-数据行1-${DateTime.nowUTC().toString()}")
            .data("2-数据行2-${DateTime.nowUTC().toString()}")
            .data("2-数据行3-${DateTime.nowUTC().toString()}")
            .build();
        println("add message2-------------${message.toMessageString()}\n")

        let emitter = SseEmitter.getEmitter(endpoint).getOrThrow();

        // 按TAG发送
        emitter.sendByTag(message)
        emitter.sendByTag(message2)

        let message3 = MessageBuilder().data("默认消息>>>>>>>>${DateTime.nowUTC().toString()}").build()
        emitter.sendAll(message3)

        // 按请求参数发送
        // let clientIdName = "clientId"
        // let sendToClientId = "clientId-1"
        // emitter.sendByRequestParameter(message, clientIdName, sendToClientId)
    })

    sseServer.serveForever()

    return 0
}

```