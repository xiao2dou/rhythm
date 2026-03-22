import Foundation

public enum RhythmMode: Equatable {
    case focusing
    case resting
}

@MainActor
public protocol RestSessionStoring: AnyObject {
    func add(_ session: RestSession)
}

@MainActor
public protocol RestOverlaying: AnyObject {
    var onSkipped: (() -> Void)? { get set }
    var onCompleted: (() -> Void)? { get set }
    func present(restSeconds: Int)
    func dismiss()
    func skipByEscape()
}

@MainActor
public protocol ScreenLockMonitoring: AnyObject {
    var onScreenLocked: (() -> Void)? { get set }
    func start()
    func stop()
}

@MainActor
public final class TimerEngine: ObservableObject {
    @Published public private(set) var mode: RhythmMode = .focusing
    @Published public private(set) var secondsUntilBreak: Int

    private let settingsStore: RhythmSettings
    private let sessionStore: RestSessionStoring
    private let overlayManager: RestOverlaying
    private let lockMonitor: ScreenLockMonitoring
    private let nowProvider: () -> Date
    private let useSystemTimer: Bool

    private var cycleStartedAt = Date()
    private var restStartedAt: Date?
    private var timer: Timer?

    public init(
        settingsStore: RhythmSettings,
        sessionStore: RestSessionStoring,
        overlayManager: RestOverlaying,
        lockMonitor: ScreenLockMonitoring,
        nowProvider: @escaping () -> Date = Date.init,
        autoStart: Bool = true,
        useSystemTimer: Bool = true
    ) {
        self.settingsStore = settingsStore
        self.sessionStore = sessionStore
        self.overlayManager = overlayManager
        self.lockMonitor = lockMonitor
        self.nowProvider = nowProvider
        self.useSystemTimer = useSystemTimer
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

        if autoStart {
            start()
        }
    }

    public func start() {
        timer?.invalidate()
        cycleStartedAt = nowProvider()
        secondsUntilBreak = settingsStore.focusSeconds
        mode = .focusing
        lockMonitor.start()

        if useSystemTimer {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.processTick(now: self.nowProvider())
                }
            }
            RunLoop.main.add(timer!, forMode: .common)
        }
    }

    public func resetCycle() {
        overlayManager.dismiss()
        restStartedAt = nil
        cycleStartedAt = nowProvider()
        mode = .focusing
        secondsUntilBreak = settingsStore.focusSeconds
    }

    public func startBreakNow() {
        guard mode == .focusing else { return }
        beginResting()
    }

    public func skipBreak() {
        guard mode == .resting else { return }
        overlayManager.skipByEscape()
    }

    public func processTick(now: Date) {
        guard mode == .focusing else { return }

        let elapsed = Int(now.timeIntervalSince(cycleStartedAt))
        let remaining = max(0, settingsStore.focusSeconds - elapsed)
        secondsUntilBreak = remaining

        if remaining == 0 {
            beginResting()
        }
    }

    private func beginResting() {
        mode = .resting
        restStartedAt = nowProvider()
        overlayManager.present(restSeconds: settingsStore.restSeconds)
    }

    private func finishRest(skipped: Bool, skipReason: String?) {
        guard mode == .resting, let restStartedAt else { return }

        let endedAt = nowProvider()
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

        cycleStartedAt = nowProvider()
        mode = .focusing
        secondsUntilBreak = settingsStore.focusSeconds
    }

    private func handleScreenLocked() {
        resetCycle()
    }
}
