## eventsource4cj 库

### 1. 介绍
#### 1.1 用途
该库提供符合 Server-Sent Events (SSE) 协议的客户端实现，支持 GET/POST 请求、自定义请求头、请求体压缩（GZIP/Brotli）、响应解压缩等功能。

#### 1.2 依赖
#### 1.2.1 stdx
该库依赖stdx中的包（https://gitcode.com/Cangjie/cangjie-stdx-bin/releases ）。

下载最新版本并解压（cangjie-stdx-ohos-aarch64-1.0.1.1.zip，cangjie-stdx-ohos-x64-1.0.1.1.zip）。

修改eventsource4cj/cjpm.toml文件中的${CANGJIE_STDX_PATH}为以上文件解压的路径，或配置环境变量（可以成功编译，但会当前版本IDE代码跳转bug）。

#### 1.2.2 三方库
该库依赖brotli4cj库（https://gitcode.com/Cangjie-TPC/brotli4cj ）。

```shell
cd ${Project_Root_Path}
git clone git@gitcode.com:Cangjie-TPC/brotli4cj.git -b brotli-ffi_cangjie-plugin_5.1.1
```

#### 1.3 场景
1. 建立 SSE 连接并接收服务器推送的事件流。
2. 支持 GET 和 POST 两种请求方式。
3. 支持请求体压缩（GZIP/Brotli）和响应解压缩。
4. 支持自定义请求头和事件处理器。

#### 1.4 约束
NA

#### 1.5 可靠性
NA

### 2. 接口
#### 2.1 构造函数

##### 2.1.1 主要接口

```cangjie
public class EventSource {
    /*
     * 初始化 SSE 客户端，用于 GET 请求
     * 
     * 参数 url - SSE 服务器端点 URL
     * 参数 bufferSize - 接收缓冲区大小，默认 8KB
     */
    public init(url: String, bufferSize!: Int64 = DEFAULT_BUFFER_SIZE)

    /*
     * 初始化 SSE 客户端，用于 POST 请求（字符串请求体）
     * 
     * 参数 url - SSE 服务器端点 URL
     * 参数 body - POST 请求体内容（字符串）
     * 参数 bufferSize - 接收缓冲区大小，默认 8KB
     */
    public init(url: String, body: String, bufferSize!: Int64 = DEFAULT_BUFFER_SIZE)

    /*
     * 初始化 SSE 客户端，用于 POST 请求（字节数组请求体）
     * 
     * 参数 url - SSE 服务器端点 URL
     * 参数 body - POST 请求体内容（字节数组）
     * 参数 bufferSize - 接收缓冲区大小，默认 8KB
     */
    public init(url: String, body: Array<UInt8>, bufferSize!: Int64 = DEFAULT_BUFFER_SIZE)
}
```

##### 2.1.2 示例

代码如下：

```cangjie
import eventsource4cj.client.EventSource

// GET 请求方式
let es = new EventSource("http://localhost:9000/sse/range/1/5/1000")

// POST 请求方式（字符串请求体）
let esPost = new EventSource("http://localhost:9000/sse/post/range/1/5/1000", "{\"key\":\"value\"}")

// POST 请求方式（字节数组请求体）
let bytes = "test data".toArray()
let esBytes = new EventSource("http://localhost:9000/sse/post/range/1/5/1000", bytes)
```

#### 2.2 请求体设置

##### 2.2.1 主要接口

```cangjie
public class EventSource {
    /*
     * 设置字符串类型的请求体
     * 
     * 参数 body - 请求体内容
     */
    public func setBody(body: String): Unit

    /*
     * 设置字节数组类型的请求体
     * 
     * 参数 body - 请求体内容
     */
    public func setBody(body: Array<UInt8>): Unit

    /*
     * 清除请求体
     */
    public func clearBody(): Unit
}
```

##### 2.2.2 示例

代码如下：

```cangjie
import eventsource4cj.client.EventSource

let es = new EventSource("http://localhost:9000/sse/post/range/1/5/1000")
es.setBody("{\"query\":\"test\"}")
// 或使用字节数组
es.setBody("test data".toArray())
```

#### 2.3 请求体压缩设置

##### 2.3.1 主要接口

