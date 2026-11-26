import SwiftUI

/// Preserve the label's natural width while allowing full-width labels to fill their proposal.
/// Padding belongs to the face, so even a compressed toolbar cannot put text on its border.
private struct PadLabelLayout: Layout {
    var horizontalPadding: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        if subviews.count == 1, let label = subviews.first {
            let labelProposal = ProposedViewSize(
                width: proposal.width.map { max(0, $0 - horizontalPadding * 2) },
                height: proposal.height
            )
            let ideal = label.sizeThatFits(.unspecified)
            let fitted = label.sizeThatFits(labelProposal)
            return CGSize(
                width: max(Theme.Size.touch, max(ideal.width, fitted.width) + horizontalPadding * 2),
                height: max(Theme.Size.touch, max(ideal.height, fitted.height))
            )
        }
        let totalSpacing = Theme.Space.small * CGFloat(subviews.count - 1)
        let innerProposal = ProposedViewSize(
            width: proposal.width.map { max(0, $0 - horizontalPadding * 2 - totalSpacing) },
            height: proposal.height
        )
        let ideals = subviews.map { $0.sizeThatFits(.unspecified) }
        let fitteds = subviews.map { $0.sizeThatFits(innerProposal) }
        let totalIdealWidth = ideals.map(\.width).reduce(0, +) + totalSpacing
        let totalFittedWidth = fitteds.map(\.width).reduce(0, +) + totalSpacing
        let maxHeight = (ideals + fitteds).map(\.height).max() ?? 0
        return CGSize(
            width: max(Theme.Size.touch, max(totalIdealWidth, totalFittedWidth) + horizontalPadding * 2),
            height: max(Theme.Size.touch, maxHeight)
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        if subviews.count == 1, let label = subviews.first {
            label.place(
                at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center,
                proposal: ProposedViewSize(width: max(0, bounds.width - horizontalPadding * 2), height: bounds.height)
            )
            return
        }
        let totalSpacing = Theme.Space.small * CGFloat(subviews.count - 1)
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let totalContentWidth = sizes.map(\.width).reduce(0, +) + totalSpacing
        var currentX = bounds.midX - totalContentWidth / 2
        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            subview.place(
                at: CGPoint(x: currentX + size.width / 2, y: bounds.midY),
                anchor: .center,
                proposal: ProposedViewSize(size)
            )
            currentX += size.width + Theme.Space.small
        }
    }
}

