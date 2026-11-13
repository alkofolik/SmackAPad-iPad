import SwiftUI

func hasAnyLessonProgress(_ records: [Int: LessonProgress]) -> Bool {
    records.values.contains { $0.hasPlayed || $0.passed || $0.mastery || $0.memory }
}

func shouldPulseIntroPad(
    loadSucceeded: Bool,
    records: [Int: LessonProgress],
    animationFinished: Bool
) -> Bool {
    loadSucceeded && animationFinished && !hasAnyLessonProgress(records)
}

/// One proportional coordinate system for the display, plate and interactive hardware.
private struct HomeControllerLayout: Equatable {
    let size: CGSize
    let cellSize: CGFloat

    init(size: CGSize) {
        self.size = size
        let shorterSide = min(size.width, size.height)
        // Preserve the existing grid ceiling; reserve 35% of the short axis for the body.
        let maxCellSize = (680 - 2 * Theme.Space.regular) / 3
        let plateInCells: CGFloat = 3 + 2 * (15.0 / 146) + 2 * (36.0 / 146)
        let footer = size.width >= size.height ? 44.0 : 144 + Theme.Space.page + shorterSide * 0.05
        let verticalBudget = max(0, size.height - 44 - 96 - Theme.Space.regular - footer)
        cellSize = max(0, floor(min(maxCellSize, min(shorterSide * 0.65, verticalBudget) / plateInCells)))
    }

    var unit: CGFloat { cellSize / 146 }
    var gap: CGFloat { 15 * unit }
    var gridSize: CGFloat { 3 * cellSize + 2 * gap }
    var plateSize: CGFloat { gridSize + 72 * unit }
    var landscape: Bool { size.width >= size.height }
    var margin: CGFloat { min(size.width, size.height) * 0.025 }
    var displayHeight: CGFloat { max(64, min(96, plateSize * 0.16)) }
    var display: CGRect {
        CGRect(x: (size.width - plateSize) / 2,
               y: landscape ? max(44, (size.height - plateSize - displayHeight - Theme.Space.regular) / 2) : 44,
               width: plateSize, height: displayHeight)
    }
    var plate: CGRect {
        CGRect(x: display.minX, y: display.maxY + Theme.Space.regular,
               width: plateSize, height: plateSize)
    }
    var portraitBayTop: CGFloat { plate.maxY + Theme.Space.page }
    var portraitControlWidth: CGFloat { min(180, max(96, size.width * 0.23)) }
    var portraitFaderHeight: CGFloat {
        min(340 * unit, max(0, size.height - portraitBayTop - 2 * margin))
    }
    var portraitFadersFit: Bool {
        unit > 0 && portraitFaderHeight - 17 * unit >= max(64 * unit, Theme.Size.touch)
    }
}

/// Static moulded plastic. Equatable isolates the rasterised surface from Home's launch/pad states.
private struct HomeControllerBody: View, Equatable {
    let darkAppearance: Bool

    var body: some View {
        Canvas { context, size in
            let bounds = CGRect(origin: .zero, size: size)
            context.fill(Path(bounds), with: .linearGradient(
                Gradient(colors: [Theme.HomeController.bodyTop, Theme.HomeController.bodyBottom]),
                startPoint: .zero, endPoint: CGPoint(x: size.width * 0.14, y: size.height)
            ))
            // Strong preview variant: a top highlight and lower shadow at a fixed 4 pt pitch.
            for y in stride(from: CGFloat(0), to: size.height, by: 4) {
                let groove = CGRect(x: 0, y: y + 2, width: size.width, height: 2)
                context.fill(Path(groove), with: .linearGradient(
                    Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: Theme.HomeController.ribLight, location: 0.25),
                        .init(color: Theme.HomeController.ribShadow, location: 0.75),
                        .init(color: .clear, location: 1)
                    ]), startPoint: CGPoint(x: 0, y: groove.minY),
                    endPoint: CGPoint(x: 0, y: groove.maxY)
                ))
            }
            // An elliptical vignette follows the screen instead of darkening the title band.
            var vignette = context
            vignette.scaleBy(x: size.width, y: size.height)
            vignette.fill(Path(CGRect(x: 0, y: 0, width: 1, height: 1)), with: .radialGradient(
                Gradient(colors: [.clear, Theme.black.opacity(darkAppearance ? 0.35 : 0.07)]),
                center: CGPoint(x: 0.5, y: 0.5), startRadius: 0.35, endRadius: 0.8
            ))
        }
        .drawingGroup()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The brushed plate, screws and faders share one static raster, separate from interactive pads.
private struct HomeControllerHardware: View, Equatable {
    let layout: HomeControllerLayout
    let darkAppearance: Bool

