import XCTest
@testable import SmackAPad

final class LearningRulesTests: XCTestCase {
    func testMainLearningConstants() {
        XCTAssertEqual(LearningRules.passMark, 0.8)
        XCTAssertEqual(LearningRules.minimumHitsPerStar, 16)
        XCTAssertEqual(LearningRules.maximumRunsPerStar, 4)
    }
}
