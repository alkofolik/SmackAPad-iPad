import Foundation
import SwiftUI
import UniformTypeIdentifiers

public enum ProgressBackupError: LocalizedError, Equatable {
    case invalidEnvelope
    case newerVersion(Int)
    case corruptedData(String)

    public var errorDescription: String? {
        switch self {
        case .invalidEnvelope:
            return "This file is not a Smack-a-Pad backup. Nothing was changed."
        case .newerVersion:
            return "This backup was created in a newer version of Smack-a-Pad. Update the app to restore it."
        case .corruptedData(let message):
            return "Backup data is corrupt: \(message)"
        }
    }
}

public struct BackupSettings: Codable, Equatable, Sendable {
    public var settingsModifiedAt: Date?
    public var selectedKitId: String
    public var lessonKitOverrides: [Int: String]
    public var midiControls: MIDIControlConfiguration
    public var bpmStep: Int
    public var practiceMode: String
    public var activeProfileName: String
    public var customProfiles: [ControllerProfile]
    public var languagePreference: String
    public var appearance: String
    public var metronomeVolume: Int
    public var padsVolume: Int
    public var patternVolume: Int
    public var instrumentTrims: [String: Int]
    public var playPadsWithKeyboard: Bool
    public var fadeMemoryNotes: Bool
    public var reviewReminderEnabled: Bool
    public var reviewReminderTime: Date?
    public var hideCompletedLessons: Bool
    public var hiddenCategoryIDsByMode: [String: Set<String>]
    public var libraryView: String
    public var libraryStarFilters: [String]
    public var trainingDueStepFilter: String
    public var nextLessonSource: String
    public var lastLessonID: Int
    public var showPads: Bool
    public var showPadKeys: Bool
    public var visibleBars: Int
    public var touchPadsInPortrait: Bool
    public var scrolling: String
    public var practiceAppearance: String
    public var legendShownOnce: Bool
    public var memoryHintShownLessonIds: Set<Int>

    public init(
        settingsModifiedAt: Date? = nil,
        selectedKitId: String = SettingsManager.defaultKitId,
        lessonKitOverrides: [Int: String] = [:],
        midiControls: MIDIControlConfiguration? = nil,
        bpmStep: Int = SettingsManager.defaultBpmStep,
        practiceMode: String = PracticeMode.learning.rawValue,
        activeProfileName: String = SettingsManager.defaultProfileName,
        customProfiles: [ControllerProfile] = [],
        languagePreference: String = SettingsManager.defaultLanguage.rawValue,
        appearance: String = SettingsManager.defaultAppearance.rawValue,
        metronomeVolume: Int = SettingsManager.defaultMetronomeVolume,
        padsVolume: Int = SettingsManager.defaultPadsVolume,
        patternVolume: Int = SettingsManager.defaultPatternVolume,
        instrumentTrims: [String: Int] = [:],
        playPadsWithKeyboard: Bool = true,
        fadeMemoryNotes: Bool = true,
        reviewReminderEnabled: Bool = false,
        reviewReminderTime: Date? = nil,
        hideCompletedLessons: Bool = false,
        hiddenCategoryIDsByMode: [String: Set<String>] = [:],
        libraryView: String = "categories",
        libraryStarFilters: [String] = [],
        trainingDueStepFilter: String = "all",
        nextLessonSource: String = "library",
        lastLessonID: Int = 10001,
        showPads: Bool = true,
        showPadKeys: Bool = true,
        visibleBars: Int = 1,
        touchPadsInPortrait: Bool = true,
        scrolling: String = "continuous",
        practiceAppearance: String = "system",
        legendShownOnce: Bool = false,
        memoryHintShownLessonIds: Set<Int> = []
    ) {
        self.settingsModifiedAt = settingsModifiedAt
        self.selectedKitId = selectedKitId
        self.lessonKitOverrides = lessonKitOverrides
        self.midiControls = midiControls ?? MIDIControlConfiguration()
        self.bpmStep = bpmStep
        self.practiceMode = practiceMode
        self.activeProfileName = activeProfileName
        self.customProfiles = customProfiles
        self.languagePreference = languagePreference
        self.appearance = appearance
        self.metronomeVolume = metronomeVolume
        self.padsVolume = padsVolume
        self.patternVolume = patternVolume
        self.instrumentTrims = SettingsManager.cleanTrims(instrumentTrims)
        self.playPadsWithKeyboard = playPadsWithKeyboard
        self.fadeMemoryNotes = fadeMemoryNotes
        self.reviewReminderEnabled = reviewReminderEnabled
        self.reviewReminderTime = reviewReminderTime
        self.hideCompletedLessons = hideCompletedLessons
        self.hiddenCategoryIDsByMode = hiddenCategoryIDsByMode
        self.libraryView = libraryView
        self.libraryStarFilters = libraryStarFilters
        self.trainingDueStepFilter = trainingDueStepFilter
        self.nextLessonSource = nextLessonSource
        self.lastLessonID = lastLessonID
        self.showPads = showPads
        self.showPadKeys = showPadKeys
        self.visibleBars = visibleBars
        self.touchPadsInPortrait = touchPadsInPortrait
        self.scrolling = scrolling
        self.practiceAppearance = practiceAppearance
        self.legendShownOnce = legendShownOnce
        self.memoryHintShownLessonIds = memoryHintShownLessonIds
    }

