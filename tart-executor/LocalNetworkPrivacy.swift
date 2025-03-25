import Foundation
import Network

final class LocalNetworkPrivacy: NSObject {
    private var service: NetService?
    private var completion: ((Bool) -> Void)?
    private var timer: Timer?
    private var publishing = false

    override init() {
        service = .init(domain: "local.", type: "_lnp._tcp.", name: "LocalNetworkPrivacy", port: 1_100)
        super.init()
        service?.delegate = self
    }

    deinit {
        service?.stop()
    }

    @objc
    func checkAccessState(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        service?.publish()

        timer = .scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            guard let self else {
                return
            }
            service?.stop()
            service = nil
            timer.invalidate()
            self.completion?(false)
        }
    }
}

extension LocalNetworkPrivacy: NetServiceDelegate {
    func netServiceDidPublish(_ sender: NetService) {
        timer?.invalidate()
        service?.stop()
        service = nil
        completion?(true)
    }
}
