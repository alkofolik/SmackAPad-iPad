import XCTest
@testable import SmackAPad

final class TimingHistoryTests: XCTestCase {
    func testTendencyUsesMedianOfLastEightHitsAndStrictCentredThreshold() {
        var history = TimingHistory()
        XCTAssertNil(history.tendency)
        for error in [-150.0, -120, -100, 9, 10, 11, 12, 12, 13, 14, 180] {
            history.record(errorMilliseconds: error, maximumMilliseconds: 200, goodMilliseconds: 100)
        }
        XCTAssertEqual(history.tendency, .late(12))

        for error in [-80.0, -14, -13, -12, -12, -11, -10, -9] {
            history.record(errorMilliseconds: error, maximumMilliseconds: 200, goodMilliseconds: 100)
        }
        XCTAssertEqual(history.tendency, .early(12))

        for error in [7.0, 7, 7, 7, 8, 8, 8, 8] {
            history.record(errorMilliseconds: error, maximumMilliseconds: 200, goodMilliseconds: 100)
        }
        XCTAssertEqual(history.tendency, .centred) // Median is 7.5 ms, before rounding.
        for _ in 0..<8 {
            history.record(errorMilliseconds: 8, maximumMilliseconds: 200, goodMilliseconds: 100)
        }
        XCTAssertEqual(history.tendency, .late(8))
        for _ in 0..<8 {
            history.record(errorMilliseconds: -8, maximumMilliseconds: 200, goodMilliseconds: 100)
        }
        XCTAssertEqual(history.tendency, .early(8))
    }
}
