import SwiftUI
import UIKit

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
    var destructive = false
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
            let base = destructive ? Theme.destructive : (primary ? Theme.black : Theme.ink)
            return base.opacity(0.35)
        }
        if destructive {
            return Theme.destructive
        } else if primary {
            return Theme.black
        } else {
            return Theme.ink
        }
    }

    private var backgroundColor: Color {
        guard enabled else {
            return Theme.disabledFill
        }
        if primary {
            return Theme.orange
        } else {
            return Theme.Skin.Pad.fill
        }
    }

    private var borderColor: Color {
        guard enabled else {
            return Theme.hairline.opacity(0.6)
        }
        if destructive {
            return Theme.destructiveOutline
        } else if primary {
            return Theme.black.opacity(0.18)
        } else {
            return Theme.hairline
        }
    }
}

struct PadPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PadControlBody(label: configuration.label, pressed: configuration.isPressed, primary: true)
    }
}

struct PadSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PadControlBody(
            label: configuration.label,
            pressed: configuration.isPressed,
            destructive: configuration.role == .destructive
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
        PadControlBody(
            label: configuration.label,
            pressed: configuration.isPressed,
            selected: isSelected,
            showLightBar: isSelected,
            horizontalPadding: 12
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
    func calmChassisBackground() -> some View { modifier(CalmChassisBackground()) }
    func satinPlate() -> some View { background { SatinPlateSurface() } }
    func structuralPlate() -> some View { background { StructuralPlateSurface() } }
    func insetDisplay() -> some View { modifier(InsetDisplay()) }
}

/// Native segmented controls ignore SwiftUI's custom font environment.
/// Keep the native control, but give both states real Plex faces and enough height.
struct PlexSegmentedPicker<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [(Value, String)]
    var fitsColumn = false
    @ScaledMetric(relativeTo: .body) private var pointSize: CGFloat = 24

    private var control: some View {
        PlexSegments(title: title, selection: $selection, options: options, pointSize: pointSize, fitsColumn: fitsColumn)
    }

    var body: some View {
        Group {
            if fitsColumn {
                control.frame(maxWidth: .infinity)
            } else {
                ViewThatFits(in: .horizontal) {
                    control.fixedSize()
                    ScrollView(.horizontal) { control.fixedSize() }
                        .fixedSize(horizontal: false, vertical: true)
                        .scrollIndicators(.hidden)
                        .scrollBounceBehavior(.basedOnSize)
                }
            }
        }
        .frame(minHeight: Theme.Size.touch)
    }
}

private final class PlexSegmentedControl: UISegmentedControl {
    var labelHeight: CGFloat = 48
    var fittedPointSize: CGFloat?

    override func layoutSubviews() {
        if let pointSize = fittedPointSize, bounds.width > 0 {
            let font = UIFont(name: "IBMPlexSans-Bold", size: pointSize)!
            let textWidth = (0..<numberOfSegments).reduce(CGFloat.zero) { width, index in
                width + ((titleForSegment(at: index) ?? "") as NSString).size(withAttributes: [.font: font]).width
            }
            let available = max(1, bounds.width - CGFloat(numberOfSegments) * 24)
            let size = pointSize * min(1, available / max(1, textWidth))
            let currentSize = (titleTextAttributes(for: .normal)?[.font] as? UIFont)?.pointSize
            if currentSize != size {
                setTitleTextAttributes([.font: UIFont(name: "IBMPlexSans-Regular", size: size)!], for: .normal)
                setTitleTextAttributes([.font: UIFont(name: "IBMPlexSans-Bold", size: size)!], for: .selected)
            }
        }
        super.layoutSubviews()
    }
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width, height: max(48, labelHeight))
    }
}

private struct PlexSegments<Value: Hashable>: UIViewRepresentable {
    @Environment(\.isEnabled) private var isEnabled
    let title: String
    @Binding var selection: Value
    let options: [(Value, String)]
    let pointSize: CGFloat
    let fitsColumn: Bool

