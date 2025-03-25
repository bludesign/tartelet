import Foundation
import WebhookServer

final class PendingJob: Identifiable {
    let workflowJob: WorkflowJob
    let imageName: String
    let netBridgedAdapter: String?
    let isInsecure: Bool
    let isHeadless: Bool
    let memory: String?
    let cpu: String?
    var didStart = false

    var id: Int {
        workflowJob.id
    }

    var action: WorkflowAction {
        workflowJob.action
    }

    init(workflowJob: WorkflowJob, imageName: String, netBridgedAdapter: String?, isInsecure: Bool, isHeadless: Bool, memory: String?, cpu: String?) {
        self.workflowJob = workflowJob
        self.imageName = imageName
        self.netBridgedAdapter = netBridgedAdapter
        self.isInsecure = isInsecure
        self.isHeadless = isHeadless
        self.memory = memory
        self.cpu = cpu
    }
}
