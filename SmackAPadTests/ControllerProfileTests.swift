import XCTest
@testable import SmackAPad

final class ControllerProfileTests: XCTestCase {
    func testProfilesWithoutArrangementDecodeWithDefaultsAndKeepTheirNoteMaps() throws {
        for preset in [ControllerProfile.standard8, .standard16] {
            let oldFormat: [String: Any] = [
                "profileName": "Old \(preset.padCount)-pad profile",
                "padCount": preset.padCount,
                "noteMap": Dictionary(uniqueKeysWithValues: preset.noteMap.map { (String($0.key), $0.value) })
            ]
            let data = try JSONSerialization.data(withJSONObject: oldFormat)
            let profile = try JSONDecoder().decode(ControllerProfile.self, from: data)
            XCTAssertEqual(profile.rows, preset.padCount == 8 ? 2 : 4)
            XCTAssertEqual(profile.columns, 4)
            XCTAssertEqual(profile.noteMap, preset.noteMap)
            XCTAssertTrue(profile.isValid)
            XCTAssertEqual(try JSONDecoder().decode(ControllerProfile.self, from: JSONEncoder().encode(profile)), profile)
        }
    }

    func testEveryHardwareArrangementNumbersSlotsFromBottomLeft() {
        let cases: [(Int, PhysicalPadGrid, [Int])] = [
            (8, .init(rows: 2, columns: 4), [4, 5, 6, 7, 0, 1, 2, 3]),
            (8, .init(rows: 4, columns: 2), [6, 7, 4, 5, 2, 3, 0, 1]),
            (8, .init(rows: 1, columns: 8), Array(0..<8)),
            (16, .init(rows: 4, columns: 4), [12, 13, 14, 15, 8, 9, 10, 11, 4, 5, 6, 7, 0, 1, 2, 3]),
            (16, .init(rows: 2, columns: 8), Array(8..<16) + Array(0..<8))
        ]
        for count in [8, 16] {
            XCTAssertEqual(PhysicalPadGrid.arrangements(padCount: count), cases.filter { $0.0 == count }.map { $0.1 })
        }
        for (count, grid, expectedSlots) in cases {
            XCTAssertEqual(grid.displaySlots, expectedSlots)
            XCTAssertEqual(grid.position(forSlot: 0).row, grid.rows - 1)
            XCTAssertEqual(grid.position(forSlot: 0).column, 0)
            for (displayIndex, slot) in expectedSlots.enumerated() {
                let position = grid.position(forSlot: slot)
                XCTAssertEqual(position.row, displayIndex / grid.columns)
                XCTAssertEqual(position.column, displayIndex % grid.columns)
                let target = PhysicalPadGrid.target(forSlot: slot, padCount: count)
                let preset = count == 8 ? ControllerProfile.standard8 : .standard16
                XCTAssertEqual(preset.midiNote(forTarget: target), 36 + slot)
            }
        }
    }

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
