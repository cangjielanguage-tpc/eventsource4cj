import {
  sse_cj_gzip_response,
  sse_cj_gzip_full,
  sse_cj_brotli_response,
  sse_cj_brotli_full,
  sse_cj_brotli_with_headers
} from "testpages";
import { SseUrlGzip, SseUrlGzipFull, SseUrlBr, SseUrlBrFull } from "testpages"

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
        Text("SSE connection with Brotli response decompression.")
          .fontSize(15)
        this.buildBrRspRow(1, 50, 100, 1)
        this.buildBrRspRow(1, 100, 100, 1)
        this.buildBrRspRow(1, 500, 100, 1)
        this.buildBrRspRow(1, 1000, 100, 1)
        this.buildBrRspRow(1, 5000, 100, 1)
        Text("SSE POST with both Brotli request body compression and response decompression.")
          .fontSize(15)
        this.buildBrFullRow(1, 50, 100, 1)
        this.buildBrFullRow(1, 100, 100, 1)
        this.buildBrFullRow(1, 500, 100, 1)
        this.buildBrFullRow(1, 1000, 100, 1)
        this.buildBrFullRow(1, 5000, 100, 1)
        Text("SSE POST with Brotli request compression and custom headers.")
          .fontSize(15)
        this.buildBrHeadersRow(1, 50, 100, 1)
        this.buildBrHeadersRow(1, 100, 100, 1)
        this.buildBrHeadersRow(1, 500, 100, 1)
        this.buildBrHeadersRow(1, 1000, 100, 1)
        this.buildBrHeadersRow(1, 5000, 100, 1)
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
  @Builder
  buildBrRspRow(page: number, count: number, interval: number, datasize: number) {
    Flex({ direction: FlexDirection.Row }) {
      Button(`${page} pages * ${count}`)
        .fontSize($r('app.float.page_text_font_size'))
        .onClick(async () => {
          sse_cj_brotli_response(this, SseUrlBr, page, count, interval, datasize)
        })
        .width('50%')
    }
    .width('100%')
    .padding(1)
    .align(Alignment.Center)
  }
  @Builder
  buildBrFullRow(page: number, count: number, interval: number, datasize: number) {
    Flex({ direction: FlexDirection.Row }) {
      Button(`${page} pages * ${count}`)
        .fontSize($r('app.float.page_text_font_size'))
        .onClick(async () => {
          sse_cj_brotli_full(this, SseUrlBrFull, page, count, interval, datasize)
        })
        .width('50%')
    }
    .width('100%')
    .padding(1)
    .align(Alignment.Center)
  }
  @Builder
  buildBrHeadersRow(page: number, count: number, interval: number, datasize: number) {
    Flex({ direction: FlexDirection.Row }) {
      Button(`${page} pages * ${count}`)
        .fontSize($r('app.float.page_text_font_size'))
        .onClick(async () => {
          sse_cj_brotli_with_headers(this, SseUrlBrFull, page, count, interval, datasize)
        })
        .width('50%')
    }
    .width('100%')
    .padding(1)
    .align(Alignment.Center)
  }
}
