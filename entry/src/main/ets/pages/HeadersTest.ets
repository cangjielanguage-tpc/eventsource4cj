import { sse_cj_headers_management, sse_cj_with_header, sse_cj_with_headers } from "./sse_cj";
import { SseUrlSecure } from "./Constants"

@Entry
@Component
export struct HeadersTest {
  build() {
    Scroll() {
      Flex({ direction: FlexDirection.Column }) {
        Text("Headers Test:")
        Text("SSE connection with single header setting.")
          .fontSize(15)
        this.buildHeaderRow(1, 50, 100, 1)
        this.buildHeaderRow(1, 100, 100, 1)
        this.buildHeaderRow(1, 500, 100, 1)
        this.buildHeaderRow(1, 1000, 100, 1)
        this.buildHeaderRow(1, 5000, 100, 1)
        Text("SSE connection with batch custom headers.")
          .fontSize(15)
        this.buildHeadersRow(1, 50, 100, 1)
        this.buildHeadersRow(1, 100, 100, 1)
        this.buildHeadersRow(1, 500, 100, 1)
        this.buildHeadersRow(1, 1000, 100, 1)
        this.buildHeadersRow(1, 5000, 100, 1)
        Text("Demonstrate the headers management function.")
          .fontSize(15)
        this.buildHeadersManagementRow(1, 50, 100, 1)
        this.buildHeadersManagementRow(1, 100, 100, 1)
        this.buildHeadersManagementRow(1, 500, 100, 1)
        this.buildHeadersManagementRow(1, 1000, 100, 1)
        this.buildHeadersManagementRow(1, 5000, 100, 1)
      }
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
  }

  @Builder
  buildHeaderRow(page: number, count: number, interval: number, datasize: number) {
    Flex({ direction: FlexDirection.Row }) {
      Button(`${page} pages * ${count}`)
        .fontSize($r('app.float.page_text_font_size'))
        .onClick(async () => {
          sse_cj_with_header(this, SseUrlSecure, page, count, interval, datasize)
        })
        .width('50%')
    }
    .width('100%')
    .padding(1)
    .align(Alignment.Center)
  }
  @Builder
  buildHeadersRow(page: number, count: number, interval: number, datasize: number) {
    Flex({ direction: FlexDirection.Row }) {
      Button(`${page} pages * ${count}`)
        .fontSize($r('app.float.page_text_font_size'))
        .onClick(async () => {
          sse_cj_with_headers(this, SseUrlSecure, page, count, interval, datasize)
        })
        .width('50%')
    }
    .width('100%')
    .padding(1)
  }
  @Builder
  buildHeadersManagementRow(page: number, count: number, interval: number, datasize: number) {
    Flex({ direction: FlexDirection.Row }) {
      Button(`${page} pages * ${count}`)
        .fontSize($r('app.float.page_text_font_size'))
        .onClick(async () => {
          sse_cj_headers_management(this, SseUrlSecure, page, count, interval, datasize)
        })
        .width('50%')
    }
    .width('100%')
    .padding(1)
  }
}
