import SwiftUI
import UIKit

enum PracticeHardware {
    static let chassis = color(0x0C0C0E)
    static let panel = color(0x141417)
    static let border = color(0x26262B)
    static var orange: Color { Theme.orange }
    static let displayBottom = color(0xE04E00)
    static let playheadGlow = color(0xFF9E44)
    static let strikeGlow = color(0xFFD1A6)
    static let padFill = color(0x1E1E24)
    static let padBorder = color(0x34343D)
    static let padFadeDuration: TimeInterval = 0.18

    static func color(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255,
              green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255)
    }
}

struct PracticeTransportPadStyle: ButtonStyle {
    let primary: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        let top = primary ? PracticeHardware.color(0xFF9447) : PracticeHardware.color(0x454552)
        let edge = primary ? PracticeHardware.displayBottom : PracticeHardware.padBorder

        configuration.label
            .foregroundStyle(.white)
            .background {
                shape
                    .fill(
                        LinearGradient(
                            colors: primary
                                ? [PracticeHardware.color(0xFF7B1A), PracticeHardware.orange]
                                : [PracticeHardware.padFill, PracticeHardware.color(0x18181D)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: PracticeHardware.orange.opacity(primary && !configuration.isPressed ? 0.65 : 0),
                            radius: 10, y: 2)
            }
            .overlay {
                shape.fill(.black.opacity(configuration.isPressed ? 0.24 : 0))
            }
            .overlay {
                shape.strokeBorder(
                    LinearGradient(colors: [top, edge], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.5
                )
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .contentShape(shape)
    }
}

/// Measurements and colours from the approved Cut Tape B source.
/// Kept local to practice so the library and settings retain their own styling.
enum PracticeBandStyle {
    static let showPadLabels = true
    static let rowGap: CGFloat = 8
    static var orange: Color { PracticeHardware.orange }

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

    static func bandMarginWidth(rowHeight: CGFloat) -> CGFloat {
        let icon = bandMarginIconSize(rowHeight: rowHeight)
        return ceil(icon + 38)
    }

    static func bandMarginIconSize(rowHeight: CGFloat) -> CGFloat {
        max(13, min(24, floor(rowHeight * 0.58)))
    }

    static func bandLabelLayout(
        rows: [Int],
        availableWidth: CGFloat,
        rowHeight: CGFloat,
        barCount: Int = 1,
        maxFontSize: CGFloat = 26,
        minFontSize: CGFloat = 18,
        trailingPadding: CGFloat = 22,
        leadingPadding: CGFloat = 20,
        showLabels: Bool = PracticeBandStyle.showPadLabels
    ) -> BandLabelLayout {
        guard showLabels, !rows.isEmpty, availableWidth > 0 else {
            return BandLabelLayout(gutter: 0, iconSize: 0, labels: [:])
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

        let icon = bandMarginIconSize(rowHeight: rowHeight)
        let gutter = bandMarginWidth(rowHeight: rowHeight)
        return BandLabelLayout(gutter: gutter, iconSize: icon, labels: rawLabels)
    }
}

struct BandLabelLayout: Equatable {
    let gutter: CGFloat
    let iconSize: CGFloat
    let labels: [Int: String]

    var fontSize: CGFloat { iconSize }
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
    var maximumWidth: CGFloat? = nil

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
        let width = min(maximumWidth ?? trackWidth, trackWidth)
        ZStack {
            Capsule()
                .fill(Theme.surface)
                .overlay { Capsule().strokeBorder(Theme.hairline, lineWidth: 1) }

            ForEach([-1.0, 1.0], id: \.self) { side in
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(width: 1, height: markHeight)
                    .offset(x: side * width / 9)
            }

            Rectangle()
                .fill(Theme.secondary)
                .frame(width: notchWidth, height: pipHeight)

            Capsule()
                .fill(offset == 0 ? Theme.orange : Theme.ink)
                .frame(width: min(pipWidth, width), height: pipHeight)
                .offset(x: offset * max(0, width - pipWidth) / 2)
                .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.78),
                           value: offset)
        }
        .frame(width: width, height: trackHeight)
        .opacity(active ? 1 : 0.35)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("Hit timing"))
        .accessibilityValue(settings.localized(timingKey))
        .accessibilityHidden(!active)
    }
}

