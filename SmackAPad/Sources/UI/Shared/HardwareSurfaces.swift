import SwiftUI

/// Static and isolated from control state; the ribbing is rasterised with the chassis.
private struct CalmChassisSurface: View, Equatable {
    let darkAppearance: Bool

    var body: some View {
        Theme.Skin.gradient([Theme.Skin.Chassis.top, Theme.Skin.Chassis.bottom],
                            degrees: Theme.Skin.Chassis.angle)
            .overlay {
                Canvas { context, size in
                    for y in stride(from: CGFloat.zero, to: size.height, by: Theme.Skin.Chassis.ribPitch) {
                        context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 2)),
                                     with: .color(Theme.HomeController.ribLight))
                        context.fill(Path(CGRect(x: 0, y: y + 2, width: size.width, height: 2)),
                                     with: .color(Theme.HomeController.ribShadow))
                    }
                }
                .opacity(Theme.Skin.Chassis.ribOpacity)
            }
            .drawingGroup(opaque: true)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct CalmChassisBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.background {
            CalmChassisSurface(darkAppearance: colorScheme == .dark)
                .equatable()
                .ignoresSafeArea()
        }
    }
}

/// All bevel drawing is clipped inside the caller's existing bounds.
struct SkinBevel: View {
    let radius: CGFloat
    let highlight: Color
    let shade: Color
    let top: CGFloat
    let bottom: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .strokeBorder(highlight, lineWidth: top)
            .mask(alignment: .top) { Rectangle().frame(height: radius + top) }
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(shade, lineWidth: bottom)
                    .mask(alignment: .bottom) { Rectangle().frame(height: radius + bottom) }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct SatinPlateSurface: View {
    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Skin.Plate.radius)
            .fill(Theme.Skin.gradient([Theme.Skin.Plate.top, Theme.Skin.Plate.bottom],
                                      degrees: Theme.Skin.Plate.angle))
            .overlay {
                SkinBevel(radius: Theme.Skin.Plate.radius, highlight: Theme.Skin.Plate.highlight,
                          shade: Theme.Skin.Plate.shade, top: Theme.Skin.Plate.bevel, bottom: Theme.Skin.Plate.bevel)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Skin.Plate.radius)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            }
            .shadow(color: Theme.Skin.Plate.shadow, radius: Theme.Skin.Plate.shadowRadius, y: Theme.Skin.Plate.shadowY)
            .shadow(color: Theme.Skin.Plate.contactShadow, radius: Theme.Skin.Plate.contactRadius, y: Theme.Skin.Plate.contactY)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct StructuralPlateSurface: View {
    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Skin.Plate.radius)
            .fill(Theme.Skin.Plate.top)
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Skin.Plate.radius)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct InsetDisplay: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Theme.Skin.Display.ink)
            .background {
                RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius)
                    .fill(Theme.Skin.Display.fill.shadow(.inner(color: Theme.Skin.Display.shadow,
                        radius: Theme.Skin.Display.shadowRadius, y: Theme.Skin.Display.shadowY)))
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius)
                            .fill(LinearGradient(colors: [Theme.Skin.Display.glassTop, Theme.Skin.Display.glassBottom],
                                                 startPoint: .top, endPoint: .bottom))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius)
                            .strokeBorder(Theme.white.opacity(0.06), lineWidth: 1)
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        // The caller retains its existing font, frame and numeric content transition.
    }
}

/// Place in an overlay: its two-point light never participates in content layout.
struct HardwareLightBar: View {
    var active = true
    var breathes = true
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var breathing = false

    private var shouldBreathe: Bool {
        active && breathes && !Theme.Motion.Policy(reduced: reduced).reduced
    }

    var body: some View {
        Rectangle().fill(Theme.orange)
            .frame(height: Theme.Skin.LightBar.height)
            .shadow(color: Theme.Skin.LightBar.glow, radius: Theme.Skin.LightBar.glowRadius)
            .opacity(active ? (shouldBreathe ? Theme.Motion.Policy(reduced: reduced).breathingOpacity(animating: breathing) : 1) : 0)
            .animation(shouldBreathe ? Theme.Motion.ledBreath : nil, value: breathing)
            .task(id: shouldBreathe) { breathing = shouldBreathe }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// Shared pad background surface with optional active state, bevel, border, and shadow.
struct PadSurface: View {
    var isActive: Bool = false
    var activeStrength: Double = 0
    var hasBorder: Bool = true
    var hasShadow: Bool = true

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius)
            .fill(isActive ? Theme.activeFill : Theme.Skin.Pad.fill)
            .overlay {
                if activeStrength > 0 {
                    RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius)
                        .fill(Theme.orange.opacity(activeStrength * 0.85))
                }
            }
            .overlay {
                SkinBevel(
                    radius: Theme.Skin.Pad.radius,
                    highlight: Theme.Skin.Pad.highlight,
                    shade: Theme.Skin.Pad.shade,
                    top: Theme.Skin.Pad.topBevel,
                    bottom: Theme.Skin.Pad.bottomBevel
                )
            }
            .overlay {
                if hasBorder {
                    RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius)
                        .strokeBorder(isActive ? Theme.orange : Theme.hairline,
                                      lineWidth: isActive ? Theme.Size.border : 1)
                }
            }
            .shadow(color: hasShadow ? Theme.black.opacity(0.08) : .clear,
                    radius: hasShadow ? 2 : 0,
                    y: hasShadow ? 2 : 0)
    }
}

/// Four-pad brand mark with a tilted orange top-right pad.
struct PadLogoGrid: View {
    var neutralColor: Color = Theme.ink
    var gap: CGFloat = 10
    var padRadius: CGFloat = 5

    var body: some View {
        VStack(spacing: gap) {
            HStack(spacing: gap) {
                RoundedRectangle(cornerRadius: padRadius)
                    .fill(neutralColor)
                RoundedRectangle(cornerRadius: padRadius)
                    .fill(Theme.orange)
                    .rotationEffect(.degrees(8))
            }
            HStack(spacing: gap) {
                RoundedRectangle(cornerRadius: padRadius)
                    .fill(neutralColor)
                RoundedRectangle(cornerRadius: padRadius)
                    .fill(neutralColor)
            }
        }
        .accessibilityHidden(true)
    }
}

extension View {
    func calmChassisBackground() -> some View { modifier(CalmChassisBackground()) }
    func satinPlate() -> some View { background { SatinPlateSurface() } }
    func structuralPlate() -> some View { background { StructuralPlateSurface() } }
    func insetDisplay() -> some View { modifier(InsetDisplay()) }
}
