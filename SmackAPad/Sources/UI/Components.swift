import SwiftUI

struct ScreenHeader<Accessory: View>: View {
    let title: String
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(spacing: Theme.Space.regular) {
            Text(title).font(Theme.screenTitle).lineLimit(1)
            Spacer(minLength: 0)
            accessory
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
            Text(title).font(Theme.sectionTitle).foregroundStyle(Theme.ink)
            if let subtitle {
                Text(subtitle).font(Theme.meta).foregroundStyle(Theme.secondary)
            }
        }
        .textCase(nil)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}

/// The primary action and trailing controls are siblings, never nested buttons.
struct ListRow<Meta: View, Trailing: View>: View {
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
        HStack(spacing: Theme.Space.small) {
            Button(action: action) {
                HStack(spacing: Theme.Space.small) {
                    RowStateSymbol(symbol: symbol)
                        .font(Theme.control).frame(width: 24)
                        .foregroundStyle(symbolTint ?? (dimmed ? Theme.secondary : Theme.ink))
                        .accessibilityLabel(stateTitle)
                    if let number {
                        Text(number.formatted()).font(Theme.meta).frame(minWidth: 24)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(title).font(Theme.rowTitle).lineLimit(1)
                        meta.font(Theme.meta).foregroundStyle(Theme.secondary).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundStyle(dimmed ? Theme.secondary : Theme.ink)
                .frame(minHeight: 60)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            trailing
        }
        .frame(minHeight: 60)
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
                .frame(minHeight: 28)
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
        .frame(height: Theme.Size.touch)
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
                        .frame(width: 28, height: Theme.Size.touch)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.localized("Star requirements"))
                .popover(isPresented: $showingRequirements, arrowEdge: .trailing) {
                    VStack(alignment: .leading, spacing: Theme.Space.regular) {
                        SectionHeader(title: settings.localized("Lesson stars"))
                        ForEach(0..<3, id: \.self) { index in
                            HStack(spacing: Theme.Space.small) {
                                Image(systemName: earned[index] ? "star.fill" : "star")
                                    .font(Theme.control).frame(width: 16, height: 24)
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
            .font(Theme.control).frame(width: 16, height: 24)
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
