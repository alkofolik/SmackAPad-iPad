import SwiftUI
import UIKit

/// The orange band's tone carries ambient information that never needs reading:
/// the mode (Listen, Play, From memory) and how close the tempo is to the goal.
enum BandTone {
    private typealias RGB = (r: Double, g: Double, b: Double)

    /// Listen is unscored, so it leaves the orange family for a warm neutral.
    private static let listen: RGB = (0.70, 0.64, 0.58)
    private static let playLow: RGB = (1.0, 0.56, 0.24)
    private static let playHigh: RGB = (1.0, 107.0 / 255, 0)
    private static let memoryLow: RGB = (0.86, 0.40, 0.08)
    private static let memoryHigh: RGB = (0.74, 0.29, 0.0)

    static func color(listen isListen: Bool, memory: Bool, bpm: Int, startBpm: Int, targetBpm: Int) -> Color {
        if isListen { return rgb(listen) }
        let span = Double(targetBpm - startBpm)
        let fraction = span > 0 ? min(1, max(0, Double(bpm - startBpm) / span)) : 1
        let low = memory ? memoryLow : playLow
        let high = memory ? memoryHigh : playHigh
        return rgb((low.r + (high.r - low.r) * fraction,
                    low.g + (high.g - low.g) * fraction,
                    low.b + (high.b - low.b) * fraction))
    }

    private static func rgb(_ value: RGB) -> Color { Color(red: value.r, green: value.g, blue: value.b) }

    /// Median timing of the last strikes as -1 (rushing) … 1 (dragging); 0 inside the
    /// comfortable part of the good window, or when no recent strikes exist.
    static func edgeTendency(_ history: TimingHistory, at date: Date) -> Double {
        let recent = history.samples.suffix(8).filter { date.timeIntervalSince($0.date) < 3 }
        guard recent.count >= 3, let good = recent.last?.goodMilliseconds, good > 0 else { return 0 }
        let sorted = recent.map(\.errorMilliseconds).sorted()
        let middle = sorted.count / 2
        let median = sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
        let excess = min(1, max(0, (abs(median) - good * 0.4) / (good * 0.8)))
        // Quantised so the glow eases between a few levels instead of flickering.
        let level = (excess * 4).rounded() / 4
        return median < 0 ? -level : level
    }
}

/// Soft glow on one edge of the band: right when rushing (ahead), left when dragging.
struct BandEdgeGlow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let tendency: Double

    var body: some View {
        HStack(spacing: 0) {
            LinearGradient(colors: [Theme.white.opacity(0.55 * max(0, tendency)), .clear],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: 72)
            Spacer(minLength: 0)
            LinearGradient(colors: [.clear, Theme.white.opacity(0.55 * max(0, -tendency))],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: 72)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.6), value: tendency)
    }
}

/// Large tappable tempo readout. Opens the tempo controls while stopped.
struct TempoTile: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduced
    private var motion: Theme.Motion.Policy { .init(reduced: reduced) }
    let bpm: Int
    let targetBpm: Int
    let editable: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: Theme.Space.small + 2) {
                Text("\(bpm)")
                    .font(Theme.display(40)).monospacedDigit()
                    .contentTransition(motion.numeric).motion(value: bpm)
                VStack(alignment: .leading, spacing: 0) {
                    Text("BPM").font(Theme.display(15))
                    Text("→ \(targetBpm)").font(Theme.meta).foregroundStyle(Theme.secondary)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.secondary)
                    .opacity(editable ? 1 : 0)
            }
            .padding(.horizontal, Theme.Space.regular - 2)
            .frame(height: InstrumentTile.height)
            .overlay(Rectangle().strokeBorder(Theme.ink.opacity(editable ? 1 : 0.35), lineWidth: Theme.Size.border))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!editable)
        .accessibilityLabel(settings.localized("Tempo"))
        .accessibilityValue("\(bpm) BPM, \(settings.localized("Goal tempo")) \(targetBpm)")
    }
}

enum InstrumentTile {
    static let height: CGFloat = 64
}

/// Shown only after a run ends: score, the lesson's three stars and details.
struct ResultCard: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var revealed: Set<Int> = []
    let summary: RunSummary
    let saved: LessonProgress?
    let detail: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Space.regular) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(Int((summary.score * 100).rounded()))")
                        .font(Theme.display(40))
                        .monospacedDigit()
                    Text("%")
                        .font(Theme.display(18))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: true, vertical: false)
                Text(settings.localized("Last run"))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .fixedSize(horizontal: true, vertical: false)
            HStack(spacing: Theme.Space.tight + 2) {
                starTile(0, label: "Passed", total: saved?.passed == true, now: summary.passed)
                starTile(1, label: "Goal tempo", total: saved?.mastery == true, now: summary.mastery)
                starTile(2, label: "From memory", total: saved?.memory == true, now: summary.memory)
            }
            Button(settings.localized("Details"), action: detail)
                .font(Theme.control).underline()
                .frame(minHeight: Theme.Size.touch, alignment: .leading)
                .fixedSize(horizontal: true, vertical: false)
        }
        .task(id: summary.id) {
            revealed = []
            for index in 0..<3 {
                do { try await Task.sleep(for: Theme.Motion.starStagger) } catch { return }
                revealed.insert(index)
            }
        }
    }

    private func starTile(_ index: Int, label: String, total: Bool, now: Bool) -> some View {
        // A star earned in this run appears with the staggered reveal; older stars show at once.
        let earned = total && (!now || revealed.contains(index) || reduced)
        return VStack(spacing: Theme.Space.tight) {
            StarShape()
                .fill(earned ? Theme.orange : Color.clear)
                .overlay(StarShape().stroke(earned ? Theme.orange : Theme.ink.opacity(0.45), lineWidth: Theme.Size.border))
                .frame(width: 24, height: 24)
            Text(settings.localized(label)).font(Theme.text(11)).lineLimit(1).minimumScaleFactor(0.7)
                .foregroundStyle(earned ? Theme.background : Theme.secondary)
        }
        .frame(width: 84, height: InstrumentTile.height)
        .background(earned ? Theme.ink : Color.clear)
        .overlay(Rectangle().strokeBorder(Theme.ink.opacity(earned ? 1 : 0.35), lineWidth: Theme.Size.border))
        .motion(value: earned)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized(label))
        .accessibilityValue(settings.localized(earned ? "earned" : "not earned"))
    }
}

/// Offered after the 2nd star while the 3rd is missing: one tap starts Play from memory.
struct MemoryChallengeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.display(Theme.Size.body))
            .foregroundStyle(Theme.black)
            .lineLimit(1)
            .padding(.horizontal, Theme.Space.regular)
            .frame(minHeight: Theme.Size.touch)
            .background(Theme.orange.opacity(configuration.isPressed ? 0.8 : 1))
            .overlay(Rectangle().strokeBorder(Theme.black, lineWidth: Theme.Size.border))
            .fixedSize(horizontal: true, vertical: false)
    }
}
