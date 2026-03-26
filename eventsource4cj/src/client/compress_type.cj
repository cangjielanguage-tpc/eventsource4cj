/**
 * Created on 2026/3/26
 */
package eventsource4cj.client

enum CompressType {
    Gzip | Brotli

    public prop name: String {
        get() {
            match(this) {
                case Gzip => "gzip"
                case Brotli => "br"
            }
        }
    }
}