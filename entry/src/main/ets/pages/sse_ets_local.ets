import EventSource from "@ohos/eventsource";
import hilog from "@ohos.hilog";
import { systemDateTime } from "@kit.BasicServicesKit";

export function sse_ets(
  view: object,
  url: string,
  page: number,
  range: number,
  interval?: number,
  datasize?: number
): void {
  try {
    interval = interval ?? 100
    datasize = datasize ?? 0
    url = `${url}/${page}/${range}/${interval}/${datasize}`
    let max = page * range
    let count = 0
    let t0 = systemDateTime.getTime(true)
    let finish = () => {
      let time = systemDateTime.getTime(true) - t0
      let msg = `ets sse done, ${datasize} ${page}*${range}=${max} ${count} ${interval}, time: ${time / count} ns/op`
      hilog.error(0, 'mdebug', msg)
      view['message'] = msg
    }
    let es = new EventSource(url)
    es.addEventListener('range', (e: Record<"data", string>) => {
      count++
      if (count >= max) {
        finish()
        es.close()
      }
    })
    es.onFailure((e: Record<"message", string>) => {
      // 得到错误消息，对错误消息做处理
      hilog.error(0, 'mdebug', e.message)
      es.close()
    })
    // es.close()
  } catch (e) {
    hilog.error(0, 'mdebug', `${e} \n ${e.stack}`)
  }
}