/**
 * Created on 2026/3/26
 */
package eventsource4cj.client

enum RequestBody {
    StringBody(String) |
    StreamBody(Array<UInt8>)
}