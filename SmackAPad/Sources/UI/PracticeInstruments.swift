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
        let font = UIFont(name: "IBMPlexSans-Bold", size: 32) ?? .boldSystemFont(ofSize: 32)
        return Dictionary(uniqueKeysWithValues: PadVoice.abbreviations.indices.map {
            ($0, (PadVoice.abbreviation($0) as NSString).size(withAttributes: [.font: font]).width)
        })
    }()

    static func cellWidth(rows: [Int], scale: CGFloat) -> CGFloat {
        let widest = rows.compactMap { padWidths[$0] }.max() ?? 47
        return max(60, ceil((widest + 4) / 0.84)) * scale
    }

    static func bandLabelLayout(
        rows: [Int],
        availableWidth: CGFloat,
        rowHeight: CGFloat,
        barCount: Int = 1,
        maxFontSize: CGFloat = 26,
        minFontSize: CGFloat = 18,
        trailingPadding: CGFloat = 12,
        showLabels: Bool = PracticeBandStyle.showPadLabels
    ) -> BandLabelLayout {
        guard showLabels, !rows.isEmpty, availableWidth > 0 else {
            return BandLabelLayout(gutter: 0, fontSize: maxFontSize, labels: [:])
        }

        let baseNames = Dictionary(uniqueKeysWithValues: rows.map { ($0, PadVoice.displayName($0)) })
        var nameCounts: [String: Int] = [:]
        for pad in rows {
            nameCounts[baseNames[pad] ?? "", default: 0] += 1
        }
        let rawLabels = Dictionary(uniqueKeysWithValues: rows.map { pad -> (Int, String) in
            let base = baseNames[pad] ?? PadVoice.displayName(pad)
            if (nameCounts[base] ?? 0) > 1 {
                return (pad, "\(base) \(pad + 1)")
            }
            return (pad, base)
        })

        let rowCappedFont: CGFloat = switch rows.count {
        case ...3: maxFontSize
        case 4: min(maxFontSize, 22)
        case 5: min(maxFontSize, 20)
        default: min(maxFontSize, minFontSize)
        }
        let heightCappedFont = max(minFontSize, floor(rowHeight * 0.62))
        let startFont = max(minFontSize, min(rowCappedFont, heightCappedFont))

        // Keep at least ~74–78% of width for pattern bars so labels never squeeze cells.
        let maxFraction: CGFloat = barCount >= 3 ? 0.22 : 0.26
        let maxGutter = max(48, min(220, availableWidth * maxFraction))

        var chosenFont = minFontSize
        var widestAtChosen: CGFloat = 0
        var size = startFont
        while size >= minFontSize {
            let font = UIFont(name: "IBMPlexSans-Bold", size: size) ?? .boldSystemFont(ofSize: size)
            let widest = rawLabels.values.map { textWidth($0, font: font) }.max() ?? 0
            widestAtChosen = widest
            if widest + trailingPadding <= maxGutter {
                chosenFont = size
                break
            }
            if size == minFontSize { break }
            size = max(minFontSize, size - 0.5)
        }

        let font = UIFont(name: "IBMPlexSans-Bold", size: chosenFont) ?? .boldSystemFont(ofSize: chosenFont)
        let fittedGutter = ceil(widestAtChosen + trailingPadding)
        if fittedGutter <= maxGutter {
            return BandLabelLayout(gutter: fittedGutter, fontSize: chosenFont, labels: rawLabels)
        }

        let maxTextWidth = max(12, floor(maxGutter - trailingPadding))
        let truncatedLabels = rawLabels.mapValues { truncate($0, maxWidth: maxTextWidth, font: font) }
        return BandLabelLayout(gutter: floor(maxGutter), fontSize: chosenFont, labels: truncatedLabels)
    }

    private static func textWidth(_ string: String, font: UIFont) -> CGFloat {
        (string as NSString).size(withAttributes: [.font: font]).width
    }

    private static func truncate(_ string: String, maxWidth: CGFloat, font: UIFont) -> String {
        guard textWidth(string, font: font) > maxWidth else { return string }
        var end = string.endIndex
        while end > string.startIndex {
            end = string.index(before: end)
            let candidate = String(string[..<end]).trimmingCharacters(in: .whitespaces) + "…"
            if textWidth(candidate, font: font) <= maxWidth {
                return candidate
            }
        }
        return "…"
    }
}

