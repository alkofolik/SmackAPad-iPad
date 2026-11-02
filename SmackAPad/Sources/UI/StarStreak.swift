/// Qualifying passes for the three lesson stars. A weaker pass only adds nothing;
/// it never takes earned credit away. Counts survive STOP, START and leaving the
/// lesson until the app quits (the original tool also keeps credit in Learning mode).
struct StarStreak {
    private static var saved: [Int: StarStreak] = [:]
    static func restore(lessonId: Int) -> StarStreak { saved[lessonId] ?? StarStreak() }
    static func keep(_ streak: StarStreak, lessonId: Int) { saved[lessonId] = streak }
    static func forgetAll() { saved = [:] }

    static let minimumHitsPerStar = 16
    private(set) var passedRuns = 0
    private(set) var masteryRuns = 0
    private(set) var memoryRuns = 0

    mutating func reset() {
        passedRuns = 0
        masteryRuns = 0
        memoryRuns = 0
    }

    static func requiredRuns(expectedHits: Int, isIntro: Bool = false) -> Int {
        let runs = min(4, (minimumHitsPerStar - 1) / max(1, expectedHits) + 1)
        return isIntro ? max(runs, 3) : runs
    }

    /// `passedRequired` is the shorter requirement for the first star (the intro minimum
    /// of three runs applies only to goal tempo and from memory, as in the original tool).
    mutating func record(passed: Bool, mastery: Bool, memory: Bool,
                         requiredRuns: Int, passedRequired: Int? = nil) -> (passed: Bool, mastery: Bool, memory: Bool) {
        let passedNeeded = passedRequired ?? requiredRuns
        passedRuns = passed ? min(passedNeeded, passedRuns + 1) : passedRuns
        masteryRuns = mastery ? min(requiredRuns, masteryRuns + 1) : masteryRuns
        memoryRuns = memory ? min(requiredRuns, memoryRuns + 1) : memoryRuns
        return (passedRuns >= passedNeeded, masteryRuns >= requiredRuns, memoryRuns >= requiredRuns)
    }
}
