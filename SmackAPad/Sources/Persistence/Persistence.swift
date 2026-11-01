//
//  Persistence.swift
//  SmackAPad
//
//  Persistence for user settings (UserDefaults) and lesson progress (JSON file in Documents).
//

import Foundation
import Observation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Settings Keys & Types

/// Clean, namespaced keys for UserDefaults storage (no legacy prefixes).
public enum SettingsKey: String, CaseIterable, Sendable {
    case selectedKitId = "smackapad.settings.selectedKitId"
    case bpmStep = "smackapad.settings.bpmStep"
    case activeProfileName = "smackapad.settings.activeProfileName"
    case calibrationOffsets = "smackapad.settings.calibrationOffsets"
    case languagePreference = "smackapad.settings.language"
    case customProfiles = "smackapad.settings.customProfiles"
    case softUnlockedCategories = "smackapad.settings.softUnlockedCategories"
}

/// Allowed tempo increase steps for BPM auto-progression.
public enum BpmStep: Int, CaseIterable, Identifiable, Codable, Sendable {
    case one = 1
    case two = 2
    case five = 5
    case ten = 10

    public var id: Int { rawValue }

    public static let defaultStep: BpmStep = .five

    public static func from(raw: Int) -> BpmStep {
        BpmStep(rawValue: raw) ?? .defaultStep
    }
}