struct BandLabelLayout: Equatable {
    let gutter: CGFloat
    let fontSize: CGFloat
    let labels: [Int: String]
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

    @ScaledMetric(relativeTo: .body) private var trackWidth: CGFloat = 180
    @ScaledMetric(relativeTo: .body) private var trackHeight: CGFloat = 30
    @ScaledMetric(relativeTo: .body) private var pipWidth: CGFloat = 14
    @ScaledMetric(relativeTo: .body) private var pipHeight: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var notchWidth: CGFloat = 2
    @ScaledMetric(relativeTo: .body) private var markHeight: CGFloat = 12

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

            ForEach([-1.0, 1.0], id: \.self) { side in
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(width: 1, height: markHeight)
                    .offset(x: side * trackWidth / 9)
            }

            Rectangle()
                .fill(Theme.secondary)
                .frame(width: notchWidth, height: pipHeight)

            Capsule()
                .fill(offset == 0 ? Theme.orange : Theme.ink)
                .frame(width: pipWidth, height: pipHeight)
                .offset(x: offset * (trackWidth - pipWidth) / 2)
                .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.78),
                           value: offset)
        }
        .frame(width: trackWidth, height: trackHeight)
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

/// Thin pass-progress bar displayed below the orange band across its full width.
/// At a pass boundary the completed fill fades out over 150 ms while the new fill starts from 0.
struct PassProgressBar: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let pass: Int
    let position: Double
    let bars: Int
    let active: Bool
    let date: Date

    @State private var lastPass = 1
    @State private var fadeStart: Date?

    private let fadeDuration: TimeInterval = 0.15

    var body: some View {
        let count = max(1, bars)
        let totalSteps = Double(count * 16)
        let clampedPosition = active ? min(totalSteps, max(0, position)) : 0
        let fraction = totalSteps > 0 ? min(1, max(0, clampedPosition / totalSteps)) : 0
        let oldOpacity: Double = {
            guard !reduceMotion, let start = fadeStart else { return 0 }
            let elapsed = max(0, date.timeIntervalSince(start))
            return max(0, 1 - elapsed / fadeDuration)
        }()

        Canvas { context, size in
            let trackHeight: CGFloat = 6
            let trackY = (size.height - trackHeight) / 2
            let trackRect = CGRect(x: 0, y: trackY, width: size.width, height: trackHeight)
            context.fill(Path(roundedRect: trackRect, cornerRadius: 3), with: .color(Theme.ink.opacity(0.14)))

            if oldOpacity > 0 {
                context.fill(Path(roundedRect: trackRect, cornerRadius: 3),
                             with: .color(Theme.ink.opacity(oldOpacity)))
            }

            if fraction > 0 {
                let fillWidth = max(trackHeight, size.width * fraction)
                let fillRect = CGRect(x: 0, y: trackY, width: min(size.width, fillWidth), height: trackHeight)
                context.fill(Path(roundedRect: fillRect, cornerRadius: 3), with: .color(Theme.ink))
            }

            for bar in 1..<count {
                let x = min(size.width - 2, max(0, size.width * Double(bar) / Double(count) - 1))
                let reached = Double(bar) / Double(count) <= fraction || oldOpacity > 0.35
                let tickColor = reached ? Theme.background : Theme.secondary.opacity(0.65)
                context.fill(Path(CGRect(x: x, y: 0, width: 2, height: size.height)),
                             with: .color(tickColor))
            }
        }
        .frame(height: 12)
        .onChange(of: pass) { oldValue, newValue in
            if active && !reduceMotion && newValue > oldValue {
                fadeStart = date
            } else {
                fadeStart = nil
            }
            lastPass = newValue
        }
        .onChange(of: active) { _, isActive in
            if !isActive { fadeStart = nil }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("Position in the current pass"))
        .accessibilityValue(settings.localized("Bar %lld / %lld, %lld percent",
            min(count, Int(clampedPosition) / 16 + 1), count, Int((fraction * 100).rounded())))
    }
}

