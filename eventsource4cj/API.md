# eventsource4cj API

本文按 `libs_stdx` 文档风格说明本项目公开 API。Cangjie API 来自 `eventsource4cj` 包；ArkTS API 来自 `ssehybrid` 导出的 `libsse` 声明。

## eventsource4cj.client

### class EventSource

```cangjie
public class EventSource {}
```

功能：SSE 客户端。支持建立 GET/POST SSE 连接，设置超时、请求头、请求体、请求体压缩、响应解压缩、事件回调、异常回调、断线重试和关闭连接。

#### init(String, Int64, Int64, Int64, Int64)

```cangjie
public init(url: String, connectTimeoutMs!: Int64 = -1, readTimeoutMs!: Int64 = -1, writeTimeoutMs!: Int64 = -1, bufferSize!: Int64 = DEFAULT_BUFFER_SIZE)
```

功能：创建 SSE 客户端实例。

参数：

- url: String - SSE 服务端地址。
- connectTimeoutMs!: Int64 - 建连超时时间，单位毫秒；小于等于 0 时不设置连接超时。
- readTimeoutMs!: Int64 - 读超时时间，单位毫秒；小于等于 0 时使用库内默认长超时。
- writeTimeoutMs!: Int64 - 写超时时间，单位毫秒；小于等于 0 时使用库内默认长超时。
- bufferSize!: Int64 - 响应流读取缓冲区大小，默认 8KB。

示例：

```cangjie
let es = EventSource("http://127.0.0.1:9000/sse/range/1/5/1000", connectTimeoutMs: 3000, readTimeoutMs: 30000, writeTimeoutMs: 3000)
```

#### func setBody(String)

```cangjie
public func setBody(body: String): Unit
```

功能：设置字符串请求体。设置后订阅请求会使用 POST。

参数：

- body: String - 请求体文本。

示例：

```cangjie
es.setBody("{\"query\":\"test\"}")
```

#### func setBody(Array\<UInt8>)

```cangjie
public func setBody(body: Array<UInt8>): Unit
```

功能：设置字节数组请求体。适合发送二进制或已编码文本，设置后订阅请求会使用 POST。

参数：

- body: Array\<UInt8> - 请求体字节数组。

示例：

```cangjie
es.setBody("hello".toArray())
```

#### func clearBody()

```cangjie
public func clearBody(): Unit
```

功能：清除请求体。清除后订阅请求使用 GET。

#### func setRetry(Duration, Int64)

```cangjie
public func setRetry(interval: Duration, count: Int64): Unit
```

功能：设置连接失败后的重试间隔和重试次数。

参数：

- interval: Duration - 每次重试前等待的时间。
- count: Int64 - 最大重试次数。

示例：

```cangjie
es.setRetry(Duration.millisecond * 500, 3)
```

#### func setRequestCompressType(Int64)

```cangjie
public func setRequestCompressType(compress: Int64): Unit
```

功能：设置请求体压缩类型，并在请求中写入对应 `Content-Encoding`。

参数：

- compress: Int64 - `0` 表示不压缩，`1` 表示 gzip，`2` 表示 br。

#### func getRequestCompressType()

```cangjie
public func getRequestCompressType(): Int64
```

功能：获取当前请求体压缩类型。

返回值：

- Int64 - `0` 表示不压缩，`1` 表示 gzip，`2` 表示 br。

#### func setAcceptCompressType(Int64)

```cangjie
public func setAcceptCompressType(compress: Int64): Unit
```

功能：设置客户端可接受的响应压缩类型，并生成 `Accept-Encoding` 请求头。

参数：

- compress: Int64 - `0` 不设置，`1` 表示 gzip，`2` 表示 br，`3` 表示 gzip 和 br。

#### func getAcceptCompressType()

```cangjie
public func getAcceptCompressType(): Int64
```

功能：获取当前响应压缩配置。

返回值：

- Int64 - `0` 不设置，`1` 表示 gzip，`2` 表示 br，`3` 表示 gzip 和 br。

#### func setHeader(String, String)

```cangjie
public func setHeader(name: String, value: String): Unit
```

功能：设置单个自定义请求头。重复设置同名 header 时按底层 `HttpHeaders` 行为追加或覆盖。

参数：

- name: String - 请求头名称。
- value: String - 请求头值。

#### func setHeaders(HashMap\<String, String>)

```cangjie
public func setHeaders(headers: HashMap<String, String>): Unit
```

功能：批量设置自定义请求头。

参数：

- headers: HashMap\<String, String> - 请求头键值对。

