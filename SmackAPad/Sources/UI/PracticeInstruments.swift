import SwiftUI
import UIKit

/// Measurements and colours from the approved Cut Tape B source.
/// Kept local to practice so the library and settings retain their own styling.
enum PracticeBandStyle {
    static let showPadLabels = true
    static let rowGap: CGFloat = 8
    static let orange = Color(red: 1, green: 120.0 / 255, blue: 0)

    static func hitColor(_ mark: HitMark) -> Color {
        switch mark {
        case .correct: return Color(red: 1, green: 224.0 / 255, blue: 194.0 / 255)
        case .off: return Color(red: 1, green: 181.0 / 255, blue: 116.0 / 255)
        case .wrong: return Color(red: 212.0 / 255, green: 79.0 / 255, blue: 0)
        }
    }

    static let minRowHeight: CGFloat = 36
    static let maxRowHeight: CGFloat = 74
    static let baseRowHeight: CGFloat = 44

    static func unscaledHeight(rows: Int) -> CGFloat {
        80 + CGFloat(max(1, rows)) * baseRowHeight + CGFloat(max(0, rows - 1)) * rowGap
    }

    /// Computes the proportional row height for a given lane count and available vertical space.
    static func rowHeight(rows: Int, availableHeight: CGFloat, minMargin: CGFloat = 40) -> CGFloat {
        let maxBandHeight = max(160, availableHeight - 2 * minMargin)
        let unscaled = unscaledHeight(rows: rows)
        let fitHeight = maxBandHeight * (baseRowHeight / unscaled)
        return min(maxRowHeight, max(minRowHeight, fitHeight))
    }

    /// Computes the vertical scale factor (rowHeight / baseRowHeight).
    static func scale(rows: Int, availableHeight: CGFloat, minMargin: CGFloat = 40) -> CGFloat {
        rowHeight(rows: rows, availableHeight: availableHeight, minMargin: minMargin) / baseRowHeight
    }

    /// Band height computed from the lane count and the available vertical space.
    static func bandHeight(rows: Int, availableHeight: CGFloat, minMargin: CGFloat = 40) -> CGFloat {
        let s = scale(rows: rows, availableHeight: availableHeight, minMargin: minMargin)
        let height = unscaledHeight(rows: rows) * s
        return min(height, availableHeight)
    }

    /// Minimum height of the band at a given scale.
    static func minimumHeight(rows: Int, scale: CGFloat = 1) -> CGFloat {
        unscaledHeight(rows: rows) * scale
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
}

/// A quiet signed timing cue, with early hits on the left and late hits on the right.
struct TimingCue: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(SettingsManager.self) private var settings

    let offset: Double
    var active = true

    private var timingKey: String {
        if offset < 0 { return "Early" }
        if offset > 0 { return "Late" }
        return "On time"
    }

    var body: some View {
        ZStack {
            Capsule()
                .fill(Theme.surface)
                .overlay { Capsule().strokeBorder(Theme.hairline, lineWidth: 1) }

            ForEach([-10.0, 10.0], id: \.self) { mark in
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(width: 1, height: 6)
                    .offset(x: mark)
            }

            Rectangle()
                .fill(Theme.secondary)
                .frame(width: 1.5, height: 10)

            Capsule()
                .fill(offset == 0 ? Theme.orange : Theme.ink)
                .frame(width: 8, height: 10)
                .offset(x: offset * 36)
                .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.78),
                           value: offset)
        }
        .frame(width: 88, height: 16)
        .opacity(active ? 1 : 0.35)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("Hit timing"))
        .accessibilityValue(settings.localized(timingKey))
        .accessibilityHidden(!active)
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

/// A small chip showing the result of one finished run.
struct RunResultChip: View {
    let run: PracticeRunResult

