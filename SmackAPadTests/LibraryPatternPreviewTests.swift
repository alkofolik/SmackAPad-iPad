import XCTest
@testable import SmackAPad

final class LibraryPatternPreviewTests: XCTestCase {
    func testStepDurationAndBarWrappingAtTargetBpm() {
        let timing = PreviewLoopTiming(bpm: 120, bars: 2)
        XCTAssertEqual(timing.secondsPerStep, 0.125, accuracy: 0.0001)
        XCTAssertEqual(timing.totalSteps, 32)
        XCTAssertEqual(timing.loopDurationSeconds, 4.0, accuracy: 0.0001)

        XCTAssertNil(timing.barStepProgress(elapsedSeconds: -0.01))
        XCTAssertEqual(try XCTUnwrap(timing.barStepProgress(elapsedSeconds: 0.0)), 0.0, accuracy: 0.0001)
        // Step 18 in bar 2 wraps cleanly to step 2 on the 16-step mini strip.
        XCTAssertEqual(try XCTUnwrap(timing.barStepProgress(elapsedSeconds: 2.25)), 2.0, accuracy: 0.0001)
    }

    func testCollectHitsLoopsAcrossHorizons() {
        let timing = PreviewLoopTiming(bpm: 120, bars: 1) // 0.125s/step, 2.0s/bar
        let hits = [
            LessonHit(step: 0, padIndex: 12, hand: "R", velocity: 100),
            LessonHit(step: 8, padIndex: 13, hand: "L", velocity: 90)
        ]
        var nextLoop = 0
        var nextHitIndex = 0

        let firstBatch = PreviewLoopTiming.collectHits(
            sortedHits: hits,
            timing: timing,
            anchorSeconds: 10.0,
            horizonSeconds: 11.5,
            nextLoop: &nextLoop,
            nextHitIndex: &nextHitIndex
        )
        XCTAssertEqual(firstBatch.count, 2)
        XCTAssertEqual(firstBatch[0].timeSeconds, 10.0, accuracy: 0.0001)
        XCTAssertEqual(firstBatch[1].timeSeconds, 11.0, accuracy: 0.0001)

        // Advance horizon into the second loop.
        let secondBatch = PreviewLoopTiming.collectHits(
            sortedHits: hits,
            timing: timing,
            anchorSeconds: 10.0,
            horizonSeconds: 12.2,
            nextLoop: &nextLoop,
            nextHitIndex: &nextHitIndex
        )
        XCTAssertEqual(secondBatch.count, 1)
        XCTAssertEqual(secondBatch[0].timeSeconds, 12.0, accuracy: 0.0001)
        XCTAssertEqual(secondBatch[0].padIndex, 12)
    }
}
