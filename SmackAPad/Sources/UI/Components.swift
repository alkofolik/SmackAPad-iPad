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
                    Image(systemName: symbol)
                        .font(Theme.control).frame(width: 24)
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
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).font(Theme.control).lineLimit(1).fixedSize()
                .padding(.horizontal, Theme.Space.small)
                .frame(minHeight: Theme.Size.touch)
                .background(selected ? Theme.surface : Theme.background)
                .overlay(alignment: .bottom) {
                    if selected { Rectangle().fill(Theme.orange).frame(height: Theme.Size.border) }
                }
        }
        .buttonStyle(.plain).foregroundStyle(Theme.ink)
        .accessibilityAddTraits(selected ? .isSelected : [])
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
                Text(text).font(Theme.meta).lineLimit(1).fixedSize()
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action).font(Theme.control)
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
    }
}

/// A single glyph size for all three stars, including the requirements popover.
struct StarsView: View {
    @Environment(SettingsManager.self) private var settings
    let record: LessonProgress?
    var lesson: Lesson? = nil
    @State private var showingRequirements = false

    private var earned: [Bool] {
        [record?.passed ?? false, record?.mastery ?? false, record?.memory ?? false]
    }

    var body: some View {
        if let lesson {
            Button { showingRequirements.toggle() } label: {
                stars.padding(.horizontal, Theme.Space.small)
                    .frame(minHeight: Theme.Size.touch).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(settings.localized("Lesson stars"))
            .popover(isPresented: $showingRequirements, arrowEdge: .trailing) {
                VStack(alignment: .leading, spacing: Theme.Space.regular) {
                    SectionHeader(title: settings.localized("Lesson stars"))
                    ForEach(0..<3, id: \.self) { index in
                        HStack(spacing: Theme.Space.small) {
                            star(index)
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

    private var stars: some View {
        HStack(spacing: Theme.Space.small) {
            ForEach(0..<3, id: \.self) { star($0) }
        }
    }

    private func star(_ index: Int) -> some View {
        Image(systemName: earned[index] ? "star.fill" : "star")
            .font(Theme.control).frame(width: 16, height: 24)
            .foregroundStyle(earned[index] ? Theme.orange : Theme.ink)
            .accessibilityLabel(settings.localized(["Passed", "Goal tempo", "From memory"][index]))
            .accessibilityValue(settings.localized(earned[index] ? "On" : "Off"))
    }
}

struct ProgressLine: View {
    let full: Int
    var partial = 0
    let total: Int

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Rectangle().fill(Theme.ink)
                    .frame(width: geometry.size.width * CGFloat(full) / CGFloat(max(1, total)))
                Rectangle().fill(Theme.ink.opacity(0.35))
                    .frame(width: geometry.size.width * CGFloat(partial) / CGFloat(max(1, total)))
                Spacer(minLength: 0)
            }
            .background(Theme.surface)
        }
        .frame(height: Theme.Size.border).accessibilityHidden(true)
    }
}

private struct AppFormStyle: ViewModifier {
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
    }
}

extension View {
    func appFormStyle() -> some View { modifier(AppFormStyle()) }
}
