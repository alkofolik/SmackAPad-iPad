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

// MARK: - AppCalendar (Injectable Date / Day Provider)

/// Provides the current calendar day string (`YYYY-MM-DD`, device time zone).
/// Injectable for tests and future tickets (e.g. review scheduler).
public struct AppCalendar: Sendable {
    public static var todayProvider: @Sendable () -> String = {
        dayString(from: now())
    }

    public static func today() -> String {
        todayProvider()
    }

    public static func now() -> Date {
        #if DEBUG
        debugNowProvider()
        #else
        Date()
        #endif
    }

    #if DEBUG
    private static var debugNowProvider: @Sendable () -> Date = { Date() }

    static func shiftedDate(by offset: Int, from date: Date = Date()) -> Date {
        guard offset != 0 else { return date }
        return Calendar.current.date(byAdding: .day, value: offset, to: date) ?? date
    }

    static func useDebugDayOffset(_ offset: Int) {
        debugNowProvider = { shiftedDate(by: offset) }
    }
    #endif

    public static func dayString(from date: Date, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let y = components.year ?? 2026
        let m = components.month ?? 1
        let d = components.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    public static func addingDays(_ days: Int, to day: String, timeZone: TimeZone = .current) -> String? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = day.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var components = DateComponents()
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        guard let date = calendar.date(from: components),
              let nextDate = calendar.date(byAdding: .day, value: days, to: date) else { return nil }
        return dayString(from: nextDate, timeZone: timeZone)
    }

    public static func daysBetween(_ startDay: String, _ endDay: String, timeZone: TimeZone = .current) -> Int? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startParts = startDay.split(separator: "-").compactMap { Int($0) }
        let endParts = endDay.split(separator: "-").compactMap { Int($0) }
        guard startParts.count == 3, endParts.count == 3 else { return nil }
        var c1 = DateComponents(); c1.year = startParts[0]; c1.month = startParts[1]; c1.day = startParts[2]
        var c2 = DateComponents(); c2.year = endParts[0]; c2.month = endParts[1]; c2.day = endParts[2]
        guard let d1 = calendar.date(from: c1), let d2 = calendar.date(from: c2) else { return nil }
        return calendar.dateComponents([.day], from: d1, to: d2).day
    }
}

// MARK: - Settings Keys & Types

/// Clean, namespaced keys for UserDefaults storage (no legacy prefixes).
public enum SettingsKey: String, CaseIterable, Sendable {
    case selectedKitId = "smackapad.settings.selectedKitId"
    case lessonKitOverrides = "smackapad.settings.lessonKitOverrides"
    case midiControls = "smackapad.settings.midiControls"
    case practiceMode = "smackapad.settings.practiceMode"
    case bpmStep = "smackapad.settings.bpmStep"
    case activeProfileName = "smackapad.settings.activeProfileName"
    case calibrationOffsets = "smackapad.settings.calibrationOffsets"
    case languagePreference = "smackapad.settings.language"
    case customProfiles = "smackapad.settings.customProfiles"
    case softUnlockedCategories = "smackapad.settings.softUnlockedCategories"
    case metronomeVolume = "smackapad.settings.volume.metronome"
    case padsVolume = "smackapad.settings.volume.pads"
    case patternVolume = "smackapad.settings.volume.pattern"
    case instrumentTrims = "smackapad.settings.volume.instrumentTrims"
    case appearance = "smackapad.settings.appearance"
    case playPadsWithKeyboard = "smackapad.settings.playPadsWithKeyboard"
    case fadeMemoryNotes = "smackapad.settings.fadeMemoryNotes"
    case reviewReminderEnabled = "smackapad.settings.reviewReminderEnabled"
    case reviewReminderTime = "smackapad.settings.reviewReminderTime"
}

