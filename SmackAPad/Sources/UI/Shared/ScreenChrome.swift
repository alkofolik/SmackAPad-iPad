import SwiftUI

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

extension View {
    func instrumentPanel(border: Color = Theme.hairline) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.panel)
        return self
            .background(Theme.surface, in: shape)
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(border, lineWidth: 1)
                    .allowsHitTesting(false)
            }
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
    var titleFont = Theme.rowTitle
    let action: () -> Void
    @ViewBuilder var meta: Meta
    @ViewBuilder var trailing: Trailing

    var body: some View {
        ViewThatFits(in: .horizontal) {
            if !dynamicType.isAccessibilitySize {
                HStack(spacing: Theme.Space.controlGap) {
                    rowButton
                    trailing.fixedSize(horizontal: true, vertical: false)
                }
            }
            VStack(alignment: .leading, spacing: Theme.Space.controlGap) {
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
                    Text(title).font(titleFont).fixedSize(horizontal: false, vertical: true)
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
            .textButtonTarget()
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

/// A flexible flowing layout that places views horizontally and wraps to subsequent rows when space runs out.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxAllowedWidth = proposal.width ?? .infinity
        var totalHeight: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width > maxAllowedWidth, currentRowWidth > 0 {
                totalHeight += currentRowHeight + spacing
                currentRowWidth = 0
                currentRowHeight = 0
            }
            currentRowWidth += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
        totalHeight += currentRowHeight
        return CGSize(width: maxAllowedWidth.isFinite ? maxAllowedWidth : currentRowWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += currentRowHeight + spacing
                currentRowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
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
                Button(action: action) {
                    Text(actionTitle).id(actionTitle).transition(.opacity)
                        .textButtonTarget()
                        .fixedSize()
                }
                .font(Theme.control)
            }
            if let secondaryActionTitle, let secondaryAction {
                Button(action: secondaryAction) {
                    Text(secondaryActionTitle)
                        .textButtonTarget()
                        .fixedSize()
                }
                .font(Theme.control)
            }
        }
        .padding(.horizontal, Theme.Space.small)
        .frame(minHeight: Theme.Size.touch)
        .background(Theme.surface).foregroundStyle(Theme.ink)
        .motion(value: text)
        .motion(value: actionTitle)
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

    func appFormRowStyle() -> some View {
        listRowBackground(Theme.surface)
            .listRowInsets(EdgeInsets(top: Theme.Space.small, leading: Theme.Space.regular,
                                     bottom: Theme.Space.small, trailing: Theme.Space.regular))
    }
}

/// Shared grid layout for physical pad profiles and MIDI learn.
struct PadProfileGrid<Cell: View>: View {
    let columns: Int
    let slots: [Int]
    @ViewBuilder let cell: (Int) -> Cell

    init(grid: PhysicalPadGrid, @ViewBuilder cell: @escaping (Int) -> Cell) {
        self.columns = grid.columns
        self.slots = grid.displaySlots
        self.cell = cell
    }

    init(profile: ControllerProfile, @ViewBuilder cell: @escaping (Int) -> Cell) {
        self.columns = profile.columns
        self.slots = profile.grid.displaySlots
        self.cell = cell
    }

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(minimum: Theme.Size.touch), spacing: Theme.Space.small),
                           count: columns),
            spacing: Theme.Space.small
        ) {
            ForEach(slots, id: \.self) { slot in
                cell(slot)
            }
        }
    }
}

extension MIDIInput {
    var connectedControllerName: String? {
        if let selectedID = selectedSourceID {
            return sources.first(where: { $0.id == selectedID })?.name ?? sources.first?.name
        }
        return sources.first?.name
    }
}
