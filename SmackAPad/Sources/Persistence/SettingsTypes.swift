//
//  SettingsTypes.swift
//  SmackAPad
//

import Foundation

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

