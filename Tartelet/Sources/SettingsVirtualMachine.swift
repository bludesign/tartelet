import SettingsDomain
import VirtualMachineData
import VirtualMachineDomain

struct SettingsVirtualMachine<SettingsStoreType: SettingsStore>: VirtualMachineDomain.VirtualMachine {
    var name: String {
        switch settingsStore.virtualMachine {
        case let .virtualMachine(name):
            return name
        case .unknown:
            fatalError("Cannot get name of virtual machine because none has been selected in settings")
        }
    }
    var canStart: Bool {
        switch settingsStore.virtualMachine {
        case .virtualMachine:
            return true
        case .unknown:
            return false
        }
    }

    let tart: Tart
    let settingsStore: SettingsStoreType
    let runnerLabels: String?

    private var virtualMachine: VirtualMachineDomain.VirtualMachine {
        TartVirtualMachine(tart: tart, vmName: name)
    }

    func start(netBridgedAdapter: String?, isHeadless: Bool) async throws {
        try await virtualMachine.start(netBridgedAdapter: netBridgedAdapter, isHeadless: isHeadless)
    }

    func clone(named newName: String, isInsecure: Bool) async throws -> VirtualMachineDomain.VirtualMachine {
        try await virtualMachine.clone(named: newName, isInsecure: isInsecure)
    }

    func setMemory(_ memory: String) async throws {
        try await virtualMachine.setMemory(memory)
    }

    func setCpu(_ cpu: String) async throws {
        try await virtualMachine.setCpu(cpu)
    }

    func delete() async throws {
        try await virtualMachine.delete()
    }

    func getIPAddress(shouldUseArpResolver: Bool) async throws -> String {
        try await virtualMachine.getIPAddress(shouldUseArpResolver: shouldUseArpResolver)
    }
}
