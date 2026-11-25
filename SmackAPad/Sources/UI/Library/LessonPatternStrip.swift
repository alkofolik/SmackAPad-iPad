import AVFoundation
import SwiftUI

/// A compact 16-step sequencer strip showing the rhythm pattern of a lesson's first bar,
/// with an optional live orange playhead and active-step highlight during audio preview.
struct LessonPatternStrip: View {
    let hits: [LessonHit]
    var dimmed: Bool = false
    var isPlaying: Bool = false
    var anchorHostTime: UInt64 = 0
    var secondsPerStep: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduced

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

    init(
        hits: [LessonHit],
        dimmed: Bool = false,
        isPlaying: Bool = false,
        anchorHostTime: UInt64 = 0,
        secondsPerStep: Double = 0
    ) {
        self.hits = hits
        self.dimmed = dimmed
        self.isPlaying = isPlaying
        self.anchorHostTime = anchorHostTime
        self.secondsPerStep = secondsPerStep

        let barHits = hits.filter { $0.step >= 0 && $0.step < 16 }
        var counts: [Int: Int] = [:]
        var stepMap: [Int: Set<Int>] = [:]
        for hit in barHits {
            counts[hit.padIndex, default: 0] += 1
            stepMap[hit.padIndex, default: []].insert(hit.step)
        }

        // Distinct padIndex values in the first bar, taking the 3 most used pads, ordered by PadVoice.rowOrder.
        let mostUsedPads = counts.keys.sorted {
            let c0 = counts[$0]!
            let c1 = counts[$1]!
            if c0 != c1 { return c0 > c1 }
            return $0 < $1
        }.prefix(3)
        let mostUsedSet = Set(mostUsedPads)
        let activePads = PadVoice.rowOrder.filter { mostUsedSet.contains($0) }
        self.rows = activePads.map { RowData(padIndex: $0, hitSteps: stepMap[$0] ?? []) }

        if activePads.isEmpty {
            self.height = 0
        } else {
            let count = CGFloat(activePads.count)
            self.height = count * Self.cellSize + (count - 1) * Self.cellGap
        }
    }

    var body: some View {
        Group {
            if isPlaying {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { _ in
                    stripCanvas(barStepProgress: currentBarStepProgress())
                }
            } else {
                stripCanvas(barStepProgress: nil)
            }
        }
        .frame(width: Self.totalWidth, height: height)
        .accessibilityHidden(true)
    }

    private func currentBarStepProgress() -> Double? {
        guard isPlaying, anchorHostTime > 0, secondsPerStep > 0 else { return nil }
        let nowSeconds = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let anchorSeconds = AVAudioTime.seconds(forHostTime: anchorHostTime)
        let elapsed = nowSeconds - anchorSeconds
        guard elapsed >= 0 else { return nil }
        return (elapsed / secondsPerStep).truncatingRemainder(dividingBy: 16.0)
    }

    private func stripCanvas(barStepProgress: Double?) -> some View {
        Canvas { context, size in
            let hitColor = dimmed ? Theme.secondary : Theme.ink
            let activeStep = barStepProgress.map { Int(floor($0)) % 16 }

            if let activeStep, size.height > 0 {
                let colX = Self.xPosition(forStep: activeStep)
                let colRect = CGRect(x: colX - 1, y: 0, width: Self.cellSize + 2, height: size.height)
                context.fill(Path(roundedRect: colRect, cornerRadius: 1.5), with: .color(Theme.orange.opacity(0.18)))
            }

            for (rowIndex, row) in rows.enumerated() {
                let y = CGFloat(rowIndex) * (Self.cellSize + Self.cellGap)
                for step in 0..<16 {
                    let x = Self.xPosition(forStep: step)
                    let rect = CGRect(x: x, y: y, width: Self.cellSize, height: Self.cellSize)
                    let path = Path(roundedRect: rect, cornerRadius: 1)
                    let isHit = row.hitSteps.contains(step)
                    let isCurrent = activeStep == step
                    let color: Color
                    if isHit {
                        color = isCurrent ? Theme.orange : hitColor
                    } else {
                        color = isCurrent ? Theme.orange.opacity(0.28) : Theme.hairline
                    }
                    context.fill(path, with: .color(color))
                }
            }

            if let barStepProgress, size.height > 0 {
                let stepValue = reduced ? Double(Int(floor(barStepProgress)) % 16) : barStepProgress
                let playheadX = Self.playheadX(forStepProgress: stepValue)
                let playheadRect = CGRect(x: playheadX, y: 0, width: 2, height: size.height)
                context.fill(Path(roundedRect: playheadRect, cornerRadius: 1), with: .color(Theme.orange))
            }
        }
    }

    private static func xPosition(forStep step: Int) -> CGFloat {
        let beatOffset = CGFloat(step / 4) * beatGap
        return CGFloat(step) * (cellSize + cellGap) + beatOffset
    }

    private static func playheadX(forStepProgress progress: Double) -> CGFloat {
        let clamped = max(0, min(15.999, progress))
        let stepIndex = Int(floor(clamped))
        let fraction = clamped - Double(stepIndex)
        let base = xPosition(forStep: stepIndex)
        return min(totalWidth - 2, base + CGFloat(fraction) * (cellSize + cellGap))
    }
}
