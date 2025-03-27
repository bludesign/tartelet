import Foundation

public final class TartHost {
    let hostname: String
    let url: URL
    let priority: Int
    var lastStatus: TartHostStatus?

    public init(hostname: String, url: URL, priority: Int) {
        self.hostname = hostname
        self.url = url
        self.priority = priority
    }
}
