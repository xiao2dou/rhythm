import RhythmCore
import SwiftUI

@main
struct RhythmApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        MenuBarExtra("Rhythm", systemImage: "metronome") {
            MenuBarView(appModel: appModel)
        }
        .menuBarExtraStyle(.window)
    }
}