#### func removeHeader(String)

```cangjie
public func removeHeader(name: String): Unit
```

功能：移除指定名称的自定义请求头。

参数：

- name: String - 待移除的请求头名称。

#### func clearHeaders()

```cangjie
public func clearHeaders(): Unit
```

功能：清除所有自定义请求头。

#### func setExceptionHandler((Exception, Array\<UInt8>) -> Unit)

```cangjie
public func setExceptionHandler(handler: (Exception, Array<UInt8>) -> Unit): Unit
```

功能：设置异常处理函数。连接失败、响应类型错误或消息解析失败时调用。

参数：

- handler: (Exception, Array\<UInt8>) -> Unit - 第一个参数是异常对象，第二个参数是相关原始字节；没有原始数据时为空数组。

#### func onMessage((Message) -> Unit)

```cangjie
public func onMessage(handler: (Message) -> Unit): Unit
```

功能：设置默认消息回调。未命中特定事件回调的消息会进入该回调。

参数：

- handler: (Message) -> Unit - 消息处理函数。

#### func onEvent(String, (Message) -> Unit)

```cangjie
public func onEvent(event: String, handler: (Message) -> Unit): Unit
```

功能：设置指定事件类型的消息回调。仅当消息的 `event` 字段等于 `event` 参数时触发。

参数：

- event: String - SSE 事件类型。
- handler: (Message) -> Unit - 事件消息处理函数。

#### func subscribe()

```cangjie
public func subscribe(): Future<Unit>
```

功能：异步启动 SSE 订阅。方法内部创建任务连接服务端并持续读取事件流。

返回值：

- Future\<Unit> - 订阅任务。

异常：

- Exception - 连接、响应校验、解压或解析过程中发生异常时，任务可能结束并触发异常处理函数。

示例：

```cangjie
es.onMessage({ msg => println(msg.data.getOrDefault({ => "" })) })
let future = es.subscribe()
```

#### func close()

```cangjie
public func close(): Unit
```

功能：取消订阅任务。页面销毁或业务不再需要接收事件时调用。

## eventsource4cj.model

### struct Message

```cangjie
public struct Message {}
```

功能：表示一条 SSE 消息。包含 `event`、`id`、`retry`、注释、多行 `data` 和扩展字段。

#### prop extention

```cangjie
public prop extention: MessageExtend
```

功能：获取扩展字段对象。

返回值：

- MessageExtend - 消息扩展字段。

#### prop eventType

```cangjie
public prop eventType: Option<String>
```

功能：获取 SSE `event` 字段。

返回值：

- Option\<String> - 有事件类型时为 `Some(event)`，否则为 `None`。

#### prop msgId

```cangjie
public prop msgId: Option<String>
```

功能：获取 SSE `id` 字段。客户端重连时会将该值作为 `Last-Event-ID` 使用。

返回值：

- Option\<String> - 有消息 ID 时为 `Some(id)`，否则为 `None`。

#### prop dataLines

```cangjie
public prop dataLines: ArrayList<String>
```

功能：获取所有 `data` 行。

返回值：

- ArrayList\<String> - 数据行列表。

#### prop data

```cangjie
public prop data: Option<String>
```

功能：获取第一行 `data`。

返回值：

- Option\<String> - 有数据时返回第一行数据，否则返回 `None`。

#### prop retryInMills

```cangjie
public prop retryInMills: Option<UInt16>
```

功能：获取 SSE `retry` 字段，单位毫秒。

返回值：

- Option\<UInt16> - 存在 retry 字段时返回重试间隔，否则返回 `None`。

#### func toMessageString()

```cangjie
public func toMessageString(): String
```

功能：将消息序列化为符合 SSE 协议的文本。输出包含字段行和结尾空行。

返回值：

- String - SSE 协议文本。

示例：

```cangjie
let msg = MessageBuilder().event("notice").id("1").data("hello").build()
println(msg.toMessageString())
```

### class MessageExtend

```cangjie
public class MessageExtend {}
```

功能：保存消息扩展属性。

#### init()

```cangjie
public init()
```

功能：创建空扩展对象。

#### prop messageTag

```cangjie
public prop messageTag: Option<String>
```

功能：获取业务标签。该值由 `MessageBuilder.tag` 设置。

返回值：

- Option\<String> - 有标签时返回 `Some(tag)`，否则返回 `None`。

### class MessageBuilder

```cangjie
public class MessageBuilder {}
```

功能：链式构建 SSE 消息，或将原始 SSE 字节解析为 `Message`。

