## ssehybrid 库

### 介绍
该库是基于 eventsource4cj 库封装的 ArkTS 互操作接口库，提供符合 Server-Sent Events (SSE) 协议的客户端实现。支持 GET/POST 请求、自定义请求头、请求体压缩（GZIP/Brotli）、响应解压缩等功能，可从 ArkTS/ETS 环境直接调用。

前置条件：NA

场景：
1. 在 ArkTS/ETS 环境中建立 SSE 连接并接收服务器推送的事件流。
2. 支持 GET 和 POST 两种请求方式。
3. 支持请求体压缩（GZIP/Brotli）和响应解压缩。
4. 支持自定义请求头和事件处理器。

约束：NA

可靠性：NA

### 1. 构造函数

#### 1.1 主要接口

```typescript
export declare class EventSource {
    /*
     * 初始化 SSE 客户端，用于 GET 请求
     * 
     * 参数 url - SSE 服务器端点 URL
     */
    constructor(url: string)

    /*
     * 初始化 SSE 客户端，用于 POST 请求（字符串请求体）
     * 
     * 参数 url - SSE 服务器端点 URL
     * 参数 body - POST 请求体内容（字符串）
     */
    constructor(url: string, body: string)

    /*
     * 初始化 SSE 客户端，用于 POST 请求（ArrayBuffer 请求体）
     * 
     * 参数 url - SSE 服务器端点 URL
     * 参数 body - POST 请求体内容（ArrayBuffer）
     */
    constructor(url: string, body: ArrayBuffer)
}
```

#### 1.2 示例

代码如下：

```typescript
import { EventSource } from 'libsse'

// GET 请求方式
let es = new EventSource("http://192.168.8.8:9000/sse/range/1/5/1000")

// POST 请求方式（字符串请求体）
let esPost = new EventSource("http://192.168.8.8:9000/sse/post/range/1/5/1000", "{\"key\":\"value\"}")

// POST 请求方式（ArrayBuffer 请求体）
let encoder = new TextEncoder()
let bytes = encoder.encode("test data")
let esBytes = new EventSource("http://192.168.8.8:9000/sse/post/range/1/5/1000", bytes.buffer)
```

### 2. 请求体设置

#### 2.1 主要接口

```typescript
export declare class EventSource {
    /*
     * 设置字符串类型的请求体
     * 
     * 参数 body - 请求体内容
     */
    setBody(body: string): void

    /*
     * 设置 ArrayBuffer 类型的请求体
     * 
     * 参数 body - 请求体内容
     */
    setBody(body: ArrayBuffer): void

    /*
     * 清除请求体
     */
    clearBody(): void
}
```

#### 2.2 示例

代码如下：

```typescript
import { EventSource } from 'libsse'

let es = new EventSource("http://192.168.8.8:9000/sse/post/range/1/5/1000")

// 设置字符串请求体
es.setBody("{\"query\":\"test\"}")

// 或设置 ArrayBuffer 请求体
let encoder = new TextEncoder()
es.setBody(encoder.encode("test data").buffer)

// 清除请求体
es.clearBody()
```

### 3. 请求体压缩设置

#### 3.1 主要接口

```typescript
export declare class EventSource {
    /*
     * 设置请求体压缩类型
     * 
     * 参数 compress - 压缩类型：0=不压缩，1=GZIP，2=Brotli
     */
    setRequestBodyCompressType(compress: number): void

    /*
     * 获取请求体压缩类型
     * 
     * 返回值 number - 压缩类型：0=不压缩，1=GZIP，2=Brotli
     */
    getRequestBodyCompressType(): number
}
```

#### 3.2 示例

代码如下：

```typescript
import { EventSource } from 'libsse'

let es = new EventSource("http://192.168.8.8:9000/sse/brotli-response/post/1/5/1000", "{\"data\":\"test\"}")

// 设置请求体使用 Brotli 压缩
es.setRequestBodyCompressType(2)

// 获取当前压缩类型
let compressType = es.getRequestBodyCompressType() // 返回 2
```