    var body: some View {
        Canvas { context, _ in
            guard layout.unit > 0 else { return }
            drawPlate(in: &context)
        }
        .drawingGroup()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawPlate(in context: inout GraphicsContext) {
        let u = layout.unit
        let rect = layout.plate
        let radius = Theme.Radius.controllerPlate * u
        let plate = Path(roundedRect: rect, cornerRadius: radius)
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: Theme.black.opacity(darkAppearance ? 0.55 : 0.09),
                                    radius: 20 * u, x: 0, y: 6 * u))
            layer.fill(plate, with: plateGradient(in: rect))
        }
        var brushed = context
        brushed.clip(to: plate)
        for x in stride(from: rect.minX, to: rect.maxX, by: 2 * u) {
            brushed.fill(Path(CGRect(x: x, y: rect.minY, width: 0.5 * u, height: rect.height)),
                         with: .color(Theme.white.opacity(0.035)))
            brushed.fill(Path(CGRect(x: x + u, y: rect.minY, width: 0.5 * u, height: rect.height)),
                         with: .color(Theme.black.opacity(0.035)))
        }
        // Clipped offset outlines leave a narrow highlight above and a dark bevel below.
        brushed.stroke(Path(roundedRect: rect.offsetBy(dx: 0, dy: 1.5 * u), cornerRadius: radius),
                       with: .color(Theme.white.opacity(darkAppearance ? 0.24 : 0.85)), lineWidth: 1.5 * u)
        brushed.stroke(Path(roundedRect: rect.offsetBy(dx: 0, dy: -1.5 * u), cornerRadius: radius),
                       with: .color(Theme.black.opacity(darkAppearance ? 0.7 : 0.2)), lineWidth: 1.5 * u)
        context.stroke(plate, with: .color(Theme.ink.opacity(darkAppearance ? 0.18 : 0.22)), lineWidth: u)

        let inset = 18 * u
        let screws: [(CGPoint, Double)] = [
            (CGPoint(x: rect.minX + inset, y: rect.minY + inset), -24),
            (CGPoint(x: rect.maxX - inset, y: rect.minY + inset), 51),
            (CGPoint(x: rect.minX + inset, y: rect.maxY - inset), 108),
            (CGPoint(x: rect.maxX - inset, y: rect.maxY - inset), -63)
        ]
        for (point, angle) in screws {
            drawScrew(in: context, at: point, angle: angle)
        }
    }

    private func plateGradient(in rect: CGRect) -> GraphicsContext.Shading {
        .linearGradient(Gradient(stops: [
            .init(color: Theme.HomeController.plateTop, location: 0),
            .init(color: Theme.HomeController.plateShade, location: 0.38),
            .init(color: Theme.HomeController.plateLight, location: 0.62),
            .init(color: Theme.HomeController.plateBottom, location: 1)
        ]), startPoint: CGPoint(x: rect.minX, y: rect.minY),
            endPoint: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.maxY))
    }

    private func drawScrew(in context: GraphicsContext, at point: CGPoint, angle: Double) {
        let u = layout.unit
        var head = context
        head.translateBy(x: point.x, y: point.y)
        let rect = CGRect(x: -9 * u, y: -9 * u, width: 18 * u, height: 18 * u)
        let circle = Path(ellipseIn: rect)
        head.drawLayer { layer in
            layer.addFilter(.shadow(color: Theme.black.opacity(0.32), radius: 1.5 * u, x: 0, y: u))
            layer.fill(circle, with: .linearGradient(Gradient(stops: [
                .init(color: Theme.HomeController.screwTop, location: 0),
                .init(color: Theme.HomeController.screwMiddle, location: 0.35),
                .init(color: Theme.HomeController.screwShade, location: 0.7),
                .init(color: Theme.HomeController.screwBottom, location: 1)
            ]), startPoint: rect.origin, endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
        }
        head.stroke(circle, with: .color(Theme.ink.opacity(0.28)), lineWidth: u)
        head.stroke(Path(ellipseIn: rect.insetBy(dx: 1.5 * u, dy: 1.5 * u)),
                    with: .color(Theme.white.opacity(darkAppearance ? 0.15 : 0.35)), lineWidth: 0.6 * u)
        head.rotate(by: .degrees(angle))
        let slot = CGRect(x: -6 * u, y: -1.3 * u, width: 12 * u, height: 2.6 * u)
        head.fill(Path(roundedRect: slot.offsetBy(dx: 0, dy: 0.7 * u), cornerRadius: 0.6 * u),
                  with: .color(Theme.white.opacity(darkAppearance ? 0.2 : 0.6)))
        head.fill(Path(roundedRect: slot, cornerRadius: 0.6 * u), with: .color(Theme.HomeController.slot))
    }
}

// MARK: - Home Hardware Faders

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
private struct HomeControllerFaders: View {
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

/// Tactile pad press animation style (scale 0.965 and 1.5 pt down, 60 ms light flash, spring back in 0.18 s).
/// Reduce Motion: darker fill only (0.1 s), no scale or movement.
struct TactilePadButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let policy = Theme.Motion.Policy(reduced: reduceMotion)
        let isPressed = configuration.isPressed

        configuration.label
            .overlay {
                if policy.reduced {
                    if isPressed {
                        RoundedRectangle(cornerRadius: Theme.Radius.pad)
                            .fill(Theme.black.opacity(0.12))
                            .allowsHitTesting(false)
                    }
                } else {
                    RoundedRectangle(cornerRadius: Theme.Radius.pad)
                        .fill(Theme.white)
                        .opacity(isPressed ? 0.38 : 0.0)
                        .animation(Theme.Motion.padFlash, value: isPressed)
                        .allowsHitTesting(false)
                }
            }
            .scaleEffect(policy.scale(isPressed ? 0.965 : 1.0))
            .offset(y: policy.offset(isPressed ? 1.5 : 0))
            .animation(
                policy.reduced ? .easeOut(duration: 0.1) : (isPressed ? .easeOut(duration: 0.06) : Theme.Motion.padPress),
                value: isPressed
            )
    }
}