    final class Coordinator {
        var parent: PlexSegments
        init(_ parent: PlexSegments) { self.parent = parent }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PlexSegmentedControl {
        let control = PlexSegmentedControl(items: options.map(\.1))
        control.apportionsSegmentWidthsByContent = true
        let coordinator = context.coordinator
        control.addAction(UIAction { [weak control] _ in
            guard let control, coordinator.parent.options.indices.contains(control.selectedSegmentIndex) else { return }
            coordinator.parent.selection = coordinator.parent.options[control.selectedSegmentIndex].0
        }, for: .valueChanged)
        return control
    }

    func updateUIView(_ control: PlexSegmentedControl, context: Context) {
        context.coordinator.parent = self
        if control.numberOfSegments != options.count {
            control.removeAllSegments()
            for (index, option) in options.enumerated() {
                control.insertSegment(withTitle: option.1, at: index, animated: false)
            }
        } else {
            for (index, option) in options.enumerated() { control.setTitle(option.1, forSegmentAt: index) }
        }
        let regular = UIFont(name: "IBMPlexSans-Regular", size: pointSize)!
        let bold = UIFont(name: "IBMPlexSans-Bold", size: pointSize)!
        control.setTitleTextAttributes([.font: regular], for: .normal)
        control.setTitleTextAttributes([.font: bold], for: .selected)
        control.fittedPointSize = fitsColumn ? pointSize : nil
        control.setNeedsLayout()
        control.labelHeight = max(regular.lineHeight, bold.lineHeight) + 16
        control.selectedSegmentIndex = options.firstIndex { $0.0 == selection } ?? UISegmentedControl.noSegment
        control.isEnabled = isEnabled
        control.accessibilityLabel = title
        control.invalidateIntrinsicContentSize()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: PlexSegmentedControl, context: Context) -> CGSize? {
        let intrinsic = uiView.intrinsicContentSize
        return CGSize(width: fitsColumn ? (proposal.width ?? intrinsic.width) : intrinsic.width,
                      height: intrinsic.height)
    }
}

struct ScreenHeader<Accessory: View>: View {
    let title: String
    @ViewBuilder var accessory: Accessory

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Theme.Space.regular) {
                Text(title).font(Theme.screenTitle).fixedSize()
                Spacer(minLength: 0)
                accessory.fixedSize(horizontal: true, vertical: false)
            }
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                Text(title).font(Theme.screenTitle).fixedSize(horizontal: false, vertical: true)
                accessory
            }
        }
        .foregroundStyle(Theme.ink)
    }
}

extension ScreenHeader where Accessory == EmptyView {
    init(title: String) { self.init(title: title) { EmptyView() } }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            Text(Theme.sentenceCase(title)).font(Theme.sectionTitle).foregroundStyle(Theme.ink)
            if let subtitle {
                Text(subtitle).font(Theme.meta).lineSpacing(4).foregroundStyle(Theme.secondary)
            }
        }
        .textCase(nil)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}

/// SwiftUI owns the text so confirmation copy uses the same scalable family.
struct AppConfirmation<Actions: View>: View {
    let title: String
    let message: String
    @ViewBuilder var actions: Actions

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.page) {
                Text(title).font(Theme.screenTitle)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message).font(Theme.navigation).lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: Theme.Space.regular) { actions }
                    .buttonStyle(PadSecondaryButtonStyle())
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(Theme.Space.page)
            .frame(maxWidth: .infinity)
        }
        .satinPlate().foregroundStyle(Theme.ink)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled()
    }
}

