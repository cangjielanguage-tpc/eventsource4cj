import { sse_cj, sse_ets, SseUrl, sse_cj_trip } from "testpages";

@Entry
@Component
export struct PerformanceTest {

  build() {
    Scroll() {
      Flex({ direction: FlexDirection.Column }) {
        Text("Basic Test:")
        Text("Simulate tiny data scenario. Data: 3-10 bytes.")
          .fontSize(15)
        this.buildRow(1, 100, 100, 0)
        this.buildRow(10, 100, 100, 0)
        this.buildRow(50, 100, 100, 0)
        this.buildRow(100, 100, 100, 0)
        this.buildRow(200, 100, 100, 0)
        this.buildRow(500, 100, 100, 0)
        this.buildRow(800, 100, 100, 0)
        this.buildRow(1000, 100, 100, 0)
        Text("Simulate large data scenario. Data: 792 bytes.")
          .fontSize(15)
        this.buildRow(1, 100, 100, 2)
        this.buildRow(10, 100, 100, 2)
        this.buildRow(50, 100, 100, 2)
        this.buildRow(100, 100, 100, 2)
        this.buildRow(200, 100, 100, 2)
        this.buildRow(500, 100, 100, 2)
        this.buildRow(800, 100, 100, 2)
        this.buildRow(1000, 100, 100, 2)
        Text("Simulate markdown AI scenario. Data: 337 bytes.")
          .fontSize(15)
        this.buildRow(1, 100, 100, 1)
        this.buildRow(10, 100, 100, 1)
        this.buildRow(50, 100, 100, 1)
        this.buildRow(100, 100, 100, 1)
        this.buildRow(200, 100, 100, 1)
        this.buildRow(500, 100, 100, 1)
        this.buildRow(800, 100, 100, 1)
        this.buildRow(1000, 100, 100, 1)
        Row() {
          Button(`cj trip`)
            .fontSize($r('app.float.page_text_font_size'))
            .onClick(async () => {
              sse_cj_trip(this)
            })
            .width('100%')
            .align(Alignment.Start)
        }

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
