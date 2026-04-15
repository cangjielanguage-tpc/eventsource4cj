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

  close(): void

  setHeader(name: string, value: string): void

  setHeaders(headers: Record<string, string>): void

  removeHeader(name: string): void

  clearHeaders(): void

  setBody(body: string): void

  setBody(body: ArrayBuffer): void

  clearBody(): void

  // 0: raw data, 1: gzip compressed data, 2: brotli compressed data
  setRequestBodyCompressType(compress: number): void

  getRequestBodyCompressType(): number

  // 0: no "Accept-Encoding", 1: "Accept-Encoding: gzip", 2: "Accept-Encoding: br", 3: "Accept-Encoding: gzip, br"
  setAcceptCompressType(compress: number): void

  getAcceptCompressType(): number

  // xxxxTimeoutMs: -1 means do not set timeout
  constructor(url: string)
}

