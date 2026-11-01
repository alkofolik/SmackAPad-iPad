import XCTest
@testable import SmackAPad

final class PlayedHitTests: XCTestCase {
    func testJudgmentTailBoundariesAndPassIdentity() {
        for bars in [1, 2, 3, 4, 8] {
            let total = bars * 16
            let first = LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 100)
            let outside = LessonHit(step: total - 5, padIndex: 12, hand: "L", velocity: 100)
            let edge = LessonHit(step: total - 4, padIndex: 12, hand: "L", velocity: 100)
            let last = LessonHit(step: total - 1, padIndex: 12, hand: "L", velocity: 100)
            let history: [Int: [LessonHit: HitJudgment]] = [1: [first: .off, outside: .off, edge: .good, last: .perfect],
                                                          2: [first: .good], 3: [last: .off]]
            func visible(_ pass: Int, _ position: Double, _ reduced: Bool = false) -> [Int: [LessonHit: HitJudgment]] {
                FeedbackWindow.visibleJudgments(history, pass: pass, position: position,
                    totalSteps: total, bpm: 120, reduceMotion: reduced)
            }
            XCTAssertNil(visible(1, 0)[0], "The first pass has no tail")
            XCTAssertNil(visible(1, 0)[2], "Future passes cannot colour this one")
            for position in [0.0, 3.999, 4.0, 5.0] {
                let notes = visible(2, position)
                XCTAssertEqual(notes[1], [edge: .good, last: .perfect])
                XCTAssertEqual(notes[2], [first: .good], "A repeated note keeps its current-pass judgment")
                XCTAssertNil(notes[3])
            }
            // At 120 BPM, the quarter-second fade spans two sixteenth steps.
            XCTAssertNil(visible(2, 6)[1])
            XCTAssertNotNil(visible(2, 3.999, true)[1])
            XCTAssertNil(visible(2, 4, true)[1])
            XCTAssertTrue(FeedbackWindow.visibleJudgments([:], pass: 1, position: 0,
                totalSteps: total, bpm: 120, reduceMotion: false).isEmpty, "Restart clears history")
        }
        XCTAssertEqual(FeedbackWindow.strength(recordedPass: 1, step: 15, pass: 2,
            position: 5, totalSteps: 16, bpm: 120, reduceMotion: false), 0.5, accuracy: 0.0001)
        XCTAssertEqual(FeedbackWindow.strength(recordedPass: 1, step: 15, pass: 2,
            position: 4.5, totalSteps: 16, bpm: 60, reduceMotion: false), 0.5, accuracy: 0.0001)
    }

    func testPlayedHitsShareTheTailWithoutAppearingAheadOfTheMarker() {
        let previous = PlayedHit(padIndex: 12, step: 15.75, pass: 1, mark: .correct)
        let current = PlayedHit(padIndex: 12, step: 0.5, pass: 2, mark: .off)
        XCTAssertTrue(previous.isVisible(in: 2, before: 0, steps: 0..<16, totalSteps: 16))
        XCTAssertTrue(previous.isVisible(in: 2, before: 4.5, steps: 0..<16, totalSteps: 16))
        XCTAssertFalse(previous.isVisible(in: 2, before: 5, steps: 0..<16, totalSteps: 16))
        XCTAssertFalse(previous.isVisible(in: 2, before: 4, steps: 0..<16, totalSteps: 16, reduceMotion: true))
        XCTAssertFalse(previous.isVisible(in: 3, before: 0, steps: 0..<16, totalSteps: 16))
        XCTAssertFalse(current.isVisible(in: 2, before: 0.5, steps: 0..<16, totalSteps: 16))
        XCTAssertTrue(current.isVisible(in: 2, before: 0.6, steps: 0..<16, totalSteps: 16))
        XCTAssertFalse(previous.isVisible(in: 2, before: 1, steps: 16..<32, totalSteps: 32))
    }

    func testVisibilityUsesTheCurrentPassPositionAndVisibleBars() {
        let hit = PlayedHit(padIndex: 12, step: 15.75, pass: 2, mark: .correct)
        // The same rule serves the scrolling strip and each static bar/page.
        XCTAssertTrue(hit.isVisible(in: 2, before: 15.8, steps: 0..<64))
        XCTAssertTrue(hit.isVisible(in: 2, before: 16, steps: 0..<16))
        XCTAssertFalse(hit.isVisible(in: 2, before: 15.75, steps: 0..<64))
        XCTAssertFalse(hit.isVisible(in: 2, before: 15.7, steps: 0..<64))
        XCTAssertFalse(hit.isVisible(in: 3, before: 16, steps: 0..<64))
        XCTAssertFalse(hit.isVisible(in: 1, before: 16, steps: 0..<64))
        XCTAssertFalse(hit.isVisible(in: 2, before: 32, steps: 16..<32))
        XCTAssertFalse(hit.isVisible(in: 3, before: 0, steps: 0..<64))

        let countIn = PlayedHit(padIndex: 12, step: -0.25, pass: 2, mark: nil)
        XCTAssertFalse(countIn.isVisible(in: 2, before: 1, steps: 0..<64))
        let boundary = PlayedHit(padIndex: 12, step: 16, pass: 2, mark: .wrong)
        XCTAssertFalse(boundary.isVisible(in: 2, before: 17, steps: 0..<16))
        XCTAssertTrue(boundary.isVisible(in: 2, before: 17, steps: 16..<32))
    }
}
