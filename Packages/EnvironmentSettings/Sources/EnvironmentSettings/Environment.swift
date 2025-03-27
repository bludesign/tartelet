import Foundation
import GitHubDomain
import VirtualMachineData
import VirtualMachineDomain
import Yams

public final class Environment: TartHomeProvider,
                         GitHubActionsRunnerConfiguration,
                         VirtualMachineSSHCredentialsStore,
                         GitHubCredentialsStore {
    public let hostname: String
    public let organizationName: String?
    public let repositoryName: String?
    public let ownerName: String?
    public let appId: String?
    public let privateKey: Data?
    public let username: String?
    public let password: String?
    public let runnerDisableUpdates: Bool
    public let runnerScope: GitHubRunnerScope
    public let runnerLabels: String
    public let runnerGroup: String
    public let homeFolderURL: URL?
    public let numberOfMachines: Int
    public let netBridgedAdapter: String?
    public let isHeadless: Bool
    public let isInsecure: Bool
    public let insecureDomains: [String]
    public let webhookPort: Int
    public let defaultMemory: Int?
    public let defaultCpu: Int?

    public init() throws {
        let configUrl = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("tart-executor.yaml")
        let contents = try Data(contentsOf: configUrl)
        let environmentYaml = try YAMLDecoder().decode(EnvironmentYaml.self, from: contents)

        hostname = environmentYaml.hostname
        organizationName = environmentYaml.github.organizationName
        repositoryName = environmentYaml.github.repositoryName
        ownerName = environmentYaml.github.ownerName
        appId = environmentYaml.github.appId
        privateKey = try Data(contentsOf: URL(fileURLWithPath: environmentYaml.github.privateKey))
        username = environmentYaml.tart.ssh?.username
        password = environmentYaml.tart.ssh?.password
        runnerDisableUpdates = environmentYaml.runner.disableUpdates ?? false
        runnerScope = environmentYaml.github.runnerScope
        runnerLabels = environmentYaml.runner.labels
        runnerGroup = environmentYaml.runner.group ?? ""
        homeFolderURL = environmentYaml.tart.homeFolder.map { URL(fileURLWithPath: $0) }
        numberOfMachines = environmentYaml.tart.numberOfVirtualMachines ?? 1
        netBridgedAdapter = environmentYaml.tart.netBridgedAdapter
        isHeadless = environmentYaml.tart.isHeadless ?? false
        isInsecure = environmentYaml.tart.isInsecure ?? false
        insecureDomains = environmentYaml.tart.insecureDomains ?? []
        webhookPort = environmentYaml.webhook.port
        defaultMemory = environmentYaml.tart.defaultMemory
        defaultCpu = environmentYaml.tart.defaultCpu
    }
}
