import { sse_cj } from "./sse_cj";
import { sse_ets } from "./sse_ets_local";
import { SseUrl } from "./Constants"

@Entry
@Component
export struct PerformanceTest {

  build() {
    Scroll() {
      Flex({ direction: FlexDirection.Column }) {
        Text("Basic Test:")
        Text("Simulate tiny data scenario. Data: 0 bytes.")
          .fontSize(15)
        this.buildRow(1, 100, 100, 0)
        this.buildRow(10, 100, 100, 0)
        this.buildRow(100, 100, 100, 0)
        this.buildRow(1000, 100, 100, 0)
        this.buildRow(10000, 100, 100, 0)
        this.buildRow(100, 1, 100, 0)
        this.buildRow(1000, 1, 100, 0)
        this.buildRow(10000, 1, 100, 0)
        this.buildRow(100000, 1, 100, 0)
        Text("Simulate large data scenario. Data: 785 bytes.")
          .fontSize(15)
        this.buildRow(1, 1, 100, 2)
        this.buildRow(10, 1, 100, 2)
        this.buildRow(100, 1, 100, 2)
        this.buildRow(1000, 1, 100, 2)
        this.buildRow(10000, 1, 100, 2)
        Text("Simulate markdown AI scenario. Data: 330 bytes.")
          .fontSize(15)
        this.buildRow(1, 50, 100, 1)
        this.buildRow(1, 100, 100, 1)
        this.buildRow(1, 500, 100, 1)
        this.buildRow(1, 1000, 100, 1)
        this.buildRow(1, 5000, 100, 1)
      }
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
  }

  @Builder
  buildRow(page: number, count: number, interval: number, datasize: number) {

    Flex({ direction: FlexDirection.Row }) {
      Button(`cj ${page}pages * ${count}`)
        .fontSize($r('app.float.page_text_font_size'))
        .onClick(async () => {
          sse_cj(this, SseUrl, page, count, interval, datasize)
        })
        .width('100%')
        .align(Alignment.Start)
      Button(`es ${page}pages * ${count}`)
        .fontSize($r('app.float.page_text_font_size'))
        .onClick(async () => {
          sse_ets(this, SseUrl, page, count, interval, datasize)
        })
        .width('100%')
        .align(Alignment.Start)
    }
    .width('100%')
    .padding(1)
  }
}
