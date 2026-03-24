import {
  sse_cj_gzip_response,
  sse_cj_gzip_full
} from "./sse_cj";
import { SseUrlGzip, SseUrlGzipFull } from "./Constants"

@Entry
@Component
export struct GzipTest {
  build() {
    Scroll() {
      Flex({ direction: FlexDirection.Column }) {
        Text("Gzip Test:")
        Text("SSE connection with GZIP response decompression.")
          .fontSize(15)
        this.buildGzipRspRow(1, 50, 100, 1)
        this.buildGzipRspRow(1, 100, 100, 1)
        this.buildGzipRspRow(1, 500, 100, 1)
        this.buildGzipRspRow(1, 1000, 100, 1)
        this.buildGzipRspRow(1, 5000, 100, 1)
        Text("SSE POST with both GZIP request body compression and response decompression.")
          .fontSize(15)
        this.buildGzipFullRow(1, 50, 100, 1)
        this.buildGzipFullRow(1, 100, 100, 1)
        this.buildGzipFullRow(1, 500, 100, 1)
        this.buildGzipFullRow(1, 1000, 100, 1)
        this.buildGzipFullRow(1, 5000, 100, 1)
      }
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
  }

  @Builder
  buildGzipRspRow(page: number, count: number, interval: number, datasize: number) {
    Flex({ direction: FlexDirection.Row }) {
      Button(`${page} pages * ${count}`)
        .fontSize($r('app.float.page_text_font_size'))
        .onClick(async () => {
          sse_cj_gzip_response(this, SseUrlGzip, page, count, interval, datasize)
        })
        .width('50%')
    }
    .width('100%')
    .padding(1)
    .align(Alignment.Center)
  }
  @Builder
  buildGzipFullRow(page: number, count: number, interval: number, datasize: number) {
    Flex({ direction: FlexDirection.Row }) {
      Button(`${page} pages * ${count}`)
        .fontSize($r('app.float.page_text_font_size'))
        .onClick(async () => {
          sse_cj_gzip_full(this, SseUrlGzipFull, page, count, interval, datasize)
        })
        .width('50%')
    }
    .width('100%')
    .padding(1)
  }
}
