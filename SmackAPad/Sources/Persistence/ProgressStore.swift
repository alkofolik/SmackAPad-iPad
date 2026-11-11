//
//  ProgressStore.swift
//  SmackAPad
//

import Foundation
import Observation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - ProgressStore

/// Observable manager for lesson progress saved as a JSON file in the Documents directory.
@Observable
public final class ProgressStore: @unchecked Sendable {
    #if DEBUG
    public static let shared = ProgressStore(fileURL: DebugProfileStorage.progressURL)
    #else
    public static let shared = ProgressStore()
    #endif

    /// Ticket 20: retired First steps IDs and their retained Intro equivalents.
    public static let duplicateIntroLessonMap: [Int: Int] = [
        1: 10001, 2: 10015, 3: 10008, 4: 10010,
        5: 10011, 7: 10016, 8: 10013, 9: 10014
    ]

    public private(set) var records: [Int: LessonProgress] = [:]
    public private(set) var trainingLog: TrainingLog = TrainingLog()
    public private(set) var lastSaveError: Error?
    public private(set) var lastLoadError: Error?
    private var hasFinishedLoading = false

    var loadedSuccessfully: Bool { hasFinishedLoading && lastLoadError == nil }

    public var hasUnreadableProgressBackup: Bool { unreadableProgressBackupURL != nil }

    public let fileURL: URL
    private let lock = NSRecursiveLock()
    private var lifecycleObservers: [Any] = []
    private var unreadableProgressBackupURL: URL?

