import { sse_cj_post,
  sse_cj_post_with_headers,
  sse_cj_post_body_management,
  SseUrlPost,
  SseUrlPostSecure
} from "testpages";

@Entry
@Component
export struct PostHeadersTest {
  build() {
    Scroll() {
      Flex({ direction: FlexDirection.Column }) {
        Text("Post Headers Test:")
        Text("SSE POST connection with request body.")
          .fontSize(15)
        this.buildPostRow(1, 50, 100, 1)
        this.buildPostRow(1, 100, 100, 1)
        this.buildPostRow(1, 500, 100, 1)
        this.buildPostRow(1, 1000, 100, 1)
        this.buildPostRow(1, 5000, 100, 1)
        Text("SSE POST connection with body and custom headers.")
          .fontSize(15)
        this.buildPostHeadersRow(1, 50, 100, 1)
        this.buildPostHeadersRow(1, 100, 100, 1)
        this.buildPostHeadersRow(1, 500, 100, 1)
        this.buildPostHeadersRow(1, 1000, 100, 1)
        this.buildPostHeadersRow(1, 5000, 100, 1)
        Text("Demonstrate POST body management functionality.")
          .fontSize(15)
        this.buildPostManagementRow(1, 50, 100, 1)
        this.buildPostManagementRow(1, 100, 100, 1)
        this.buildPostManagementRow(1, 500, 100, 1)
        this.buildPostManagementRow(1, 1000, 100, 1)
        this.buildPostManagementRow(1, 5000, 100, 1)
      }
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
  }

  @Builder
  buildPostRow(page: number, count: number, interval: number, datasize: number) {
    Flex({ direction: FlexDirection.Row }) {
      Button(`${page} pages * ${count}`)
        .fontSize($r('app.float.page_text_font_size'))
        .onClick(async () => {
          sse_cj_post(this, SseUrlPost, page, count, interval, datasize)
        })
        .width('50%')
    }
    .width('100%')
    .padding(1)
    .align(Alignment.Center)
  }
  @Builder
  buildPostHeadersRow(page: number, count: number, interval: number, datasize: number) {
    Flex({ direction: FlexDirection.Row }) {
      Button(`${page} pages * ${count}`)
        .fontSize($r('app.float.page_text_font_size'))
        .onClick(async () => {
          sse_cj_post_with_headers(this, SseUrlPostSecure, page, count, interval, datasize)
        })
        .width('50%')
    }
    .width('100%')
    .padding(1)
  }
  @Builder
  buildPostManagementRow(page: number, count: number, interval: number, datasize: number) {
    Flex({ direction: FlexDirection.Row }) {
      Button(`${page} pages * ${count}`)
        .fontSize($r('app.float.page_text_font_size'))
        .onClick(async () => {
          sse_cj_post_body_management(this, SseUrlPost, page, count, interval, datasize)
        })
        .width('50%')
    }
    .width('100%')
    .padding(1)
  }
}
