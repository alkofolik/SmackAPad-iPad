//
//  SoundKitResolverTests.swift
//  SmackAPadTests
//
//  Tests sound kit resolution order, automatic genre mapping table,
//  voice safety fallback, per-lesson override persistence, and settings migration.
//

import XCTest
@testable import SmackAPad

final class SoundKitResolverTests: XCTestCase {

    private func makeLesson(
        id: Int = 1,
        genre: String = "Rock",
        padIndices: [Int] = [12, 13] // kick, snare
    ) -> Lesson {
        let hits = padIndices.enumerated().map { offset, pad in
            LessonHit(step: offset * 4, padIndex: pad, hand: "R", velocity: 100)
        }
        return Lesson(
            id: id,
            cat: "rock",
            title: "Test Lesson",
            genre: genre,
            tags: [],
            text: "Lesson description",
            division: 16,
            bars: 1,
            startBpm: 80,
            targetBpm: 120,
            level: 1,
            score: 0,
            src: "test",
            hits: hits,
            hits8: nil,
            eightNote: nil,
            intro: nil
        )
    }

    private func createSettings(selectedKit: String? = nil, overrides: [Int: String] = [:]) -> (SettingsManager, UserDefaults) {
        let suiteName = "SoundKitResolverTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        if let selectedKit = selectedKit {
            defaults.set(selectedKit, forKey: SettingsKey.selectedKitId.rawValue)
        }
        if !overrides.isEmpty {
            let data = try! JSONEncoder().encode(overrides)
            defaults.set(data, forKey: SettingsKey.lessonKitOverrides.rawValue)
        }
        let settings = SettingsManager(userDefaults: defaults)
        return (settings, defaults)
    }

    // MARK: - Automatic Genre Mapping

    func testAutomaticGenreMappingEveryGenreInTable() {
        let expectedTable: [String: [String]] = [
            "rock": ["Rock", "Punk", "Country", "Pop", "Blues", "Gospel"],
            "acoustic": ["Funk", "Soul", "Disco", "Lo-fi", "Trip hop"],
            "jazz": ["Jazz", "New Orleans"],
            "world": ["Latin", "Afrobeat", "Highlife", "Reggae", "Reggaeton", "Middle Eastern"],
            "worldperc": ["Afro-Cuban"],
            "808": ["Hip hop", "Trap", "Miami bass", "Electro"],
            "house": [
                "Dance", "House", "Deep house", "Tech house", "Techno",
                "Hard techno", "Trance", "UK garage", "Dubstep", "Drum and bass",
                "Jungle", "Breakbeat", "Moombahton", "Synthwave"
            ]
        ]

        for (kit, genres) in expectedTable {
            for genre in genres {
                let resolved = SoundKitResolver.kitId(forGenre: genre)
                XCTAssertEqual(resolved, kit, "Genre '\(genre)' should map to '\(kit)'")

                // Test case-insensitivity: lowercase and uppercase
                XCTAssertEqual(SoundKitResolver.kitId(forGenre: genre.lowercased()), kit)
                XCTAssertEqual(SoundKitResolver.kitId(forGenre: genre.uppercased()), kit)
            }
        }
    }

    func testUnknownGenreDefaultsToAcoustic() {
        let unlistedGenres = ["Polka", "Heavy Metal", "Opera", "RandomGenre", "", "   ", nil]
        for genre in unlistedGenres {
            XCTAssertEqual(SoundKitResolver.kitId(forGenre: genre), "acoustic")
        }
    }

    // MARK: - Resolution Order

    func testResolutionOrderOverrideBeatsGlobalBeatsAuto() {
        let lesson = makeLesson(id: 42, genre: "Rock") // "Rock" maps to "rock" in auto

        // 1. When override is set, it beats both global and auto
        let (settingsOverride, _) = createSettings(selectedKit: "house", overrides: [42: "808"])
        XCTAssertEqual(SoundKitResolver.resolveKitId(for: lesson, settings: settingsOverride), "808")

        // 2. When override is cleared ("auto" or removed), global kit beats auto
        let (settingsGlobal, _) = createSettings(selectedKit: "jazz", overrides: [:])
        XCTAssertEqual(SoundKitResolver.resolveKitId(for: lesson, settings: settingsGlobal), "jazz")

        // 3. When global is "auto", genre mapping determines the kit
        let (settingsAuto, _) = createSettings(selectedKit: "auto", overrides: [:])
        XCTAssertEqual(SoundKitResolver.resolveKitId(for: lesson, settings: settingsAuto), "rock")

        // 4. Per-lesson override beats "auto" global
        let (settingsOverrideOverAuto, _) = createSettings(selectedKit: "auto", overrides: [42: "world"])
        XCTAssertEqual(SoundKitResolver.resolveKitId(for: lesson, settings: settingsOverrideOverAuto), "world")
    }

    func testRockAndHouseLessonsPlayDifferentKitsOnAutomatic() {
        let (settings, _) = createSettings(selectedKit: "auto")

        let rockLesson = makeLesson(id: 1, genre: "Rock")
        let houseLesson = makeLesson(id: 2, genre: "House")

        let rockKit = SoundKitResolver.resolveKitId(for: rockLesson, settings: settings)
        let houseKit = SoundKitResolver.resolveKitId(for: houseLesson, settings: settings)

        XCTAssertEqual(rockKit, "rock")
        XCTAssertEqual(houseKit, "house")
        XCTAssertNotEqual(rockKit, houseKit)
    }

    // MARK: - Voice Safety Fallback

    func testMissingVoiceFallsBackToAcoustic() {
        // Pad 6 corresponds to "cowbell" in AudioEngine.defaultPadVoices
        let lessonWithCowbell = makeLesson(id: 1, genre: "Rock", padIndices: [12, 13, 6]) // kick, snare, cowbell

        let kickEntry = SampleVoiceEntry(url: "samples/test/kick.wav", maxVel: 127)
        let snareEntry = SampleVoiceEntry(url: "samples/test/snare.wav", maxVel: 127)

        // Mock kit missing cowbell
        let incompleteKit = SampleKit(
            kitId: "incomplete",
            name: "Incomplete Kit",
            license: "MIT",
            voices: [
                "kick": [kickEntry],
                "snare": [snareEntry]
            ]
        )

        // Complete acoustic kit containing kick, snare, cowbell
        let cowbellEntry = SampleVoiceEntry(url: "samples/test/cowbell.wav", maxVel: 127)
        let acousticKit = SampleKit(
            kitId: "acoustic",
            name: "Acoustic",
            license: "MIT",
            voices: [
                "kick": [kickEntry],
                "snare": [snareEntry],
                "cowbell": [cowbellEntry]
            ]
        )

        let mockKits = [
            "incomplete": incompleteKit,
            "acoustic": acousticKit
        ]

        let (settings, _) = createSettings(selectedKit: "incomplete")

        // Should fall back to acoustic because "cowbell" is missing from "incomplete"
        let resolved = SoundKitResolver.resolve(for: lessonWithCowbell, settings: settings, kits: mockKits)
        XCTAssertEqual(resolved.kitId, "acoustic")

        // When all voices are present, kit is retained
        let lessonWithoutCowbell = makeLesson(id: 2, genre: "Rock", padIndices: [12, 13])
        let resolvedComplete = SoundKitResolver.resolve(for: lessonWithoutCowbell, settings: settings, kits: mockKits)
        XCTAssertEqual(resolvedComplete.kitId, "incomplete")
    }

    // MARK: - Bundled Kits Voice Verification

    func testBundledKitsAllContainRequiredStandardVoices() throws {
        let kits = try DataLoader.shared.loadSampleKits()
        XCTAssertEqual(kits.count, 8)

        let expectedKits = ["acoustic", "808", "jazz", "world", "rock", "brush", "worldperc", "house"]
        for expectedId in expectedKits {
            guard let kit = kits[expectedId] else {
                XCTFail("Missing bundled kit: \(expectedId)")
                continue
            }
            // Verify all 13 standard voices are present
            let requiredVoices = [
                "kick", "snare", "clap", "hat", "openHat", "rim",
                "tomHi", "tomLo", "shaker", "wood", "cowbell", "crash", "ride"
            ]
            for voice in requiredVoices {
                XCTAssertNotNil(kit.voices[voice], "Kit '\(expectedId)' must contain voice '\(voice)'")
                XCTAssertFalse(kit.voices[voice]?.isEmpty ?? true, "Kit '\(expectedId)' voice '\(voice)' must not be empty")
            }
        }
    }

    // MARK: - Migration Tests

    func testMigrationUntouchedUserGetsAuto() {
        let suiteName = "SoundKitResolverTests.untouched.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        // Ensure no kit is set
        defaults.removeObject(forKey: SettingsKey.selectedKitId.rawValue)

        let settings = SettingsManager(userDefaults: defaults)
        XCTAssertEqual(settings.selectedKitId, "auto")
    }

    func testMigrationExplicitlyChosenKitRetained() {
        let suiteName = "SoundKitResolverTests.explicit.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set("808", forKey: SettingsKey.selectedKitId.rawValue)

        let settings = SettingsManager(userDefaults: defaults)
        XCTAssertEqual(settings.selectedKitId, "808")

        // Also test a user who explicitly selected "rock"
        let defaultsRock = UserDefaults(suiteName: "SoundKitResolverTests.explicitRock.\(UUID().uuidString)")!
        defaultsRock.set("rock", forKey: SettingsKey.selectedKitId.rawValue)
        let settingsRock = SettingsManager(userDefaults: defaultsRock)
        XCTAssertEqual(settingsRock.selectedKitId, "rock")
    }

    // MARK: - Per-lesson Override Persistence

    func testPerLessonOverrideSurvivesRestartAndCanBeCleared() {
        let suiteName = "SoundKitResolverTests.overridePersist.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let settings = SettingsManager(userDefaults: defaults)

        XCTAssertNil(settings.kitOverride(for: 10))

        // Set override
        settings.setKitOverride("808", for: 10)
        XCTAssertEqual(settings.kitOverride(for: 10), "808")

        // Re-read from new SettingsManager instance with same UserDefaults (simulating app restart)
        let reloadedSettings = SettingsManager(userDefaults: defaults)
        XCTAssertEqual(reloadedSettings.kitOverride(for: 10), "808")

        // Clear override with "auto"
        reloadedSettings.setKitOverride("auto", for: 10)
        XCTAssertNil(reloadedSettings.kitOverride(for: 10))

        // Re-read after clearing
        let afterClearSettings = SettingsManager(userDefaults: defaults)
        XCTAssertNil(afterClearSettings.kitOverride(for: 10))

        // Setting nil also clears
        afterClearSettings.setKitOverride("rock", for: 10)
        XCTAssertEqual(afterClearSettings.kitOverride(for: 10), "rock")
        afterClearSettings.setKitOverride(nil, for: 10)
        XCTAssertNil(afterClearSettings.kitOverride(for: 10))
    }
}
