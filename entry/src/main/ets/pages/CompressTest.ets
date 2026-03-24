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
        Text("SSE POST with both GZIP request body compression and response decompression.")
          .fontSize(15)
        this.buildGzipFullRow(1, 50, 100, 1)
      }
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
  }

  @Builder
  buildGzipRspRow(page: number, count: number, interval: number, datasize: number) {
    Flex({ direction: FlexDirection.Row }) {
      Button(`Test Only Rsp`)
        .fontSize($r('app.float.page_text_font_size'))
        .onClick(async () => {
          sse_cj_gzip_response(this, SseUrlGzip)
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
      Button(`Test Gzip Req & Rsp`)
        .fontSize($r('app.float.page_text_font_size'))
        .onClick(async () => {
          sse_cj_gzip_full(this, SseUrlGzipFull)
        })
        .width('50%')
    }
    .width('100%')
    .padding(1)
  }
}