    private enum CodingKeys: String, CodingKey {
        case settingsModifiedAt, selectedKitId, lessonKitOverrides, midiControls, bpmStep, practiceMode
        case activeProfileName, customProfiles, languagePreference, appearance, metronomeVolume, padsVolume, patternVolume, instrumentTrims
        case playPadsWithKeyboard, fadeMemoryNotes, reviewReminderEnabled, reviewReminderTime, hideCompletedLessons
        case hiddenCategoryIDsByMode, libraryView, libraryStarFilters, trainingDueStepFilter, nextLessonSource, lastLessonID
        case showPads, showPadKeys, visibleBars, touchPadsInPortrait, scrolling, practiceAppearance
        case legendShownOnce, memoryHintShownLessonIds
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.settingsModifiedAt = try c.decodeIfPresent(Date.self, forKey: .settingsModifiedAt)
        self.selectedKitId = try c.decodeIfPresent(String.self, forKey: .selectedKitId) ?? SettingsManager.defaultKitId
        self.lessonKitOverrides = try c.decodeIfPresent([Int: String].self, forKey: .lessonKitOverrides) ?? [:]
        self.midiControls = try c.decodeIfPresent(MIDIControlConfiguration.self, forKey: .midiControls) ?? MIDIControlConfiguration()
        self.bpmStep = try c.decodeIfPresent(Int.self, forKey: .bpmStep) ?? SettingsManager.defaultBpmStep
        self.practiceMode = try c.decodeIfPresent(String.self, forKey: .practiceMode) ?? PracticeMode.learning.rawValue
        self.activeProfileName = try c.decodeIfPresent(String.self, forKey: .activeProfileName) ?? SettingsManager.defaultProfileName
        self.customProfiles = try c.decodeIfPresent([ControllerProfile].self, forKey: .customProfiles) ?? []
        self.languagePreference = try c.decodeIfPresent(String.self, forKey: .languagePreference) ?? SettingsManager.defaultLanguage.rawValue
        self.appearance = try c.decodeIfPresent(String.self, forKey: .appearance) ?? SettingsManager.defaultAppearance.rawValue
        self.metronomeVolume = try c.decodeIfPresent(Int.self, forKey: .metronomeVolume) ?? SettingsManager.defaultMetronomeVolume
        self.padsVolume = try c.decodeIfPresent(Int.self, forKey: .padsVolume) ?? SettingsManager.defaultPadsVolume
        self.patternVolume = try c.decodeIfPresent(Int.self, forKey: .patternVolume) ?? SettingsManager.defaultPatternVolume
        self.instrumentTrims = SettingsManager.cleanTrims(
            try c.decodeIfPresent([String: Int].self, forKey: .instrumentTrims) ?? [:])
        self.playPadsWithKeyboard = try c.decodeIfPresent(Bool.self, forKey: .playPadsWithKeyboard) ?? true
        self.fadeMemoryNotes = try c.decodeIfPresent(Bool.self, forKey: .fadeMemoryNotes) ?? true
        self.reviewReminderEnabled = try c.decodeIfPresent(Bool.self, forKey: .reviewReminderEnabled) ?? false
        self.reviewReminderTime = try c.decodeIfPresent(Date.self, forKey: .reviewReminderTime)
        self.hideCompletedLessons = try c.decodeIfPresent(Bool.self, forKey: .hideCompletedLessons) ?? false
        self.hiddenCategoryIDsByMode = try c.decodeIfPresent([String: Set<String>].self, forKey: .hiddenCategoryIDsByMode) ?? [:]
        self.libraryView = try c.decodeIfPresent(String.self, forKey: .libraryView) ?? "categories"
        self.libraryStarFilters = try c.decodeIfPresent([String].self, forKey: .libraryStarFilters) ?? []
        self.trainingDueStepFilter = try c.decodeIfPresent(String.self, forKey: .trainingDueStepFilter) ?? "all"
        self.nextLessonSource = try c.decodeIfPresent(String.self, forKey: .nextLessonSource) ?? "library"
        self.lastLessonID = try c.decodeIfPresent(Int.self, forKey: .lastLessonID) ?? 10001
        self.showPads = try c.decodeIfPresent(Bool.self, forKey: .showPads) ?? true
        self.showPadKeys = try c.decodeIfPresent(Bool.self, forKey: .showPadKeys) ?? true
        self.visibleBars = try c.decodeIfPresent(Int.self, forKey: .visibleBars) ?? 1
        self.touchPadsInPortrait = try c.decodeIfPresent(Bool.self, forKey: .touchPadsInPortrait) ?? true
        self.scrolling = try c.decodeIfPresent(String.self, forKey: .scrolling) ?? "continuous"
        self.practiceAppearance = try c.decodeIfPresent(String.self, forKey: .practiceAppearance) ?? "system"
        self.legendShownOnce = try c.decodeIfPresent(Bool.self, forKey: .legendShownOnce) ?? false
        self.memoryHintShownLessonIds = try c.decodeIfPresent(Set<Int>.self, forKey: .memoryHintShownLessonIds) ?? []
    }
}

