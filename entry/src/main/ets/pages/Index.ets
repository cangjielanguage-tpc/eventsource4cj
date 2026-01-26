import { Message, EventSource, testCJ } from "ssehybrid"
import hilog from "@ohos.hilog";
import { sse_cj } from "./sse_cj";
import { sse_ets } from "./sse_ets_local";

let SseUrl = "http://139.9.247.2:9000/sse/range"
// let SseUrl = "http://127.0.0.1:9000/sse/range"
// let SseUrl = "http://10.56.237.14:9000/sse/range"

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  build() {
    Scroll() {
      Flex({ direction: FlexDirection.Column }) {
        this.buildRow(1, 100, 100, 0)
        this.buildRow(10, 100, 100, 0)
        this.buildRow(100, 100, 100, 0)
        this.buildRow(1000, 100, 100, 0)
        this.buildRow(10000, 100, 100, 0)
        this.buildRow(100, 1, 100, 0)
        this.buildRow(1000, 1, 100, 0)
        this.buildRow(10000, 1, 100, 0)
        this.buildRow(100000, 1, 100, 0)
        this.buildRow(1, 1, 100, 2)
        this.buildRow(10, 1, 100, 2)
        this.buildRow(100, 1, 100, 2)
        this.buildRow(1000, 1, 100, 2)
        this.buildRow(10000, 1, 100, 2)
        /*模仿markdown ai场景: 数据330byte 间隔100ms 发送500次*/
        this.buildRow(1, 50, 100, 1)
        this.buildRow(1, 100, 100, 1)
        this.buildRow(1, 500, 100, 1)
        this.buildRow(1, 1000, 100, 1)
        this.buildRow(1, 5000, 100, 1)
        Text(this.message)
      }
    }
    // 设置滚动方法
    .scrollable(ScrollDirection.Vertical)
    // 设置滚动条状态
    .scrollBar(BarState.Auto)
  }

  @Builder
  buildRow(page: number, count: number, interval: number, datasize: number) {
    Flex({ direction: FlexDirection.Row }) {
      Button(`cj${datasize} ${toString(page)}*${toString(count)}${toStringInterval(interval)}`)
        .fontSize($r('app.float.page_text_font_size'))
        .onClick(async () => {
          sse_cj(this, `${SseUrl}`, page, count, interval, datasize)
        })
        .width('100%')
        .align(Alignment.Start)
      Button(`es${datasize} ${toString(page)}*${toString(count)}${toStringInterval(interval)}`)
        .fontSize($r('app.float.page_text_font_size'))
        .onClick(async () => {
          sse_ets(this, `${SseUrl}`, page, count, interval, datasize)
        })
        .width('100%')
        .align(Alignment.Start)
    }
    .width('100%')
    .padding(1)
  }
}

function toString(n: number): string {
  return n.toString()
    // .replaceAll(`100000`, `100k`)
    // .replaceAll(`50000`, `50k`)
    // .replaceAll(`10000`, `10k`)
    // .replaceAll(`5000`, `5k`)
    // .replaceAll(`1000`, `1k`)
}

function toStringInterval(n: number): string {
  if (n == 100) {
    return ''
  } else {
    return ` ${n}ms`
  }
}

/*
 * ai markdown: (54-01)/471 = 0.112526
 */