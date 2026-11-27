import Foundation

struct BossAttempt {
    let encounter: BossEncounter
    let gentle: Bool
    private(set) var stamina: Int
    private(set) var judgedBars = 0

    init(encounter: BossEncounter, gentle: Bool = false) {
        self.encounter = encounter
        self.gentle = gentle
        stamina = encounter.stamina
    }

    var finished: Bool { judgedBars == encounter.bars }
    var won: Bool { finished && stamina == 0 }
    var veilBars: Set<Int> { gentle ? [] : encounter.veilBars }

    func warnsDuring(bar: Int) -> Bool { veilBars.contains(bar + 1) }

    mutating func judgeBars(elapsed: Double, secondsPerBar: Double, lateWindow: Double,
                            isClean: (Int) -> Bool) {
        while !finished && elapsed > Double(judgedBars + 1) * secondsPerBar + lateWindow {
            if isClean(judgedBars) { stamina = max(0, stamina - 1) }
            judgedBars += 1
        }
    }

    static func isClean(bar: Int, cycle: Int, hits: [LessonHit],
                        judgments: [LessonHit: HitJudgment], playedHits: [PlayedHit]) -> Bool {
        let steps = bar * 16..<(bar + 1) * 16
        let allNotesClean = hits.lazy.filter { steps.contains($0.step) }.allSatisfy {
            judgments[$0] == .perfect || judgments[$0] == .good
        }
        return allNotesClean && !playedHits.contains {
            $0.pass == cycle && $0.mark == .wrong && $0.step >= Double(steps.lowerBound)
                && $0.step < Double(steps.upperBound)
        }
    }
}
