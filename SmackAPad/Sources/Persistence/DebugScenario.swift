#if DEBUG
import Foundation

enum DebugScenario: String, CaseIterable, Identifiable {
    case fresh, introDone, stage1Done, awaitingStar3, reviewDueToday, advanced

    var id: String { rawValue }

    @MainActor
    func makeSnapshot(catalog: LibraryCatalog, overrides: DebugOverrides) throws -> DebugSnapshotStore.Snapshot {
        let today = AppCalendar.dayString(from: AppCalendar.shiftedDate(by: overrides.dayOffset))
        let tomorrow = AppCalendar.addingDays(1, to: today) ?? today
        let freePath = catalog.path.filter { $0.access == "free" }
        let introIDs = Set(catalog.introLessons.map(\.id))
        let lessons: [Lesson]
        switch self {
        case .fresh: lessons = []
        case .introDone: lessons = catalog.introLessons
        case .stage1Done:
            lessons = catalog.introLessons + (catalog.stages.first?.lessons ?? []).filter { !introIDs.contains($0.id) }
        case .awaitingStar3, .reviewDueToday: lessons = Array(freePath.prefix(4))
        case .advanced:
            lessons = catalog.introLessons + catalog.path.filter { !introIDs.contains($0.id) }.dropLast(5)
        }

        var records: [Int: LessonProgress] = [:]
        for (index, lesson) in lessons.enumerated() {
            let due = self == .awaitingStar3 || self == .reviewDueToday
                || (self == .advanced && index.isMultiple(of: 3))
            let memory = self == .reviewDueToday || (self == .advanced && (due || index.isMultiple(of: 2)))
            let passedReviews = memory ? 2 : (self == .awaitingStar3 ? 1 : 0)
            let daysSinceMastery = ReviewScheduler.gaps.prefix(passedReviews + 1).reduce(0, +)
            let masteryDay = AppCalendar.addingDays(-daysSinceMastery, to: due ? today : tomorrow) ?? today
            var schedule = ReviewScheduler.initialSchedule(masteryDay: masteryDay)
            for _ in 0..<passedReviews {
                schedule = ReviewScheduler.evaluate(schedule: schedule, today: schedule.reviewDueDay ?? today,
                                                    isFullRun: true, fromMemory: true,
                                                    bpm: lesson.targetBpm, targetBpm: lesson.targetBpm,
                                                    score: 0.92).newSchedule
            }
            var progress = LessonProgress(passed: true, mastery: true, memory: memory,
                                          currentBpm: lesson.targetBpm, bestScore: 0.92,
                                          lastPlayedDay: schedule.lastReviewedDay ?? masteryDay,
                                          masteryDay: masteryDay)
            progress.reviewSchedule = schedule
            records[lesson.id] = progress
        }

        var snapshot = DebugSnapshotStore.Snapshot()
        overrides.write(to: &snapshot.settings)
        if !records.isEmpty {
            let root = ProgressRoot(lessons: records)
            snapshot.progress = try JSONEncoder().encode(root)
        }
        if self == .advanced {
            // Use the same definitions and award rules as normal play.
            let suite = "SmackAPad.DebugScenario.\(UUID().uuidString)"
            if let defaults = UserDefaults(suiteName: suite) {
                defer { defaults.removePersistentDomain(forName: suite) }
                let badges = BadgeStore(userDefaults: defaults)
                badges.awardSilently(progress: records, catalog: catalog,
                                     at: AppCalendar.shiftedDate(by: overrides.dayOffset))
                snapshot.settings[BadgeStore.storageKey] = defaults.data(forKey: BadgeStore.storageKey)
            }
        }
        return snapshot
    }
}

@MainActor
enum DebugTestStartup {
    static func prepare(arguments: [String] = ProcessInfo.processInfo.arguments) {
        let snapshots = DebugSnapshotStore.shared
        do {
            try snapshots.finishPendingChange()
        } catch {
            // Never let the app write progress while a profile change is incomplete.
            fatalError("Could not finish the debug profile change. The backup and pending change were kept. \(error)")
        }

        if let options = LaunchOptions(arguments: arguments, current: snapshots.overrides) {
            do {
                if let scenario = options.scenario {
                    try snapshots.queueScenario(scenario, catalog: LessonStore.shared.libraryCatalog,
                                                overrides: options.overrides)
                } else if options.overrides != snapshots.overrides {
                    try snapshots.queueOverrides(options.overrides)
                }
            } catch {
                print("Could not prepare the debug profile change: \(error)")
            }
            do {
                try snapshots.finishPendingChange()
            } catch {
                fatalError("Could not finish the debug profile change. The backup and pending change were kept. \(error)")
            }
        }
        AppCalendar.useDebugDayOffset(snapshots.overrides.dayOffset)
    }

    private struct LaunchOptions {
        var scenario: DebugScenario?
        var overrides: DebugOverrides

        init?(arguments: [String], current: DebugOverrides) {
            let flags = ["-debugScenario", "-debugDayOffset", "-debugAccess"]
            guard flags.contains(where: arguments.contains) else { return nil }
            var options: [String: String] = [:]
            for flag in flags {
                guard let index = arguments.lastIndex(of: flag) else { continue }
                guard arguments.indices.contains(index + 1) else {
                    print("Missing value for \(flag)")
                    return nil
                }
                options[flag] = arguments[index + 1]
            }

            if let id = options["-debugScenario"] {
                guard let scenario = DebugScenario(rawValue: id) else {
                    print("Unknown debug scenario: \(id)")
                    return nil
                }
                self.scenario = scenario
            }

            var access = scenario == nil ? current.access : .real
            var dayOffset = scenario == nil ? current.dayOffset : 0
            if let value = options["-debugAccess"] {
                guard let override = DebugAccessOverride(rawValue: value), override != .real else {
                    print("Use free or full for -debugAccess")
                    return nil
                }
                access = override
            }
            if let value = options["-debugDayOffset"] {
                guard let offset = Int(value), DebugOverrides.dayRange.contains(offset) else {
                    print("Use a whole number from -30 to 60 for -debugDayOffset")
                    return nil
                }
                dayOffset = offset
            }
            overrides = DebugOverrides(access: access, dayOffset: dayOffset)
        }
    }
}
#endif
