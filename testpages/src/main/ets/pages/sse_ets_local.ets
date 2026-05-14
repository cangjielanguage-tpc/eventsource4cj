import EventSource from "./eventsource";
import hilog from "@ohos.hilog";
import { systemDateTime } from "@kit.BasicServicesKit";
import { NsPerMs } from "./Constants";

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
    hilog.info(0, 'mdebug', `begin: ${url}`)
    let t0 = systemDateTime.getTime(true)
    let finish = () => {
      let time = (systemDateTime.getTime(true) - t0) / NsPerMs
      let msg = `ets sse done, ${datasize} ${page}*${range}=${max} ${count} ${interval}, time: ${time / range} ms/range`
      hilog.error(0, 'mdebug', msg)
      view['message'] = msg
    }
    let es = new EventSource(url)
    es.addEventListener('range', (e: Record<"data", string>) => {
      // hilog.info(0, 'mdebug', `Received: ${e.data}`)
      count++
      if (count >= max) {
        finish()
        es.close()
      }
    })
    es.onFailure((e: Record<"message", string>) => {
      // Get error message and handle it
      hilog.error(0, 'mdebug', e.message)
      es.close()
    })
    // es.close()
  } catch (e) {
    hilog.error(0, 'mdebug', `${e} \n ${e.stack}`)
  }
}