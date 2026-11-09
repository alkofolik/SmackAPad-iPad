import SwiftUI

/// One proportional coordinate system for the grid, title and decorative hardware.
private struct HomeControllerLayout: Equatable {
    let size: CGSize
    let cellSize: CGFloat

    init(size: CGSize) {
        self.size = size
        let shorterSide = min(size.width, size.height)
        // Preserve the existing grid ceiling; reserve 35% of the short axis for the body.
        let maxCellSize = (680 - 2 * Theme.Space.regular) / 3
        let plateInCells: CGFloat = 3 + 2 * (15.0 / 146) + 2 * (36.0 / 146)
        cellSize = max(0, floor(min(maxCellSize, shorterSide * 0.65 / plateInCells)))
    }

    var unit: CGFloat { cellSize / 146 }
    var gap: CGFloat { 15 * unit }
    var gridSize: CGFloat { 3 * cellSize + 2 * gap }
    var plateSize: CGFloat { gridSize + 72 * unit }
    var plate: CGRect {
        CGRect(x: (size.width - plateSize) / 2, y: (size.height - plateSize) / 2,
               width: plateSize, height: plateSize)
    }
    var landscape: Bool { size.width >= size.height }
    var margin: CGFloat { min(size.width, size.height) * 0.025 }
    var wordmarkWidth: CGFloat {
        let desired = plateSize * (landscape ? 292.0 / 540 : 332.0 / 540)
        // Keep equal clear space above and below the real wordmark, including small windows.
        return min(desired, max(0, plate.minY - 2 * margin) * (490.455 / 73.8))
    }
    var wordmarkY: CGFloat { plate.minY / 2 }
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
            drawFaders(in: &context)
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

    private func drawFaders(in context: inout GraphicsContext) {
        if layout.landscape {
            let bayWidth = layout.plate.minX
            let u = min(layout.unit, max(0, bayWidth - 2 * layout.margin) / 134)
            guard u > 0 else { return }
            let height = 217 * u
            for channel in 0..<4 {
                let right = channel >= 2
                let centerX = right ? layout.size.width - bayWidth / 2 : bayWidth / 2
                let x = centerX - 67 * u + CGFloat(channel % 2) * 78 * u
                drawFader(in: context, channel: channel, unit: u,
                          rect: CGRect(x: x, y: (layout.size.height - height) / 2, width: 56 * u, height: height),
                          mirrored: right, portrait: false)
            }
        } else {
            let u = min(layout.unit, max(0, layout.size.width - 2 * layout.margin) / 316)
            let bayHeight = layout.size.height - layout.plate.maxY
            let height = min(142 * u, max(0, bayHeight - 2 * layout.margin))
            // Compress the travel first, then omit channels in unusually short portrait windows.
            let travel = height - 17 * u
            let count = travel >= 64 * u ? 4 : (travel >= 48 * u ? 2 : 0)
            guard u > 0, count > 0 else { return }
            let width = CGFloat(count) * 52 * u + CGFloat(count - 1) * 36 * u
            for channel in 0..<count {
                let rect = CGRect(x: (layout.size.width - width) / 2 + CGFloat(channel) * 88 * u,
                                  y: layout.plate.maxY + (bayHeight - height) / 2,
                                  width: 52 * u, height: height)
                drawFader(in: context, channel: channel, unit: u, rect: rect, mirrored: false, portrait: true)
            }
        }
    }

