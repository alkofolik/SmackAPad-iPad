import SwiftUI
import UIKit

/// Measurements and colours from the approved Cut Tape B source.
/// Kept local to practice so the library and settings retain their own styling.
enum PracticeBandStyle {
    static let showPadLabels = true
    static let radius: CGFloat = 28
    static let rowGap: CGFloat = 8
    static let orange = Color(red: 1, green: 120.0 / 255, blue: 0)

    static func hitColor(_ mark: HitMark) -> Color {
        switch mark {
        case .correct: return Color(red: 1, green: 224.0 / 255, blue: 194.0 / 255)
        case .off: return Color(red: 1, green: 181.0 / 255, blue: 116.0 / 255)
        case .wrong: return Color(red: 212.0 / 255, green: 79.0 / 255, blue: 0)
        }
    }

    /// Rows may shrink to 44 points; smaller viewports scroll inside the band.
    static func minimumHeight(rows: Int, scale: CGFloat = 1) -> CGFloat {
        max(160, 80 + CGFloat(max(1, rows)) * 44 + CGFloat(max(0, rows - 1)) * rowGap) * scale
    }

    private static let padWidths: [Int: CGFloat] = {
        let font = UIFont(name: "IBMPlexSans-Bold", size: 32)!
        return Dictionary(uniqueKeysWithValues: PadVoice.abbreviations.indices.map {
            ($0, (PadVoice.abbreviation($0) as NSString).size(withAttributes: [.font: font]).width)
        })
    }()

    static func cellWidth(rows: [Int], scale: CGFloat) -> CGFloat {
        let widest = rows.compactMap { padWidths[$0] }.max() ?? 47
        return max(60, ceil((widest + 4) / 0.84)) * scale
    }

    static func barWidth(rows: [Int], scale: CGFloat) -> CGFloat {
        96 * scale + 16 * cellWidth(rows: rows, scale: scale)
    }
}

/// The orange band's tone carries ambient information that never needs reading:
/// the mode (Listen, Play, From memory) and how close the tempo is to the goal.
enum BandTone {
    private typealias RGB = (r: Double, g: Double, b: Double)

    private static let listen: [RGB] = [(255, 177, 108), (242, 152, 74), (231, 122, 33)]
    private static let play: [RGB] = [(255, 148, 47), (255, 120, 0), (229, 94, 0)]
    private static let memory: [RGB] = [(248, 120, 0), (231, 100, 0), (217, 86, 0)]

    static func color(listen isListen: Bool, memory: Bool, bpm: Int, startBpm: Int, targetBpm: Int) -> Color {
        let span = Double(targetBpm - startBpm)
        let fraction = span > 0 ? min(1, max(0, Double(bpm - startBpm) / span)) : 1
        let stops = isListen ? listen : (memory ? Self.memory : play)
        // The illustrated middle stop is 88 BPM within the 75–100 BPM range.
        let midpoint = 13.0 / 25
        let low = fraction <= midpoint ? stops[0] : stops[1]
        let high = fraction <= midpoint ? stops[1] : stops[2]
        let blend = fraction <= midpoint ? fraction / midpoint : (fraction - midpoint) / (1 - midpoint)
        return rgb((low.r + (high.r - low.r) * blend,
                    low.g + (high.g - low.g) * blend,
                    low.b + (high.b - low.b) * blend))
    }

    private static func rgb(_ value: RGB) -> Color {
        Color(red: value.r / 255, green: value.g / 255, blue: value.b / 255)
    }

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
            LinearGradient(colors: [Theme.white.opacity(0.82 * max(0, tendency)), .clear],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: 78)
            Spacer(minLength: 0)
            LinearGradient(colors: [.clear, Theme.white.opacity(0.82 * max(0, -tendency))],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: 78)
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
                    .font(Theme.mainValue).monospacedDigit()
                    .contentTransition(motion.numeric).motion(value: bpm)
                VStack(alignment: .leading, spacing: 0) {
                    Text("BPM").font(Theme.text(22))
                    Text("→ \(targetBpm)").font(Theme.meta).monospacedDigit().foregroundStyle(Theme.secondary)
                }
                Image(systemName: "chevron.down")
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
                    .opacity(editable ? 1 : 0)
            }
            .padding(.horizontal, Theme.Space.regular - 2)
            .padding(.vertical, Theme.Space.tight)
            .frame(minHeight: InstrumentTile.height)
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
    static let height: CGFloat = 80
}