```cangjie
public class EventSource {
    /*
     * 设置请求体压缩类型
     * 
     * 参数 compress - 压缩类型：0=不压缩，1=GZIP，2=Brotli
     */
    public func setRequestCompressType(compress: Int64): Unit

    /*
     * 获取请求体压缩类型
     * 
     * 返回值 Int64 - 压缩类型：0=不压缩，1=GZIP，2=Brotli
     */
    public func getRequestCompressType(): Int64
}
```

##### 2.3.2 示例

代码如下：

```cangjie
import eventsource4cj.client.EventSource

let es = new EventSource("http://localhost:9000/sse/brotli-response/post/1/5/1000", "{\"data\":\"test\"}")
// 设置请求体使用 Brotli 压缩
es.setRequestCompressType(2)

// 获取当前压缩类型
let compressType = es.getRequestCompressType() // 返回 2
```

#### 2.4 响应压缩设置

##### 2.4.1 主要接口

```cangjie
public class EventSource {
    /*
     * 设置接受的响应压缩类型（Accept-Encoding 头）
     * 
     * 参数 compress - 压缩类型：0=不设置，1=GZIP，2=Brotli，3=GZIP+Brotli
     */
    public func setAcceptCompressType(compress: Int64): Unit

    /*
     * 获取接受的响应压缩类型
     * 
     * 返回值 Int64 - 压缩类型：0=不设置，1=GZIP，2=Brotli，3=GZIP+Brotli
     */
    public func getAcceptCompressType(): Int64
}
```

##### 2.4.2 示例

代码如下：

```cangjie
import eventsource4cj.client.EventSource

let es = new EventSource("http://localhost:9000/sse/gzip-response/test/1/5/1000")
// 设置接受 GZIP 压缩响应
es.setAcceptCompressType(1)

// 设置同时接受 GZIP 和 Brotli 压缩响应
es.setAcceptCompressType(3)
```

#### 2.5 自定义请求头设置

##### 2.5.1 主要接口

```cangjie
public class EventSource {
    /*
     * 设置单个自定义请求头
     * 
     * 参数 name - 请求头名称
     * 参数 value - 请求头值
     */
    public func setHeader(name: String, value: String): Unit

    /*
     * 批量设置自定义请求头
     * 
     * 参数 headers - 请求头键值对映射
     */
    public func setHeaders(headers: HashMap<String, String>): Unit

    /*
     * 移除指定的请求头
     * 
     * 参数 name - 请求头名称
     */
    public func removeHeader(name: String): Unit

    /*
     * 清除所有自定义请求头
     */
    public func clearHeaders(): Unit
}
```

##### 2.5.2 示例

代码如下：

```cangjie
import eventsource4cj.client.EventSource
import std.collection.HashMap

let es = new EventSource("http://localhost:9000/sse/secure/range/1/5/1000")

// 设置单个请求头
es.setHeader("X-Auth-Token", "my-secret-token")
es.setHeader("X-Client-Id", "client-001")
es.setHeader("Content-Type", "application/json")

// 批量设置请求头
let headers = HashMap<String, String>()
headers.add("X-Custom-1", "value1")
headers.add("X-Custom-2", "value2")
es.setHeaders(headers)

// 移除单个请求头
es.removeHeader("X-Custom-1")

// 清除所有自定义请求头
es.clearHeaders()
```

#### 2.6 事件处理器设置

##### 2.6.1 主要接口

```cangjie
public class EventSource {
    /*
     * 设置默认消息处理器，处理没有事件类型的消息
     * 
     * 参数 handler - 消息处理函数
     */
    public func onMessage(handler: (Message) -> Unit): Unit

    /*
     * 设置指定事件类型的处理器
     * 
     * 参数 event - 事件类型名称
     * 参数 handler - 消息处理函数
     */
    public func onEvent(event: String, handler: (Message) -> Unit): Unit

    /*
     * 设置异常处理器
     * 
     * 参数 handler - 异常处理函数，接收异常对象和相关数据
     */
    public func setExceptionHandler(handler: (Exception, Array<UInt8>) -> Unit): Unit
}
```

##### 2.6.2 示例

代码如下：

