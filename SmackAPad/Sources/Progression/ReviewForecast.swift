//
//  ReviewForecast.swift
//  SmackAPad
//
//  Forecast of due review counts over upcoming days (Tickets 105, 107).
//

import Foundation

public struct ReviewForecast: Sendable {
    /// Pure function returning the forecast of due lessons for each day in a range of `days`,
    /// starting from `today`.
    ///
    /// Rules:
    /// - Day count = lessons whose due day <= that day and that are not settled.
    /// - Overdue reviews count on today and on each later day until played.
    /// - Settled lessons never count.
    public static func dueCounts(
        _ records: [Int: LessonProgress],
        from today: String,
        days: Int
    ) -> [(day: String, count: Int)] {
        dueCounts(Array(records.values), from: today, days: days)
    }

    public static func dueCounts(
        records: [Int: LessonProgress],
        from today: String,
        days: Int
    ) -> [(day: String, count: Int)] {
        dueCounts(Array(records.values), from: today, days: days)
    }

    public static func dueCounts(
        _ records: [LessonProgress],
        from today: String,
        days: Int
    ) -> [(day: String, count: Int)] {
        guard days > 0 else { return [] }
        var result: [(day: String, count: Int)] = []
        result.reserveCapacity(days)

        let unsettledWithDue = records.filter { record in
            !record.reviewSchedule.isSettled && record.reviewDueDay != nil
        }

        for offset in 0..<days {
            guard let currentDay = AppCalendar.addingDays(offset, to: today) else { continue }
            let count = unsettledWithDue.filter { record in
                guard let dueDay = record.reviewDueDay else { return false }
                return dueDay <= currentDay
            }.count
            result.append((day: currentDay, count: count))
        }

        return result
    }

    public static func dueCounts(
        records: [LessonProgress],
        from today: String,
        days: Int
    ) -> [(day: String, count: Int)] {
        dueCounts(records, from: today, days: days)
    }
}
