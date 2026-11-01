import XCTest
import SwiftUI
@testable import SmackAPad

final class MotionTests: XCTestCase {
    func testReducedPolicyUsesOnlyOpacityAndFastAnimation() {
        let policy = Theme.Motion.Policy(reduced: true)
        XCTAssertTrue(policy.opacityOnly)
        XCTAssertEqual(policy.animation(Theme.Motion.emphasis), Theme.Motion.fast)
        XCTAssertEqual(policy.scale(1.15), 1)
        XCTAssertEqual(policy.offset(6), 0)
        XCTAssertEqual(policy.angle(90), .zero)
        let normal = Theme.Motion.Policy(reduced: false)
        XCTAssertFalse(normal.opacityOnly)
        XCTAssertEqual(normal.animation(Theme.Motion.emphasis), Theme.Motion.emphasis)
        XCTAssertEqual(normal.scale(1.15), 1.15)
    }

    func testOnlyNewStarsAreReturned() {
        XCTAssertEqual(Theme.Motion.newStars(before: [true, false, false], after: [true, true, true]), [1, 2])
        XCTAssertEqual(Theme.Motion.newStars(before: [true, true, true], after: [true, true, true]), [])
        XCTAssertEqual(Theme.Motion.newStars(before: [], after: [true, false, true]), [0, 2])
        XCTAssertEqual(Theme.Motion.newStars(before: [true, true, true], after: [false, false, false]), [])
    }
}