/// The breathing light bar along the top edge of a lit pad (Training with reviews due, ticket 112).
struct PadLightBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    var body: some View {
        GeometryReader { geo in
            let inset = geo.size.width * 0.22
            VStack(spacing: 0) {
                Capsule()
                    .fill(Theme.orange)
                    .frame(height: 2)
                    .shadow(color: Theme.orange.opacity(0.8), radius: 3)
                    .padding(.horizontal, inset)
                    .padding(.top, 7)
                    .opacity(Theme.Motion.Policy(reduced: reduceMotion).breathingOpacity(animating: breathing))
                Spacer(minLength: 0)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !Theme.Motion.Policy(reduced: reduceMotion).reduced else { return }
            withAnimation(Theme.Motion.ledBreath) {
                breathing = true
            }
        }
        .onChange(of: reduceMotion) { _, isReduced in
            if isReduced {
                breathing = false
            } else {
                withAnimation(Theme.Motion.ledBreath) {
                    breathing = true
                }
            }
        }
    }
}

/// Pure subtitle and target helpers for the 8 Home pads so logic stays testable without views.
enum HomePadSubtitles {
    static func singleLine(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func today(plan: TodayPlan?, language: AppLanguage) -> String? {
        guard let plan, !plan.finished else { return nil }
        let remaining = max(0, plan.steps.count - plan.index)
        guard remaining > 0 else { return nil }
        return singleLine(language.localizedLessonCount(remaining))
    }

    static func library() -> String? {
        nil
    }

    static func continueLesson(lastPlayedLesson: Lesson?, language: AppLanguage) -> String? {
        guard let lastPlayedLesson else { return nil }
        let shortKey = "home.short.\(lastPlayedLesson.title)"
        let localizedCandidate = language.localizedOptional(shortKey) ?? language.localized(lastPlayedLesson.title)
        let localized = singleLine(localizedCandidate)
        return localized.isEmpty ? nil : localized
    }

    static func continueTarget(
        lastPlayedLesson: Lesson?,
        introFirstLesson: Lesson?,
        pathFirstLesson: Lesson?
    ) -> Lesson? {
        lastPlayedLesson ?? introFirstLesson ?? pathFirstLesson
    }

    static func intro() -> String? {
        nil
    }

    static func controller(connectedName: String?, language: AppLanguage) -> String {
        guard let connectedName else {
            return singleLine(language.localized("Not connected"))
        }
        let trimmed = singleLine(connectedName)
        guard !trimmed.isEmpty else {
            return singleLine(language.localized("Not connected"))
        }

        if isNetworkSession(trimmed) {
            return language == .czech ? "Síťový MIDI" : "Network MIDI"
        }

        return truncateAtWordBoundary(trimmed, limit: 14)
    }

    static func isNetworkSession(_ name: String) -> Bool {
        let lower = name.lowercased()
        if lower.contains("network session") || lower.contains("síťová relace") || lower.contains("sitova relace") {
            return true
        }
        if lower == "network midi" || lower == "síťový midi" || lower == "sitovy midi" {
            return true
        }
        return false
    }

    static func truncateAtWordBoundary(_ text: String, limit: Int = 14) -> String {
        guard text.count > limit else { return text }
        let words = text.split(whereSeparator: \.isWhitespace).map(String.init)
        guard let first = words.first else { return "" }
        if first.count >= limit {
            return first
        }
        var result = first
        for word in words.dropFirst() {
            let candidate = result + " " + word
            if candidate.count <= limit {
                result = candidate
            } else {
                break
            }
        }
        return result
    }

    static func badges(earned: Int, total: Int) -> String {
        "\(earned) / \(total)"
    }

    static func fullVersion(hasFullAccess: Bool, price: String?, language: AppLanguage) -> String? {
        if hasFullAccess {
            return singleLine(language.localized("Unlocked"))
        }
        guard let price else { return nil }
        let trimmed = singleLine(price)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func settings() -> String? {
        nil
    }
}

/// A tactile button pad on the Home screen.
struct HomePadView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let title: String
    let subtitle: String?
    var numericTransitionValue: Int? = nil
    var accessibilityText: String? = nil
    var accessibilityValue: String? = nil
    var isLit: Bool = false
    var padNumber: Int? = nil
    var cellSize: CGFloat = 146
    let isHero: Bool
    let action: () -> Void

    var body: some View {
        let policy = Theme.Motion.Policy(reduced: reduceMotion)

        Button(action: action) {
            VStack(spacing: Theme.Space.tight) {
                Spacer(minLength: 0)
                let titleSize = 22.0 * (cellSize / 146.0)
                Text(title.uppercased())
                    .font(Theme.padTitle(size: titleSize))
                    .tracking(titleSize * 0.03)
                    .foregroundStyle(isHero ? Theme.black : Theme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                let trimmedSubtitle = subtitle.map(HomePadSubtitles.singleLine) ?? ""
                let hasSubtitle = !trimmedSubtitle.isEmpty
                subtitleText(trimmedSubtitle: trimmedSubtitle, hasSubtitle: hasSubtitle, policy: policy)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Space.small)
            // Reserve the engraving band before text fitting chooses subtitle variants.
            .padding(.top, padNumber == nil ? 0 : 22)
            .padding(.bottom, Theme.Space.small)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.pad)
                    .fill(isHero ? Theme.orange : Theme.surface)
                    .shadow(
                        color: isLit ? Theme.orange.opacity(0.4) : (isHero ? Theme.orange.opacity(0.25) : Theme.black.opacity(0.08)),
                        radius: isLit ? 7 : (isHero ? 3 : 2),
                        x: 0,
                        y: isLit ? 0 : (isHero ? 3 : 2)
                    )
            )
            .overlay {
                // Two-tone bevel: top 1.5 pt light highlight, bottom 2 pt darker edge (proposal A)
                VStack(spacing: 0) {
                    (isHero ? Theme.white.opacity(0.42) : Theme.padBevelTop)
                        .frame(height: 1.5)
                    Spacer(minLength: 0)
                    (isHero ? Theme.black.opacity(0.28) : Theme.padBevelBottom)
                        .frame(height: isHero ? 2.5 : 2.0)
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pad))
                .allowsHitTesting(false)
            }
            .overlay {
                // Outline: 2 pt orange for lit state, 1 pt hairline (or black opacity for hero) otherwise
                if isLit {
                    RoundedRectangle(cornerRadius: Theme.Radius.pad)
                        .strokeBorder(Theme.orange, lineWidth: 2)
                        .allowsHitTesting(false)
                } else if isHero {
                    RoundedRectangle(cornerRadius: Theme.Radius.pad)
                        .strokeBorder(Theme.black.opacity(0.12), lineWidth: 1)
                        .allowsHitTesting(false)
                } else {
                    RoundedRectangle(cornerRadius: Theme.Radius.pad)
                        .strokeBorder(Theme.hairline, lineWidth: 1)
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                if isLit {
                    PadLightBar()
                }
            }
            .overlay(alignment: .topLeading) {
                if let padNumber {
                    Text(verbatim: String(format: "%02d", padNumber))
                        .font(Theme.canvasDisplay(9).monospacedDigit())
                        .foregroundStyle(isHero ? Theme.black : Theme.secondary)
                        .shadow(color: Theme.white.opacity(isHero ? 0.3 : 0.45), radius: 0, y: 0.6)
                        .padding(.leading, 8)
                        .padding(.top, 7)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.pad))
        }
        .buttonStyle(TactilePadButtonStyle())
        .accessibilityLabel(accessibilityText ?? defaultAccessibilityText)
        .modifier(AccessibilityValueModifier(value: accessibilityValue))
    }

