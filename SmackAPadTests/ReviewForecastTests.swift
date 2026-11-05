//
//  ReviewForecastTests.swift
//  SmackAPadTests
//
//  Unit tests for ReviewForecast (Ticket 105).
//

import XCTest
@testable import SmackAPad

final class ReviewForecastTests: XCTestCase {
    // 1. Forecast counts a lesson due in 3 days only from day 3
    func testForecastCountsLessonDueInThreeDaysOnlyFromDayThree() {
        let today = "2026-11-05"
        let inThreeDays = "2026-11-08"
        let progress = LessonProgress(passed: true, mastery: true, reviewStep: 0, reviewDueDay: inThreeDays, settled: false)
        let records = [101: progress]

        let forecast = ReviewForecast.dueCounts(records, from: today, days: 5)
        XCTAssertEqual(forecast.count, 5)
        XCTAssertEqual(forecast[0].day, "2026-11-05")
        XCTAssertEqual(forecast[0].count, 0)
        XCTAssertEqual(forecast[1].day, "2026-11-06")
        XCTAssertEqual(forecast[1].count, 0)
        XCTAssertEqual(forecast[2].day, "2026-11-07")
        XCTAssertEqual(forecast[2].count, 0)
        XCTAssertEqual(forecast[3].day, "2026-11-08")
        XCTAssertEqual(forecast[3].count, 1)
        XCTAssertEqual(forecast[4].day, "2026-11-09")
        XCTAssertEqual(forecast[4].count, 1)
    }

    // 2. An overdue lesson counts on today and later days
    func testOverdueLessonCountsOnTodayAndLaterDays() {
        let today = "2026-11-05"
        let overdueDay = "2026-11-03" // 2 days ago
        let progress = LessonProgress(passed: true, mastery: true, reviewStep: 1, reviewDueDay: overdueDay, settled: false)
        let records = [201: progress]

        let forecast = ReviewForecast.dueCounts(records, from: today, days: 4)
        XCTAssertEqual(forecast.count, 4)
        XCTAssertEqual(forecast[0].day, "2026-11-05")
        XCTAssertEqual(forecast[0].count, 1)
        XCTAssertEqual(forecast[1].day, "2026-11-06")
        XCTAssertEqual(forecast[1].count, 1)
        XCTAssertEqual(forecast[2].day, "2026-11-07")
        XCTAssertEqual(forecast[2].count, 1)
        XCTAssertEqual(forecast[3].day, "2026-11-08")
        XCTAssertEqual(forecast[3].count, 1)
    }

    // 3. Settled lessons never count
    func testSettledLessonsNeverCount() {
        let today = "2026-11-05"
        let pastDay = "2026-11-01"
        let settled1 = LessonProgress(passed: true, mastery: true, reviewStep: 3, reviewDueDay: pastDay, settled: true)
        let settled2 = LessonProgress(passed: true, mastery: true, reviewStep: 3, reviewDueDay: "2026-11-10", settled: true)
        let records = [301: settled1, 302: settled2]

        let forecast = ReviewForecast.dueCounts(records, from: today, days: 7)
        XCTAssertEqual(forecast.count, 7)
        for entry in forecast {
            XCTAssertEqual(entry.count, 0)
        }
    }
}