/// Top-right lesson-requirements progress cluster: warm-up eyes, counted passes, and live %.
struct PracticeProgressMeter: View {
    @Environment(SettingsManager.self) private var settings

    @ScaledMetric(relativeTo: .body) private var blockHeight: CGFloat = 40
    @ScaledMetric(relativeTo: .body) private var eyeSize: CGFloat = 34

    let showWarmUps: Bool
    let completedWarmUps: Int
    let starProgress: (count: Int, required: Int, name: String, starIndex: Int)?
    let reviewProgress: (count: Int, required: Int, settled: Bool)?
    let fraction: Double
    let verdict: RunVerdict?
    let starMomentActive: Bool
    let currentAccuracy: Double?

    private var accuracyText: String {
        guard let currentAccuracy else { return "—\u{00a0}%" }
        return "\(Int((currentAccuracy * 100).rounded()))\u{00a0}%"
    }

    var body: some View {
        HStack(spacing: Theme.Space.small) {
            if showWarmUps {
                warmUpEyes
                if starProgress != nil || reviewProgress != nil {
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(width: 1, height: blockHeight * 0.65)
                        .accessibilityHidden(true)
                }
            }

            if let starProgress {
                RunMeterView(
                    progress: starProgress,
                    fraction: fraction,
                    verdict: verdict,
                    starMomentActive: starMomentActive
                )
            } else if let reviewProgress {
                RunMeterView(
                    badgeTitle: settings.localized("Review"),
                    count: reviewProgress.count,
                    required: reviewProgress.required,
                    accessibilityTarget: settings.localized("Review"),
                    fraction: fraction,
                    verdict: verdict,
                    starMomentActive: starMomentActive
                )
            }

            Text(accuracyText)
                .font(Theme.rowTitle)
                .fontWeight(.bold)
                .monospacedDigit()
                .foregroundStyle(currentAccuracy == nil ? Theme.secondary : Theme.ink)
                .frame(minWidth: 62, alignment: .trailing)
                .padding(.horizontal, Theme.Space.small)
                .frame(height: blockHeight)
                .background(Theme.surface, in: Capsule())
                .overlay { Capsule().strokeBorder(Theme.hairline, lineWidth: 1) }
                .accessibilityLabel(settings.localized("Accuracy"))
                .accessibilityValue(accuracyText)
        }
        .fixedSize()
    }

    private var warmUpEyes: some View {
        let progressText = settings.localized("%lld / %lld", completedWarmUps, LearningRules.warmUpPassesNeeded)
        return HStack(spacing: Theme.Space.tight + 2) {
            ForEach(0..<LearningRules.warmUpPassesNeeded, id: \.self) { index in
                let done = index < completedWarmUps
                Image(systemName: done ? "eye.slash.fill" : "eye")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(done ? Theme.white : Theme.secondary)
                    .frame(width: eyeSize, height: eyeSize)
                    .background(done ? Theme.black : Theme.surface, in: Circle())
                    .overlay {
                        Circle().strokeBorder(done ? .clear : Theme.hairline, lineWidth: 1)
                    }
            }
        }
        .frame(height: blockHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(settings.localized("From memory")), \(progressText)")
    }
}

struct EndOfRunChip: Equatable, Identifiable {
    var id: String { "\(isOrange):\(icon ?? ""):\(text)" }
    let text: String
    let isOrange: Bool
    let icon: String?
}

struct EndOfRunStatus: Equatable {
    let icon: String
    let tintOrange: Bool
    let title: String
}

/// Pure presentation model for the end-of-run card, separated for deterministic tests.
struct EndOfRunCardModel: Equatable {
    let scorePercent: Int
    let bpm: Int
    let showsStars: Bool
    let earnedStars: [Bool]
    let status: EndOfRunStatus
    let chips: [EndOfRunChip]

