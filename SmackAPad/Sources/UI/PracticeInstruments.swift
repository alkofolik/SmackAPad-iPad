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
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.control)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    private var verdictMark: some View {
        ZStack {
            if run.passed {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.orange)
                    .frame(width: 5, height: 24)
            } else {
                RoundedRectangle(cornerRadius: 2)
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

/// Result card taking the left two thirds of the bottom zone after STOP.
struct ResultCard: View {
    @Environment(SettingsManager.self) private var settings
    let summary: RunSummary
    let runs: [PracticeRunResult]
    let saved: LessonProgress?
    let event: StarEvent?
    let announcement: String
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
            return "Výsledek \(scorePercent) procent, \(starCount) ze 3 hvězd, \(runPart)"
        } else {
            let runsWord = count == 1 ? "1 run" : "\(count) runs"
            runPart = "\(runsWord), best \(bestPercent) percent"
            return "Result \(scorePercent) percent, \(starCount) of 3 stars, \(runPart)"
        }
    }

    var body: some View {
        HStack(spacing: Theme.Space.regular) {
            scoreColumn

            Spacer(minLength: 0)

            starsColumn

            Spacer(minLength: 0)

            runSummaryColumn
        }
        .padding(.horizontal, Theme.Space.regular)
        .frame(width: cardWidth, height: cardHeight)
        .background(Theme.background)
        .overlay(
            Rectangle().strokeBorder(Theme.ink, lineWidth: Theme.Size.border)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            openSessionResults()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(voiceOverLabel)
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
                .font(Theme.display(min(56, cardHeight * 0.36)))
                .fontWeight(.bold)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(settings.localized("Last run"))
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
        }
    }

    private var starsColumn: some View {
        VStack(spacing: 2) {
            Button(action: openRules) {
                StarBurst(
                    earned: [saved?.passed == true, saved?.mastery == true, saved?.memory == true],
                    event: event,
                    announcement: announcement
                )
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
            .background(Theme.background, in: RoundedRectangle(cornerRadius: Theme.Radius.pad))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.pad).strokeBorder(Theme.ink, lineWidth: Theme.Size.border))
            .opacity(configuration.isPressed ? 0.65 : 1)
            .fixedSize(horizontal: true, vertical: false)
    }
}

/// Compact row of slots replacing the "1 / 3" text in the instrument row.
/// Shows runs needed for the star being worked on, with verdict flag and notch ticks.
struct LapVaultView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let progress: (count: Int, required: Int, name: String, starIndex: Int)
    let mode: PracticeMode
    let verdict: RunVerdict?
    let starEvent: StarEvent?
    let starMomentActive: Bool
    let settings: SettingsManager

    @State private var flagVerdict: Bool? = nil
    @State private var showNotch = false
    @State private var recoil = false
    @State private var starScale: CGFloat = 1.0
    @State private var starOpacity: Double = 1.0

    private var displayCount: Int {
        if starMomentActive {
            return progress.required
        }
        return progress.count
    }

    private var targetStarNumber: Int {
        min(3, max(1, progress.starIndex + 1))
    }

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .center, spacing: Theme.Space.small) {
                // Verdict flag next to slots
                verdictFlagView

                // Slots row with notch space above
                HStack(spacing: Theme.Space.tight) {
                    ForEach(0..<progress.required, id: \.self) { index in
                        vaultSlot(index: index)
                    }
                }
            }

            // Star mark under slots: 1, 2, or 3 filled star marks
            HStack(spacing: 3) {
                ForEach(0..<targetStarNumber, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(starMomentActive ? Theme.orange : Theme.ink)
                        .scaleEffect(reduceMotion ? 1.0 : starScale)
                        .opacity(starOpacity)
                }
            }
            .frame(height: 12)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("Consecutive passes for %@", settings.localized(progress.name)))
        .accessibilityValue(settings.localized("%lld of %lld", displayCount, progress.required))
        .task(id: verdict?.id) {
            guard let verdict else {
                flagVerdict = nil
                showNotch = false
                recoil = false
                return
            }
            flagVerdict = verdict.passed
            if mode == .learning && !verdict.passed {
                showNotch = true
            }
            if mode == .challenge && verdict.brokenStreak {
                if reduceMotion {
                    withAnimation(.easeInOut(duration: 0.2)) { recoil = true }
                    try? await Task.sleep(for: .milliseconds(200))
                    recoil = false
                } else {
                    withAnimation(.easeOut(duration: 0.25)) { recoil = true }
                    try? await Task.sleep(for: .milliseconds(250))
                    recoil = false
                }
            }
            try? await Task.sleep(for: .milliseconds(1200))
            flagVerdict = nil
            showNotch = false
        }
        .task(id: starMomentActive) {
            guard starMomentActive else {
                starScale = 1.0
                starOpacity = 1.0
                return
            }
            if reduceMotion {
                withAnimation(.easeInOut(duration: 0.2)) { starOpacity = 0.5 }
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation(.easeInOut(duration: 0.2)) { starOpacity = 1.0 }
            } else {
                try? await Task.sleep(for: .milliseconds(450))
                withAnimation(.easeOut(duration: 0.12)) { starScale = 1.15 }
                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(.easeInOut(duration: 0.13)) { starScale = 1.0 }
            }
        }
    }

    private var verdictFlagView: some View {
        ZStack {
            if let flagVerdict {
                if flagVerdict {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.orange)
                        .frame(width: 6, height: 24)
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(Theme.markWrong, lineWidth: 1.5)
                        .frame(width: 6, height: 24)
                }
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
                    .frame(width: 6, height: 24)
            }
        }
        .frame(width: 6, height: 24)
    }

    private func vaultSlot(index: Int) -> some View {
        let isFilled = index < displayCount
        let isNextFree = (index == progress.count)
        return VStack(spacing: 2) {
            // Quiet notch mark for uncredited run in Learning mode
            ZStack {
                if showNotch && isNextFree && mode == .learning {
                    Rectangle()
                        .fill(Theme.ink)
                        .frame(width: 1.5, height: 4)
                }
            }
            .frame(width: 24, height: 4)

            // Slot square
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.control)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.control)
                            .strokeBorder(Theme.hairline, lineWidth: 1)
                    )

                if isFilled && !recoil {
                    RoundedRectangle(cornerRadius: Theme.Radius.control)
                        .fill(starMomentActive ? Theme.orange : Theme.ink)
                        .padding(2)
                        .transition(reduceMotion ? .opacity : .scale)
                }
            }
            .frame(width: 24, height: 24)
        }
        .frame(width: 24, height: 30)
    }
}