    @ViewBuilder
    private func subtitleText(
        trimmedSubtitle: String,
        hasSubtitle: Bool,
        policy: Theme.Motion.Policy
    ) -> some View {
        let base = Text(hasSubtitle ? trimmedSubtitle : " ")
            .font(Theme.meta)
            .foregroundStyle(isHero ? Theme.black : Theme.secondary)
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .opacity(hasSubtitle ? 1 : 0)
            .accessibilityHidden(!hasSubtitle)

        if let numericTransitionValue, hasSubtitle {
            base
                .contentTransition(policy.numeric)
                .motion(value: numericTransitionValue)
        } else {
            base
        }
    }

    private var defaultAccessibilityText: String {
        var parts: [String] = [title]
        if let subtitle {
            let trimmed = HomePadSubtitles.singleLine(subtitle)
            if !trimmed.isEmpty {
                parts.append(trimmed)
            }
        }
        return parts.joined(separator: ", ")
    }
}

private struct AccessibilityValueModifier: ViewModifier {
    let value: String?
    @ViewBuilder
    func body(content: Content) -> some View {
        if let value, !value.isEmpty {
            content.accessibilityValue(value)
        } else {
            content
        }
    }
}


/// The centre logo mark (three pads + rotated orange pad at 8°, optically centred).
struct HomeLogoMarkView: View {
    let size: CGFloat
    let darkAppearance: Bool
    private static let blackPad = Color(red: 17 / 255.0, green: 17 / 255.0, blue: 17 / 255.0)
    private static let creamPad = Color(red: 242 / 255.0, green: 240 / 255.0, blue: 234 / 255.0)
    private static let orangePad = Color(red: 255 / 255.0, green: 91 / 255.0, blue: 31 / 255.0)

    var body: some View {
        let unit = size / 100.0
        let padDimension = 32.0 * unit
        let cornerRadius = 3.0 * unit
        let neutralPadColor = darkAppearance ? Self.creamPad : Self.blackPad

        ZStack {
            // Three neutral pads
            ZStack {
                // Top-left
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(neutralPadColor)
                    .frame(width: padDimension, height: padDimension)
                    .position(x: 28.4086 * unit, y: 32.5914 * unit)

                // Bottom-left
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(neutralPadColor)
                    .frame(width: padDimension, height: padDimension)
                    .position(x: 28.4086 * unit, y: 72.5914 * unit)

                // Bottom-right
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(neutralPadColor)
                    .frame(width: padDimension, height: padDimension)
                    .position(x: 68.4086 * unit, y: 72.5914 * unit)
            }
            .frame(width: size, height: size)

            // Top-right orange smack pad
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Self.orangePad)
                .frame(width: padDimension, height: padDimension)
                .rotationEffect(.degrees(8))
                .position(x: 69.9086 * unit, y: 29.0914 * unit)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Smack-a-Pad")
        .accessibilityAddTraits(.isImage)
    }
}

/// Destinations opened from Home pads with pad-to-screen zoom navigation transition (ticket 113).
enum HomePadDestination: Identifiable, Equatable {
    case continueToLesson(Lesson)
    case continueToLibrary
    case library(LibraryLaunchTarget)
    case training
    case intro
    case controller
    case badges
    case purchases
    case settings
    case about

    var id: String {
        switch self {
        case .continueToLesson, .continueToLibrary: return "pad-continue"
        case .library: return "pad-library"
        case .training: return "pad-training"
        case .intro: return "pad-intro"
        case .controller: return "pad-controller"
        case .badges: return "pad-badges"
        case .purchases: return "pad-purchases"
        case .settings: return "pad-settings"
        case .about: return "pad-about"
        }
    }

