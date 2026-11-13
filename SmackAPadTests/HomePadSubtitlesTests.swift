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
        // Network session
        XCTAssertEqual(
            HomePadSubtitles.controller(connectedName: "Network session 1", language: .english),
            "Network MIDI"
        )
        XCTAssertEqual(
            HomePadSubtitles.controller(connectedName: "Network session 1", language: .czech),
            "Síťový MIDI"
        )
        XCTAssertEqual(
            HomePadSubtitles.controller(connectedName: "Network MIDI", language: .english),
            "Network MIDI"
        )
        XCTAssertEqual(
            HomePadSubtitles.controller(connectedName: "Network MIDI", language: .czech),
            "Síťový MIDI"
        )
        XCTAssertEqual(
            HomePadSubtitles.controller(connectedName: "Síťová relace 1", language: .english),
            "Network MIDI"
        )
        XCTAssertEqual(
            HomePadSubtitles.controller(connectedName: "Síťová relace 1", language: .czech),
            "Síťový MIDI"
        )
        // Long device name cut at word boundary within 14 chars
        XCTAssertEqual(
            HomePadSubtitles.controller(connectedName: "Akai MPD218 Controller", language: .english),
            "Akai MPD218"
        )
        XCTAssertEqual(
            HomePadSubtitles.controller(connectedName: "Novation Launchkey Mini", language: .english),
            "Novation"
        )
        // First word already longer than limit
        XCTAssertEqual(
            HomePadSubtitles.controller(connectedName: "SuperLongControllerName Extra", language: .english),
            "SuperLongControllerName"
        )
    }

    func testContinueSubtitleUsesShortNameWhenTitleExceedsLimit() {
        let kickLesson = makeLesson(id: 10001, title: "Kick on every beat")
        XCTAssertEqual(
            HomePadSubtitles.continueLesson(lastPlayedLesson: kickLesson, language: .english),
            "Kick on beats"
        )
        XCTAssertEqual(
            HomePadSubtitles.continueLesson(lastPlayedLesson: kickLesson, language: .czech),
            "Kick na doby"
        )
    }

    func testEveryLessonHasHomeLineAtMost14CharactersInEnglishAndCzech() throws {
        let store = LessonStore.shared
        if store.lessons.isEmpty {
            try store.reload()
        }
        var allLessons = store.lessons
        if allLessons.isEmpty {
            for source in BundledLessonContentSource.allDefaultBundledSources() {
                if let loaded = try? source.loadLessons() {
                    allLessons.append(contentsOf: loaded)
                }
            }
        }
        XCTAssertFalse(allLessons.isEmpty, "Bundled lessons should not be empty")

        var seenIDs: Set<Int> = []
        for lesson in allLessons {
            guard seenIDs.insert(lesson.id).inserted else { continue }
            for language in [AppLanguage.english, AppLanguage.czech] {
                let subtitle = try XCTUnwrap(
                    HomePadSubtitles.continueLesson(lastPlayedLesson: lesson, language: language),
                    "Missing subtitle for lesson \(lesson.id) '\(lesson.title)' in \(language)"
                )
                XCTAssertLessThanOrEqual(
                    subtitle.count,
                    14,
                    "Lesson \(lesson.id) '\(lesson.title)' in \(language) subtitle '\(subtitle)' exceeds 14 chars (\(subtitle.count))"
                )
                XCTAssertFalse(
                    subtitle.contains("…"),
                    "Lesson \(lesson.id) '\(lesson.title)' in \(language) subtitle '\(subtitle)' contains ellipsis"
                )
                XCTAssertFalse(
                    subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "Lesson \(lesson.id) '\(lesson.title)' in \(language) subtitle is empty"
                )
            }
        }
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
