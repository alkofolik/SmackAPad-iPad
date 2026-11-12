import SwiftUI

enum HelpTopic: String, CaseIterable, Identifiable {
    case lesson, modes, signals, stars, tempo, memory, reviews, training, library, controller, keyboard, setup

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .memory: "From memory"
        case .stars: "Stars"
        case .tempo: "Tempo"
        case .reviews: "Reviews"
        case .library: "Library"
        case .controller: "MIDI controller"
        default: "help.\(rawValue).title"
        }
    }

    var captionKey: String { "help.\(rawValue).caption" }
}

enum TutorialCard: String, CaseIterable {
    case playLesson, hitColours, modes, starsAndTempo, whereNext

    var titleKey: String { "help.tutorial.\(rawValue).title" }
    var captionKey: String { "help.tutorial.\(rawValue).caption" }
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
        initialTopic: HelpTopic? = nil,
        onDismiss: @escaping () -> Void
    ) -> some View {
        let deck = {
            HelpDeck(initialTopic: initialTopic) { presentation.wrappedValue = nil }
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
    @State private var topic: HelpTopic?
    @State private var tutorialIndex: Int?
    @State private var cameFromContents: Bool
    private let onClose: () -> Void

    init(initialTopic: HelpTopic? = nil, onClose: @escaping () -> Void) {
        _topic = State(initialValue: initialTopic)
        _tutorialIndex = State(initialValue: nil)
        _cameFromContents = State(initialValue: initialTopic == nil)
        self.onClose = onClose
    }

    private enum Page: Hashable {
        case contents
        case topic(HelpTopic)
        case tutorial(TutorialCard)

        var titleKey: String {
            switch self {
            case .contents: "help.title"
            case .topic(let topic): topic.titleKey
            case .tutorial(let card): card.titleKey
            }
        }
    }

    private var page: Page {
        if let tutorialIndex { return .tutorial(TutorialCard.allCases[tutorialIndex]) }
        if let topic { return .topic(topic) }
        return .contents
    }

    var body: some View {
        let currentPage = page
        return VStack(spacing: Theme.Space.small) {
            header(for: currentPage)
            ScrollView {
                switch currentPage {
                case .contents:
                    topicList
                case .topic(let topic):
                    HelpIllustration(topic: topic)
                case .tutorial(let card):
                    HelpIllustration(card: card)
                }
            }
            .id(currentPage)
            .scrollBounceBehavior(.basedOnSize)
            Divider().overlay(Theme.hairline)
            footer(for: currentPage)
        }
        .padding(Theme.Space.page)
        .frame(maxWidth: 680, maxHeight: .infinity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Theme.ink)
        .background(Theme.background)
        .presentationBackground(Theme.background)
        .interactiveDismissDisabled(tutorialIndex != nil)
        .task(id: currentPage) {
            await Task.yield()
            guard !Task.isCancelled else { return }
            headingFocus = currentPage
        }
    }

    private func header(for page: Page) -> some View {
        HStack(alignment: .center, spacing: Theme.Space.regular) {
            BackButton { backAction(for: page) }
            Text(settings.localized(page.titleKey))
                .font(Theme.display(headingSize))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityValue(tutorialIndex.map(tutorialPosition) ?? "")
                .accessibilityFocused($headingFocus, equals: page)
                .frame(maxWidth: .infinity, minHeight: Theme.Size.touch, alignment: .leading)
        }
    }

    private func backAction(for page: Page) {
        switch page {
        case .contents:
            onClose()
        case .topic:
            if cameFromContents {
                topic = nil
            } else {
                onClose()
            }
        case .tutorial:
            close()
        }
    }

    private var topicList: some View {
        VStack(spacing: 0) {
            ForEach(HelpTopic.allCases) { item in
                Button { topic = item } label: {
                    HStack(spacing: Theme.Space.small) {
                        Text(settings.localized(item.titleKey))
                            .font(Theme.text(controlSize))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: Theme.Space.small)
                        Image(systemName: "chevron.right")
                            .font(Theme.canvasDisplay(13))
                            .accessibilityHidden(true)
                    }
                    .frame(minHeight: Theme.Size.touch)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Divider().overlay(Theme.hairline)
            }
        }
    }

    @ViewBuilder
    private func footer(for page: Page) -> some View {
        switch page {
        case .contents:
            Button { tutorialIndex = 0 } label: {
                controlLabel("help.tutorial.reopen").textButtonTarget(alignment: .leading)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
        case .topic:
            Button {
                cameFromContents = true
                topic = nil
            } label: {
                controlLabel("help.nav.topics")
            }
            .buttonStyle(PadSecondaryButtonStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
        case .tutorial:
            if let tutorialIndex {
                let isLast = tutorialIndex == TutorialCard.allCases.count - 1
                HStack(spacing: Theme.Space.small) {
                    if tutorialIndex > 0 {
                        Button { self.tutorialIndex = tutorialIndex - 1 } label: { controlLabel("help.nav.back") }
                            .buttonStyle(PadSecondaryButtonStyle())
                    }
                    Text(tutorialPosition(tutorialIndex))
                        .font(Theme.text(controlSize))
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                    Button {
                        if isLast { close() } else { self.tutorialIndex = tutorialIndex + 1 }
                    } label: {
                        controlLabel(isLast ? "Done" : "Next")
                    }
                    .buttonStyle(PadPrimaryButtonStyle())
                }
            }
        }
    }

    private func tutorialPosition(_ index: Int) -> String {
        settings.localized("help.nav.position", index + 1, TutorialCard.allCases.count)
    }

    private func controlLabel(_ key: String) -> some View {
        Text(settings.localized(key))
            .font(Theme.strong(controlSize))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(minWidth: Theme.Size.touch, minHeight: Theme.Size.touch)
    }

    private func close() {
        if tutorialIndex == nil {
            onClose()
        } else {
            tutorialIndex = nil
        }
    }
}