/// Supported app localization preferences.
public enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case english = "en"
    case czech = "cs"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .czech: return "Čeština"
        }
    }

    /// Bundle containing localized strings for this language.
    public var bundle: Bundle {
        if let path = Bundle.main.path(forResource: rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }

    /// Localize a key using this language bundle.
    public func localized(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    /// Localize a format key using this language bundle and locale.
    public func localized(_ key: String, _ arguments: CVarArg...) -> String {
        let format = localized(key)
        return String(format: format, locale: Locale(identifier: rawValue), arguments: arguments)
    }

    /// Localize a String.LocalizationValue using this language bundle.
    public func localized(_ value: String.LocalizationValue) -> String {
        String(localized: value, bundle: bundle)
    }
}

// MARK: - SettingsManager

/// Observable manager for user preferences persisted in UserDefaults.
@Observable
public final class SettingsManager: @unchecked Sendable {
    public static let shared = SettingsManager()

    private let userDefaults: UserDefaults
    private let lock = NSRecursiveLock()

    // MARK: Defaults

    public static let defaultKitId = "acoustic"
    public static let defaultBpmStep: Int = BpmStep.defaultStep.rawValue
    public static let defaultProfileName = "Standard 16-Pad"
    public static let defaultLanguage: AppLanguage = .english

    // MARK: Stored Properties

    public var selectedKitId: String {
        didSet {
            persistKitId()
        }
    }

    public var bpmStep: Int {
        didSet {
            persistBpmStep()
        }
    }

    public var activeProfileName: String {
        didSet {
            persistActiveProfileName()
        }
    }

    public var calibrationOffsets: [String: Double] {
        didSet {
            persistCalibrationOffsets()
        }
    }

    public var languagePreference: AppLanguage {
        didSet {
            persistLanguage()
        }
    }

    public var customProfiles: [ControllerProfile] {
        didSet {
            persistCustomProfiles()
        }
    }

    public var libraryView: String {
        didSet { userDefaults.set(libraryView, forKey: "smackapad.library.view") }
    }
    public var libraryStarFilters: [String] {
        didSet { userDefaults.set(libraryStarFilters, forKey: "smackapad.library.stars") }
    }
    public var nextLessonSource: String {
        didSet { userDefaults.set(nextLessonSource, forKey: "smackapad.library.nextSource") }
    }
    public var lastLessonID: Int {
        didSet { userDefaults.set(lastLessonID, forKey: "smackapad.library.lastLesson") }
    }

    // MARK: Computed Helpers

    public var bundle: Bundle {
        languagePreference.bundle
    }

    public func localized(_ key: String) -> String {
        languagePreference.localized(key)
    }

    public func localized(_ key: String, _ arguments: CVarArg...) -> String {
        let format = languagePreference.localized(key)
        return String(format: format, locale: Locale(identifier: languagePreference.rawValue), arguments: arguments)
    }

    public func localized(_ value: String.LocalizationValue) -> String {
        languagePreference.localized(value)
    }

    public var bpmStepEnum: BpmStep {
        get { BpmStep.from(raw: bpmStep) }
        set { bpmStep = newValue.rawValue }
    }

    // MARK: Initialization

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        libraryView = LibraryViewMode(rawValue: userDefaults.string(forKey: "smackapad.library.view") ?? "")?.rawValue ?? "path"
        libraryStarFilters = userDefaults.stringArray(forKey: "smackapad.library.stars") ?? LibraryStarFilter.allCases.map(\.rawValue)
        nextLessonSource = NextLessonSource(rawValue: userDefaults.string(forKey: "smackapad.library.nextSource") ?? "")?.rawValue ?? "path"
        lastLessonID = userDefaults.integer(forKey: "smackapad.library.lastLesson")

        // Read kit ID
        let initialKitId = userDefaults.string(forKey: SettingsKey.selectedKitId.rawValue) ?? Self.defaultKitId
        self.selectedKitId = initialKitId

        // Read BPM step (1, 2, 5, or 10)
        let rawStep = userDefaults.integer(forKey: SettingsKey.bpmStep.rawValue)
        self.bpmStep = (rawStep > 0 && BpmStep(rawValue: rawStep) != nil) ? rawStep : Self.defaultBpmStep

        // Read active profile name
        let initialProfile = userDefaults.string(forKey: SettingsKey.activeProfileName.rawValue) ?? Self.defaultProfileName
        self.activeProfileName = initialProfile

        // Read calibration offsets (keyed by MIDI device identifier, signed ms)
        if let rawOffsets = userDefaults.dictionary(forKey: SettingsKey.calibrationOffsets.rawValue) as? [String: Double] {
            self.calibrationOffsets = rawOffsets
        } else {
            self.calibrationOffsets = [:]
        }

        // Read language preference
        if let rawLang = userDefaults.string(forKey: SettingsKey.languagePreference.rawValue),
           let lang = AppLanguage(rawValue: rawLang) {
            self.languagePreference = lang
        } else {
            self.languagePreference = Self.defaultLanguage
        }

        // Read custom controller profiles
        if let data = userDefaults.data(forKey: SettingsKey.customProfiles.rawValue),
           let profiles = try? JSONDecoder().decode([ControllerProfile].self, from: data) {
            self.customProfiles = profiles.filter(\.isValid)
        } else {
            self.customProfiles = []
        }
    }

    // MARK: Persistence Helpers

    private func persistKitId() {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.set(selectedKitId, forKey: SettingsKey.selectedKitId.rawValue)
    }

    private func persistBpmStep() {
        lock.lock()
        defer { lock.unlock() }
        // Ensure valid BPM step
        let validStep = BpmStep.from(raw: bpmStep).rawValue
        if bpmStep != validStep {
            bpmStep = validStep
            return
        }
        userDefaults.set(validStep, forKey: SettingsKey.bpmStep.rawValue)
    }

    private func persistActiveProfileName() {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.set(activeProfileName, forKey: SettingsKey.activeProfileName.rawValue)
    }

    private func persistCalibrationOffsets() {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.set(calibrationOffsets, forKey: SettingsKey.calibrationOffsets.rawValue)
    }

    private func persistLanguage() {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.set(languagePreference.rawValue, forKey: SettingsKey.languagePreference.rawValue)
    }

    private func persistCustomProfiles() {
        lock.lock()
        defer { lock.unlock() }
        if let data = try? JSONEncoder().encode(customProfiles) {
            userDefaults.set(data, forKey: SettingsKey.customProfiles.rawValue)
        }
    }

    // MARK: Calibration Offset Management

    /// Returns the calibration offset in milliseconds for the given MIDI device identifier.
    /// Returns 0.0 if not calibrated yet.
    public func calibrationOffset(for deviceId: String) -> Double {
        lock.lock()
        defer { lock.unlock() }
        return calibrationOffsets[deviceId] ?? 0.0
    }

    /// Stores a signed calibration offset in ms for a device, capped at ±200 ms (SPEC §3.5).
    public func setCalibrationOffset(_ offsetMs: Double, for deviceId: String) {
        lock.lock()
        defer { lock.unlock() }
        let capped = min(max(offsetMs, -200.0), 200.0)
        var updated = calibrationOffsets
        updated[deviceId] = capped
        self.calibrationOffsets = updated
    }

    /// Removes the calibration offset for a device.
    public func removeCalibrationOffset(for deviceId: String) {
        lock.lock()
        defer { lock.unlock() }
        var updated = calibrationOffsets
        updated.removeValue(forKey: deviceId)
        self.calibrationOffsets = updated
    }

    // MARK: Controller Profile Management

    /// Looks up a profile by name (checks custom profiles first, then standard built-in presets).
    public func profile(named name: String) -> ControllerProfile? {
        lock.lock()
        defer { lock.unlock() }
        if let custom = customProfiles.first(where: { $0.profileName == name }) {
            return custom
        }
        return ControllerProfile.builtInProfiles.first { $0.profileName == name }
    }

    /// Returns the active controller profile or falls back to Standard 16-Pad.
    public func activeProfile() -> ControllerProfile {
        profile(named: activeProfileName) ?? .standard16
    }

    /// Saves or updates a custom controller profile.
    public func saveProfile(_ profile: ControllerProfile) {
        lock.lock()
        defer { lock.unlock() }
        guard profile.isValid,
              !ControllerProfile.builtInProfiles.contains(where: { $0.profileName == profile.profileName }) else { return }
        var updated = customProfiles.filter { $0.profileName != profile.profileName }
        updated.append(profile)
        self.customProfiles = updated
    }

    /// Deletes a custom profile by name. If it was active, resets activeProfileName to default.
    public func deleteProfile(named name: String) {
        lock.lock()
        defer { lock.unlock() }
        customProfiles.removeAll { $0.profileName == name }
        if activeProfileName == name {
            self.activeProfileName = Self.defaultProfileName
        }
    }

    /// Returns all available profiles (presets + user custom profiles).
    public func allProfiles() -> [ControllerProfile] {
        lock.lock()
        defer { lock.unlock() }
        var result: [ControllerProfile] = ControllerProfile.builtInProfiles
        for custom in customProfiles {
            if !result.contains(where: { $0.profileName == custom.profileName }) {
                result.append(custom)
            }
        }
        return result
    }

    /// Resets all settings to factory defaults.
    public func resetToDefaults() {
        lock.lock()
        defer { lock.unlock() }
        for key in SettingsKey.allCases {
            userDefaults.removeObject(forKey: key.rawValue)
        }
        self.selectedKitId = Self.defaultKitId
        self.bpmStep = Self.defaultBpmStep
        self.activeProfileName = Self.defaultProfileName
        self.calibrationOffsets = [:]
        self.languagePreference = Self.defaultLanguage
        self.customProfiles = []
    }
}

