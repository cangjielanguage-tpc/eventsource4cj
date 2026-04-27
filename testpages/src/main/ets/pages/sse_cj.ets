import { EventSource } from 'ssehybrid'
import hilog from '@ohos.hilog'
import { systemDateTime } from '@kit.BasicServicesKit'
import { NsPerMs } from './Constants'

export function sse_cj_trip(
  view: object
): void {
  try {
    // let url = `https://m.ctrip.com:443/restapi/soa2/30568/appEvents?eventid=af0eea7cb35cc88f41d53143562e2268&__gw_appid=99999999&__gw_ver=890.006&__gw_os=Harmony&__gw_platform=APP&__gw_from=native`
    let url = `https://m.ctrip.com/restapi/soa2/30568/appEvents?eventid=af0eea7cb35cc88f41d53143562e2268&__gw_appid=99999999&__gw_ver=890.006&__gw_os=Harmony&__gw_platform=APP&__gw_from=native`
    let finish = () => {
      let msg = `cj sse trip done`
      hilog.warn(0, 'mdebug', msg)
      view['message'] = msg
    }
    let es = new EventSource(url)
    es.onOpen((headers) => {
      hilog.info(0, 'mdebug', `onOpen: ${headers}`)
    })
    es.onMessage((msg) => {
      hilog.info(0, 'mdebug', `Received: ${msg.data}`)
    })
    es.setExceptionHandler((e, buf) => {
      hilog.error(0, 'mdebug', `Exception ${e}`)
    })
    es.subscribe()
  } catch (e) {
    hilog.error(0, 'mdebug', `${e} \n ${e.stack}`)
  }
}

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
    hilog.info(0, 'mdebug', `begin: ${url}`)
    let t0 = systemDateTime.getTime(true)
    let finish = () => {
      let time = (systemDateTime.getTime(true) - t0) / NsPerMs
      let msg = `cj sse done, ${datasize} ${page}*${range}=${max} ${count} ${interval}, time: ${time / range} ms/range`
      hilog.warn(0, 'mdebug', msg)
      view['message'] = msg
    }
    let es = new EventSource(url)
    es.onOpen((headers) => {
      hilog.info(0, 'mdebug', `onOpen: ${headers}`)
    })
    es.onMessage((msg) => {
      count++
      // hilog.info(0, 'mdebug', `Received: ${msg.data}`)
      if (count >= max) {
        finish()
      }
    })
    es.setExceptionHandler((e, buf) => {
      hilog.error(0, 'mdebug', `Exception ${e}`)
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

    es.onOpen((headers) => {
      hilog.info(0, 'mdebug', `onOpen: ${headers}`)
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

    es.onOpen((headers) => {
      hilog.info(0, 'mdebug', `onOpen: ${headers}`)
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

    es.onOpen((headers) => {
      hilog.info(0, 'mdebug', `onOpen: ${headers}`)
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
 * SSE POST connection with request body
 */
export function sse_cj_post(
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
    // Use POST endpoint
    url = `${url}/${page}/${range}/${interval}/${datasize}`
    let max = page * range
    let count = 0
    let t0 = systemDateTime.getTime(true)
    let finish = () => {
      let time = systemDateTime.getTime(true) - t0
      let msg = `cj sse POST done, ${datasize} ${page}*${range}=${max} ${count} ${interval}, time: ${time / count} ns/op`
      hilog.warn(0, 'mdebug', msg)
      view['message'] = msg
    }

    // Create request body
    let requestBody = JSON.stringify({
      query: 'test data',
      timestamp: new Date().toISOString(),
      clientType: 'arkts'
    })

    let es = new EventSource(url)
    es.setBody(requestBody)

    es.onOpen((headers) => {
      hilog.info(0, 'mdebug', `onOpen: ${headers}`)
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
 * SSE POST connection with body and custom headers
 */
export function sse_cj_post_with_headers(
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
    // Use secure POST endpoint
    url = `${url}/${page}/${range}/${interval}/${datasize}`
    let max = page * range
    let count = 0
    let t0 = systemDateTime.getTime(true)
    let finish = () => {
      let time = systemDateTime.getTime(true) - t0
      let msg = `cj sse POST with headers done, ${datasize} ${page}*${range}=${max} ${count} ${interval}, time: ${time / count} ns/op`
      hilog.warn(0, 'mdebug', msg)
      view['message'] = msg
    }

    // Create request body
    let requestBody = JSON.stringify({
      query: 'secure data',
      timestamp: new Date().toISOString(),
      clientType: 'arkts-secure'
    })

    let es = new EventSource(url)
    es.setBody(requestBody)

    // Set custom headers
    es.setHeader('X-Auth-Token', 'my-secret-token-12345')
    es.setHeader('X-Client-Id', 'arkts-post-client')
    es.setHeader('Content-Type', 'application/json')

    es.onOpen((headers) => {
      hilog.info(0, 'mdebug', `onOpen: ${headers}`)
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
 * Demonstrate POST body management functionality
 */
export function sse_cj_post_body_management(
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
      let msg = `cj sse POST body management done, ${datasize} ${page}*${range}=${max} ${count} ${interval}, time: ${time / count} ns/op`
      hilog.warn(0, 'mdebug', msg)
      view['message'] = msg
    }

    let es = new EventSource(url)

    // Step 1: Set body using setBody
    es.setBody(JSON.stringify({ step: 1, data: 'initial' }))
    hilog.info(0, 'mdebug', 'Step 1: Set body using setBody()')

    // Step 2: Update body
    es.setBody(JSON.stringify({ step: 2, data: 'updated' }))
    hilog.info(0, 'mdebug', 'Step 2: Updated body with new content')

    // Step 3: Clear body (will revert to GET)
    es.clearBody()
    hilog.info(0, 'mdebug', 'Step 3: Cleared body (will use GET)')

    // Step 4: Set body again for POST request
    es.setBody(JSON.stringify({ step: 4, data: 'final', timestamp: new Date().toISOString() }))
    hilog.info(0, 'mdebug', 'Step 4: Set body again for POST request')

    es.onOpen((headers) => {
      hilog.info(0, 'mdebug', `onOpen: ${headers}`)
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
 * SSE connection with GZIP response decompression
 * Tests the client's ability to decompress GZIP encoded responses
 */
export function sse_cj_gzip_response(
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
    // Use the GZIP response test endpoint with path parameters
    let testUrl = `${url}/${page}/${range}/${interval}/${datasize}`
    let max = page * range
    let count = 0
    let t0 = systemDateTime.getTime(true)
    let finish = () => {
      let time = systemDateTime.getTime(true) - t0
      let msg = `cj sse GZIP response decompression done, ${datasize} ${page}*${range}=${max} ${count} ${interval}, time: ${time / count} ns/op`
      hilog.warn(0, 'mdebug', msg)
      view['message'] = msg
    }

    let es = new EventSource(testUrl)

    // Enable GZIP to request compressed response and handle decompression
    es.setAcceptCompressType(1)
    hilog.info(0, 'mdebug', `Accept response decompression: ${es.getAcceptCompressType()}`)

    es.onOpen((headers) => {
      hilog.info(0, 'mdebug', `onOpen: ${headers}`)
    })
    es.onMessage((msg) => {
      count++
      hilog.info(0, 'mdebug', `GZIP Response: ${msg.data}`)
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
 * SSE POST with both GZIP request body compression and response decompression
 */
export function sse_cj_gzip_full(
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
    // Use the GZIP response POST endpoint with path parameters
    let testUrl = `${url}/${page}/${range}/${interval}/${datasize}`
    let max = page * range
    let count = 0
    let t0 = systemDateTime.getTime(true)
    let finish = () => {
      let time = systemDateTime.getTime(true) - t0
      let msg = `cj sse GZIP full (request + response) done, ${datasize} ${page}*${range}=${max} ${count} ${interval}, time: ${time / count} ns/op`
      hilog.warn(0, 'mdebug', msg)
      view['message'] = msg
    }

    // Create request body
    let requestBody = JSON.stringify({
      query: 'gzip full test',
      timestamp: new Date().toISOString(),
      clientType: 'arkts-gzip-full'
    })

    let es = new EventSource(testUrl)
    es.setBody(requestBody)

    // Enable both request body compression and response decompression
    es.setRequestBodyCompressType(1)
    es.setAcceptCompressType(1)
    hilog.info(0, 'mdebug', `Accept response decompression: ${es.getAcceptCompressType()}, request compress: ${es.getRequestBodyCompressType()}`)

    es.onOpen((headers) => {
      hilog.info(0, 'mdebug', `onOpen: ${headers}`)
    })
    es.onMessage((msg) => {
      count++
      hilog.info(0, 'mdebug', `GZIP Full: ${msg.data}`)
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
 * SSE connection with Brotli response decompression
 * Tests the client's ability to decompress Brotli encoded responses
 */
export function sse_cj_brotli_response(
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
    // Use the Brotli response test endpoint with path parameters
    let testUrl = `${url}/${page}/${range}/${interval}/${datasize}`
    let max = page * range
    let count = 0
    let t0 = systemDateTime.getTime(true)
    let finish = () => {
      let time = systemDateTime.getTime(true) - t0
      let msg = `cj sse Brotli response decompression done, ${datasize} ${page}*${range}=${max} ${count} ${interval}, time: ${time / count} ns/op`
      hilog.warn(0, 'mdebug', msg)
      view['message'] = msg
    }

    let es = new EventSource(testUrl)

    // Enable Brotli to request compressed response and handle decompression
    es.setAcceptCompressType(2)
    hilog.info(0, 'mdebug', `Accept response decompression: ${es.getAcceptCompressType()}`)

    es.onOpen((headers) => {
      hilog.info(0, 'mdebug', `onOpen: ${headers}`)
    })
    es.onMessage((msg) => {
      count++
      hilog.info(0, 'mdebug', `Brotli Response: ${msg.data}`)
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
 * SSE POST with both Brotli request body compression and response decompression
 */
export function sse_cj_brotli_full(
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
    // Use the Brotli response POST endpoint with path parameters
    let testUrl = `${url}/${page}/${range}/${interval}/${datasize}`
    let max = page * range
    let count = 0
    let t0 = systemDateTime.getTime(true)
    let finish = () => {
      let time = systemDateTime.getTime(true) - t0
      let msg = `cj sse Brotli full (request + response) done, ${datasize} ${page}*${range}=${max} ${count} ${interval}, time: ${time / count} ns/op`
      hilog.warn(0, 'mdebug', msg)
      view['message'] = msg
    }

    // Create request body
    let requestBody = JSON.stringify({
      query: 'brotli full test',
      timestamp: new Date().toISOString(),
      clientType: 'arkts-brotli-full'
    })

    let es = new EventSource(testUrl)
    es.setBody(requestBody)

    // Enable both request body compression and response decompression
    es.setRequestBodyCompressType(2)
    es.setAcceptCompressType(2)
    hilog.info(0, 'mdebug', `Accept response decompression: ${es.getAcceptCompressType()}, request compress: ${es.getRequestBodyCompressType()}`)

    es.onOpen((headers) => {
      hilog.info(0, 'mdebug', `onOpen: ${headers}`)
    })
    es.onMessage((msg) => {
      count++
      hilog.info(0, 'mdebug', `Brotli Full: ${msg.data}`)
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
 * SSE POST with Brotli request compression and custom headers
 */
export function sse_cj_brotli_with_headers(
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
    // Use the Brotli response POST endpoint with path parameters
    let testUrl = `${url}/${page}/${range}/${interval}/${datasize}`
    let max = page * range
    let count = 0
    let t0 = systemDateTime.getTime(true)
    let finish = () => {
      let time = systemDateTime.getTime(true) - t0
      let msg = `cj sse Brotli with headers done, ${datasize} ${page}*${range}=${max} ${count} ${interval}, time: ${time / count} ns/op`
      hilog.warn(0, 'mdebug', msg)
      view['message'] = msg
    }

    // Create request body
    let requestBody = JSON.stringify({
      query: 'secure brotli data',
      timestamp: new Date().toISOString(),
      clientType: 'arkts-brotli-secure'
    })

    let es = new EventSource(testUrl)
    es.setBody(requestBody)

    // Enable Brotli compression
    es.setRequestBodyCompressType(2)
    es.setAcceptCompressType(2)

    // Set custom headers
    es.setHeader('X-Auth-Token', 'my-secret-token-12345')
    es.setHeader('X-Client-Id', 'arkts-brotli-client')
    es.setHeader('Content-Type', 'application/json')

    es.onOpen((headers) => {
      hilog.info(0, 'mdebug', `onOpen: ${headers}`)
    })
    es.onMessage((msg) => {
      count++
      hilog.info(0, 'mdebug', `Brotli with headers: ${msg.data}`)
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