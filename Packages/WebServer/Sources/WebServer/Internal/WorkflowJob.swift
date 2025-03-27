import Foundation

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
