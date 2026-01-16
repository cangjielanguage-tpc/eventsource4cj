package sse

internal import ohos.ark_interop.JSModule
internal import ohos.ark_interop.JSContext
internal import ohos.ark_interop.JSCallInfo
internal import ohos.ark_interop.JSValue

func testCJ(runtime: JSContext, callInfo: JSCallInfo): JSValue {
    let result = "Hello ${callInfo[0].toString(runtime)}"
    runtime.string(result).toJSValue()
}

let EXPORT_MODULE = JSModule.registerModule {
    runtime, exports => exports["testCJ"] = runtime.function(testCJ).toJSValue()
}
