import { Message, EventSource, testCJ } from "ssehybrid"
import hilog from "@ohos.hilog";
import { PerformanceTest } from "./PerformanceTest";
import { sse_ets } from "./sse_ets_local";
import { SseUrl } from "./Constants"
import { router } from "@kit.ArkUI";

@Entry
@Component
struct Index {
  @State cjWithHeader: string = 'No header';

  build() {
    Column() {
      Button("Basic Performance Comparison Test")
        .fontSize($r('app.float.page_text_font_size'))
        .width('80%')
        .onClick(async () => {
          router.pushUrl({
            url: 'pages/PerformanceTest'
          })
        })
        .margin({top: 3, bottom: 3})
      Button("Custom Headers Test")
        .fontSize($r('app.float.page_text_font_size'))
        .width('80%')
        .onClick(async () => {
          router.pushUrl({
            url: 'pages/HeadersTest'
          })
        })
        .margin({top: 3, bottom: 3})
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}