import Combine
import Foundation
import LoggingDomain
import Observation
import WebhookServer

@Observable
public final class VirtualMachineFleetWebhook {
    @MainActor
    public private(set) var isStarted = false
    @MainActor
    public private(set) var isStopping = false

    private let logger: Logger
    private let webhookServer: WebhookServer
    private var webhookServerTask: Task<(), any Error>?
    private let jobHandler: JobHandler
    private var numberOfMachines = 1
    private var gitHubRunnerLabels: Set<String>?
    private var insecureDomains: [String]?
    private var isInsecure = false
    private var isHeadless = false
    private var netBridgedAdapter: String?
    private var cancellables = Set<AnyCancellable>()

    public init(logger: Logger, webhookServer: WebhookServer, virtualMachineProvider: VirtualMachineProvider) {
        self.logger = logger
        self.webhookServer = webhookServer
        jobHandler = .init(
            virtualMachineProvider: virtualMachineProvider,
            webhookServer: webhookServer,
            logger: logger
        )

        webhookServer.workflowJobPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] workflowJob in
                Task { [weak self] in
                    guard let self, await isStarted else {
                        return
                    }
                    await handleWorkflowJob(workflowJob)
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    public func start(
        numberOfMachines: Int,
        gitHubRunnerLabels: String,
        webhookPort: Int?,
        isInsecure: Bool,
        isHeadless: Bool,
        netBridgedAdapter: String?
    ) {
        self.isInsecure = isInsecure
        self.isHeadless = isHeadless
        self.netBridgedAdapter = netBridgedAdapter
        guard let webhookPort else {
            logger.error("Starting without webhook port")
            return
        }
        guard !isStarted else {
            return
        }
        self.numberOfMachines = numberOfMachines
        Task {
            await jobHandler.set(numberOfMachines: numberOfMachines)
        }

        let labelsArray = gitHubRunnerLabels.components(separatedBy: ",").map { label in
            label.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        self.gitHubRunnerLabels = Set<String>(labelsArray)

        webhookServerTask = Task { [webhookServer] in
            logger.info("Starting web server on port: \(webhookPort) numberOfMachines: \(numberOfMachines)")
            try await webhookServer.run(port: webhookPort)
            isStarted = false
        }
        isStarted = true
    }

    public func startCommandLine(
        numberOfMachines: Int,
        gitHubRunnerLabels: String,
        webhookPort: Int,
        isInsecure: Bool,
        isHeadless: Bool,
        insecureDomains: [String],
        netBridgedAdapter: String?
    ) async throws {
        self.isInsecure = isInsecure
        self.isHeadless = isHeadless
        self.insecureDomains = insecureDomains
        self.netBridgedAdapter = netBridgedAdapter
        self.numberOfMachines = numberOfMachines
        Task {
            await jobHandler.set(numberOfMachines: numberOfMachines)
        }

        let labelsArray = gitHubRunnerLabels.components(separatedBy: ",").map { label in
            label.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        self.gitHubRunnerLabels = Set<String>(labelsArray)

        logger.info("Starting web server on port: \(webhookPort) numberOfMachines: \(numberOfMachines)")
        Task { @MainActor in
            isStarted = true
        }
        try await webhookServer.run(port: webhookPort)
    }

    @MainActor
    public func stopImmediately() {
        logger.info("Stop webhook immediately")
        isStarted = false
        isStopping = false
        webhookServerTask?.cancel()
        Task {
            await jobHandler.cancelAll()
        }
    }

    @MainActor
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

        let imageInsecure = insecureDomains?.contains { insecureDomain in
            imageName.contains(insecureDomain)
        } ?? false

        let isJobInsecure = isInsecure || imageInsecure

        logger.info("Workflow job: \(workflowJob.id) action: \(workflowJob.action.rawValue) image: \(imageName) isInsecure: \(isJobInsecure)")

        let pendingJob = PendingJob(
            workflowJob: workflowJob,
            imageName: imageName,
            netBridgedAdapter: netBridgedAdapter,
            isInsecure: isJobInsecure,
            isHeadless: isHeadless,
            memory: memoryLabel,
            cpu: cpuLabel
        )
        await jobHandler.handle(pendingJob: pendingJob)
    }
}
