import { Message, EventSource, testCJ } from "ssehybrid"
import hilog from "@ohos.hilog";
import { sse_cj } from "./sse_cj";
import { sse_ets } from "./sse_ets_local";

// let SseUrl = "http://139.9.247.2:9000/sse/range"
// let SseUrl = "http://127.0.0.1:9000/sse/range"
let SseUrl = "http://10.56.237.14:9000/sse/range"

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  build() {
    Scroll() {
      Column() {
        Button("cj__1*100").fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_cj(this, `${SseUrl}`, 1, 100)
        })
        Button('ets_1*100').fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_ets(this, `${SseUrl}`, 1, 100)
        })
        Button("cj__10*100").fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_cj(this, `${SseUrl}`, 10, 100)
        })
        Button('ets_10*100').fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_ets(this, `${SseUrl}`, 10, 100)
        })
        Button("cj__100*100").fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_cj(this, `${SseUrl}`, 100, 100)
        })
        Button('ets_100*100').fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_ets(this, `${SseUrl}`, 100, 100)
        })
        Button("cj__1000*100").fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_cj(this, `${SseUrl}`, 1000, 100)
        })
        Button('ets_1000*100').fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_ets(this, `${SseUrl}`, 1000, 100)
        })
        Button("cj__100*1").fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_cj(this, `${SseUrl}`, 100, 1)
        })
        Button('ets_100*1').fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_ets(this, `${SseUrl}`, 100, 1)
        })
        Button("cj__1000*1").fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_cj(this, `${SseUrl}`, 1000, 1)
        })
        Button('ets_1000*1').fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_ets(this, `${SseUrl}`, 1000, 1)
        })
        Button("cj__10000*1").fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_cj(this, `${SseUrl}`, 10000, 1)
        })
        Button('ets_10000*1').fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_ets(this, `${SseUrl}`, 10000, 1)
        })
        Button("cj__100000*1").fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_cj(this, `${SseUrl}`, 100000, 1)
        })
        Button('ets_100000*1').fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_ets(this, `${SseUrl}`, 100000, 1)
        })
        Button("cj__1*1_data2").fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_cj(this, `${SseUrl}`, 1, 1, 100, 2)
        })
        Button('ets_1*1_data2').fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_ets(this, `${SseUrl}`, 1, 1, 100, 2)
        })
        Button("cj__10*1_data2").fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_cj(this, `${SseUrl}`, 10, 1, 100, 2)
        })
        Button('ets_10*1_data2').fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_ets(this, `${SseUrl}`, 10, 1, 100, 2)
        })
        Button("cj__100*1_data2").fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_cj(this, `${SseUrl}`, 100, 1, 100, 2)
        })
        Button('ets_100*1_data2').fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_ets(this, `${SseUrl}`, 100, 1, 100, 2)
        })
        Button("cj__1000*1_data2").fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_cj(this, `${SseUrl}`, 1000, 1, 100, 2)
        })
        Button('ets_1000*1_data2').fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_ets(this, `${SseUrl}`, 1000, 1, 100, 2)
        })
        Button("cj__10000*1_data2").fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_cj(this, `${SseUrl}`, 10000, 1, 100, 2)
        })
        Button('ets_10000*1_data2').fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_ets(this, `${SseUrl}`, 10000, 1, 100, 2)
        })
        Text(this.message)
      }
    }
    // 设置滚动方法
    .scrollable(ScrollDirection.Vertical)
    // 设置滚动条状态
    .scrollBar(BarState.Auto)
  }
}