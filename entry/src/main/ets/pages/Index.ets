import { Message, EventSource, testCJ } from "ssehybrid"
import hilog from "@ohos.hilog";
import { sse_cj } from "./sse_cj";
import { sse_ets } from "./sse_ets";

let SseUrl = "http://139.9.247.2:9000/sse/range/100/100/100"

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  build() {
    Scroll() {
      Column() {
        Button("bench_cj").fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_cj(this, SseUrl)
        })
        Button('bench_ets').fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_ets(this, SseUrl)
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