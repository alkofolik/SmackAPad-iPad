import SwiftUI

/// Channels represented by the real Home faders (ticket 191).
private enum HomeFaderChannel: Int, CaseIterable, Identifiable {
    case metronome = 0
    case pattern = 1
    case pads = 2

    var id: Int { rawValue }

    func title(settings: SettingsManager) -> String {
        switch self {
        case .metronome:
            return settings.localized("Metronome")
        case .pattern:
            return settings.localized("settings.sound.pattern")
        case .pads:
            return settings.localized("Pads")
        }
    }

    func volume(settings: SettingsManager) -> Int {
        switch self {
        case .metronome:
            return settings.metronomeVolume
        case .pattern:
            return settings.patternVolume
        case .pads:
            return settings.padsVolume
        }
    }

    func setVolume(_ value: Int, settings: SettingsManager) {
        switch self {
        case .metronome:
            settings.metronomeVolume = value
        case .pattern:
            settings.patternVolume = value
        case .pads:
            settings.padsVolume = value
        }
    }

    var defaultVolume: Int {
        switch self {
        case .metronome:
            return SettingsManager.defaultMetronomeVolume
        case .pattern:
            return SettingsManager.defaultPatternVolume
        case .pads:
            return SettingsManager.defaultPadsVolume
        }
    }
}

/// Interactive fader bank replacing the static decorative faders on Home (ticket 191).
struct HomeControllerFaders: View {
    let layout: HomeControllerLayout
    let darkAppearance: Bool

    var body: some View {
        ZStack {
            if layout.landscape {
                landscapeFaders
            } else {
                portraitFaders
            }
        }
        .frame(width: layout.size.width, height: layout.size.height)
    }

    @ViewBuilder
    private var landscapeFaders: some View {
        let bayWidth = layout.plate.minX
        let u = min(layout.unit, max(0, bayWidth - 2 * layout.margin) / 134)
        if u > 0 {
            let height = 217 * u
            let topY = layout.plate.minY
            let leftCenterX = bayWidth / 2
            let x0 = leftCenterX - 67 * u
            let x1 = leftCenterX + 11 * u
            let rightCenterX = layout.size.width - bayWidth / 2
            let x2 = rightCenterX - 28 * u
            let margin = 12 * u

            // Metronome (left bay, left channel)
            HomeControllerFaderView(
                channel: .metronome,
                unit: u,
                faderSize: CGSize(width: 56 * u, height: height),
                horizontalMargin: margin,
                mirrored: false,
                portrait: false,
                darkAppearance: darkAppearance
            )
            .position(x: x0 + 28 * u, y: topY + height / 2)

            // Pattern (left bay, right channel)
            HomeControllerFaderView(
                channel: .pattern,
                unit: u,
                faderSize: CGSize(width: 56 * u, height: height),
                horizontalMargin: margin,
                mirrored: false,
                portrait: false,
                darkAppearance: darkAppearance
            )
            .position(x: x1 + 28 * u, y: topY + height / 2)

            // Pads (right bay, centered)
            HomeControllerFaderView(
                channel: .pads,
                unit: u,
                faderSize: CGSize(width: 56 * u, height: height),
                horizontalMargin: margin,
                mirrored: true,
                portrait: false,
                darkAppearance: darkAppearance
            )
            .position(x: x2 + 28 * u, y: topY + height / 2)
        }
    }

    @ViewBuilder
    private var portraitFaders: some View {
        let availableWidth = max(0, layout.size.width - 2 * layout.portraitControlWidth - 2 * layout.margin)
        let u = min(layout.unit, availableWidth / 264)
        let height = layout.portraitFaderHeight
        if layout.portraitFadersFit && u > 0 {
            let startX = (layout.size.width - 264 * u) / 2
            let channels: [HomeFaderChannel] = [.metronome, .pattern, .pads]
            ForEach(0..<3, id: \.self) { idx in
                HomeControllerFaderView(
                    channel: channels[idx],
                    unit: u,
                    faderSize: CGSize(width: 52 * u, height: height),
                    horizontalMargin: 18 * u,
                    mirrored: false,
                    portrait: true,
                    darkAppearance: darkAppearance
                )
                .position(x: startX + CGFloat(idx) * 88 * u + 44 * u,
                          y: layout.portraitBayTop + height / 2)
            }
        }
    }
}

/// One interactive fader control: real values, haptic tick at 0 dB (100 %) and bottom (0 %), double tap reset.
private struct HomeControllerFaderView: View {
    let channel: HomeFaderChannel
    let unit: CGFloat
    let faderSize: CGSize
    let horizontalMargin: CGFloat
    let mirrored: Bool
    let portrait: Bool
    let darkAppearance: Bool

