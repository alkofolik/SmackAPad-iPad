import Foundation
import Observation

/// Observable store managing badge definitions and persisted earned dates.
@Observable
final class BadgeStore: @unchecked Sendable {
    static let shared = BadgeStore()

    static let storageKey = "smackapad.badges"

    private(set) var definitions: [BadgeDefinition] = []
    private(set) var definitionsById: [String: BadgeDefinition] = [:]
    /// Map of [badgeId: earnedAt date]
    private(set) var records: [String: Date] = [:]

    private let userDefaults: UserDefaults
    private let lock = NSRecursiveLock()

    var earnedCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return records.count
    }

    var totalCount: Int {
        definitions.count
    }

    init(userDefaults: UserDefaults = .standard, autoLoad: Bool = true) {
        self.userDefaults = userDefaults
        loadDefinitions()
        if autoLoad {
            loadRecords()
        }
    }

    func loadDefinitions() {
        let bundle = Bundle(for: BadgeStore.self)
        if let url = try? DataLoader.shared.findResourceURL(named: "badges", withExtension: "json", in: .main),
           let defs: [BadgeDefinition] = try? DataLoader.shared.loadJSON(from: url) {
            self.definitions = defs
            self.definitionsById = Dictionary(uniqueKeysWithValues: defs.map { ($0.id, $0) })
        } else if let fallbackURL = try? DataLoader.shared.findResourceURL(named: "badges", withExtension: "json", in: bundle),
                  let defs: [BadgeDefinition] = try? DataLoader.shared.loadJSON(from: fallbackURL) {
            self.definitions = defs
            self.definitionsById = Dictionary(uniqueKeysWithValues: defs.map { ($0.id, $0) })
        } else if let directURL = bundle.url(forResource: "badges", withExtension: "json"),
                  let defs: [BadgeDefinition] = try? DataLoader.shared.loadJSON(from: directURL) {
            self.definitions = defs
            self.definitionsById = Dictionary(uniqueKeysWithValues: defs.map { ($0.id, $0) })
        }
    }

    func loadRecords() {
        lock.lock()
        defer { lock.unlock() }
        guard let data = userDefaults.data(forKey: Self.storageKey) else {
            self.records = [:]
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([String: Date].self, from: data) {
            self.records = decoded
        } else {
            self.records = [:]
        }
    }

    func saveRecords() {
        lock.lock()
        defer { lock.unlock() }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(records) {
            userDefaults.set(data, forKey: Self.storageKey)
        }
    }

    func earnedDate(for badgeId: String) -> Date? {
        lock.lock()
        defer { lock.unlock() }
        return records[badgeId]
    }

    func isEarned(badgeId: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return records[badgeId] != nil
    }

    /// Awards badges silently (e.g. at app start or legacy import) with the given timestamp.
    /// Does not revoke any previously earned badge.
    @discardableResult
    func awardSilently(
        progress: [Int: LessonProgress],
        catalog: LibraryCatalog,
        trainingLog: TrainingLog = TrainingLog(),
        at date: Date = Date()
    ) -> [String] {
        lock.lock()
        let currentKeys = Set(records.keys)
        lock.unlock()

        let result = BadgeEvaluator.evaluate(
            progress: progress,
            catalog: catalog,
            definitions: definitions,
            currentlyEarned: currentKeys,
            trainingLog: trainingLog
        )

        if !result.newlyEarnedBadgeIds.isEmpty {
            lock.lock()
            for id in result.newlyEarnedBadgeIds {
                if records[id] == nil {
                    records[id] = date
                }
            }
            saveRecords()
            lock.unlock()
        }

        return result.newlyEarnedBadgeIds
    }

    /// Evaluates current progress and awards newly earned badges, returning their definitions.
    func evaluate(
        progress: [Int: LessonProgress],
        catalog: LibraryCatalog,
        trainingLog: TrainingLog = TrainingLog(),
        onlyGroup: BadgeGroup? = nil,
        at date: Date = Date()
    ) -> [BadgeDefinition] {
        lock.lock()
        let currentKeys = Set(records.keys)
        lock.unlock()

        let defsToEvaluate: [BadgeDefinition]
        if let onlyGroup {
            defsToEvaluate = definitions.filter { $0.group == onlyGroup }
        } else {
            defsToEvaluate = definitions
        }

        let result = BadgeEvaluator.evaluate(
            progress: progress,
            catalog: catalog,
            definitions: defsToEvaluate,
            currentlyEarned: currentKeys,
            trainingLog: trainingLog
        )

        guard !result.newlyEarnedBadgeIds.isEmpty else { return [] }

        lock.lock()
        var newlyAwarded: [BadgeDefinition] = []
        for id in result.newlyEarnedBadgeIds {
            if records[id] == nil {
                records[id] = date
                if let def = definitionsById[id] {
                    newlyAwarded.append(def)
                }
            }
        }
        saveRecords()
        lock.unlock()

        return newlyAwarded
    }

    func resetAll() {
        lock.lock()
        records.removeAll()
        userDefaults.removeObject(forKey: Self.storageKey)
        lock.unlock()
    }
}
