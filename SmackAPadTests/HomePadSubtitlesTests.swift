import XCTest
@testable import SmackAPad

final class HomePadSubtitlesTests: XCTestCase {

    private func makeLesson(id: Int, title: String) -> Lesson {
        Lesson(
            id: id,
            cat: "path",
            title: title,
            genre: "Funk",
            tags: [],
            text: "",
            division: 16,
            bars: 2,
            startBpm: 70,
            targetBpm: 95,
            level: 1,
            src: "test",
            hits: [LessonHit(step: 0, padIndex: 0, hand: "R", velocity: 100)]
        )
    }

    private func makePlan(stepCount: Int, index: Int = 0, finished: Bool = false) -> TodayPlan {
        let steps = (0..<stepCount).map { i in
            TodayPlan.Step(kind: .review, lessonIDs: [i + 1])
        }
        return TodayPlan(day: "2026-11-11", steps: steps, index: index, finished: finished)
    }

    func testTodaySubtitleHandlesRemainingCountsAndDoneState() {
        XCTAssertNil(HomePadSubtitles.today(plan: nil, language: .english))
        XCTAssertNil(HomePadSubtitles.today(plan: makePlan(stepCount: 2, finished: true), language: .english))
        XCTAssertNil(HomePadSubtitles.today(plan: makePlan(stepCount: 2, index: 2, finished: false), language: .czech))

        XCTAssertEqual(
            HomePadSubtitles.today(plan: makePlan(stepCount: 1), language: .english),
            "1 lesson"
        )
        XCTAssertEqual(
            HomePadSubtitles.today(plan: makePlan(stepCount: 2), language: .english),
            "2 lessons"
        )
        XCTAssertEqual(
            HomePadSubtitles.today(plan: makePlan(stepCount: 5), language: .english),
            "5 lessons"
        )

        XCTAssertEqual(
            HomePadSubtitles.today(plan: makePlan(stepCount: 1), language: .czech),
            "1 lekce"
        )
        XCTAssertEqual(
            HomePadSubtitles.today(plan: makePlan(stepCount: 3, index: 1), language: .czech),
            "2 lekce"
        )
        XCTAssertEqual(
            HomePadSubtitles.today(plan: makePlan(stepCount: 5), language: .czech),
            "5 lekcí"
        )
    }

    func testContinueSubtitleAndTargetForEmptyProfileAndPlayedLesson() {
        let introFirst = makeLesson(id: 10, title: "Intro 1")
        let pathFirst = makeLesson(id: 20, title: "Soul 1")
        let played = makeLesson(id: 42, title: "Soul 2\nGroove")

        XCTAssertNil(HomePadSubtitles.continueLesson(lastPlayedLesson: nil, language: .english))
        XCTAssertEqual(
            HomePadSubtitles.continueTarget(
                lastPlayedLesson: nil,
                introFirstLesson: introFirst,
                pathFirstLesson: pathFirst
            )?.id,
            introFirst.id
        )
        XCTAssertEqual(
            HomePadSubtitles.continueTarget(
                lastPlayedLesson: nil,
                introFirstLesson: nil,
                pathFirstLesson: pathFirst
            )?.id,
            pathFirst.id
        )

        let playedSubtitle = HomePadSubtitles.continueLesson(lastPlayedLesson: played, language: .english)
        XCTAssertEqual(playedSubtitle, "Soul 2 Groove")
        XCTAssertEqual(playedSubtitle?.contains("\n"), false)
        XCTAssertEqual(
            HomePadSubtitles.continueTarget(
                lastPlayedLesson: played,
                introFirstLesson: introFirst,
                pathFirstLesson: pathFirst
            )?.id,
            played.id
        )
    }

    func testControllerSubtitleShowsConnectedNameOrLocalizedDisconnected() {
        XCTAssertEqual(
            HomePadSubtitles.controller(connectedName: "JP-Mini\n", language: .czech),
            "JP-Mini"
        )
        XCTAssertEqual(
            HomePadSubtitles.controller(connectedName: nil, language: .english),
            "Not connected"
        )
        XCTAssertEqual(
            HomePadSubtitles.controller(connectedName: "   ", language: .czech),
            "Nepřipojeno"
        )
    }

    func testRemainingPadsUseExpectedSubtitles() {
        XCTAssertNil(HomePadSubtitles.library())
        XCTAssertNil(HomePadSubtitles.intro())
        XCTAssertEqual(HomePadSubtitles.badges(earned: 14, total: 55), "14 / 55")
        XCTAssertEqual(
            HomePadSubtitles.fullVersion(hasFullAccess: true, price: "$9.99", language: .english),
            "Unlocked"
        )
        XCTAssertEqual(
            HomePadSubtitles.fullVersion(hasFullAccess: true, price: "249 Kč", language: .czech),
            "Odemknuto"
        )
        XCTAssertEqual(
            HomePadSubtitles.fullVersion(hasFullAccess: false, price: "249 Kč", language: .czech),
            "249 Kč"
        )
        XCTAssertNil(
            HomePadSubtitles.fullVersion(hasFullAccess: false, price: nil, language: .english)
        )
        XCTAssertNil(HomePadSubtitles.settings())
    }
}
