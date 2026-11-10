import XCTest
@testable import SmackAPad

final class RunMeterTests: XCTestCase {
    @MainActor
    func testRunFractionIncludesBothRepeatsAndWrapsAtTheNextRun() {
        XCTAssertEqual(PracticeSession.runFraction(tapePosition: 0, totalSteps: 32, repeatsPerRun: 2), 0)
        XCTAssertEqual(PracticeSession.runFraction(tapePosition: 32, totalSteps: 32, repeatsPerRun: 2), 0.5)
        XCTAssertEqual(PracticeSession.runFraction(tapePosition: 64, totalSteps: 32, repeatsPerRun: 2), 0)
    }

    @MainActor
    func testMicroStepsLightAtTheThirds() {
        XCTAssertEqual(RunMeterView.litMicroSteps(fraction: 0), 0)
        XCTAssertEqual(RunMeterView.litMicroSteps(fraction: 1.0 / 3), 1)
        XCTAssertEqual(RunMeterView.litMicroSteps(fraction: 2.0 / 3), 2)
        XCTAssertEqual(RunMeterView.litMicroSteps(fraction: 1), 3)
    }
}
