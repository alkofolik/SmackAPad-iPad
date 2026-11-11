//
//  SmackAPadTests.swift
//  SmackAPadTests
//
//  Validation tests for ported legacy data files (JSON, WAVs, licenses).
//

import XCTest
@testable import SmackAPad

final class SmackAPadDataPortTests: XCTestCase {

    // MARK: - 1. Core & Intro Lessons

    func testBundledCoreAndIntroLessonsLoad() throws {
        let loader = DataLoader.shared

        // 539 core lessons after removing Intro duplicates
        let corePayload = try loader.loadCoreLessons()
        XCTAssertEqual(corePayload.lessons.count, 539, "Expected 539 core lessons")
        XCTAssertEqual(corePayload.cats.count, 8, "Expected 8 core categories")

        let expectedCategoryIds = ["starter", "eighth", "sixteenth", "electronic", "ghost", "swing", "world", "fills"]
        XCTAssertEqual(corePayload.cats.map(\.id), expectedCategoryIds)

        // Verify first and last lesson IDs
        XCTAssertEqual(corePayload.lessons.first?.id, 6)
        XCTAssertEqual(corePayload.lessons.last?.id, 547)

        // 24 intro lessons
        let introLessons = try loader.loadIntroLessons()
        XCTAssertEqual(introLessons.count, 24, "Expected 24 intro exercises")
        XCTAssertTrue(introLessons.allSatisfy { $0.cat == "intro" })
    }

    // MARK: - 2. Electronic Path & Genre Extensions

    func testElectronicPathAndGenreExtensionsLoad() throws {
        let loader = DataLoader.shared

        let electronicLessons = try loader.loadElectronicPathLessons()
        XCTAssertEqual(electronicLessons.count, 12, "Expected 12 electronic path lessons")
        let electronicCats = Set(electronicLessons.map(\.cat))
        XCTAssertEqual(electronicCats, ["uk-club", "broken-techno", "hardgroove"])

        let genreExtensionLessons = try loader.loadGenreExtensionLessons()
        XCTAssertEqual(genreExtensionLessons.count, 12, "Expected 12 genre extension lessons")
        let extensionCats = Set(genreExtensionLessons.map(\.cat))
        XCTAssertEqual(extensionCats, ["jersey", "footwork"])
    }

    // MARK: - 3. Error Handling

    func testInvalidOrMissingJSONProducesClearError() {
        let loader = DataLoader.shared

        let missingURL = URL(fileURLWithPath: "/tmp/non-existent-smackapad-file.json")
        XCTAssertThrowsError(try loader.loadJSON(from: missingURL) as [Lesson]) { error in
            guard case DataLoaderError.fileNotFound(let path) = error else {
                XCTFail("Expected .fileNotFound error, got: \(error)")
                return
            }
            XCTAssertEqual(path, missingURL.path)
        }

        let tempInvalidURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("invalid-\(UUID().uuidString).json")
        try? "{\"notValid\": true}".data(using: .utf8)?.write(to: tempInvalidURL)
        defer { try? FileManager.default.removeItem(at: tempInvalidURL) }

        XCTAssertThrowsError(try loader.loadJSON(from: tempInvalidURL) as [Lesson]) { error in
            guard case DataLoaderError.decodingFailed(let path, _) = error else {
                XCTFail("Expected .decodingFailed error, got: \(error)")
                return
            }
            XCTAssertEqual(path, tempInvalidURL.path)
        }
    }

    // MARK: - 4. hits8 Lessons

    func testLessonsWithHits8Preserved() throws {
        let loader = DataLoader.shared
        let corePayload = try loader.loadCoreLessons()

        let hits8Lessons = corePayload.lessons.filter { $0.hits8 != nil }
        XCTAssertEqual(hits8Lessons.count, 6, "Expected exactly 6 lessons with hits8")

        let hits8Ids = Set(hits8Lessons.map(\.id))
        let expectedHits8Ids: Set<Int> = [480, 502, 520, 524, 532, 541]
        XCTAssertEqual(hits8Ids, expectedHits8Ids, "Expected hits8 on lessons 480, 502, 520, 524, 532, 541")

        for lesson in hits8Lessons {
            XCTAssertFalse(lesson.hits8?.isEmpty ?? true, "hits8 should not be empty for lesson \(lesson.id)")
            XCTAssertNotNil(lesson.eightNote, "eightNote explanation should exist for lesson \(lesson.id)")
        }
    }