    static func build(
        summary: RunSummary,
        runs: [PracticeRunResult],
        saved: LessonProgress?,
        reviewFeedback: ReviewScheduler.ReviewFeedback?,
        badgeMessage: String?,
        isAfterMe: Bool,
        isSectionLoop: Bool,
        bestResponseScore: Double?,
        language: AppLanguage
    ) -> EndOfRunCardModel {
        let scorePercent = Int((summary.score * 100).rounded())
        let earnedStars = [saved?.passed == true, saved?.mastery == true, saved?.memory == true]

        let status: EndOfRunStatus
        var chips: [EndOfRunChip] = []

        if let reviewFeedback {
            switch reviewFeedback {
            case .passed(_, let gapDays):
                status = EndOfRunStatus(icon: "checkmark", tintOrange: true, title: language.localized("Review passed"))
                chips.append(EndOfRunChip(text: nextReviewGapText(days: gapDays, language: language), isOrange: false, icon: nil))
            case .settled:
                status = EndOfRunStatus(icon: "checkmark", tintOrange: true, title: language.localized("Lesson settled"))
            case .failed:
                status = EndOfRunStatus(icon: "xmark", tintOrange: false, title: language.localized("Review not passed"))
                chips.append(EndOfRunChip(text: language.localized("again tomorrow"), isOrange: false, icon: nil))
            case .doesNotCount(let goalBpm):
                status = EndOfRunStatus(icon: "exclamationmark.circle", tintOrange: false, title: language.localized("Not counted"))
                chips.append(EndOfRunChip(text: "\(language.localized("From memory")) · \(goalBpm) BPM", isOrange: false, icon: nil))
            }
        } else if isAfterMe {
            status = EndOfRunStatus(
                icon: summary.score >= Scoring.passMark ? "checkmark" : "repeat",
                tintOrange: summary.score >= Scoring.passMark,
                title: language.localized("Practice only · no stars")
            )
            if let bestResponseScore {
                let bestPct = Int((bestResponseScore * 100).rounded())
                chips.append(EndOfRunChip(
                    text: "\(language.localized("Best response")): \(bestPct)\u{00a0}%",
                    isOrange: false,
                    icon: nil
                ))
            }
        } else if isSectionLoop {
            status = EndOfRunStatus(icon: "repeat", tintOrange: false, title: language.localized("Section loop"))
            chips.append(EndOfRunChip(text: language.localized("Practice only · no stars"), isOrange: false, icon: nil))
        } else if summary.passes == 0 {
            status = EndOfRunStatus(icon: "exclamationmark.circle", tintOrange: false, title: language.localized("Not counted"))
        } else if summary.passed || runs.last?.passed == true || summary.score >= Scoring.passMark {
            status = EndOfRunStatus(icon: "checkmark", tintOrange: true, title: language.localized("Passed"))
        } else {
            let notPassed = language.localized("not passed")
            let title = notPassed.prefix(1).uppercased(with: Locale(identifier: language == .czech ? "cs" : "en")) + notPassed.dropFirst()
            status = EndOfRunStatus(icon: "xmark", tintOrange: false, title: title)
        }

        if reviewFeedback == nil, summary.firstStar2 {
            chips.append(EndOfRunChip(text: language.localized("Comes back tomorrow for a review"), isOrange: false, icon: nil))
        }

        if reviewFeedback == nil, !isAfterMe, !isSectionLoop, !runs.isEmpty {
            let bestScore = runs.map(\.score).max() ?? summary.score
            let bestPercent = Int((bestScore * 100).rounded())
            chips.append(EndOfRunChip(text: runSummaryText(count: runs.count, bestPercent: bestPercent, language: language), isOrange: false, icon: nil))
        }

        if let badgeMessage {
            chips.append(EndOfRunChip(text: badgeMessage, isOrange: true, icon: "rosette"))
        }

        return EndOfRunCardModel(
            scorePercent: scorePercent,
            bpm: summary.bpm,
            showsStars: !isAfterMe,
            earnedStars: earnedStars,
            status: status,
            chips: chips
        )
    }