### 4. 响应压缩设置

#### 4.1 主要接口

```typescript
export declare class EventSource {
    /*
     * 设置接受的响应压缩类型（Accept-Encoding 头）
     * 
     * 参数 compress - 压缩类型：0=不设置，1=GZIP，2=Brotli，3=GZIP+Brotli
     */
    setAcceptCompressType(compress: number): void

    /*
     * 获取接受的响应压缩类型
     * 
     * 返回值 number - 压缩类型：0=不设置，1=GZIP，2=Brotli，3=GZIP+Brotli
     */
    getAcceptCompressType(): number
}
```

#### 4.2 示例

代码如下：

```typescript
import { EventSource } from 'libsse'

let es = new EventSource("http://192.168.8.8:9000/sse/gzip-response/test/1/5/1000")

// 设置接受 GZIP 压缩响应
es.setAcceptCompressType(1)

// 设置同时接受 GZIP 和 Brotli 压缩响应
es.setAcceptCompressType(3)

// 获取当前设置
let acceptType = es.getAcceptCompressType()
```

### 5. 自定义请求头设置

#### 5.1 主要接口

```typescript
export declare class EventSource {
    /*
     * 设置单个自定义请求头
     * 
     * 参数 name - 请求头名称
     * 参数 value - 请求头值
     */
    setHeader(name: string, value: string): void

    /*
     * 批量设置自定义请求头
     * 
     * 参数 headers - 请求头键值对对象
     */
    setHeaders(headers: Record<string, string>): void

    /*
     * 移除指定的请求头
     * 
     * 参数 name - 请求头名称
     */
    removeHeader(name: string): void

    /*
     * 清除所有自定义请求头
     */
    clearHeaders(): void
}
```

#### 5.2 示例

代码如下：

```typescript
import { EventSource } from 'libsse'

let es = new EventSource("http://192.168.8.8:9000/sse/secure/range/1/5/1000")

// 设置单个请求头
es.setHeader("X-Auth-Token", "my-secret-token")
es.setHeader("X-Client-Id", "client-001")
es.setHeader("Content-Type", "application/json")

// 批量设置请求头
es.setHeaders({
    "X-Custom-1": "value1",
    "X-Custom-2": "value2"
})

// 移除单个请求头
es.removeHeader("X-Custom-1")

// 清除所有自定义请求头
es.clearHeaders()
```

### 6. 事件处理器设置

#### 6.1 主要接口

```typescript
export declare class EventSource {
    /*
     * 设置默认消息处理器，处理没有事件类型的消息
     * 
     * 参数 handler - 消息处理函数
     */
    onMessage(handler: (msg: Message) => void): void

    /*
     * 设置指定事件类型的处理器
     * 
     * 参数 event - 事件类型名称
     * 参数 handler - 消息处理函数
     */
    onEvent(event: string, handler: (msg: Message) => void): void

    /*
     * 设置异常处理器
     * 
     * 参数 handler - 异常处理函数，接收异常消息字符串和相关数据
     */
    setExceptionHandler(handler: (exception: string, buffer: ArrayBuffer) => void): void
}
```

#### 6.2 示例

代码如下：

```typescript
import { EventSource, Message } from 'libsse'
import hilog from '@ohos.hilog'

let es = new EventSource("http://192.168.8.8:9000/sse/range/1/5/1000")

// 设置默认消息处理器
es.onMessage((msg: Message) => {
    hilog.info(0, "SSE", "Received: %{public}s", msg.data ?? "")
})

// 设置特定事件类型的处理器
es.onEvent("range", (msg: Message) => {
    hilog.info(0, "SSE", "Range event: %{public}s", msg.data ?? "")
})

// 设置异常处理器
es.setExceptionHandler((exception: string, buffer: ArrayBuffer) => {
    hilog.error(0, "SSE", "Error: %{public}s", exception)
})
```

### 7. 订阅连接

#### 7.1 主要接口

```typescript
export declare class EventSource {
    /*
     * 启动 SSE 连接订阅，异步执行
     * 
     * 返回值 Promise<void> - 异步 Promise 对象
     */
    subscribe(): Promise<void>
}
```