// MARK: - Lesson Progress Model

/// Progress record for an individual lesson matching SPEC §4.3:
/// `{ passed: Bool, mastery: Bool, memory: Bool, currentBpm: Int, bestScore: Float }`
public struct LessonProgress: Codable, Equatable, Hashable, Sendable {
    public var hasPlayed: Bool
    public var passed: Bool
    public var mastery: Bool
    public var memory: Bool
    public var currentBpm: Int
    public var bestScore: Float

    public init(
        passed: Bool = false,
        mastery: Bool = false,
        memory: Bool = false,
        hasPlayed: Bool = false,
        currentBpm: Int = 0,
        bestScore: Float = 0.0
    ) {
        self.hasPlayed = hasPlayed || passed || mastery || memory
        self.passed = passed
        self.mastery = mastery
        self.memory = memory
        self.currentBpm = currentBpm
        self.bestScore = bestScore
    }

    private enum CodingKeys: String, CodingKey { case hasPlayed, passed, mastery, memory, currentBpm, bestScore }

    /// Existing progress files predate the memory star.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        passed = try values.decode(Bool.self, forKey: .passed)
        mastery = try values.decode(Bool.self, forKey: .mastery)
        memory = try values.decodeIfPresent(Bool.self, forKey: .memory) ?? false
        currentBpm = try values.decode(Int.self, forKey: .currentBpm)
        bestScore = try values.decode(Float.self, forKey: .bestScore)
        // Old records did not distinguish a saved tempo from an interrupted attempt.
        hasPlayed = try values.decodeIfPresent(Bool.self, forKey: .hasPlayed) ?? (passed || mastery || memory || currentBpm > 0 || bestScore > 0)
    }
}

