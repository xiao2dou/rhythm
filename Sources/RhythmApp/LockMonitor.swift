import AppKit
import Foundation
import RhythmCore

@MainActor
final class LockMonitor {
    var onScreenLocked: (() -> Void)?

    private let distributedNotificationCenter = DistributedNotificationCenter.default()

    func start() {
        distributedNotificationCenter.addObserver(
            self,
            selector: #selector(handleScreenLocked),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )
    }

    func stop() {
        distributedNotificationCenter.removeObserver(self)
    }

    @objc private func handleScreenLocked() {
        onScreenLocked?()
    }
}

extension LockMonitor: ScreenLockMonitoring {}