#### 7.2 示例

代码如下：

```typescript
import { EventSource, Message } from 'libsse'
import hilog from '@ohos.hilog'

let es = new EventSource("http://192.168.8.8:9000/sse/range/1/10/1000")

let count = 0
es.onMessage((msg: Message) => {
    count++
    hilog.info(0, "SSE", "Message %{public}d: %{public}s", count, msg.data ?? "")
    if (count >= 10) {
        // 处理完成
    }
})

// 启动订阅
es.subscribe()
```

### 8. Message 消息对象

#### 8.1 主要接口

```typescript
export declare interface Message {
    /* 消息标签 */
    messageTag: string | undefined

    /* 事件类型 */
    eventType: string | undefined

    /* 消息 ID */
    msgId: string | undefined

    /* 数据行数组 */
    dataLines: Array<string>

    /* 消息数据（多行数据合并后的字符串） */
    data: string | undefined

    /* 重连间隔时间（毫秒） */
    retryInMills: number | undefined

    /* 消息的字符串表示 */
    toMessageString: string | undefined
}
```

#### 8.2 示例

代码如下：

```typescript
import { Message } from 'libsse'

function handleMessage(msg: Message): void {
    // 获取事件类型
    if (msg.eventType) {
        console.log(`Event type: ${msg.eventType}`)
    }

    // 获取消息数据
    if (msg.data) {
        console.log(`Data: ${msg.data}`)
    }

    // 获取数据行数组
    for (let line of msg.dataLines) {
        console.log(`Data line: ${line}`)
    }

    // 获取消息 ID（用于断线重连）
    if (msg.msgId) {
        console.log(`Message ID: ${msg.msgId}`)
    }

    // 获取重连间隔
    if (msg.retryInMills) {
        console.log(`Retry interval: ${msg.retryInMills}ms`)
    }

    // 获取完整消息字符串
    if (msg.toMessageString) {
        console.log(`Full message: ${msg.toMessageString}`)
    }
}
```

### 9. 完整示例
以下示例演示在 ETS 页面中使用 Brotli 压缩请求体并携带自定义请求头的 POST 请求：

```typescript
import { EventSource, Message } from 'libsse'
import hilog from '@ohos.hilog'

@Entry
@Component
struct SseTestPage {
  @State message: string = ''

  build() {
    Column() {
      Button('Start SSE with Brotli')
        .onClick(() => this.startSseBrotliWithHeaders())
      
      Text(this.message)
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
  }

  startSseBrotliWithHeaders(): void {
    let url = "http://192.168.8.8:9000/sse/brotli-response/post/2/5/1000"
    
    // 创建带请求体的 EventSource
    let requestBody = JSON.stringify({
        query: 'secure brotli data',
        clientType: 'arkts'
    })
    let es = new EventSource(url, requestBody)
    
    // 启用 Brotli 压缩
    es.setRequestBodyCompressType(2)
    
    // 设置自定义请求头
    es.setHeader("X-Auth-Token", "my-secret-token-12345")
    es.setHeader("X-Client-Id", "arkts-brotli-client")
    es.setHeader("Content-Type", "application/json")
    
    // 设置消息处理器
    let count = 0
    es.onMessage((msg: Message) => {
        count++
        hilog.info(0, "SSE", "Brotli msg %{public}d: %{public}s", count, msg.data ?? "")
        this.message = `Received ${count} messages`
    })
    
    // 设置异常处理器
    es.setExceptionHandler((exception: string, buffer: ArrayBuffer) => {
        hilog.error(0, "SSE", "Error: %{public}s", exception)
        this.message = `Error: ${exception}`
    })
    
    // 启动订阅
    es.subscribe()
  }
}
```

运行结果如下：

```
Brotli msg 1: 5-1|body:{"query":"secure brotli data","clientType":"arkts"}
Brotli msg 2: 5-2|body:{"query":"secure brotli data","clientType":"arkts"}
...
```
