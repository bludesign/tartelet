import SettingsDomain
import SwiftUI
import VirtualMachineDomain

struct FleetMenuBarItem: View {
    let configurationState: ConfigurationState
    let virtualMachineState: VirtualMachineState
    let startFleet: () -> Void
    let startFleetWebhook: () -> Void
    let stopFleet: () -> Void

    var body: some View {
        ContentButton(presentSettings: presentSettings) {
            performAction()
        } label: {
            HStack {
                image
                Text(title)
            }
        }
        if virtualMachineState == .stoppingFleet || virtualMachineState == .stoppingFleetWebook {
            Button {} label: {
                Text(L10n.MenuBarItem.VirtualMachines.stoppingInfo)
            }
            .disabled(true)
        }
    }
}

private extension FleetMenuBarItem {
    private var title: String {
        switch (configurationState, virtualMachineState) {
        case (.ready, .stoppingFleet),
             (.ready, .stoppingFleetWebook),
             (.readyWebhook, .stoppingFleet),
             (.readyWebhook, .stoppingFleetWebook):
            return L10n.MenuBarItem.VirtualMachines.stopping
        case (.ready, .fleetStarted),
             (.ready, .fleetWebhookStarted),
             (.readyWebhook, .fleetStarted),
             (.readyWebhook, .fleetWebhookStarted):
            return L10n.MenuBarItem.VirtualMachines.stop
        case (.ready, .ready), (.ready, .editorStarted):
            return L10n.MenuBarItem.VirtualMachines.start
        case (.readyWebhook, .ready):
            return L10n.MenuBarItem.VirtualMachines.startWebhook
        case (_, _):
            return configurationState.shortInstruction
        }
    }

    private var image: Image {
        switch (configurationState, virtualMachineState) {
        case (.ready, .stoppingFleet),
             (.ready, .stoppingFleetWebook),
             (.readyWebhook, .stoppingFleet),
             (.readyWebhook, .stoppingFleetWebook),
             (.ready, .fleetStarted),
             (.ready, .fleetWebhookStarted),
             (.readyWebhook, .fleetStarted),
             (.readyWebhook, .fleetWebhookStarted):
            return Image(systemName: "stop.fill")
        case (.ready, .ready), (.ready, .editorStarted), (.readyWebhook, .ready):
            return Image(systemName: "play.fill")
        case (_, _):
            return Image(systemName: "switch.2")
        }
    }

    private var isDisabled: Bool {
        switch virtualMachineState {
        case .stoppingFleet, .editorStarted, .stoppingFleetWebook:
            return true
        case .fleetStarted, .fleetWebhookStarted, .ready:
            return false
        }
    }

    private var presentSettings: Bool {
        switch configurationState {
        case .ready, .readyWebhook:
            false
        case _:
            true
        }
    }

    private func performAction() {
        switch (configurationState, virtualMachineState) {
        case (.ready, .stoppingFleet),
             (.ready, .stoppingFleetWebook),
             (.readyWebhook, .stoppingFleet),
             (.readyWebhook, .stoppingFleetWebook),
             (.ready, .editorStarted):
            break
        case (.ready, .fleetStarted),
             (.ready, .fleetWebhookStarted),
             (.readyWebhook, .fleetStarted),
             (.readyWebhook, .fleetWebhookStarted):
            stopFleet()
        case (.ready, .ready):
            startFleet()
        case (.readyWebhook, .ready):
            startFleetWebhook()
        case (_, _):
            break
        }
    }
}

private extension FleetMenuBarItem {
    struct ContentButton<Label: View>: View {
        private let presentSettings: Bool
        private let onSelect: () -> Void
        private let label: () -> Label

        init(
            presentSettings: Bool,
            onSelect: @escaping () -> Void,
            @ViewBuilder label: @escaping () -> Label
        ) {
            self.presentSettings = presentSettings
            self.onSelect = onSelect
            self.label = label
        }

        var body: some View {
            if presentSettings {
                SettingsLink {
                    label()
                }
            } else {
                Button {
                    onSelect()
                } label: {
                    label()
                }
            }
        }
    }
}
