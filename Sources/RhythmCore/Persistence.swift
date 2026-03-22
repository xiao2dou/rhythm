import Foundation

public struct RestSession: Codable, Identifiable {
    public let id: UUID
    public let scheduledRestSeconds: Int
    public let actualRestSeconds: Int
    public let startedAt: Date
    public let endedAt: Date
    public let skipped: Bool
    public let skipReason: String?
    public let createdAt: Date

    public init(
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
public final class SessionStore: ObservableObject {
    @Published public private(set) var sessions: [RestSession] = []

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init() {
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

    public func add(_ session: RestSession) {
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

extension SessionStore: RestSessionStoring {}

@MainActor
public protocol RhythmSettings: AnyObject {
    var focusSeconds: Int { get }
    var restSeconds: Int { get }
    var onDidChange: (() -> Void)? { get set }
}

@MainActor
public final class SettingsStore: ObservableObject {
    public static let focusMinutesKey = "focusMinutes"
    public static let restMinutesKey = "restMinutes"

    @Published public var focusMinutes: Int {
        didSet {
            let normalized = max(1, focusMinutes)
            if focusMinutes != normalized {
                focusMinutes = normalized
                return
            }
            if oldValue == focusMinutes {
                return
            }
            userDefaults.set(focusMinutes, forKey: Self.focusMinutesKey)
            onDidChange?()
        }
    }

    @Published public var restMinutes: Int {
        didSet {
            let normalized = max(1, restMinutes)
            if restMinutes != normalized {
                restMinutes = normalized
                return
            }
            if oldValue == restMinutes {
                return
            }
            userDefaults.set(restMinutes, forKey: Self.restMinutesKey)
            onDidChange?()
        }
    }

    public var onDidChange: (() -> Void)?

    public var focusSeconds: Int { focusMinutes * 60 }
    public var restSeconds: Int { restMinutes * 60 }

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let storedFocus = userDefaults.integer(forKey: Self.focusMinutesKey)
        let storedRest = userDefaults.integer(forKey: Self.restMinutesKey)
        self.focusMinutes = max(1, storedFocus == 0 ? 25 : storedFocus)
        self.restMinutes = max(1, storedRest == 0 ? 5 : storedRest)
    }
}

extension SettingsStore: RhythmSettings {}
