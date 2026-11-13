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
        let height = bandHeight(rows: rows, availableHeight: availableHeight, minMargin: minMargin)
        return BandGeometry(size: CGSize(width: 1000, height: height), rows: rows).rowHeight
    }

    /// Computes the vertical scale factor (rowHeight / baseRowHeight).
    static func scale(rows: Int, availableHeight: CGFloat, minMargin: CGFloat = 40) -> CGFloat {
        rowHeight(rows: rows, availableHeight: availableHeight, minMargin: minMargin) / baseRowHeight
    }

    /// Band height computed from the lane count and the available vertical space.
    /// Keeps 1–3 row bands unchanged at roomy iPad heights while expanding into margin
    /// before squeezing dense (4+ row) lessons, never exceeding `availableHeight`.
    static func bandHeight(rows: Int, availableHeight: CGFloat, minMargin: CGFloat = 40) -> CGFloat {
        let clampedAvailable = max(0, availableHeight)
        let unscaled = unscaledHeight(rows: rows)
        let maxDesired = unscaled * (maxRowHeight / baseRowHeight)
        let comfortableTarget = max(160, clampedAvailable - 2 * minMargin)
        let target: CGFloat
        if maxDesired <= comfortableTarget {
            target = maxDesired
        } else if unscaled <= comfortableTarget {
            target = comfortableTarget
        } else {
            target = unscaled
        }
        return min(target, clampedAvailable)
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
        let verticalCap = floor(rowHeight * 0.62)
        let floorFont = min(minFontSize, max(10, verticalCap))
        let heightCappedFont = max(floorFont, verticalCap)
        let startFont = max(floorFont, min(rowCappedFont, heightCappedFont))

        // Keep at least ~74–78% of width for pattern bars so labels never squeeze cells.
        let maxFraction: CGFloat = barCount >= 3 ? 0.22 : 0.26
        let maxGutter = max(48, min(220, availableWidth * maxFraction))

        var chosenFont = floorFont
        var widestAtChosen: CGFloat = 0
        var size = startFont
        var fitted = false
        while size >= floorFont {
            let font = UIFont(name: "IBMPlexSans-Bold", size: size) ?? .boldSystemFont(ofSize: size)
            let widest = rawLabels.values.map { textWidth($0, font: font) }.max() ?? 0
            widestAtChosen = widest
            chosenFont = size
            if widest + trailingPadding <= maxGutter {
                fitted = true
                break
            }
            if size == floorFont { break }
            size = max(floorFont, size - 0.5)
        }

        let font = UIFont(name: "IBMPlexSans-Bold", size: chosenFont) ?? .boldSystemFont(ofSize: chosenFont)
        if fitted {
            let fittedGutter = ceil(widestAtChosen + trailingPadding)
            return BandLabelLayout(gutter: fittedGutter, fontSize: chosenFont, labels: rawLabels)
        }

        let maxTextWidth = max(12, floor(maxGutter - trailingPadding))
        let truncatedLabels = rawLabels.mapValues { truncateMiddle($0, maxWidth: maxTextWidth, font: font) }
        return BandLabelLayout(gutter: floor(maxGutter), fontSize: chosenFont, labels: truncatedLabels)
    }

    private static func textWidth(_ string: String, font: UIFont) -> CGFloat {
        (string as NSString).size(withAttributes: [.font: font]).width
    }

    private static func truncateMiddle(_ string: String, maxWidth: CGFloat, font: UIFont) -> String {
        guard textWidth(string, font: font) > maxWidth else { return string }
        let chars = Array(string)
        guard chars.count > 2 else { return "…" }

        var leftCount = (chars.count + 1) / 2
        var rightCount = chars.count / 2
        while leftCount + rightCount > 1 {
            if leftCount > rightCount {
                leftCount -= 1
            } else {
                rightCount -= 1
            }
            let left = String(chars.prefix(leftCount)).trimmingCharacters(in: .whitespaces)
            let right = String(chars.suffix(rightCount)).trimmingCharacters(in: .whitespaces)
            let candidate = left + "…" + right
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

/// Single source of truth for the vertical geometry of the practice pattern band,
/// keeping the top progress strip, beat ruler, and all pattern rows separated inside the band.
struct BandGeometry: Equatable {
    static let spineRulerHeight: CGFloat = 8
    private static let minBeatFontSize: CGFloat = 15
    private static let maxHeaderTintHeight: CGFloat = 76
    private static let spineToBeatGap: CGFloat = 3

    let size: CGSize
    let rowCount: Int
    let scale: CGFloat
    let rowScale: CGFloat
    let top: CGFloat
    let bottom: CGFloat
    let rowHeight: CGFloat
    let rowGap: CGFloat
    let bottomPadding: CGFloat
    let countY: CGFloat
    let beatFontSize: CGFloat
    let tickY: CGFloat
    let tickWidth: CGFloat
    let tickHeight: CGFloat
    let beatLineTop: CGFloat
    let headerTintHeight: CGFloat
    let noteFontSize: CGFloat

    init(size: CGSize, rows: Int) {
        let count = max(1, rows)
        self.size = size
        self.rowCount = count

        let unscaled = PracticeBandStyle.unscaledHeight(rows: count)
        let maxScale = PracticeBandStyle.maxRowHeight / PracticeBandStyle.baseRowHeight
        let rawScale = size.height > 0 ? (size.height / unscaled) : 1
        let clampedScale = min(maxScale, max(0.35, rawScale))
        self.scale = clampedScale

        let isCompact = rawScale < 1
        let beatFont = isCompact
            ? max(Self.minBeatFontSize, 28 * rawScale)
            : 28 * clampedScale
        self.beatFontSize = beatFont

        // Keep beat digits cleanly below the 8 pt progress strip (BandTopSpineRuler).
        let beatHalfBox = beatFont * 0.65
        let minCountY = Self.spineRulerHeight + Self.spineToBeatGap + beatHalfBox
        let computedCountY = isCompact
            ? max(minCountY, 26 * rawScale)
            : max(minCountY, 26 * clampedScale)
        self.countY = computedCountY

        let tickH = max(2.5, 4 * clampedScale)
        let tickW = max(4, 6 * clampedScale)
        let computedTickY = computedCountY + max(beatFont * 0.42, 12 * clampedScale)
        self.tickY = computedTickY
        self.tickWidth = tickW
        self.tickHeight = tickH
        self.beatLineTop = computedCountY + max(beatFont * 0.48, 14 * clampedScale)

        let markerExtension = 4 * clampedScale + 3
        let minTopAfterRuler = computedTickY + tickH + markerExtension + 2
        let computedTop = max(minTopAfterRuler, 56 * (isCompact ? rawScale : clampedScale))
        self.top = computedTop

        let computedBottomPadding = isCompact
            ? max(6, 24 * rawScale)
            : 24 * clampedScale
        self.bottomPadding = computedBottomPadding

        let computedRowGap = isCompact
            ? max(2.5, 8 * rawScale)
            : 8 * clampedScale
        self.rowGap = computedRowGap

        let totalGaps = computedRowGap * CGFloat(max(0, count - 1))
        let spaceForRows = max(CGFloat(count), size.height - computedTop - computedBottomPadding - totalGaps)
        let computedRowHeight = min(PracticeBandStyle.maxRowHeight, spaceForRows / CGFloat(count))
        self.rowHeight = computedRowHeight
        self.bottom = computedTop + CGFloat(count) * computedRowHeight + totalGaps

        let computedRowScale = computedRowHeight / PracticeBandStyle.baseRowHeight
        self.rowScale = computedRowScale
        self.noteFontSize = 32 * computedRowScale

        self.headerTintHeight = min(Self.maxHeaderTintHeight, max(0, computedTop - 4 * clampedScale))
    }

    var contentRect: CGRect {
        CGRect(origin: .zero, size: size)
    }

    var spineRulerRect: CGRect {
        CGRect(x: 0, y: 0, width: size.width, height: Self.spineRulerHeight)
    }

    /// Full top ruler zone spanning the progress strip, beat numbers, bar ticks, and marker cap clearance.
    var rulerRect: CGRect {
        CGRect(x: 0, y: 0, width: size.width, height: headerTintHeight)
    }

    func rowCenterY(_ row: Int) -> CGFloat {
        top + CGFloat(row) * (rowHeight + rowGap) + rowHeight / 2
    }

    func rowRect(_ row: Int) -> CGRect {
        CGRect(x: 0, y: top + CGFloat(row) * (rowHeight + rowGap), width: size.width, height: rowHeight)
    }

    var rowRects: [CGRect] {
        (0..<rowCount).map { rowRect($0) }
    }

    func tileRect(x: CGFloat, width: CGFloat, row: Int) -> CGRect {
        let h = min(rowHeight - 4 * rowScale, 64 * rowScale)
        return CGRect(x: x - width * 0.42, y: rowCenterY(row) - h / 2, width: width * 0.84, height: max(1, h))
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

/// Presentation only; lesson credit remains owned by StarStreak.
enum PracticeMeterPhase: Equatable {
    case climbSegments(filled: Int, total: Int)
    case climbContinuous(fraction: Double)
    case runs(count: Int, required: Int)

    var isClimbing: Bool {
        switch self {
        case .climbSegments, .climbContinuous: true
        case .runs: false
        }
    }

    init(starIndex: Int, count: Int, required: Int,
         startBpm: Int, goalBpm: Int, step: Int, currentBpm: Int) {
        guard starIndex == 1, currentBpm < goalBpm else {
            self = .runs(count: count, required: required)
            return
        }
        let span = goalBpm - startBpm
        let distance = max(0, currentBpm - startBpm)
        guard step > 0, span > 0 else {
            self = .climbContinuous(fraction: span > 0 ? min(1, Double(distance) / Double(span)) : 0)
            return
        }
        let total = (span + step - 1) / step
        if total > 8 {
            self = .climbContinuous(fraction: min(1, Double(distance) / Double(span)))
        } else {
            self = .climbSegments(filled: min(total, distance / step), total: total)
        }
    }
}

/// Top-right lesson-requirements progress cluster: warm-up eyes, counted passes, and live %.
struct PracticeProgressMeter: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ScaledMetric(relativeTo: .body) private var blockHeight: CGFloat = 40
    @ScaledMetric(relativeTo: .body) private var eyeSize: CGFloat = 34

    let showWarmUps: Bool
    let completedWarmUps: Int
    let starProgress: (count: Int, required: Int, name: String, starIndex: Int)?
    let reviewProgress: (count: Int, required: Int, settled: Bool)?
    let startBpm: Int
    let goalBpm: Int
    let currentBpm: Int
    let tempoStep: Int
    let fraction: Double
    let verdict: RunVerdict?
    let starMomentActive: Bool
    let currentAccuracy: Double?

    private var accuracyText: String {
        guard let currentAccuracy else { return "—\u{00a0}%" }
        return "\(Int((currentAccuracy * 100).rounded()))\u{00a0}%"
    }

    private var phase: PracticeMeterPhase? {
        starProgress.map {
            PracticeMeterPhase(starIndex: $0.starIndex, count: $0.count, required: $0.required,
                               startBpm: startBpm, goalBpm: goalBpm, step: tempoStep, currentBpm: currentBpm)
        }
    }

    var body: some View {
        HStack(spacing: Theme.Space.regular) {
            if showWarmUps {
                warmUpEyes
                if starProgress != nil || reviewProgress != nil {
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(width: 1, height: blockHeight * 0.65)
                        .accessibilityHidden(true)
                }
            }

            if let starProgress, let phase {
                ZStack {
                    if case let .runs(count, required) = phase {
                        RunMeterView(
                            progress: (count, required, starProgress.name, starProgress.starIndex),
                            fraction: fraction,
                            verdict: verdict,
                            starMomentActive: starMomentActive
                        )
                        .transition(reduceMotion ? .identity : .opacity)
                    } else {
                        TempoLadderView(startBpm: startBpm, goalBpm: goalBpm, currentBpm: currentBpm,
                                        phase: phase, starMomentActive: starMomentActive)
                            .transition(reduceMotion ? .identity : .opacity)
                    }
                }
                .animation(reduceMotion ? nil : Theme.Motion.fast, value: phase.isClimbing)
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
        return HStack(spacing: Theme.Space.controlGap) {
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

private struct TempoLadderView: View {
    @Environment(SettingsManager.self) private var settings
    @ScaledMetric(relativeTo: .body) private var trackWidth: CGFloat = 108
    @ScaledMetric(relativeTo: .body) private var trackHeight: CGFloat = 8

    let startBpm: Int
    let goalBpm: Int
    let currentBpm: Int
    let phase: PracticeMeterPhase
    let starMomentActive: Bool

    var body: some View {
        HStack(spacing: Theme.Space.regular) {
            RunMeterBadge(badgeTitle: nil, starNumber: 2, starMomentActive: starMomentActive)
            HStack(spacing: Theme.Space.small) {
                Text("\(startBpm)")
                track.frame(width: trackWidth, height: trackHeight)
                Text("\(goalBpm)")
            }
            .font(Theme.meta)
            .monospacedDigit()
            .foregroundStyle(Theme.secondary)
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("Star 2: tempo %lld of %lld BPM", currentBpm, goalBpm))
    }

    @ViewBuilder
    private var track: some View {
        switch phase {
        case let .climbSegments(filled, total):
            HStack(spacing: Theme.Space.tight) {
                ForEach(0..<total, id: \.self) { index in
                    Capsule().fill(index < filled ? Theme.ink : Theme.hairline)
                }
            }
        case let .climbContinuous(fraction):
            GeometryReader { geometry in
                Capsule().fill(Theme.hairline)
                    .overlay(alignment: .leading) {
                        Capsule().fill(Theme.ink)
                            .frame(width: geometry.size.width * fraction)
                    }
            }
        case .runs:
            EmptyView()
        }
    }
}

struct EndOfRunLine: Equatable, Identifiable {
    enum Kind: Equatable {
        case review
        case runs
        case badge
    }

    var id: String { "\(kind):\(text)" }
    let kind: Kind
    let icon: String
    let text: String
    let isOrange: Bool
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
    let reviewLine: EndOfRunLine?
    let runsLine: EndOfRunLine?
    let badgeLine: EndOfRunLine?

    var lines: [EndOfRunLine] {
        [reviewLine, runsLine, badgeLine].compactMap { $0 }
    }

    static func build(
        summary: RunSummary,
        runs: [PracticeRunResult],
        saved: LessonProgress?,
        reviewFeedback: ReviewScheduler.ReviewFeedback?,
        badgeCount: Int = 0,
        isAfterMe: Bool,
        isSectionLoop: Bool,
        bestResponseScore: Double?,
        language: AppLanguage,
        isDueReview: Bool = false,
        reviewPendingReason: PracticeStepOutcome.Reason? = nil
    ) -> EndOfRunCardModel {
        let scorePercent = Int((summary.score * 100).rounded())
        let earnedStars = [saved?.passed == true, saved?.mastery == true, saved?.memory == true]

        let status: EndOfRunStatus
        if let reviewFeedback {
            switch reviewFeedback {
            case .passed:
                status = EndOfRunStatus(icon: "checkmark", tintOrange: true, title: language.localized("Review passed"))
            case .settled:
                status = EndOfRunStatus(icon: "checkmark", tintOrange: true, title: language.localized("Lesson settled"))
            case .failed:
                status = EndOfRunStatus(icon: "xmark", tintOrange: false, title: language.localized("Review not passed"))
            case .doesNotCount:
                status = EndOfRunStatus(icon: "exclamationmark.circle", tintOrange: false, title: language.localized("Not counted"))
            }
        } else if isAfterMe {
            status = EndOfRunStatus(
                icon: summary.score >= Scoring.passMark ? "checkmark" : "repeat",
                tintOrange: summary.score >= Scoring.passMark,
                title: language.localized("Practice only · no stars")
            )
        } else if isSectionLoop {
            status = EndOfRunStatus(icon: "repeat", tintOrange: false, title: language.localized("Section loop"))
        } else if isDueReview {
            // An undecided due review must never report a regular "Passed" card (ticket 189).
            status = EndOfRunStatus(icon: "exclamationmark.circle", tintOrange: false, title: language.localized("Not counted"))
        } else if summary.passes == 0 {
            status = EndOfRunStatus(icon: "exclamationmark.circle", tintOrange: false, title: language.localized("Not counted"))
        } else if summary.passed || runs.last?.passed == true || summary.score >= Scoring.passMark {
            status = EndOfRunStatus(icon: "checkmark", tintOrange: true, title: language.localized("Passed"))
        } else {
            let notPassed = language.localized("not passed")
            let title = notPassed.prefix(1).uppercased(with: Locale(identifier: language == .czech ? "cs" : "en")) + notPassed.dropFirst()
            status = EndOfRunStatus(icon: "xmark", tintOrange: false, title: title)
        }

        let reviewLine: EndOfRunLine?
        if let reviewFeedback {
            switch reviewFeedback {
            case .passed(_, let gapDays):
                reviewLine = EndOfRunLine(
                    kind: .review,
                    icon: "calendar",
                    text: nextReviewGapText(days: gapDays, language: language),
                    isOrange: false
                )
            case .settled:
                reviewLine = nil
            case .failed:
                reviewLine = EndOfRunLine(
                    kind: .review,
                    icon: "calendar",
                    text: language.localized("Review tomorrow"),
                    isOrange: false
                )
            case .doesNotCount(let goalBpm):
                reviewLine = EndOfRunLine(
                    kind: .review,
                    icon: "calendar",
                    text: "\(language.localized("From memory")) · \(goalBpm) BPM",
                    isOrange: false
                )
            }
        } else if isDueReview {
            let reason = reviewPendingReason ?? .unfinishedReview
            reviewLine = EndOfRunLine(
                kind: .review,
                icon: "calendar",
                text: reason.message(language: language),
                isOrange: false
            )
        } else if isAfterMe {
            if let bestResponseScore {
                let bestPct = Int((bestResponseScore * 100).rounded())
                reviewLine = EndOfRunLine(
                    kind: .review,
                    icon: "chart.line.uptrend.xyaxis",
                    text: "\(language.localized("Best response")): \(bestPct)\u{00a0}%",
                    isOrange: false
                )
            } else {
                reviewLine = nil
            }
        } else if isSectionLoop {
            reviewLine = EndOfRunLine(
                kind: .review,
                icon: "repeat",
                text: language.localized("Practice only · no stars"),
                isOrange: false
            )
        } else if summary.firstStar2 {
            reviewLine = EndOfRunLine(
                kind: .review,
                icon: "calendar",
                text: language.localized("Review tomorrow"),
                isOrange: false
            )
        } else {
            reviewLine = nil
        }

        let runsLine: EndOfRunLine?
        if !isAfterMe, !isSectionLoop, !runs.isEmpty {
            let bestScore = runs.map(\.score).max() ?? summary.score
            let bestPercent = Int((bestScore * 100).rounded())
            runsLine = EndOfRunLine(
                kind: .runs,
                icon: "chart.bar.fill",
                text: runSummaryText(count: runs.count, bestPercent: bestPercent, language: language),
                isOrange: false
            )
        } else {
            runsLine = nil
        }

        let badgeLine: EndOfRunLine?
        if badgeCount > 0 {
            badgeLine = EndOfRunLine(
                kind: .badge,
                icon: "rosette",
                text: badgeSummaryText(count: badgeCount, language: language),
                isOrange: true
            )
        } else {
            badgeLine = nil
        }

        return EndOfRunCardModel(
            scorePercent: scorePercent,
            bpm: summary.bpm,
            showsStars: !isAfterMe,
            earnedStars: earnedStars,
            status: status,
            reviewLine: reviewLine,
            runsLine: runsLine,
            badgeLine: badgeLine
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

    static func badgeSummaryText(count: Int, language: AppLanguage) -> String {
        if language == .czech {
            if count == 1 {
                return language.localized("1 new badge")
            } else if count >= 2 && count <= 4 {
                return "\(count) nové odznaky"
            } else {
                return "\(count) nových odznaků"
            }
        }
        return count == 1
            ? language.localized("1 new badge")
            : language.localized("%lld new badges", count)
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
    var isDueReview: Bool = false
    var reviewPendingReason: PracticeStepOutcome.Reason? = nil
    var badgeCount: Int = 0
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
            badgeCount: badgeCount,
            isAfterMe: isAfterMe,
            isSectionLoop: isSectionLoop,
            bestResponseScore: bestResponseScore,
            language: settings.languagePreference,
            isDueReview: isDueReview,
            reviewPendingReason: reviewPendingReason
        )
    }

    private var accuracySubtitle: String {
        let locale = Locale(identifier: settings.languagePreference == .czech ? "cs" : "en")
        let word = settings.localized("Accuracy").lowercased(with: locale)
        return "\(word) · \(model.bpm) BPM"
    }

    private var isCompactWidth: Bool {
        if let cardWidth { return cardWidth < 620 }
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
                    }
                    factsColumn
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                HStack(alignment: .center, spacing: Theme.Space.regular) {
                    scoreColumn
                    if model.showsStars {
                        starsRow
                    }
                    factsColumn
                        .frame(maxWidth: .infinity, alignment: .leading)
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
        .frame(minWidth: isCompactWidth ? 110 : 138, alignment: .leading)
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

    private var factsColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            statusRow

            if let reviewLine = model.reviewLine {
                reviewRow(reviewLine)
            }

            if let runsLine = model.runsLine {
                runsButton(runsLine)
            }

            if let badgeLine = model.badgeLine {
                badgeRow(badgeLine)
            }
        }
    }

    private var statusRow: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: model.status.icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(model.status.tintOrange ? Theme.orange : Theme.white.opacity(0.75))
                .frame(width: 20, alignment: .center)
                .accessibilityHidden(true)
            Text(model.status.title)
                .font(Theme.strong(20))
                .foregroundStyle(Theme.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(minHeight: 28, alignment: .leading)
    }

    private func reviewRow(_ line: EndOfRunLine) -> some View {
        HStack(spacing: 8) {
            Image(systemName: line.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.white.opacity(0.75))
                .frame(width: 20, alignment: .center)
                .accessibilityHidden(true)
            Text(line.text)
                .font(Theme.text(14).weight(.medium))
                .foregroundStyle(Theme.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(minHeight: 24, alignment: .leading)
    }

    private func runsButton(_ line: EndOfRunLine) -> some View {
        Button(action: openSessionResults) {
            HStack(spacing: 8) {
                Image(systemName: line.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.white.opacity(0.85))
                    .frame(width: 20, alignment: .center)
                    .accessibilityHidden(true)
                Text(line.text)
                    .font(Theme.text(14).weight(.medium))
                    .foregroundStyle(Theme.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.white.opacity(0.55))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Theme.white.opacity(0.25), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(line.text)
        .accessibilityHint(settings.localized("Shows all runs"))
    }

    private func badgeRow(_ line: EndOfRunLine) -> some View {
        HStack(spacing: 8) {
            Image(systemName: line.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.orange)
                .frame(width: 20, alignment: .center)
                .accessibilityHidden(true)
            Text(line.text)
                .font(Theme.text(14).weight(.semibold))
                .foregroundStyle(Theme.orange)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(minHeight: 24, alignment: .leading)
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



private struct RunMeterBadge: View {
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 40

    let badgeTitle: String?
    let starNumber: Int?
    let starMomentActive: Bool

    var body: some View {
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
        .frame(height: height)
        .background(Theme.surface, in: Capsule())
        .overlay { Capsule().strokeBorder(Theme.hairline, lineWidth: 1) }
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
        HStack(spacing: Theme.Space.regular) {
            RunMeterBadge(badgeTitle: badgeTitle, starNumber: starNumber, starMomentActive: starMomentActive)

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
