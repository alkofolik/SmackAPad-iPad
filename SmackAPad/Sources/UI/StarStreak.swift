/// How qualifying passes contribute toward lesson stars.
public enum PracticeMode: String, CaseIterable, Codable, Sendable {
    case learning, challenge

    var title: String {
        self == .learning ? "Learning · keep progress" : "Challenge · consecutive clean runs"
    }
    var explanation: String {
        self == .learning ? "Good passes add up. A weaker pass never takes them away." : "Each star needs its passes in a row."
    }
}

/// Independent counters; Learning credit is stored in lesson progress per pad mode.
public struct StarStreak: Codable, Equatable, Hashable, Sendable {
    /// Alternative Learning qualification; the normal score threshold remains valid too.
    static func learningPassed(score: Double, perfectOrGoodHits: Int, expectedHits: Int, errors: Int) -> Bool {
        expectedHits > 0 && score >= 0.6 &&
        Double(perfectOrGoodHits) / Double(expectedHits) >= 0.85 &&
        errors <= max(1, expectedHits / 10)
    }

    static let minimumHitsPerStar = 16
    public static func forgetAll() {}
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
                         requiredRuns: Int, passedRequired: Int? = nil, mode: PracticeMode = .learning) -> (passed: Bool, mastery: Bool, memory: Bool) {
        let passedNeeded = passedRequired ?? requiredRuns
        passedRuns = passed ? min(passedNeeded, passedRuns + 1) : (mode == .learning ? passedRuns : 0)
        masteryRuns = mastery ? min(requiredRuns, masteryRuns + 1) : (mode == .learning ? masteryRuns : 0)
        memoryRuns = memory ? min(requiredRuns, memoryRuns + 1) : (mode == .learning ? memoryRuns : 0)
        return (passedRuns >= passedNeeded, masteryRuns >= requiredRuns, memoryRuns >= requiredRuns)
    }
}