#### init()

```cangjie
public init()
```

功能：创建空消息构建器。

#### func tag(String)

```cangjie
public func tag(tag: String): MessageBuilder
```

功能：设置扩展业务标签。

参数：

- tag: String - 业务标签。

返回值：

- MessageBuilder - 当前构建器，支持链式调用。

#### func event(String)

```cangjie
public func event(envent: String): MessageBuilder
```

功能：设置 SSE `event` 字段。

参数：

- envent: String - 事件类型。参数名来自当前源码。

返回值：

- MessageBuilder - 当前构建器。

#### func id(String)

```cangjie
public func id(id: String): MessageBuilder
```

功能：设置 SSE `id` 字段。

参数：

- id: String - 消息 ID。

返回值：

- MessageBuilder - 当前构建器。

#### func retry(UInt16)

```cangjie
public func retry(retry: UInt16): MessageBuilder
```

功能：设置 SSE `retry` 字段。

参数：

- retry: UInt16 - 重试间隔，单位毫秒。

返回值：

- MessageBuilder - 当前构建器。

#### func comment(String)

```cangjie
public func comment(comment: String): MessageBuilder
```

功能：设置 SSE 注释行。序列化后以 `:` 开头。

参数：

- comment: String - 注释内容。

返回值：

- MessageBuilder - 当前构建器。

#### func data(String)

```cangjie
public func data(data: String): MessageBuilder
```

功能：追加一行 SSE `data` 字段。多次调用会生成多行 `data`。

参数：

- data: String - 数据内容。

返回值：

- MessageBuilder - 当前构建器。

#### func build()

```cangjie
public func build(): Message
```

功能：根据已设置字段创建 `Message`。

返回值：

- Message - 构建完成的消息。

#### static func resolve(Array\<UInt8>)

```cangjie
public static func resolve(messageBody: Array<UInt8>): Message
```

功能：将 UTF-8 SSE 协议字节解析为 `Message`。

参数：

- messageBody: Array\<UInt8> - SSE 消息字节。

返回值：

- Message - 解析得到的消息。非 UTF-8 输入会返回空消息。

异常：

- Exception - `retry` 字段无法转换为 `UInt16` 等解析错误可能抛出异常。

示例：

```cangjie
let msg = MessageBuilder()
    .event("update")
    .id("42")
    .data("payload")
    .build()
let parsed = MessageBuilder.resolve(msg.toMessageString().toArray())
```

## eventsource4cj.server

### class SseServer

```cangjie
public class SseServer {}
```

功能：SSE 服务端入口。用于创建或包装 HTTP Server，发布 SSE endpoint，并控制服务启动和关闭。

#### init(String, UInt16)

```cangjie
public init(address: String, port: UInt16)
```

功能：按地址和端口创建内部 HTTP Server。

参数：

- address: String - 监听地址。
- port: UInt16 - 监听端口。

#### init(Server)

```cangjie
public init(server: Server)
```

功能：使用已有 HTTP Server 创建 SSE 服务端。

参数：

- server: Server - 已创建的 HTTP Server。

#### func getHttpServer()

```cangjie
public func getHttpServer(): Server
```

功能：获取底层 HTTP Server。

返回值：

- Server - 当前 SSE 服务端持有的 HTTP Server。

#### func serveForever()

```cangjie
public func serveForever(): Unit
```

功能：启动 HTTP Server 并阻塞等待。内部会保存服务任务，便于 `terminate` 取消。

#### func terminate()

```cangjie
public func terminate(): Unit
```

功能：取消服务任务并优雅关闭底层 HTTP Server。

#### func publish(String)

```cangjie
public func publish(endpoint: String): SseEmitter
```

功能：发布 SSE endpoint，并接受所有客户端连接。

参数：

- endpoint: String - SSE 路由，如 `"/events"`。

返回值：

- SseEmitter - 当前 endpoint 的消息发送器。

#### func publish(String, (SseEmitterBroker) -> Bool)

```cangjie
public func publish(endpoint: String, clientConnectedHandler: (SseEmitterBroker) -> Bool): SseEmitter
```

功能：发布 SSE endpoint，并在每个客户端连接建立时执行校验或初始化逻辑。

参数：

- endpoint: String - SSE 路由。
- clientConnectedHandler: (SseEmitterBroker) -> Bool - 连接处理函数。返回 `true` 表示接受连接，返回 `false` 表示拒绝连接。

返回值：

- SseEmitter - 当前 endpoint 的消息发送器。

异常：

