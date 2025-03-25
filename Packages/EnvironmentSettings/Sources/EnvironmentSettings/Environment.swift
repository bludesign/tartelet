import Foundation
import GitHubDomain
import VirtualMachineData
import VirtualMachineDomain
import Yams

public final class Environment: TartHomeProvider,
                         GitHubActionsRunnerConfiguration,
                         VirtualMachineSSHCredentialsStore,
                         GitHubCredentialsStore {
    public var organizationName: String?
    public var repositoryName: String?
    public var ownerName: String?
    public var appId: String?
    public var privateKey: Data?
    public var username: String?
    public var password: String?
    public var runnerDisableUpdates = false
    public var runnerScope: GitHubRunnerScope = .organization
    public var runnerLabels: String = ""
    public var runnerGroup: String = ""
    public var homeFolderURL: URL?
    public var numberOfMachines = 1
    public var netBridgedAdapter: String?
    public var isHeadless = false
    public var isInsecure = false
    public var insecureDomains: [String]
    public var webhookPort: Int?

    public init() throws {
        let configUrl = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("tart-executor.yaml")
        let contents = try Data(contentsOf: configUrl)
        let environmentYaml = try YAMLDecoder().decode(EnvironmentYaml.self, from: contents)

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
    }

    public func setUsername(_ username: String?) {
    }

    public func setPassword(_ password: String?) {
    }

    public func setOrganizationName(_ organizationName: String?) {
    }

    public func setRepository(_ repositoryName: String?, withOwner ownerName: String?) {
    }

    public func setAppID(_ appID: String?) {
    }

    public func setPrivateKey(_ privateKeyData: Data?) {
    }
}
