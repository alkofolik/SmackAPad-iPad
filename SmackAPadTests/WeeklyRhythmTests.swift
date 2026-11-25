import XCTest
@testable import SmackAPad

final class WeeklyRhythmTests: XCTestCase {
    func testWeekRunsFromMondayThroughSundayAcrossNewYear() throws {
        let locale = Locale(identifier: "en_US")
        let timeZone = try XCTUnwrap(TimeZone(identifier: "Pacific/Auckland"))
        let dates = ["2026-12-28", "2026-12-29", "2026-12-30", "2026-12-31", "2027-01-01", "2027-01-02", "2027-01-03"]
        let practiced: Set<String> = ["2026-12-27", "2026-12-28", "2027-01-03", "2027-01-04"]

        for today in [dates[0], dates[6]] {
            let week = WeeklyRhythm(today: today, practiceDays: practiced, locale: locale, timeZone: timeZone)

            XCTAssertEqual(week.days.map(\.dayString), dates)
            XCTAssertEqual(week.days.map(\.shortWeekday), ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
            XCTAssertEqual(week.days.filter(\.isToday).map(\.dayString), [today])
            XCTAssertEqual(week.days.filter(\.practiced).map(\.dayString), [dates[0], dates[6]])
            XCTAssertEqual(week.practicedThisWeek, 2)
            XCTAssertEqual(week.totalPracticedDays, 4)
        }
    }
}
