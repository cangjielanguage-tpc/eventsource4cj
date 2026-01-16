import { Message, EventSource, testCJ } from 'ssehybrid'
import hilog from '@ohos.hilog'

export function sse_cj(page: object, url: string): void {
  try {
    let count = 0
    let es = new EventSource(url)
    es.onMessage((msg) => {
      count++
      hilog.error(0, "mdebug", msg.data)
    })
    es.subscribe().then(() => {
      page['message'] = `cj sse done, count:${count}`
    })
  } catch (e) {
    hilog.error(0, 'mdebug', `${e} \n ${e.stack}`)
  }
}