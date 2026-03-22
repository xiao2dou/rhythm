import Foundation

struct RestSession: Codable, Identifiable {
    let id: UUID
    let scheduledRestSeconds: Int
    let actualRestSeconds: Int
    let startedAt: Date
    let endedAt: Date
    let skipped: Bool
    let skipReason: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        scheduledRestSeconds: Int,
        actualRestSeconds: Int,
        startedAt: Date,
        endedAt: Date,
        skipped: Bool,
        skipReason: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.scheduledRestSeconds = scheduledRestSeconds
        self.actualRestSeconds = actualRestSeconds
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.skipped = skipped
        self.skipReason = skipReason
        self.createdAt = createdAt
    }
}

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var sessions: [RestSession] = []

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("Rhythm", isDirectory: true)
        self.fileURL = directory.appendingPathComponent("sessions.json", isDirectory: false)

        if !fm.fileExists(atPath: directory.path) {
            try? fm.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        load()
    }

    func add(_ session: RestSession) {
        sessions.insert(session, at: 0)
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            sessions = []
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            sessions = try decoder.decode([RestSession].self, from: data)
        } catch {
            sessions = []
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(sessions)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Intentionally swallow write errors in V1 to avoid crashing the menu bar app.
        }
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    static let focusMinutesKey = "focusMinutes"
    static let restMinutesKey = "restMinutes"

    @Published var focusMinutes: Int {
        didSet {
            focusMinutes = max(1, focusMinutes)
            userDefaults.set(focusMinutes, forKey: Self.focusMinutesKey)
            onDidChange?()
        }
    }

    @Published var restMinutes: Int {
        didSet {
            restMinutes = max(1, restMinutes)
            userDefaults.set(restMinutes, forKey: Self.restMinutesKey)
            onDidChange?()
        }
    }

    var onDidChange: (() -> Void)?

    var focusSeconds: Int { focusMinutes * 60 }
    var restSeconds: Int { restMinutes * 60 }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let storedFocus = userDefaults.integer(forKey: Self.focusMinutesKey)
        let storedRest = userDefaults.integer(forKey: Self.restMinutesKey)
        self.focusMinutes = max(1, storedFocus == 0 ? 25 : storedFocus)
        self.restMinutes = max(1, storedRest == 0 ? 5 : storedRest)
    }
}
