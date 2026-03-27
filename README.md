## 1. 依赖
该库依赖brotli4cj库（https://gitcode.com/Cangjie-TPC/brotli4cj）
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