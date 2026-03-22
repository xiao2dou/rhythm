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
    }
}
