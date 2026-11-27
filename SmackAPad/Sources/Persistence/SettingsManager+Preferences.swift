//
//  SettingsManager+Preferences.swift
//  SmackAPad
//

import Foundation

// MARK: - Localization, Appearance, BPM & Reminders

extension SettingsManager {
    static let introSkippedKey = "smackapad.progression.introSkipped"

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

    public func localizedBarCount(_ bars: Int) -> String {
        if bars == 1 {
            return localized("1 bar")
        }
        if languagePreference == .czech && bars >= 5 {
            return "\(bars) taktů"
        }
        return localized("%lld bars", bars)
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

    func persistBpmStep() {
        withLock {
            // Ensure valid BPM step
            let validStep = BpmStep.from(raw: bpmStep).rawValue
            if bpmStep != validStep {
                bpmStep = validStep
                return
            }
            userDefaults.set(validStep, forKey: SettingsKey.bpmStep.rawValue)
        }
    }

    func persistLanguage() {
        withLock {
            userDefaults.set(languagePreference.rawValue, forKey: SettingsKey.languagePreference.rawValue)
        }
    }

    func persistAppearance() {
        withLock {
            userDefaults.set(appearance.rawValue, forKey: SettingsKey.appearance.rawValue)
            userDefaults.set(appearance.rawValue, forKey: "smackapad.practice.appearance")
        }
    }

    func persistReviewReminderEnabled() {
        withLock {
            userDefaults.set(reviewReminderEnabled, forKey: SettingsKey.reviewReminderEnabled.rawValue)
        }
    }

    func persistReviewReminderTime() {
        withLock {
            userDefaults.set(reviewReminderTime, forKey: SettingsKey.reviewReminderTime.rawValue)
        }
    }
}