    var body: some View {
        HStack(spacing: Theme.Space.small) {
            verdictMark
            VStack(alignment: .leading, spacing: 1) {
                Text("\(Int((run.score * 100).rounded()))\u{00a0}%")
                    .font(Theme.strong(16))
                    .monospacedDigit()
                    .lineLimit(1)
                Text("\(run.bpm)\u{00a0}BPM")
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Space.small)
        .frame(width: 96, height: 48)
        .background(Theme.surface, in: Rectangle())
        .overlay(
            Rectangle()
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    private var verdictMark: some View {
        ZStack {
            if run.passed {
                Rectangle()
                    .fill(Theme.orange)
                    .frame(width: 5, height: 24)
            } else {
                Rectangle()
                    .strokeBorder(Theme.markWrong, lineWidth: 1.5)
                    .frame(width: 5, height: 24)
            }
        }
        .frame(width: 5, height: 24)
    }
}

/// A single chip showing only the last finished run while playing.
struct PlayingLastRunChip: View {
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(SettingsManager.self) private var settings
    let lastRun: PracticeRunResult?

    var body: some View {
        ZStack {
            if let lastRun {
                RunResultChip(run: lastRun)
                    .id(lastRun.id)
                    .transition(reduced ? .identity : .opacity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(settings.localized(
                        "Last run %lld percent, %lld BPM, %@",
                        Int((lastRun.score * 100).rounded()),
                        lastRun.bpm,
                        settings.localized(lastRun.passed ? "passed" : "not passed")
                    ))
            }
        }
        .frame(width: 96, height: 48)
        .animation(reduced ? nil : .easeInOut(duration: 0.3), value: lastRun?.id)
    }
}

/// Chip showing the current memory fade phase (Pass 1 · notes shown / Pass 2 · notes fading) in place of the run meter.
struct MemoryPhaseChip: View {
    let phase: String

    var body: some View {
        Text(phase)
            .font(Theme.control)
            .foregroundStyle(Theme.ink)
            .lineLimit(1)
            .padding(.horizontal, Theme.Space.small)
            .frame(height: 48)
            .background(Theme.surface, in: Rectangle())
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(phase)
    }
}

/// Result card taking the left two thirds of the bottom zone after STOP.
struct ResultCard: View {
    @Environment(SettingsManager.self) private var settings
    let summary: RunSummary
    let runs: [PracticeRunResult]
    let saved: LessonProgress?
    let event: StarEvent?
    let announcement: String
    var reviewMessage: String? = nil
    var badgeText: String? = nil
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let openRules: () -> Void
    let openSessionResults: () -> Void
    var starRulesAttachment: AnyView? = nil

    private var scorePercent: Int {
        Int((summary.score * 100).rounded())
    }

    private var bestPercent: Int {
        let bestScore = runs.map(\.score).max() ?? summary.score
        return Int((bestScore * 100).rounded())
    }

    private var starCount: Int {
        [saved?.passed == true, saved?.mastery == true, saved?.memory == true].filter { $0 }.count
    }

    private var runSummaryText: String {
        let count = runs.count
        if settings.languagePreference == .czech {
            let runsWord: String
            if count == 1 {
                runsWord = "1 běh"
            } else if count >= 2 && count <= 4 {
                runsWord = "\(count) běhy"
            } else {
                runsWord = "\(count) běhů"
            }
            return "\(runsWord) · nejlepší \(bestPercent)\u{00a0}%"
        } else {
            let runsWord = count == 1 ? "1 run" : "\(count) runs"
            return "\(runsWord) · best \(bestPercent)%"
        }
    }

    private var voiceOverLabel: String {
        let count = runs.count
        let runPart: String
        let noticePart: String = {
            if let badgeText { return ", " + badgeText }
            if saved?.memory != true && (saved?.mastery == true || summary.mastery) {
                return ", " + StarRequirement.requirementText(for: 2, progress: saved, language: settings.languagePreference)
            }
            return ""
        }()
        if settings.languagePreference == .czech {
            let runsWord: String
            if count == 1 {
                runsWord = "1 běh"
            } else if count >= 2 && count <= 4 {
                runsWord = "\(count) běhy"
            } else {
                runsWord = "\(count) běhů"
            }
            runPart = "\(runsWord), nejlepší \(bestPercent) procent"
            return "Výsledek \(scorePercent) procent, \(starCount) ze 3 hvězd\(noticePart), \(runPart)"
        } else {
            let runsWord = count == 1 ? "1 run" : "\(count) runs"
            runPart = "\(runsWord), best \(bestPercent) percent"
            return "Result \(scorePercent) percent, \(starCount) of 3 stars\(noticePart), \(runPart)"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            if let reviewMessage {
                Text(reviewMessage)
                    .font(Theme.display(22))
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: Theme.Space.regular) {
                scoreColumn
                Spacer(minLength: 0)
                starsColumn
                Spacer(minLength: 0)
                runSummaryColumn
            }
        }
        .padding(.horizontal, Theme.Space.regular)
        .frame(width: cardWidth, height: cardHeight)
        .satinPlate()
        .contentShape(RoundedRectangle(cornerRadius: Theme.Skin.Plate.radius))
        .onTapGesture {
            openSessionResults()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([reviewMessage, voiceOverLabel].compactMap { $0 }.joined(separator: ". "))
        .accessibilityHint(settings.localized("Shows all runs"))
        .accessibilityAction(named: settings.localized("Star requirements")) {
            openRules()
        }
        .task {
            if event == nil, !announcement.isEmpty {
                UIAccessibility.post(notification: .announcement, argument: announcement)
            }
        }
    }

    private var scoreColumn: some View {
        VStack(spacing: 2) {
            Text("\(scorePercent)\u{00a0}%")
                .font(Theme.display(reviewMessage == nil ? min(56, cardHeight * 0.36) : 18))
                .fontWeight(.bold)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(settings.localized("Last run"))
                .font(Theme.meta)
                .foregroundStyle(Theme.Skin.Display.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .insetDisplay()
    }

    private var starsColumn: some View {
        VStack(spacing: 2) {
            Button(action: openRules) {
                HStack(spacing: Theme.Space.tight) {
                    if saved?.reviewSchedule.isSettled == true {
                        Image(systemName: "checkmark")
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                            .accessibilityLabel(settings.localized("Settled"))
                    }
                    StarBurst(
                        earned: [saved?.passed == true, saved?.mastery == true, saved?.memory == true],
                        event: event,
                        announcement: announcement
                    )
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background {
                if let starRulesAttachment {
                    starRulesAttachment
                }
            }

            if let badgeText {
                Text(badgeText)
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
            } else if saved?.memory != true && (saved?.mastery == true || summary.mastery) {
                Text(StarRequirement.requirementText(for: 2, progress: saved, language: settings.languagePreference))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    private var runSummaryColumn: some View {
        HStack(spacing: Theme.Space.tight) {
            Text(runSummaryText)
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
            Image(systemName: "chevron.right")
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
        }
    }
}

/// Offered after the 2nd star while the 3rd is missing: one tap starts Play from memory.
struct MemoryChallengeButtonStyle: ButtonStyle {
    var customHeight: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.action)
            .foregroundStyle(Theme.black)
            .lineLimit(1)
            .padding(.horizontal, Theme.Space.regular)
            .frame(height: customHeight)
            .frame(minHeight: customHeight == nil ? Theme.Size.control : nil)
            .background(PracticeBandStyle.orange.opacity(configuration.isPressed ? 0.8 : 1))
            .overlay(Rectangle().stroke(Theme.ink, lineWidth: Theme.Size.border))
            .opacity(configuration.isPressed ? 0.65 : 1)
            .contentShape(Rectangle())
            .motion(value: configuration.isPressed)
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
            .background(Theme.background, in: Rectangle())
            .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: Theme.Size.border))
            .opacity(configuration.isPressed ? 0.65 : 1)
            .fixedSize(horizontal: true, vertical: false)
    }
}

/// Three LEDs per qualifying run, stacked from the bottom as the tape advances.
struct RunMeterView: View {
    @Environment(SettingsManager.self) private var settings

    let progress: (count: Int, required: Int, name: String, starIndex: Int)
    let fraction: Double
    let verdict: RunVerdict?
    let starMomentActive: Bool

    @State private var flashingOutline = false

    static func litMicroSteps(fraction: Double) -> Int {
        Int(min(1, max(0, fraction)) * 3)
    }

    var body: some View {
        HStack(spacing: Theme.Space.small) {
            HStack(spacing: Theme.Space.tight) {
                Image(systemName: "star.fill")
                Text("\(progress.starIndex + 1)").monospacedDigit()
            }
            .font(Theme.meta)
            .foregroundStyle(starMomentActive ? Theme.orange : Theme.ink)
            .padding(.horizontal, Theme.Space.small)
            .frame(height: 24)
            .background(Theme.surface, in: Capsule())
            .overlay { Capsule().strokeBorder(Theme.hairline, lineWidth: 1) }

            HStack(spacing: Theme.Space.tight) {
                ForEach(0..<progress.required, id: \.self) { index in
                    runBlock(index: index)
                }
            }
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("Consecutive passes for %@", settings.localized(progress.name)))
        .accessibilityValue(settings.localized("%lld of %lld", progress.count, progress.required))
        .task(id: verdict?.id) {
            flashingOutline = verdict?.brokenStreak == true
            guard flashingOutline else { return }
            do { try await Task.sleep(for: .milliseconds(200)) } catch { return }
            withAnimation(.easeOut(duration: 0.20)) { flashingOutline = false }
        }
    }

    private func runBlock(index: Int) -> some View {
        let banked = index < progress.count
        let lit = banked ? 3 : (index == progress.count ? Self.litMicroSteps(fraction: fraction) : 0)
        return VStack(spacing: 2) {
            ForEach((0..<3).reversed(), id: \.self) { step in
                Rectangle()
                    .fill(Theme.hairline)
                    .overlay {
                        Rectangle()
                            .fill(banked && starMomentActive ? Theme.orange : Theme.ink)
                            .opacity(step < lit ? 1 : 0)
                    }
            }
        }
        .padding(2)
        .frame(width: 14, height: 24)
        .background(Theme.surface)
        .animation(verdict?.passed == true ? Theme.Motion.fast : .easeOut(duration: 0.20),
                   value: verdict?.id)
        .overlay {
            Rectangle().strokeBorder(flashingOutline ? Theme.markWrong : Theme.hairline, lineWidth: 1)
        }
    }
}