    var libraryTarget: LibraryLaunchTarget? {
        switch self {
        case .continueToLesson(let lesson): return .lesson(lesson)
        case .continueToLibrary: return LibraryLaunchTarget.none
        case .library(let target): return target
        case .intro: return .intro
        default: return nil
        }
    }
}

/// Home screen with a 3×3 pad grid and the Smack-a-Pad logo in the centre cell.
/// On cold start, it plays the brand launch animation settling into the finished grid.
@MainActor
public struct HomeScreen: View {
    let isColdStart: Bool
    let onColdStartFinished: () -> Void
    let onNavigateToLibrary: (LibraryLaunchTarget) -> Void
    let onNavigateToTraining: () -> Void

    @Environment(StoreManager.self) private var store
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(ProgressionManager.self) private var progression
    @Environment(BadgeStore.self) private var badgeStore
    @Environment(MIDIInput.self) private var midi
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(TodayPlan.storageKey) private var savedTodayPlan = ""
    @AppStorage("smackapad.training.dailyMixes") private var dailyMixes = "{}"
    @State private var helpPresentation: HelpPresentation?
    @State private var didFocusIntro = false
    @AccessibilityFocusState private var introFocused: Bool
    @AccessibilityFocusState private var helpFocused: Bool
    @State private var calendarDay = AppCalendar.today()
    @State private var activeDestination: HomePadDestination?
    @Namespace private var homeNamespace

    @State private var lessonStore = LessonStore.shared
    @State private var homeOpacity: Double = 1.0

    // The bezel is already visible when the display powers on.
    @State private var pixelsVisible: Bool
    @State private var displayPowered: Bool
    @State private var plateVisible: Bool
    @State private var padVisible: [Bool]
    @State private var animationFinished: Bool
    @State private var animationTask: Task<Void, Never>?

    public init(
        isColdStart: Bool = false,
        onColdStartFinished: @escaping () -> Void = {},
        onNavigateToLibrary: @escaping (LibraryLaunchTarget) -> Void = { _ in },
        onNavigateToTraining: @escaping () -> Void = {}
    ) {
        self.isColdStart = isColdStart
        self.onColdStartFinished = onColdStartFinished
        self.onNavigateToLibrary = onNavigateToLibrary
        self.onNavigateToTraining = onNavigateToTraining

        let settled = !isColdStart
        _pixelsVisible = State(initialValue: settled)
        _displayPowered = State(initialValue: settled)
        _plateVisible = State(initialValue: settled)
        _padVisible = State(initialValue: Array(repeating: settled, count: 8))
        _animationFinished = State(initialValue: settled)
    }