/// Shown only after a run ends. The next action is supplied by the screen's existing eligibility rules.
struct ResultCard<Action: View>: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.dynamicTypeSize) private var dynamicType
    let summary: RunSummary
    let saved: LessonProgress?
    let event: StarEvent?
    let announcement: String
    let detail: () -> Void
    let rules: () -> Void
    @ViewBuilder let nextAction: () -> Action

    var body: some View {
        ViewThatFits(in: .horizontal) {
            if !dynamicType.isAccessibilitySize {
                HStack(spacing: Theme.Space.small) {
                    accuracy
                    starControls
                    Spacer(minLength: 0)
                    nextAction()
                }
            }
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Space.small) { accuracy; Spacer(minLength: 0); starControls }
                    VStack(alignment: .leading, spacing: Theme.Space.small) { accuracy; starControls }
                }
                HStack { Spacer(minLength: 0); nextAction() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var accuracy: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Measure the widest value using the same face and size as the real value.
            // The entire percentage is a single, indivisible string.
            Text("100\u{00a0}%")
                .hidden()
                .overlay(alignment: .leading) {
                    Text("\(Int((summary.score * 100).rounded()))\u{00a0}%")
                        .accessibilityLabel(settings.localized("Last run"))
                        .accessibilityValue("\(Int((summary.score * 100).rounded())) %")
                }
                .font(Theme.mainValue)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            Text(settings.localized("Last run"))
                .font(Theme.meta)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .fixedSize(horizontal: true, vertical: true)
    }

    private var starControls: some View {
        HStack(spacing: Theme.Space.small) {
            Button(action: rules) {
                StarBurst(earned: [saved?.passed == true, saved?.mastery == true, saved?.memory == true],
                          event: event, announcement: announcement)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(settings.localized("Lesson stars"))
            .accessibilityValue(settings.localized("%lld of 3 stars", starCount))
            .accessibilityHint(settings.localized("Star requirements"))
            .highPriorityGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in rules() })
            Button(action: detail) {
                PracticeDetailIcon()
                    .stroke(Theme.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 32, height: 32)
                    .frame(width: 56, height: 56)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(settings.localized("Detail"))
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var starCount: Int {
        [saved?.passed == true, saved?.mastery == true, saved?.memory == true].filter { $0 }.count
    }
}

/// The 30-point line icon from the approved source, with an exact two-point stroke.
private struct PracticeDetailIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLines([CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY)])
        path.move(to: CGPoint(x: rect.minX + 5, y: rect.minY + 21))
        path.addLines([CGPoint(x: rect.minX + 12, y: rect.minY + 13),
                       CGPoint(x: rect.minX + 19, y: rect.minY + 17),
                       CGPoint(x: rect.minX + 28, y: rect.minY + 3)])
        return path
    }
}

/// Offered after the 2nd star while the 3rd is missing: one tap starts Play from memory.
struct MemoryChallengeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.action)
            .foregroundStyle(Theme.black)
            .lineLimit(1)
            .padding(.horizontal, Theme.Space.regular)
            .frame(minHeight: Theme.Size.rowLarge)
            .background(PracticeBandStyle.orange.opacity(configuration.isPressed ? 0.8 : 1),
                        in: RoundedRectangle(cornerRadius: Theme.Radius.pad))
            .fixedSize(horizontal: true, vertical: false)
    }
}

/// The result action uses the same rounded outline as the approved result row.
struct PracticeNextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.navigation)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, Theme.Space.regular)
            .frame(minHeight: Theme.Size.rowLarge)
            .background(Theme.background, in: RoundedRectangle(cornerRadius: Theme.Radius.pad))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.pad).strokeBorder(Theme.ink, lineWidth: Theme.Size.border))
            .opacity(configuration.isPressed ? 0.65 : 1)
            .fixedSize(horizontal: true, vertical: false)
    }
}
