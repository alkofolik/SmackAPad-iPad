import SwiftUI

enum HelpTopic: String, CaseIterable {
    case goal, modes, memory, stars, tempo, reviews, overview, inputs

    var titleKey: String {
        switch self {
        case .memory: "From memory"
        case .stars: "Stars"
        case .tempo: "Tempo"
        case .reviews: "Reviews"
        default: "help.\(rawValue).title"
        }
    }

    var captionKey: String { "help.\(rawValue).caption" }
}

enum HelpPresentation: Equatable {
    case popover, sheet

    init(windowWidth: CGFloat) {
        self = windowWidth < 600 ? .sheet : .popover
    }
}

extension View {
    func helpDeck(
        presentation: Binding<HelpPresentation?>,
        arrowEdge: Edge = .top,
        lesson: Lesson? = nil,
        onDismiss: @escaping () -> Void
    ) -> some View {
        let deck = {
            HelpDeck(lesson: lesson) { presentation.wrappedValue = nil }
        }
        return self
            .popover(isPresented: helpBinding(presentation, style: .popover), arrowEdge: arrowEdge) {
                deck()
                    .frame(idealWidth: 660, idealHeight: 540)
                    .presentationCompactAdaptation(.sheet)
                    .onDisappear(perform: onDismiss)
            }
            .sheet(isPresented: helpBinding(presentation, style: .sheet), onDismiss: onDismiss) {
                deck().presentationDragIndicator(.visible)
            }
    }

    private func helpBinding(_ presentation: Binding<HelpPresentation?>, style: HelpPresentation) -> Binding<Bool> {
        Binding(
            get: { presentation.wrappedValue == style },
            set: { if !$0 && presentation.wrappedValue == style { presentation.wrappedValue = nil } }
        )
    }
}

struct HelpEntryLabel: View {
    @Environment(SettingsManager.self) private var settings
    @ScaledMetric(relativeTo: .body) private var textSize = 18.0

    var body: some View {
        HStack(spacing: Theme.Space.small) {
            Image(systemName: "questionmark.circle").accessibilityHidden(true)
            Text(settings.localized("help.title"))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Theme.Space.small)
            Image(systemName: "chevron.right")
                .font(Theme.canvasDisplay(13))
                .accessibilityHidden(true)
        }
        .font(Theme.text(textSize))
        .frame(minHeight: Theme.Size.touch)
        .contentShape(Rectangle())
    }
}

struct HelpDeck: View {
    @Environment(SettingsManager.self) private var settings
    @ScaledMetric(relativeTo: .title) private var headingSize = 28.0
    @ScaledMetric(relativeTo: .body) private var controlSize = 18.0
    @AccessibilityFocusState private var headingFocus: Page?
    @State private var index = 0
    @State private var replayIndex: Int?
    var lesson: Lesson? = nil
    var firstLaunch = false
    let onClose: () -> Void

    private struct Page: Hashable {
        let index: Int
        let tutorial: Bool
    }

    private var page: Page { Page(index: replayIndex ?? index, tutorial: firstLaunch || replayIndex != nil) }
    private var topic: HelpTopic { HelpTopic.allCases[page.index] }
    private var count: Int { page.tutorial ? 4 : HelpTopic.allCases.count }
    private var position: String { settings.localized("help.nav.position", page.index + 1, count) }

    var body: some View {
        VStack(spacing: Theme.Space.small) {
            header
            ScrollView {
                HelpIllustration(topic: topic, lesson: page.tutorial ? nil : lesson)
                    .padding(.vertical, Theme.Space.regular)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .id(page)
            .scrollBounceBehavior(.basedOnSize)
            Divider().overlay(Theme.hairline)
            footer
        }
        .padding(Theme.Space.page)
        .frame(maxWidth: 680, maxHeight: .infinity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Theme.ink)
        .background(Theme.background)
        .presentationBackground(Theme.background)
        .interactiveDismissDisabled(replayIndex != nil)
        .task(id: page) {
            // Moving focus also reads the heading's position on each page.
            let currentPage = page
            await Task.yield()
            guard !Task.isCancelled else { return }
            headingFocus = currentPage
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Theme.Space.regular) {
            Text(settings.localized(topic.titleKey))
                .font(Theme.display(headingSize))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityValue(position)
                .accessibilityFocused($headingFocus, equals: page)
                .frame(maxWidth: .infinity, minHeight: Theme.Size.touch, alignment: .leading)
            Button(action: close) {
                controlLabel(page.tutorial ? "Skip" : "Close")
                    .textButtonTarget(alignment: .trailing)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
            .fixedSize()
        }
    }

    @ViewBuilder
    private var footer: some View {
        if !page.tutorial && index == 0 {
            ViewThatFits(in: .horizontal) {
                HStack {
                    replayButton
                    Spacer()
                    positionLabel
                    Spacer()
                    nextButton
                }
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity)
                VStack(spacing: Theme.Space.tight) {
                    navigationRow
                    replayButton.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } else {
            navigationRow
        }
    }

    private var navigationRow: some View {
        HStack(spacing: Theme.Space.small) {
            if page.index > 0 {
                Button { move(by: -1) } label: { controlLabel("help.nav.back") }
                    .buttonStyle(PadSecondaryButtonStyle())
            }
            positionLabel.frame(maxWidth: .infinity)
            nextButton
        }
    }

    private var positionLabel: some View {
        Text(position)
            .font(Theme.text(controlSize))
            .monospacedDigit()
            .multilineTextAlignment(.center)
            .accessibilityHidden(true)
    }

    private var replayButton: some View {
        Button { replayIndex = 0 } label: {
            controlLabel("help.tutorial.reopen").textButtonTarget(alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private var nextButton: some View {
        let isLast = page.index == count - 1
        return Button {
            if isLast { close() } else { move(by: 1) }
        } label: {
            controlLabel(isLast ? "Done" : "Next")
        }
        .buttonStyle(PadPrimaryButtonStyle())
    }

    private func controlLabel(_ key: String) -> some View {
        Text(settings.localized(key))
            .font(Theme.strong(controlSize))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(minWidth: Theme.Size.touch, minHeight: Theme.Size.touch)
    }

    private func move(by offset: Int) {
        if let replayIndex {
            self.replayIndex = replayIndex + offset
        } else {
            index += offset
        }
    }

    private func close() {
        if replayIndex != nil {
            replayIndex = nil
        } else {
            onClose()
        }
    }
}
