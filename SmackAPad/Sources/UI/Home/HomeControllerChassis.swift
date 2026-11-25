import SwiftUI

/// One proportional coordinate system for the display, plate and interactive hardware.
struct HomeControllerLayout: Equatable {
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
struct HomeControllerBody: View, Equatable {
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

/// The brushed plate and screws share one static raster, separate from interactive pads.
struct HomeControllerHardware: View, Equatable {
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