- Exception - 连接处理函数返回 `false` 时抛出异常，当前连接不会继续服务。

示例：

```cangjie
let server = SseServer("127.0.0.1", 8080)
let emitter = server.publish("/events", {
    broker => broker.httpContext.request.headers.getFirst("token").isSome()
})
emitter.sendAll(MessageBuilder().event("ready").data("ok").build())
server.serveForever()
```

### class SseEmitter

```cangjie
public class SseEmitter {}
```

功能：指定 endpoint 的消息发送器。负责向已连接客户端广播或按条件发送消息。

#### func sendAll(Message)

```cangjie
public func sendAll(message: Message): Unit
```

功能：向当前 endpoint 下所有连接发送消息。

参数：

- message: Message - 要发送的 SSE 消息。

#### func send(Message, (SseEmitterBroker) -> Bool)

```cangjie
public func send(message: Message, brokerFilter: (SseEmitterBroker) -> Bool): Unit
```

功能：向满足过滤条件的连接发送消息。

参数：

- message: Message - 要发送的 SSE 消息。
- brokerFilter: (SseEmitterBroker) -> Bool - 连接过滤函数，返回 `true` 的连接会收到消息。

#### static func getEmitter(String)

```cangjie
public static func getEmitter(endpoint: String): Option<SseEmitter>
```

功能：根据 endpoint 获取已创建的发送器。

参数：

- endpoint: String - SSE 路由。

返回值：

- Option\<SseEmitter> - endpoint 已发布时返回发送器，否则返回 `None`。

#### static func defaultBrokerFilterByRequestParameterValue(String, String)

```cangjie
public static func defaultBrokerFilterByRequestParameterValue(parameterName: String, parameterValue: String): (SseEmitterBroker) -> Bool
```

功能：创建按请求参数值过滤连接的函数。过滤器会读取 `broker.httpContext.request.form` 中的参数。

参数：

- parameterName: String - 请求参数名称。
- parameterValue: String - 期望的请求参数值。

返回值：

- (SseEmitterBroker) -> Bool - 可传入 `send` 的过滤函数。

示例：

```cangjie
let filter = SseEmitter.defaultBrokerFilterByRequestParameterValue("group", "A")
let msg = MessageBuilder().event("notice").data("hello").build()
emitter.send(msg, filter)
```

### class SseEmitterBroker

```cangjie
public class SseEmitterBroker {}
```

功能：表示一个 SSE 客户端连接。服务端可通过它读取请求上下文、获取 `Last-Event-ID`，或向单个连接发送消息。

#### init(String, HttpContext)

```cangjie
public init(endpoint: String, context: HttpContext)
```

功能：创建连接代理。通常由 `SseServer.publish` 内部创建，业务代码不需要手动构造。

参数：

- endpoint: String - 当前连接所属 endpoint。
- context: HttpContext - 当前 HTTP 请求上下文。

#### prop httpContext

```cangjie
public prop httpContext: HttpContext
```

功能：获取当前连接的 HTTP 上下文。

返回值：

- HttpContext - 请求和响应上下文。

#### prop lastEventId

```cangjie
public prop lastEventId: Option<String>
```

功能：获取请求头 `Last-Event-ID`。

返回值：

- Option\<String> - 请求携带该头时返回值，否则返回 `None`。

#### func send(Message)

```cangjie
public func send(message: Message): Unit
```

功能：向当前单个连接发送消息。

参数：

- message: Message - 要发送的 SSE 消息。

## eventsource4cj.util

### class GzipUtil

```cangjie
public class GzipUtil {}
```

功能：GZIP 压缩和解压工具。

#### static func compress(Array\<UInt8>)

```cangjie
public static func compress(data: Array<UInt8>): Array<UInt8>
```

功能：将字节数组压缩为 GZIP 格式。空数组直接返回空数组。

参数：

- data: Array\<UInt8> - 待压缩数据。

返回值：

- Array\<UInt8> - GZIP 压缩后的字节数组。

#### static func decompress(Array\<UInt8>)

```cangjie
public static func decompress(data: Array<UInt8>): Array<UInt8>
```

功能：解压 GZIP 字节数组。

参数：

- data: Array\<UInt8> - GZIP 数据。

返回值：

- Array\<UInt8> - 解压后的字节数组。

异常：

- Exception - 数据长度过短或 GZIP magic number 不正确时抛出异常。

#### static func isGzip(Array\<UInt8>)

```cangjie
public static func isGzip(data: Array<UInt8>): Bool
```

