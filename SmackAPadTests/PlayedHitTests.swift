import XCTest
@testable import SmackAPad

final class PlayedHitTests: XCTestCase {
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