    // MARK: - 5. Sample Kits & 371 WAV Files

    func testAllSampleKitsAndReferencedWAVFilesExist() throws {
        let loader = DataLoader.shared
        let kits = try loader.loadSampleKits()

        // 8 kits expected
        let expectedKitIds = ["acoustic", "808", "jazz", "world", "rock", "brush", "worldperc", "house"]
        XCTAssertEqual(Set(kits.keys), Set(expectedKitIds))

        var referencedWavURLs = Set<String>()

        for (kitId, kit) in kits {
            XCTAssertFalse(kit.name.isEmpty, "Kit \(kitId) name should not be empty")
            XCTAssertFalse(kit.license.isEmpty, "Kit \(kitId) license should not be empty")
            XCTAssertEqual(kit.voices.count, 13, "Kit \(kitId) should have 13 standard voices")

            for (_, entries) in kit.voices {
                for entry in entries {
                    referencedWavURLs.insert(entry.url)
                    if let variants = entry.variants {
                        for variant in variants {
                            referencedWavURLs.insert(variant)
                        }
                    }
                }
            }
        }

        XCTAssertEqual(referencedWavURLs.count, 371, "Expected exactly 371 unique WAV references across all 8 kits")

        var missingFiles: [String] = []
        for wavPath in referencedWavURLs {
            if loader.resolveSampleURL(for: wavPath) == nil {
                missingFiles.append(wavPath)
            }
        }

        XCTAssertTrue(
            missingFiles.isEmpty,
            "Missing \(missingFiles.count) referenced WAV files: \(missingFiles.prefix(5))"
        )
    }

    // MARK: - 6. Sample Kit Licenses & Credits

    func testSampleKitLicenseFilesExist() throws {
        let loader = DataLoader.shared
        let kitDirs = ["808", "acoustic", "brush", "house", "rock", "virtuosity", "worldperc"]

        for kit in kitDirs {
            let licensePath = "samples/\(kit)/LICENSE.txt"
            let licenseURL = loader.resolveSampleURL(for: licensePath)
            XCTAssertNotNil(licenseURL, "LICENSE.txt missing for kit: \(kit)")
        }
    }

    // MARK: - 8. Extensible Content Architecture

    func testContentSourceArchitecture() throws {
        let bundledSource = BundledLessonContentSource(
            sourceIdentifier: "core-bundled",
            resourceName: "intro"
        )
        let lessons = try bundledSource.loadLessons()
        XCTAssertEqual(lessons.count, 24)

        // External JSON file simulation
        let tempExternalURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("custom-pack-\(UUID().uuidString).json")
        let dummyLesson = Lesson(
            id: 9999,
            cat: "custom",
            title: "Custom pack test",
            genre: "Custom",
            tags: ["test"],
            text: "Testing content pack loader",
            division: 16,
            bars: 1,
            startBpm: 60,
            targetBpm: 90,
            level: 1,
            score: nil,
            src: "Unit test",
            hits: [LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 100)]
        )
        let encoded = try JSONEncoder().encode([dummyLesson])
        try encoded.write(to: tempExternalURL)
        defer { try? FileManager.default.removeItem(at: tempExternalURL) }

        let externalSource = ExternalJSONContentSource(
            sourceIdentifier: "user-pack",
            fileURL: tempExternalURL
        )
        let loadedExternal = try externalSource.loadLessons()
        XCTAssertEqual(loadedExternal.count, 1)
        XCTAssertEqual(loadedExternal.first?.title, "Custom pack test")
    }
}

// MARK: - Ticket 03: Lesson Models & Content-Pack Loader Tests

final class SmackAPadLessonModelsTests: XCTestCase {

    // MARK: 1. Default LessonStore & Bundled Content

    func testLessonStoreLoadsBundledLessonsByDefault() {
        let store = LessonStore()
        XCTAssertEqual(store.lessons.count, 587, "Expected 587 bundled lessons (539 core + 24 intro + 12 electronic + 12 extensions)")
        XCTAssertEqual(store.categories.count, 7, "Expected 7 categories (First steps was removed in ticket 25B)")

        // Fast lookup by ID
        XCTAssertNotNil(store.lesson(for: 6))
        XCTAssertNotNil(store.lesson(for: 547))
        XCTAssertNotNil(store.lesson(for: 10001)) // intro
        XCTAssertNotNil(store.lesson(for: 13001)) // electronic-path
        XCTAssertNotNil(store.lesson(for: 14001)) // genre-extensions

        // Category query
        // The former First steps lesson now lives in Intro.
        XCTAssertTrue(store.lessons(in: "starter").isEmpty)
        XCTAssertEqual(store.lesson(for: 6)?.cat, "intro")
    }

