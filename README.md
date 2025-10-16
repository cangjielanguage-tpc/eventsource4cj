<div align="center">
<h1>eventsource4cj</h1>
</div>

<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v0.0.1-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjc-v0.53.13-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjcov-0.0%25-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/domain-HOS/Cloud-brightgreen" style="display: inline-block;" />
</p>

## 介绍

基于仓颉语言实现的SSE规范(Html5, Server-Send Event)组件。用于服务端和客户端的单向消息推送场景。

[Html5, Server-Send Event 规范](https://html.spec.whatwg.org/multipage/server-sent-events.html#server-sent-events)

### 项目特性

- 服务端完整实现SSE规范保证良好的兼容性

- 屏蔽规范实现与通信细节，让使用者专注于业务处理

- 提供客户端实现

### 项目计划

介绍开发和维护等关键里程碑

## 项目架构

架构图文说明，包括模块说明、架构层次等详细说明，详见 [DESGIN](./doc/design.md)

### 源码目录

```shell
.
├── README.md                   #整体介绍
├── doc                         #文档目录，包括设计文档，API接口文档等
│   ├── design.md               #设计文档
│   ├── example.md              #示例代码
│   └── feature_api.md          #特性接口文档
├── src                         #源码目录
│   └── client                  #客户端实现
│       └── sse_client.cj       #客户端类-EventSource
│   └── model                   #SSE消息模型
│       └── message.cj          #消息构建器-MessageBuilder
│   └── server                  #服务端实现
│       └── sse_emitter.cj      #服务实现类-SseServer(http服务)、SseEmitter(事件发布器)、SseEmitterBroker(http链接代理类)
└── test                        #测试代码目录
    ├── HLT
    └── LLT
```

### 接口说明

主要类和函数接口说明，详见 [API](./doc/feature_api.md)


## 使用说明
### 编译构建

修改cjpm.toml文件，添加本项目依赖：
```tmol
[dependencies]
  eventsource4cj = { git = "https://gitcode.com/Cangjie-SIG/eventsource4cj.git", branch = "main" }
```

编译运行：
```shell
cjpm update
cjpm build
cjpm run
```

### 功能示例

完整示例代码请参考帮助文档，详见 [示例](./doc/example.md)

#### 创建SSE服务

功能示例描述: 创建支持SSE的http服务

绑定指定地址和端口：

```cangjie
let sseServer = SseServer("127.0.0.1", 8080);
```

绑定至已有http服务：

```cangjie
// 已经存在的http服务
let server = ServerBuilder().addr("127.0.0.1").port(8080).build();

let sseServer = SseServer(server);
```

#### 发布SSE端点

功能示例描述: 发布一个SSE端点，eventsource客户端连接此端点接收消息。一个端点支持多个http连接。

发布一个端点并发送消息：

```cangjie
let endpoint = "/bus"

// 发布端点(客户端连接事件处理回调函数)
sseServer.publish(endpoint, checkAndInit)

// 发布端点(不传客户端连接事件处理回调函数)
//sseServer.publish(endpoint)

// 获取端点绑定的消息发送器
let emitter = SseEmitter.getEmitter(endpoint).getOrThrow();

// 向该端点上的全部连接发送消息
let message = MessageBuilder().data("hello world").build()
emitter.sendAll(message)

/**
* 示例：客户端连接事件处理回调函数
*/
func checkAndInit(broker: SseEmitterBroker): Bool {
    let requestContext = broker.httpContext;

    // 模拟权限校验等检查
    let token = requestContext.request.headers.get("token");
    if (token.isEmpty()) {
        let tokenInForm = requestContext.request.form.get("token")
        let tk = tokenInForm.getOrThrow({=>Exception("用户未登录！！！")})
        if (tk.size < 1) {
            return false;
        }
    }

    // 业务处理。例如记录已连接请求，然后在相关业务中调用发送方法
    clients.append(broker);

    return true;
}
```

#### 端点多路复用

功能示例描述: 在同一个端点上发送消息至不同客户端连接

方式1：在发布端点的初始化函数中记载不同客户端连接，然后按需求发送
```cangjie
let clients = ArrayList<SseEmitterBroker>()
sseServer.publish(endpoint, {broker=>clients.append(broker);})
clients.iterator().forEach({broker=>
    let message = MessageBuilder()
        .data("数据行1-${DateTime.nowUTC().toString()}")
        .build();
    broker.send(message)
})
```

方式2：使用带过滤函数的方法发送消息
```cangjie
let emitter = SseEmitter.getEmitter("/bus").getOrThrow();
let message = MessageBuilder().data("将消息发送给所有请求参数sse-tag=GA的客户端").build();
emitter.send(message, SseEmitter.defaultBrokerFilterByRequestParameterValue("sse-tag", "GA"))
//let eventsource2 = EventSource("http://127.0.0.1:8080/bus?token=c2-394j590&sse-tag=GA");
```

#### 客户端接收与处理消息

使用内置客户端：

```cangjie
// 创建消息源
let eventsource= Eventsource("http://127.0.0.1:8080/bus");

// 设置消息处理函数
eventsource.onMessage({msg=>println("默认处理消息：${msg.toMessageString()}")})
eventsource.onEvent("test-event", {msg=>println("处理消息：${msg.toMessageString()}")})

// 开始订阅消息（异步操作）
let future = eventsource.subscribe()
```

使用浏览器测试-客户端1订阅消息：

```javascript
const evtsource = new EventSource('http://127.0.0.1:8080/bus?sse-tag=GA');
evtsource.addEventListener('test-event', function(ctx) {
    console.log(ctx);
})
```

使用浏览器测试-客户端2订阅消息：

```javascript
const evtsource = new EventSource('http://127.0.0.1:8080/bus?sse-tag=GB');
evtsource.addEventListener('test-event', function(ctx) {
    console.log(ctx);
})
```

## 约束与限制
在下述版本验证通过：

    Cangjie Version: 0.53.13

## 开源协议
[木兰宽松许可证, 第2版](http://license.coscl.org.cn/MulanPSL2)

## 参与贡献

欢迎给我们提交PR，欢迎给我们提交Issue，欢迎参与任何形式的贡献。