/// Supported app appearances (Light, Dark, or follow System).
public enum AppAppearance: String, CaseIterable, Identifiable, Codable, Sendable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
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

    private static let czechTSVLookup: [String: String] = {
        let bundles = [Bundle.main, Bundle(for: SettingsManager.self)]
        var foundURL: URL?
        for b in bundles {
            if let url = try? DataLoader.shared.findResourceURL(named: "cs", withExtension: "tsv", in: b) {
                foundURL = url
                break
            }
        }
        guard let url = foundURL, let content = try? String(contentsOf: url, encoding: .utf8) else {
            return [:]
        }
        var dict: [String: String] = [:]
        content.enumerateLines { line, _ in
            let parts = line.split(separator: "\t", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                dict[parts[0]] = parts[1]
            }
        }
        return dict
    }()

    /// Localize a key using this language bundle.
    public func localized(_ key: String) -> String {
        let localized = bundle.localizedString(forKey: key, value: nil, table: nil)
        if localized != key {
            return localized
        }
        if self == .czech, let tsv = Self.czechTSVLookup[key] {
            return tsv
        }
        return localized
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
    #if DEBUG
    public static let shared = SettingsManager(userDefaults: DebugProfileStorage.defaults)
    #else
    public static let shared = SettingsManager()
    #endif

    private let userDefaults: UserDefaults
    private let lock = NSRecursiveLock()

    // MARK: Defaults

    public static let defaultKitId = "auto"
    public static let defaultBpmStep: Int = BpmStep.defaultStep.rawValue
    public static let defaultProfileName = "Standard 16-Pad"
    public static let defaultLanguage: AppLanguage = .english
    public static let defaultAppearance: AppAppearance = .dark
    public static let defaultMetronomeVolume: Int = 80
    public static let defaultPadsVolume: Int = 100
    public static let defaultPatternVolume: Int = 70

    public static func clampVolume(_ value: Int) -> Int {
        let clamped = min(max(value, 0), 100)
        return ((clamped + 2) / 5) * 5
    }

    // MARK: Stored Properties

    public var selectedKitId: String {
        didSet {
            persistKitId()
        }
    }

    public var lessonKitOverrides: [Int: String] {
        didSet {
            persistLessonKitOverrides()
        }
    }

    public var midiControls: MIDIControlConfiguration {
        didSet {
            if let data = try? JSONEncoder().encode(midiControls) {
                userDefaults.set(data, forKey: SettingsKey.midiControls.rawValue)
            }
        }
    }

    public var practiceMode: PracticeMode {
        didSet { userDefaults.set(practiceMode.rawValue, forKey: SettingsKey.practiceMode.rawValue) }
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

    public var appearance: AppAppearance {
        didSet {
            persistAppearance()
        }
    }

    public var customProfiles: [ControllerProfile] {
        didSet {
            persistCustomProfiles()
        }
    }

    public var metronomeVolume: Int {
        didSet {
            let clamped = Self.clampVolume(metronomeVolume)
            if metronomeVolume != clamped {
                metronomeVolume = clamped
                return
            }
            userDefaults.set(metronomeVolume, forKey: SettingsKey.metronomeVolume.rawValue)
        }
    }

    public var padsVolume: Int {
        didSet {
            let clamped = Self.clampVolume(padsVolume)
            if padsVolume != clamped {
                padsVolume = clamped
                return
            }
            userDefaults.set(padsVolume, forKey: SettingsKey.padsVolume.rawValue)
        }
    }

    public var patternVolume: Int {
        didSet {
            let clamped = Self.clampVolume(patternVolume)
            if patternVolume != clamped {
                patternVolume = clamped
                return
            }
            userDefaults.set(patternVolume, forKey: SettingsKey.patternVolume.rawValue)
        }
    }

    /// Per-instrument trim in dB (-12...+6), keyed by voice name. Missing = 0 dB.
    public var instrumentTrims: [String: Int] {
        didSet {
            let cleaned = Self.cleanTrims(instrumentTrims)
            if cleaned != instrumentTrims {
                instrumentTrims = cleaned
                return
            }
            if let data = try? JSONEncoder().encode(cleaned) {
                userDefaults.set(data, forKey: SettingsKey.instrumentTrims.rawValue)
            }
        }
    }

    /// Clamps every trim and drops zero entries so "all default" is an empty dictionary.
    public static func cleanTrims(_ trims: [String: Int]) -> [String: Int] {
        trims.mapValues(SampleGain.clampTrim).filter { $0.value != 0 }
    }

    public func resetInstrumentTrims() { instrumentTrims = [:] }

    public var libraryView: String {
        didSet { userDefaults.set(libraryView, forKey: "smackapad.library.view") }
    }
    public var libraryStarFilters: [String] {
        didSet { userDefaults.set(libraryStarFilters, forKey: "smackapad.library.stars") }
    }
    public var trainingDueStepFilter: String {
        didSet { userDefaults.set(trainingDueStepFilter, forKey: "smackapad.training.dueStepFilter") }
    }
    public var nextLessonSource: String {
        didSet { userDefaults.set(nextLessonSource, forKey: "smackapad.library.nextSource") }
    }
    public var lastLessonID: Int {
        didSet { userDefaults.set(lastLessonID, forKey: "smackapad.library.lastLesson") }
    }
    public var playPadsWithKeyboard: Bool {
        didSet { userDefaults.set(playPadsWithKeyboard, forKey: SettingsKey.playPadsWithKeyboard.rawValue) }
    }
    public var fadeMemoryNotes: Bool {
        didSet { userDefaults.set(fadeMemoryNotes, forKey: SettingsKey.fadeMemoryNotes.rawValue) }
    }
    public var reviewReminderEnabled: Bool {
        didSet {
            persistReviewReminderEnabled()
        }
    }
    public var reviewReminderTime: Date {
        didSet {
            persistReviewReminderTime()
        }
    }
    public var hideCompletedLessons: Bool {
        didSet { userDefaults.set(hideCompletedLessons, forKey: "smackapad.library.hideCompleted") }
    }
    public var hiddenCategoryIDsByMode: [String: Set<String>] {
        didSet {
            persistHiddenCategories()
        }
    }

    public func hiddenCategories(for mode: String) -> Set<String> {
        lock.lock()
        defer { lock.unlock() }
        return hiddenCategoryIDsByMode[mode] ?? []
    }

    public func hideCategory(_ id: String, in mode: String) {
        lock.lock()
        defer { lock.unlock() }
        var current = hiddenCategoryIDsByMode[mode] ?? []
        current.insert(id)
        hiddenCategoryIDsByMode[mode] = current
    }

    public func unhideCategory(_ id: String, in mode: String) {
        lock.lock()
        defer { lock.unlock() }
        var current = hiddenCategoryIDsByMode[mode] ?? []
        current.remove(id)
        hiddenCategoryIDsByMode[mode] = current
    }

    public func isCategoryHidden(_ id: String, in mode: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return hiddenCategoryIDsByMode[mode]?.contains(id) ?? false
    }

    // MARK: - Memory Star Hint

    public func hasShownMemoryHint(for lessonId: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let set = memoryHintShownIds()
        return set.contains(lessonId)
    }

    public func markMemoryHintShown(for lessonId: Int) {
        lock.lock()
        defer { lock.unlock() }
        var set = memoryHintShownIds()
        set.insert(lessonId)
        if let data = try? JSONEncoder().encode(Array(set)) {
            userDefaults.set(data, forKey: "smackapad.memoryHintShownLessonIds")
        }
    }

    private func memoryHintShownIds() -> Set<Int> {
        guard let data = userDefaults.data(forKey: "smackapad.memoryHintShownLessonIds"),
              let ids = try? JSONDecoder().decode([Int].self, from: data) else { return [] }
        return Set(ids)
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

    public static func defaultReminderTime(calendar: Calendar = .current) -> Date {
        // The picker stores a time of day for real local notifications.
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 18
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? Date()
    }

    public var reviewReminderHour: Int {
        Calendar.current.component(.hour, from: reviewReminderTime)
    }

    public var reviewReminderMinute: Int {
        Calendar.current.component(.minute, from: reviewReminderTime)
    }

    // MARK: Initialization

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let data = userDefaults.data(forKey: SettingsKey.midiControls.rawValue),
           let controls = try? JSONDecoder().decode(MIDIControlConfiguration.self, from: data) {
            midiControls = controls.validated()
        } else {
            midiControls = MIDIControlConfiguration()
        }
        practiceMode = PracticeMode(rawValue: userDefaults.string(forKey: SettingsKey.practiceMode.rawValue) ?? "") ?? .learning
        libraryView = LibraryViewMode(rawValue: userDefaults.string(forKey: "smackapad.library.view") ?? "")?.rawValue ?? "path"
        libraryStarFilters = userDefaults.stringArray(forKey: "smackapad.library.stars") ?? LibraryStarFilter.allCases.map(\.rawValue)
        trainingDueStepFilter = userDefaults.string(forKey: "smackapad.training.dueStepFilter") ?? "all"
        nextLessonSource = NextLessonSource(rawValue: userDefaults.string(forKey: "smackapad.library.nextSource") ?? "")?.rawValue ?? "path"
        lastLessonID = userDefaults.integer(forKey: "smackapad.library.lastLesson")

        // Read kit ID
        let initialKitId = userDefaults.string(forKey: SettingsKey.selectedKitId.rawValue) ?? Self.defaultKitId
        self.selectedKitId = initialKitId

        // Read lesson kit overrides
        if let data = userDefaults.data(forKey: SettingsKey.lessonKitOverrides.rawValue),
           let overrides = try? JSONDecoder().decode([Int: String].self, from: data) {
            self.lessonKitOverrides = overrides
        } else if let rawDict = userDefaults.dictionary(forKey: SettingsKey.lessonKitOverrides.rawValue) as? [String: String] {
            var converted: [Int: String] = [:]
            for (k, v) in rawDict {
                if let id = Int(k) { converted[id] = v }
            }
            self.lessonKitOverrides = converted
        } else {
            self.lessonKitOverrides = [:]
        }

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

        // Read appearance preference
        if let rawAppearance = userDefaults.string(forKey: SettingsKey.appearance.rawValue),
           let app = AppAppearance(rawValue: rawAppearance) {
            self.appearance = app
        } else if let legacyAppearance = userDefaults.string(forKey: "smackapad.practice.appearance"),
                  let app = AppAppearance(rawValue: legacyAppearance) {
            self.appearance = app
            userDefaults.set(app.rawValue, forKey: SettingsKey.appearance.rawValue)
        } else {
            self.appearance = Self.defaultAppearance
        }

        // Read custom controller profiles
        if let data = userDefaults.data(forKey: SettingsKey.customProfiles.rawValue),
           let profiles = try? JSONDecoder().decode([ControllerProfile].self, from: data) {
            self.customProfiles = profiles.filter(\.isValid)
        } else {
            self.customProfiles = []
        }

        // Read volume settings (0-100% in steps of 5)
        if userDefaults.object(forKey: SettingsKey.metronomeVolume.rawValue) != nil {
            self.metronomeVolume = Self.clampVolume(userDefaults.integer(forKey: SettingsKey.metronomeVolume.rawValue))
        } else {
            self.metronomeVolume = Self.defaultMetronomeVolume
        }

        if userDefaults.object(forKey: SettingsKey.padsVolume.rawValue) != nil {
            self.padsVolume = Self.clampVolume(userDefaults.integer(forKey: SettingsKey.padsVolume.rawValue))
        } else {
            self.padsVolume = Self.defaultPadsVolume
        }

        if userDefaults.object(forKey: SettingsKey.patternVolume.rawValue) != nil {
            self.patternVolume = Self.clampVolume(userDefaults.integer(forKey: SettingsKey.patternVolume.rawValue))
        } else {
            self.patternVolume = Self.defaultPatternVolume
        }

        if let data = userDefaults.data(forKey: SettingsKey.instrumentTrims.rawValue),
           let stored = try? JSONDecoder().decode([String: Int].self, from: data) {
            self.instrumentTrims = Self.cleanTrims(stored)
        } else {
            self.instrumentTrims = [:]
        }

        self.playPadsWithKeyboard = userDefaults.object(forKey: SettingsKey.playPadsWithKeyboard.rawValue) as? Bool ?? true
        self.fadeMemoryNotes = userDefaults.object(forKey: SettingsKey.fadeMemoryNotes.rawValue) as? Bool ?? true
        self.reviewReminderEnabled = userDefaults.bool(forKey: SettingsKey.reviewReminderEnabled.rawValue)
        if let storedReminderTime = userDefaults.object(forKey: SettingsKey.reviewReminderTime.rawValue) as? Date {
            self.reviewReminderTime = storedReminderTime
        } else {
            self.reviewReminderTime = Self.defaultReminderTime()
        }
        self.hideCompletedLessons = userDefaults.object(forKey: "smackapad.library.hideCompleted") as? Bool ?? true

        var loadedHidden: [String: Set<String>] = [:]
        for mode in ["path", "genre", "technique"] {
            if let arr = userDefaults.stringArray(forKey: "smackapad.library.hiddenCategories.\(mode)") {
                loadedHidden[mode] = Set(arr)
            }
        }
        self.hiddenCategoryIDsByMode = loadedHidden

        switch initialProfile {
        case "Akai MPD (36–51)", "NI Maschine (36–51)":
            // These presets shared the default map. Preserve any custom profile with the same name.
            if !customProfiles.contains(where: { $0.profileName == initialProfile }) {
                activeProfileName = Self.defaultProfileName
                persistActiveProfileName()
            }
        default:
            break
        }
    }

    // MARK: Persistence Helpers

    private func persistKitId() {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.set(selectedKitId, forKey: SettingsKey.selectedKitId.rawValue)
    }

    private func persistLessonKitOverrides() {
        lock.lock()
        defer { lock.unlock() }
        if let data = try? JSONEncoder().encode(lessonKitOverrides) {
            userDefaults.set(data, forKey: SettingsKey.lessonKitOverrides.rawValue)
        }
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

    private func persistAppearance() {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.set(appearance.rawValue, forKey: SettingsKey.appearance.rawValue)
        userDefaults.set(appearance.rawValue, forKey: "smackapad.practice.appearance")
    }

    private func persistCustomProfiles() {
        lock.lock()
        defer { lock.unlock() }
        if let data = try? JSONEncoder().encode(customProfiles) {
            userDefaults.set(data, forKey: SettingsKey.customProfiles.rawValue)
        }
    }

    private func persistReviewReminderEnabled() {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.set(reviewReminderEnabled, forKey: SettingsKey.reviewReminderEnabled.rawValue)
    }

    private func persistReviewReminderTime() {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.set(reviewReminderTime, forKey: SettingsKey.reviewReminderTime.rawValue)
    }

    private func persistHiddenCategories() {
        lock.lock()
        defer { lock.unlock() }
        for mode in ["path", "genre", "technique"] {
            let ids = Array(hiddenCategoryIDsByMode[mode] ?? []).sorted()
            userDefaults.set(ids, forKey: "smackapad.library.hiddenCategories.\(mode)")
        }
    }

    // MARK: Calibration Offset Management

    /// Reads a route-specific offset, falling back to calibration saved before routes were tracked.
    public func calibrationOffset(for deviceId: String, outputRoute: AudioOutputRoute) -> Double {
        lock.lock()
        defer { lock.unlock() }
        return calibrationOffsets[calibrationKey(for: deviceId, outputRoute: outputRoute)] ?? calibrationOffsets[deviceId] ?? 0
    }

    /// Stores a signed offset for this input and output, capped at ±200 ms (SPEC §3.5).
    public func setCalibrationOffset(_ offsetMs: Double, for deviceId: String, outputRoute: AudioOutputRoute) {
        lock.lock()
        defer { lock.unlock() }
        let capped = min(max(offsetMs, -200.0), 200.0)
        var updated = calibrationOffsets
        updated[calibrationKey(for: deviceId, outputRoute: outputRoute)] = capped
        self.calibrationOffsets = updated
    }

    /// Removes all calibration offsets for an input, including its legacy fallback.
    public func removeCalibrationOffset(for deviceId: String) {
        lock.lock()
        defer { lock.unlock() }
        var updated = calibrationOffsets
        updated.removeValue(forKey: deviceId)
        for route in AudioOutputRoute.allCases {
            updated.removeValue(forKey: calibrationKey(for: deviceId, outputRoute: route))
        }
        self.calibrationOffsets = updated
    }

    private func calibrationKey(for deviceId: String, outputRoute: AudioOutputRoute) -> String {
        "\(deviceId)|\(outputRoute.rawValue)"
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

    /// Built-in profile titles can be localized without changing their saved names.
    public func displayName(for profile: ControllerProfile) -> String {
        profile == .standard16 ? localized("16 pads, notes 36–51") : profile.profileName
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

    // MARK: - Lesson Kit Override Management

    /// Returns any sound kit override set for the given lesson ID, or nil if none.
    public func kitOverride(for lessonId: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return lessonKitOverrides[lessonId]
    }

    /// Sets or clears a sound kit override for a lesson.
    /// Setting "auto", empty, or nil removes the override.
    public func setKitOverride(_ kitId: String?, for lessonId: Int) {
        lock.lock()
        defer { lock.unlock() }
        var updated = lessonKitOverrides
        if let kitId = kitId, kitId != "auto" && !kitId.isEmpty {
            updated[lessonId] = kitId
        } else {
            updated.removeValue(forKey: lessonId)
        }
        self.lessonKitOverrides = updated
    }

    /// Resets all settings to factory defaults.
    public func resetToDefaults() {
        lock.lock()
        defer { lock.unlock() }
        for key in SettingsKey.allCases {
            userDefaults.removeObject(forKey: key.rawValue)
        }
        self.selectedKitId = Self.defaultKitId
        self.lessonKitOverrides = [:]
        self.midiControls = MIDIControlConfiguration()
        self.practiceMode = .learning
        self.bpmStep = Self.defaultBpmStep
        self.activeProfileName = Self.defaultProfileName
        self.calibrationOffsets = [:]
        self.languagePreference = Self.defaultLanguage
        self.appearance = Self.defaultAppearance
        self.customProfiles = []
        self.metronomeVolume = Self.defaultMetronomeVolume
        self.padsVolume = Self.defaultPadsVolume
        self.patternVolume = Self.defaultPatternVolume
        self.instrumentTrims = [:]
        self.playPadsWithKeyboard = true
        self.reviewReminderEnabled = false
        self.reviewReminderTime = Self.defaultReminderTime()
        userDefaults.removeObject(forKey: "smackapad.training.dueStepFilter")
        self.trainingDueStepFilter = "all"
        userDefaults.removeObject(forKey: "smackapad.library.hideCompleted")
        self.hideCompletedLessons = true
        for mode in ["path", "genre", "technique"] {
            userDefaults.removeObject(forKey: "smackapad.library.hiddenCategories.\(mode)")
        }
        self.hiddenCategoryIDsByMode = [:]
    }

    // MARK: - Device ID & Export/Import

    /// Unique, persistent identifier for this device install. Generated once and never replaced by an import.
    public static var deviceId: String {
        let key = "smackapad.deviceId"
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }

    /// Exports player preferences for backup. Device-specific offsets (calibration, etc.) are excluded.
    public func exportSettings() -> BackupSettings {
        lock.lock()
        defer { lock.unlock() }

        let showPads = userDefaults.object(forKey: "smackapad.practice.showPads") as? Bool ?? true
        let showPadKeys = userDefaults.object(forKey: "smackapad.practice.showPadKeys") as? Bool ?? true
        let visibleBars = userDefaults.integer(forKey: "smackapad.practice.visibleBars")
        let touchPadsInPortrait = userDefaults.object(forKey: "smackapad.practice.touchPadsInPortrait") as? Bool ?? true
        let scrolling = userDefaults.string(forKey: "smackapad.practice.scrolling") ?? "continuous"
        let practiceAppearance = userDefaults.string(forKey: "smackapad.practice.appearance") ?? "system"

        let tutorialSeen = userDefaults.bool(forKey: "smackapad.tutorial.seen")
        let legendShownOnce = userDefaults.bool(forKey: "smackapad.legend.shownOnce")
        let memoryHints = userDefaults.array(forKey: "smackapad.memoryHintShownLessonIds") as? [Int] ?? []

        let modifiedAt = userDefaults.object(forKey: "smackapad.settings.modifiedAt") as? Date

        return BackupSettings(
            settingsModifiedAt: modifiedAt,
            selectedKitId: selectedKitId,
            lessonKitOverrides: lessonKitOverrides,
            midiControls: midiControls,
            bpmStep: bpmStep,
            practiceMode: practiceMode.rawValue,
            activeProfileName: activeProfileName,
            customProfiles: customProfiles,
            languagePreference: languagePreference.rawValue,
            appearance: appearance.rawValue,
            metronomeVolume: metronomeVolume,
            padsVolume: padsVolume,
            patternVolume: patternVolume,
            instrumentTrims: instrumentTrims,
            playPadsWithKeyboard: playPadsWithKeyboard,
            fadeMemoryNotes: fadeMemoryNotes,
            reviewReminderEnabled: reviewReminderEnabled,
            reviewReminderTime: reviewReminderTime,
            hideCompletedLessons: hideCompletedLessons,
            hiddenCategoryIDsByMode: hiddenCategoryIDsByMode,
            libraryView: libraryView,
            libraryStarFilters: libraryStarFilters,
            trainingDueStepFilter: trainingDueStepFilter,
            nextLessonSource: nextLessonSource,
            lastLessonID: lastLessonID,
            showPads: showPads,
            showPadKeys: showPadKeys,
            visibleBars: visibleBars > 0 ? visibleBars : 1,
            touchPadsInPortrait: touchPadsInPortrait,
            scrolling: scrolling,
            practiceAppearance: practiceAppearance,
            tutorialSeen: tutorialSeen,
            legendShownOnce: legendShownOnce,
            memoryHintShownLessonIds: Set(memoryHints)
        )
    }

    /// Applies portable player preferences from a backup on a fresh device.
    /// Hardware/route calibration offsets are intentionally not restored.
    public func applyImportedSettings(_ settings: BackupSettings) {
        lock.lock()
        defer { lock.unlock() }

        self.selectedKitId = settings.selectedKitId
        self.lessonKitOverrides = settings.lessonKitOverrides
        self.midiControls = settings.midiControls
        self.bpmStep = settings.bpmStep
        if let mode = PracticeMode(rawValue: settings.practiceMode) {
            self.practiceMode = mode
        }
        self.activeProfileName = settings.activeProfileName
        self.customProfiles = settings.customProfiles
        if let lang = AppLanguage(rawValue: settings.languagePreference) {
            self.languagePreference = lang
        }
        if let app = AppAppearance(rawValue: settings.appearance) {
            self.appearance = app
        }
        self.metronomeVolume = settings.metronomeVolume
        self.padsVolume = settings.padsVolume
        self.patternVolume = settings.patternVolume
        self.instrumentTrims = settings.instrumentTrims
        self.playPadsWithKeyboard = settings.playPadsWithKeyboard
        self.fadeMemoryNotes = settings.fadeMemoryNotes
        self.reviewReminderEnabled = settings.reviewReminderEnabled
        if let time = settings.reviewReminderTime {
            self.reviewReminderTime = time
        }
        self.hideCompletedLessons = settings.hideCompletedLessons
        self.hiddenCategoryIDsByMode = settings.hiddenCategoryIDsByMode
        self.libraryView = settings.libraryView
        self.libraryStarFilters = settings.libraryStarFilters
        self.trainingDueStepFilter = settings.trainingDueStepFilter
        self.nextLessonSource = settings.nextLessonSource
        self.lastLessonID = settings.lastLessonID

        userDefaults.set(settings.showPads, forKey: "smackapad.practice.showPads")
        userDefaults.set(settings.showPadKeys, forKey: "smackapad.practice.showPadKeys")
        if settings.visibleBars > 0 {
            userDefaults.set(settings.visibleBars, forKey: "smackapad.practice.visibleBars")
        }
        userDefaults.set(settings.touchPadsInPortrait, forKey: "smackapad.practice.touchPadsInPortrait")
        userDefaults.set(settings.scrolling, forKey: "smackapad.practice.scrolling")
        userDefaults.set(settings.practiceAppearance, forKey: "smackapad.practice.appearance")

        userDefaults.set(settings.tutorialSeen, forKey: "smackapad.tutorial.seen")
        userDefaults.set(settings.legendShownOnce, forKey: "smackapad.legend.shownOnce")
        if !settings.memoryHintShownLessonIds.isEmpty {
            userDefaults.set(Array(settings.memoryHintShownLessonIds), forKey: "smackapad.memoryHintShownLessonIds")
        }

        if let mod = settings.settingsModifiedAt {
            userDefaults.set(mod, forKey: "smackapad.settings.modifiedAt")
        }
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
    public var lastPlayedDay: String?
    public var masteryDay: String?
    public var reviewStep: Int?
    public var reviewDueDay: String?
    public var settled: Bool?
    public var lastReviewedDay: String?
    public var lastReviewFailDay: String?
    var learningCreditByPadCount: [String: StarStreak] = [:]
    public var modifiedAt: Date?

    public static func == (lhs: LessonProgress, rhs: LessonProgress) -> Bool {
        lhs.hasPlayed == rhs.hasPlayed &&
        lhs.passed == rhs.passed &&
        lhs.mastery == rhs.mastery &&
        lhs.memory == rhs.memory &&
        lhs.currentBpm == rhs.currentBpm &&
        lhs.bestScore == rhs.bestScore &&
        lhs.lastPlayedDay == rhs.lastPlayedDay &&
        lhs.masteryDay == rhs.masteryDay &&
        lhs.reviewStep == rhs.reviewStep &&
        lhs.reviewDueDay == rhs.reviewDueDay &&
        lhs.settled == rhs.settled &&
        lhs.lastReviewedDay == rhs.lastReviewedDay &&
        lhs.lastReviewFailDay == rhs.lastReviewFailDay &&
        lhs.learningCreditByPadCount == rhs.learningCreditByPadCount
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hasPlayed)
        hasher.combine(passed)
        hasher.combine(mastery)
        hasher.combine(memory)
        hasher.combine(currentBpm)
        hasher.combine(bestScore)
        hasher.combine(lastPlayedDay)
        hasher.combine(masteryDay)
        hasher.combine(reviewStep)
        hasher.combine(reviewDueDay)
        hasher.combine(settled)
        hasher.combine(lastReviewedDay)
        hasher.combine(lastReviewFailDay)
        hasher.combine(learningCreditByPadCount)
    }

    /// Imported stars remain earned; an untouched review chain is an invitation, not a failed counter.
    var isUnstartedLegacyReview: Bool {
        memory && (reviewStep ?? 0) == 0 && settled != true
            && lastReviewedDay == nil && lastReviewFailDay == nil
    }

    public var reviewSchedule: ReviewScheduler.ScheduleState {
        get {
            ReviewScheduler.ScheduleState(reviewStep: reviewStep, reviewDueDay: reviewDueDay, settled: settled,
                                          lastReviewedDay: lastReviewedDay)
        }
        set {
            self.reviewStep = newValue.reviewStep
            self.reviewDueDay = newValue.reviewDueDay
            self.settled = newValue.settled
            self.lastReviewedDay = newValue.lastReviewedDay
        }
    }

    public init(
        passed: Bool = false,
        mastery: Bool = false,
        memory: Bool = false,
        hasPlayed: Bool = false,
        currentBpm: Int = 0,
        bestScore: Float = 0.0,
        lastPlayedDay: String? = nil,
        masteryDay: String? = nil,
        reviewStep: Int? = nil,
        reviewDueDay: String? = nil,
        settled: Bool? = nil,
        lastReviewedDay: String? = nil,
        lastReviewFailDay: String? = nil,
        modifiedAt: Date? = nil
    ) {
        self.hasPlayed = hasPlayed || passed || mastery || memory
        self.passed = passed
        self.mastery = mastery
        self.memory = memory
        self.currentBpm = currentBpm
        self.bestScore = bestScore
        self.lastPlayedDay = lastPlayedDay
        self.masteryDay = masteryDay
        self.reviewStep = reviewStep
        self.reviewDueDay = reviewDueDay
        self.settled = settled
        self.lastReviewedDay = lastReviewedDay
        self.lastReviewFailDay = lastReviewFailDay
        self.modifiedAt = modifiedAt
    }

    private enum CodingKeys: String, CodingKey {
        case hasPlayed, passed, mastery, memory, currentBpm, bestScore, masteryDay, lastPlayedDay, learningCreditByPadCount
        case reviewStep, reviewDueDay, settled, lastReviewedDay, lastReviewFailDay, modifiedAt
    }

    /// Existing progress files predate the memory star and review schedule.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        passed = try values.decode(Bool.self, forKey: .passed)
        mastery = try values.decode(Bool.self, forKey: .mastery)
        memory = try values.decodeIfPresent(Bool.self, forKey: .memory) ?? false
        currentBpm = try values.decode(Int.self, forKey: .currentBpm)
        bestScore = try values.decode(Float.self, forKey: .bestScore)
        lastPlayedDay = try values.decodeIfPresent(String.self, forKey: .lastPlayedDay)
        masteryDay = try values.decodeIfPresent(String.self, forKey: .masteryDay)
        learningCreditByPadCount = try values.decodeIfPresent([String: StarStreak].self, forKey: .learningCreditByPadCount) ?? [:]
        reviewStep = try values.decodeIfPresent(Int.self, forKey: .reviewStep)
        reviewDueDay = try values.decodeIfPresent(String.self, forKey: .reviewDueDay)
        settled = try values.decodeIfPresent(Bool.self, forKey: .settled)
        lastReviewedDay = try values.decodeIfPresent(String.self, forKey: .lastReviewedDay)
        lastReviewFailDay = try values.decodeIfPresent(String.self, forKey: .lastReviewFailDay)
        if let dateString = try? values.decodeIfPresent(String.self, forKey: .modifiedAt) {
            let formatter = ISO8601DateFormatter()
            modifiedAt = formatter.date(from: dateString)
        } else {
            modifiedAt = try values.decodeIfPresent(Date.self, forKey: .modifiedAt)
        }
        // Old records did not distinguish a saved tempo from an interrupted attempt.
        hasPlayed = try values.decodeIfPresent(Bool.self, forKey: .hasPlayed) ?? (passed || mastery || memory || currentBpm > 0 || bestScore > 0)
    }
}

// MARK: - TrainingLog & ProgressRoot

/// Cumulative training counts and session sets persisted in the progress file.
public struct TrainingLog: Codable, Equatable, Hashable, Sendable {
    public var reviewsPassed: Int
    public var bounceBacks: Int
    public var mixRounds: Int
    public var mixMemoryRounds: Int
    public var afterMeLessons: Set<Int>
    public var trainingDays: Set<String>

    public init(
        reviewsPassed: Int = 0,
        bounceBacks: Int = 0,
        mixRounds: Int = 0,
        mixMemoryRounds: Int = 0,
        afterMeLessons: Set<Int> = [],
        trainingDays: Set<String> = []
    ) {
        self.reviewsPassed = reviewsPassed
        self.bounceBacks = bounceBacks
        self.mixRounds = mixRounds
        self.mixMemoryRounds = mixMemoryRounds
        self.afterMeLessons = afterMeLessons
        self.trainingDays = trainingDays
    }

    public static func merging(_ existing: TrainingLog, with incoming: TrainingLog) -> TrainingLog {
        TrainingLog(
            reviewsPassed: max(existing.reviewsPassed, incoming.reviewsPassed),
            bounceBacks: max(existing.bounceBacks, incoming.bounceBacks),
            mixRounds: max(existing.mixRounds, incoming.mixRounds),
            mixMemoryRounds: max(existing.mixMemoryRounds, incoming.mixMemoryRounds),
            afterMeLessons: existing.afterMeLessons.union(incoming.afterMeLessons),
            trainingDays: existing.trainingDays.union(incoming.trainingDays)
        )
    }
}

/// Root structure of the progress JSON file.
/// Decodes both legacy flat dictionary format (`[String: LessonProgress]`) and the structured format.
public struct ProgressRoot: Codable, Equatable, Sendable {
    public var formatVersion: Int
    public var lessons: [Int: LessonProgress]
    public var trainingLog: TrainingLog

    public init(formatVersion: Int = 1, lessons: [Int: LessonProgress] = [:], trainingLog: TrainingLog = TrainingLog()) {
        self.formatVersion = formatVersion
        self.lessons = lessons
        self.trainingLog = trainingLog
    }

    private enum CodingKeys: String, CodingKey {
        case formatVersion
        case lessons
        case trainingLog
        case reviewsPassed
        case bounceBacks
        case mixRounds
        case mixMemoryRounds
        case afterMeLessons
        case trainingDays
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           container.contains(.lessons) {
            let version = try container.decodeIfPresent(Int.self, forKey: .formatVersion) ?? 1
            if version > 1 {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unsupported formatVersion: \(version)"
                    )
                )
            }
            self.formatVersion = version

            let stringLessons = try container.decode([String: LessonProgress].self, forKey: .lessons)
            var convertedLessons: [Int: LessonProgress] = [:]
            for (k, v) in stringLessons {
                if let id = Int(k) { convertedLessons[id] = v }
            }
            self.lessons = convertedLessons

            if let nested = try? container.decodeIfPresent(TrainingLog.self, forKey: .trainingLog) {
                self.trainingLog = nested
            } else {
                let reviews = try container.decodeIfPresent(Int.self, forKey: .reviewsPassed) ?? 0
                let bounce = try container.decodeIfPresent(Int.self, forKey: .bounceBacks) ?? 0
                let rounds = try container.decodeIfPresent(Int.self, forKey: .mixRounds) ?? 0
                let memRounds = try container.decodeIfPresent(Int.self, forKey: .mixMemoryRounds) ?? 0
                let afterMe = try container.decodeIfPresent(Set<Int>.self, forKey: .afterMeLessons) ?? []
                let days = try container.decodeIfPresent(Set<String>.self, forKey: .trainingDays) ?? []
                self.trainingLog = TrainingLog(
                    reviewsPassed: reviews,
                    bounceBacks: bounce,
                    mixRounds: rounds,
                    mixMemoryRounds: memRounds,
                    afterMeLessons: afterMe,
                    trainingDays: days
                )
            }
        } else {
            let container = try decoder.singleValueContainer()
            let stringLessons = try container.decode([String: LessonProgress].self)
            var convertedLessons: [Int: LessonProgress] = [:]
            for (k, v) in stringLessons {
                if let id = Int(k) { convertedLessons[id] = v }
            }
            self.formatVersion = 1
            self.lessons = convertedLessons
            self.trainingLog = TrainingLog()
        }

        // Old progress: reviewsPassed starts at least at the passes implied by the schedule
        let impliedPasses = self.lessons.values.reduce(0) { sum, record in
            sum + (record.settled == true ? LearningRules.settledReviewPasses : (record.reviewStep ?? 0))
        }
        self.trainingLog.reviewsPassed = max(self.trainingLog.reviewsPassed, impliedPasses)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(formatVersion, forKey: .formatVersion)
        var stringLessons: [String: LessonProgress] = [:]
        for (id, record) in lessons {
            stringLessons[String(id)] = record
        }
        try container.encode(stringLessons, forKey: .lessons)
        try container.encode(trainingLog.reviewsPassed, forKey: .reviewsPassed)
        try container.encode(trainingLog.bounceBacks, forKey: .bounceBacks)
        try container.encode(trainingLog.mixRounds, forKey: .mixRounds)
        try container.encode(trainingLog.mixMemoryRounds, forKey: .mixMemoryRounds)
        try container.encode(Array(trainingLog.afterMeLessons).sorted(), forKey: .afterMeLessons)
        try container.encode(Array(trainingLog.trainingDays).sorted(), forKey: .trainingDays)
    }
}

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

#if DEBUG
/// Only decodes the legacy fields needed for stars and tempo; all other data is ignored.
enum LegacyProgressImport {
    enum ImportError: Error { case invalidBackup }

    private struct Backup: Decodable {
        let app: String
        let formatVersion: Int
        let rewards: Rewards
        let progress: [String: Progress]?
    }
    private struct Rewards: Decodable { let stars: [String: Stars] }
    private struct Stars: Decodable {
        let passed: Bool?
        let mastered: Bool?
        let memory: String?
    }
    private struct Progress: Decodable {
        let bpm: Int?
        let best: Float?
    }

    static func map(_ data: Data) throws -> [Int: LessonProgress] {
        let backup: Backup
        do {
            backup = try JSONDecoder().decode(Backup.self, from: data)
        } catch {
            throw ImportError.invalidBackup
        }
        guard backup.app == "padwork", backup.formatVersion == 1 else {
            throw ImportError.invalidBackup
        }
        var records: [Int: LessonProgress] = [:]
        for (key, stars) in backup.rewards.stars {
            guard let id = Int(key), id > 0 else { throw ImportError.invalidBackup }
            let passed = stars.passed ?? false
            let mastery = stars.mastered ?? false
            let memory = stars.memory != nil
            guard passed || mastery || memory else { continue }
            let progress = backup.progress?[key]
            records[id] = LessonProgress(
                passed: passed, mastery: mastery, memory: memory, hasPlayed: true,
                currentBpm: max(0, progress?.bpm ?? 0),
                bestScore: min(1, max(0, (progress?.best ?? 0) / 100))
            )
        }
        ProgressStore.migrateDuplicateIntroProgress(in: &records)
        return records
    }

    static func merge(existing: [Int: LessonProgress], imported: [Int: LessonProgress]) -> [Int: LessonProgress] {
        var result = existing
        ProgressStore.migrateDuplicateIntroProgress(in: &result)
        for id in imported.keys.sorted() {
            guard let incoming = imported[id] else { continue }
            result[id] = ProgressStore.merging(result[id] ?? LessonProgress(), with: incoming)
        }
        return result
    }
}
#endif