    private func drawFader(in context: GraphicsContext, channel: Int, unit u: CGFloat,
                           rect: CGRect, mirrored: Bool, portrait: Bool) {
        engraved(String(format: "CH %02d", channel + 1), in: context,
                 at: CGPoint(x: rect.midX, y: rect.minY + 4.5 * u), size: 9 * u)
        let trackTop = rect.minY + 17 * u
        let travel = rect.maxY - trackTop
        let trackWidth: CGFloat = (portrait ? 26 : 28) * u
        let trackX = mirrored ? rect.minX + trackWidth / 2 : rect.maxX - trackWidth / 2
        let slot = CGRect(x: trackX - 3 * u, y: trackTop, width: 6 * u, height: travel)
        context.fill(Path(roundedRect: slot.offsetBy(dx: 0, dy: u), cornerRadius: 3 * u),
                     with: .color(Theme.white.opacity(darkAppearance ? 0.08 : 0.65)))
        context.fill(Path(roundedRect: slot, cornerRadius: 3 * u), with: .color(Theme.HomeController.slot))
        context.fill(Path(CGRect(x: trackX, y: trackTop + u, width: 0.6 * u, height: travel - 2 * u)),
                     with: .color(Theme.white.opacity(0.15)))

        let labels = ["+6", "0", "-6", "-12", "-24", "-∞"]
        let levels: [CGFloat] = [0.95, 0.75, 0.55, 0.38, 0.22, 0.05]
        for index in labels.indices {
            let y = rect.maxY - travel * levels[index]
            let major = index == 1
            let length: CGFloat = (major ? 8 : 5) * u
            let tickX = mirrored ? trackX + trackWidth / 2 + 4 * u : trackX - trackWidth / 2 - 4 * u - length
            context.fill(Path(CGRect(x: tickX, y: y, width: length, height: (major ? 1.5 : 1) * u)),
                         with: .color(Theme.ink.opacity(major ? 0.65 : 0.32)))
            engraved(labels[index], in: context,
                     at: CGPoint(x: mirrored ? tickX + length + 3 * u : tickX - 3 * u, y: y),
                     size: 8 * u, anchor: mirrored ? .leading : .trailing, prominent: major)
        }

        let capLevels: [CGFloat] = [0.72, 0.48, 0.88, 0.28]
        let capWidth: CGFloat = (portrait ? 24 : 26) * u
        let capHeight: CGFloat = (portrait ? 28 : 34) * u
        let capY = min(rect.maxY - capHeight / 2, max(trackTop + capHeight / 2, rect.maxY - travel * capLevels[channel]))
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
        context.fill(Path(CGRect(x: cap.minX + 3 * u, y: cap.midY - u, width: cap.width - 6 * u, height: 2 * u)),
                     with: .color(channel == 2 ? Theme.orange : Theme.ink))
    }