/// The primary action and trailing controls are siblings, never nested buttons.
struct ListRow<Meta: View, Trailing: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicType
    let symbol: String
    var symbolTint: Color? = nil
    let stateTitle: String
    var number: Int? = nil
    let title: String
    var dimmed = false
    let action: () -> Void
    @ViewBuilder var meta: Meta
    @ViewBuilder var trailing: Trailing

    var body: some View {
        ViewThatFits(in: .horizontal) {
            if !dynamicType.isAccessibilitySize {
                HStack(spacing: Theme.Space.small) {
                    rowButton
                    trailing.fixedSize(horizontal: true, vertical: false)
                }
            }
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                rowButton
                trailing
            }
        }
        .padding(.vertical, Theme.Space.small)
        .frame(minHeight: Theme.Size.listRow)
    }

    private var rowButton: some View {
        Button(action: action) {
            HStack(spacing: Theme.Space.small) {
                RowStateSymbol(symbol: symbol)
                    .font(Theme.control).frame(minWidth: 28)
                    .foregroundStyle(symbolTint ?? (dimmed ? Theme.secondary : Theme.ink))
                    .accessibilityLabel(stateTitle)
                if let number {
                    Text(number.formatted()).font(Theme.meta).frame(minWidth: 24)
                }
                VStack(alignment: .leading, spacing: Theme.Space.tight) {
                    Text(title).font(Theme.rowTitle).fixedSize(horizontal: false, vertical: true)
                    meta.font(Theme.meta).foregroundStyle(Theme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(dimmed ? Theme.secondary : Theme.ink)
            .frame(minHeight: Theme.Size.listRow)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct FilterChipButtonStyle: ButtonStyle {
    let isSelected: Bool
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        let policy = Theme.Motion.Policy(reduced: reduced)
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(isSelected ? Theme.ink : Theme.secondary)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(isSelected ? Theme.activeFill : Theme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .strokeBorder(isSelected ? Theme.orange : Theme.hairline, lineWidth: isSelected ? 1.5 : 1)
                    }
                    .allowsHitTesting(false)
            }
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay {
                if enabled {
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(policy.reduced ? Color.black : Color.white)
                        .opacity(pressed ? (policy.reduced ? Theme.Skin.Pad.reducedPressOpacity : Theme.Skin.Pad.flashOpacity) : 0)
                        .animation(policy.reduced ? nil : policy.animation(Theme.Motion.padFlash), value: pressed)
                        .allowsHitTesting(false)
                }
            }
            .scaleEffect(enabled ? policy.scale(pressed ? Theme.Skin.Pad.pressedScale : 1) : 1)
            .offset(y: enabled ? policy.offset(pressed ? Theme.Skin.Pad.pressedY : 0) : 0)
            .animation(enabled ? policy.animation(pressed ? Theme.Motion.padFlash : Theme.Motion.padPress) : nil, value: pressed)
    }
}

struct FilterChip: View {
    @Environment(\.accessibilityReduceMotion) private var reduced
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).font(Theme.meta).lineLimit(1).fixedSize()
                .contentTransition(Theme.Motion.Policy(reduced: reduced).numeric)
                .motion(value: title)
                .padding(.horizontal, Theme.Space.small)
                .frame(minHeight: Theme.Size.touch)
        }
        .buttonStyle(FilterChipButtonStyle(isSelected: selected))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .motion(value: selected)
    }
}

struct InfoBanner: View {
    let text: String
    var symbol = "info.circle"
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var secondaryActionTitle: String? = nil
    var secondaryAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Theme.Space.small) {
            Image(systemName: symbol).font(Theme.control)
            // Long stage names stay on one line and can be read by scrolling.
            ScrollView(.horizontal, showsIndicators: false) {
                Text(text).font(Theme.meta).lineLimit(1).fixedSize().id(text).transition(.opacity)
            }
            .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(action: action) { Text(actionTitle).id(actionTitle).transition(.opacity) }.font(Theme.control)
                    .frame(minHeight: Theme.Size.touch).fixedSize()
            }
            if let secondaryActionTitle, let secondaryAction {
                Button(secondaryActionTitle, action: secondaryAction).font(Theme.control)
                    .frame(minHeight: Theme.Size.touch).fixedSize()
            }
        }
        .padding(.horizontal, Theme.Space.small)
        .frame(minHeight: Theme.Size.touch)
        .background(Theme.surface).foregroundStyle(Theme.ink)
        .motion(value: text)
        .motion(value: actionTitle)
    }
}

