//
//  main.swift
//  tartelet
//
//  Created by Chandler Huff on 3/21/25.
//

import EnvironmentSettings
import FileSystemData
import Foundation
import GitHubData
import GitHubDomain
import LoggingData
import LoggingDomain
import NetworkingData
import Observation
import ShellData
import SSHData
import VirtualMachineData
import VirtualMachineDomain
import WebhookServer

let environment = try Environment()

enum Composers {
    static let tart = Tart(
        homeProvider: environment,
        shell: ProcessShell()
    )

    static let fleetWebhook = VirtualMachineFleetWebhook(
        logger: logger(subsystem: "VirtualMachineFleetWebhook"),
        webhookServer: WebhookServer(),
        virtualMachineProvider: TartVirtualMachineProvider(
            logger: logger(subsystem: "TartVirtualMachineProvider"),
            tart: tart,
            sshClient: sshClient
        )
    )

    static let sshClient = VirtualMachineSSHClient(
        logger: logger(subsystem: "VirtualMachineSSHClient"),
        client: CitadelSSHClient(
            logger: logger(subsystem: "CitadelSSHClient")
        ),
        ipAddressReader: RetryingVirtualMachineIPAddressReader(),
        credentialsStore: environment,
        connectionHandler: CompositeVirtualMachineSSHConnectionHandler([
            PostBootScriptSSHConnectionHandler(),
            GitHubActionsRunnerSSHConnectionHandler(
                logger: logger(subsystem: "GitHubActionsRunnerSSHConnectionHandler"),
                client: NetworkingGitHubClient(
                    credentialsStore: environment,
                    networkingService: URLSessionNetworkingService(
                        logger: logger(subsystem: "URLSessionNetworkingService")
                    )
                ),
                credentialsStore: environment,
                configuration: environment
            )
        ])
    )

    static func logger(subsystem: String) -> Logger {
        ConsoleLogger(subsystem: subsystem)
    }
}

guard let webhookPort = environment.webhookPort else {
    print("Webhook port not set")
    exit(1)
}

Task {
    try await Composers.fleetWebhook.startCommandLine(
        numberOfMachines: environment.numberOfMachines,
        gitHubRunnerLabels: environment.runnerLabels,
        webhookPort: webhookPort,
        isInsecure: environment.isInsecure,
        isHeadless: environment.isHeadless,
        insecureDomains: environment.insecureDomains,
        netBridgedAdapter: environment.netBridgedAdapter
    )
}

RunLoop.main.run()
