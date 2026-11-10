#if DEBUG
import Foundation

enum DebugAccessOverride: String, CaseIterable {
    case real, free, full
}

struct DebugOverrides: Equatable {
    static let accessKey = "smackapad.debug.access"
    static let dayOffsetKey = "smackapad.debug.dayOffset"
    static let dayRange = -30...60

    var access: DebugAccessOverride = .real
    var dayOffset = 0

    init(access: DebugAccessOverride = .real, dayOffset: Int = 0) {
        self.access = access
        self.dayOffset = min(Self.dayRange.upperBound, max(Self.dayRange.lowerBound, dayOffset))
    }

    init(defaults: UserDefaults) {
        self.init(access: defaults.string(forKey: Self.accessKey).flatMap(DebugAccessOverride.init(rawValue:)) ?? .real,
                  dayOffset: defaults.integer(forKey: Self.dayOffsetKey))
    }

    func write(to settings: inout [String: Any]) {
        settings[Self.accessKey] = access == .real ? nil : access.rawValue
        settings[Self.dayOffsetKey] = dayOffset == 0 ? nil : dayOffset
    }
}

enum DebugProfileStorage {
    static let realDomain = Bundle.main.bundleIdentifier!
    static let testDomain = realDomain + ".debug.testProfile"
    static let testDefaults = UserDefaults(suiteName: testDomain)!

    static var isActive: Bool { testDefaults.string(forKey: DebugSnapshotStore.activeKey) != nil }
    static var defaults: UserDefaults { isActive ? testDefaults : .standard }
    static var progressURL: URL {
        let realURL = ProgressStore.defaultFileURL
        return isActive ? DebugSnapshotStore.testProgressURL(for: realURL) : realURL
    }
}

@MainActor
struct DebugSnapshotStore {
    static let realName = "_real"
    nonisolated static let activeKey = "smackapad.debug.activeScenario"
    static let currentProfileName = "Current profile copy"
    static var shared: Self {
        Self(progressURL: ProgressStore.defaultFileURL, defaults: .standard,
             domainName: DebugProfileStorage.realDomain, testDefaults: DebugProfileStorage.testDefaults,
             testDomainName: DebugProfileStorage.testDomain)
    }

    private static let settingsPrefix = "smackapad."
    private let real: Profile
    private let test: Profile
    private var snapshotsURL: URL { Self.snapshotsURL(for: real.progressURL) }
    private var pendingURL: URL { snapshotsURL.appendingPathComponent(".pending-test.plist") }
    private let files = FileManager.default

    private struct Profile {
        let progressURL: URL
        let defaults: UserDefaults
        let domainName: String
        var scenario: String? { defaults.string(forKey: DebugSnapshotStore.activeKey) }
    }

    init(progressURL: URL, defaults: UserDefaults, domainName: String,
         testDefaults: UserDefaults, testDomainName: String) {
        real = Profile(progressURL: progressURL, defaults: defaults, domainName: domainName)
        test = Profile(progressURL: Self.testProgressURL(for: progressURL),
                       defaults: testDefaults, domainName: testDomainName)
    }

    nonisolated static func testProgressURL(for realURL: URL) -> URL {
        snapshotsURL(for: realURL).appendingPathComponent(".active", isDirectory: true)
            .appendingPathComponent(realURL.lastPathComponent)
    }

    private nonisolated static func snapshotsURL(for progressURL: URL) -> URL {
        progressURL.deletingLastPathComponent().appendingPathComponent("DebugSnapshots", isDirectory: true)
    }

    var activeScenario: String? { test.scenario }
    var overrides: DebugOverrides { activeScenario == nil ? DebugOverrides() : DebugOverrides(defaults: test.defaults) }

    func capture(name: String) throws {
        let url = try customSnapshotURL(name)
        guard !files.fileExists(atPath: url.path) else { throw SnapshotError.nameInUse }
        try write(currentState(of: activeScenario == nil ? real : test), to: url)
    }