/// A single glyph size for all three stars, including the requirements popover.
struct StarsView: View {
    @Environment(SettingsManager.self) private var settings
    let record: LessonProgress?
    var lesson: Lesson? = nil
    @State private var showingRequirements = false
    @Environment(\.returnedStars) private var returnedStars
    @Environment(\.consumeReturnedStars) private var consumeReturnedStars
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var popping: Set<Int> = []

    private var earned: [Bool] {
        [record?.passed ?? false, record?.mastery ?? false, record?.memory ?? false]
    }

    private var starCount: Int {
        earned.filter { $0 }.count
    }

    var body: some View {
        HStack(spacing: Theme.Space.tight) {
            if let lesson {
                Button { showingRequirements.toggle() } label: {
                    stars.padding(.horizontal, Theme.Space.tight)
                        .frame(minHeight: Theme.Size.touch).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.localized("Lesson stars"))

                Button { showingRequirements.toggle() } label: {
                    Image(systemName: "info.circle")
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary)
                        .frame(minWidth: 28, minHeight: Theme.Size.touch)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.localized("Star requirements"))
                .popover(isPresented: $showingRequirements, arrowEdge: .trailing) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Space.regular) {
                            SectionHeader(title: settings.localized("Lesson stars"))
                            ForEach(0..<3, id: \.self) { index in
                                HStack(spacing: Theme.Space.small) {
                                    Image(systemName: earned[index] ? "star.fill" : "star")
                                        .font(Theme.control).frame(minWidth: 28, minHeight: 32)
                                        .foregroundStyle(earned[index] ? Theme.starColor(for: index + 1) : Theme.starColor(for: 0))
                                    Text(StarRequirement.requirementText(for: index, lesson: lesson,
                                        padCount: settings.activeProfile().padCount, settings: settings))
                                        .font(Theme.control).fixedSize(horizontal: false, vertical: true)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                        .padding(Theme.Space.page).frame(maxWidth: 380)
                        .foregroundStyle(Theme.ink).satinPlate()
                    }
                    .frame(idealWidth: 380, maxHeight: 560)
                }
            } else {
                stars
            }
        }
    }

    private var stars: some View {
        HStack(spacing: Theme.Space.small) {
            ForEach(0..<3, id: \.self) { index in
                star(index)
                    .scaleEffect(Theme.Motion.Policy(reduced: reduced).scale(popping.contains(index) ? 1.25 : 1))
                    .opacity(Theme.Motion.Policy(reduced: reduced).opacityOnly && popping.contains(index) ? 0.45 : 1)
                    .motion(Theme.Motion.emphasis, value: popping)
            }
        }
        .task(id: lesson.map { returnedStars[$0.id] ?? [] } ?? []) {
            guard let lesson else { return }
            let fresh = consumeReturnedStars(lesson.id)
            guard !fresh.isEmpty else { return }
            for index in fresh.sorted() {
                popping.insert(index)
                do { try await Task.sleep(for: Theme.Motion.starStagger) } catch { return }
            }
            do { try await Task.sleep(for: .milliseconds(180)) } catch { return }
            popping = []
        }
    }

    private func star(_ index: Int) -> some View {
        let isEarned = earned[index]
        return Image(systemName: isEarned ? "star.fill" : "star")
            .font(Theme.control).frame(minWidth: 28, minHeight: 32)
            .foregroundStyle(isEarned ? Theme.starColor(for: starCount) : Theme.starColor(for: 0))
            .accessibilityLabel(settings.localized(["Passed", "Goal tempo", "From memory"][index]))
            .accessibilityValue(settings.localized(isEarned ? "On" : "Off"))
    }
}

struct ProgressLine: View {
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var appeared = false
    let threeStars: Int
    let twoStars: Int
    let oneStar: Int
    let total: Int

