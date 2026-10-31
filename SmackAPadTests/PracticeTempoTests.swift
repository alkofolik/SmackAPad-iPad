import XCTest
@testable import SmackAPad

final class PracticeTempoTests: XCTestCase {
    func testCleanPassesFormAMonotoneStaircaseWithOnePassDelay() {
        for step in [1, 2, 5, 10] {
            var tempo = PracticeTempo()
            var queued = [50]
            // Pass 2 must be queued before pass 1 can be scored.
            queued.append(tempo.queue(after: 50, targetBpm: 100, listenBpm: nil))
            for finishedBpm in [50, 50, 50 + step, 50 + step] {
                tempo.completed(nextBpm: finishedBpm + step)
                queued.append(tempo.queue(after: queued.last!, targetBpm: 100, listenBpm: nil))
            }
            XCTAssertEqual(queued, [50, 50, 50 + step, 50 + step, 50 + 2 * step, 50 + 2 * step])
        }
    }

    func testUncleanPassKeepsTheLastQueuedTempoEvenIfItsResultIsSlower() {
        var tempo = PracticeTempo()
        tempo.completed(nextBpm: 50)
        XCTAssertEqual(tempo.queue(after: 55, targetBpm: 100, listenBpm: nil), 55)
    }

    func testOneFinishedResultCannotRaiseTwoQueuedPasses() {
        var tempo = PracticeTempo()
        tempo.completed(nextBpm: 55)
        XCTAssertEqual(tempo.queue(after: 50, targetBpm: 100, listenBpm: nil), 55)
        // The result is consumed, even if the caller supplies the old baseline.
        XCTAssertEqual(tempo.queue(after: 50, targetBpm: 100, listenBpm: nil), 50)
        XCTAssertEqual(tempo.queue(after: 55, targetBpm: 100, listenBpm: nil), 55)
    }

    func testQueuedTempoIsCappedAtTarget() {
        var tempo = PracticeTempo()
        tempo.completed(nextBpm: 105)
        XCTAssertEqual(tempo.queue(after: 98, targetBpm: 100, listenBpm: nil), 100)
    }

    func testRestartDiscardsThePreviousResultAndRespectsManualTempo() {
        var tempo = PracticeTempo()
        tempo.completed(nextBpm: 95)
        tempo.reset()
        XCTAssertEqual(tempo.queue(after: 50, targetBpm: 100, listenBpm: nil), 50)
        tempo.completed(nextBpm: 55)
        XCTAssertEqual(tempo.queue(after: 50, targetBpm: 100, listenBpm: nil), 55)
    }

    func testListenKeepsItsCurrentTempoWithoutApplyingScoringOrTarget() {
        var tempo = PracticeTempo()
        tempo.completed(nextBpm: 95)
        XCTAssertEqual(tempo.queue(after: 50, targetBpm: 80, listenBpm: 90), 90)
        XCTAssertEqual(tempo.queue(after: 90, targetBpm: 80, listenBpm: 90), 90)
    }
}
