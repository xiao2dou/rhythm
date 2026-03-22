import Foundation

enum RhythmMode {
    case focusing
    case resting
}

@MainActor
final class TimerEngine: ObservableObject {
    @Published private(set) var mode: RhythmMode = .focusing
    @Published private(set) var secondsUntilBreak: Int

    private let settingsStore: SettingsStore
    private let sessionStore: SessionStore
    private let overlayManager: OverlayManager
    private let lockMonitor: LockMonitor

    private var cycleStartedAt = Date()
    private var restStartedAt: Date?
    private var timer: Timer?

    init(
        settingsStore: SettingsStore,
        sessionStore: SessionStore,
        overlayManager: OverlayManager,
        lockMonitor: LockMonitor
    ) {
        self.settingsStore = settingsStore
        self.sessionStore = sessionStore
        self.overlayManager = overlayManager
        self.lockMonitor = lockMonitor
        self.secondsUntilBreak = settingsStore.focusSeconds

        settingsStore.onDidChange = { [weak self] in
            self?.resetCycle()
        }

        overlayManager.onSkipped = { [weak self] in
            self?.finishRest(skipped: true, skipReason: "esc")
        }

        overlayManager.onCompleted = { [weak self] in
            self?.finishRest(skipped: false, skipReason: nil)
        }

        lockMonitor.onScreenLocked = { [weak self] in
            self?.handleScreenLocked()
        }

        start()
    }

    func start() {
        timer?.invalidate()
        cycleStartedAt = Date()
        secondsUntilBreak = settingsStore.focusSeconds
        mode = .focusing
        lockMonitor.start()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func resetCycle() {
        overlayManager.dismiss()
        restStartedAt = nil
        cycleStartedAt = Date()
        mode = .focusing
        secondsUntilBreak = settingsStore.focusSeconds
    }

    func startBreakNow() {
        guard mode == .focusing else { return }
        beginResting()
    }

    func skipBreak() {
        guard mode == .resting else { return }
        overlayManager.skipByEscape()
    }

    private func tick() {
        guard mode == .focusing else { return }

        let elapsed = Int(Date().timeIntervalSince(cycleStartedAt))
        let remaining = max(0, settingsStore.focusSeconds - elapsed)
        secondsUntilBreak = remaining

        if remaining == 0 {
            beginResting()
        }
    }

    private func beginResting() {
        mode = .resting
        restStartedAt = Date()
        overlayManager.present(restSeconds: settingsStore.restSeconds)
    }

    private func finishRest(skipped: Bool, skipReason: String?) {
        guard mode == .resting, let restStartedAt else { return }

        let endedAt = Date()
        let actualSeconds = max(0, Int(endedAt.timeIntervalSince(restStartedAt)))
        let session = RestSession(
            scheduledRestSeconds: settingsStore.restSeconds,
            actualRestSeconds: actualSeconds,
            startedAt: restStartedAt,
            endedAt: endedAt,
            skipped: skipped,
            skipReason: skipReason
        )
        sessionStore.add(session)
        self.restStartedAt = nil

        cycleStartedAt = Date()
        mode = .focusing
        secondsUntilBreak = settingsStore.focusSeconds
    }

    private func handleScreenLocked() {
        resetCycle()
    }
}
