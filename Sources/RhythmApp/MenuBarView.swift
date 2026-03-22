import AppKit
import RhythmCore
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            statusSection
            Divider()
            configSection
            Divider()
            sessionsSection
            Divider()
            actionSection
        }
        .padding(14)
        .frame(width: 360)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(appModel.timerEngine.mode == .focusing ? "当前状态：专注中" : "当前状态：休息中")
                .font(.headline)

            if appModel.timerEngine.mode == .focusing {
                Text("距离休息还有 \(formatDuration(appModel.timerEngine.secondsUntilBreak))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("休息遮罩已显示，按 ESC 可跳过")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var configSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("节奏设置")
                .font(.subheadline.weight(.semibold))

            HStack {
                Text("专注时长")
                Spacer()
                Stepper(
                    value: Binding(
                        get: { appModel.settingsStore.focusMinutes },
                        set: { appModel.settingsStore.focusMinutes = $0 }
                    ),
                    in: 1 ... 240
                ) {
                    Text("\(appModel.settingsStore.focusMinutes) 分钟")
                        .frame(width: 100, alignment: .trailing)
                }
                .frame(width: 180)
            }

            HStack {
                Text("休息时长")
                Spacer()
                Stepper(
                    value: Binding(
                        get: { appModel.settingsStore.restMinutes },
                        set: { appModel.settingsStore.restMinutes = $0 }
                    ),
                    in: 1 ... 90
                ) {
                    Text("\(appModel.settingsStore.restMinutes) 分钟")
                        .frame(width: 100, alignment: .trailing)
                }
                .frame(width: 180)
            }
        }
    }

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("最近记录")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(appModel.sessionStore.sessions.count) 次")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if appModel.sessionStore.sessions.isEmpty {
                Text("暂无记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(appModel.sessionStore.sessions.prefix(5)) { session in
                    HStack {
                        Text(timeLabel(session.startedAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(
                            session.skipped
                                ? "跳过 \(formatDuration(session.actualRestSeconds))"
                                : "完成 \(formatDuration(session.actualRestSeconds))"
                        )
                        .font(.caption)
                        .foregroundStyle(session.skipped ? .orange : .green)
                    }
                }
            }
        }
    }

    private var actionSection: some View {
        HStack {
            if appModel.timerEngine.mode == .focusing {
                Button("立即休息") {
                    appModel.timerEngine.startBreakNow()
                }
            } else {
                Button("跳过本次休息") {
                    appModel.timerEngine.skipBreak()
                }
            }

            Button("重置计时") {
                appModel.timerEngine.resetCycle()
            }

            Spacer()

            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minute = max(0, seconds) / 60
        let second = max(0, seconds) % 60
        return String(format: "%02d:%02d", minute, second)
    }

    private func timeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