    static func nextReviewGapText(days: Int, language: AppLanguage) -> String {
        if language == .czech {
            if days == 1 { return language.localized("next in 1 day") }
            if days >= 2 && days <= 4 { return "další za \(days) dny" }
            return language.localized("next in %lld days", days)
        }
        return days == 1
            ? language.localized("next in 1 day")
            : language.localized("next in %lld days", days)
    }

    static func runSummaryText(count: Int, bestPercent: Int, language: AppLanguage) -> String {
        if language == .czech {
            let runsWord: String
            if count == 1 {
                runsWord = "1 běh"
            } else if count >= 2 && count <= 4 {
                runsWord = "\(count) běhy"
            } else {
                runsWord = "\(count) běhů"
            }
            return "\(runsWord) · nejlepší \(bestPercent)\u{00a0}%"
        }
        let runsWord = count == 1 ? "1 run" : "\(count) runs"
        return "\(runsWord) · best \(bestPercent)%"
    }
}

/// Modern black end-of-run card replacing the old summary strip.
struct ResultCard: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduced

    let summary: RunSummary
    let runs: [PracticeRunResult]
    let saved: LessonProgress?
    let event: StarEvent?
    let announcement: String
    var reviewFeedback: ReviewScheduler.ReviewFeedback? = nil
    var badgeText: String? = nil
    var isAfterMe: Bool = false
    var isSectionLoop: Bool = false
    var bestResponseScore: Double? = nil
    let cardWidth: CGFloat?
    let openRules: () -> Void
    let openSessionResults: () -> Void
    var starRulesAttachment: AnyView? = nil

    @State private var revealedStars: Set<Int> = []
    @State private var poppingStar: Int? = nil

    private var model: EndOfRunCardModel {
        EndOfRunCardModel.build(
            summary: summary,
            runs: runs,
            saved: saved,
            reviewFeedback: reviewFeedback,
            badgeMessage: badgeText,
            isAfterMe: isAfterMe,
            isSectionLoop: isSectionLoop,
            bestResponseScore: bestResponseScore,
            language: settings.languagePreference
        )
    }

    private var accuracySubtitle: String {
        let locale = Locale(identifier: settings.languagePreference == .czech ? "cs" : "en")
        let word = settings.localized("Accuracy").lowercased(with: locale)
        return "\(word) · \(model.bpm) BPM"
    }

    private var isCompactWidth: Bool {
        if let cardWidth { return cardWidth < 580 }
        return false
    }

    var body: some View {
        Group {
            if isCompactWidth {
                VStack(alignment: .leading, spacing: Theme.Space.regular) {
                    HStack(alignment: .center, spacing: Theme.Space.regular) {
                        scoreColumn
                        Spacer(minLength: 0)
                        if model.showsStars {
                            starsRow
                        }
                        detailButton
                    }
                    statusAndChips
                }
            } else {
                HStack(alignment: .center, spacing: Theme.Space.wide) {
                    scoreColumn
                    if model.showsStars {
                        starsRow
                    }
                    statusAndChips
                        .frame(maxWidth: .infinity, alignment: .leading)
                    detailButton
                }
            }
        }
        .padding(.horizontal, Theme.Space.handoff)
        .padding(.vertical, Theme.Space.regular)
        .frame(width: cardWidth)
        .frame(minHeight: 168)
        .foregroundStyle(Theme.white)
        .background(Theme.black, in: RoundedRectangle(cornerRadius: 20))
        .task(id: event?.id ?? summary.id) {
            await animateFreshStars()
            if event == nil, !announcement.isEmpty {
                UIAccessibility.post(notification: .announcement, argument: announcement)
            }
        }
    }