    private func engraved(_ text: String, in context: GraphicsContext, at point: CGPoint,
                          size: CGFloat, anchor: UnitPoint = .center, prominent: Bool = false) {
        let label = Text(verbatim: text).font(Theme.canvasDisplay(size).monospacedDigit())
        context.draw(label.foregroundColor(Theme.white.opacity(darkAppearance ? 0.08 : 0.6)),
                     at: CGPoint(x: point.x, y: point.y + layout.unit * 0.6), anchor: anchor)
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

/// A tactile button pad on the Home screen.
struct HomePadView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let title: String
    let subtitle: String?
    var subtitleVariants: [String]? = nil
    var secondarySubtitle: String? = nil
    var secondarySubtitleVariants: [String]? = nil
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
                let titleSize = (isHero ? 19.0 : 16.0) * (cellSize / 146.0)
                Text(title.uppercased())
                    .font(Theme.padTitle(size: titleSize))
                    .tracking(titleSize * 0.03)
                    .foregroundStyle(isHero ? Theme.black : Theme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if let subtitleVariants, !subtitleVariants.isEmpty {
                    ViewThatFits(in: .vertical) {
                        ForEach(subtitleVariants, id: \.self) { variant in
                            Text(variant)
                                .font(Theme.meta)
                                .foregroundStyle(isHero ? Theme.black : Theme.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .minimumScaleFactor(0.75)
                        }
                    }
                } else if let subtitle, !subtitle.isEmpty {
                    if let numericTransitionValue {
                        Text(subtitle)
                            .font(Theme.meta)
                            .foregroundStyle(isHero ? Theme.black : Theme.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .minimumScaleFactor(0.75)
                            .contentTransition(policy.numeric)
                            .motion(value: numericTransitionValue)
                    } else {
                        Text(subtitle)
                            .font(Theme.meta)
                            .foregroundStyle(isHero ? Theme.black : Theme.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .minimumScaleFactor(0.75)
                    }
                }

                if let secondarySubtitleVariants, !secondarySubtitleVariants.isEmpty {
                    ViewThatFits(in: .vertical) {
                        ForEach(secondarySubtitleVariants, id: \.self) { variant in
                            Text(variant)
                                .font(Theme.meta)
                                .foregroundStyle(Theme.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .minimumScaleFactor(0.75)
                        }
                    }
                } else if let secondarySubtitle, !secondarySubtitle.isEmpty {
                    Text(secondarySubtitle)
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.75)
                }
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

    private var defaultAccessibilityText: String {
        var parts: [String] = [title]
        if let sub = subtitleVariants?.first ?? subtitle, !sub.isEmpty {
            parts.append(sub)
        }
        if let sec = secondarySubtitleVariants?.first ?? secondarySubtitle, !sec.isEmpty {
            parts.append(sec)
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
    var reduceMotion: Bool = false
    var pad1Popped: Bool = true
    var pad2Popped: Bool = true
    var pad3Popped: Bool = true
    var orangeVisible: Bool = true
    var orangeLanded: Bool = true
    var blackBounce: CGFloat = 0

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
                    .scaleEffect(reduceMotion ? 1.0 : (pad1Popped ? 1.0 : 0.4))
                    .opacity(reduceMotion ? 1.0 : (pad1Popped ? 1.0 : 0.0))
                    .position(x: 28.4086 * unit, y: 32.5914 * unit)

                // Bottom-left
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(neutralPadColor)
                    .frame(width: padDimension, height: padDimension)
                    .scaleEffect(reduceMotion ? 1.0 : (pad2Popped ? 1.0 : 0.4))
                    .opacity(reduceMotion ? 1.0 : (pad2Popped ? 1.0 : 0.0))
                    .position(x: 28.4086 * unit, y: 72.5914 * unit)

                // Bottom-right
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(neutralPadColor)
                    .frame(width: padDimension, height: padDimension)
                    .scaleEffect(reduceMotion ? 1.0 : (pad3Popped ? 1.0 : 0.4))
                    .opacity(reduceMotion ? 1.0 : (pad3Popped ? 1.0 : 0.0))
                    .position(x: 68.4086 * unit, y: 72.5914 * unit)
            }
            .frame(width: size, height: size)
            .offset(y: reduceMotion ? 0 : blackBounce)

            // Top-right orange smack pad
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Self.orangePad)
                .frame(width: padDimension, height: padDimension)
                .scaleEffect(reduceMotion ? 1.0 : (orangeLanded ? 1.0 : 1.35))
                .rotationEffect(.degrees(reduceMotion ? 8.0 : (orangeLanded ? 8.0 : 0.0)))
                .offset(y: reduceMotion ? 0 : (orangeLanded ? 0 : -36 * unit))
                .opacity(reduceMotion ? 1.0 : (orangeVisible ? 1.0 : 0.0))
                .position(x: 69.9086 * unit, y: 29.0914 * unit)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Smack-a-Pad")
        .accessibilityAddTraits(.isImage)
    }
}

/// The vector wordmark "Smack-a-Pad".
struct HomeWordmarkView: View {
    let width: CGFloat
    let darkAppearance: Bool
    var reduceMotion: Bool = false
    var isVisible: Bool = true

    private static let aspectRatio: CGFloat = 490.455 / 73.8
    private static let blackPad = Color(red: 17 / 255.0, green: 17 / 255.0, blue: 17 / 255.0)
    private static let creamPad = Color(red: 242 / 255.0, green: 240 / 255.0, blue: 234 / 255.0)

    var body: some View {
        Image("LaunchWordmark")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(darkAppearance ? Self.creamPad : Self.blackPad)
            .frame(width: width, height: width / Self.aspectRatio)
            .offset(y: reduceMotion ? 0 : (isVisible ? 0 : 8))
            .opacity(reduceMotion ? 1.0 : (isVisible ? 1.0 : 0.0))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Smack-a-Pad")
    }
}

/// Home screen with a 3×3 pad grid and the Smack-a-Pad logo in the centre cell.
/// On cold start, it plays the brand launch animation settling into the finished grid.
@MainActor
/// Destinations opened from Home pads with pad-to-screen zoom navigation transition (ticket 113).
enum HomePadDestination: Identifiable, Equatable {
    case today(TodayPlan)
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
        case .today: return "pad-today"
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
    @AppStorage("smackapad.training.today") private var savedTodayPlan = ""
    @AppStorage("smackapad.training.dailyMixes") private var dailyMixes = "{}"
    @State private var calendarDay = AppCalendar.today()
    @State private var activeDestination: HomePadDestination?
    @Namespace private var homeNamespace

    @State private var lessonStore = LessonStore.shared
    @State private var gridOpacity: Double = 1.0

    // Launch animation sequence states
    @State private var pad1Popped: Bool
    @State private var pad2Popped: Bool
    @State private var pad3Popped: Bool
    @State private var orangeVisible: Bool
    @State private var orangeLanded: Bool
    @State private var blackBounce: CGFloat = 0
    @State private var wordmarkVisible: Bool
    @State private var isSettled: Bool
    @State private var logoInPad: Bool
    @State private var plateVisible: Bool
    @State private var padVisible: [Bool]
    @State private var animationFinished: Bool
    @State private var animationTask: Task<Void, Never>?

    private static let cream = Color(red: 242 / 255.0, green: 240 / 255.0, blue: 234 / 255.0)

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
        _pad1Popped = State(initialValue: settled)
        _pad2Popped = State(initialValue: settled)
        _pad3Popped = State(initialValue: settled)
        _orangeVisible = State(initialValue: settled)
        _orangeLanded = State(initialValue: settled)
        _wordmarkVisible = State(initialValue: settled)
        _isSettled = State(initialValue: settled)
        _logoInPad = State(initialValue: settled)
        _plateVisible = State(initialValue: settled)
        _padVisible = State(initialValue: Array(repeating: settled, count: 8))
        _animationFinished = State(initialValue: settled)
    }

    public var body: some View {
        GeometryReader { proxy in
            let containerW = proxy.size.width
            let containerH = proxy.size.height
            let shorterSide = min(containerW, containerH)
            let layout = HomeControllerLayout(size: proxy.size)
            let gap = layout.gap
            let aspectRatio: CGFloat = 490.455 / 73.8
            let settledWordmarkW = layout.wordmarkWidth
            let cellSize = layout.cellSize
            let gridSize = layout.gridSize
            let settledWordmarkY = layout.wordmarkY
            let settledGridCenterY = containerH / 2

            // Initial animation geometry (centered on screen)
            let initialLogoSize = shorterSide * 0.28
            let initialWordmarkW = initialLogoSize * 1.12
            let initialWordmarkH = initialWordmarkW / aspectRatio
            let initialSpacing = initialLogoSize * 0.12
            let totalInitialH = initialLogoSize + initialSpacing + initialWordmarkH

            let initialLogoY = containerH / 2 - totalInitialH / 2 + initialLogoSize / 2
            let initialWordmarkY = initialLogoY + initialLogoSize / 2 + initialSpacing + initialWordmarkH / 2

            let darkLogo = isSettled && (colorScheme == .dark)

            ZStack {
                // Home-only body: the launch cream clears before the static hardware appears.
                Theme.background
                    .ignoresSafeArea()

                HomeControllerBody(darkAppearance: colorScheme == .dark)
                    .equatable()
                    .opacity(isSettled ? 1 : 0)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isSettled)

                Self.cream
                    .ignoresSafeArea()
                    .opacity(isSettled ? 0.0 : 1.0)

                HomeControllerHardware(layout: layout, darkAppearance: colorScheme == .dark)
                    .equatable()
                    .opacity(plateVisible ? 1 : 0)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: plateVisible)

                // 3x3 Pad Grid (outer pads + centre logo pad)
                gridContent(cellSize: cellSize, gap: gap)
                    .frame(width: gridSize, height: gridSize)
                    .position(x: containerW / 2, y: settledGridCenterY)
                    .opacity(gridOpacity)

                // Floating Centre Logo Mark (only during launch animation until landed)
                if !logoInPad {
                    HomeLogoMarkView(
                        size: isSettled ? cellSize : initialLogoSize,
                        darkAppearance: darkLogo,
                        reduceMotion: reduceMotion,
                        pad1Popped: pad1Popped,
                        pad2Popped: pad2Popped,
                        pad3Popped: pad3Popped,
                        orangeVisible: orangeVisible,
                        orangeLanded: orangeLanded,
                        blackBounce: blackBounce
                    )
                    .position(x: containerW / 2, y: isSettled ? settledGridCenterY : initialLogoY)
                    .allowsHitTesting(false)
                }

                // Wordmark "Smack-a-Pad"
                HomeWordmarkView(
                    width: isSettled ? settledWordmarkW : initialWordmarkW,
                    darkAppearance: darkLogo,
                    reduceMotion: reduceMotion,
                    isVisible: wordmarkVisible
                )
                .position(x: containerW / 2, y: isSettled ? settledWordmarkY : initialWordmarkY)
            }
            .frame(width: containerW, height: containerH)
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
        .padPresentation(item: $activeDestination, namespace: homeNamespace) { destination in
            destinationView(for: destination)
        }
        .onChange(of: AppNavigation.shared.route) { _, route in
            syncWithNavigationRoute(route)
        }
        .onAppear {
            syncWithNavigationRoute(AppNavigation.shared.route)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { calendarDay = AppCalendar.today() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            calendarDay = AppCalendar.today()
        }
    }

    // MARK: - Destination Views

    @ViewBuilder
    private func destinationView(for destination: HomePadDestination) -> some View {
        switch destination {
        case .today(let plan):
            TodaySessionScreen(plan: plan) {
                activeDestination = nil
            }
            .environment(store)
            .environment(settings)
            .environment(progress)
            .environment(progression)
            .environment(badgeStore)
            .environment(midi)

        case .continueToLesson(let lesson):
            LibraryScreen(
                launchTarget: .lesson(lesson),
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

        case .continueToLibrary:
            LibraryScreen(
                launchTarget: .none,
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

        case .library(let target):
            LibraryScreen(
                launchTarget: target,
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

        case .intro:
            LibraryScreen(
                launchTarget: .intro,
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
                ControllerSetupView(showsDoneButton: true, onDismiss: {
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
                AboutDetailView(showsDoneButton: true, onDismiss: {
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
            if activeDestination != .training {
                activeDestination = .training
            }
        case .library(let target):
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
            // Row 0: Continue/Start (1) · Library (2) · Training (3)
            HStack(spacing: gap) {
                bootPad(pad1(cellSize: cellSize), isVisible: padVisible[0])
                    .padSource(todayPlan != nil ? "pad-today" : "pad-continue", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
                bootPad(pad2(cellSize: cellSize), isVisible: padVisible[1])
                    .padSource("pad-library", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
                bootPad(pad3(cellSize: cellSize), isVisible: padVisible[2])
                    .padSource("pad-training", in: homeNamespace)
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

    private func todaySubtitle(_ plan: TodayPlan) -> String {
        let count = settings.localized("%lld today", plan.reviewCount)
        return plan.hasNewLesson ? count + " · " + settings.localized("then new lesson") : count
    }

    private func todaySubtitleVariants(_ plan: TodayPlan) -> [String] {
        let full = todaySubtitle(plan)
        var variants = [full]
        if full.contains(" · ") {
            let short = full.components(separatedBy: " · ")[0].trimmingCharacters(in: .whitespaces)
            if !variants.contains(short) { variants.append(short) }
        }
        let count = "\(plan.reviewCount)"
        if !variants.contains(count) { variants.append(count) }
        return variants
    }

    private func lessonSubtitleVariants(lesson: Lesson) -> [String] {
        let title = settings.localized(lesson.title)
        let record = progress.progress(for: lesson.id)
        let stars = LibraryStarFilter.stars(record)
        let starSuffix = stars > 0 ? " · \(String(repeating: "★", count: stars))" : ""
        let fullSubtitle = "\(title)\(starSuffix)"

        var variants: [String] = [fullSubtitle]

        // 1. Short form if lesson has one (e.g. prefix before " · ")
        if title.contains(" · ") {
            let shortForm = title.components(separatedBy: " · ")[0].trimmingCharacters(in: .whitespaces)
            let withStars = "\(shortForm)\(starSuffix)"
            if !variants.contains(withStars) { variants.append(withStars) }
            if !variants.contains(shortForm) { variants.append(shortForm) }
        }

        // 2. Lesson number plus first words that fit on a whole word boundary
        let number: Int? = lesson.intro?.number
            ?? progression.catalog.path.firstIndex(where: { $0.id == lesson.id }).map { $0 + 1 }
            ?? (progression.catalog.lessons.filter { $0.cat == lesson.cat }.firstIndex { $0.id == lesson.id }.map { $0 + 1 })

        let words = title.split(separator: " ").map(String.init)
        let numPrefix = number.map { "\($0). " } ?? ""

        for count in stride(from: words.count - 1, through: 1, by: -1) {
            var prefix = words.prefix(count).joined(separator: " ")
            if prefix.hasSuffix(" ·") { prefix = String(prefix.dropLast(2)) }
            if prefix.hasSuffix(",") || prefix.hasSuffix("·") { prefix = String(prefix.dropLast()) }
            let candidateWithStars = "\(numPrefix)\(prefix)\(starSuffix)"
            if !variants.contains(candidateWithStars) { variants.append(candidateWithStars) }
            let candidate = "\(numPrefix)\(prefix)"
            if !variants.contains(candidate) { variants.append(candidate) }
        }

        if let number {
            let numWithStars = "\(number)\(starSuffix)"
            if !variants.contains(numWithStars) { variants.append(numWithStars) }
            let numOnly = "\(number)"
            if !variants.contains(numOnly) { variants.append(numOnly) }
        }

        return variants
    }

    static func wordBoundaryVariants(for text: String) -> [String] {
        let words = text.split(separator: " ").map(String.init)
        guard words.count > 1 else { return [text] }
        var variants: [String] = [text]
        for count in stride(from: words.count - 1, through: 1, by: -1) {
            var prefix = words.prefix(count).joined(separator: " ")
            if prefix.hasSuffix(" ·") {
                prefix = String(prefix.dropLast(2))
            } else if prefix.hasSuffix(",") || prefix.hasSuffix("·") {
                prefix = String(prefix.dropLast())
            }
            if !prefix.isEmpty && !variants.contains(prefix) {
                variants.append(prefix)
            }
        }
        return variants
    }

    private func pad1(cellSize: CGFloat) -> some View {
        if let plan = todayPlan {
            let label = settings.localized("Today").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
            let subtitle = todaySubtitle(plan)
            let variants = todaySubtitleVariants(plan)
            return AnyView(HomePadView(
                title: label,
                subtitle: subtitle,
                subtitleVariants: variants,
                accessibilityText: "\(label), \(subtitle)",
                padNumber: 1,
                cellSize: cellSize,
                isHero: true
            ) {
                // Keep the same Mix visible on Training even if reviews change recency first.
                if let mix = plan.steps.first(where: { $0.kind == .mix }) {
                    var saved = (try? JSONDecoder().decode([String: [Int]].self, from: Data(dailyMixes.utf8))) ?? [:]
                    saved = saved.filter { $0.key.hasPrefix(calendarDay + ":") }
                    saved["\(calendarDay):\(midi.activeProfile.padCount)"] = mix.lessonIDs
                    if let data = try? JSONEncoder().encode(saved), let json = String(data: data, encoding: .utf8) {
                        dailyMixes = json
                    }
                }
                activeDestination = .today(plan)
            })
        }
        let isFirstRun = settings.lastLessonID == 0
        let label = settings.localized(isFirstRun ? "Start" : "Continue").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))

        let targetLesson: Lesson? = {
            if isFirstRun {
                return progression.catalog.introLessons.first ?? progression.catalog.path.first
            }
            let source = NextLessonSource(rawValue: settings.nextLessonSource) ?? .path
            return progression.nextLesson(after: lessonStore.lesson(for: settings.lastLessonID), source: source) ?? progression.catalog.path.first
        }()

        let subtitle: String? = {
            guard let targetLesson else { return nil }
            let title = settings.localized(targetLesson.title)
            let record = progress.progress(for: targetLesson.id)
            let stars = LibraryStarFilter.stars(record)
            if stars > 0 {
                return "\(title) · \(String(repeating: "★", count: stars))"
            }
            return title
        }()

        let variants: [String]? = {
            guard let targetLesson else { return nil }
            return lessonSubtitleVariants(lesson: targetLesson)
        }()

        let accessibility: String? = {
            guard let subtitle else { return label }
            return "\(label), \(subtitle)"
        }()

        return AnyView(HomePadView(
            title: label,
            subtitle: subtitle,
            subtitleVariants: variants,
            accessibilityText: accessibility,
            padNumber: 1,
            cellSize: cellSize,
            isHero: true
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
        })
    }

    private func pad2(cellSize: CGFloat) -> some View {
        let label = settings.localized("Library").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        let allLessons = progression.catalog.path
        let three = allLessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 3 }.count
        let two = allLessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 2 }.count
        let one = allLessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 1 }.count
        let earnedStars = three * 3 + two * 2 + one
        let maxStars = allLessons.count * 3
        let subtitle = "\(earnedStars) / \(maxStars) ★"

        return HomePadView(
            title: label,
            subtitle: subtitle,
            numericTransitionValue: earnedStars,
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
        let label = settings.localized("Training").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        let dueCount = progress.dueLessonsCount(today: calendarDay)

        return HomePadView(
            title: label,
            subtitle: nil,
            accessibilityText: label,
            isLit: dueCount > 0,
            padNumber: 3,
            cellSize: cellSize,
            isHero: false
        ) {
            TrainingOpenMeasurement.begin()
            activeDestination = .training
            onNavigateToTraining()
            AppNavigation.shared.openTraining()
        }
    }

    private func pad4(cellSize: CGFloat) -> some View {
        let label = settings.localized("Intro").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        return HomePadView(title: label, subtitle: nil, padNumber: 4, cellSize: cellSize, isHero: false) {
            activeDestination = .intro
            onNavigateToLibrary(.intro)
            AppNavigation.shared.openLibrary(.intro)
        }
    }

    private func pad5(cellSize: CGFloat) -> some View {
        let label = settings.localized("Controller").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        let profileName = settings.displayName(for: settings.activeProfile())

        let inputName: String = {
            if let selectedID = midi.selectedSourceID {
                return midi.sources.first(where: { $0.id == selectedID })?.name ?? settings.localized("Not connected")
            } else if let firstSource = midi.sources.first {
                return firstSource.name
            } else {
                return settings.localized("Not connected")
            }
        }()

        let voiceOverText = "\(label), \(inputName), \(profileName)"
        let inputVariants = Self.wordBoundaryVariants(for: inputName)
        let profileVariants = Self.wordBoundaryVariants(for: profileName)

        return HomePadView(
            title: label,
            subtitle: inputName,
            subtitleVariants: inputVariants,
            secondarySubtitle: profileName,
            secondarySubtitleVariants: profileVariants,
            accessibilityText: voiceOverText,
            padNumber: 5,
            cellSize: cellSize,
            isHero: false
        ) {
            activeDestination = .controller
        }
    }

    private func pad6(cellSize: CGFloat) -> some View {
        let label = settings.localized("Badges").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        let subtitle = "\(badgeStore.earnedCount) / \(badgeStore.totalCount)"

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
        let subtitle = store.hasFullAccess ? settings.localized("Unlocked") : settings.localized("Unlock")

        return HomePadView(title: label, subtitle: subtitle, padNumber: 7, cellSize: cellSize, isHero: false) {
            activeDestination = .purchases
        }
    }

    private func pad8(cellSize: CGFloat) -> some View {
        let label = settings.localized("Settings").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        return HomePadView(title: label, subtitle: nil, padNumber: 8, cellSize: cellSize, isHero: false) {
            activeDestination = .settings
        }
    }

    private func centreLogoPad(cellSize: CGFloat) -> some View {
        let darkLogo = isSettled && (colorScheme == .dark)
        let label = settings.localized("About")

        return Button {
            guard animationFinished else { return }
            activeDestination = .about
        } label: {
            ZStack {
                if logoInPad {
                    HomeLogoMarkView(
                        size: cellSize,
                        darkAppearance: darkLogo,
                        reduceMotion: reduceMotion
                    )
                    .accessibilityHidden(true)
                }
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
            let policy = Theme.Motion.Policy(reduced: reduceMotion)
            if policy.reduced {
                skipAnimation()
                gridOpacity = 0
                withAnimation(.easeOut(duration: 0.2)) {
                    gridOpacity = 1
                }
                return
            }

            gridOpacity = 1.0

            // 0.00–0.45 s: three black pads appear 0.12 s apart
            withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                pad1Popped = true
            }
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }

            withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                pad2Popped = true
            }
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }

            withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                pad3Popped = true
            }
            // Wait until 0.55 s (elapsed: 240 ms -> sleep 310 ms)
            try? await Task.sleep(for: .milliseconds(310))
            guard !Task.isCancelled else { return }

            // 0.55 s: orange pad smacks in
            orangeVisible = true
            withAnimation(.spring(response: 0.28, dampingFraction: 0.54)) {
                orangeLanded = true
            }

            // Impact at ~0.64 s: 2 pt bounce on black pads
            try? await Task.sleep(for: .milliseconds(90))
            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: 0.06)) {
                blackBounce = 2
            }
            try? await Task.sleep(for: .milliseconds(60))
            guard !Task.isCancelled else { return }

            withAnimation(.easeOut(duration: 0.10)) {
                blackBounce = 0
            }

            // Wait until 0.95 s (elapsed: 550 + 90 + 60 + 100 = 800 ms -> sleep 150 ms)
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }

            // 0.95–1.25 s: wordmark fades and rises
            withAnimation(.easeOut(duration: 0.30)) {
                wordmarkVisible = true
            }

            // Hold until 1.50 s (elapsed: 950 + 300 = 1250 ms -> sleep 250 ms)
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }

            // 1.50–2.10 s: Logo scales to centre cell, wordmark moves up, background cross-fades
            withAnimation(.easeInOut(duration: 0.60)) {
                isSettled = true
            }

            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }

            // Logo has landed in centre cell; switch to pad logo and fade plate in (Ticket 115)
            logoInPad = true
            withAnimation(.easeOut(duration: 0.20)) {
                plateVisible = true
            }

            // 2.10–2.80 s: 8 pads appear in a diagonal wave from top-left to bottom-right (ticket 112)
            // Wave 0: Pad 1 (top-left)
            withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                padVisible[0] = true
            }
            try? await Task.sleep(for: Theme.Motion.bootStagger)
            guard !Task.isCancelled else { return }

            // Wave 1: Pad 2 and Pad 4
            withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                padVisible[1] = true
                padVisible[3] = true
            }
            try? await Task.sleep(for: Theme.Motion.bootStagger)
            guard !Task.isCancelled else { return }

            // Wave 2: Pad 3 and Pad 6
            withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                padVisible[2] = true
                padVisible[5] = true
            }
            try? await Task.sleep(for: Theme.Motion.bootStagger)
            guard !Task.isCancelled else { return }

            // Wave 3: Pad 5 and Pad 7
            withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                padVisible[4] = true
                padVisible[6] = true
            }
            try? await Task.sleep(for: Theme.Motion.bootStagger)
            guard !Task.isCancelled else { return }

            // Wave 4: Pad 8 (bottom-right)
            withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                padVisible[7] = true
            }

            // Settle time
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            finishOnce()
        }
    }

    private func skipAnimation() {
        guard !animationFinished else { return }
        animationTask?.cancel()
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) {
            pad1Popped = true
            pad2Popped = true
            pad3Popped = true
            orangeVisible = true
            orangeLanded = true
            blackBounce = 0
            wordmarkVisible = true
            isSettled = true
            logoInPad = true
            plateVisible = true
            for i in 0..<8 {
                padVisible[i] = true
            }
        }
        finishOnce()
    }

    private func finishOnce() {
        guard !animationFinished else { return }
        animationFinished = true
        onColdStartFinished()
    }
}
