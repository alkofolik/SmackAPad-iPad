import Foundation

/// Bounded presentation history; signed deviations come directly from scoring.
struct TimingHistory {
    struct Sample {
        let errorMilliseconds: Double
        let maximumMilliseconds: Double
        let goodMilliseconds: Double
        let date: Date

        var isGood: Bool { abs(errorMilliseconds) <= goodMilliseconds }
        var normalized: Double { min(1, max(-1, errorMilliseconds / maximumMilliseconds)) }
    }

    private(set) var samples: [Sample] = []

    mutating func record(errorMilliseconds: Double, maximumMilliseconds: Double,
                         goodMilliseconds: Double, date: Date = Date()) {
        samples.append(Sample(errorMilliseconds: errorMilliseconds,
                              maximumMilliseconds: maximumMilliseconds,
                              goodMilliseconds: goodMilliseconds, date: date))
        if samples.count > 32 { samples.removeFirst(samples.count - 32) }
    }

    func cueOffset(at date: Date) -> Double {
        let recent = samples.filter { date.timeIntervalSince($0.date) < 3 }.suffix(8)
        guard recent.count >= 3, let latest = recent.last else { return 0 }
        let deadband = latest.goodMilliseconds * 0.4
        let travel = latest.maximumMilliseconds - deadband
        guard travel > 0 else { return 0 }
        let sorted = recent.map(\.errorMilliseconds).sorted()
        let middle = sorted.count / 2
        let median = sorted.count.isMultiple(of: 2)
            ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
        guard abs(median) > deadband else { return 0 }
        let offset = min(1, (abs(median) - deadband) / travel)
        return median < 0 ? -offset : offset
    }
}

/// Presentation policy shared by expected notes and played hits in both pattern views.
/// Pass identity is preserved even when the same note appears in adjacent repeats.
enum FeedbackWindow {
    static let trailingSteps = 4.0
    static let fadeSeconds = 0.25

    static func strength(recordedPass: Int, step: Double, pass: Int, position: Double,
                         totalSteps: Int, bpm: Int, reduceMotion: Bool) -> Double {
        guard step >= 0, step < Double(totalSteps) else { return 0 }
        if recordedPass == pass { return 1 }
        guard pass > 1, recordedPass == pass - 1,
              step >= Double(totalSteps) - trailingSteps else { return 0 }
        if position < trailingSteps { return 1 }
        guard !reduceMotion else { return 0 }
        let elapsed = (position - trailingSteps) * 15 / Double(max(1, bpm))
        return max(0, 1 - elapsed / fadeSeconds)
    }

    static func visibleJudgments(_ history: [Int: [LessonHit: HitJudgment]], pass: Int,
                                 position: Double, totalSteps: Int, bpm: Int,
                                 reduceMotion: Bool) -> [Int: [LessonHit: HitJudgment]] {
        history.reduce(into: [:]) { visible, entry in
            let notes = entry.value.filter {
                strength(recordedPass: entry.key, step: Double($0.key.step), pass: pass,
                         position: position, totalSteps: totalSteps, bpm: bpm,
                         reduceMotion: reduceMotion) > 0
            }
            if !notes.isEmpty { visible[entry.key] = notes }
        }
    }
}