private struct PadControlBody<Label: View>: View {
    let label: Label
    let pressed: Bool
    var primary = false
    var darkFace = false
    var destructive = false
    var onDark = false
    var selected: Bool? = nil
    var showLightBar = false
    var horizontalPadding: CGFloat = 16
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.isEnabled) private var enabled

    var body: some View {
        let policy = Theme.Motion.Policy(reduced: reduced)
        let shape = RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius)
        PadLabelLayout(horizontalPadding: horizontalPadding) {
            HStack(spacing: Theme.Space.small) {
                label
            }
            .lineLimit(1)
        }
            .foregroundStyle(foregroundColor)
            .background {
                shape
                    .fill(backgroundColor)
                    .overlay {
                        shape.strokeBorder(borderColor, lineWidth: 1)
                    }
                    .allowsHitTesting(false)
            }
            .contentShape(shape)
            .overlay(alignment: .bottom) {
                if showLightBar, let selected {
                    Color.clear.overlay(alignment: .bottom) { HardwareLightBar(active: selected) }
                        .clipShape(shape)
                        .motion(Theme.Motion.fast, value: selected)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .overlay {
                if enabled {
                    shape
                        .fill(policy.reduced ? Color.black : Color.white)
                        .opacity(pressed ? (policy.reduced ? Theme.Skin.Pad.reducedPressOpacity : Theme.Skin.Pad.flashOpacity) : 0)
                        .animation(policy.reduced ? nil : policy.animation(Theme.Motion.padFlash), value: pressed)
                        .allowsHitTesting(false)
                }
            }
            .scaleEffect(enabled ? policy.scale(pressed ? Theme.Skin.Pad.pressedScale : 1) : 1)
            .offset(y: enabled ? policy.offset(pressed ? Theme.Skin.Pad.pressedY : 0) : 0)
            .animation(enabled ? policy.animation(pressed ? Theme.Motion.padFlash : Theme.Motion.padPress) : nil, value: pressed)
        // Face, border and press overlays use the same bounds; no offset shadow layer.
    }

    private var foregroundColor: Color {
        guard enabled else {
            let base = destructive ? Theme.destructive : (primary && !darkFace ? Theme.black : (onDark ? Theme.white : Theme.ink))
            return base.opacity(0.35)
        }
        if destructive {
            return Theme.destructive
        } else if primary {
            return darkFace ? Theme.white : Theme.black
        } else if onDark {
            return Theme.white
        } else {
            return Theme.ink
        }
    }

    private var backgroundColor: Color {
        guard enabled else {
            return Theme.disabledFill
        }
        if primary {
            return darkFace ? Theme.black : Theme.orange
        } else if onDark {
            return Theme.white.opacity(0.10)
        } else {
            return Theme.Skin.Pad.fill
        }
    }

    private var borderColor: Color {
        guard enabled else {
            return onDark ? Theme.white.opacity(0.16) : Theme.hairline.opacity(0.6)
        }
        if destructive {
            return Theme.destructiveOutline
        } else if primary {
            return Theme.black.opacity(0.18)
        } else if onDark {
            return Theme.white.opacity(0.28)
        } else {
            return Theme.hairline
        }
    }
}

struct PadPrimaryButtonStyle: ButtonStyle {
    var darkFace = false

    func makeBody(configuration: Configuration) -> some View {
        PadControlBody(label: configuration.label, pressed: configuration.isPressed, primary: true, darkFace: darkFace)
    }
}

struct PadSecondaryButtonStyle: ButtonStyle {
    var onDark: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        PadControlBody(
            label: configuration.label,
            pressed: configuration.isPressed,
            destructive: configuration.role == .destructive,
            onDark: onDark
        )
    }
}

struct PadDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PadControlBody(
            label: configuration.label,
            pressed: configuration.isPressed,
            destructive: true
        )
    }
}

struct PadIconButtonStyle: ButtonStyle {
    var selected: Bool? = nil
    var destructive = false

    func makeBody(configuration: Configuration) -> some View {
        PadControlBody(
            label: configuration.label,
            pressed: configuration.isPressed,
            destructive: destructive || configuration.role == .destructive,
            selected: selected,
            showLightBar: false,
            horizontalPadding: 0
        )
    }
}

/// Apply to each existing segment button; the group retains its sizes and selection binding.
struct HardwareKeyButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        HardwareKeyFace(isSelected: isSelected, pressed: configuration.isPressed) {
            configuration.label
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct HardwareKeyFace<Label: View>: View {
    let isSelected: Bool
    var pressed = false
    @ViewBuilder let label: Label

    var body: some View {
        PadControlBody(
            label: label,
            pressed: pressed,
            selected: isSelected,
            showLightBar: isSelected,
            horizontalPadding: 12
        )
    }
}

/// Custom pads provide their own face; hide the system's additional glass capsule.
struct PadToolbarItem<Content: View>: ToolbarContent {
    let placement: ToolbarItemPlacement
    private let content: Content

    init(placement: ToolbarItemPlacement, @ViewBuilder content: () -> Content) {
        self.placement = placement
        self.content = content()
    }

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: placement) {
                content.fixedSize(horizontal: true, vertical: false)
            }
            .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: placement) {
                content.fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}

extension View {
    func textButtonTarget(alignment: Alignment = .center) -> some View {
        frame(minWidth: Theme.Size.minimumTouch, minHeight: Theme.Size.touch, alignment: alignment)
            .contentShape(Rectangle())
    }
}
