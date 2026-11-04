import XCTest
@testable import SmackAPad

final class BadgeEvaluatorTests: XCTestCase {
    private func makeLesson(
        _ id: Int,
        cat: String = "eighth",
        genre: String = "Rock",
        tags: [String] = [],
        division: Int = 16,
        level: Int = 1
    ) -> Lesson {
        Lesson(
            id: id,
            cat: cat,
            title: "Lesson \(id)",
            genre: genre,
            tags: tags,
            text: "",
            division: division,
            bars: 1,
            startBpm: 60,
            targetBpm: 100,
            level: level,
            src: "Test",
            hits: []
        )
    }

    func testFirstGrooveAwardedWhenFirstLessonPassed() {
        let lessons = [makeLesson(101)]
        let catalog = LibraryCatalog(lessons: lessons)
        let firstGroove = BadgeDefinition(
            id: "first-groove",
            name: "First groove",
            condition: "Pass your first lesson.",
            metric: "passed",
            goal: .count(1),
            tier: 1,
            group: .passed
        )

        let progress: [Int: LessonProgress] = [
            101: LessonProgress(passed: true)
        ]

        let result = BadgeEvaluator.evaluate(
            progress: progress,
            catalog: catalog,
            definitions: [firstGroove],
            currentlyEarned: []
        )

        XCTAssertEqual(result.stats.passed, 1)
        XCTAssertEqual(result.newlyEarnedBadgeIds, ["first-groove"])
    }

    func testMasteryAndMemoryBadgesAwarded() {
        let lessons = [makeLesson(101), makeLesson(102)]
        let catalog = LibraryCatalog(lessons: lessons)
        let goalTempoBadge = BadgeDefinition(
            id: "goal-tempo",
            name: "Goal tempo",
            condition: "Master your first lesson at goal tempo.",
            metric: "mastered",
            goal: .count(1),
            tier: 1,
            group: .mastered
        )
        let byHeartBadge = BadgeDefinition(
            id: "by-heart",
            name: "By heart",
            condition: "Earn your first memory star.",
            metric: "memory",
            goal: .count(1),
            tier: 1,
            group: .memory
        )

        let progress: [Int: LessonProgress] = [
            101: LessonProgress(passed: true, mastery: true),
            102: LessonProgress(passed: true, memory: true)
        ]

        let result = BadgeEvaluator.evaluate(
            progress: progress,
            catalog: catalog,
            definitions: [goalTempoBadge, byHeartBadge],
            currentlyEarned: []
        )

        XCTAssertEqual(result.stats.passed, 2)
        XCTAssertEqual(result.stats.mastered, 1)
        XCTAssertEqual(result.stats.memory, 1)
        XCTAssertEqual(Set(result.newlyEarnedBadgeIds), Set(["goal-tempo", "by-heart"]))
    }

    func testPathStageCompletionRequiresAllLessonsMastered() {
        // Stage L1-groove contains lessons with level 1 and classified as groove
        let l1 = makeLesson(1, level: 1)
        let l2 = makeLesson(2, level: 1)
        let catalog = LibraryCatalog(lessons: [l1, l2])

        let courseDoneBadge = BadgeDefinition(
            id: "course-done",
            name: "Stage complete",
            condition: "Master every lesson in one Path stage.",
            metric: "courses",
            goal: .count(1),
            tier: 1,
            group: .courses
        )

        // Only 1 of 2 lessons mastered: course not complete
        let partialProgress: [Int: LessonProgress] = [
            1: LessonProgress(passed: true, mastery: true),
            2: LessonProgress(passed: true, mastery: false)
        ]
        let partialResult = BadgeEvaluator.evaluate(
            progress: partialProgress,
            catalog: catalog,
            definitions: [courseDoneBadge],
            currentlyEarned: []
        )
        XCTAssertEqual(partialResult.stats.courses, 0)
        XCTAssertTrue(partialResult.newlyEarnedBadgeIds.isEmpty)

        // Both lessons mastered: course complete!
        let fullProgress: [Int: LessonProgress] = [
            1: LessonProgress(passed: true, mastery: true),
            2: LessonProgress(passed: true, mastery: true)
        ]
        let fullResult = BadgeEvaluator.evaluate(
            progress: fullProgress,
            catalog: catalog,
            definitions: [courseDoneBadge],
            currentlyEarned: []
        )
        XCTAssertEqual(fullResult.stats.courses, 1)
        XCTAssertEqual(fullResult.newlyEarnedBadgeIds, ["course-done"])
    }

