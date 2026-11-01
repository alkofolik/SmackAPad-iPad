import XCTest
@testable import SmackAPad

final class StarRequirementTests: XCTestCase {
    func testNoStarRequirementWithSingleAndMultipleRuns() {
        let nilProgress: LessonProgress? = nil
        let emptyProgress = LessonProgress(passed: false, mastery: false, memory: false)

        for progress in [nilProgress, emptyProgress] {
            XCTAssertEqual(StarRequirement.nextMissingStarIndex(progress: progress), 0)

            // Single run
            XCTAssertEqual(StarRequirement.requirementText(for: 0, requiredRuns: 1, targetBpm: 85, language: .english),
                           "Pass the lesson")
            XCTAssertEqual(StarRequirement.requirementText(for: 0, requiredRuns: 1, targetBpm: 85, language: .czech),
                           "Splň lekci")
            XCTAssertEqual(StarRequirement.nextMissingStarText(progress: progress, requiredRuns: 1, targetBpm: 85, language: .english),
                           "Next: pass the lesson")
            XCTAssertEqual(StarRequirement.nextMissingStarText(progress: progress, requiredRuns: 1, targetBpm: 85, language: .czech),
                           "Další: splň lekci")

            // Multiple runs
            XCTAssertEqual(StarRequirement.requirementText(for: 0, requiredRuns: 4, targetBpm: 85, language: .english),
                           "Pass the lesson, 4 times in a row")
            XCTAssertEqual(StarRequirement.requirementText(for: 0, requiredRuns: 4, targetBpm: 85, language: .czech),
                           "Splň lekci, 4krát za sebou")
            XCTAssertEqual(StarRequirement.nextMissingStarText(progress: progress, requiredRuns: 4, targetBpm: 85, language: .english),
                           "Next: pass the lesson, 4 times in a row")
            XCTAssertEqual(StarRequirement.nextMissingStarText(progress: progress, requiredRuns: 4, targetBpm: 85, language: .czech),
                           "Další: splň lekci, 4krát za sebou")
        }
    }

    func testOneStarRequirementWithSingleAndMultipleRuns() {
        let progress = LessonProgress(passed: true, mastery: false, memory: false)
        XCTAssertEqual(StarRequirement.nextMissingStarIndex(progress: progress), 1)

        // Single run with target BPM
        XCTAssertEqual(StarRequirement.requirementText(for: 1, requiredRuns: 1, targetBpm: 85, language: .english),
                       "Reach 85 BPM cleanly")
        XCTAssertEqual(StarRequirement.requirementText(for: 1, requiredRuns: 1, targetBpm: 85, language: .czech),
                       "Dosáhni čistě 85 BPM")
        XCTAssertEqual(StarRequirement.nextMissingStarText(progress: progress, requiredRuns: 1, targetBpm: 85, language: .english),
                       "Next: reach 85 BPM cleanly")
        XCTAssertEqual(StarRequirement.nextMissingStarText(progress: progress, requiredRuns: 1, targetBpm: 85, language: .czech),
                       "Další: dosáhni čistě 85 BPM")

        // Multiple runs with target BPM
        XCTAssertEqual(StarRequirement.requirementText(for: 1, requiredRuns: 3, targetBpm: 85, language: .english),
                       "Reach 85 BPM cleanly, 3 times in a row")
        XCTAssertEqual(StarRequirement.requirementText(for: 1, requiredRuns: 3, targetBpm: 85, language: .czech),
                       "Dosáhni čistě 85 BPM, 3krát za sebou")
        XCTAssertEqual(StarRequirement.nextMissingStarText(progress: progress, requiredRuns: 3, targetBpm: 85, language: .english),
                       "Next: reach 85 BPM cleanly, 3 times in a row")
        XCTAssertEqual(StarRequirement.nextMissingStarText(progress: progress, requiredRuns: 3, targetBpm: 85, language: .czech),
                       "Další: dosáhni čistě 85 BPM, 3krát za sebou")

        // Without target BPM
        XCTAssertEqual(StarRequirement.requirementText(for: 1, requiredRuns: 1, targetBpm: nil, language: .english),
                       "Reach the goal tempo cleanly")
        XCTAssertEqual(StarRequirement.requirementText(for: 1, requiredRuns: 1, targetBpm: nil, language: .czech),
                       "Dosáhni čistě cílového tempa")
        XCTAssertEqual(StarRequirement.requirementText(for: 1, requiredRuns: 2, targetBpm: nil, language: .english),
                       "Reach the goal tempo cleanly, 2 times in a row")
        XCTAssertEqual(StarRequirement.requirementText(for: 1, requiredRuns: 2, targetBpm: nil, language: .czech),
                       "Dosáhni čistě cílového tempa, 2krát za sebou")
    }