    public var body: some View {
        GeometryReader { proxy in
            let containerW = proxy.size.width
            let containerH = proxy.size.height
            let layout = HomeControllerLayout(size: proxy.size)
            let gap = layout.gap
            let cellSize = layout.cellSize
            let gridSize = layout.gridSize

            ZStack {
                // The chassis and unpowered display are visible from the first launch frame.
                Theme.background
                    .ignoresSafeArea()

                HomeControllerBody(darkAppearance: colorScheme == .dark)
                    .equatable()

                HomeHardwareDisplay(status: controllerDisplayStatus,
                                    pixelsVisible: pixelsVisible, powered: displayPowered)
                    .frame(width: layout.display.width, height: layout.display.height)
                    .position(x: layout.display.midX, y: layout.display.midY)

                HomeControllerHardware(layout: layout, darkAppearance: colorScheme == .dark)
                    .equatable()
                    .opacity(plateVisible ? 1 : 0)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: plateVisible)

                HomeControllerFaders(layout: layout, darkAppearance: colorScheme == .dark)
                    .opacity(plateVisible ? 1 : 0)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: plateVisible)
                    .allowsHitTesting(plateVisible && animationFinished)

                // 3x3 Pad Grid (outer pads + centre logo pad)
                gridContent(cellSize: cellSize, gap: gap)
                    .frame(width: gridSize, height: gridSize)
                    .position(x: layout.plate.midX, y: layout.plate.midY)

                hardwareSettings(layout: layout)
                    .opacity(plateVisible ? 1 : 0)
                    .allowsHitTesting(animationFinished)

                Button {
                    helpPresentation = HelpPresentation(windowWidth: containerW)
                } label: {
                    Text("?")
                        .font(Theme.strong(22))
                        .foregroundStyle(Theme.white)
                        .frame(width: 36, height: 36)
                        .background(Theme.black, in: Circle())
                        .overlay { Circle().strokeBorder(Theme.white.opacity(0.12), lineWidth: 1) }
                        .shadow(color: Theme.black.opacity(0.25), radius: 2, y: 2)
                        .frame(width: Theme.Size.minimumTouch, height: Theme.Size.minimumTouch)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.localized("help.title"))
                .accessibilityFocused($helpFocused)
                .helpDeck(presentation: $helpPresentation, arrowEdge: .top) {
                    helpFocused = true
                }
                .position(x: layout.display.maxX + (containerW - layout.display.maxX) / 2,
                          y: layout.display.midY)
                .opacity(plateVisible ? 1 : 0)
                .allowsHitTesting(animationFinished)

            }
            .frame(width: containerW, height: containerH)
            .opacity(homeOpacity)
            .contentShape(Rectangle())
            .onTapGesture {
                if !animationFinished {
                    skipAnimation()
                }
            }
        }
        .ignoresSafeArea()
        .task {
            if isColdStart && !animationFinished {
                startAnimation()
            }
        }
        .onChange(of: introFocusEligible, initial: true) { _, eligible in
            if eligible {
                didFocusIntro = true
                introFocused = true
            }
        }
        #if DEBUG
        .debugTestMarker()
        #endif
        .padPresentation(item: $activeDestination, namespace: homeNamespace) { destination in
            #if DEBUG
            destinationView(for: destination).debugTestMarker()
            #else
            destinationView(for: destination)
            #endif
        }
        .onChange(of: AppNavigation.shared.route) { _, route in
            syncWithNavigationRoute(route)
        }
        .onAppear {
            syncWithNavigationRoute(AppNavigation.shared.route)
        }
        .onChange(of: activeDestination) { _, destination in
            if destination == nil, AppNavigation.shared.route != .home {
                AppNavigation.shared.openHome()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { calendarDay = AppCalendar.today() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            calendarDay = AppCalendar.today()
        }
    }

    private var controllerDisplayStatus: String {
        let source = midi.selectedSourceID.flatMap { selected in
            midi.sources.first { $0.id == selected }
        } ?? (midi.selectedSourceID == nil ? midi.sources.first : nil)
        guard let source else { return settings.localized("home.controller.none") }
        return "\(HomePadSubtitles.singleLine(source.name)) · \(settings.localized("home.controller.connected"))"
    }

    @ViewBuilder
    private func hardwareSettings(layout: HomeControllerLayout) -> some View {
        let bayWidth = layout.plate.minX
        let width = layout.landscape ? min(180, max(0, bayWidth - 2 * layout.margin)) : layout.portraitControlWidth
        let leftX = layout.landscape ? bayWidth / 2 : layout.margin + width / 2
        let rightX = layout.size.width - leftX
        let faderUnit = min(layout.unit, max(0, bayWidth - 2 * layout.margin) / 134)
        let centerY = layout.landscape
            ? layout.plate.minY + 217 * faderUnit + Theme.Space.page + 72
            : min(layout.size.height - layout.margin - 72,
                  layout.portraitBayTop + max(72, layout.portraitFaderHeight / 2))
        HomeLanguageKnob()
            .frame(width: width)
            .position(x: leftX, y: centerY)
        HomeAppearanceSwitch()
            .frame(width: width)
            .position(x: rightX, y: centerY)
    }

    private var homeIsIdle: Bool {
        AppNavigation.shared.route == .home && activeDestination == nil && helpPresentation == nil
    }

    private var introPadShouldPulse: Bool {
        shouldPulseIntroPad(
            loadSucceeded: progress.loadedSuccessfully,
            records: progress.records,
            animationFinished: animationFinished
        )
    }

    private var introFocusEligible: Bool {
        introPadShouldPulse && homeIsIdle && scenePhase == .active && !didFocusIntro
    }

    // MARK: - Destination Views

    @ViewBuilder
    private func destinationView(for destination: HomePadDestination) -> some View {
        switch destination {
        case .continueToLesson, .continueToLibrary, .library, .intro:
            let target = destination.libraryTarget ?? .none
            let initialProgress = switch target {
            case .lesson(let lesson): progress.progress(for: lesson.id)
            default: nil as LessonProgress?
            }
            LibraryScreen(
                launchTarget: target,
                initialProgress: initialProgress,
                onReviewOpen: preserveTodayPlan(for:),
                onHome: {
                    activeDestination = nil
                    AppNavigation.shared.openHome()
                }
            )
            .environment(store)
            .environment(settings)
            .environment(progress)
            .environment(progression)
            .environment(badgeStore)
            .environment(midi)

        case .training:
            TrainingScreen(
                onHome: {
                    activeDestination = nil
                    AppNavigation.shared.openHome()
                }
            )
            .environment(store)
            .environment(settings)
            .environment(progress)
            .environment(progression)
            .environment(badgeStore)
            .environment(midi)

        case .controller:
            NavigationStack {
                ControllerSetupView(onDismiss: {
                    activeDestination = nil
                })
            }
            .environment(store)
            .environment(settings)
            .environment(progress)
            .environment(progression)
            .environment(badgeStore)
            .environment(midi)

        case .badges:
            BadgesView(onDismiss: {
                activeDestination = nil
            })
            .environment(store)
            .environment(settings)
            .environment(progress)
            .environment(progression)
            .environment(badgeStore)
            .environment(midi)

        case .purchases:
            PurchaseSheet(onDismiss: {
                activeDestination = nil
            })
            .environment(store)
            .environment(settings)
            .environment(progress)
            .environment(progression)
            .environment(badgeStore)
            .environment(midi)

        case .settings:
            SettingsView(onDismiss: {
                activeDestination = nil
            })
            .environment(store)
            .environment(settings)
            .environment(progress)
            .environment(progression)
            .environment(badgeStore)
            .environment(midi)

        case .about:
            NavigationStack {
                AboutDetailView(onDismiss: {
                    activeDestination = nil
                })
            }
            .environment(store)
            .environment(settings)
            .environment(progress)
            .environment(progression)
            .environment(badgeStore)
            .environment(midi)
        }
    }

    private func syncWithNavigationRoute(_ route: AppRoute) {
        switch route {
        case .home:
            if activeDestination == .training || activeDestination?.libraryTarget != nil {
                activeDestination = nil
            }
        case .training:
            helpPresentation = nil
            if activeDestination != .training {
                activeDestination = .training
            }
        case .library(let target):
            helpPresentation = nil
            // Keep the originating pad's cover identity when its route is echoed back.
            // Replacing Continue/Intro here dismisses and re-presents a zoom mid-transition.
            if activeDestination?.libraryTarget != target {
                activeDestination = .library(target)
            }
        }
    }

    // MARK: - 3×3 Grid Content

    @ViewBuilder
    private func gridContent(cellSize: CGFloat, gap: CGFloat) -> some View {
        VStack(spacing: gap) {
            // Row 0: Today (1) · Library (2) · Continue (3)
            HStack(spacing: gap) {
                bootPad(pad1(cellSize: cellSize), isVisible: padVisible[0])
                    .padSource("pad-training", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
                bootPad(pad2(cellSize: cellSize), isVisible: padVisible[1])
                    .padSource("pad-library", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
                bootPad(pad3(cellSize: cellSize), isVisible: padVisible[2])
                    .padSource("pad-continue", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
            }
            // Row 1: Intro (4) · Centre Logo Pad (About) · Controller (5)
            HStack(spacing: gap) {
                bootPad(pad4(cellSize: cellSize), isVisible: padVisible[3])
                    .padSource("pad-intro", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
                centreLogoPad(cellSize: cellSize)
                    .padSource("pad-about", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
                bootPad(pad5(cellSize: cellSize), isVisible: padVisible[4])
                    .padSource("pad-controller", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
            }
            // Row 2: Badges (6) · Full Version (7) · Settings (8)
            HStack(spacing: gap) {
                bootPad(pad6(cellSize: cellSize), isVisible: padVisible[5])
                    .padSource("pad-badges", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
                bootPad(pad7(cellSize: cellSize), isVisible: padVisible[6])
                    .padSource("pad-purchases", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
                bootPad(pad8(cellSize: cellSize), isVisible: padVisible[7])
                    .padSource("pad-settings", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
            }
        }
    }

    @ViewBuilder
    private func bootPad<Content: View>(_ content: Content, isVisible: Bool) -> some View {
        let policy = Theme.Motion.Policy(reduced: reduceMotion)
        content
            .scaleEffect(policy.scale(isVisible ? 1.0 : 0.85))
            .opacity(isVisible ? 1.0 : 0.0)
            .allowsHitTesting(isVisible)
    }

    // MARK: - Pad Definitions

    private var todayPlan: TodayPlan? {
        if let saved = TodayPlan.decode(savedTodayPlan, today: calendarDay) {
            return saved.finished ? nil : saved
        }
        let source = NextLessonSource(rawValue: settings.nextLessonSource) ?? .path
        let next = progression.nextLesson(after: lessonStore.lesson(for: settings.lastLessonID), source: source)
        let openIDs = Set(progression.catalog.lessons.filter {
            store.isUnlocked($0) && progression.isLessonOpen($0)
        }.map(\.id))
        let padCount = midi.activeProfile.padCount
        let mix = TrainingMix.dailySelection(lessons: progression.catalog.lessons, progress: progress.records,
            padCount: padCount, openLessonIDs: openIDs, day: calendarDay, savedJSON: dailyMixes)
        let dueCandidates = progress.dueLessonIds(today: calendarDay).compactMap { lessonStore.lesson(for: $0) }.filter { lesson in
            guard openIDs.contains(lesson.id) else { return false }
            return padCount == 16 || EightPadLayout.slots(for: lesson) != nil
        }
        let due = ReviewQueue.order(dueCandidates, records: progress.records, today: calendarDay)
        return TodayPlan.make(day: calendarDay,
            dueLessonIDs: due.map(\.id),
            nextLessonID: next?.id, mixLessonIDs: mix.map(\.id))
    }

    private func preserveTodayPlan(for lessonID: Int) {
        guard TodayPlan.decode(savedTodayPlan, today: calendarDay) == nil,
              let plan = todayPlan,
              plan.steps.contains(where: { $0.kind == .review && $0.lessonIDs.first == lessonID }),
              let json = plan.encoded else { return }
        savedTodayPlan = json
    }

    private func pad1(cellSize: CGFloat) -> some View {
        let label = settings.localized("Today").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        let subtitle = HomePadSubtitles.today(plan: todayPlan, language: settings.languagePreference)

        return HomePadView(
            title: label,
            subtitle: subtitle,
            padNumber: 1,
            cellSize: cellSize,
            isHero: true
        ) {
            guard activeDestination == nil, helpPresentation == nil else { return }
            TrainingOpenMeasurement.begin()
            activeDestination = .training
            onNavigateToTraining()
            AppNavigation.shared.openTraining()
        }
    }

    private func pad2(cellSize: CGFloat) -> some View {
        let label = settings.localized("Library").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))

        return HomePadView(
            title: label,
            subtitle: HomePadSubtitles.library(),
            padNumber: 2,
            cellSize: cellSize,
            isHero: false
        ) {
            activeDestination = .library(.none)
            onNavigateToLibrary(.none)
            AppNavigation.shared.openLibrary(.none)
        }
    }

    private func pad3(cellSize: CGFloat) -> some View {
        let label = settings.localized("Continue").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        let lastLesson = settings.lastLessonID == 0 ? nil : lessonStore.lesson(for: settings.lastLessonID)
        let targetLesson = HomePadSubtitles.continueTarget(
            lastPlayedLesson: lastLesson,
            introFirstLesson: progression.catalog.introLessons.first,
            pathFirstLesson: progression.catalog.path.first
        )
        let subtitle = HomePadSubtitles.continueLesson(
            lastPlayedLesson: lastLesson,
            language: settings.languagePreference
        )

        return HomePadView(
            title: label,
            subtitle: subtitle,
            padNumber: 3,
            cellSize: cellSize,
            isHero: false
        ) {
            if let targetLesson {
                activeDestination = .continueToLesson(targetLesson)
                onNavigateToLibrary(.lesson(targetLesson))
                AppNavigation.shared.openLibrary(.lesson(targetLesson))
            } else {
                activeDestination = .continueToLibrary
                onNavigateToLibrary(.none)
                AppNavigation.shared.openLibrary(.none)
            }
        }
    }

    private func pad4(cellSize: CGFloat) -> some View {
        let label = settings.localized("Intro").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        return HomePadView(
            title: label,
            subtitle: HomePadSubtitles.intro(),
            isLit: introPadShouldPulse,
            padNumber: 4,
            cellSize: cellSize,
            isHero: false
        ) {
            activeDestination = .intro
            onNavigateToLibrary(.intro)
            AppNavigation.shared.openLibrary(.intro)
        }
        .accessibilityFocused($introFocused)
    }

    private func pad5(cellSize: CGFloat) -> some View {
        let label = settings.localized("Controller").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        let connectedName: String? = {
            if let selectedID = midi.selectedSourceID {
                return midi.sources.first(where: { $0.id == selectedID })?.name
            }
            return midi.sources.first?.name
        }()
        let subtitle = HomePadSubtitles.controller(
            connectedName: connectedName,
            language: settings.languagePreference
        )

        return HomePadView(
            title: label,
            subtitle: subtitle,
            padNumber: 5,
            cellSize: cellSize,
            isHero: false
        ) {
            activeDestination = .controller
        }
    }

    private func pad6(cellSize: CGFloat) -> some View {
        let label = settings.localized("Badges").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        let subtitle = HomePadSubtitles.badges(earned: badgeStore.earnedCount, total: badgeStore.totalCount)

        return HomePadView(
            title: label,
            subtitle: subtitle,
            numericTransitionValue: badgeStore.earnedCount,
            padNumber: 6,
            cellSize: cellSize,
            isHero: false
        ) {
            activeDestination = .badges
        }
    }

    private func pad7(cellSize: CGFloat) -> some View {
        let label = settings.localized("Full version").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        let price = store.products[StoreManager.fullID]?.displayPrice
        let subtitle = HomePadSubtitles.fullVersion(
            hasFullAccess: store.hasFullAccess,
            price: price,
            language: settings.languagePreference
        )

        return HomePadView(title: label, subtitle: subtitle, padNumber: 7, cellSize: cellSize, isHero: false) {
            activeDestination = .purchases
        }
    }

    private func pad8(cellSize: CGFloat) -> some View {
        let label = settings.localized("Settings").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        return HomePadView(
            title: label,
            subtitle: HomePadSubtitles.settings(),
            padNumber: 8,
            cellSize: cellSize,
            isHero: false
        ) {
            activeDestination = .settings
        }
    }

    private func centreLogoPad(cellSize: CGFloat) -> some View {
        let darkLogo = colorScheme == .dark
        let label = settings.localized("About")

        return Button {
            guard animationFinished else { return }
            activeDestination = .about
        } label: {
            ZStack {
                HomeLogoMarkView(size: cellSize, darkAppearance: darkLogo)
                    .opacity(plateVisible ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.pad)
                    .fill(Theme.surface)
                    .opacity(plateVisible ? 1.0 : 0.0)
            )
            .overlay {
                // Two-tone bevel: top 1.5 pt light highlight, bottom 2 pt darker edge (ticket 112)
                VStack(spacing: 0) {
                    Theme.padBevelTop
                        .frame(height: 1.5)
                    Spacer(minLength: 0)
                    Theme.padBevelBottom
                        .frame(height: 2.0)
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pad))
                .opacity(plateVisible ? 1.0 : 0.0)
                .allowsHitTesting(false)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.pad)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
                    .opacity(plateVisible ? 1.0 : 0.0)
                    .allowsHitTesting(false)
            }
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.pad))
        }
        .buttonStyle(TactilePadButtonStyle())
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
        .allowsHitTesting(animationFinished)
    }

    // MARK: - Animation Sequence

    private func startAnimation() {
        animationTask?.cancel()
        animationTask = Task { @MainActor in
            if reduceMotion {
                pixelsVisible = true
                displayPowered = true
                plateVisible = true
                padVisible = Array(repeating: true, count: 8)
                homeOpacity = 0
                withAnimation(.easeOut(duration: 0.2)) { homeOpacity = 1 }
                finishOnce()
                return
            }

            // 0.00–0.15 s: the unlit matrix appears inside the already visible bezel.
            withAnimation(.easeOut(duration: 0.15)) { pixelsVisible = true }
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            // 0.15–0.45 s: the logo and status line light up.
            withAnimation(.easeOut(duration: 0.3)) { displayPowered = true }
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            // 0.45–0.75 s: the plate and pads finish in their real Home positions.
            withAnimation(.easeOut(duration: 0.3)) {
                plateVisible = true
                padVisible = Array(repeating: true, count: 8)
            }
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            finishOnce()
        }
    }

    private func skipAnimation() {
        guard !animationFinished else { return }
        animationTask?.cancel()
        pixelsVisible = true
        displayPowered = true
        plateVisible = true
        padVisible = Array(repeating: true, count: 8)
        homeOpacity = 1
        finishOnce()
    }

    private func finishOnce() {
        guard !animationFinished else { return }
        animationFinished = true
        onColdStartFinished()
    }
}