/// Large tappable OLED tempo readout. Opens the tempo controls while stopped.
struct TempoTile<CueContent: View>: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduced
    private var motion: Theme.Motion.Policy { .init(reduced: reduced) }
    let bpm: Int
    let startBpm: Int
    let targetBpm: Int
    let editable: Bool
    let status: String?
    let side: CGFloat
    var expanded: Bool = false
    var onStepTempo: ((Int) -> Void)? = nil
    var onSetTempo: ((Int) -> Void)? = nil
    let action: () -> Void
    @ViewBuilder var timingCue: () -> CueContent

    init(
        bpm: Int,
        startBpm: Int = 60,
        targetBpm: Int,
        editable: Bool,
        status: String?,
        side: CGFloat,
        expanded: Bool = false,
        onStepTempo: ((Int) -> Void)? = nil,
        onSetTempo: ((Int) -> Void)? = nil,
        action: @escaping () -> Void,
        @ViewBuilder timingCue: @escaping () -> CueContent = { EmptyView() }
    ) {
        self.bpm = bpm
        self.startBpm = startBpm
        self.targetBpm = targetBpm
        self.editable = editable
        self.status = status
        self.side = side
        self.expanded = expanded
        self.onStepTempo = onStepTempo
        self.onSetTempo = onSetTempo
        self.action = action
        self.timingCue = timingCue
    }

    private var sliderMinBpm: Int { min(40, min(startBpm, bpm)) }
    private var sliderMaxBpm: Int { max(180, max(targetBpm + 20, bpm)) }

    var body: some View {
        Group {
            if let status {
                Text(status)
                    .font(Theme.meta)
                    .foregroundStyle(Theme.Skin.Display.secondary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .padding(Theme.Space.small)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if expanded {
                expandedBody
            } else {
                compactBody
            }
        }
        .frame(maxWidth: expanded ? .infinity : side, minHeight: side, maxHeight: side)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous)
                .fill(PracticeHardware.panel.shadow(.inner(color: .black.opacity(0.8), radius: 6, y: 3)))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous)
                        .strokeBorder(PracticeHardware.border, lineWidth: 1)
                }
        }
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.panel))
    }

    private var expandedBody: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Button(action: action) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(editable ? PracticeHardware.orange : Color.white.opacity(0.3))
                            .frame(width: 6, height: 6)
                            .shadow(color: editable ? PracticeHardware.orange.opacity(0.8) : .clear, radius: 4)
                        Text("TEMPO")
                            .font(Theme.strong(11))
                            .tracking(0.8)
                            .foregroundStyle(Color.white.opacity(editable ? 0.92 : 0.45))
                        if editable {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.65))
                        }
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(PracticeHardware.chassis, in: Capsule())
                    .overlay {
                        Capsule().strokeBorder(PracticeHardware.border, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!editable)
                .accessibilityLabel(settings.localized("Tempo"))

                Spacer(minLength: 4)

                HStack(spacing: 5) {
                    Text(settings.localized("Goal").uppercased())
                        .font(Theme.strong(10))
                        .tracking(0.6)
                        .foregroundStyle(Color.white.opacity(0.6))
                    Text("\(targetBpm)")
                        .font(Theme.strong(13))
                        .monospacedDigit()
                        .foregroundStyle(bpm >= targetBpm ? PracticeHardware.orange : Color.white)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    (bpm >= targetBpm ? PracticeHardware.orange.opacity(0.18) : PracticeHardware.chassis),
                    in: Capsule()
                )
                .overlay {
                    Capsule().strokeBorder(
                        bpm >= targetBpm ? PracticeHardware.orange : PracticeHardware.border,
                        lineWidth: 1
                    )
                }
            }

            HStack(spacing: Theme.Space.regular) {
                if let onStepTempo {
                    stepButton(symbol: "minus", label: settings.localized("Decrease tempo")) {
                        onStepTempo(-1)
                    }
                    .opacity(editable ? 1 : 0.32)
                    .disabled(!editable)
                }

                Button(action: action) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(bpm)")
                            .font(Theme.boldDisplay(min(54, max(34, side * 0.36))))
                            .monospacedDigit()
                            .foregroundStyle(Color.white)
                            .shadow(color: PracticeHardware.orange.opacity(0.60), radius: 10)
                            .shadow(color: PracticeHardware.playheadGlow.opacity(0.30), radius: 3)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .contentTransition(motion.numeric)
                            .motion(value: bpm)
                        Text("BPM")
                            .font(Theme.strong(13))
                            .tracking(0.6)
                            .foregroundStyle(PracticeHardware.orange)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!editable)
                .accessibilityLabel(settings.localized("Tempo %lld BPM, goal %lld", bpm, targetBpm))

                if let onStepTempo {
                    stepButton(symbol: "plus", label: settings.localized("Increase tempo")) {
                        onStepTempo(1)
                    }
                    .opacity(editable ? 1 : 0.32)
                    .disabled(!editable)
                }
            }

            ZStack {
                tempoBarSlider
                    .opacity(editable ? 1 : 0.45)
                timingCue()
            }
            .frame(height: 26)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var compactBody: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(bpm)")
                        .font(Theme.boldDisplay(min(44, side * 0.42)))
                        .monospacedDigit()
                        .foregroundStyle(Color.white)
                        .shadow(color: PracticeHardware.orange.opacity(0.55), radius: 8)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .contentTransition(motion.numeric)
                        .motion(value: bpm)
                    Text("BPM")
                        .font(Theme.strong(11))
                        .foregroundStyle(PracticeHardware.orange)
                }
                Text("\(settings.localized("Goal")) \(targetBpm)")
                    .font(Theme.meta)
                    .monospacedDigit()
                    .foregroundStyle(bpm >= targetBpm ? PracticeHardware.orange : Color.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!editable)
        .accessibilityLabel(settings.localized("Tempo %lld BPM, goal %lld", bpm, targetBpm))
    }

    private var tempoBarSlider: some View {
        GeometryReader { geo in
            let width = max(1, geo.size.width)
            let span = Double(max(1, sliderMaxBpm - sliderMinBpm))
            let fraction = min(1, max(0, Double(bpm - sliderMinBpm) / span))
            let goalFraction = min(1, max(0, Double(targetBpm - sliderMinBpm) / span))
            let segmentCount = 24
            let gap: CGFloat = 2
            let segWidth = max(1, (width - CGFloat(segmentCount - 1) * gap) / CGFloat(segmentCount))

            ZStack(alignment: .leading) {
                HStack(spacing: gap) {
                    ForEach(0..<segmentCount, id: \.self) { index in
                        let threshold = Double(index) / Double(segmentCount)
                        let lit = threshold <= fraction
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(lit ? PracticeHardware.orange : PracticeHardware.padBorder.opacity(0.65))
                            .frame(width: segWidth, height: lit ? 10 : 7)
                            .shadow(color: lit ? PracticeHardware.orange.opacity(0.55) : .clear, radius: 3)
                    }
                }
                .frame(maxHeight: .infinity)

                // Goal marker tick
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 2, height: 16)
                    .offset(x: max(0, min(width - 2, width * goalFraction - 1)))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard editable, let onSetTempo else { return }
                        let ratio = min(1, max(0, value.location.x / width))
                        let newBpm = Int((Double(sliderMinBpm) + ratio * span).rounded())
                        onSetTempo(newBpm)
                    }
            )
        }
        .frame(height: 18)
        .accessibilityHidden(true)
    }

    private func stepButton(symbol: String, label: String, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 44, height: 42)
                .background {
                    RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                        .fill(PracticeHardware.padFill)
                        .overlay {
                            RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                                .strokeBorder(PracticeHardware.padBorder, lineWidth: 1)
                        }
                        .shadow(color: Color.black.opacity(0.45), radius: 3, y: 2)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
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
    var listenProgress: Double? = nil

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
        if let listenProgress {
            ProgressView(value: min(1, max(0, listenProgress)))
                .tint(Theme.orange)
                .frame(width: 120, height: blockHeight)
                .accessibilityLabel(settings.localized("Position in the current pass"))
        } else {
            scoredMeter
        }
    }

    private var scoredMeter: some View {
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
    let progressDetail: String?
    let growthLine: String?
    let growthLineHighlighted: Bool
    let rpgLine: String?
    let rpgLineHighlighted: Bool
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
        reviewPendingReason: PracticeStepOutcome.Reason? = nil,
        reviewSuccesses: Int? = nil,
        completedCoachDrillBarIndex: Int? = nil,
        drummerDelta: DrummerProgressDelta? = nil,
        keysAwarded: Int = 0
    ) -> EndOfRunCardModel {
        let scorePercent = Int((summary.score * 100).rounded())
        let earnedStars = [saved?.passed == true, saved?.mastery == true, saved?.memory == true]

        let status: EndOfRunStatus
        let progressDetail: String?
        if reviewPendingReason == .peeked {
            status = EndOfRunStatus(
                icon: "eye",
                tintOrange: false,
                title: PracticeStepOutcome.Reason.peeked.title(language: language)
            )
            progressDetail = PracticeStepOutcome.Reason.peeked.message(language: language)
        } else if let reviewFeedback {
            switch reviewFeedback {
            case .passed:
                status = EndOfRunStatus(icon: "checkmark", tintOrange: true, title: language.localized("Review passed"))
                progressDetail = nil
            case .settled:
                status = EndOfRunStatus(icon: "checkmark", tintOrange: true, title: language.localized("Lesson settled"))
                progressDetail = nil
            case .failed:
                status = EndOfRunStatus(icon: "xmark", tintOrange: false, title: language.localized("Review not passed"))
                progressDetail = nil
            case .doesNotCount(let goalBpm):
                let reason = PracticeStepOutcome.Reason.requirements(goalBpm: goalBpm)
                status = EndOfRunStatus(icon: "metronome", tintOrange: false, title: reason.title(language: language))
                progressDetail = reason.message(language: language)
            }
        } else if isAfterMe {
            status = EndOfRunStatus(
                icon: summary.score >= Scoring.passMark ? "checkmark" : "repeat",
                tintOrange: summary.score >= Scoring.passMark,
                title: language.localized("Practice only · no stars")
            )
            progressDetail = nil
        } else if let completedBarIndex = completedCoachDrillBarIndex {
            status = EndOfRunStatus(
                icon: "checkmark.circle.fill",
                tintOrange: true,
                title: language.localized("Bar %lld nailed!", completedBarIndex + 1)
            )
            progressDetail = nil
        } else if isSectionLoop {
            status = EndOfRunStatus(icon: "repeat", tintOrange: false, title: language.localized("Section loop"))
            progressDetail = nil
        } else if isDueReview {
            if saved?.lastReviewFailDay == AppCalendar.today() || saved?.reviewSchedule.lastReviewFailDay == AppCalendar.today() {
                status = EndOfRunStatus(icon: "xmark", tintOrange: false, title: language.localized("Review not passed"))
                progressDetail = nil
            } else {
                // An undecided due review must never report a regular "Passed" card (ticket 189).
                let reason = reviewPendingReason ?? .unfinishedReview
                let icon: String
                switch reason {
                case .notesVisible, .peeked: icon = "eye"
                case .unfinishedReview: icon = "eye.slash"
                case .requirements: icon = "metronome"
                case .reviewNotPassed: icon = "xmark"
                }
                status = EndOfRunStatus(
                    icon: icon,
                    tintOrange: false,
                    title: reason.title(language: language, reviewSuccesses: reviewSuccesses)
                )
                progressDetail = reason.message(language: language)
            }
        } else if summary.passes == 0 {
            status = EndOfRunStatus(icon: "stop.circle", tintOrange: false, title: language.localized("Stopped early"))
            progressDetail = language.localized("Finish one full pass to see your score")
        } else if summary.passed || runs.last?.passed == true || summary.score >= Scoring.passMark {
            status = EndOfRunStatus(icon: "checkmark", tintOrange: true, title: language.localized("Passed"))
            progressDetail = nil
        } else {
            let notPassed = language.localized("not passed")
            let title = notPassed.prefix(1).uppercased(with: Locale(identifier: language == .czech ? "cs" : "en")) + notPassed.dropFirst()
            status = EndOfRunStatus(icon: "xmark", tintOrange: false, title: title)
            progressDetail = nil
        }

        let growthLine: String?
        let growthLineHighlighted: Bool
        if summary.passes > 0, !isAfterMe, reviewPendingReason != .peeked, completedCoachDrillBarIndex == nil {
            let previousPercent = summary.previousBestScore.map { Int(($0 * 100).rounded()) }
            let isClean = summary.isCleanRun || (summary.totalBars > 0 && summary.cleanBars == summary.totalBars)
            if let previousPercent, scorePercent - previousPercent >= 1 {
                growthLine = language.localized("+%lld%% personal best", scorePercent - previousPercent)
                growthLineHighlighted = true
            } else if isClean, let previousBpm = summary.previousBpm, summary.bpm > previousBpm {
                growthLine = language.localized("New clean tempo best · %lld BPM", summary.bpm)
                growthLineHighlighted = true
            } else if summary.totalBars >= 2, summary.cleanBars > 0, let weakestBar = summary.weakestBar {
                growthLine = language.localized("%lld of %lld bars clean · watch bar %lld",
                                                summary.cleanBars, summary.totalBars, weakestBar)
                growthLineHighlighted = false
            } else if summary.totalBars > 0, summary.cleanBars == summary.totalBars {
                growthLine = language.localized("All bars clean")
                growthLineHighlighted = true
            } else {
                growthLine = nil
                growthLineHighlighted = false
            }
        } else {
            growthLine = nil
            growthLineHighlighted = false
        }

        let reviewLine: EndOfRunLine?
        if reviewPendingReason == .peeked {
            reviewLine = EndOfRunLine(kind: .review, icon: "eye",
                                     text: PracticeStepOutcome.Reason.peeked.message(language: language), isOrange: false)
        } else if let reviewFeedback {
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
                    text: language.localized("Review not met yet · you can still pass it today"),
                    isOrange: false
                )
            case .doesNotCount(let goalBpm):
                reviewLine = EndOfRunLine(
                    kind: .review,
                    icon: "calendar",
                    text: PracticeStepOutcome.Reason.requirements(goalBpm: goalBpm).message(language: language),
                    isOrange: false
                )
            }
        } else if isDueReview {
            let lineText: String
            if saved?.lastReviewFailDay == AppCalendar.today() || saved?.reviewSchedule.lastReviewFailDay == AppCalendar.today() {
                lineText = language.localized("Review not met yet · you can still pass it today")
            } else {
                let reason = reviewPendingReason ?? .unfinishedReview
                lineText = reason.message(language: language)
            }
            reviewLine = EndOfRunLine(
                kind: .review,
                icon: "calendar",
                text: lineText,
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
        } else if completedCoachDrillBarIndex != nil {
            reviewLine = nil
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

        let rpgSummary: (text: String, highlighted: Bool)?
        if summary.passes > 0, !isAfterMe, !isSectionLoop, reviewPendingReason != .peeked, completedCoachDrillBarIndex == nil {
            rpgSummary = formattedRpgLine(delta: drummerDelta, keysAwarded: keysAwarded, language: language)
        } else {
            rpgSummary = nil
        }

        return EndOfRunCardModel(
            scorePercent: scorePercent,
            bpm: summary.bpm,
            showsStars: !isAfterMe && completedCoachDrillBarIndex == nil,
            earnedStars: earnedStars,
            status: status,
            progressDetail: progressDetail,
            growthLine: growthLine,
            growthLineHighlighted: growthLineHighlighted,
            rpgLine: rpgSummary?.text,
            rpgLineHighlighted: rpgSummary?.highlighted ?? false,
            reviewLine: reviewLine,
            runsLine: runsLine,
            badgeLine: badgeLine
        )
    }

    static func formattedRpgLine(
        delta: DrummerProgressDelta?,
        keysAwarded: Int,
        language: AppLanguage
    ) -> (text: String, highlighted: Bool)? {
        if keysAwarded > 0 {
            let keyText: String
            switch language {
            case .czech:
                if keysAwarded == 1 {
                    keyText = "Získán +1 klíč!"
                } else if (2...4).contains(keysAwarded) {
                    keyText = "Získány +\(keysAwarded) klíče!"
                } else {
                    keyText = "Získáno +\(keysAwarded) klíčů!"
                }
            case .english:
                keyText = keysAwarded == 1 ? "Earned +1 key!" : "Earned +\(keysAwarded) keys!"
            }
            if let xp = delta?.xpGained, xp > 0 {
                return ("\(keyText) · +\(xp) XP", true)
            }
            return (keyText, true)
        }

        guard let delta, !delta.isEmpty else { return nil }
        var parts: [String] = []
        if delta.didLevelUp {
            parts.append("Lvl \(delta.newLevel)")
        }
        if !delta.formattedAttributeDeltas.isEmpty {
            parts.append(delta.formattedAttributeDeltas)
        }
        if delta.xpGained > 0 {
            parts.append("+\(delta.xpGained) XP")
        }
        guard !parts.isEmpty else { return nil }
        return (parts.joined(separator: " · "), delta.didLevelUp)
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

/// Modern black end-of-run card with symmetric 3-zone layout.
struct ResultCard: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(\.accessibilityReduceMotion) private var reduced

    let summary: RunSummary
    let runs: [PracticeRunResult]
    let saved: LessonProgress?
    let event: StarEvent?
    let announcement: String
    var reviewFeedback: ReviewScheduler.ReviewFeedback? = nil
    var isDueReview: Bool = false
    var reviewPendingReason: PracticeStepOutcome.Reason? = nil
    var reviewSuccesses: Int? = nil
    var badgeCount: Int = 0
    var isAfterMe: Bool = false
    var isSectionLoop: Bool = false
    var bestResponseScore: Double? = nil
    let cardWidth: CGFloat?
    var nextAction: (() -> Void)? = nil
    var nextEnabled: Bool = false
    var nextLocked: Bool = false
    var nextTitle: String? = nil
    var nextHint: String? = nil
    var restartAction: (() -> Void)? = nil
    var restartEnabled: Bool = true
    var coachSuggestion: CoachSuggestion? = nil
    var coachAction: ((CoachSuggestion) -> Void)? = nil
    var completedCoachDrillBarIndex: Int? = nil
    var finishCoachDrillAction: (() -> Void)? = nil
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
            reviewPendingReason: reviewPendingReason,
            reviewSuccesses: reviewSuccesses,
            completedCoachDrillBarIndex: completedCoachDrillBarIndex,
            drummerDelta: progress.lastDrummerDelta,
            keysAwarded: progress.lastDrummerKeysAwarded
        )
    }

    private var verdictText: String {
        if model.progressDetail != nil {
            return model.status.title
        }
        if let reviewLine = model.reviewLine, model.runsLine != nil {
            return "\(model.status.title) · \(reviewLine.text)"
        }
        return model.status.title
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

    private var showNext: Bool {
        model.progressDetail == nil && nextEnabled && nextAction != nil
    }

    private var showFinishCoachDrill: Bool {
        completedCoachDrillBarIndex != nil && finishCoachDrillAction != nil
    }

    private var showCoachSuggestion: Bool {
        !showFinishCoachDrill && !showNext && coachSuggestion != nil && coachAction != nil
    }

    private func coachSuggestionLabel(_ suggestion: CoachSuggestion) -> String {
        switch suggestion {
        case let .drillBar(barIndex, _):
            return settings.localized("Drill bar %lld", barIndex + 1)
        case let .slowDown(targetBpm):
            return settings.localized("Slow to %lld BPM", targetBpm)
        }
    }

    private var primaryNextLabel: String {
        nextTitle ?? settings.localized("Next lesson")
    }

    private var sideZoneWidth: CGFloat {
        if let cardWidth, cardWidth < 800 {
            return 156
        }
        return 176
    }

    private var dividerGap: CGFloat {
        if let cardWidth, cardWidth < 800 {
            return 20
        }
        return 28
    }

    var body: some View {
        Group {
            if isCompactWidth {
                compactBody
            } else {
                HStack(alignment: .center, spacing: 0) {
                    scoreColumn
                    verticalDivider
                        .padding(.horizontal, dividerGap)
                    middleZone
                    verticalDivider
                        .padding(.horizontal, dividerGap)
                    buttonsColumn
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
        .frame(width: cardWidth)
        .frame(minHeight: 168)
        .foregroundStyle(Theme.white)
        .background(Theme.black, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .task(id: event?.id ?? summary.id) {
            await animateFreshStars()
            if event == nil, !announcement.isEmpty {
                UIAccessibility.post(notification: .announcement, argument: announcement)
            }
        }
    }

    private var verticalDivider: some View {
        Rectangle()
            .fill(Theme.white.opacity(0.12))
            .frame(width: 1)
            .frame(maxHeight: 112)
            .accessibilityHidden(true)
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
                .minimumScaleFactor(0.8)
        }
        .frame(width: isCompactWidth ? nil : sideZoneWidth, alignment: .leading)
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
                                .frame(width: 52, height: 52)
                                .transition(.opacity)
                        }
                        Image(systemName: visible ? "star.fill" : "star")
                            .font(.system(size: isCompactWidth ? 32 : 38, weight: .regular))
                            .foregroundStyle(visible ? Theme.orange : Theme.white.opacity(0.28))
                            .scaleEffect(popping ? 1.14 : 1)
                    }
                    .frame(width: isFresh ? 52 : (isCompactWidth ? 32 : 38), height: 52)
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

    private var progressIcon: some View {
        Image(systemName: model.status.icon)
            .font(.system(size: isCompactWidth ? 30 : 36, weight: .regular))
            .foregroundStyle(Theme.white.opacity(0.85))
            .frame(height: 52)
            .accessibilityHidden(true)
    }

    private var middleZone: some View {
        VStack(alignment: .center, spacing: 6) {
            if model.progressDetail != nil {
                progressIcon
            } else if model.showsStars {
                starsRow
            } else {
                Image(systemName: model.status.icon)
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(model.status.tintOrange ? Theme.orange : Theme.white.opacity(0.85))
                    .frame(height: 52)
                    .accessibilityHidden(true)
            }

            Text(verdictText)
                .font(Theme.strong(20))
                .foregroundStyle(Theme.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)

            if let detail = model.progressDetail {
                Text(detail)
                    .font(Theme.text(14).weight(.medium))
                    .foregroundStyle(Theme.white.opacity(0.8))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 44, alignment: .center)
            } else {
                if let growthLine = model.growthLine {
                    Text(growthLine)
                        .font(Theme.meta)
                        .foregroundStyle(model.growthLineHighlighted ? Theme.orange : Theme.white.opacity(0.78))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                }

                if let rpgLine = model.rpgLine {
                    Text(rpgLine)
                        .font(Theme.meta.monospacedDigit())
                        .foregroundStyle(model.rpgLineHighlighted ? Theme.orange : Theme.white.opacity(0.72))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                }

                if let runsLine = model.runsLine {
                    summaryRowButton(runsLine)
                } else if let reviewLine = model.reviewLine {
                    summaryRowButton(reviewLine)
                } else if model.growthLine == nil && model.rpgLine == nil {
                    Color.clear.frame(height: 44)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func summaryRowButton(_ line: EndOfRunLine) -> some View {
        Button(action: openSessionResults) {
            HStack(spacing: 8) {
                Text(line.text)
                    .font(Theme.text(14).weight(.medium))
                    .foregroundStyle(Theme.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.white.opacity(0.55))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
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

    private var buttonsColumn: some View {
        VStack(spacing: 10) {
            if showFinishCoachDrill {
                let label = settings.localized("Play full lesson")
                Button {
                    finishCoachDrillAction?()
                } label: {
                    Text(label)
                        .font(Theme.action)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(PadPrimaryButtonStyle())
                .frame(width: sideZoneWidth, height: 48)
                .accessibilityLabel(label)
                .disabled(!restartEnabled || finishCoachDrillAction == nil)
                .opacity(restartEnabled ? 1 : 0.5)

                Button {
                    restartAction?()
                } label: {
                    Text(settings.localized("Again"))
                        .font(Theme.action)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(PadSecondaryButtonStyle(onDark: true))
                .frame(width: sideZoneWidth, height: 48)
                .accessibilityLabel(settings.localized("Again"))
                .disabled(!restartEnabled || restartAction == nil)
                .opacity(restartEnabled ? 1 : 0.5)
            } else if showNext {
                Button {
                    nextAction?()
                } label: {
                    Text(primaryNextLabel)
                        .font(Theme.action)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(PadPrimaryButtonStyle())
                .frame(width: sideZoneWidth, height: 48)
                .accessibilityLabel(primaryNextLabel)
                .accessibilityHint(nextHint ?? "")
                .disabled(!nextEnabled || nextAction == nil)

                Button {
                    restartAction?()
                } label: {
                    Text(settings.localized("Again"))
                        .font(Theme.action)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(PadSecondaryButtonStyle(onDark: true))
                .frame(width: sideZoneWidth, height: 48)
                .accessibilityLabel(settings.localized("Again"))
                .disabled(!restartEnabled || restartAction == nil)
                .opacity(restartEnabled ? 1 : 0.5)
            } else if showCoachSuggestion, let suggestion = coachSuggestion {
                let label = coachSuggestionLabel(suggestion)
                Button {
                    coachAction?(suggestion)
                } label: {
                    Text(label)
                        .font(Theme.action)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(PadPrimaryButtonStyle())
                .frame(width: sideZoneWidth, height: 48)
                .accessibilityLabel(label)
                .disabled(!restartEnabled || coachAction == nil)
                .opacity(restartEnabled ? 1 : 0.5)

                Button {
                    restartAction?()
                } label: {
                    Text(settings.localized("Again"))
                        .font(Theme.action)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(PadSecondaryButtonStyle(onDark: true))
                .frame(width: sideZoneWidth, height: 48)
                .accessibilityLabel(settings.localized("Again"))
                .disabled(!restartEnabled || restartAction == nil)
                .opacity(restartEnabled ? 1 : 0.5)
            } else {
                Button {
                    restartAction?()
                } label: {
                    Text(settings.localized("Again"))
                        .font(Theme.action)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(PadPrimaryButtonStyle())
                .frame(width: sideZoneWidth, height: 52)
                .accessibilityLabel(settings.localized("Again"))
                .disabled(!restartEnabled || restartAction == nil)
                .opacity(restartEnabled ? 1 : 0.5)
            }
        }
        .frame(width: sideZoneWidth, alignment: .trailing)
    }

    private var compactBody: some View {
        VStack(spacing: Theme.Space.regular) {
            HStack(alignment: .center, spacing: Theme.Space.regular) {
                scoreColumn
                Spacer(minLength: 0)
                if model.progressDetail != nil {
                    progressIcon
                } else if model.showsStars {
                    starsRow
                } else if model.status.tintOrange {
                    Image(systemName: model.status.icon)
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(Theme.orange)
                        .frame(height: 44)
                        .accessibilityHidden(true)
                }
            }

            VStack(spacing: 8) {
                Text(verdictText)
                    .font(Theme.strong(18))
                    .foregroundStyle(Theme.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)

                if let detail = model.progressDetail {
                    Text(detail)
                        .font(Theme.text(14).weight(.medium))
                        .foregroundStyle(Theme.white.opacity(0.8))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                        .frame(minHeight: 44, alignment: .center)
                } else {
                    if let growthLine = model.growthLine {
                        Text(growthLine)
                            .font(Theme.meta)
                            .foregroundStyle(model.growthLineHighlighted ? Theme.orange : Theme.white.opacity(0.78))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.center)
                    }

                    if let runsLine = model.runsLine {
                        summaryRowButton(runsLine)
                    } else if let reviewLine = model.reviewLine {
                        summaryRowButton(reviewLine)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: Theme.Space.controlGap) {
                if showFinishCoachDrill {
                    let label = settings.localized("Play full lesson")
                    Button {
                        finishCoachDrillAction?()
                    } label: {
                        Text(label)
                            .font(Theme.action)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(PadPrimaryButtonStyle())
                    .frame(height: 48)
                    .accessibilityLabel(label)
                    .disabled(!restartEnabled || finishCoachDrillAction == nil)
                    .opacity(restartEnabled ? 1 : 0.5)

                    Button {
                        restartAction?()
                    } label: {
                        Text(settings.localized("Again"))
                            .font(Theme.action)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(PadSecondaryButtonStyle(onDark: true))
                    .frame(height: 48)
                    .accessibilityLabel(settings.localized("Again"))
                    .disabled(!restartEnabled || restartAction == nil)
                    .opacity(restartEnabled ? 1 : 0.5)
                } else if showNext {
                    Button {
                        nextAction?()
                    } label: {
                        Text(primaryNextLabel)
                            .font(Theme.action)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(PadPrimaryButtonStyle())
                    .frame(height: 48)
                    .accessibilityLabel(primaryNextLabel)
                    .accessibilityHint(nextHint ?? "")
                    .disabled(!nextEnabled || nextAction == nil)

                    Button {
                        restartAction?()
                    } label: {
                        Text(settings.localized("Again"))
                            .font(Theme.action)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(PadSecondaryButtonStyle(onDark: true))
                    .frame(height: 48)
                    .accessibilityLabel(settings.localized("Again"))
                    .disabled(!restartEnabled || restartAction == nil)
                    .opacity(restartEnabled ? 1 : 0.5)
                } else if showCoachSuggestion, let suggestion = coachSuggestion {
                    let label = coachSuggestionLabel(suggestion)
                    Button {
                        coachAction?(suggestion)
                    } label: {
                        Text(label)
                            .font(Theme.action)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(PadPrimaryButtonStyle())
                    .frame(height: 48)
                    .accessibilityLabel(label)
                    .disabled(!restartEnabled || coachAction == nil)
                    .opacity(restartEnabled ? 1 : 0.5)

                    Button {
                        restartAction?()
                    } label: {
                        Text(settings.localized("Again"))
                            .font(Theme.action)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(PadSecondaryButtonStyle(onDark: true))
                    .frame(height: 48)
                    .accessibilityLabel(settings.localized("Again"))
                    .disabled(!restartEnabled || restartAction == nil)
                    .opacity(restartEnabled ? 1 : 0.5)
                } else {
                    Button {
                        restartAction?()
                    } label: {
                        Text(settings.localized("Again"))
                            .font(Theme.action)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(PadPrimaryButtonStyle())
                    .frame(height: 52)
                    .accessibilityLabel(settings.localized("Again"))
                    .disabled(!restartEnabled || restartAction == nil)
                    .opacity(restartEnabled ? 1 : 0.5)
                }
            }
        }
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
            Rectangle().strokeBorder(flashingOutline ? Theme.destructive : Theme.hairline, lineWidth: 1)
        }
    }
}