    func testTwoStarsRequirementWithSingleAndMultipleRuns() {
        let progress = LessonProgress(passed: true, mastery: true, memory: false)
        XCTAssertEqual(StarRequirement.nextMissingStarIndex(progress: progress), 2)

        // Single run with target BPM
        XCTAssertEqual(StarRequirement.requirementText(for: 2, requiredRuns: 1, targetBpm: 85, language: .english),
                       "Play it from memory at 85 BPM, 80 % or better")
        XCTAssertEqual(StarRequirement.requirementText(for: 2, requiredRuns: 1, targetBpm: 85, language: .czech),
                       "Zahraj zpaměti v 85 BPM na 80 % a lépe")
        XCTAssertEqual(StarRequirement.nextMissingStarText(progress: progress, requiredRuns: 1, targetBpm: 85, language: .english),
                       "Next: play it from memory at 85 BPM, 80 % or better")
        XCTAssertEqual(StarRequirement.nextMissingStarText(progress: progress, requiredRuns: 1, targetBpm: 85, language: .czech),
                       "Další: zahraj zpaměti v 85 BPM na 80 % a lépe")

        // Multiple runs with target BPM
        XCTAssertEqual(StarRequirement.requirementText(for: 2, requiredRuns: 4, targetBpm: 85, language: .english),
                       "Play it from memory at 85 BPM, 80 % or better, 4 times in a row")
        XCTAssertEqual(StarRequirement.requirementText(for: 2, requiredRuns: 4, targetBpm: 85, language: .czech),
                       "Zahraj zpaměti v 85 BPM na 80 % a lépe, 4krát za sebou")
        XCTAssertEqual(StarRequirement.nextMissingStarText(progress: progress, requiredRuns: 4, targetBpm: 85, language: .english),
                       "Next: play it from memory at 85 BPM, 80 % or better, 4 times in a row")
        XCTAssertEqual(StarRequirement.nextMissingStarText(progress: progress, requiredRuns: 4, targetBpm: 85, language: .czech),
                       "Další: zahraj zpaměti v 85 BPM na 80 % a lépe, 4krát za sebou")

        // Without target BPM
        XCTAssertEqual(StarRequirement.requirementText(for: 2, requiredRuns: 1, targetBpm: nil, language: .english),
                       "Play it from memory at goal tempo, 80 % or better")
        XCTAssertEqual(StarRequirement.requirementText(for: 2, requiredRuns: 1, targetBpm: nil, language: .czech),
                       "Zahraj zpaměti v cílovém tempu na 80 % a lépe")
        XCTAssertEqual(StarRequirement.requirementText(for: 2, requiredRuns: 4, targetBpm: nil, language: .english),
                       "Play it from memory at goal tempo, 80 % or better, 4 times in a row")
        XCTAssertEqual(StarRequirement.requirementText(for: 2, requiredRuns: 4, targetBpm: nil, language: .czech),
                       "Zahraj zpaměti v cílovém tempu na 80 % a lépe, 4krát za sebou")
    }

    func testThreeStarsEarnedReturnsNilForNextMissingStar() {
        let progress = LessonProgress(passed: true, mastery: true, memory: true)
        XCTAssertNil(StarRequirement.nextMissingStarIndex(progress: progress))
        XCTAssertNil(StarRequirement.nextMissingStarText(progress: progress, requiredRuns: 1, targetBpm: 85, language: .english))
        XCTAssertNil(StarRequirement.nextMissingStarText(progress: progress, requiredRuns: 1, targetBpm: 85, language: .czech))
        XCTAssertNil(StarRequirement.nextMissingStarText(progress: progress, requiredRuns: 4, targetBpm: 85, language: .english))
        XCTAssertNil(StarRequirement.nextMissingStarText(progress: progress, requiredRuns: 4, targetBpm: 85, language: .czech))
    }
}
