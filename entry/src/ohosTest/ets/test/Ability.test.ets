import { hilog } from '@kit.PerformanceAnalysisKit';
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';

import promptAction from '@ohos.promptAction';
import EventSource from '@ohos/eventsource'

export default function abilityTest() {
  describe('ActsAbilityTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    })
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    })
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    })
    it('assertContain', 0, () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      hilog.info(0x0000, 'testTag', '%{public}s', 'it begin');
      let a = 'abc';
      let b = 'b';
      // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
      expect(a).assertContain(b);
      expect(a).assertEqual(a);
    })
    it('ets_sse_test1', 0, () => {
      let es: null | EventSource = null;
      let url: string = "http://10.56.237.14:8080/sse/range/10";
      let simpleList: string[] = []
      let eventListener = (e: Record<"data", string>) => {
        simpleList.push(e.data);
      }
      // Create connection
      es = new EventSource(url)

      // Start listening
      es.addEventListener("server-time", eventListener);
      es.addEventListener("", eventListener);
      es.addEventListener(undefined, eventListener);
      es.addEventListener(null, eventListener);
      es.addEventListener('data', eventListener);

      // Cancel listening
      // es.removeEventListener("server-time", eventListener);

      // Disconnect
      // es.close();

      // Error listening
      es.onFailure((e: Record<"message", string>) => {
        // Get error message and handle it
      })

      hilog.error(0, 'mdebug', simpleList.length.toString())
    })
  })
}