```cangjie
import eventsource4cj.client.EventSource
import ohos.hilog.Hilog

let es = new EventSource("http://localhost:9000/sse/range/1/5/1000")

// 设置默认消息处理器
es.onMessage({ msg =>
    Hilog.info(0, "SSE", "Received: ${msg.data}")
})

// 设置特定事件类型的处理器
es.onEvent("range", { msg =>
    Hilog.info(0, "SSE", "Range event: ${msg.data}")
})

// 设置异常处理器
es.setExceptionHandler({ e, data =>
    Hilog.error(0, "SSE", "Error: ${e}, data: ${data}")
})
```

#### 2.7 订阅连接

##### 2.7.1 主要接口

```cangjie
public class EventSource {
    /*
     * 启动 SSE 连接订阅，异步执行
     * 
     * 返回值 Future<Unit> - 异步任务对象
     */
    public func subscribe(): Future<Unit>
}
```

##### 2.7.2 示例

代码如下：

```cangjie
import eventsource4cj.client.EventSource
import ohos.hilog.Hilog

let es = new EventSource("http://localhost:9000/sse/range/1/10/1000")

var count = 0
es.onMessage({ msg =>
    count++
    Hilog.info(0, "SSE", "Message ${count}: ${msg.data}")
    if (count >= 10) {
        // 处理完成
    }
})

// 启动订阅
es.subscribe()
```

#### 2.8 关闭连接

##### 2.8.1 主要接口

```cangjie
public class EventSource {
    /*
     * 关闭 SSE 连接。
     * 设置关闭标志和唤醒重试等待线程，关闭底层 socket 连接，
     * 使阻塞的 stream.read() 立即返回，Future 立即完成。
     */
    public func close(): Unit
}
```

##### 2.8.2 示例

代码如下：

```cangjie
import eventsource4cj.client.EventSource

let persistentEs = new EventSource("http://localhost:9000/sse/range/1/1000/500")
persistentEs.onMessage({ msg => println(msg.data) })
let future = persistentEs.subscribe()
// 关闭连接，断开 socket，Future 立即完成
sleep(Duration.millisecond * 5000)
persistentEs.close()
future.get() // Future 立即完成
```

#### 2.9 完整示例

以下示例演示使用 Brotli 压缩请求体并携带自定义请求头的 POST 请求：

```cangjie
import eventsource4cj.client.EventSource
import ohos.hilog.Hilog

func sseBrotliWithHeaders(): Unit {
    let url = "http://192.168.8.8:9000/sse/brotli-response/post/2/5/1000"
    
    // 创建带请求体的 EventSource
    let requestBody = "{\"query\":\"secure brotli data\",\"clientType\":\"arkts\"}"
    let es = new EventSource(url, requestBody)
    
    // 启用 Brotli 压缩
    es.setRequestCompressType(2)
    
    // 设置自定义请求头
    es.setHeader("X-Auth-Token", "my-secret-token-12345")
    es.setHeader("X-Client-Id", "arkts-brotli-client")
    es.setHeader("Content-Type", "application/json")
    
    // 设置消息处理器
    var count = 0
    es.onMessage({ msg =>
        count++
        Hilog.info(0, "SSE", "Brotli msg ${count}: ${msg.data}")
    })
    
    // 启动订阅
    es.subscribe()
}
```

运行结果如下：

```
Brotli msg 1: 5-1|body:{"query":"secure brotli data","clientType":"arkts"}
Brotli msg 2: 5-2|body:{"query":"secure brotli data","clientType":"arkts"}
...
```

#### 2.10 公共属性

##### 2.10.1 主要接口

```cangjie
public class EventSource {
    /* 重连间隔时间（毫秒），默认 30000ms */
    var retryInMills: UInt16
    
    /* 最后一条消息的 ID，用于断线重连 */
    var lastMessageId: Option<String>
}
```

##### 2.10.2 示例

代码如下：

```cangjie
import eventsource4cj.client.EventSource

let es = new EventSource("http://localhost:9000/sse")
// 设置重连间隔为 5 秒
es.retryInMills = 5000

// 获取最后消息 ID
if (let Some(id) <- es.lastMessageId) {
    println("Last message ID: ${id}")
}
```
