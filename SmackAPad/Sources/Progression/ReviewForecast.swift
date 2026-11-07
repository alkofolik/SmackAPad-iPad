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

// MARK: - ReviewQueue

public enum ReviewQueue: Sendable {
    /// Pure function ordering candidate due lessons for spaced review:
    /// 1. lowest `reviewStep` first (step 1 is the most fragile, internally step 0)
    /// 2. most days late (higher days between dueDay and today first)
    /// 3. earlier `masteryDay` (oldest mastered lesson first)
    /// 4. lesson id (ascending)
    public static func order(
        _ lessons: [Lesson],
        records: [Int: LessonProgress],
        today: String = AppCalendar.today()
    ) -> [Lesson] {
        lessons.sorted { a, b in
            isDueOrderedBefore(
                idA: a.id, recordA: records[a.id],
                idB: b.id, recordB: records[b.id],
                today: today
            )
        }
    }

    /// Pure function ordering candidate lesson IDs for spaced review.
    public static func order(
        ids: [Int],
        records: [Int: LessonProgress],
        today: String = AppCalendar.today()
    ) -> [Int] {
        ids.sorted { a, b in
            isDueOrderedBefore(
                idA: a, recordA: records[a],
                idB: b, recordB: records[b],
                today: today
            )
        }
    }

    /// Order for waiting lessons (reviews not yet due):
    /// Soonest due first (`reviewDueDay` ascending), then the Due-now order.
    public static func orderWaiting(
        _ lessons: [Lesson],
        records: [Int: LessonProgress],
        today: String = AppCalendar.today()
    ) -> [Lesson] {
        lessons.sorted { a, b in
            let recordA = records[a.id]
            let recordB = records[b.id]
            let dueA = recordA?.reviewDueDay ?? ""
            let dueB = recordB?.reviewDueDay ?? ""
            if dueA != dueB {
                if dueA.isEmpty != dueB.isEmpty { return !dueA.isEmpty }
                return dueA < dueB
            }
            return isDueOrderedBefore(
                idA: a.id, recordA: recordA,
                idB: b.id, recordB: recordB,
                today: today
            )
        }
    }

    private static func isDueOrderedBefore(
        idA: Int, recordA: LessonProgress?,
        idB: Int, recordB: LessonProgress?,
        today: String
    ) -> Bool {
        // 1. Lowest reviewStep first
        let stepA = recordA?.reviewStep ?? 0
        let stepB = recordB?.reviewStep ?? 0
        if stepA != stepB {
            return stepA < stepB
        }

        // 2. Most days late (higher lateness comes first)
        let daysLateA = recordA?.reviewDueDay.flatMap { AppCalendar.daysBetween($0, today) } ?? 0
        let daysLateB = recordB?.reviewDueDay.flatMap { AppCalendar.daysBetween($0, today) } ?? 0
        if daysLateA != daysLateB {
            return daysLateA > daysLateB
        }

        // 3. Earlier masteryDay
        let masteryA = recordA?.masteryDay ?? ""
        let masteryB = recordB?.masteryDay ?? ""
        if masteryA != masteryB {
            if masteryA.isEmpty != masteryB.isEmpty {
                return !masteryA.isEmpty
            }
            return masteryA < masteryB
        }

        // 4. Lesson ID
        return idA < idB
    }
}
