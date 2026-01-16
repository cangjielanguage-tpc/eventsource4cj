import EventSource from "@ohos/eventsource";
import hilog from "@ohos.hilog";

export async function sse_ets(page: object, url: string): Promise<void> {
  try {
    let count = 0
    let es = new EventSource(url)
    es.addEventListener('range', (e: Record<"data", string>) => {
      count++
      hilog.error(0, 'mdebug', e.data)
    })
    es.onFailure((e: Record<"message", string>) => {
      // 得到错误消息，对错误消息做处理
      hilog.error(0, 'mdebug', e.message)
      page['message'] = `ets sse err, count:${count}`
    })
    // es.close()
  } catch (e) {
    hilog.error(0, 'mdebug', `${e} \n ${e.stack}`)
  }
}