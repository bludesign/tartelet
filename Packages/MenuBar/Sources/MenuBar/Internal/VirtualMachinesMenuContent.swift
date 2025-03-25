import SettingsDomain
import SwiftUI
import VirtualMachineDomain

struct VirtualMachinesMenuContent: View {
    enum Action {
        case startFleet
        case startFleetWebhook
        case stopFleet
        case startEditor
    }

    let configurationState: ConfigurationState
    let virtualMachineState: VirtualMachineState
    let onSelect: (Action) -> Void

    var body: some View {
        FleetMenuBarItem(
            configurationState: configurationState,
            virtualMachineState: virtualMachineState,
            startFleet: {
                onSelect(.startFleet)
            },
            startFleetWebhook: {
                onSelect(.startFleetWebhook)
            },
            stopFleet: {
                onSelect(.stopFleet)
            }
        )
        Divider()
        EditorMenuBarItem(
            configurationState: configurationState,
            virtualMachineState: virtualMachineState
        ) {
            onSelect(.startEditor)
        }
    }
}
