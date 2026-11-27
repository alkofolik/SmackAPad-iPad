//
//  SettingsManager+Backup.swift
//  SmackAPad
//

import Foundation

// MARK: - Device ID, Reset & Export/Import

extension SettingsManager {
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

    /// Resets all settings to factory defaults.
    public func resetToDefaults() {
        withLock {
            for key in SettingsKey.allCases {
                userDefaults.removeObject(forKey: key.rawValue)
            }
            self.selectedKitId = Self.defaultKitId
            self.selectedInstrumentSkinId = StudioRigCatalog.defaultSkinId
            self.lessonKitOverrides = [:]
            self.midiControls = MIDIControlConfiguration()
            self.practiceMode = .learning
            self.playMode = Self.defaultPlayMode
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
            self.autoPeekMemory = true
            self.reviewReminderEnabled = false
            self.reviewReminderTime = Self.defaultReminderTime()
            userDefaults.removeObject(forKey: "smackapad.training.dueStepFilter")
            userDefaults.removeObject(forKey: "smackapad.library.hideCompleted")
            self.hideCompletedLessons = true
            self.introSkipped = false
            for mode in ["path", "genre", "technique"] {
                userDefaults.removeObject(forKey: "smackapad.library.hiddenCategories.\(mode)")
            }
            self.hiddenCategoryIDsByMode = [:]
        }
    }

    /// Exports player preferences for backup. Device-specific offsets (calibration, etc.) are excluded.
    public func exportSettings() -> BackupSettings {
        withLock {
            let showPads = userDefaults.object(forKey: "smackapad.practice.showPads") as? Bool ?? true
            let visibleBars = userDefaults.integer(forKey: "smackapad.practice.visibleBars")
            let touchPadsInPortrait = userDefaults.object(forKey: "smackapad.practice.touchPadsInPortrait") as? Bool ?? true
            let scrolling = userDefaults.string(forKey: "smackapad.practice.scrolling") ?? "continuous"
            let practiceAppearance = userDefaults.string(forKey: "smackapad.practice.appearance") ?? "system"

            let legendShownOnce = userDefaults.bool(forKey: "smackapad.legend.shownOnce")
            let memoryHints = userDefaults.array(forKey: "smackapad.memoryHintShownLessonIds") as? [Int] ?? []

            let modifiedAt = userDefaults.object(forKey: "smackapad.settings.modifiedAt") as? Date

            return BackupSettings(
                settingsModifiedAt: modifiedAt,
                selectedKitId: selectedKitId,
                selectedInstrumentSkinId: selectedInstrumentSkinId,
                lessonKitOverrides: lessonKitOverrides,
                midiControls: midiControls,
                bpmStep: bpmStep,
                practiceMode: practiceMode.rawValue,
                playMode: playMode.rawValue,
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
                autoPeekMemory: autoPeekMemory,
                reviewReminderEnabled: reviewReminderEnabled,
                reviewReminderTime: reviewReminderTime,
                hideCompletedLessons: hideCompletedLessons,
                introSkipped: introSkipped,
                hiddenCategoryIDsByMode: hiddenCategoryIDsByMode,
                libraryView: libraryView,
                libraryStarFilters: libraryStarFilters,
                nextLessonSource: nextLessonSource,
                lastLessonID: lastLessonID,
                showPads: showPads,
                visibleBars: visibleBars > 0 ? visibleBars : 1,
                touchPadsInPortrait: touchPadsInPortrait,
                scrolling: scrolling,
                practiceAppearance: practiceAppearance,
                legendShownOnce: legendShownOnce,
                memoryHintShownLessonIds: Set(memoryHints)
            )
        }
    }

    /// Applies portable player preferences from a backup on a fresh device.
    /// Hardware/route calibration offsets are intentionally not restored.
    public func applyImportedSettings(_ settings: BackupSettings) {
        withLock {
            self.selectedKitId = settings.selectedKitId
            self.selectedInstrumentSkinId = settings.selectedInstrumentSkinId
            self.lessonKitOverrides = settings.lessonKitOverrides
            self.midiControls = settings.midiControls
            self.bpmStep = settings.bpmStep
            if let mode = PracticeMode(rawValue: settings.practiceMode) {
                self.practiceMode = mode
            }
            if let mode = PlayMode(rawValue: settings.playMode) {
                self.playMode = mode
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
            self.autoPeekMemory = settings.autoPeekMemory
            self.reviewReminderEnabled = settings.reviewReminderEnabled
            if let time = settings.reviewReminderTime {
                self.reviewReminderTime = time
            }
            self.hideCompletedLessons = settings.hideCompletedLessons
            self.introSkipped = settings.introSkipped
            self.hiddenCategoryIDsByMode = settings.hiddenCategoryIDsByMode
            self.libraryView = settings.libraryView
            self.libraryStarFilters = settings.libraryStarFilters
            self.nextLessonSource = settings.nextLessonSource
            self.lastLessonID = settings.lastLessonID

            userDefaults.set(settings.showPads, forKey: "smackapad.practice.showPads")
            if settings.visibleBars > 0 {
                userDefaults.set(settings.visibleBars, forKey: "smackapad.practice.visibleBars")
            }
            userDefaults.set(settings.touchPadsInPortrait, forKey: "smackapad.practice.touchPadsInPortrait")
            userDefaults.set(settings.scrolling, forKey: "smackapad.practice.scrolling")
            userDefaults.set(settings.practiceAppearance, forKey: "smackapad.practice.appearance")

            userDefaults.set(settings.legendShownOnce, forKey: "smackapad.legend.shownOnce")
            if !settings.memoryHintShownLessonIds.isEmpty {
                userDefaults.set(Array(settings.memoryHintShownLessonIds), forKey: "smackapad.memoryHintShownLessonIds")
            }

            if let mod = settings.settingsModifiedAt {
                userDefaults.set(mod, forKey: "smackapad.settings.modifiedAt")
            }
        }
    }
}
