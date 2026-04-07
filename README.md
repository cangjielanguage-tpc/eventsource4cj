## 1 依赖
### 1.1 stdx
该库依赖stdx中的包（https://gitcode.com/Cangjie/cangjie-stdx-bin/releases ）。

下载最新版本并解压（cangjie-stdx-ohos-aarch64-1.0.1.1.zip，cangjie-stdx-ohos-x64-1.0.1.1.zip）。

修改eventsource4cj/cjpm.toml文件中的${CANGJIE_STDX_PATH}为以上文件解压的路径，或配置环境变量（可以成功编译，但会当前版本IDE代码跳转bug）。

### 1.2 三方库
该库依赖brotli4cj库（https://gitcode.com/Cangjie-TPC/brotli4cj ）。

```shell
cd ${Project_Root_Path}
git clone git@gitcode.com:Cangjie-TPC/brotli4cj.git -b brotli-ffi_cangjie-plugin_5.1.1
```
## 2. 用例
### 2.1 cangjie互操作用例

entry/src/main/ets/pages/sse_cj.ets

### 2.2 arkts用例

entry/src/main/ets/pages/sse_ets.ets

## 3. sse服务端

server/sse-server.js

启动sse服务端: 
```bash
cd server
npm install
node sse-server.js
```

## 4. sse客户端
配置测试服务器ip

entry/src/main/ets/pages/Constants.ets
```javascript
const ServerIP = "192.168.8.8"
```

编译并安装到手机上执行测试用例