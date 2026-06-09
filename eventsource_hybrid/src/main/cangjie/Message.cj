/**
 * Created on 015 26/1/15
 */
package sse

import eventsource4cj.model.Message as CJMessage
import ohos.ark_interop.*

public class Message <: SharedObject & JSInteropType<Message> {
    static init() {
        JSModule.registerClass("Message") {
            context =>
                let clazz = context.clazz(jsConstructor)

                clazz.addAccessor("messageTag", getter: context.function(get_messageTag_ArkTS_Interop_Identifier),
                    setter: context.function(set_messageTag_ArkTS_Interop_Identifier))
                clazz.addAccessor("eventType", getter: context.function(get_eventType_ArkTS_Interop_Identifier),
                    setter: context.function(set_eventType_ArkTS_Interop_Identifier))
                clazz.addAccessor("msgId", getter: context.function(get_msgId_ArkTS_Interop_Identifier),
                    setter: context.function(set_msgId_ArkTS_Interop_Identifier))
                clazz.addAccessor("dataLines", getter: context.function(get_dataLines_ArkTS_Interop_Identifier),
                    setter: context.function(set_dataLines_ArkTS_Interop_Identifier))
                clazz.addAccessor("data", getter: context.function(get_data_ArkTS_Interop_Identifier),
                    setter: context.function(set_data_ArkTS_Interop_Identifier))
                clazz.addAccessor("retryInMills", getter: context.function(get_retryInMills_ArkTS_Interop_Identifier),
                    setter: context.function(set_retryInMills_ArkTS_Interop_Identifier))
                clazz.addAccessor("toMessageString",
                    getter: context.function(get_toMessageString_ArkTS_Interop_Identifier),
                    setter: context.function(set_toMessageString_ArkTS_Interop_Identifier))

                return clazz
        }
    }

    public init() {
    }

    public static func jsConstructor(context: JSContext, callInfo: JSCallInfo): JSValue {
        let clazz = Message()
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = context.external(clazz)
        thisObject.attachCJObject(jsExternal)
        return thisObject.toJSValue()
    }

    public var messageTag: Option<String> = None
    public var eventType: Option<String> = None
    public var msgId: Option<String> = None
    public var dataLines: Option<JSArrayEx<String>> = None
    public var data: Option<String> = None
    public var retryInMills: Option<UInt16> = None
    public var toMessageString: String = ""

    public static func get_messageTag_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<Message>() ?? throw Exception("class: get clazz failed.")