    // MARK: 2. Content Pack Registration & Merging

    func testLessonStoreRegistersAdditionalSources() throws {
        let store = LessonStore()
        let initialCount = store.lessons.count

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("pack-extra-\(UUID().uuidString).json")
        let extraLesson = Lesson(
            id: 99901,
            cat: "extra",
            title: "Extra Pack Lesson",
            genre: "Test",
            tags: ["expansion"],
            text: "Testing store expansion",
            division: 16,
            bars: 1,
            startBpm: 60,
            targetBpm: 90,
            level: 1,
            score: nil,
            src: "Unit test",
            hits: [LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 100)]
        )
        let data = try JSONEncoder().encode([extraLesson])
        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let externalSource = ExternalJSONContentSource(sourceIdentifier: "extra-pack", fileURL: tempURL)
        try store.register(source: externalSource)

        XCTAssertEqual(store.lessons.count, initialCount + 1)
        XCTAssertEqual(store.lesson(for: 99901)?.title, "Extra Pack Lesson")
        XCTAssertEqual(store.lessons(in: "extra").count, 1)

        // Test overriding an existing lesson
        let overrideURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("override-\(UUID().uuidString).json")
        let overriddenLesson = Lesson(
            id: 99901,
            cat: "extra",
            title: "Overridden Extra Lesson",
            genre: "Test",
            tags: ["expansion"],
            text: "Testing store override",
            division: 16,
            bars: 1,
            startBpm: 70,
            targetBpm: 100,
            level: 2,
            score: nil,
            src: "Unit test",
            hits: [LessonHit(step: 0, padIndex: 13, hand: "L", velocity: 100)]
        )
        let overrideData = try JSONEncoder().encode([overriddenLesson])
        try overrideData.write(to: overrideURL)
        defer { try? FileManager.default.removeItem(at: overrideURL) }

        let overrideSource = ExternalJSONContentSource(sourceIdentifier: "override-pack", fileURL: overrideURL)
        try store.register(source: overrideSource)

