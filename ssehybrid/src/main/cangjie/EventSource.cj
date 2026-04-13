/**
 * Created on 015 26/1/15
 */
package sse

import eventsource4cj.client.EventSource as CJEventSource
import eventsource4cj.model.Message as CJMessage
import ohos.ark_interop.*
import ohos.hilog.Hilog
import std.collection.HashMap

public class EventSource <: SharedObject & JSInteropType<EventSource> {
    static init() {
        JSModule.registerClass("EventSource") {
            context =>
                let clazz = context.clazz(jsConstructor)
                clazz.addMethod("subscribe", context.function(subscribe_ArkTS_Interop_Identifier))
                clazz.addMethod("close", context.function(close_ArkTS_Interop_Identifier))
                clazz.addMethod("setExceptionHandler", context.function(setExceptionHandler_ArkTS_Interop_Identifier))
                clazz.addMethod("onMessage", context.function(onMessage_ArkTS_Interop_Identifier))
                clazz.addMethod("onEvent", context.function(onEvent_ArkTS_Interop_Identifier))
                clazz.addMethod("setHeader", context.function(setHeader_ArkTS_Interop_Identifier))
                clazz.addMethod("setHeaders", context.function(setHeaders_ArkTS_Interop_Identifier))
                clazz.addMethod("removeHeader", context.function(removeHeader_ArkTS_Interop_Identifier))
                clazz.addMethod("clearHeaders", context.function(clearHeaders_ArkTS_Interop_Identifier))
                clazz.addMethod("setBody", context.function(setBody_ArkTS_Interop_Identifier))
                clazz.addMethod("clearBody", context.function(clearBody_ArkTS_Interop_Identifier))
                clazz.addMethod("setRequestBodyCompressType", context.function(setRequestCompressType_ArkTS_Interop_Identifier))
                clazz.addMethod("getRequestBodyCompressType", context.function(getRequestCompressType_ArkTS_Interop_Identifier))
                clazz.addMethod("setAcceptCompressType", context.function(setAcceptCompressType_ArkTS_Interop_Identifier))
                clazz.addMethod("getAcceptCompressType", context.function(getAcceptCompressType_ArkTS_Interop_Identifier))
                return clazz
        }
    }

    public init(url: String) {
        this.cjEventSource = CJEventSource(url)
    }

    public static func jsConstructor(context: JSContext, callInfo: JSCallInfo): JSValue {
        let argCount = callInfo.count
        let url = String.fromJSValue(context, callInfo[0])

        JSCurrentJSContext.set(context)
        let clazz: EventSource
        if (argCount >= 2) {
            // Check if second argument is String or ArrayBuffer
            let jsBody = callInfo[1]
            if (jsBody.isString()) {
                let body = String.fromJSValue(context, jsBody)
                clazz = EventSource(url)
                clazz.setBody(body)
            } else {
                // Treat as ArrayBuffer/Uint8Array
                let buffer = jsBody.asArrayBuffer()
                let body = buffer.readBytes()
                clazz = EventSource(url)
                clazz.setBody(body)
            }
        } else {
            clazz = EventSource(url)
        }
        JSCurrentJSContext.unset()
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = context.external(clazz)
        thisObject.attachCJObject(jsExternal)
        return thisObject.toJSValue()
    }

    public func setExceptionHandler(handler: (Exception, Array<UInt8>) -> Unit): Unit {
        cjEventSource.setExceptionHandler(handler)
    }
    public static func setExceptionHandler_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<EventSource>() ?? throw Exception("class: get clazz failed.")