功能：判断字节数组是否以 GZIP magic number 开头。

参数：

- data: Array\<UInt8> - 待检测数据。

返回值：

- Bool - 是 GZIP 数据返回 `true`，否则返回 `false`。

#### static func compressString(String)

```cangjie
public static func compressString(str: String): Array<UInt8>
```

功能：将字符串按 UTF-8 字节压缩为 GZIP 数据。

参数：

- str: String - 待压缩字符串。

返回值：

- Array\<UInt8> - GZIP 数据。

#### static func decompressToString(Array\<UInt8>)

```cangjie
public static func decompressToString(data: Array<UInt8>): String
```

功能：解压 GZIP 数据并按 UTF-8 转为字符串。

参数：

- data: Array\<UInt8> - GZIP 数据。

返回值：

- String - 解压后的字符串。

示例：

```cangjie
let compressed = GzipUtil.compressString("hello")
let text = GzipUtil.decompressToString(compressed)
```

### class BrotliUtil

```cangjie
public class BrotliUtil {}
```

功能：Brotli 压缩和解压工具。

#### static func compress(Array\<UInt8>)

```cangjie
public static func compress(data: Array<UInt8>): Array<UInt8>
```

功能：使用默认参数压缩字节数组。空数组直接返回空数组。

参数：

- data: Array\<UInt8> - 待压缩数据。

返回值：

- Array\<UInt8> - Brotli 压缩后的字节数组。

#### static func compress(Array\<UInt8>, Int64)

```cangjie
public static func compress(data: Array<UInt8>, quality: Int64): Array<UInt8>
```

功能：按指定质量参数压缩字节数组。

参数：

- data: Array\<UInt8> - 待压缩数据。
- quality: Int64 - 压缩质量，通常取 `0..11`；值越高通常压缩率越高、耗时越长。

返回值：

- Array\<UInt8> - Brotli 压缩后的字节数组。

#### static func decompress(Array\<UInt8>)

```cangjie
public static func decompress(data: Array<UInt8>): Array<UInt8>
```

功能：解压 Brotli 字节数组。

参数：

- data: Array\<UInt8> - Brotli 数据。

返回值：

- Array\<UInt8> - 解压后的字节数组。

#### static func isBrotli(Array\<UInt8>)

```cangjie
public static func isBrotli(data: Array<UInt8>): Bool
```

功能：启发式判断字节数组是否可能为 Brotli 数据。Brotli 没有固定 magic number，因此该函数不能保证数据一定可解压。

参数：

- data: Array\<UInt8> - 待检测数据。

返回值：

- Bool - 可能为 Brotli 且不是 GZIP 时返回 `true`，否则返回 `false`。

#### static func compressString(String)

```cangjie
public static func compressString(str: String): Array<UInt8>
```

功能：将字符串按 UTF-8 字节压缩为 Brotli 数据。

参数：

- str: String - 待压缩字符串。

返回值：

- Array\<UInt8> - Brotli 数据。

#### static func decompressToString(Array\<UInt8>)

```cangjie
public static func decompressToString(data: Array<UInt8>): String
```

功能：解压 Brotli 数据并按 UTF-8 转为字符串。

参数：

- data: Array\<UInt8> - Brotli 数据。

返回值：

- String - 解压后的字符串。

示例：

```cangjie
let compressed = BrotliUtil.compress("hello".toArray(), 4)
let text = BrotliUtil.decompressToString(compressed)
```

## ssehybrid ArkTS API

### interface Message

```typescript
export declare interface Message {
  messageTag: string | undefined
  eventType: string | undefined
  msgId: string | undefined
  dataLines: Array<string>
  data: string | undefined
  retryInMills: number | undefined
  toMessageString: string | undefined
}
```

功能：ArkTS 侧接收的 SSE 消息对象。

#### prop messageTag

```typescript
messageTag: string | undefined
```

功能：消息扩展业务标签。

#### prop eventType

```typescript
eventType: string | undefined
```

功能：SSE `event` 字段。

#### prop msgId

```typescript
msgId: string | undefined
```

功能：SSE `id` 字段。

#### prop dataLines

```typescript
dataLines: Array<string>
```

功能：所有 `data` 行。

#### prop data

```typescript
data: string | undefined
```

功能：第一行 `data`。

#### prop retryInMills

```typescript
retryInMills: number | undefined
```

功能：SSE `retry` 字段，单位毫秒。

#### prop toMessageString

```typescript
toMessageString: string | undefined
```

功能：消息的 SSE 协议文本。

### class EventSource

