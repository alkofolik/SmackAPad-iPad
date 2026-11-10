import XCTest
@testable import SmackAPad

final class TimingHistoryTests: XCTestCase {
    private let now = Date(timeIntervalSinceReferenceDate: 100)

    private func history(_ errors: [Double], age: TimeInterval = 0,
                         following history: TimingHistory = TimingHistory()) -> TimingHistory {
        var history = history
        for error in errors {
            history.record(errorMilliseconds: error, maximumMilliseconds: 100, goodMilliseconds: 50,
                           date: now.addingTimeInterval(-age))
        }
        return history
    }

    func testCueRequiresThreeRecentHits() {
        let old = history([100, 100, 100], age: 3)
        XCTAssertEqual(history([-60, -60], following: old).cueOffset(at: now), 0)
        XCTAssertEqual(history([-60, -60, -60], following: old).cueOffset(at: now), -0.5)
    }

    func testCueUsesMedianWithInclusiveDeadbandAndLinearTravel() {
        XCTAssertEqual(history([-95, 20, 100]).cueOffset(at: now), 0)
        XCTAssertEqual(history([-95, -20, 100]).cueOffset(at: now), 0)
        XCTAssertEqual(history([-95, -60, 100]).cueOffset(at: now), -0.5)
        XCTAssertEqual(history([-95, 60, 100]).cueOffset(at: now), 0.5)
    }

    func testCueClampsLargeErrorsInBothDirections() {
        XCTAssertEqual(history([-200, -150, 0]).cueOffset(at: now), -1)
        XCTAssertEqual(history([0, 150, 200]).cueOffset(at: now), 1)
    }

    func testCueUsesOnlyTheLastEightHits() {
        let errors: [Double] = [-100, -100, -100, -100, -100, 40, 40, 60, 60]
        XCTAssertEqual(history(errors).cueOffset(at: now), -0.125)
    }
}