public struct ProgressBackupEnvelope: Codable, Equatable, Sendable {
    public var app: String
    public var formatVersion: Int
    public var exportedAt: Date
    public var appVersion: String
    public var deviceId: String
    public var progress: [Int: LessonProgress]
    public var trainingLog: TrainingLog
    public var badges: [String: Date]
    public var settings: BackupSettings

    public init(
        app: String = ProgressBackup.appIdentifier,
        formatVersion: Int = ProgressBackup.currentFormatVersion,
        exportedAt: Date = AppCalendar.now(),
        appVersion: String = "1.0",
        deviceId: String = "",
        progress: [Int: LessonProgress] = [:],
        trainingLog: TrainingLog = TrainingLog(),
        badges: [String: Date] = [:],
        settings: BackupSettings = BackupSettings()
    ) {
        self.app = app
        self.formatVersion = formatVersion
        self.exportedAt = exportedAt
        self.appVersion = appVersion
        self.deviceId = deviceId
        self.progress = progress
        self.trainingLog = trainingLog
        self.badges = badges
        self.settings = settings
    }

    private enum CodingKeys: String, CodingKey {
        case app, formatVersion, exportedAt, appVersion, deviceId, progress, trainingLog, badges, settings
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.app = try container.decode(String.self, forKey: .app)
        self.formatVersion = try container.decode(Int.self, forKey: .formatVersion)
        self.exportedAt = try container.decode(Date.self, forKey: .exportedAt)
        self.appVersion = try container.decodeIfPresent(String.self, forKey: .appVersion) ?? "1.0"
        self.deviceId = try container.decodeIfPresent(String.self, forKey: .deviceId) ?? ""

        let stringLessons = try container.decodeIfPresent([String: LessonProgress].self, forKey: .progress) ?? [:]
        var converted: [Int: LessonProgress] = [:]
        for (k, v) in stringLessons {
            if let id = Int(k) { converted[id] = v }
        }
        self.progress = converted

        self.trainingLog = try container.decodeIfPresent(TrainingLog.self, forKey: .trainingLog) ?? TrainingLog()
        self.badges = try container.decodeIfPresent([String: Date].self, forKey: .badges) ?? [:]
        self.settings = try container.decodeIfPresent(BackupSettings.self, forKey: .settings) ?? BackupSettings()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(app, forKey: .app)
        try container.encode(formatVersion, forKey: .formatVersion)
        try container.encode(exportedAt, forKey: .exportedAt)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(deviceId, forKey: .deviceId)

        var stringLessons: [String: LessonProgress] = [:]
        for (id, record) in progress {
            stringLessons[String(id)] = record
        }
        try container.encode(stringLessons, forKey: .progress)
        try container.encode(trainingLog, forKey: .trainingLog)
        try container.encode(badges, forKey: .badges)
        try container.encode(settings, forKey: .settings)
    }
}

public enum ProgressBackup {
    public static let currentFormatVersion = 1
    public static let appIdentifier = "smack-a-pad"

    public static func encode(envelope: ProgressBackupEnvelope) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(envelope)
    }

    public static func decode(from data: Data) throws -> ProgressBackupEnvelope {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let app = jsonObject["app"] as? String,
              app == appIdentifier else {
            throw ProgressBackupError.invalidEnvelope
        }

        if let version = jsonObject["formatVersion"] as? Int, version > currentFormatVersion {
            throw ProgressBackupError.newerVersion(version)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(ProgressBackupEnvelope.self, from: data)
        } catch {
            throw ProgressBackupError.corruptedData(error.localizedDescription)
        }
    }
}

public struct BackupDocument: FileDocument {
    public static var readableContentTypes: [UTType] { [.json] }
    public var data: Data

    public init(data: Data = Data()) {
        self.data = data
    }

    public init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
