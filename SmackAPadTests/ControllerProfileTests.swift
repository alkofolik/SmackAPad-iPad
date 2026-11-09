import XCTest
@testable import SmackAPad

final class ControllerProfileTests: XCTestCase {
    func testBuiltInProfilesHaveNeutralNames() throws {
        XCTAssertEqual(ControllerProfile.builtInProfiles.map(\.profileName),
                       ["Standard 16-Pad", "Standard 8-Pad"])
        XCTAssertEqual(AppLanguage.english.localized("16 pads, notes 36–51"), "16 pads, notes 36–51")
        XCTAssertEqual(AppLanguage.czech.localized("16 pads, notes 36–51"), "16 padů, noty 36–51")

        for language in AppLanguage.allCases {
            let catalog = try XCTUnwrap(Bundle.main.url(forResource: "Localizable", withExtension: "strings",
                                                       subdirectory: nil, localization: language.rawValue))
            let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: catalog),
                                                                   options: [], format: nil)
            let strings = try XCTUnwrap(plist as? [String: String])
            for text in Array(strings.keys) + Array(strings.values) {
                XCTAssertFalse(text.localizedCaseInsensitiveContains("Akai"))
                XCTAssertFalse(text.localizedCaseInsensitiveContains("Maschine"))
            }
        }
    }

    func testSavedBrandedSelectionsMigrateToTheSameNoteMap() throws {
        let suite = "ControllerProfileTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let noteMap = [
            36: 12, 37: 13, 38: 14, 39: 15,
            40: 8, 41: 9, 42: 10, 43: 11,
            44: 4, 45: 5, 46: 6, 47: 7,
            48: 0, 49: 1, 50: 2, 51: 3
        ]

        for oldName in ["Akai MPD (36–51)", "NI Maschine (36–51)"] {
            defaults.set(oldName, forKey: "smackapad.settings.activeProfileName")
            let settings = SettingsManager(userDefaults: defaults)
            XCTAssertEqual(settings.activeProfileName, ControllerProfile.standard16.profileName)
            XCTAssertEqual(settings.activeProfile().padCount, 16)
            XCTAssertEqual(settings.activeProfile().noteMap, noteMap)
            XCTAssertEqual(defaults.string(forKey: "smackapad.settings.activeProfileName"),
                           ControllerProfile.standard16.profileName)
        }
    }

    func testCustomAndEightPadSelectionsLoadUnchanged() throws {
        let suite = "ControllerProfileTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsManager(userDefaults: defaults)
        let custom = ControllerProfile(profileName: "My learned profile",
                                       noteMap: [40: 0, 42: 1, 44: 2, 46: 3, 48: 4, 50: 5, 52: 6, 54: 7],
                                       padCount: 8)
        settings.saveProfile(custom)

        for profile in [custom, .standard8] {
            settings.activeProfileName = profile.profileName
            let reloaded = SettingsManager(userDefaults: defaults)
            XCTAssertEqual(reloaded.activeProfileName, profile.profileName)
            XCTAssertEqual(reloaded.activeProfile(), profile)
            XCTAssertEqual(reloaded.customProfiles, [custom])
        }
    }
}
