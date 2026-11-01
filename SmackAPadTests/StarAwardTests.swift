import XCTest
@testable import SmackAPad

final class StarAwardTests: XCTestCase {
    func testFirstPassedStarKeepsTheRunGoing() {
        let award = StarAward(previous: nil, passed: true, mastery: false, memory: false)
        XCTAssertEqual(award.earned, [true, false, false])
        XCTAssertEqual(award.fresh, [true, false, false])
        XCTAssertFalse(award.shouldStop)
    }

    func testNewMasteryStarStopsTheRun() {
        let award = StarAward(previous: LessonProgress(passed: true), passed: true, mastery: true, memory: false)
        XCTAssertEqual(award.earned, [true, true, false])
        XCTAssertEqual(award.fresh, [false, true, false])
        XCTAssertTrue(award.shouldStop)
    }

    func testNewMemoryStarStopsTheRun() {
        let award = StarAward(previous: LessonProgress(passed: true, mastery: true),
                              passed: true, mastery: true, memory: true)
        XCTAssertEqual(award.earned, [true, true, true])
        XCTAssertEqual(award.fresh, [false, false, true])
        XCTAssertTrue(award.shouldStop)
    }

    func testRepeatingEarnedStarsNeitherAnimatesNorStops() {
        for previous in [LessonProgress(passed: true), LessonProgress(passed: true, mastery: true),
                         LessonProgress(passed: true, mastery: true, memory: true)] {
            let award = StarAward(previous: previous, passed: previous.passed,
                                  mastery: previous.mastery, memory: previous.memory)
            XCTAssertEqual(award.fresh, [false, false, false])
            XCTAssertFalse(award.shouldStop)
        }
    }

    func testTwoNewStarsAreAwardedTogether() {
        let award = StarAward(previous: nil, passed: true, mastery: true, memory: false)
        XCTAssertEqual(award.earned, [true, true, false])
        XCTAssertEqual(award.fresh, [true, true, false])
        XCTAssertTrue(award.shouldStop)
    }

    func testThreeNewStarsAreAwardedTogether() {
        let award = StarAward(previous: nil, passed: true, mastery: true, memory: true)
        XCTAssertEqual(award.earned, [true, true, true])
        XCTAssertEqual(award.fresh, [true, true, true])
        XCTAssertTrue(award.shouldStop)
    }

    func testUnsuccessfulPassPreservesOldStarsWithoutAnAward() {
        let award = StarAward(previous: LessonProgress(passed: true, mastery: true, memory: true),
                              passed: false, mastery: false, memory: false)
        XCTAssertEqual(award.earned, [true, true, true])
        XCTAssertEqual(award.fresh, [false, false, false])
        XCTAssertFalse(award.shouldStop)
    }

    func testNoStarsMeansNoStopOrAnimation() {
        let award = StarAward(previous: nil, passed: false, mastery: false, memory: false)
        XCTAssertEqual(award.earned, [false, false, false])
        XCTAssertEqual(award.fresh, [false, false, false])
        XCTAssertFalse(award.shouldStop)
    }
}