        JSCurrentJSContext.set(context)
        let jsHandler = callInfo[0].asFunction()
        let handlerWrapper: (Exception, Array<UInt8>) -> Unit = {
            e: Exception, data: Array<UInt8> => context.postJSTask {
                jsHandler.call(
                    [
                        context.string(e.toString()).toJSValue(),
                        context.arrayBuffer(data).toJSValue()
                    ]
                )
            }
        }
        let RET = clazz.setExceptionHandler(handlerWrapper)
        JSCurrentJSContext.unset()
        return RET.toJSValue(context)
    }

    public func onMessage(handler: (CJMessage) -> Unit): Unit {
        cjEventSource.onMessage(handler)
    }
    public static func onMessage_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<EventSource>() ?? throw Exception("class: get clazz failed.")

        JSCurrentJSContext.set(context)
        let jsHandler = callInfo[0].asFunction()
        let handlerWrapper: (CJMessage) -> Unit = {
            msg: CJMessage => context.postJSTask {
                jsHandler.call(buildMessage(context, msg))
            }
        }
        let RET = clazz.onMessage(handlerWrapper)
        JSCurrentJSContext.unset()
        return RET.toJSValue(context)
    }

    public func onEvent(event: String, handler: (CJMessage) -> Unit): Unit {
        cjEventSource.onEvent(event, handler)
    }
    public static func onEvent_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<EventSource>() ?? throw Exception("class: get clazz failed.")

        JSCurrentJSContext.set(context)
        let event = callInfo[0].toString()
        let jsHandler = callInfo[1].asFunction()
        let handlerWrapper: (CJMessage) -> Unit = {
            msg: CJMessage => context.postJSTask {
                jsHandler.call(buildMessage(context, msg))
            }
        }
        let RET = clazz.onEvent(event, handlerWrapper)
        JSCurrentJSContext.unset()
        return RET.toJSValue(context)
    }

    public func subscribe(): Future<Unit> {
        return cjEventSource.subscribe()
    }
    public static func subscribe_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<EventSource>() ?? throw Exception("class: get clazz failed.")

        JSCurrentJSContext.set(context)
        let promise = context.promiseCapability()
        spawn {
            try {
                let future = clazz.subscribe()
                let ret = future.get()
                context.postJSTask {
                    promise.resolve(ret.toJSValue(context))
                }
            } catch (e: Exception) {
                context.postJSTask {
                    promise.reject(context.string(e.toString()).toJSValue())
                }
                Hilog.error(0, 'mdebug', getStackTrace(e))
            }
        }
        JSCurrentJSContext.unset()
        return promise.toJSValue()
    }

    public func close(): Unit {
        return cjEventSource.close()
    }
    public static func close_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<EventSource>() ?? throw Exception("class: get clazz failed.")

        JSCurrentJSContext.set(context)
        let RET = clazz.close()
        JSCurrentJSContext.unset()
        return RET.toJSValue(context)
    }

    public func setHeader(name: String, value: String): Unit {
        cjEventSource.setHeader(name, value)
    }
    public static func setHeader_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<EventSource>() ?? throw Exception("class: get clazz failed.")

        JSCurrentJSContext.set(context)
        let name = callInfo[0].toString()
        let value = callInfo[1].toString()
        let RET = clazz.setHeader(name, value)
        JSCurrentJSContext.unset()
        return RET.toJSValue(context)
    }

    public func setHeaders(headers: HashMap<String, String>): Unit {
        cjEventSource.setHeaders(headers)
    }
    public static func setHeaders_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<EventSource>() ?? throw Exception("class: get clazz failed.")

        JSCurrentJSContext.set(context)
        let jsHeaders = callInfo[0]
        let headers = HashMap<String, String>()

        // Use JS built-in method to get all keys of object
        let objectKeys = context.global["Object"].asObject()["keys"].asFunction()
        let keysJSArray = objectKeys.call([jsHeaders]).asArray(context)
        let length = keysJSArray.size
        let jsHeadersObj = jsHeaders.asObject(context)

        for (i in 0..length) {
            let key = keysJSArray[i].toString()
            let value = jsHeadersObj[key].toString()
            headers.add(key, value)
        }
        let RET = clazz.setHeaders(headers)
        JSCurrentJSContext.unset()
        return RET.toJSValue(context)
    }

    public func removeHeader(name: String): Unit {
        cjEventSource.removeHeader(name)
    }
    public static func removeHeader_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<EventSource>() ?? throw Exception("class: get clazz failed.")

        JSCurrentJSContext.set(context)
        let name = callInfo[0].toString()
        let RET = clazz.removeHeader(name)
        JSCurrentJSContext.unset()
        return RET.toJSValue(context)
    }

    public func clearHeaders(): Unit {
        cjEventSource.clearHeaders()
    }
    public static func clearHeaders_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<EventSource>() ?? throw Exception("class: get clazz failed.")

        JSCurrentJSContext.set(context)
        let RET = clazz.clearHeaders()
        JSCurrentJSContext.unset()
        return RET.toJSValue(context)
    }

    public func setBody(body: String): Unit {
        cjEventSource.setBody(body)
    }

    public func setBody(body: Array<UInt8>): Unit {
        cjEventSource.setBody(body)
    }

    public static func setBody_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<EventSource>() ?? throw Exception("class: get clazz failed.")

        JSCurrentJSContext.set(context)
        let jsBody = callInfo[0]
        let RET: Unit
        if (jsBody.isString()) {
            let body = jsBody.toString()
            RET = clazz.setBody(body)
        } else {
            // Treat as ArrayBuffer/Uint8Array
            let buffer = jsBody.asArrayBuffer()
            let body = buffer.readBytes()
            RET = clazz.setBody(body)
        }
        JSCurrentJSContext.unset()
        return RET.toJSValue(context)
    }

    public func clearBody(): Unit {
        cjEventSource.clearBody()
    }
    public static func clearBody_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<EventSource>() ?? throw Exception("class: get clazz failed.")

        JSCurrentJSContext.set(context)
        let RET = clazz.clearBody()
        JSCurrentJSContext.unset()
        return RET.toJSValue(context)
    }

    public func setRequestCompressType(compress: Int64): Unit {
        cjEventSource.setRequestCompressType(compress)
    }
    public static func setRequestCompressType_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<EventSource>() ?? throw Exception("class: get clazz failed.")

        JSCurrentJSContext.set(context)
        let compress = Int64(callInfo[0].toNumber())
        let RET = clazz.setRequestCompressType(compress)
        JSCurrentJSContext.unset()
        return RET.toJSValue(context)
    }

    public func getRequestCompressType(): Int64 {
        cjEventSource.getRequestCompressType()
    }
    public static func getRequestCompressType_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<EventSource>() ?? throw Exception("class: get clazz failed.")

        JSCurrentJSContext.set(context)
        let RET = clazz.getRequestCompressType()
        JSCurrentJSContext.unset()
        return RET.toJSValue(context)
    }

    public func setAcceptCompressType(compress: Int64): Unit {
        cjEventSource.setAcceptCompressType(compress)
    }

    public static func setAcceptCompressType_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<EventSource>() ?? throw Exception("class: get clazz failed.")

        JSCurrentJSContext.set(context)
        let compress = Int64(callInfo[0].toNumber())
        let RET = clazz.setAcceptCompressType(compress)
        JSCurrentJSContext.unset()
        return RET.toJSValue(context)
    }

    public func getAcceptCompressType(): Int64 {
        cjEventSource.getAcceptCompressType()
    }

    public static func getAcceptCompressType_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<EventSource>() ?? throw Exception("class: get clazz failed.")

        JSCurrentJSContext.set(context)
        let RET = clazz.getAcceptCompressType()
        JSCurrentJSContext.unset()
        return RET.toJSValue(context)
    }

    public func toJSValue(context: JSContext): JSValue {
        let ext = context.external(this)
        let obj = context.object()

        obj["subscribe"] = context.function(subscribe_ArkTS_Interop_Identifier).toJSValue()
        obj["setExceptionHandler"] = context.function(setExceptionHandler_ArkTS_Interop_Identifier).toJSValue()
        obj["onMessage"] = context.function(onMessage_ArkTS_Interop_Identifier).toJSValue()
        obj["onEvent"] = context.function(onEvent_ArkTS_Interop_Identifier).toJSValue()
        obj["setHeader"] = context.function(setHeader_ArkTS_Interop_Identifier).toJSValue()
        obj["setHeaders"] = context.function(setHeaders_ArkTS_Interop_Identifier).toJSValue()
        obj["removeHeader"] = context.function(removeHeader_ArkTS_Interop_Identifier).toJSValue()
        obj["clearHeaders"] = context.function(clearHeaders_ArkTS_Interop_Identifier).toJSValue()
        obj["setBody"] = context.function(setBody_ArkTS_Interop_Identifier).toJSValue()
        obj["clearBody"] = context.function(clearBody_ArkTS_Interop_Identifier).toJSValue()
        obj["setRequestCompressType"] = context.function(setRequestCompressType_ArkTS_Interop_Identifier).toJSValue()
        obj["getRequestCompressType"] = context.function(getRequestCompressType_ArkTS_Interop_Identifier).toJSValue()
        obj["setAcceptCompressType"] = context.function(setAcceptCompressType_ArkTS_Interop_Identifier).toJSValue()
        obj["getAcceptCompressType"] = context.function(getAcceptCompressType_ArkTS_Interop_Identifier).toJSValue()

        obj.attachCJObject(ext)
        obj.toJSValue()
    }

    public static func fromJSValue(context: JSContext, input: JSValue) {
        let jsObj = input.asObject()
        let jsExt = jsObj.getAttachInfo() ?? throw Exception("class: get external failed.")
        let obj = jsExt.cast<EventSource>() ?? throw Exception("class: get clazz failed.")
        return obj
    }
    public static func toArkTsType(): String {
        "class"
    }

    let cjEventSource: CJEventSource
}

func getStackTrace(thrown: ?Exception): String {
    var res: String = ""
    match (thrown) {
        case None => return res
        case Some(v) =>
            res = "\n${v.toString()}\n"
            var arr = v.getStackTrace()
            for (line in arr) {
                res += "      at ${line.declaringClass}.${line.methodName}(${line.fileName}:${line.lineNumber})\n"
            }
            return res
    }
}
