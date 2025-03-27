import Foundation
import LoggingData
import LoggingDomain
import Router
import WebServer

let environment = try RouterEnvironment()

let hosts: [TartHost] = environment.hosts.map { tartHost in
    .init(hostname: tartHost.hostname, url: tartHost.url, priority: tartHost.priority)
}

let server = RouterServer(hosts: hosts, logger: ConsoleLogger(subsystem: "RouterServer"))

Task {
    try await server.run(port: environment.port)
}

RunLoop.main.run()