    func testLevelAndGenreAndTechniqueBadges() {
        let l1 = makeLesson(1, cat: "eighth", genre: "Rock", tags: [], level: 1)
        let l2 = makeLesson(2, cat: "eighth", genre: "Rock", tags: [], level: 1)
        let l3 = makeLesson(3, cat: "fills", genre: "Jazz", tags: ["toms"], level: 2)
        let catalog = LibraryCatalog(lessons: [l1, l2, l3])

        let level1Badge = BadgeDefinition(
            id: "level-1-done",
            name: "Level 1 done",
            condition: "Pass every level 1 lesson in this edition.",
            metric: "level-1",
            goal: .group,
            tier: 2,
            group: .levels
        )
        let rockBadge = BadgeDefinition(
            id: "genre-rock",
            name: "Rock and punk done",
            condition: "Pass every lesson in the Rock and punk group.",
            metric: "genre-rock",
            goal: .group,
            tier: 2,
            group: .genres
        )
        let grooveBadge = BadgeDefinition(
            id: "tech-basic",
            name: "Basic groove done",
            condition: "Pass every lesson in the Basic groove technique.",
            metric: "tech-groove",
            goal: .group,
            tier: 2,
            group: .techniques
        )

        // When only l1 is passed, level 1 and rock are not done yet
        let partialProgress: [Int: LessonProgress] = [
            1: LessonProgress(passed: true)
        ]
        let partialResult = BadgeEvaluator.evaluate(
            progress: partialProgress,
            catalog: catalog,
            definitions: [level1Badge, rockBadge, grooveBadge],
            currentlyEarned: []
        )
        XCTAssertTrue(partialResult.newlyEarnedBadgeIds.isEmpty)

        // When both l1 and l2 are passed, all level 1, all rock, and all groove are passed!
        let fullProgress: [Int: LessonProgress] = [
            1: LessonProgress(passed: true),
            2: LessonProgress(passed: true)
        ]
        let fullResult = BadgeEvaluator.evaluate(
            progress: fullProgress,
            catalog: catalog,
            definitions: [level1Badge, rockBadge, grooveBadge],
            currentlyEarned: []
        )
        XCTAssertEqual(Set(fullResult.newlyEarnedBadgeIds), Set(["level-1-done", "genre-rock", "tech-basic"]))
    }

    func testAlreadyEarnedBadgesAreNotReawarded() {
        let lessons = [makeLesson(101)]
        let catalog = LibraryCatalog(lessons: lessons)
        let firstGroove = BadgeDefinition(
            id: "first-groove",
            name: "First groove",
            condition: "Pass your first lesson.",
            metric: "passed",
            goal: .count(1),
            tier: 1,
            group: .passed
        )

        let progress: [Int: LessonProgress] = [
            101: LessonProgress(passed: true)
        ]

        let result = BadgeEvaluator.evaluate(
            progress: progress,
            catalog: catalog,
            definitions: [firstGroove],
            currentlyEarned: ["first-groove"]
        )

        XCTAssertEqual(result.stats.passed, 1)
        XCTAssertTrue(result.newlyEarnedBadgeIds.isEmpty)
    }

    func testCatalogueGoalBadgeAwardedWhenAllLessonsPassed() {
        let lessons = [makeLesson(1), makeLesson(2)]
        let catalog = LibraryCatalog(lessons: lessons)
        let everyLessonBadge = BadgeDefinition(
            id: "every-lesson",
            name: "Every lesson",
            condition: "Pass every lesson in this edition.",
            metric: "passed",
            goal: .catalogue,
            tier: 3,
            group: .passed
        )

        let partialResult = BadgeEvaluator.evaluate(
            progress: [1: LessonProgress(passed: true)],
            catalog: catalog,
            definitions: [everyLessonBadge],
            currentlyEarned: []
        )
        XCTAssertTrue(partialResult.newlyEarnedBadgeIds.isEmpty)

        let fullResult = BadgeEvaluator.evaluate(
            progress: [
                1: LessonProgress(passed: true),
                2: LessonProgress(passed: true)
            ],
            catalog: catalog,
            definitions: [everyLessonBadge],
            currentlyEarned: []
        )
        XCTAssertEqual(fullResult.newlyEarnedBadgeIds, ["every-lesson"])
    }
}