```typescript
export declare class EventSource {}
```

功能：ArkTS 侧 SSE 客户端。该类通过 hybrid 层调用 Cangjie `EventSource`。

#### constructor(String, Number, Number, Number)

```typescript
constructor(url: string, connectTimeoutMs: number, readTimeoutMs: number, writeTimeoutMs: number)
```

功能：创建 ArkTS SSE 客户端。

参数：

- url: string - SSE 服务端地址。
- connectTimeoutMs: number - 建连超时时间，单位毫秒；`-1` 表示不设置。
- readTimeoutMs: number - 读超时时间，单位毫秒；`-1` 表示使用默认值。
- writeTimeoutMs: number - 写超时时间，单位毫秒；`-1` 表示使用默认值。

#### onMessage((Message) => void)

```typescript
onMessage(handler: (msg: Message) => void): void
```

功能：设置默认消息回调。

参数：

- handler: (msg: Message) => void - 消息处理函数。

#### onEvent(String, (Message) => void)

```typescript
onEvent(event: string, handler: (msg: Message) => void): void
```

功能：设置指定事件类型的消息回调。

参数：

- event: string - SSE 事件类型。
- handler: (msg: Message) => void - 事件消息处理函数。

#### setExceptionHandler((String, ArrayBuffer) => void)

```typescript
setExceptionHandler(handler: (exception: string, buffer: ArrayBuffer) => void): void
```

功能：设置异常处理函数。

参数：

- handler: (exception: string, buffer: ArrayBuffer) => void - `exception` 是异常字符串，`buffer` 是相关原始字节。

#### subscribe()

```typescript
subscribe(): Promise<void>
```

功能：启动 SSE 订阅。

返回值：

- Promise\<void> - 订阅任务对应的 Promise。

#### close()

```typescript
close(): void
```

功能：取消当前订阅任务。

#### setHeader(String, String)

```typescript
setHeader(name: string, value: string): void
```

功能：设置单个自定义请求头。

参数：

- name: string - 请求头名称。
- value: string - 请求头值。

#### setHeaders(Record\<String, String>)

```typescript
setHeaders(headers: Record<string, string>): void
```

功能：批量设置自定义请求头。

参数：

- headers: Record\<string, string> - 请求头键值对。

#### removeHeader(String)

```typescript
removeHeader(name: string): void
```

功能：移除指定请求头。

参数：

- name: string - 请求头名称。

#### clearHeaders()

```typescript
clearHeaders(): void
```

功能：清除全部自定义请求头。

#### setBody(String)

```typescript
setBody(body: string): void
```

功能：设置字符串请求体。设置后订阅请求使用 POST。

参数：

- body: string - 请求体文本。

#### setBody(ArrayBuffer)

```typescript
setBody(body: ArrayBuffer): void
```

功能：设置字节请求体。设置后订阅请求使用 POST。

参数：

- body: ArrayBuffer - 请求体字节。

#### clearBody()

```typescript
clearBody(): void
```

功能：清除请求体。清除后订阅请求使用 GET。

#### setRequestBodyCompressType(Number)

```typescript
setRequestBodyCompressType(compress: number): void
```

功能：设置请求体压缩类型。

参数：

- compress: number - `0` 表示不压缩，`1` 表示 gzip，`2` 表示 br。

#### getRequestBodyCompressType()

```typescript
getRequestBodyCompressType(): number
```

功能：获取请求体压缩类型。

返回值：

- number - `0` 表示不压缩，`1` 表示 gzip，`2` 表示 br。

#### setAcceptCompressType(Number)

```typescript
setAcceptCompressType(compress: number): void
```

功能：设置响应压缩接受类型。

参数：

- compress: number - `0` 不设置，`1` 表示 gzip，`2` 表示 br，`3` 表示 gzip 和 br。

#### getAcceptCompressType()

```typescript
getAcceptCompressType(): number
```

功能：获取响应压缩接受类型。

返回值：

- number - `0` 不设置，`1` 表示 gzip，`2` 表示 br，`3` 表示 gzip 和 br。

示例：

```typescript
import { EventSource } from 'libsse'

const es = new EventSource('http://192.168.8.8:9000/sse/range/1/5/1000', 3000, 30000, 3000)
es.setHeader('Authorization', 'Bearer token')
es.setAcceptCompressType(3)
es.onMessage((msg) => {
  console.info(msg.data ?? '')
})
es.setExceptionHandler((exception, buffer) => {
  console.error(exception)
})
es.subscribe().catch((err) => console.error(String(err)))
```
