//
//  SettingsManager+Profiles.swift
//  SmackAPad
//

import Foundation

// MARK: - Controller Profile Management

extension SettingsManager {
    /// Looks up a profile by name (checks custom profiles first, then standard built-in presets).
    public func profile(named name: String) -> ControllerProfile? {
        withLock {
            if let custom = customProfiles.first(where: { $0.profileName == name }) {
                return custom
            }
            return ControllerProfile.builtInProfiles.first { $0.profileName == name }
        }
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
        withLock {
            guard profile.isValid,
                  !ControllerProfile.builtInProfiles.contains(where: { $0.profileName == profile.profileName }) else { return }
            var updated = customProfiles.filter { $0.profileName != profile.profileName }
            updated.append(profile)
            self.customProfiles = updated
        }
    }

    /// Deletes a custom profile by name. If it was active, resets activeProfileName to default.
    public func deleteProfile(named name: String) {
        withLock {
            customProfiles.removeAll { $0.profileName == name }
            if activeProfileName == name {
                self.activeProfileName = Self.defaultProfileName
            }
        }
    }

    /// Returns all available profiles (presets + user custom profiles).
    public func allProfiles() -> [ControllerProfile] {
        withLock {
            var result: [ControllerProfile] = ControllerProfile.builtInProfiles
            for custom in customProfiles {
                if !result.contains(where: { $0.profileName == custom.profileName }) {
                    result.append(custom)
                }
            }
            return result
        }
    }

    func persistActiveProfileName() {
        withLock {
            userDefaults.set(activeProfileName, forKey: SettingsKey.activeProfileName.rawValue)
        }
    }

    func persistCustomProfiles() {
        withLock {
            if let data = try? JSONEncoder().encode(customProfiles) {
                userDefaults.set(data, forKey: SettingsKey.customProfiles.rawValue)
            }
        }
    }
}
