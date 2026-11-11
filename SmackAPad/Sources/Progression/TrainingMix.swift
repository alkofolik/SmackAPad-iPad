import Foundation

/// Pure daily selection. Access is supplied by the owning screen, including edition access.
enum TrainingMix {
    /// Shares Training's saved draw with any entry point that needs today's Mix.
    static func dailySelection(lessons: [Lesson], progress: [Int: LessonProgress], padCount: Int,
                               openLessonIDs: Set<Int>, day: String, savedJSON: String) -> [Lesson] {
        let pool = candidates(lessons: lessons, progress: progress, padCount: padCount,
                              openLessonIDs: openLessonIDs)
        let saved = (try? JSONDecoder().decode([String: [Int]].self, from: Data(savedJSON.utf8))) ?? [:]
        if let ids = saved["\(day):\(padCount)"], ids.count >= LearningRules.minimumMixLessons,
           Set(ids).count == ids.count {
            let cached = ids.compactMap { id in pool.first { $0.id == id } }
            if cached.count == ids.count { return cached }
        }
        return select(lessons: lessons, progress: progress, padCount: padCount,
                      openLessonIDs: openLessonIDs, day: day)
    }

    static func candidates(lessons: [Lesson], progress: [Int: LessonProgress], padCount: Int,
                           openLessonIDs: Set<Int>) -> [Lesson] {
        var seen: Set<Int> = []
        return lessons.filter {
            seen.insert($0.id).inserted && progress[$0.id]?.mastery == true
                && openLessonIDs.contains($0.id)
                && (padCount == 16 || (padCount == 8 && EightPadLayout.slots(for: $0) != nil))
        }
    }

    static func select(lessons: [Lesson], progress: [Int: LessonProgress], padCount: Int,
                       openLessonIDs: Set<Int>, day: String, draw: UInt64 = 0) -> [Lesson] {
        let pool = candidates(lessons: lessons, progress: progress, padCount: padCount,
                              openLessonIDs: openLessonIDs)
        let ordered = pool.sorted {
            let left = progress[$0.id]?.lastPlayedDay ?? ""
            let right = progress[$1.id]?.lastPlayedDay ?? ""
            if left != right { return left < right }
            let lhs = rank("\(day):\(draw):\($0.id)")
            let rhs = rank("\(day):\(draw):\($1.id)")
            return lhs != rhs ? lhs < rhs : $0.id < $1.id
        }
        let windows = (1...5).map { low in ordered.filter { (low...(low + 1)).contains($0.level) } }
        let count = min(3, windows.map(\.count).max() ?? 0)
        guard count >= LearningRules.minimumMixLessons else { return [] }
        let eligible = ordered.filter { anchor in
            windows.contains { $0.count >= count && $0.contains { $0.id == anchor.id } }
        }
        // The daily draw starts with the oldest lesson. New mix may choose another
        // anchor among the six oldest, while retaining the recency preference.
        let anchor = eligible[Int(draw % UInt64(min(6, eligible.count)))]
        let possible = windows.filter { $0.count >= count && $0.contains { $0.id == anchor.id } }
        let groups = possible.map { window -> [Lesson] in
            var selected = [anchor]
            while selected.count < count {
                let remaining = window.filter { item in !selected.contains { $0.id == item.id } }
                let categories = Set(selected.map(\.cat))
                let next = remaining.first { !categories.contains($0.cat) } ?? remaining[0]
                selected.append(next)
            }
            return selected
        }
        return groups.max { Set($0.map(\.cat)).count < Set($1.map(\.cat)).count } ?? []
    }

    /// Stable across processes; Swift's Hasher intentionally is not.
    private static func rank(_ value: String) -> UInt64 {
        value.utf8.reduce(14_695_981_039_346_656_037) { ($0 ^ UInt64($1)) &* 1_099_511_628_211 }
    }
}