    @Environment(SettingsManager.self) private var settings
    @State private var dragInitialCapY: CGFloat? = nil
    @State private var dragTouchStartY: CGFloat? = nil
    @State private var lastHapticVolume: Int? = nil
    @State private var lastTapTime: Date = .distantPast

    var body: some View {
        let u = unit
        let totalWidth = faderSize.width + 2 * horizontalMargin
        let totalHeight = faderSize.height
        let faderMinX = horizontalMargin
        let trackTop = 17 * u
        let travel = totalHeight - trackTop
        let capHeight: CGFloat = (portrait ? 28 : 34) * u
        let capWidth: CGFloat = (portrait ? 24 : 26) * u
        let trackWidth: CGFloat = (portrait ? 26 : 28) * u
        let trackX = mirrored ? faderMinX + trackWidth / 2 : faderMinX + faderSize.width - trackWidth / 2
        let minY = trackTop + capHeight / 2
        let maxY = totalHeight - capHeight / 2
        let effectiveTravel = maxY - minY
        let currentVolume = channel.volume(settings: settings)
        let currentCapY = FaderValueMapping.yPosition(fromVolumePercent: currentVolume, minY: minY, maxY: maxY)

        Canvas { context, _ in
            drawBackground(
                in: context,
                unit: u,
                faderMinX: faderMinX,
                trackTop: trackTop,
                travel: travel,
                trackWidth: trackWidth,
                trackX: trackX,
                minY: minY,
                maxY: maxY,
                effectiveTravel: effectiveTravel
            )
            drawCap(
                in: context,
                unit: u,
                capWidth: capWidth,
                capHeight: capHeight,
                trackX: trackX,
                capY: currentCapY
            )
        }
        .frame(width: totalWidth, height: totalHeight)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let touchY = value.location.y
                    if dragTouchStartY == nil {
                        dragTouchStartY = value.startLocation.y
                        dragInitialCapY = currentCapY
                    }
                    let initialCapY = dragInitialCapY ?? currentCapY
                    let startTouchY = dragTouchStartY ?? value.startLocation.y

                    let targetY: CGFloat
                    if abs(startTouchY - initialCapY) <= capHeight / 2 + 10 * u {
                        targetY = initialCapY + (touchY - startTouchY)
                    } else {
                        targetY = touchY
                    }

                    let newVolume = FaderValueMapping.volumePercent(fromY: targetY, minY: minY, maxY: maxY)
                    let oldVolume = channel.volume(settings: settings)
                    if newVolume != oldVolume {
                        if (newVolume == 100 && lastHapticVolume != 100) || (newVolume == 0 && lastHapticVolume != 0) {
                            triggerHaptic()
                            lastHapticVolume = newVolume
                        } else if newVolume != 100 && newVolume != 0 {
                            lastHapticVolume = nil
                        }
                        channel.setVolume(newVolume, settings: settings)
                    }
                }
                .onEnded { value in
                    dragTouchStartY = nil
                    dragInitialCapY = nil
                    lastHapticVolume = nil
                    let distSq = value.translation.width * value.translation.width + value.translation.height * value.translation.height
                    if distSq < 36 {
                        let now = Date()
                        if now.timeIntervalSince(lastTapTime) < 0.35 {
                            resetToDefault()
                            lastTapTime = .distantPast
                        } else {
                            lastTapTime = now
                        }
                    } else {
                        lastTapTime = .distantPast
                    }
                }
        )
        .onTapGesture(count: 2) {
            resetToDefault()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(channel.title(settings: settings))
        .accessibilityValue(SoundSliderRow.formatDB(fromPercent: currentVolume))
        .accessibilityAdjustableAction { direction in
            let current = channel.volume(settings: settings)
            switch direction {
            case .increment:
                let newVolume = min(100, current + 5)
                channel.setVolume(newVolume, settings: settings)
            case .decrement:
                let newVolume = max(0, current - 5)
                channel.setVolume(newVolume, settings: settings)
            @unknown default:
                break
            }
        }
    }

    private func resetToDefault() {
        let def = channel.defaultVolume
        channel.setVolume(def, settings: settings)
        triggerHaptic()
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func drawBackground(
        in context: GraphicsContext,
        unit u: CGFloat,
        faderMinX: CGFloat,
        trackTop: CGFloat,
        travel: CGFloat,
        trackWidth: CGFloat,
        trackX: CGFloat,
        minY: CGFloat,
        maxY: CGFloat,
        effectiveTravel: CGFloat
    ) {
        // Channel name in sentence case, not tiny uppercase, not monospaced
        let title = channel.title(settings: settings)
        engraved(
            title,
            in: context,
            unit: u,
            at: CGPoint(x: faderMinX + faderSize.width / 2, y: 4.5 * u),
            size: (portrait ? 9.5 : 10.5) * u,
            anchor: .center,
            prominent: true,
            monospaced: false
        )

        // Slot
        let slot = CGRect(x: trackX - 3 * u, y: trackTop, width: 6 * u, height: travel)
        context.fill(Path(roundedRect: slot.offsetBy(dx: 0, dy: u), cornerRadius: 3 * u),
                     with: .color(Theme.white.opacity(darkAppearance ? 0.08 : 0.65)))
        context.fill(Path(roundedRect: slot, cornerRadius: 3 * u), with: .color(Theme.HomeController.slot))
        context.fill(Path(CGRect(x: trackX, y: trackTop + u, width: 0.6 * u, height: travel - 2 * u)),
                     with: .color(Theme.white.opacity(0.15)))

        // dB Scale marks and labels
        let scalePercents: [Int] = effectiveTravel >= 70 * u ? [100, 70, 50, 25, 10, 0] : [100, 50, 25, 0]
        for percent in scalePercents {
            let y = FaderValueMapping.yPosition(fromVolumePercent: percent, minY: minY, maxY: maxY)
            let major = percent == 100
            let length: CGFloat = (major ? 8 : 5) * u
            let tickX = mirrored ? trackX + trackWidth / 2 + 4 * u : trackX - trackWidth / 2 - 4 * u - length
            context.fill(Path(CGRect(x: tickX, y: y, width: length, height: (major ? 1.5 : 1) * u)),
                         with: .color(Theme.ink.opacity(major ? 0.65 : 0.32)))
            let text = SoundSliderRow.formatDB(fromPercent: percent)
            engraved(
                text,
                in: context,
                unit: u,
                at: CGPoint(x: mirrored ? tickX + length + 3 * u : tickX - 3 * u, y: y),
                size: 8 * u,
                anchor: mirrored ? .leading : .trailing,
                prominent: major,
                monospaced: true
            )
        }
    }

    private func drawCap(
        in context: GraphicsContext,
        unit u: CGFloat,
        capWidth: CGFloat,
        capHeight: CGFloat,
        trackX: CGFloat,
        capY: CGFloat
    ) {
        let cap = CGRect(x: trackX - capWidth / 2, y: capY - capHeight / 2, width: capWidth, height: capHeight)
        let shape = Path(roundedRect: cap, cornerRadius: 3 * u)
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: Theme.black.opacity(darkAppearance ? 0.6 : 0.22),
                                    radius: 4 * u, x: 0, y: 4 * u))
            layer.fill(shape, with: .linearGradient(Gradient(stops: [
                .init(color: Theme.HomeController.capTop, location: 0),
                .init(color: Theme.HomeController.capMiddle, location: 0.48),
                .init(color: Theme.HomeController.capShade, location: 0.52),
                .init(color: Theme.HomeController.capBottom, location: 1)
            ]), startPoint: cap.origin, endPoint: CGPoint(x: cap.minX, y: cap.maxY)))
        }
        context.stroke(shape, with: .color(Theme.black.opacity(darkAppearance ? 0.65 : 0.32)), lineWidth: u)
        context.fill(Path(CGRect(x: cap.minX + 3 * u, y: cap.minY + u, width: cap.width - 6 * u, height: u)),
                     with: .color(Theme.white.opacity(darkAppearance ? 0.2 : 0.75)))
        for offset in [-6.0, -2, 2, 6] {
            context.fill(Path(CGRect(x: cap.midX - 8 * u, y: cap.midY + offset * u, width: 16 * u, height: u)),
                         with: .color(Theme.black.opacity(darkAppearance ? 0.5 : 0.28)))
        }
        // Center indicator stripe
        context.fill(Path(CGRect(x: cap.minX + 3 * u, y: cap.midY - u, width: cap.width - 6 * u, height: 2 * u)),
                     with: .color(channel == .pads ? Theme.orange : Theme.ink))
    }

    private func engraved(
        _ text: String,
        in context: GraphicsContext,
        unit u: CGFloat,
        at point: CGPoint,
        size: CGFloat,
        anchor: UnitPoint = .center,
        prominent: Bool = false,
        monospaced: Bool = false
    ) {
        let font = monospaced ? Theme.canvasDisplay(size).monospacedDigit() : Theme.strong(size)
        let label = Text(verbatim: text).font(font)
        context.draw(label.foregroundColor(Theme.white.opacity(darkAppearance ? 0.08 : 0.6)),
                     at: CGPoint(x: point.x, y: point.y + u * 0.6), anchor: anchor)
        context.draw(label.foregroundColor(prominent ? Theme.ink : Theme.secondary), at: point, anchor: anchor)
    }
}
