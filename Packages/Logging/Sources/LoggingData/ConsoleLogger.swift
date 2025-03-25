import Foundation
import LoggingDomain

public final class ConsoleLogger: LoggingDomain.Logger {
    private let subsystem: String

    public init(subsystem: String) {
        self.subsystem = subsystem
    }

    public func info(_ message: String) {
        print("INFO \(subsystem): \(message)")
    }

    public func error(_ message: String) {
        print("ERROR \(subsystem): \(message)")
    }
}
