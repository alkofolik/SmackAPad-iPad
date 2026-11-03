import SwiftUI
import UIKit

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
                    .buttonStyle(InstrumentButtonStyle(main: true))
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(Theme.Space.page)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background).foregroundStyle(Theme.ink)
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
        .frame(minHeight: 60)
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
            .frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                .background(selected ? Theme.surface : Theme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Size.blockRadius)
                        .stroke(selected ? Theme.orange : Theme.secondary.opacity(0.35), lineWidth: 1)
                )
        }
        .buttonStyle(.plain).foregroundStyle(selected ? Theme.orange : Theme.ink)
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
                        .foregroundStyle(Theme.ink).background(Theme.background)
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
            .background(Theme.background).foregroundStyle(Theme.ink).tint(Theme.orange)
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
