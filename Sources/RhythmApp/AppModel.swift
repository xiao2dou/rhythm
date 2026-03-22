import AppKit
import Foundation
import RhythmCore

@MainActor
final class AppModel: ObservableObject {
    let settingsStore: SettingsStore
    let sessionStore: SessionStore
    let timerEngine: TimerEngine
    let overlayManager: OverlayManager

    init() {
        let settingsStore = SettingsStore()
        let sessionStore = SessionStore()
        let overlayManager = OverlayManager()
        let lockMonitor = LockMonitor()

        self.settingsStore = settingsStore
        self.sessionStore = sessionStore
        self.overlayManager = overlayManager
        self.timerEngine = TimerEngine(
            settingsStore: settingsStore,
            sessionStore: sessionStore,
            overlayManager: overlayManager,
            lockMonitor: lockMonitor
        )

        runOverlaySmokeIfNeeded()
    }

    private func runOverlaySmokeIfNeeded() {
        guard ProcessInfo.processInfo.environment["RHYTHM_SMOKE_OVERLAY"] == "1" else {
            return
        }

        print("[RhythmSmoke] start")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            print("[RhythmSmoke] trigger break")
            self.timerEngine.startBreakNow()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            guard let self else { return }
            print("[RhythmSmoke] force skip")
            self.timerEngine.skipBreak()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            print("[RhythmSmoke] end")
            NSApplication.shared.terminate(nil)
        }
    }
}
