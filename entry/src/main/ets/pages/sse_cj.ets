import { Message, EventSource, testCJ } from 'ssehybrid'
import hilog from '@ohos.hilog'
import { systemDateTime } from '@kit.BasicServicesKit'

/**
 * Basic SSE connection (without custom headers)
 */
export function sse_cj(
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
      let msg = `cj sse done, ${datasize} ${page}*${range}=${max} ${count} ${interval}, time: ${time / count} ns/op`
      hilog.warn(0, 'mdebug', msg)
      view['message'] = msg
    }
    let es = new EventSource(url)
    es.onMessage((msg) => {
      count++
      hilog.info(0, 'mdebug', `Received: ${msg.data}`)
      if (count >= max) {
        finish()
      }
    })
    es.subscribe()
  } catch (e) {
    hilog.error(0, 'mdebug', `${e} \n ${e.stack}`)
  }
}

/**
 * SSE connection with custom headers (single header setting)
 */
export function sse_cj_with_header(
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
    // Use secure endpoint requiring validation
    url = `${url}/${page}/${range}/${interval}/${datasize}`
    let max = page * range
    let count = 0
    let t0 = systemDateTime.getTime(true)
    let finish = () => {
      let time = systemDateTime.getTime(true) - t0
      let msg = `cj  sse with header done, ${datasize} ${page}*${range}=${max} ${count} ${interval}, time: ${time / count} ns/op`
      hilog.warn(0, 'mdebug', msg)
      view['message'] = msg
    }

    let es = new EventSource(url)

    // Set single custom header
    es.setHeader('X-Auth-Token', 'my-secret-token-12345')
    es.setHeader('X-Client-Id', 'arkts-client-001')

    es.onMessage((msg) => {
      count++
      hilog.info(0, 'mdebug', `Received: ${msg.data}`)
      if (count >= max) {
        finish()
      }
    })
    es.subscribe()
  } catch (e) {
    hilog.error(0, 'mdebug', `${e} \n ${e.stack}`)
    view['message'] = `Error: ${e.message}`
  }
}

/**
 * SSE connection with batch custom headers
 */
export function sse_cj_with_headers(
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
    // Use secure endpoint requiring validation
    url = `${url}/${page}/${range}/${interval}/${datasize}`
    let max = page * range
    let count = 0
    let t0 = systemDateTime.getTime(true)
    let finish = () => {
      let time = systemDateTime.getTime(true) - t0
      let msg = `cj  sse with headers done, ${datasize} ${page}*${range}=${max} ${count} ${interval}, time: ${time / count} ns/op`
      hilog.warn(0, 'mdebug', msg)
      view['message'] = msg
    }

    let es = new EventSource(url)

    // Batch set headers
    es.setHeaders({
      'X-Auth-Token': 'my-secret-token-12345',
      'X-Client-Id': 'arkts-client-002',
      'X-Api-Key': 'valid-api-key-12345',
      'X-Custom-Data': 'custom-value'
    })

    es.onMessage((msg) => {
      count++
      hilog.info(0, 'mdebug', `Received: ${msg.data}`)
      if (count >= max) {
        finish()
      }
    })
    es.subscribe()
  } catch (e) {
    hilog.error(0, 'mdebug', `${e} \n ${e.stack}`)
    view['message'] = `Error: ${e.message}`
  }
}

/**
 * Demonstrate headers management functionality
 */
export function sse_cj_headers_management(
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
      let msg = `cj  sse headers management done, ${datasize} ${page}*${range}=${max} ${count} ${interval}, time: ${time / count} ns/op`
      hilog.warn(0, 'mdebug', msg)
      view['message'] = msg
    }

    let es = new EventSource(url)

    // 1. Set some headers
    es.setHeader('X-Auth-Token', 'temp-token')
    es.setHeader('X-Client-Id', 'temp-client')
    es.setHeader('X-Temp-Header', 'will-be-removed')

    // 2. Remove single header
    es.removeHeader('X-Temp-Header')

    // 3. Update header values
    es.setHeader('X-Auth-Token', 'my-secret-token-12345')
    es.setHeader('X-Client-Id', 'arkts-client-003')

    // 4. Add more headers
    es.setHeaders({
      'X-Api-Key': 'valid-api-key-12345'
    })

    es.onMessage((msg) => {
      count++
      hilog.info(0, 'mdebug', `Received: ${msg.data}`)
     if (count >= max) {
        finish()
      }
    })
    es.subscribe()
  } catch (e) {
    hilog.error(0, 'mdebug', `${e} \n ${e.stack}`)
    view['message'] = `Error: ${e.message}`
  }
}