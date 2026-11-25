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

    let userDefaults: UserDefaults
    private let lock = NSRecursiveLock()

    func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

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

    private static func loadVolume(from userDefaults: UserDefaults, key: SettingsKey, defaultValue: Int) -> Int {
        guard userDefaults.object(forKey: key.rawValue) != nil else { return defaultValue }
        return clampVolume(userDefaults.integer(forKey: key.rawValue))
    }

    // MARK: Stored Properties

    public var selectedKitId: String {
        didSet { persistKitId() }
    }

    public var selectedInstrumentSkinId: String {
        didSet {
            userDefaults.set(selectedInstrumentSkinId, forKey: SettingsKey.selectedInstrumentSkinId.rawValue)
            Theme.setActiveSkinId(selectedInstrumentSkinId)
        }
    }

    public var lessonKitOverrides: [Int: String] {
        didSet { persistLessonKitOverrides() }
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
        didSet { persistBpmStep() }
    }

    public var activeProfileName: String {
        didSet { persistActiveProfileName() }
    }

    public var calibrationOffsets: [String: Double] {
        didSet { persistCalibrationOffsets() }
    }

    public var languagePreference: AppLanguage {
        didSet { persistLanguage() }
    }

    public var appearance: AppAppearance {
        didSet { persistAppearance() }
    }

    public var customProfiles: [ControllerProfile] {
        didSet { persistCustomProfiles() }
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

    public var autoPeekMemory: Bool {
        didSet { userDefaults.set(autoPeekMemory, forKey: SettingsKey.autoPeekMemory.rawValue) }
    }

    public var reviewReminderEnabled: Bool {
        didSet { persistReviewReminderEnabled() }
    }

    public var reviewReminderTime: Date {
        didSet { persistReviewReminderTime() }
    }

    public var hideCompletedLessons: Bool {
        didSet { userDefaults.set(hideCompletedLessons, forKey: "smackapad.library.hideCompleted") }
    }

    public var introSkipped: Bool {
        didSet { userDefaults.set(introSkipped, forKey: Self.introSkippedKey) }
    }

    public var hiddenCategoryIDsByMode: [String: Set<String>] {
        didSet { persistHiddenCategories() }
    }

    // MARK: Initialization

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        userDefaults.removeObject(forKey: "smackapad.practice.showPadKeys")

        if let data = userDefaults.data(forKey: SettingsKey.midiControls.rawValue),
           let controls = try? JSONDecoder().decode(MIDIControlConfiguration.self, from: data) {
            midiControls = controls.validated()
        } else {
            midiControls = MIDIControlConfiguration()
        }

        practiceMode = PracticeMode(rawValue: userDefaults.string(forKey: SettingsKey.practiceMode.rawValue) ?? "") ?? .learning
        libraryView = LibraryViewMode(rawValue: userDefaults.string(forKey: "smackapad.library.view") ?? "")?.rawValue ?? "path"
        libraryStarFilters = userDefaults.stringArray(forKey: "smackapad.library.stars") ?? LibraryStarFilter.allCases.map(\.rawValue)
        nextLessonSource = NextLessonSource(rawValue: userDefaults.string(forKey: "smackapad.library.nextSource") ?? "")?.rawValue ?? "path"
        lastLessonID = userDefaults.integer(forKey: "smackapad.library.lastLesson")

        self.selectedKitId = userDefaults.string(forKey: SettingsKey.selectedKitId.rawValue) ?? Self.defaultKitId
        let initialSkinId = userDefaults.string(forKey: SettingsKey.selectedInstrumentSkinId.rawValue) ?? StudioRigCatalog.defaultSkinId
        self.selectedInstrumentSkinId = initialSkinId
        Theme.setActiveSkinId(initialSkinId)

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

        let rawStep = userDefaults.integer(forKey: SettingsKey.bpmStep.rawValue)
        self.bpmStep = (rawStep > 0 && BpmStep(rawValue: rawStep) != nil) ? rawStep : Self.defaultBpmStep

        let initialProfile = userDefaults.string(forKey: SettingsKey.activeProfileName.rawValue) ?? Self.defaultProfileName
        self.activeProfileName = initialProfile

        if let rawOffsets = userDefaults.dictionary(forKey: SettingsKey.calibrationOffsets.rawValue) as? [String: Double] {
            self.calibrationOffsets = rawOffsets
        } else {
            self.calibrationOffsets = [:]
        }

        if let rawLang = userDefaults.string(forKey: SettingsKey.languagePreference.rawValue),
           let lang = AppLanguage(rawValue: rawLang) {
            self.languagePreference = lang
        } else {
            self.languagePreference = Self.defaultLanguage
        }

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

        if let data = userDefaults.data(forKey: SettingsKey.customProfiles.rawValue),
           let profiles = try? JSONDecoder().decode([ControllerProfile].self, from: data) {
            self.customProfiles = profiles.filter(\.isValid)
        } else {
            self.customProfiles = []
        }

        self.metronomeVolume = Self.loadVolume(from: userDefaults, key: .metronomeVolume, defaultValue: Self.defaultMetronomeVolume)
        self.padsVolume = Self.loadVolume(from: userDefaults, key: .padsVolume, defaultValue: Self.defaultPadsVolume)
        self.patternVolume = Self.loadVolume(from: userDefaults, key: .patternVolume, defaultValue: Self.defaultPatternVolume)

        if let data = userDefaults.data(forKey: SettingsKey.instrumentTrims.rawValue),
           let stored = try? JSONDecoder().decode([String: Int].self, from: data) {
            self.instrumentTrims = Self.cleanTrims(stored)
        } else {
            self.instrumentTrims = [:]
        }

        self.playPadsWithKeyboard = userDefaults.object(forKey: SettingsKey.playPadsWithKeyboard.rawValue) as? Bool ?? true
        self.fadeMemoryNotes = userDefaults.object(forKey: SettingsKey.fadeMemoryNotes.rawValue) as? Bool ?? true
        self.autoPeekMemory = userDefaults.object(forKey: SettingsKey.autoPeekMemory.rawValue) as? Bool ?? true
        self.reviewReminderEnabled = userDefaults.bool(forKey: SettingsKey.reviewReminderEnabled.rawValue)
        if let storedReminderTime = userDefaults.object(forKey: SettingsKey.reviewReminderTime.rawValue) as? Date {
            self.reviewReminderTime = storedReminderTime
        } else {
            self.reviewReminderTime = Self.defaultReminderTime()
        }
        self.hideCompletedLessons = userDefaults.object(forKey: "smackapad.library.hideCompleted") as? Bool ?? true
        self.introSkipped = userDefaults.bool(forKey: Self.introSkippedKey)

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
}
