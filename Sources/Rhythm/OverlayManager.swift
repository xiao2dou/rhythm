import AppKit
import SwiftUI

@MainActor
final class OverlayManager: ObservableObject {
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var isShowing: Bool = false

    var onSkipped: (() -> Void)?
    var onCompleted: (() -> Void)?

    private var overlayWindow: NSWindow?
    private var keyMonitor: Any?
    private var countdownTimer: Timer?
    private var restEndAt: Date?

    func present(restSeconds: Int) {
        dismiss()

        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        remainingSeconds = max(1, restSeconds)
        restEndAt = Date().addingTimeInterval(TimeInterval(restSeconds))

        let contentView = OverlayView(
            remainingSeconds: { [weak self] in self?.remainingSeconds ?? 0 },
            skipAction: { [weak self] in self?.skipByEscape() }
        )

        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .stationary]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.contentView = NSHostingView(rootView: contentView)

        overlayWindow = window
        isShowing = true

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 {
                self.skipByEscape()
                return nil
            }
            return event
        }

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        RunLoop.main.add(countdownTimer!, forMode: .common)
    }

    func dismiss() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        restEndAt = nil

        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
        keyMonitor = nil

        overlayWindow?.orderOut(nil)
        overlayWindow = nil
        isShowing = false
        remainingSeconds = 0
    }

    func skipByEscape() {
        guard isShowing else { return }
        dismiss()
        onSkipped?()
    }

    private func tick() {
        guard let restEndAt else { return }
        let nextRemaining = max(0, Int(ceil(restEndAt.timeIntervalSinceNow)))
        remainingSeconds = nextRemaining

        if nextRemaining == 0 {
            dismiss()
            onCompleted?()
        }
    }
}

private struct OverlayView: View {
    let remainingSeconds: () -> Int
    let skipAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Text("休息时间")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(Self.format(remainingSeconds()))
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text("按 ESC 跳过本次休息")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Button("跳过") {
                    skipAction()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.2))
            }
        }
    }

    private static func format(_ seconds: Int) -> String {
        let minute = max(0, seconds) / 60
        let second = max(0, seconds) % 60
        return String(format: "%02d:%02d", minute, second)
    }
}