        // Count should not increase; title should be updated
        XCTAssertEqual(store.lessons.count, initialCount + 1)
        XCTAssertEqual(store.lesson(for: 99901)?.title, "Overridden Extra Lesson")
        XCTAssertEqual(store.lesson(for: 99901)?.level, 2)
    }

    // MARK: 3. EightPadLayout on all 587 bundled lessons

    func testEightPadLayoutReturnsLayoutForAllBundledLessons() {
        let store = LessonStore()
        XCTAssertEqual(store.lessons.count, 587)

        for lesson in store.lessons {
            guard let layout = EightPadLayout.slots(for: lesson) else {
                XCTFail("Lesson \(lesson.id) ('\(lesson.title)') returned nil 8-pad layout")
                return
            }
            XCTAssertEqual(layout.count, 8, "Layout for lesson \(lesson.id) must contain exactly 8 slots")
            // Ensure all pads in hits/hits8 are in the layout
            let requiredPads = lesson.requiredPadIndices(forPadCount: 8)
            let layoutSet = Set(layout)
            XCTAssertTrue(
                requiredPads.isSubset(of: layoutSet),
                "Lesson \(lesson.id) required pads \(requiredPads) not satisfied by layout \(layout)"
            )
        }
    }

    // MARK: 4. hits8 Lessons Behavior

    func testEightPadLayoutHits8Handling() throws {
        let store = LessonStore()
        let hits8LessonIds = [480, 502, 520, 524, 532, 541]

        for id in hits8LessonIds {
            guard let lesson = store.lesson(for: id) else {
                XCTFail("Missing expected hits8 lesson: \(id)")
                continue
            }
            XCTAssertNotNil(lesson.hits8, "Lesson \(id) should have hits8")
            XCTAssertEqual(lesson.requiredPadIndices(forPadCount: 16).count, 9, "Lesson \(id) 16-pad version should use 9 pads")
            XCTAssertEqual(lesson.requiredPadIndices(forPadCount: 8).count, 8, "Lesson \(id) 8-pad version should use 8 pads")

            // In 8-pad mode (using hits8), layout must succeed
            let layoutWithHits8 = EightPadLayout.slots(for: lesson)
            XCTAssertNotNil(layoutWithHits8, "Lesson \(id) must have valid 8-pad layout when hits8 is used")
            XCTAssertEqual(layoutWithHits8?.count, 8)

            // If hits8 was not present, 9 pads would exceed 8-pad capacity and return nil
            let layoutWithoutHits8 = EightPadLayout.slots(forHits: lesson.hits)
            XCTAssertNil(layoutWithoutHits8, "Lesson \(id) must return nil when evaluated with 9-pad hits array")
        }
    }

    // MARK: 5. Exact EightPadLayout Base Slots and Fill Order Logic

    func testEightPadLayoutBaseSlotsAndFillOrder() {
        // Base slots: [9, 10, 2, 3, 12, 13, 11, 7]
        // Fill order: [0, 1, 3, 2, 7, 6, 5, 4]

        // 1. A lesson using only base pads (Kick L: 12, Snare L: 13, Hat R: 11)
        let basicHits = [
            LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 100),
            LessonHit(step: 4, padIndex: 13, hand: "L", velocity: 100),
            LessonHit(step: 8, padIndex: 11, hand: "R", velocity: 100)
        ]
        let basicLayout = EightPadLayout.slots(forHits: basicHits)
        XCTAssertEqual(basicLayout, EightPadLayout.baseSlots, "Unused base slots should remain untouched")

        // 2. A lesson requiring toms 0 and 1 (High tom, Low tom)
        // Non-base required pads: 0, 1. Ascending order: [0, 1].
        // Fill order walks 0, 1, 3, 2, 7, 6, 5, 4.
        // Slot 0 (pad 9) is not in required -> replaced by 0.
        // Slot 1 (pad 10) is not in required -> replaced by 1.
        let tomHits = basicHits + [
            LessonHit(step: 12, padIndex: 0, hand: "R", velocity: 90),
            LessonHit(step: 14, padIndex: 1, hand: "R", velocity: 90)
        ]
        let tomLayout = EightPadLayout.slots(forHits: tomHits)
        XCTAssertEqual(tomLayout, [0, 1, 2, 3, 12, 13, 11, 7])

        // Verify slot and pad lookup helpers
        if let layout = tomLayout {
            XCTAssertEqual(EightPadLayout.padIndex(forSlot: 0, in: layout), 0)
            XCTAssertEqual(EightPadLayout.padIndex(forSlot: 4, in: layout), 12)
            XCTAssertEqual(EightPadLayout.slotIndex(forPad: 12, in: layout), 4)
            XCTAssertEqual(EightPadLayout.slotIndex(forPad: 13, in: layout), 5)
            XCTAssertEqual(EightPadLayout.slotIndex(forPad: 99, in: layout), nil)
        }
    }

    // MARK: 6. Controller Profile Model & Presets

    func testControllerProfileModelAndPresets() throws {
        let p16 = ControllerProfile.standard16
        XCTAssertEqual(p16.padCount, 16)
        XCTAssertTrue(p16.isSixteenPad)
        XCTAssertFalse(p16.isEightPad)
        XCTAssertEqual(p16.target(forMidiNote: 36), 12)
        XCTAssertEqual(p16.midiNote(forTarget: 12), 36)

        let p8 = ControllerProfile.standard8
        XCTAssertEqual(p8.padCount, 8)
        XCTAssertTrue(p8.isEightPad)
        XCTAssertFalse(p8.isSixteenPad)
        XCTAssertEqual(p8.target(forMidiNote: 36), 0)
        XCTAssertEqual(p8.target(forMidiNote: 43), 7)

        // Codable roundtrip
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(p16)
        let decoded = try JSONDecoder().decode(ControllerProfile.self, from: encoded)
        XCTAssertEqual(decoded, p16)
    }

    // MARK: 7. Error Handling on Invalid Sources

    func testLessonStoreThrowsClearErrorOnInvalidExternalSource() {
        let store = LessonStore()
        let nonExistentURL = URL(fileURLWithPath: "/tmp/non-existent-content-pack-\(UUID().uuidString).json")
        let badSource = ExternalJSONContentSource(sourceIdentifier: "broken", fileURL: nonExistentURL)

        XCTAssertThrowsError(try store.register(source: badSource)) { error in
            guard case DataLoaderError.fileNotFound(let path) = error else {
                XCTFail("Expected DataLoaderError.fileNotFound, got: \(error)")
                return
            }
            XCTAssertEqual(path, nonExistentURL.path)
        }
    }
}