    private var scoreColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(model.scorePercent)\u{00a0}%")
                .font(Theme.boldDisplay(isCompactWidth ? 48 : 64))
                .monospacedDigit()
                .foregroundStyle(Theme.white)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(accuracySubtitle)
                .font(Theme.text(15))
                .monospacedDigit()
                .foregroundStyle(Theme.white.opacity(0.68))
                .lineLimit(1)
        }
        .frame(minWidth: isCompactWidth ? 110 : 164, alignment: .leading)
    }

    private var starsRow: some View {
        Button(action: openRules) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    let earned = model.earnedStars[index]
                    let isFresh = event?.award.fresh[index] == true
                    let visible = earned && (!isFresh || reduced || revealedStars.contains(index))
                    let popping = poppingStar == index && !reduced

                    ZStack {
                        if isFresh && visible {
                            Circle()
                                .fill(Theme.orange.opacity(0.22))
                                .frame(width: 60, height: 60)
                                .transition(.opacity)
                        }
                        Image(systemName: visible ? "star.fill" : "star")
                            .font(.system(size: isCompactWidth ? 34 : 44, weight: .regular))
                            .foregroundStyle(visible ? Theme.orange : Theme.white.opacity(0.28))
                            .scaleEffect(popping ? 1.14 : 1)
                    }
                    .frame(width: isFresh ? 60 : (isCompactWidth ? 36 : 44), height: 60)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("%lld of 3 stars", model.earnedStars.filter { $0 }.count))
        .accessibilityHint(settings.localized("Star requirements"))
        .background {
            if let starRulesAttachment {
                starRulesAttachment
            }
        }
    }

    private var statusAndChips: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: model.status.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(model.status.tintOrange ? Theme.orange : Theme.white.opacity(0.75))
                    .accessibilityHidden(true)
                Text(model.status.title)
                    .font(Theme.strong(20))
                    .foregroundStyle(Theme.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !model.chips.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(model.chips) { chip in
                        HStack(spacing: 6) {
                            if let icon = chip.icon {
                                Image(systemName: icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .accessibilityHidden(true)
                            }
                            Text(chip.text)
                                .font(Theme.text(14).weight(chip.isOrange ? .semibold : .medium))
                                .lineLimit(1)
                        }
                        .foregroundStyle(chip.isOrange ? Theme.black : Theme.white)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(
                            chip.isOrange ? Theme.orange : Theme.white.opacity(0.12),
                            in: Capsule()
                        )
                    }
                }
            }
        }
    }

    private var detailButton: some View {
        ResultDetailButton(action: openSessionResults)
    }

    @MainActor
    private func animateFreshStars() async {
        guard let event, event.award.fresh.contains(true) else {
            revealedStars = [0, 1, 2]
            poppingStar = nil
            return
        }
        revealedStars = Set((0..<3).filter { !event.award.fresh[$0] })
        poppingStar = nil
        if reduced {
            revealedStars = [0, 1, 2]
            UIAccessibility.post(notification: .announcement, argument: announcement)
            return
        }
        for index in 0..<3 where event.award.fresh[index] {
            do { try await Task.sleep(for: Theme.Motion.starStagger) } catch { return }
            withAnimation(Theme.Motion.fast) {
                _ = revealedStars.insert(index)
                poppingStar = index
            }
            do { try await Task.sleep(for: .milliseconds(160)) } catch { return }
            withAnimation(Theme.Motion.emphasis) {
                poppingStar = nil
            }
        }
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}

struct ResultDetailButton: View {
    @Environment(SettingsManager.self) private var settings
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            BarChartGlyph()
                .frame(width: 26, height: 26)
                .foregroundStyle(Theme.white)
                .frame(width: 56, height: 56)
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Theme.white.opacity(0.35), lineWidth: 1.5)
                }
                .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(settings.localized("Session results"))
        .accessibilityHint(settings.localized("Shows all runs"))
    }
}

private struct BarChartGlyph: View {
    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height) / 24
            var path = Path()
            let bars: [(CGFloat, CGFloat)] = [(4, 10), (10, 4), (16, 13)]
            for (x, topY) in bars {
                path.move(to: CGPoint(x: x * s, y: 20 * s))
                path.addLine(to: CGPoint(x: x * s, y: topY * s))
            }
            path.move(to: CGPoint(x: 22 * s, y: 20 * s))
            path.addLine(to: CGPoint(x: 2 * s, y: 20 * s))
            context.stroke(path, with: .foreground, style: StrokeStyle(lineWidth: 2 * s, lineCap: .round, lineJoin: .round))
        }
        .accessibilityHidden(true)
    }
}

