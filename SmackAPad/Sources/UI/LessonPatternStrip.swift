import SwiftUI

/// A compact 16-step sequencer strip showing the rhythm pattern of a lesson's first bar.
struct LessonPatternStrip: View {
    let hits: [LessonHit]
    var dimmed: Bool = false

    private static let cellSize: CGFloat = 6
    private static let cellGap: CGFloat = 2
    private static let beatGap: CGFloat = 2
    private static let totalWidth: CGFloat = 132 // 16 * 6 + 15 * 2 + 3 * 2

    private struct RowData {
        let padIndex: Int
        let hitSteps: Set<Int>
    }

    private let rows: [RowData]
    private let height: CGFloat

    init(hits: [LessonHit], dimmed: Bool = false) {
        self.hits = hits
        self.dimmed = dimmed

        let barHits = hits.filter { $0.step >= 0 && $0.step < 16 }
        var counts: [Int: Int] = [:]
        var stepMap: [Int: Set<Int>] = [:]
        for hit in barHits {
            counts[hit.padIndex, default: 0] += 1
            stepMap[hit.padIndex, default: []].insert(hit.step)
        }

        // Distinct padIndex values in the first bar, ordered by frequency (most first), at most 3 rows.
        let sortedPads = counts.keys.sorted {
            let c0 = counts[$0]!
            let c1 = counts[$1]!
            if c0 != c1 { return c0 > c1 }
            return $0 < $1
        }
        let activePads = Array(sortedPads.prefix(3))
        self.rows = activePads.map { RowData(padIndex: $0, hitSteps: stepMap[$0] ?? []) }

        if activePads.isEmpty {
            self.height = 0
        } else {
            let count = CGFloat(activePads.count)
            self.height = count * Self.cellSize + (count - 1) * Self.cellGap
        }
    }

    var body: some View {
        Canvas { context, _ in
            let hitColor = dimmed ? Theme.secondary : Theme.ink
            for (rowIndex, row) in rows.enumerated() {
                let y = CGFloat(rowIndex) * (Self.cellSize + Self.cellGap)
                for step in 0..<16 {
                    let beatOffset = CGFloat(step / 4) * Self.beatGap
                    let x = CGFloat(step) * (Self.cellSize + Self.cellGap) + beatOffset
                    let rect = CGRect(x: x, y: y, width: Self.cellSize, height: Self.cellSize)
                    let path = Path(roundedRect: rect, cornerRadius: 1)
                    let isHit = row.hitSteps.contains(step)
                    context.fill(path, with: .color(isHit ? hitColor : Theme.hairline))
                }
            }
        }
        .frame(width: Self.totalWidth, height: height)
        .accessibilityHidden(true)
    }
}
