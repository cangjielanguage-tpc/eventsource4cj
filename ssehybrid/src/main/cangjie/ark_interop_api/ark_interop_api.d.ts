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
  subscribe(): void
}

export declare interface CustomLib {
  EventSource: { new(url: string): EventSource }

  subscribe(): Promise<void>

  Message: { new(): Message }
}