## 1 依赖

### 1.1 stdx

该库依赖stdx中的包（<https://gitcode.com/Cangjie/cangjie-stdx-bin/releases> ），当前依赖版本为 v1.1.3.1。

执行 `ohpm install` 时，`scripts/pre-install.mjs` 脚本会自动完成以下操作：

- 优先读取 `CANGJIE_STDX_PATH` 环境变量；若未设置且 `DEVECO_CANGJIE_HOME` 存在，则自动将 `CANGJIE_STDX_PATH` 配置为相同路径
- 若目标路径下缺少 `linux_ohos_aarch64_llvm` 和 `linux_ohos_x86_64_llvm` 文件夹，则自动下载并解压到对应路径
- 在 Windows 上通过 `setx` 将 `CANGJIE_STDX_PATH` 持久化到用户环境变量

如果构建过程中提示找不到 stdx 相关库，请检查 `ohpm install` 的脚本执行日志，确认下载和解压是否成功；若脚本执行失败，可参考上文链接自行下载并解压，并将路径配置为 `CANGJIE_STDX_PATH` 环境变量。

### 1.2 stdx 链接方式

#### 静态链接（默认）

静态链接在编译期间将所有依赖 stdx 的库函数和代码链接到最终的可执行文件中，生成的 so 已包含所需代码，无需再依赖外部的 stdx 库。

**缺点**：由于将所有代码都包含进最终的可执行文件，生成的 so 文件比动态链接的更大。

当前三方库默认使用静态链接，`eventsource4cj/cjpm.toml` 中配置如下：

```toml
[target]
  [target.aarch64-linux-ohos]
      ...
      path-option = [ ..., "${CANGJIE_STDX_PATH}/linux_ohos_aarch64_llvm/static/stdx" ]
  [target.x86_64-linux-ohos]
      ...
      path-option = [ ..., "${CANGJIE_STDX_PATH}/linux_ohos_x86_64_llvm/static/stdx" ]
```

#### 动态链接

动态链接编译的 har 包中，会将所有使用到的 stdx 二进制 so 添加到 har 的 libs 文件夹内；程序启动时或运行时加载这些共享库。

**缺点**：stdx 版本之间可能存在不兼容，当三方库和 hap 包依赖的 stdx 版本不一致时，存在运行时 crash 风险。

如需切换为动态链接，将 `cjpm.toml` 中 `path-option` 的 `static` 改为 `dynamic` 即可：

```toml
[target]
  [target.aarch64-linux-ohos]
      ...
      path-option = [ ..., "${CANGJIE_STDX_PATH}/linux_ohos_aarch64_llvm/dynamic/stdx" ]
  [target.x86_64-linux-ohos]
      ...
      path-option = [ ..., "${CANGJIE_STDX_PATH}/linux_ohos_x86_64_llvm/dynamic/stdx" ]
```

### 1.3 三方库

该库依赖brotli4cj库（<https://gitcode.com/Cangjie-TPC/brotli4cj/blob/brotli-ffi_cangjie-plugin-6.1.1_compatibility> ）。

```shell
cd ${Project_Root_Path}
git clone https://gitcode.com/Cangjie-TPC/brotli4cj.git -b brotli-ffi_cangjie-plugin-6.1.1_compatibility
```

## 2. 用例

### 2.1 cangjie互操作用例

entry/src/main/ets/pages/sse\_cj.ets

### 2.2 arkts用例

entry/src/main/ets/pages/sse\_ets.ets

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

## 5. 编译

编译ssehybrid模块：

点击ssehybrid目录，点击Build - Make Module 'ssehybrid'。

编译并安装应用即可开始测试。
