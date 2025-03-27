import Combine
import Foundation
import LoggingDomain
import WebServer

public protocol VirtualMachineFleetSettings {
    var numberOfMachines: Int { get }
    var runnerLabels: String { get }
    var webhookPort: Int { get }
    var isHeadless: Bool { get }
    var isInsecure: Bool { get }
    var insecureDomains: [String] { get }
    var netBridgedAdapter: String? { get }
    var defaultMemory: Int? { get }
    var defaultCpu: Int? { get }
}

public final class VirtualMachineFleetWebhook {
    public private(set) var isStarted = false
    public private(set) var isStopping = false

    private let logger: Logger
    private let webhookServer: WebhookServer
    private var webhookServerTask: Task<(), any Error>?
    private let jobHandler: JobHandler
    private var gitHubRunnerLabels: Set<String>?
    private var cancellables = Set<AnyCancellable>()
    private let settings: VirtualMachineFleetSettings

    public init(logger: Logger, webhookServer: WebhookServer, virtualMachineProvider: VirtualMachineProvider, settings: VirtualMachineFleetSettings) {
        self.logger = logger
        self.webhookServer = webhookServer
        self.settings = settings
        let labelsArray = settings.runnerLabels.components(separatedBy: ",").map { label in
            label.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        gitHubRunnerLabels = Set<String>(labelsArray)
        jobHandler = .init(
            virtualMachineProvider: virtualMachineProvider,
            webhookServer: webhookServer,
            logger: logger
        )

        webhookServer.workflowJobPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] workflowJob in
                Task { [weak self] in
                    guard let self, isStarted else {
                        return
                    }
                    await handleWorkflowJob(workflowJob)
                }
            }
            .store(in: &cancellables)

        Task {
            await jobHandler.set(numberOfMachines: settings.numberOfMachines)
        }
    }

    public func startCommandLine() async throws {
        logger.info("Starting web server on port: \(settings.webhookPort) numberOfMachines: \(settings.numberOfMachines)")
        isStarted = true
        try await webhookServer.run(port: settings.webhookPort)
    }

    public func stopImmediately() {
        logger.info("Stop webhook immediately")
        isStarted = false
        isStopping = false
        webhookServerTask?.cancel()
        Task {
            await jobHandler.cancelAll()
        }
    }

    public func stop() {
        guard isStarted else {
            return
        }
        logger.info("Stop webhook")
        isStopping = true
        Task {
            await webhookServer.stop()
            webhookServerTask?.cancel()
            await jobHandler.cancelAll()
            isStopping = false
            isStarted = false
        }
    }
}

private extension VirtualMachineFleetWebhook {
    func handleWorkflowJob(_ workflowJob: WorkflowJob) async {
        guard let gitHubRunnerLabels else {
            logger.error("Workflow job skipped no runner labels set.")
            return
        }

        guard gitHubRunnerLabels.isSubset(of: workflowJob.labels) else {
            logger.error("Workflow job skipped because of labels. Job labels: \(workflowJob.labels) Tart labels: \(gitHubRunnerLabels)")
            return
        }

        let workflowSet = workflowJob.labels.subtracting(gitHubRunnerLabels)

        let memoryLabels = workflowSet.filter { label in
            label.starts(with: "memory:")
        }
        guard memoryLabels.count <= 1 else {
            logger.error("Workflow job skipped extra memory labels found: \(memoryLabels)")
            return
        }
        let memoryLabel = memoryLabels.first?.components(separatedBy: ":").last

        let cpuLabels = workflowSet.filter { label in
            label.starts(with: "cpu:")
        }
        guard cpuLabels.count <= 1 else {
            logger.error("Workflow job skipped extra cpu labels found: \(memoryLabels)")
            return
        }
        let cpuLabel = cpuLabels.first?.components(separatedBy: ":").last

        let imageNameSet = workflowSet.subtracting(memoryLabels).subtracting(cpuLabels)

        guard imageNameSet.count == 1, let imageName = imageNameSet.first else {
            logger.error("Workflow job skipped extra labels found: \(imageNameSet)")
            return
        }

        let imageInsecure = settings.insecureDomains.contains { insecureDomain in
            imageName.contains(insecureDomain)
        }

        let isJobInsecure = settings.isInsecure || imageInsecure

        logger.info("Workflow job: \(workflowJob.id) action: \(workflowJob.action.rawValue) image: \(imageName) isInsecure: \(isJobInsecure)")

        let pendingJob = PendingJob(
            workflowJob: workflowJob,
            imageName: imageName,
            netBridgedAdapter: settings.netBridgedAdapter,
            isInsecure: isJobInsecure,
            isHeadless: settings.isHeadless,
            memory: memoryLabel ?? settings.defaultMemory.map { "\($0)" },
            cpu: cpuLabel ?? settings.defaultCpu.map { "\($0)" }
        )
        await jobHandler.handle(pendingJob: pendingJob)
    }
}
