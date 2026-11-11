//
//  SettingsManager.swift
//  SmackAPad
//

import Foundation
import Observation

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

    /// Number of instruments whose trim differs from 0 dB after clamping.
    public static func changedInstrumentTrimCount(_ trims: [String: Int]) -> Int {
        cleanTrims(trims).count
    }

    public var changedInstrumentTrimCount: Int {
        Self.changedInstrumentTrimCount(instrumentTrims)
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
        let format = localized(key)
        return String(format: format, locale: Locale(identifier: languagePreference.rawValue), arguments: arguments)
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

