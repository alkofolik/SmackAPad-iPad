//
//  AppCalendar.swift
//  SmackAPad
//

import Foundation

// MARK: - AppCalendar (Injectable Date / Day Provider)

/// Provides the current calendar day string (`YYYY-MM-DD`, device time zone).
/// Injectable for tests and future tickets (e.g. review scheduler).
public struct AppCalendar: Sendable {
    public static var todayProvider: @Sendable () -> String = {
        dayString(from: now())
    }

    public static func today() -> String {
        todayProvider()
    }

    public static func now() -> Date {
        #if DEBUG
        debugNowProvider()
        #else
        Date()
        #endif
    }

    #if DEBUG
    private static var debugNowProvider: @Sendable () -> Date = { Date() }

    static func shiftedDate(by offset: Int, from date: Date = Date()) -> Date {
        guard offset != 0 else { return date }
        return Calendar.current.date(byAdding: .day, value: offset, to: date) ?? date
    }

    static func useDebugDayOffset(_ offset: Int) {
        debugNowProvider = { shiftedDate(by: offset) }
    }
    #endif

    public static func dayString(from date: Date, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let y = components.year ?? 2026
        let m = components.month ?? 1
        let d = components.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    public static func addingDays(_ days: Int, to day: String, timeZone: TimeZone = .current) -> String? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = day.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var components = DateComponents()
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        guard let date = calendar.date(from: components),
              let nextDate = calendar.date(byAdding: .day, value: days, to: date) else { return nil }
        return dayString(from: nextDate, timeZone: timeZone)
    }

    public static func daysBetween(_ startDay: String, _ endDay: String, timeZone: TimeZone = .current) -> Int? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let startParts = startDay.split(separator: "-").compactMap { Int($0) }
        let endParts = endDay.split(separator: "-").compactMap { Int($0) }
        guard startParts.count == 3, endParts.count == 3 else { return nil }
        var c1 = DateComponents(); c1.year = startParts[0]; c1.month = startParts[1]; c1.day = startParts[2]
        var c2 = DateComponents(); c2.year = endParts[0]; c2.month = endParts[1]; c2.day = endParts[2]
        guard let d1 = calendar.date(from: c1), let d2 = calendar.date(from: c2) else { return nil }
        return calendar.dateComponents([.day], from: d1, to: d2).day
    }
}

