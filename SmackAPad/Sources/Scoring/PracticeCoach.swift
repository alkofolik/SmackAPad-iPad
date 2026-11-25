/// One-tap coaching recommendation shown after a failed full run.
public enum CoachSuggestion: Equatable, Sendable {
    /// Loop a single 0-based bar at a slightly reduced tempo.
    case drillBar(barIndex: Int, drillBpm: Int)
    /// Step down tempo and replay the full lesson.
    case slowDown(targetBpm: Int)
}

/// Pure evaluator deciding whether to isolate a weak bar or step down tempo.
public enum PracticeCoach {
    public static func recommend(
        score: Double,
        totalBars: Int,
        errorsByBar: [Int: Int],
        currentBpm: Int,
        startBpm: Int,
        bpmStep: Int,
        isAfterMe: Bool,
        isMix: Bool,
        isSectionLoop: Bool,
        passes: Int = 1
    ) -> CoachSuggestion? {
        guard passes > 0,
              score < LearningRules.passMark,
              !isAfterMe,
              !isMix,
              !isSectionLoop else {
            return nil
        }

        let validErrors = errorsByBar.filter { (0..<max(0, totalBars)).contains($0.key) && $0.value > 0 }
        let totalBarErrors = validErrors.values.reduce(0, +)

        if totalBars >= 2,
           let worst = validErrors.min(by: { a, b in
               if a.value != b.value { return a.value > b.value }
               return a.key < b.key
           }),
           worst.value >= 2,
           worst.value * 2 >= totalBarErrors {
            let drillBpm = max(40, min(currentBpm, max(startBpm, currentBpm - 5)))
            return .drillBar(barIndex: worst.key, drillBpm: drillBpm)
        }

        if currentBpm > startBpm || (currentBpm == startBpm && currentBpm > 50 && totalBarErrors >= 2) {
            let targetBpm = max(40, currentBpm - max(5, bpmStep))
            return .slowDown(targetBpm: targetBpm)
        }

        return nil
    }
}