    /// Default progress file location in app Documents: `<Documents>/progress.json`.
    public static var defaultFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("progress.json")
    }

    public init(fileURL: URL? = nil, autoLoad: Bool = true) {
        self.fileURL = fileURL ?? Self.defaultFileURL
        if autoLoad {
            load()
        }
        setupLifecycleObservers()
    }

    deinit {
        #if canImport(UIKit)
        for observer in lifecycleObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        #endif
    }

    private func setupLifecycleObservers() {
        #if canImport(UIKit)
        let backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            try? self?.save()
        }

        let terminateObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            try? self?.save()
        }

        lifecycleObservers.append(contentsOf: [backgroundObserver, terminateObserver])
        #endif
    }

    // MARK: - Load & Save

    /// Loads progress from `progress.json`.
    /// Missing files start fresh; unreadable files are backed up and block all saves.
    public func load() {
        lock.lock()
        defer {
            hasFinishedLoading = true
            lock.unlock()
        }

        unreadableProgressBackupURL = nil
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let root = try decoder.decode(ProgressRoot.self, from: data)
            self.records = root.lessons
            self.trainingLog = root.trainingLog
            self.lastLoadError = nil
            var didMigrate = migrateDuplicateIntroProgress()
            if migrateLegacyMasteredReviewSchedule() {
                didMigrate = true
            }
            if migrateTwoReviewsStar3() {
                didMigrate = true
            }
            if didMigrate {
                // Atomic saving leaves the original file intact on failure. Keep merged
                // progress in memory for the next normal save; do not treat it as a decode error.
                try? save()
            }
        } catch {
            if (error as? CocoaError)?.code == .fileReadNoSuchFile {
                self.records = [:]
                self.trainingLog = TrainingLog()
                self.lastLoadError = nil
                return
            }
            // Preserve the original before clearing memory. A failed copy must still block saves.
            do {
                unreadableProgressBackupURL = try backupUnreadableProgress()
            } catch {
                print("SmackAPad.ProgressStore: Error backing up unreadable progress: \(error)")
            }
            print("SmackAPad.ProgressStore: Warning - failed to read progress from \(fileURL.path): \(error). Saving is blocked.")
            self.records = [:]
            self.trainingLog = TrainingLog()
            self.lastLoadError = error
        }
    }

    /// Keeps distinct, timestamped copies even when failures occur within the same second.
    private func backupUnreadableProgress() throws -> URL {
        let manager = FileManager.default
        let directory = fileURL.deletingLastPathComponent()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.isLenient = false
        let prefix = "progress.corrupt-"
        let suffix = ".json"
        let backups = try manager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { url in
                let name = url.lastPathComponent
                guard name.hasPrefix(prefix), name.hasSuffix(suffix) else { return false }
                let timestamp = String(name.dropFirst(prefix.count).dropLast(suffix.count))
                guard let date = formatter.date(from: timestamp) else { return false }
                return formatter.string(from: date) == timestamp
            }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        var date = Date()
        if let newest = backups.last {
            let timestamp = String(newest.lastPathComponent.dropFirst(prefix.count).dropLast(suffix.count))
            if let newestDate = formatter.date(from: timestamp) {
                date = max(date, newestDate.addingTimeInterval(1))
            }
        }
        let backupURL = directory.appendingPathComponent("\(prefix)\(formatter.string(from: date))\(suffix)")
        // copyItem refuses to replace an existing destination. Prune only after a successful copy.
        try manager.copyItem(at: fileURL, to: backupURL)
        for oldBackup in backups.prefix(max(0, backups.count - 4)) {
            do {
                try manager.removeItem(at: oldBackup)
            } catch {
                print("SmackAPad.ProgressStore: Error pruning progress backup: \(error)")
            }
        }
        return backupURL
    }

    /// Explicit recovery choice. Never unblock saving unless the unreadable file has a copy.
    public func startWithEmptyProgress() throws {
        lock.lock()
        defer { lock.unlock() }
        guard lastLoadError != nil else { return }
        if unreadableProgressBackupURL.map({ FileManager.default.fileExists(atPath: $0.path) }) != true {
            unreadableProgressBackupURL = try backupUnreadableProgress()
        }
        records = [:]
        trainingLog = TrainingLog()
        lastLoadError = nil
    }

    /// Consuming retired records makes the migration idempotent without a separate marker.
    private func migrateDuplicateIntroProgress() -> Bool {
        Self.migrateDuplicateIntroProgress(in: &records)
    }

    /// Shared canonicalization for loaded and imported progress.
    @discardableResult
    static func migrateDuplicateIntroProgress(in records: inout [Int: LessonProgress]) -> Bool {
        var changed = false
        for retiredID in duplicateIntroLessonMap.keys.sorted() {
            guard let introID = duplicateIntroLessonMap[retiredID],
                  let source = records.removeValue(forKey: retiredID) else { continue }
            records[introID] = merging(records[introID] ?? LessonProgress(), with: source)
            changed = true
        }
        return changed
    }

    private func migrateLegacyMasteredReviewSchedule() -> Bool {
        Self.migrateLegacyMasteredReviewSchedule(in: &records)
    }

    /// Ticket 98: lessons that had star 2 before this update get their first review tomorrow.
    @discardableResult
    static func migrateLegacyMasteredReviewSchedule(in records: inout [Int: LessonProgress], today: String = AppCalendar.today()) -> Bool {
        var changed = false
        for (id, record) in records {
            if record.mastery && record.reviewDueDay == nil && record.settled != true {
                var updated = record
                let migrated = ReviewScheduler.migrationSchedule(today: today)
                updated.reviewStep = migrated.reviewStep
                updated.reviewDueDay = migrated.reviewDueDay
                updated.settled = migrated.settled
                records[id] = updated
                changed = true
            }
        }
        return changed
    }

    private func migrateTwoReviewsStar3() -> Bool {
        Self.migrateTwoReviewsStar3(in: &records)
    }

    /// Ticket 143: lessons with reviewStep >= 2 or settled == true get star 3 silently.
    @discardableResult
    public static func migrateTwoReviewsStar3(in records: inout [Int: LessonProgress]) -> Bool {
        var changed = false
        for (id, record) in records {
            let passedTwoReviews = (record.reviewStep ?? 0) >= LearningRules.reviewsForMemoryStar || record.settled == true
            if passedTwoReviews && !record.memory {
                var updated = record
                updated.memory = true
                records[id] = updated
                changed = true
            }
        }
        return changed
    }

    public static func merging(_ existing: LessonProgress, with incoming: LessonProgress) -> LessonProgress {
        var result = existing
        result.passed = existing.passed || incoming.passed
        result.mastery = existing.mastery || incoming.mastery
        result.memory = existing.memory || incoming.memory
        result.hasPlayed = existing.hasPlayed || incoming.hasPlayed
        result.bestScore = max(existing.bestScore, incoming.bestScore)
        if result.currentBpm <= 0 { result.currentBpm = incoming.currentBpm }
        if let d1 = existing.masteryDay, let d2 = incoming.masteryDay {
            result.masteryDay = min(d1, d2)
        } else {
            result.masteryDay = existing.masteryDay ?? incoming.masteryDay
        }
        result.lastPlayedDay = [existing.lastPlayedDay, incoming.lastPlayedDay].compactMap { $0 }.max()
        if let d1 = existing.lastReviewFailDay, let d2 = incoming.lastReviewFailDay {
            result.lastReviewFailDay = max(d1, d2)
        } else {
            result.lastReviewFailDay = existing.lastReviewFailDay ?? incoming.lastReviewFailDay
        }
        let mergedSchedule = ReviewScheduler.merge(existing.reviewSchedule, incoming.reviewSchedule)
        result.reviewSchedule = mergedSchedule
        return result
    }

    public static func merging(_ existing: TrainingLog, with incoming: TrainingLog) -> TrainingLog {
        TrainingLog.merging(existing, with: incoming)
    }

    // MARK: - Export / Import

    public struct ImportSummary: Equatable, Sendable {
        public let updatedLessonsCount: Int
        public let totalImportedLessons: Int
        public let isFreshDevice: Bool

        public init(updatedLessonsCount: Int, totalImportedLessons: Int, isFreshDevice: Bool) {
            self.updatedLessonsCount = updatedLessonsCount
            self.totalImportedLessons = totalImportedLessons
            self.isFreshDevice = isFreshDevice
        }
    }

    /// Exports full application state into a portable backup envelope.
    public func exportEnvelope() -> ProgressBackupEnvelope {
        lock.lock()
        let currentLessons = records
        let currentTraining = trainingLog
        lock.unlock()

        let badges = BadgeStore.shared.records
        let settings = SettingsManager.shared.exportSettings()
        let appVersion: String
        if let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            appVersion = "\(short) (\(build))"
        } else {
            appVersion = "1.0"
        }

        return ProgressBackupEnvelope(
            app: ProgressBackup.appIdentifier,
            formatVersion: ProgressBackup.currentFormatVersion,
            exportedAt: AppCalendar.now(),
            appVersion: appVersion,
            deviceId: SettingsManager.deviceId,
            progress: currentLessons,
            trainingLog: currentTraining,
            badges: badges,
            settings: settings
        )
    }

    /// Serializes the current state into backup JSON data.
    public func exportData() throws -> Data {
        let envelope = exportEnvelope()
        return try ProgressBackup.encode(envelope: envelope)
    }

    /// Imports backup JSON data, validating format and applying "never lose anything" merge rules.
    public func importFromData(_ data: Data, validLessonIds: Set<Int>? = nil) throws -> ImportSummary {
        let envelope = try ProgressBackup.decode(from: data)
        return try importEnvelope(envelope, validLessonIds: validLessonIds)
    }

    /// Applies an imported backup envelope safely with atomic replacement and in-place reload.
    public func importEnvelope(_ envelope: ProgressBackupEnvelope, validLessonIds: Set<Int>? = nil) throws -> ImportSummary {
        lock.lock()
        defer { lock.unlock() }

        if let lastLoadError {
            throw lastLoadError
        }

        // Hard constraint 4: Before an import is applied, the current state is saved automatically to
        // <Documents>/Backups/before-import-<timestamp>.json (keep the last 5).
        // If anything fails mid-import, nothing on disk changes (write to temp, then atomic replace).
        let currentEnvelope = exportEnvelope()
        let backupsDir = fileURL.deletingLastPathComponent().appendingPathComponent("Backups", isDirectory: true)
        try BackupStorage.createPreImportBackup(envelope: currentEnvelope, directory: backupsDir)

        let isFresh = ProgressMerge.isFreshDevice(
            records: records,
            trainingLog: trainingLog,
            earnedBadgesCount: BadgeStore.shared.earnedCount
        )

        let catalogIds = validLessonIds ?? (LessonStore.shared.lessons.isEmpty ? nil : Set(LessonStore.shared.lessons.map(\.id)))
        let mergeResult = ProgressMerge.mergeLessons(
            localLessons: records,
            incomingLessons: envelope.progress,
            validLessonIds: catalogIds
        )

        let mergedTraining = ProgressMerge.mergeTrainingLog(
            local: trainingLog,
            incoming: envelope.trainingLog
        )

        // Write to temp file then atomic replace
        let parentDir = fileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentDir.path) {
            try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }
        let tempURL = parentDir.appendingPathComponent("progress.json.tmp")
        let root = ProgressRoot(formatVersion: ProgressBackup.currentFormatVersion, lessons: mergeResult.merged, trainingLog: mergedTraining)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(root)
        try data.write(to: tempURL, options: .atomic)

        let manager = FileManager.default
        if manager.fileExists(atPath: fileURL.path) {
            _ = try manager.replaceItemAt(fileURL, withItemAt: tempURL)
        } else {
            try manager.moveItem(at: tempURL, to: fileURL)
        }

        // Reload in place without app restart
        self.records = mergeResult.merged
        self.trainingLog = mergedTraining

        // Update badges and silently award any newly earned badges
        BadgeStore.shared.importBadges(envelope.badges)
        BadgeStore.shared.awardSilently(progress: mergeResult.merged, catalog: LessonStore.shared.libraryCatalog, trainingLog: mergedTraining)

        // If fresh device, apply settings
        if isFresh {
            SettingsManager.shared.applyImportedSettings(envelope.settings)
        }

        ReviewReminderScheduler.shared.reschedule()

        return ImportSummary(
            updatedLessonsCount: mergeResult.updatedCount,
            totalImportedLessons: envelope.progress.count,
            isFreshDevice: isFresh
        )
    }

    #if DEBUG
    /// Validation and mapping finish before touching either the backup or stored progress.
    func importLegacyBackup(_ data: Data) throws -> (lessons: Int, starsAdded: Int) {
        let imported = try LegacyProgressImport.map(data)
        lock.lock()
        defer { lock.unlock() }
        if let lastLoadError { throw lastLoadError }

        let previous = records
        let merged = LegacyProgressImport.merge(existing: previous, imported: imported)
        let starsAdded = merged.reduce(0) { $0 + LibraryStarFilter.stars($1.value) }
            - previous.reduce(0) { $0 + LibraryStarFilter.stars($1.value) }
        let manager = FileManager.default
        try manager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let backupURL = fileURL.appendingPathExtension("pre-import")
        // Keep the first snapshot so a repeated import cannot replace it with imported progress.
        if !manager.fileExists(atPath: backupURL.path) {
            if manager.fileExists(atPath: fileURL.path) {
                try Data(contentsOf: fileURL).write(to: backupURL, options: .atomic)
            } else {
                let snapshot = Dictionary(uniqueKeysWithValues: previous.map { (String($0.key), $0.value) })
                try JSONEncoder().encode(snapshot).write(to: backupURL, options: .atomic)
            }
        }
        records = merged
        do {
            try save()
            BadgeStore.shared.awardSilently(progress: merged, catalog: LessonStore.shared.libraryCatalog)
        } catch {
            records = previous
            throw error
        }
        return (imported.count, starsAdded)
    }
    #endif

    /// Atomically saves progress records to `progress.json`.
    public func save() throws {
        lock.lock()
        defer { lock.unlock() }
        guard lastLoadError == nil else { return }

        let parentDir = fileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentDir.path) {
            try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        let root = ProgressRoot(formatVersion: ProgressBackup.currentFormatVersion, lessons: records, trainingLog: trainingLog)

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(root)
            try data.write(to: fileURL, options: .atomic)
            self.lastSaveError = nil
        } catch {
            self.lastSaveError = error
            print("SmackAPad.ProgressStore: Error saving progress to \(fileURL.path): \(error)")
            throw error
        }
    }

    // MARK: - Query Methods

    /// Returns the progress record for a lesson ID if it exists.
    public func progress(for lessonId: Int) -> LessonProgress? {
        lock.lock()
        defer { lock.unlock() }
        return records[lessonId]
    }

    /// Returns whether the specified lesson has been passed.
    public func isPassed(lessonId: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return records[lessonId]?.passed ?? false
    }

    /// Two-star completion for stage access; the optional memory star does not affect it.
    public func isCompleted(lessonId: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let record = records[lessonId] else { return false }
        return record.passed && record.mastery
    }

    /// Returns whether the specified lesson has been mastered.
    public func isMastered(lessonId: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return records[lessonId]?.mastery ?? false
    }

    /// Total count of passed lessons.
    public var passedCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return records.values.filter(\.passed).count
    }

    /// Total count of mastered lessons.
    public var masteredCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return records.values.filter(\.mastery).count
    }

    /// Set of lesson IDs that are passed.
    public func passedLessonIds() -> Set<Int> {
        lock.lock()
        defer { lock.unlock() }
        return Set(records.filter { $0.value.passed }.map(\.key))
    }

    /// Set of lesson IDs that are mastered.
    public func masteredLessonIds() -> Set<Int> {
        lock.lock()
        defer { lock.unlock() }
        return Set(records.filter { $0.value.mastery }.map(\.key))
    }

    /// Learning credit is isolated by physical pad mode. Missing old-file counters start at zero.
    func learningCredit(lessonId: Int, padCount: Int) -> StarStreak {
        progress(for: lessonId)?.learningCreditByPadCount[String(padCount)] ?? StarStreak()
    }

    func setLearningCredit(_ credit: StarStreak, lessonId: Int, padCount: Int, autoSave: Bool = true) {
        lock.lock()
        var record = records[lessonId] ?? LessonProgress()
        record.learningCreditByPadCount[String(padCount)] = credit
        record.modifiedAt = AppCalendar.now()
        records[lessonId] = record
        lock.unlock()
        if autoSave { try? save() }
    }

    // MARK: - Mutation Methods

    /// Updates the record for a lesson after an attempt and saves immediately by default.
    /// Cumulative status: `passed` and `mastery` remain true once achieved; best score and BPM are tracked.
    public func recordResult(
        lessonId: Int,
        passed: Bool,
        mastery: Bool,
        bpm: Int,
        score: Float,
        memory: Bool = false,
        autoSave: Bool = true,
        today: String = AppCalendar.today()
    ) {
        lock.lock()
        let hadStar = (records[lessonId]?.passed == true) || (records[lessonId]?.mastery == true) || (records[lessonId]?.memory == true)

        var record = records[lessonId] ?? LessonProgress(
            passed: false,
            mastery: false,
            currentBpm: bpm,
            bestScore: score
        )

        record.hasPlayed = true
        record.lastPlayedDay = today
        record.passed = record.passed || passed
        let wasMastered = record.mastery
        record.mastery = record.mastery || mastery
        if record.mastery && !wasMastered {
            if record.masteryDay == nil {
                record.masteryDay = today
            }
            if record.reviewDueDay == nil && record.settled != true {
                let initial = ReviewScheduler.initialSchedule(masteryDay: record.masteryDay ?? today)
                record.reviewStep = initial.reviewStep
                record.reviewDueDay = initial.reviewDueDay
                record.settled = initial.settled
            }
        }
        record.memory = record.memory || memory
        if bpm > record.currentBpm {
            record.currentBpm = bpm
        }
        if score > record.bestScore {
            record.bestScore = score
        }
        record.modifiedAt = AppCalendar.now()

        records[lessonId] = record
        lock.unlock()

        if autoSave {
            try? save()
        }
        ReviewReminderScheduler.shared.reschedule()

        let hasStarNow = record.passed || record.mastery || record.memory
        if !hadStar && hasStarNow {
            let env = exportEnvelope()
            let backupsDir = fileURL.deletingLastPathComponent().appendingPathComponent("Backups", isDirectory: true)
            try? BackupStorage.recordDailyAutoBackupIfNeeded(envelope: env, today: today, directory: backupsDir)
        }
    }

    /// Convenience helper to record a passing result for a lesson.
    public func recordPass(
        lessonId: Int,
        bpm: Int = 100,
        score: Float = 0.85,
        mastery: Bool = false,
        autoSave: Bool = true,
        today: String = AppCalendar.today()
    ) {
        recordResult(lessonId: lessonId, passed: true, mastery: mastery, bpm: bpm, score: score, autoSave: autoSave, today: today)
    }

    /// Directly sets or replaces the progress record for a lesson.
    public func setProgress(
        _ progress: LessonProgress,
        for lessonId: Int,
        autoSave: Bool = true
    ) {
        lock.lock()
        var updated = progress
        updated.modifiedAt = AppCalendar.now()
        records[lessonId] = updated
        lock.unlock()

        if autoSave {
            try? save()
        }
    }

    /// Updates review schedule for a lesson.
    public func updateReviewSchedule(_ schedule: ReviewScheduler.ScheduleState, for lessonId: Int, autoSave: Bool = true) {
        lock.lock()
        var record = records[lessonId] ?? LessonProgress()
        record.reviewSchedule = schedule
        record.modifiedAt = AppCalendar.now()
        records[lessonId] = record
        lock.unlock()

        if autoSave {
            try? save()
        }
        ReviewReminderScheduler.shared.reschedule()
    }

    /// Records a full review attempt, including warm-up passes that do not advance the schedule.
    public func markReviewPlayed(for lessonId: Int, today: String) {
        guard var schedule = progress(for: lessonId)?.reviewSchedule else { return }
        schedule.lastReviewedDay = today
        updateReviewSchedule(schedule, for: lessonId)
    }

    public func postponeReview(for lessonId: Int, today: String) {
        guard let schedule = progress(for: lessonId)?.reviewSchedule else { return }
        let postponed = ReviewScheduler.postpone(schedule, today: today)
        if postponed != schedule { updateReviewSchedule(postponed, for: lessonId) }
    }

    /// Number of lessons currently due for spaced review.
    public func dueLessonsCount(today: String = AppCalendar.today()) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return records.values.filter { $0.reviewSchedule.isDue(on: today) }.count
    }

    /// Sorted list of lesson IDs currently due for spaced review (oldest due day first).
    public func dueLessonIds(today: String = AppCalendar.today()) -> [Int] {
        lock.lock()
        defer { lock.unlock() }
        let dueRecords = records.filter { $0.value.reviewSchedule.isDue(on: today) }
        return dueRecords.sorted { a, b in
            let dayA = a.value.reviewDueDay ?? ""
            let dayB = b.value.reviewDueDay ?? ""
            if dayA != dayB { return dayA < dayB }
            return a.key < b.key
        }.map(\.key)
    }

    /// Returns the nearest due day among all scheduled lessons that are not yet settled,
    /// or nil if no lessons are scheduled.
    public func nearestDueDay(today: String = AppCalendar.today()) -> String? {
        lock.lock()
        defer { lock.unlock() }
        let futureDueDays = records.values.compactMap { record -> String? in
            guard !record.reviewSchedule.isSettled, let due = record.reviewDueDay else { return nil }
            return due
        }
        return futureDueDays.sorted().first
    }

    /// Returns whether any lesson has earned star 2 (mastered).
    public var hasAnyMasteredLesson: Bool {
        lock.lock()
        defer { lock.unlock() }
        return records.values.contains { $0.mastery }
    }

    /// Records a spaced review run (pass or fail), updating training log and bounce-back state.
    public func recordReviewRun(
        lessonId: Int,
        passed: Bool,
        today: String = AppCalendar.today(),
        autoSave: Bool = true
    ) {
        lock.lock()
        var record = records[lessonId] ?? LessonProgress()
        trainingLog.trainingDays.insert(today)
        if passed {
            trainingLog.reviewsPassed += 1
            if let failDay = record.lastReviewFailDay,
               AppCalendar.addingDays(LearningRules.nextDayReviewDelay, to: failDay) == today {
                trainingLog.bounceBacks += 1
            }
            record.lastReviewFailDay = nil
        } else {
            record.lastReviewFailDay = today
        }
        record.modifiedAt = AppCalendar.now()
        records[lessonId] = record
        lock.unlock()

        if autoSave {
            try? save()
        }
    }

    /// Records completion of a full Mix round (each lesson of the set played one full run).
    public func recordFinishedMixRound(
        isMemoryRound: Bool,
        today: String = AppCalendar.today(),
        autoSave: Bool = true
    ) {
        lock.lock()
        trainingLog.mixRounds += 1
        if isMemoryRound {
            trainingLog.mixMemoryRounds += 1
        }
        trainingLog.trainingDays.insert(today)
        lock.unlock()

        if autoSave {
            try? save()
        }
    }

    /// Records a Play after me response attempt.
    public func recordAfterMeResponse(
        lessonId: Int,
        score: Double,
        today: String = AppCalendar.today(),
        autoSave: Bool = true
    ) {
        lock.lock()
        trainingLog.trainingDays.insert(today)
        if score >= Scoring.passMark {
            trainingLog.afterMeLessons.insert(lessonId)
        }
        lock.unlock()

        if autoSave {
            try? save()
        }
    }

    /// Clears all progress records in memory and resets or deletes the file.
    public func resetAll(deleteFile: Bool = false) throws {
        lock.lock()
        records.removeAll()
        trainingLog = TrainingLog()
        lock.unlock()

        if deleteFile {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } else {
            try save()
        }
    }
}

