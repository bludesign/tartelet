import Combine
import FlyingFox
import Foundation
import LoggingDomain

public final class RouterServer {
    private enum RouterError: Error {
        case wrongBody
    }

    private let decoder = JSONDecoder()
    private var server: HTTPServer?
    private var hosts: [TartHost]
    private let logger: Logger
    private var timer: Timer?

    public init(hosts: [TartHost], logger: Logger) {
        self.hosts = hosts.sorted { lhs, rhs in
            lhs.priority < rhs.priority
        }
        self.logger = logger

//        timer = .scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
//            Task {
//                await self?.updateStatus()
//            }
//        }
    }

    private static func sendJob(host: TartHost, workflowJob: WorkflowJob, headers: [HTTPHeader: String], bodyData: Data, logger: Logger) async throws {
        logger.info("Sending job: \(workflowJob.id) to host: \(host.hostname)")
        var hostRequest = URLRequest(url: host.url.appending(path: "/"))
        hostRequest.httpMethod = "POST"
        hostRequest.httpBody = bodyData
        headers.forEach { header, value in
            hostRequest.setValue(value, forHTTPHeaderField: header.rawValue)
        }
        _ = try await URLSession.shared.data(for: hostRequest)
    }

    public func run(port: Int) async throws {
        let server = HTTPServer(port: UInt16(port))
        await server.appendRoute("GET /metrics") { [weak self] _ in
            guard let self else {
                return .init(statusCode: .badGateway)
            }
            let strings = try await withThrowingTaskGroup(of: String.self) { [hosts, logger] group in
                hosts.forEach { host in
                    group.addTask {
                        do {
                            let url = host.url.appending(path: "/metrics")
                            let (data, _) = try await URLSession.shared.data(from: url)
                            guard let string = String(data: data, encoding: .utf8) else {
                                throw RouterError.wrongBody
                            }
                            return string.appending("\ntart_executor_reachable{hostname=\"\(host.hostname)\"} true")
                        } catch {
                            logger.error("Error getting status for host: \(host.hostname): \(error.localizedDescription)")
                            return "tart_executor_reachable{hostname=\"\(host.hostname)\"} false"
                        }
                    }
                }

                var results: [String] = []
                for try await result in group {
                    results.append(result)
                }
                return results
            }
            let status = strings.joined(separator: "\n")
            return .init(statusCode: .ok, body: Data(status.utf8))
        }
        await server.appendRoute("POST /") { [weak self] request in
            guard let self else {
                return .init(statusCode: .badGateway)
            }
            do {
                let bodyData = try await request.bodyData
                let webhookResponse = try decoder.decode(WebhookResponse.self, from: bodyData)
                let workflowJob = WorkflowJob(
                    id: webhookResponse.workflow_job.id,
                    action: webhookResponse.action,
                    labels: webhookResponse.workflow_job.labels
                )
                await updateStatus()

                if workflowJob.action == .queued {
                    var lowestCapacity: (capacity: Int, host: TartHost)?
                    for host in hosts {
                        guard let lastStatus = host.lastStatus else { continue }
                        let capacity = lastStatus.virtualMachineLimit - lastStatus.totalJobs
                        let hasCapacity = lastStatus.totalJobs < lastStatus.virtualMachineLimit
                        if let currentLowestCapacity = lowestCapacity {
                            if capacity > currentLowestCapacity.capacity {
                                lowestCapacity = (capacity, host)
                            }
                        } else {
                            lowestCapacity = (capacity, host)
                        }
                        if hasCapacity {
                            try await Self.sendJob(host: host, workflowJob: workflowJob, headers: request.headers, bodyData: bodyData, logger: logger)
                            return .init(statusCode: .ok)
                        }
                    }
                    if let lowestCapacity {
                        try await Self.sendJob(host: lowestCapacity.host, workflowJob: workflowJob, headers: request.headers, bodyData: bodyData, logger: logger)
                    } else {
                        logger.error("No host found to take job: \(workflowJob.id)")
                        return .init(statusCode: .serviceUnavailable)
                    }
                    // TODO: Handle failed host
                } else {
                    await withTaskGroup(of: Void.self) { [hosts, logger] group in
                        hosts.forEach { host in
                            group.addTask {
                                do {
                                    try await Self.sendJob(host: host, workflowJob: workflowJob, headers: request.headers, bodyData: bodyData, logger: logger)
                                } catch {
                                    logger.error("Error sending completed job: \(workflowJob.id) host: \(host.hostname): \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
            } catch {
                throw error
            }
            return .init(statusCode: .ok)
        }
        try await server.run()
    }

    public func stop() async {
        await server?.stop()
        server = nil
    }
}

private extension RouterServer {
    func updateStatus() async {
        await withTaskGroup(of: Void.self) { [weak self] group in
            guard let self else { return }
            hosts.forEach { [weak self] host in
                group.addTask { [weak self] in
                    guard let self else { return }
                    do {
                        let url = host.url.appending(path: "/status")
                        let (data, _) = try await URLSession.shared.data(from: url)
                        let status = try decoder.decode(TartHostStatus.self, from: data)
                        host.lastStatus = status
                    } catch {
                        host.lastStatus = nil
                        logger.error("Error getting status for host: \(host.hostname): \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
