/// Session-only consecutive qualifying passes for the three lesson stars.
struct StarStreak {
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

    mutating func record(passed: Bool, mastery: Bool, memory: Bool,
                         requiredRuns: Int) -> (passed: Bool, mastery: Bool, memory: Bool) {
        passedRuns = passed ? min(requiredRuns, passedRuns + 1) : 0
        masteryRuns = mastery ? min(requiredRuns, masteryRuns + 1) : 0
        memoryRuns = memory ? min(requiredRuns, memoryRuns + 1) : 0
        return (passedRuns >= requiredRuns, masteryRuns >= requiredRuns, memoryRuns >= requiredRuns)
    }
}
