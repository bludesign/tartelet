import GitHubDomain

// swiftlint:disable nesting
struct EnvironmentYaml: Decodable {
    struct Tart: Decodable {
        struct SSH: Decodable {
            let username: String
            let password: String
        }

        let homeFolder: String?
        let netBridgedAdapter: String?
        let isHeadless: Bool?
        let isInsecure: Bool?
        let insecureDomains: [String]?
        let numberOfVirtualMachines: Int?
        let ssh: SSH?
    }
    struct Github: Decodable {
        let runnerScope: GitHubRunnerScope
        let organizationName: String?
        let ownerName: String?
        let repositoryName: String?
        let appId: String
        let privateKey: String
    }
    struct Runner: Decodable {
        let labels: String
        let group: String?
        let disableUpdates: Bool?
    }
    struct Webhook: Decodable {
        let port: Int
    }

    let tart: Tart
    let github: Github
    let runner: Runner
    let webhook: Webhook
}
// swiftlint:enable nesting
