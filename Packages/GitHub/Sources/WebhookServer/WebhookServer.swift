import Combine
import FlyingFox
import Foundation
import GitHubDomain

public struct WorkflowJob: Codable, Identifiable, Hashable {
    public let id: Int
    public let action: WorkflowAction
    public let labels: Set<String>

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public enum WorkflowAction: String {
    case waiting
    case queued
    case inProgress = "in_progress"
    case completed
    case unknown
}

extension WorkflowAction: Codable {
    public init(from decoder: Decoder) throws {
        self = try WorkflowAction(rawValue: decoder.singleValueContainer().decode(String.self)) ?? .unknown
    }
}

struct WebhookResponse: Codable {
    struct WorkflowJobResponse: Codable, Identifiable {
        let id: Int
        let labels: Set<String>
    }

    let action: WorkflowAction
    let workflow_job: WorkflowJobResponse
}

public final class WebhookServer {
    private let decoder = JSONDecoder()
    private let workflowJobSubject = PassthroughSubject<WorkflowJob, Never>()
    private var server: HTTPServer?

    public var inProgressJobs = 0
    public var pendingJobs = 0
    public var startedPendingJobs = 0
    public var virtualMachines = 0

    public var workflowJobPublisher: AnyPublisher<WorkflowJob, Never> {
        workflowJobSubject.eraseToAnyPublisher()
    }

    public init() {
    }

    public func run(port: Int) async throws {
        let server = HTTPServer(port: UInt16(port))
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
                workflowJobSubject.send(workflowJob)
            } catch {
                throw error
            }
            return .init(statusCode: .ok)
        }
        await server.appendRoute("GET /metrics") { [weak self] _ in
            guard let self else {
                return .init(statusCode: .badGateway)
            }
            let string = "tart_executor_in_progress_jobs \(inProgressJobs)\ntart_executor_pending_jobs \(pendingJobs)\ntart_executor_started_pending_jobs \(startedPendingJobs)\ntart_executor_virtual_machines \(virtualMachines)"
            let data = Data(string.utf8)
            return .init( statusCode: .ok, body: data)
        }
        try await server.run()
    }

    public func stop() async {
        await server?.stop()
        server = nil
    }
}