    func list() throws -> [String] {
        let entries: [URL]
        do {
            entries = try files.contentsOfDirectory(at: snapshotsURL, includingPropertiesForKeys: nil,
                                                     options: .skipsHiddenFiles)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return []
        }
        return entries.map(\.lastPathComponent)
            .filter { name in
                guard let url = try? customSnapshotURL(name) else { return false }
                return files.fileExists(atPath: url.path)
            }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    func delete(name: String) throws {
        let url = try customSnapshotURL(name)
        try files.removeItem(at: url.deletingLastPathComponent())
    }

    func apply(name: String) throws {
        try queueSnapshot(name: name)
        try finishPendingChange()
    }

    // The menu only stages a change. No live store can write between installation and launch.
    func queueSnapshot(name: String) throws {
        let snapshot = try read(customSnapshotURL(name))
        try queueScenario(snapshot, named: name)
    }

    func queueScenario(_ scenario: DebugScenario, catalog: LibraryCatalog, overrides: DebugOverrides) throws {
        let snapshot = try scenario.makeSnapshot(catalog: catalog, overrides: overrides)
        try queueScenario(snapshot, named: scenario.rawValue)
    }

    func queueOverrides(_ overrides: DebugOverrides) throws {
        var state = try currentState(of: activeScenario == nil ? real : test)
        overrides.write(to: &state.settings)
        try queueScenario(state, named: activeScenario ?? Self.currentProfileName)
    }

    func queueRestore() throws {
        guard activeScenario != nil else { throw SnapshotError.noActiveScenario }
        // The real profile may have advanced in Release since the backup was made.
        try queue(Snapshot())
    }

    private func queueScenario(_ state: Snapshot, named name: String) throws {
        guard !files.fileExists(atPath: pendingURL.path) else { throw SnapshotError.pendingChange }
        if activeScenario == nil {
            try write(currentState(of: real), to: snapshotURL(Self.realName))
        }
        var scenario = state
        scenario.settings[Self.activeKey] = name
        try queue(scenario)
    }

    private func queue(_ state: Snapshot) throws {
        guard !files.fileExists(atPath: pendingURL.path) else { throw SnapshotError.pendingChange }
        try write(state, to: pendingURL)
    }

    /// An interrupted install is replayed before any store can read or change the profile.
    func finishPendingChange() throws {
        try migrateLegacyProfile()
        guard files.fileExists(atPath: pendingURL.path) else { return }
        try install(read(pendingURL), in: test)
        try files.removeItem(at: pendingURL)
    }

    private func migrateLegacyProfile() throws {
        let legacyPending = snapshotsURL.appendingPathComponent(".pending.plist")
        let migration = snapshotsURL.appendingPathComponent(".migrate.plist")
        let hasLegacyPending = files.fileExists(atPath: legacyPending.path)
        if !files.fileExists(atPath: migration.path) {
            guard hasLegacyPending || real.scenario != nil else { return }
            let legacy = try hasLegacyPending ? read(legacyPending) : currentState(of: real)
            if legacy.settings[Self.activeKey] == nil {
                try install(legacy, in: real)
                try files.removeItem(at: legacyPending)
                return
            }
            try write(legacy, to: migration)
        }

        // Journal the old test state before restoring the real profile from its backup.
        let backup = try read(snapshotURL(Self.realName))
        try install(read(migration), in: test)
        try install(backup, in: real)
        if hasLegacyPending { try files.removeItem(at: legacyPending) }
        try files.removeItem(at: migration)
    }

    private func install(_ state: Snapshot, in profile: Profile) throws {
        if let progress = state.progress {
            try files.createDirectory(at: profile.progressURL.deletingLastPathComponent(),
                                      withIntermediateDirectories: true)
            try progress.write(to: profile.progressURL, options: .atomic)
        } else {
            do {
                try files.removeItem(at: profile.progressURL)
            } catch let error as CocoaError where error.code == .fileNoSuchFile {
                // An absent progress file is part of the snapshot.
            }
        }

        var domain = (profile.defaults.persistentDomain(forName: profile.domainName) ?? [:]).filter {
            !$0.key.hasPrefix(Self.settingsPrefix)
        }
        domain.merge(state.settings) { _, incoming in incoming }
        profile.defaults.setPersistentDomain(domain, forName: profile.domainName)
        // Keep the journal until preferences are persisted as well as progress.
        guard profile.defaults.synchronize() else { throw SnapshotError.settingsWriteFailed }
    }

    private func currentState(of profile: Profile) throws -> Snapshot {
        let progress: Data?
        do {
            progress = try Data(contentsOf: profile.progressURL)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            progress = nil
        }
        let settings = (profile.defaults.persistentDomain(forName: profile.domainName) ?? [:]).filter {
            $0.key.hasPrefix(Self.settingsPrefix)
        }
        return Snapshot(progress: progress, settings: settings)
    }

    private func customSnapshotURL(_ name: String) throws -> URL {
        guard !name.isEmpty, name.utf8.count <= 100, name == name.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.hasPrefix("."), name.caseInsensitiveCompare(Self.realName) != .orderedSame,
              name.rangeOfCharacter(from: CharacterSet.controlCharacters.union(CharacterSet(charactersIn: "/\\:"))) == nil
        else { throw SnapshotError.invalidName }
        return snapshotURL(name)
    }

    private func snapshotURL(_ name: String) -> URL {
        snapshotsURL.appendingPathComponent(name, isDirectory: true).appendingPathComponent("state.plist")
    }

    private func write(_ state: Snapshot, to url: URL) throws {
        try files.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        // One atomic file keeps the exact progress bytes and settings together.
        var values: [String: Any] = ["settings": state.settings]
        values["progress.json"] = state.progress
        let data = try PropertyListSerialization.data(fromPropertyList: values, format: .binary, options: 0)
        try data.write(to: url, options: .atomic)
    }

    private func read(_ url: URL) throws -> Snapshot {
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard let values = plist as? [String: Any],
              let settings = values["settings"] as? [String: Any],
              settings.keys.allSatisfy({ $0.hasPrefix(Self.settingsPrefix) }),
              values["progress.json"] == nil || values["progress.json"] is Data
        else { throw SnapshotError.invalidSnapshot }
        return Snapshot(progress: values["progress.json"] as? Data, settings: settings)
    }

    struct Snapshot {
        var progress: Data?
        var settings: [String: Any] = [:]
    }

    private enum SnapshotError: LocalizedError {
        case invalidName, nameInUse, invalidSnapshot, noActiveScenario, pendingChange, settingsWriteFailed

        var errorDescription: String? {
            switch self {
            case .invalidName: return "Use a name up to 100 bytes without slashes, colons, or a leading dot. _real is reserved."
            case .nameInUse: return "A snapshot with that name already exists."
            case .invalidSnapshot: return "The snapshot could not be read."
            case .noActiveScenario: return "No test profile is active."
            case .pendingChange: return "A profile change is pending. Open the app again to finish it."
            case .settingsWriteFailed: return "Profile settings could not be saved. Open the app again to retry."
            }
        }
    }
}
#endif
