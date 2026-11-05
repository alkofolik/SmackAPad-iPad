import XCTest
@testable import SmackAPad

final class TrainingMixSelectionTests: XCTestCase {
    private func lesson(_ id: Int, level: Int = 2, category: String = "eighth", eight: Bool = true) -> Lesson {
        Lesson(id: id, cat: category, title: "Lesson \(id)", genre: "Rock", tags: [], text: "",
               division: 16, bars: 1, startBpm: 60, targetBpm: 120, level: level, src: "Test",
               hits: [LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 100)],
               hits8: eight ? [LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 100)] : nil)
    }

    func testSelectionUsesLearnedPlayableOpenLessonsAcrossNearbyLevelsAndCategories() {
        let lessons = [lesson(1), lesson(2, category: "ghost"), lesson(3, level: 3, category: "swing"),
                       lesson(4, level: 5), lesson(5, eight: false), lesson(6), lesson(7)]
        let records = Dictionary(uniqueKeysWithValues: (1...6).map { ($0, LessonProgress(passed: true, mastery: true)) })
        let mix = TrainingMix.select(lessons: lessons, progress: records, padCount: 8,
                                     openLessonIDs: [1, 2, 3, 4, 5, 7], day: "2026-11-05")
        XCTAssertEqual(Set(mix.map(\.id)), [1, 2, 3])
        XCTAssertEqual(Set(mix.map(\.cat)).count, 3)
        XCTAssertEqual(Set(mix.map(\.id)).count, mix.count)
        XCTAssertLessThanOrEqual((mix.map(\.level).max() ?? 0) - (mix.map(\.level).min() ?? 0), 1)
    }
    func testSameDayAndInputsGiveTheSameSetRegardlessOfInputOrder() {
        let lessons = (1...8).map { lesson($0, category: "category-\($0 % 3)") }
        let records = Dictionary(uniqueKeysWithValues: lessons.map { ($0.id, LessonProgress(mastery: true)) })
        let first = TrainingMix.select(lessons: lessons, progress: records, padCount: 16,
            openLessonIDs: Set(1...8), day: "2026-11-05")
        let reopened = TrainingMix.select(lessons: lessons.reversed(), progress: records, padCount: 16,
            openLessonIDs: Set(1...8), day: "2026-11-05")
        XCTAssertEqual(first.map(\.id), reopened.map(\.id))
        let alternatives = (1...8).map { draw in
            TrainingMix.select(lessons: lessons, progress: records, padCount: 16,
                openLessonIDs: Set(1...8), day: "2026-11-05", draw: UInt64(draw)).map(\.id)
        }
        XCTAssertTrue(alternatives.contains { Set($0) != Set(first.map(\.id)) })
    }

    func testTwoLessonsFallbackInsufficientCandidatesAndRecencyPreference() {
        let lessons = [lesson(1), lesson(2), lesson(3), lesson(4)]
        var records = Dictionary(uniqueKeysWithValues: lessons.map {
            ($0.id, LessonProgress(mastery: true, lastPlayedDay: "2026-11-04"))
        })
        records[3]?.lastPlayedDay = "2026-10-01"
        let mix = TrainingMix.select(lessons: lessons, progress: records, padCount: 16,
            openLessonIDs: [1, 2, 3, 4], day: "2026-11-05")
        XCTAssertEqual(mix.first?.id, 3)
        XCTAssertEqual(TrainingMix.select(lessons: lessons, progress: records, padCount: 16,
            openLessonIDs: [1, 2], day: "2026-11-05").count, 2)
        XCTAssertTrue(TrainingMix.select(lessons: lessons, progress: records, padCount: 16,
            openLessonIDs: [1], day: "2026-11-05").isEmpty)
        XCTAssertTrue(TrainingMix.select(lessons: [lesson(1, level: 1), lesson(2, level: 5)],
            progress: records, padCount: 16, openLessonIDs: [1, 2], day: "2026-11-05").isEmpty)
    }

}
