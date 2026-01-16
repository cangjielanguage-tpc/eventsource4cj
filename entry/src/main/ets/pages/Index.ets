import { Message, EventSource, testCJ } from "ssehybrid"
import hilog from "@ohos.hilog";
import { sse_cj } from "./sse_cj";
import { sse_ets } from "./sse_ets";

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  build() {
    Scroll() {
      Column() {
        Button("bench_cj").fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          sse_cj(this, "http://10.56.237.14:9000/sse/range/10/100")
        })
        Button('bench_ets').fontSize($r('app.float.page_text_font_size')).onClick(async () => {
          // sse_ets(this, "http://10.56.237.14:8080/sse")
          sse_ets(this, "http://10.56.237.14:9000/sse/range/10/100")
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