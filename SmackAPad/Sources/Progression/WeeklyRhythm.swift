import Foundation

struct WeeklyRhythm {
    struct Day: Identifiable {
        let dayString: String
        let shortWeekday: String
        let practiced: Bool
        let isToday: Bool

        var id: String { dayString }
    }

    let days: [Day]
    let totalPracticedDays: Int

    var practicedThisWeek: Int { days.filter(\.practiced).count }

    init(today: String, practiceDays: Set<String>, locale: Locale, timeZone: TimeZone = .current) {
        totalPracticedDays = practiceDays.count

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4

        let parts = today.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])),
              let week = calendar.dateInterval(of: .weekOfYear, for: date) else {
            days = []
            return
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEE"

        days = (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: week.start) else { return nil }
            let day = AppCalendar.dayString(from: date, timeZone: timeZone)
            return Day(dayString: day, shortWeekday: formatter.string(from: date),
                       practiced: practiceDays.contains(day), isToday: day == today)
        }
    }
}
