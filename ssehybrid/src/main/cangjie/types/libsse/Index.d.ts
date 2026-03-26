export declare interface Message {
  messageTag: string | undefined
  eventType: string | undefined
  msgId: string | undefined
  dataLines: Array<string>
  data: string | undefined
  retryInMills: number | undefined
  toMessageString: string | undefined
}

export declare class EventSource {
  onMessage(handler: (msg: Message) => void): void

  onEvent(event: string, handler: (msg: Message) => void): void

  setExceptionHandler(handler: (exception: string, buffer: ArrayBuffer) => void): void

  subscribe(): Promise<void>

  setHeader(name: string, value: string): void

  setHeaders(headers: Record<string, string>): void

  removeHeader(name: string): void

  clearHeaders(): void

  setBody(body: string): void

  setBody(body: ArrayBuffer): void

  clearBody(): void

  setEnableGzip(enable: boolean): void

  setCompressRequestBody(compress: boolean): void

  isGzipEnabled(): boolean

  isRequestBodyCompressionEnabled(): boolean

  setEnableBrotli(enable: boolean): void

  setCompressRequestBodyWithBrotli(compress: boolean): void

  isBrotliEnabled(): boolean

  isRequestBodyBrotliCompressionEnabled(): boolean

  constructor(url: string)

  constructor(url: string, body: string)

  constructor(url: string, body: ArrayBuffer)
}

export declare function testCJ(s: string): string
