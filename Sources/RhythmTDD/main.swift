import Foundation
import RhythmCore

@main
@MainActor
struct RhythmTDDRunner {
    static func main() {
        var failures = 0

        failures += run("settings change callback fires once") {
            let isolated = makeIsolatedDefaults()
            defer { isolated.defaults.removePersistentDomain(forName: isolated.suiteName) }

            let store = SettingsStore(userDefaults: isolated.defaults)
            var callbackCount = 0
            store.onDidChange = {
                callbackCount += 1
            }
            store.focusMinutes = 30

            guard store.focusMinutes == 30 else { return false }
            return callbackCount == 1
        }

        failures += run("settings normalization avoids recursion") {
            let isolated = makeIsolatedDefaults()
            defer { isolated.defaults.removePersistentDomain(forName: isolated.suiteName) }

            let store = SettingsStore(userDefaults: isolated.defaults)
            store.focusMinutes = 0
            return store.focusMinutes == 1
        }

        failures += run("timer skip records rest session") {
            let clock = TestClock(now: Date(timeIntervalSince1970: 1_000))
            let settings = FakeSettings(focusSeconds: 10, restSeconds: 5)
            let sessions = FakeSessionStore()
            let overlay = FakeOverlay()
            let lock = FakeLockMonitor()

            let engine = TimerEngine(
                settingsStore: settings,
                sessionStore: sessions,
                overlayManager: overlay,
                lockMonitor: lock,
                nowProvider: { clock.now },
                autoStart: false,
                useSystemTimer: false
            )

            engine.start()
            clock.now = clock.now.addingTimeInterval(10)
            engine.processTick(now: clock.now)
            guard engine.mode == .resting else { return false }
            guard overlay.lastPresentedRestSeconds == 5 else { return false }

            clock.now = clock.now.addingTimeInterval(2)
            overlay.onSkipped?()

            guard engine.mode == .focusing else { return false }
            guard engine.secondsUntilBreak == 10 else { return false }
            guard sessions.captured.count == 1 else { return false }
            guard sessions.captured[0].scheduledRestSeconds == 5 else { return false }
            guard sessions.captured[0].actualRestSeconds == 2 else { return false }
            guard sessions.captured[0].skipped else { return false }
            return sessions.captured[0].skipReason == "esc"
        }

        failures += run("screen lock resets cycle") {
            let clock = TestClock(now: Date(timeIntervalSince1970: 2_000))
            let settings = FakeSettings(focusSeconds: 12, restSeconds: 4)
            let sessions = FakeSessionStore()
            let overlay = FakeOverlay()
            let lock = FakeLockMonitor()

            let engine = TimerEngine(
                settingsStore: settings,
                sessionStore: sessions,
                overlayManager: overlay,
                lockMonitor: lock,
                nowProvider: { clock.now },
                autoStart: false,
                useSystemTimer: false
            )

            engine.start()
            clock.now = clock.now.addingTimeInterval(5)
            engine.processTick(now: clock.now)
            guard engine.secondsUntilBreak == 7 else { return false }

            lock.fireLock()

            guard engine.mode == .focusing else { return false }
            guard engine.secondsUntilBreak == 12 else { return false }
            return overlay.dismissCallCount == 1
        }

        if failures == 0 {
            print("All TDD checks passed.")
            exit(0)
        } else {
            print("TDD checks failed: \(failures)")
            exit(1)
        }
    }
}

@MainActor
private func run(_ name: String, check: () -> Bool) -> Int {
    let passed = check()
    if passed {
        print("PASS: \(name)")
        return 0
    } else {
        print("FAIL: \(name)")
        return 1
    }
}

private func makeIsolatedDefaults() -> (defaults: UserDefaults, suiteName: String) {
    let suiteName = "RhythmTDD.\(UUID().uuidString)"
    return (UserDefaults(suiteName: suiteName)!, suiteName)
}

@MainActor
private final class FakeSettings: RhythmSettings {
    var focusSeconds: Int
    var restSeconds: Int
    var onDidChange: (() -> Void)?

    init(focusSeconds: Int, restSeconds: Int) {
        self.focusSeconds = focusSeconds
        self.restSeconds = restSeconds
    }
}

@MainActor
private final class FakeSessionStore: RestSessionStoring {
    private(set) var captured: [RestSession] = []

    func add(_ session: RestSession) {
        captured.append(session)
    }
}

@MainActor
private final class FakeOverlay: RestOverlaying {
    var onSkipped: (() -> Void)?
    var onCompleted: (() -> Void)?
    private(set) var dismissCallCount = 0
    private(set) var lastPresentedRestSeconds: Int?

    func present(restSeconds: Int) {
        lastPresentedRestSeconds = restSeconds
    }

    func dismiss() {
        dismissCallCount += 1
    }

    func skipByEscape() {
        onSkipped?()
    }
}

@MainActor
private final class FakeLockMonitor: ScreenLockMonitoring {
    var onScreenLocked: (() -> Void)?
    func start() {}
    func stop() {}
    func fireLock() {
        onScreenLocked?()
    }
}

private final class TestClock {
    var now: Date

    init(now: Date) {
        self.now = now
    }
}