// MARK: - ProgressStore

/// Observable manager for lesson progress saved as a JSON file in the Documents directory.
@Observable
public final class ProgressStore: @unchecked Sendable {
    public static let shared = ProgressStore()

    public private(set) var records: [Int: LessonProgress] = [:]
    public private(set) var lastSaveError: Error?
    public private(set) var lastLoadError: Error?

    public let fileURL: URL
    private let lock = NSRecursiveLock()
    private var lifecycleObservers: [Any] = []

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
    /// Gracefully handles missing files (starts fresh) and corrupt files (logs warning, starts fresh, no crash).
    public func load() {
        lock.lock()
        defer { lock.unlock() }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            self.records = [:]
            self.lastLoadError = nil
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let stringKeyed = try JSONDecoder().decode([String: LessonProgress].self, from: data)
            var converted: [Int: LessonProgress] = [:]
            for (key, record) in stringKeyed {
                if let id = Int(key) {
                    converted[id] = record
                }
            }
            self.records = converted
            self.lastLoadError = nil
        } catch {
            // Graceful handling of corrupt or malformed file: start fresh without crashing.
            print("SmackAPad.ProgressStore: Warning - failed to decode progress from \(fileURL.path): \(error). Starting fresh.")
            self.records = [:]
            self.lastLoadError = error
        }
    }

    /// Atomically saves progress records to `progress.json`.
    public func save() throws {
        lock.lock()
        defer { lock.unlock() }

        let parentDir = fileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentDir.path) {
            try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        var stringKeyed: [String: LessonProgress] = [:]
        for (id, record) in records {
            stringKeyed[String(id)] = record
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(stringKeyed)
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
        autoSave: Bool = true
    ) {
        lock.lock()
        var record = records[lessonId] ?? LessonProgress(
            passed: false,
            mastery: false,
            currentBpm: bpm,
            bestScore: score
        )

        record.hasPlayed = true
        record.passed = record.passed || passed
        record.mastery = record.mastery || mastery
        record.memory = record.memory || memory
        if bpm > record.currentBpm {
            record.currentBpm = bpm
        }
        if score > record.bestScore {
            record.bestScore = score
        }

        records[lessonId] = record
        lock.unlock()

        if autoSave {
            try? save()
        }
    }

    /// Convenience helper to record a passing result for a lesson.
    public func recordPass(
        lessonId: Int,
        bpm: Int = 100,
        score: Float = 0.85,
        mastery: Bool = false,
        autoSave: Bool = true
    ) {
        recordResult(lessonId: lessonId, passed: true, mastery: mastery, bpm: bpm, score: score, autoSave: autoSave)
    }

    /// Directly sets or replaces the progress record for a lesson.
    public func setProgress(
        _ progress: LessonProgress,
        for lessonId: Int,
        autoSave: Bool = true
    ) {
        lock.lock()
        records[lessonId] = progress
        lock.unlock()

        if autoSave {
            try? save()
        }
    }

    /// Clears all progress records in memory and resets or deletes the file.
    public func resetAll(deleteFile: Bool = false) throws {
        lock.lock()
        records.removeAll()
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
