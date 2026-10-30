import XCTest
#if !CALIBRATION_STANDALONE
@testable import SmackAPad
#endif

final class CalibrationTests: XCTestCase {
    func testMatchingUsesActualOutputTimesAndDuplicatesCannotTakeTheNextBeat() throws {
        var run = CalibrationMeasurement()
        // Deliberately shifted from any intended schedule. Taps may arrive before
        // the audio tap reports its timestamp, so matching happens against the full output record.
        for tap in [10.215, 10.235, 11.215, 12.215, 13.215, 14.215, 15.215] {
            run.recordTap(at: tap)
        }
        let outputs = (0..<10).map { 10.125 + Double($0) }
        let result = try run.finish(outputTimes: outputs, clockChanged: false).get()
        XCTAssertEqual(result.offsetMilliseconds, 90)
        XCTAssertEqual(result.usableTaps, 6)
        XCTAssertEqual(run.matchedClickIndices(outputTimes: outputs), Set(0..<6))
        XCTAssertEqual(run.finish(outputTimes: outputs, clockChanged: true), .failure(.audioClockChanged))
    }

    func testSixHumanTapsSurviveOutliersWithoutADriftOrDuplicateLimit() throws {
        // Six taps drift by 100 ms; two unrelated taps are discarded.
        let result = try CalibrationAnalysis.evaluate(
            deltasMilliseconds: [-20, 0, 20, 40, 60, 80, -320, 340]
        ).get()
        XCTAssertEqual(result.offsetMilliseconds, 30)
        XCTAssertEqual(result.usableTaps, 6)
        XCTAssertEqual(result.discardedTaps, 2)
        XCTAssertEqual(result.spreadMilliseconds, 59.304, accuracy: 0.001)
        XCTAssertEqual(CalibrationAnalysis.evaluate(deltasMilliseconds: [0, 10, 20, 30, 40]), .failure(.tooFewTaps))
        XCTAssertEqual(CalibrationAnalysis.evaluate(deltasMilliseconds: [-200, -150, -100, 100, 150, 200]), .failure(.unevenTaps))
    }

    func testMedianKeepsTheSignAndCapsBothDirections() throws {
        for (deltas, expected) in [
            ([10.0, 20, 30, 40, 50, 60, 70, 80, 90, 100], 55.0),
            ([-100.0, -90, -80, -70, -60, -50, -40, -30, -20, -10], -55.0),
            (Array(repeating: 260.0, count: 10), 200.0),
            (Array(repeating: -260.0, count: 10), -200.0)
        ] {
            let result = try CalibrationAnalysis.evaluate(deltasMilliseconds: deltas).get()
            XCTAssertEqual(result.offsetMilliseconds, expected)
        }
    }
}
