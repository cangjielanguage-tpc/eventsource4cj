/**
 * Created on 015 26/1/15
 */
package sse

import eventsource4cj.client.EventSource as CJEventSource
import eventsource4cj.model.Message as CJMessage
import ohos.ark_interop.*
import ohos.ark_interop_macro.*
import ohos.hilog.Hilog

public class EventSource <: SharedObject & JSInteropType<EventSource> {
    static init() {
        JSModule.registerClass("EventSource") {
            context =>
                let clazz = context.clazz(jsConstructor)
                clazz.addMethod("subscribe", context.function(subscribe_ArkTS_Interop_Identifier))
                clazz.addMethod("setExceptionHandler", context.function(setExceptionHandler_ArkTS_Interop_Identifier))
                clazz.addMethod("onMessage", context.function(onMessage_ArkTS_Interop_Identifier))
                clazz.addMethod("onEvent", context.function(onEvent_ArkTS_Interop_Identifier))
                return clazz
        }
    }

    public init(url: String) {
        this.cjEventSource = CJEventSource(url)
    }

    public static func jsConstructor(context: JSContext, callInfo: JSCallInfo): JSValue {
        let arg1768443191338681800 = String.fromJSValue(context, callInfo[0])

        JSCurrentJSContext.set(context)
        let clazz = EventSource(arg1768443191338681800)
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

    public func toJSValue(context: JSContext): JSValue {
        let ext = context.external(this)
        let obj = context.object()

        obj["subscribe"] = context.function(subscribe_ArkTS_Interop_Identifier).toJSValue()
        obj["setExceptionHandler"] = context.function(setExceptionHandler_ArkTS_Interop_Identifier).toJSValue()
        obj["onMessage"] = context.function(onMessage_ArkTS_Interop_Identifier).toJSValue()
        obj["onEvent"] = context.function(onEvent_ArkTS_Interop_Identifier).toJSValue()

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

/**
@Interop[ArkTS]
public class EventSource {
    let cjEventSource: CJEventSource
    public init(url: String) {
        this.cjEventSource = CJEventSource(url)
    }
    public func subscribe(): Unit {
        throw Exception()
    }
}
 */
