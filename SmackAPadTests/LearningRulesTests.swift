import XCTest
@testable import SmackAPad

final class LearningRulesTests: XCTestCase {
    func testMainLearningConstants() {
        XCTAssertEqual(LearningRules.passMark, 0.8)
        XCTAssertEqual(LearningRules.minimumHitsPerStar, 16)
        XCTAssertEqual(LearningRules.maximumRunsPerStar, 4)
        XCTAssertEqual(LearningRules.warmUpPassesNeeded, 2)
    }

    private func visibility(
        _ warmUp: LearningRules.MemoryWarmUp,
        fadeNotes: Bool = true
    ) -> NoteVisibility {
        NoteVisibility.derive(
            fromMemory: true,
            running: true,
            listen: false,
            isSectionLoop: false,
            warmUp: warmUp,
            fadeNotes: fadeNotes
        )
    }

    // (a) Two good warm-ups -> hidden from pass 3.
    func testTwoGoodWarmUpsHideNotesFromPass3() {
        var warmUp = LearningRules.MemoryWarmUp()
        let schedule = ReviewScheduler.ScheduleState(reviewStep: 1, reviewDueDay: "2026-11-07")

        // Pass 1: notes shown, warm-up does not count for review.
        XCTAssertEqual(warmUp.consecutivePasses, 0)
        XCTAssertFalse(warmUp.areNotesHidden(fadeNotes: true))
        XCTAssertEqual(visibility(warmUp), .shown)
        XCTAssertNil(ReviewScheduler.evaluate(
            schedule: schedule, today: "2026-11-07", isFullRun: true,
            fromMemory: true, bpm: 100, targetBpm: 100, score: 0.8,
            notesHidden: warmUp.areNotesHidden(fadeNotes: true)
        ).feedback)
        warmUp.recordPass(score: 0.8)

        // Pass 2: one good warm-up done (notes fade, still not hidden).
        XCTAssertEqual(warmUp.consecutivePasses, 1)
        XCTAssertFalse(warmUp.areNotesHidden(fadeNotes: true))
        XCTAssertEqual(visibility(warmUp), .faded)
        XCTAssertNil(ReviewScheduler.evaluate(
            schedule: schedule, today: "2026-11-07", isFullRun: true,
            fromMemory: true, bpm: 100, targetBpm: 100, score: 0.9,
            notesHidden: warmUp.areNotesHidden(fadeNotes: true)
        ).feedback)
        warmUp.recordPass(score: 0.9)

        // Pass 3: hidden after two consecutive passes >= 80 %, review counts.
        XCTAssertEqual(warmUp.consecutivePasses, 2)
        XCTAssertTrue(warmUp.areNotesHidden(fadeNotes: true))
        XCTAssertEqual(visibility(warmUp), .hidden)
        XCTAssertNotNil(ReviewScheduler.evaluate(
            schedule: schedule, today: "2026-11-07", isFullRun: true,
            fromMemory: true, bpm: 100, targetBpm: 100, score: 0.85,
            notesHidden: warmUp.areNotesHidden(fadeNotes: true)
        ).feedback)

        // A later weak hidden pass keeps notes hidden.
        warmUp.recordPass(score: 0.4)
        XCTAssertEqual(warmUp.consecutivePasses, 2)
        XCTAssertTrue(warmUp.areNotesHidden(fadeNotes: true))
        XCTAssertEqual(visibility(warmUp), .hidden)
    }

    // (b) Good, weak, good, good -> hidden from pass 5.
    func testWeakWarmUpResetsStreakUntilTwoConsecutiveGoodPasses() {
        var warmUp = LearningRules.MemoryWarmUp()

        // Pass 1 (good) -> 1 done, pass 2 shows faded notes.
        warmUp.recordPass(score: 0.85)
        XCTAssertEqual(warmUp.consecutivePasses, 1)
        XCTAssertFalse(warmUp.areNotesHidden(fadeNotes: true))
        XCTAssertEqual(visibility(warmUp), .faded)

        // Pass 2 (weak) -> streak resets to 0, pass 3 goes back to full notes.
        warmUp.recordPass(score: 0.79)
        XCTAssertEqual(warmUp.consecutivePasses, 0)
        XCTAssertFalse(warmUp.areNotesHidden(fadeNotes: true))
        XCTAssertEqual(visibility(warmUp), .shown)

        // Pass 3 (good) -> 1 done, pass 4 fades again.
        warmUp.recordPass(score: 0.8)
        XCTAssertEqual(warmUp.consecutivePasses, 1)
        XCTAssertFalse(warmUp.areNotesHidden(fadeNotes: true))
        XCTAssertEqual(visibility(warmUp), .faded)

        // Pass 4 (good) -> 2 in a row, pass 5 hides notes.
        warmUp.recordPass(score: 1.0)
        XCTAssertEqual(warmUp.consecutivePasses, 2)
        XCTAssertTrue(warmUp.areNotesHidden(fadeNotes: true))
        XCTAssertEqual(visibility(warmUp), .hidden)
    }

    // (c) Fade setting off -> hidden from pass 1.
    func testFadeSettingOffHidesNotesFromPass1() {
        var warmUp = LearningRules.MemoryWarmUp()
        let schedule = ReviewScheduler.ScheduleState(reviewStep: 1, reviewDueDay: "2026-11-07")

        XCTAssertEqual(warmUp.consecutivePasses, 0)
        XCTAssertTrue(warmUp.areNotesHidden(fadeNotes: false))
        XCTAssertEqual(visibility(warmUp, fadeNotes: false), .hidden)
        XCTAssertNotNil(ReviewScheduler.evaluate(
            schedule: schedule, today: "2026-11-07", isFullRun: true,
            fromMemory: true, bpm: 100, targetBpm: 100, score: 0.9,
            notesHidden: warmUp.areNotesHidden(fadeNotes: false)
        ).feedback)

        warmUp.recordPass(score: 0.4, fadeNotes: false)
        XCTAssertTrue(warmUp.areNotesHidden(fadeNotes: false))
        XCTAssertEqual(visibility(warmUp, fadeNotes: false), .hidden)
    }
}
