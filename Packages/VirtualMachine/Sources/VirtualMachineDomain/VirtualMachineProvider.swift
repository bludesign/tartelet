import Foundation

public protocol VirtualMachineProvider: AnyObject {
    func createVirtualMachine(
        imageName: String,
        name: String,
        runnerLabels: String?,
        isInsecure: Bool,
        memory: String?,
        cpu: String?
    ) async throws -> VirtualMachine
}