        let RET = clazz.messageTag
        return RET.toJSValue(context)
    }

    public static func get_eventType_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<Message>() ?? throw Exception("class: get clazz failed.")

        let RET = clazz.eventType
        return RET.toJSValue(context)
    }

    public static func get_msgId_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<Message>() ?? throw Exception("class: get clazz failed.")

        let RET = clazz.msgId
        return RET.toJSValue(context)
    }

    public static func get_dataLines_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<Message>() ?? throw Exception("class: get clazz failed.")

        let RET = clazz.dataLines
        return RET.toJSValue(context)
    }

    public static func get_data_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<Message>() ?? throw Exception("class: get clazz failed.")

        let RET = clazz.data
        return RET.toJSValue(context)
    }

    public static func get_retryInMills_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<Message>() ?? throw Exception("class: get clazz failed.")

        let RET = clazz.retryInMills
        return RET.toJSValue(context)
    }

    public static func get_toMessageString_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<Message>() ?? throw Exception("class: get clazz failed.")

        let RET = clazz.toMessageString
        return RET.toJSValue(context)
    }

    public static func set_messageTag_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<Message>() ?? throw Exception("class: get clazz failed.")

        let value = Option<String>.fromJSValue(context, callInfo[0])
        clazz.messageTag = value
        return context.undefined().toJSValue()
    }

    public static func set_eventType_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<Message>() ?? throw Exception("class: get clazz failed.")

        let value = Option<String>.fromJSValue(context, callInfo[0])
        clazz.eventType = value
        return context.undefined().toJSValue()
    }

    public static func set_msgId_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<Message>() ?? throw Exception("class: get clazz failed.")

        let value = Option<String>.fromJSValue(context, callInfo[0])
        clazz.msgId = value
        return context.undefined().toJSValue()
    }

    public static func set_dataLines_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<Message>() ?? throw Exception("class: get clazz failed.")

        let value = Option<JSArrayEx<String>>.fromJSValue(context, callInfo[0])
        clazz.dataLines = value
        return context.undefined().toJSValue()
    }

    public static func set_data_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<Message>() ?? throw Exception("class: get clazz failed.")

        let value = Option<String>.fromJSValue(context, callInfo[0])
        clazz.data = value
        return context.undefined().toJSValue()
    }

    public static func set_retryInMills_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<Message>() ?? throw Exception("class: get clazz failed.")

        let value = Option<UInt16>.fromJSValue(context, callInfo[0])
        clazz.retryInMills = value
        return context.undefined().toJSValue()
    }

    public static func set_toMessageString_ArkTS_Interop_Identifier(context: JSContext, callInfo: JSCallInfo): JSValue {
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = thisObject.getAttachInfo() ?? throw Exception("class: get external failed.")
        let clazz = jsExternal.cast<Message>() ?? throw Exception("class: get clazz failed.")

        let value = String.fromJSValue(context, callInfo[0])
        clazz.toMessageString = value
        return context.undefined().toJSValue()
    }

    public func toJSValue(context: JSContext): JSValue {
        let ext = context.external(this)
        let obj = context.object()

        obj.defineOwnAccessor("messageTag", getter: context.function(get_messageTag_ArkTS_Interop_Identifier),
            setter: context.function(set_messageTag_ArkTS_Interop_Identifier))
        obj.defineOwnAccessor("eventType", getter: context.function(get_eventType_ArkTS_Interop_Identifier),
            setter: context.function(set_eventType_ArkTS_Interop_Identifier))
        obj.defineOwnAccessor("msgId", getter: context.function(get_msgId_ArkTS_Interop_Identifier),
            setter: context.function(set_msgId_ArkTS_Interop_Identifier))
        obj.defineOwnAccessor("dataLines", getter: context.function(get_dataLines_ArkTS_Interop_Identifier),
            setter: context.function(set_dataLines_ArkTS_Interop_Identifier))
        obj.defineOwnAccessor("data", getter: context.function(get_data_ArkTS_Interop_Identifier),
            setter: context.function(set_data_ArkTS_Interop_Identifier))
        obj.defineOwnAccessor("retryInMills", getter: context.function(get_retryInMills_ArkTS_Interop_Identifier),
            setter: context.function(set_retryInMills_ArkTS_Interop_Identifier))
        obj.defineOwnAccessor("toMessageString", getter: context.function(get_toMessageString_ArkTS_Interop_Identifier),
            setter: context.function(set_toMessageString_ArkTS_Interop_Identifier))

        obj.attachCJObject(ext)
        obj.toJSValue()
    }

    public static func fromJSValue(context: JSContext, input: JSValue): Message {
        let jsObj = input.asObject()
        let jsExt = jsObj.getAttachInfo() ?? throw Exception("class: get external failed.")
        let obj = jsExt.cast<Message>() ?? throw Exception("class: get clazz failed.")
        return obj
    }
    public static func toArkTsType(): String {
        "class"
    }

    private func setMsg(context: JSContext, msg: CJMessage): Unit {
        this.messageTag = msg.extention.messageTag
        this.eventType = msg.eventType
        this.msgId = msg.msgId
        this.dataLines = JSArrayEx<String>(unsafe {
            msg.dataLines.getRawArray()[..msg.dataLines.size]
        })
        this.data = msg.data
        this.retryInMills = msg.retryInMills
        this.toMessageString = msg.toMessageString()
    }

    static func create(context: JSContext, callInfo: JSCallInfo, msg: CJMessage): JSValue {
        let clazz = Message()
        clazz.setMsg(context, msg)
        let thisArg = callInfo.thisArg
        let thisObject = thisArg.asObject()
        let jsExternal = context.external(clazz)
        thisObject.attachCJObject(jsExternal)
        return thisObject.toJSValue()
    }
}

func buildMessage(context: JSContext, msg: CJMessage): JSValue {
    //    Hilog.error(0,'mdebug',"1.1 ${msg.data}")
    let obj = context.object()
    obj.set("messageTag", msg.extention.messageTag, context)
    obj.set("eventType", msg.eventType, context)
    obj.set("msgId", msg.msgId, context)
    obj["dataLines"] = JSArrayEx<String>(unsafe {
        msg.dataLines.getRawArray()[..msg.dataLines.size]
    }).toJSValue(context)
    obj.set("data", msg.data, context)
    obj.set("retryInMills", msg.retryInMills, context)
    obj.set("toMessageString", msg.toMessageString(), context)
    return obj.toJSValue()
}

extend JSObject {
    func set<T>(name: String, value: Option<T>, context: JSContext): Unit {
        match (value) {
            case Some(v: String) => this[name] = context.string(v).toJSValue()
            case Some(v: Rune) => this[name] = context.string(v.toString()).toJSValue()
            case Some(v: Int64) => this[name] = context.number(Float64(v)).toJSValue()
            case Some(v: UInt16) => this[name] = context.number(Float64(v)).toJSValue()
            case Some(v: Bool) => this[name] = context.boolean(v).toJSValue()
            case Some(v: JSValue) => this[name] = v
            case _ => this[name] = context.undefined().toJSValue()
        }
    }
}
