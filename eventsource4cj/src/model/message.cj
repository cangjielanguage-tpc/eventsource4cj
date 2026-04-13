/**
Copyright (c) 2025 hashli
eventsource4cj is licensed under Mulan PSL v2.
You can use this software according to the terms and conditions of the Mulan PSL v2.
You may obtain a copy of Mulan PSL v2 at:
        http://license.coscl.org.cn/MulanPSL2
THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
See the Mulan PSL v2 for more details.
 */
package eventsource4cj.model

import std.collection.ArrayList
import std.math.numeric.*
import stdx.log.*
import ohos.hilog.Hilog

public struct Message {
    static let NEXT_DATA_LINE = '\n'

    static let FIELD_LABEL_EVENT = "event"

    static let FIELD_LABEL_ID = "id"

    static let FIELD_LABEL_RETRY = "retry"

    static let FIELD_LABEL_DATA = "data"

    static let FIELD_MARK_COLON = ":"

    /*
     * Event type. Optional. Custom arbitrary value
     */
    let event: Option<String>

    /*
     * Event ID. Optional. Can be used to locate the last message position on reconnection
     */
    let id: Option<String>

    /*
     * Retry time (milliseconds). Optional
     */
    let retry: Option<UInt16>

    /*
     * Comment. Optional
     */
    let comment: Option<String>

    /*
     * Data.
     */
    let dataList: ArrayList<String>

    /**
     * Extended properties
     */
    let ext = MessageExtend()

    protected init(event: Option<String>, id: Option<String>, retry: Option<UInt16>, comment: Option<String>,
        dataList: ArrayList<String>, tag: Option<String>) {
        this.event = event
        this.id = id
        this.retry = retry
        this.comment = comment
        this.dataList = dataList
        this.ext.tag = tag
    }

    public prop extention: MessageExtend {
        get() {
            return this.ext
        }
    }

    public prop eventType: Option<String> {
        get() {
            return this.event
        }
    }

    public prop msgId: Option<String> {
        get() {
            return this.id
        }
    }

    public prop dataLines: ArrayList<String> {
        get() {
            return this.dataList
        }
    }

    public prop data: Option<String> {
        get() {
            if (this.dataList.isEmpty()) {
                return Option.None
            } else {
                return this.dataList[0]
            }
        }
    }

    public prop retryInMills: Option<UInt16> {
        get() {
            return this.retry
        }
    }

    public func toMessageString(): String {
        let body = StringBuilder()

        // Process comment
        if (this.comment.isSome()) {
            body.append(FIELD_MARK_COLON)
            body.append(this.comment.getOrThrow())
            body.append(NEXT_DATA_LINE)
        }

        // Process message body
        if (this.event.isSome()) {
            body.append(FIELD_LABEL_EVENT)
            body.append(FIELD_MARK_COLON)
            body.append(this.event.getOrThrow())
            body.append(NEXT_DATA_LINE)
        }
        if (this.id.isSome()) {
            body.append(FIELD_LABEL_ID)
            body.append(FIELD_MARK_COLON)
            body.append(this.id.getOrThrow())
            body.append(NEXT_DATA_LINE)
        }
        if (this.retry.isSome()) {
            body.append(FIELD_LABEL_RETRY)
            body.append(FIELD_MARK_COLON)
            body.append("${this.retry.getOrThrow()}")
            body.append(NEXT_DATA_LINE)
        }

        for (data in dataList) {
            body.append(FIELD_LABEL_DATA)
            body.append(FIELD_MARK_COLON)
            body.append(data)
            body.append(NEXT_DATA_LINE)
        }

        return body.toString() + NEXT_DATA_LINE
    }
}

public class MessageExtend {
    var tag: Option<String>

    public init() {
        this.tag = Option.None
    }

    public prop messageTag: Option<String> {
        get() {
            return this.tag
        }
    }
}

public class MessageBuilder {
    static let log: Logger = getGlobalLogger()

    private var _tag: Option<String>

    private var _event: Option<String>

    private var _id: Option<String>

    private var _retry: Option<UInt16>

    private var _comment: Option<String>

    private let _dataList: ArrayList<String>

    public init() {
        this._tag = Option.None
        this._event = Option.None
        this._id = Option.None
        this._retry = Option.None
        this._comment = Option.None
        this._dataList = ArrayList<String>()
    }

    public func tag(tag: String): MessageBuilder {
        this._tag = tag

        return this
    }

    public func event(envent: String): MessageBuilder {
        this._event = envent

        return this
    }

    public func id(id: String): MessageBuilder {
        this._id = id

        return this
    }

    public func retry(retry: UInt16): MessageBuilder {
        this._retry = retry

        return this
    }

    public func comment(comment: String): MessageBuilder {
        this._comment = comment

        return this
    }

    public func data(data: String): MessageBuilder {
        this._dataList.add(data)
        return this
    }

    public func build(): Message {
        return Message(_event, _id, _retry, _comment, _dataList, _tag)
    }

    public static func resolve(messageBody: Array<UInt8>): Message {
        let mb = MessageBuilder()
        if (!String.checkUtf8Encoding(messageBody)) {
             Hilog.warn(0, 'SSE', "message is not utf8")
            return mb.build()
        }
        for (line in unsafe { String.fromUtf8(messageBody) }.lines()) {
            if (line.startsWith(Message.FIELD_MARK_COLON)) {
                mb.comment(getValue(line))
            } else if (line.startsWith(Message.FIELD_LABEL_EVENT)) {
                mb.event(getValue(line))
            } else if (line.startsWith(Message.FIELD_LABEL_ID)) {
                mb.id(getValue(line))
            } else if (line.startsWith(Message.FIELD_LABEL_RETRY)) {
                let retryValue = getValue(line)
                if (retryValue.size > 0) {
                    mb.retry(Decimal.parse(retryValue).toUInt16())
                }
            } else if (line.startsWith(Message.FIELD_LABEL_DATA)) {
                mb.data(getValue(line))
            } else {
                log.warn("Unrecognized data line: ${line}")
            }
        }

        return mb.build()
    }

    static func getValue(messageLine: String): String {
        return messageLine.split(Message.FIELD_MARK_COLON, 2)[1].removePrefix(" ")
    }
}
