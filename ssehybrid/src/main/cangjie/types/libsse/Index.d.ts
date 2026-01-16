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

  constructor(url: string)
}

export declare function testCJ(s: string): string
