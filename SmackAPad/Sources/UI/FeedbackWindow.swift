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
