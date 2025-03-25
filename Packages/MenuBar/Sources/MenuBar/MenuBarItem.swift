import GitHubDomain
import Observation
import SettingsDomain
import SwiftUI
import VirtualMachineDomain

public struct MenuBarItem<SettingsStoreType: SettingsStore & Observable>: Scene {
    @State private var isInserted: Bool
    private let settingsStore: SettingsStoreType
    private let fleet: VirtualMachineFleet
    private let fleetWebhook: VirtualMachineFleetWebhook
    private let editor: VirtualMachineEditor
    private let configurationState: ConfigurationState
    private let virtualMachineState: VirtualMachineState
    private var virtualMachinesMenuTitle: String {
        if settingsStore.numberOfVirtualMachines == 1 {
            L10n.Menu.VirtualMachines.singularis
        } else {
            L10n.Menu.VirtualMachines.pluralis
        }
    }

    public init(
        settingsStore: SettingsStoreType,
        fleet: VirtualMachineFleet,
        fleetWebhook: VirtualMachineFleetWebhook,
        editor: VirtualMachineEditor,
        configurationState: ConfigurationState,
        virtualMachineState: VirtualMachineState
    ) {
        self.settingsStore = settingsStore
        self.fleet = fleet
        self.fleetWebhook = fleetWebhook
        self.editor = editor
        self.configurationState = configurationState
        self.virtualMachineState = virtualMachineState
        self.isInserted = settingsStore.applicationUIMode.showInMenuBar
    }

    public var body: some Scene {
        MenuBarExtra(isInserted: $isInserted) {
            makeVirtualMachinesMenuContent()
            Divider()
            Button {
                if let url = URL(string: "https://github.com/shapehq/tartelet/wiki") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Text(L10n.MenuBarItem.documentation)
            }
            Divider()
            SettingsLink {
                Text(L10n.MenuBarItem.settings)
            }.keyboardShortcut(",", modifiers: .command)
            Button {
                presentAbout()
            } label: {
                Text(L10n.MenuBarItem.about)
            }
            Divider()
            Button {
                quitApp()
            } label: {
                Text(L10n.MenuBarItem.quit)
            }
        } label: {
            Image(systemName: "desktopcomputer")
        }
        .onChange(of: settingsStore.applicationUIMode) { _, newValue in
            isInserted = newValue.showInMenuBar
        }
        .commands {
            CommandMenu(virtualMachinesMenuTitle) {
                makeVirtualMachinesMenuContent()
            }
        }
    }
}

private extension MenuBarItem {
    private func presentAbout() {
        NSApplication.shared.orderFrontStandardAboutPanel()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    @ViewBuilder
    private func makeVirtualMachinesMenuContent() -> some View {
        VirtualMachinesMenuContent(
            configurationState: configurationState,
            virtualMachineState: virtualMachineState
        ) { action in
            switch action {
            case .startFleet:
                fleet.start(
                    numberOfMachines: settingsStore.numberOfVirtualMachines,
                    isInsecure: settingsStore.insecurePull,
                    isHeadless: settingsStore.headless,
                    netBridgedAdapter: settingsStore.netBridgedAdapter
                )
            case .startFleetWebhook:
                fleetWebhook.start(
                    numberOfMachines: settingsStore.numberOfVirtualMachines,
                    gitHubRunnerLabels: settingsStore.gitHubRunnerLabels,
                    webhookPort: settingsStore.webhookPort.flatMap { Int($0) },
                    isInsecure: settingsStore.insecurePull,
                    isHeadless: settingsStore.headless,
                    netBridgedAdapter: settingsStore.netBridgedAdapter
                )
            case .stopFleet:
                fleet.stop()
                fleetWebhook.stop()
            case .startEditor:
                editor.start(netBridgedAdapter: settingsStore.netBridgedAdapter, isHeadless: settingsStore.headless)
            }
        }
    }
}
