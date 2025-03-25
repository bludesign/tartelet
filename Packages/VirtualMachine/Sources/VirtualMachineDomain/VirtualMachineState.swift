public enum VirtualMachineState {
    case ready
    case fleetStarted
    case stoppingFleet
    case fleetWebhookStarted
    case stoppingFleetWebook
    case editorStarted

    @MainActor
    public init(fleet: VirtualMachineFleet, fleetWebhook: VirtualMachineFleetWebhook, editor: VirtualMachineEditor) {
        if fleet.isStopping {
            self = .stoppingFleet
        } else if fleet.isStarted {
            self = .fleetStarted
        } else if fleetWebhook.isStopping {
            self = .stoppingFleetWebook
        } else if fleetWebhook.isStarted {
            self = .fleetWebhookStarted
        } else if editor.isStarted {
            self = .editorStarted
        } else {
            self = .ready
        }
    }
}
