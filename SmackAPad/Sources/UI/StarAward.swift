/// Compares one completed pass with the lesson's cumulative stars.
/// Star thresholds and persistence remain the responsibility of their owners.
struct StarAward {
    let earned: [Bool]
    let fresh: [Bool]

    var shouldStop: Bool { fresh[1] || fresh[2] }

    init(previous: LessonProgress?, passed: Bool, mastery: Bool, memory: Bool) {
        let before = [previous?.passed ?? false, previous?.mastery ?? false, previous?.memory ?? false]
        let result = [passed, mastery, memory]
        earned = zip(before, result).map { $0 || $1 }
        fresh = zip(before, result).map { !$0 && $1 }
    }
}