    init(threeStars: Int, twoStars: Int = 0, oneStar: Int = 0, total: Int) {
        self.threeStars = threeStars
        self.twoStars = twoStars
        self.oneStar = oneStar
        self.total = total
    }

    init(full: Int, partial: Int = 0, total: Int) {
        self.init(threeStars: full, twoStars: partial, oneStar: 0, total: total)
    }

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let t = CGFloat(max(1, total))
            let factor = appeared || Theme.Motion.Policy(reduced: reduced).opacityOnly ? 1.0 : 0.0
            HStack(spacing: 0) {
                Rectangle().fill(Theme.starColor(for: 3))
                    .frame(width: w * CGFloat(threeStars) / t * factor)
                Rectangle().fill(Theme.starColor(for: 2))
                    .frame(width: w * CGFloat(twoStars) / t * factor)
                Rectangle().fill(Theme.starColor(for: 1))
                    .frame(width: w * CGFloat(oneStar) / t * factor)
                Spacer(minLength: 0)
            }
            .background(Theme.starColor(for: 0))
        }
        .frame(height: Theme.Size.border).accessibilityHidden(true)
        .onAppear { appeared = true }
        .motion(Theme.Motion.emphasis, value: appeared)
        .motion(Theme.Motion.emphasis, value: threeStars)
        .motion(Theme.Motion.emphasis, value: twoStars)
        .motion(Theme.Motion.emphasis, value: oneStar)
        .transaction { transaction in
            // Reduce Motion fades the completed line instead of interpolating its width.
            if Theme.Motion.Policy(reduced: reduced).opacityOnly { transaction.animation = nil }
        }
        .opacity(appeared ? 1 : 0)
        .motion(value: appeared)
    }
}

private struct AppFormStyle: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduced
    func body(content: Content) -> some View {
        content
            .font(Theme.control)
            .lineSpacing(4)
            .environment(\.defaultMinListRowHeight, 64)
            .listRowInsets(EdgeInsets(top: Theme.Space.small, leading: Theme.Space.regular,
                                     bottom: Theme.Space.small, trailing: Theme.Space.regular))
            .listRowBackground(Theme.surface)
            .contentMargins(.horizontal, Theme.Space.page, for: .scrollContent)
            .scrollContentBackground(.hidden)
            .calmChassisBackground().foregroundStyle(Theme.ink).tint(Theme.orange)
            .transaction { transaction in
                if transaction.animation != nil {
                    transaction.animation = Theme.Motion.Policy(reduced: reduced).opacityOnly ? nil : Theme.Motion.fast
                }
            }
    }
}

extension View {
    func appFormStyle() -> some View { modifier(AppFormStyle()) }
}

/// Retains an opening lock long enough to read it before it fades away.
struct AnimatedLock: View {
    let locked: Bool
    @State private var showing = false
    @State private var open = false
    var body: some View {
        Image(systemName: open ? "lock.open" : "lock")
            .contentTransition(.opacity)
            .opacity(locked || showing ? 1 : 0)
            .frame(width: locked || showing ? 16 : 0)
            .motion(value: open)
            .motion(value: showing)
            .onAppear { open = !locked }
            .task(id: locked) {
                if locked { open = false; showing = false }
                else {
                    showing = true; open = true
                    do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
                    showing = false
                }
            }
            .accessibilityHidden(!locked)
    }
}

private struct RowStateSymbol: View {
    let symbol: String
    @State private var wasLocked = false
    @State private var opening = false
    var body: some View {
        Image(systemName: opening ? "lock.open" : symbol)
            .contentTransition(.opacity)
            .motion(value: opening)
            .motion(value: symbol)
            .onAppear { wasLocked = symbol == "lock" }
            .task(id: symbol) {
                guard wasLocked, symbol != "lock" else {
                    wasLocked = symbol == "lock"; return
                }
                opening = true
                do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
                opening = false; wasLocked = false
            }
    }
}
