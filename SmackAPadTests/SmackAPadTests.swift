//
//  SmackAPadTests.swift
//  SmackAPadTests
//
//  Validation tests for ported legacy data files (JSON, WAVs, i18n, licenses).
//

import XCTest
@testable import SmackAPad

final class SmackAPadDataPortTests: XCTestCase {

    // MARK: - 1. Core & Intro Lessons

    func testBundledCoreAndIntroLessonsLoad() throws {
        let loader = DataLoader.shared

        // 547 core lessons
        let corePayload = try loader.loadCoreLessons()
        XCTAssertEqual(corePayload.lessons.count, 547, "Expected 547 core lessons")
        XCTAssertEqual(corePayload.cats.count, 8, "Expected 8 core categories")

        let expectedCategoryIds = ["starter", "eighth", "sixteenth", "electronic", "ghost", "swing", "world", "fills"]
        XCTAssertEqual(corePayload.cats.map(\.id), expectedCategoryIds)

        // Verify first and last lesson IDs
        XCTAssertEqual(corePayload.lessons.first?.id, 1)
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

    // MARK: - 7. Localisation cs.tsv

    func testCzechLocalisationTSVLoads() throws {
        let loader = DataLoader.shared
        let tsvContent = try loader.loadLocalizationTSV()

        XCTAssertFalse(tsvContent.isEmpty, "cs.tsv content should not be empty")
        let lines = tsvContent.components(separatedBy: .newlines)
        XCTAssertGreaterThan(lines.count, 100, "cs.tsv should have substantial translation lines")
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
