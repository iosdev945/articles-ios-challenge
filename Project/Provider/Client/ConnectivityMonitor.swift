import Foundation
import Reachability
import XCGLogger

@MainActor
protocol ConnectivityMonitoring: AnyObject {
    var isOnline: Bool { get }
    var onChange: ((Bool) -> Void)? { get set }
    func start()
}

@MainActor
final class ConnectivityMonitor: ConnectivityMonitoring {
    private let reachability: Reachability?
    private let logger: XCGLogger
    private var observer: NSObjectProtocol?
    var onChange: ((Bool) -> Void)?
    // A notifier failure is not proof of being offline: allow a real request to determine the outcome.
    var isOnline: Bool { reachability?.connection != .unavailable }

    init(logger: XCGLogger) {
        self.logger = logger
        reachability = try? Reachability()
    }
    func start() {
        guard observer == nil, let reachability else { return }
        observer = NotificationCenter.default.addObserver(forName: .reachabilityChanged, object: reachability, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.logger.info("Connectivity: \(self.isOnline ? "online" : "offline")")
                self.onChange?(self.isOnline)
            }
        }
        do { try reachability.startNotifier() }
        catch { logger.warning("Reachability notifier failed: \(error.localizedDescription)") }
    }
    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        reachability?.stopNotifier()
    }
}
