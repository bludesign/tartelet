import Foundation

struct TartHostStatus: Codable {
    let inProgressJobs: Int
    let pendingJobs: Int
    let startedPendingJobs: Int
    let activeVirtualMachines: Int
    let virtualMachineLimit: Int

    var totalJobs: Int {
        inProgressJobs + pendingJobs
    }
}