/// Three LEDs per qualifying run, stacked from the bottom as the tape advances.
struct RunMeterView: View {
    @Environment(SettingsManager.self) private var settings

    @ScaledMetric(relativeTo: .body) private var blockHeight: CGFloat = 40
    @ScaledMetric(relativeTo: .body) private var blockWidth: CGFloat = 22
    @ScaledMetric(relativeTo: .body) private var stepGap: CGFloat = 3
    @ScaledMetric(relativeTo: .body) private var blockInset: CGFloat = 2

    let badgeTitle: String?
    let starNumber: Int?
    let count: Int
    let required: Int
    let accessibilityTarget: String
    let fraction: Double
    let verdict: RunVerdict?
    let starMomentActive: Bool

    @State private var flashingOutline = false

    init(
        progress: (count: Int, required: Int, name: String, starIndex: Int),
        fraction: Double,
        verdict: RunVerdict?,
        starMomentActive: Bool
    ) {
        self.badgeTitle = nil
        self.starNumber = progress.starIndex + 1
        self.count = progress.count
        self.required = progress.required
        self.accessibilityTarget = progress.name
        self.fraction = fraction
        self.verdict = verdict
        self.starMomentActive = starMomentActive
    }

    init(
        badgeTitle: String,
        count: Int,
        required: Int,
        accessibilityTarget: String,
        fraction: Double,
        verdict: RunVerdict?,
        starMomentActive: Bool
    ) {
        self.badgeTitle = badgeTitle
        self.starNumber = nil
        self.count = count
        self.required = required
        self.accessibilityTarget = accessibilityTarget
        self.fraction = fraction
        self.verdict = verdict
        self.starMomentActive = starMomentActive
    }

    static func litMicroSteps(fraction: Double) -> Int {
        Int(min(1, max(0, fraction)) * 3)
    }

    var body: some View {
        HStack(spacing: Theme.Space.small) {
            HStack(spacing: Theme.Space.tight) {
                if let starNumber {
                    Image(systemName: "star.fill")
                    Text("\(starNumber)").monospacedDigit()
                } else if let badgeTitle {
                    Text(badgeTitle)
                }
            }
            .font(Theme.rowTitle)
            .foregroundStyle(starMomentActive ? Theme.orange : Theme.ink)
            .padding(.horizontal, Theme.Space.small)
            .frame(height: blockHeight)
            .background(Theme.surface, in: Capsule())
            .overlay { Capsule().strokeBorder(Theme.hairline, lineWidth: 1) }

            HStack(spacing: Theme.Space.tight) {
                ForEach(0..<required, id: \.self) { index in
                    runBlock(index: index)
                }
            }
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("Consecutive passes for %@", settings.localized(accessibilityTarget)))
        .accessibilityValue(settings.localized("%lld of %lld", count, required))
        .task(id: verdict?.id) {
            flashingOutline = verdict?.brokenStreak == true
            guard flashingOutline else { return }
            do { try await Task.sleep(for: .milliseconds(200)) } catch { return }
            withAnimation(.easeOut(duration: 0.20)) { flashingOutline = false }
        }
    }

    private func runBlock(index: Int) -> some View {
        let banked = index < count
        let lit = banked ? 3 : (index == count ? Self.litMicroSteps(fraction: fraction) : 0)
        return VStack(spacing: stepGap) {
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
        .padding(blockInset)
        .frame(width: blockWidth, height: blockHeight)
        .background(Theme.surface)
        .animation(verdict?.passed == true ? Theme.Motion.fast : .easeOut(duration: 0.20),
                   value: verdict?.id)
        .overlay {
            Rectangle().strokeBorder(flashingOutline ? Theme.markWrong : Theme.hairline, lineWidth: 1)
        }
    }
}
