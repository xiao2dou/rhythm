import RhythmCore
import SwiftUI

@main
struct RhythmApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                timerEngine: appModel.timerEngine,
                settingsStore: appModel.settingsStore,
                sessionStore: appModel.sessionStore
            )
        } label: {
            RhythmMenuBarLabel()
        }
        .menuBarExtraStyle(.window)
    }
}
