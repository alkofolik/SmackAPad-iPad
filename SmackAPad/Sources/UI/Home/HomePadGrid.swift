import SwiftUI

func hasAnyLessonProgress(_ records: [Int: LessonProgress]) -> Bool {
    records.values.contains { $0.hasPlayed || $0.passed || $0.mastery || $0.memory }
}

func shouldPulseIntroPad(
    loadSucceeded: Bool,
    records: [Int: LessonProgress],
    animationFinished: Bool
) -> Bool {
    loadSucceeded && animationFinished && !hasAnyLessonProgress(records)
}

/// 3×3 pad grid (8 outer navigation pads + centre About logo pad) on Home.
struct HomePadGrid: View {
    let cellSize: CGFloat
    let gap: CGFloat
    let plateVisible: Bool
    let padVisible: [Bool]
    let animationFinished: Bool
    let introPadShouldPulse: Bool
    let todayPlan: TodayPlan?
    let lessonStore: LessonStore
    let homeNamespace: Namespace.ID
    @AccessibilityFocusState.Binding var introFocused: Bool
    let onSelectToday: () -> Void
    let onOpenDestination: (HomePadDestination) -> Void
    let onNavigateToLibrary: (LibraryLaunchTarget) -> Void

    @Environment(StoreManager.self) private var store
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressionManager.self) private var progression
    @Environment(BadgeStore.self) private var badgeStore
    @Environment(MIDIInput.self) private var midi
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: gap) {
            // Row 0: Today (1) · Library (2) · Continue (3)
            HStack(spacing: gap) {
                bootPad(pad1, isVisible: padVisible[0])
                    .padSource("pad-training", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
                bootPad(pad2, isVisible: padVisible[1])
                    .padSource("pad-library", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
                bootPad(pad3, isVisible: padVisible[2])
                    .padSource("pad-continue", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
            }
            // Row 1: Intro (4) · Centre Logo Pad (About) · Controller (5)
            HStack(spacing: gap) {
                bootPad(pad4, isVisible: padVisible[3])
                    .padSource("pad-intro", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
                centreLogoPad
                    .padSource("pad-about", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
                bootPad(pad5, isVisible: padVisible[4])
                    .padSource("pad-controller", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
            }
            // Row 2: Badges (6) · Full Version (7) · Settings (8)
            HStack(spacing: gap) {
                bootPad(pad6, isVisible: padVisible[5])
                    .padSource("pad-badges", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
                bootPad(pad7, isVisible: padVisible[6])
                    .padSource("pad-purchases", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
                bootPad(pad8, isVisible: padVisible[7])
                    .padSource("pad-settings", in: homeNamespace)
                    .frame(width: cellSize, height: cellSize)
            }
        }
    }

    @ViewBuilder
    private func bootPad<Content: View>(_ content: Content, isVisible: Bool) -> some View {
        let policy = Theme.Motion.Policy(reduced: reduceMotion)
        content
            .scaleEffect(policy.scale(isVisible ? 1.0 : 0.85))
            .opacity(isVisible ? 1.0 : 0.0)
            .allowsHitTesting(isVisible)
    }

    private func localizedTitle(_ key: String) -> String {
        settings.localized(key).uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
    }

    private var pad1: some View {
        HomePadView(
            title: localizedTitle("Today"),
            subtitle: HomePadSubtitles.today(plan: todayPlan, language: settings.languagePreference),
            padNumber: 1,
            cellSize: cellSize,
            isHero: true,
            action: onSelectToday
        )
    }

    private var pad2: some View {
        HomePadView(
            title: localizedTitle("Library"),
            subtitle: HomePadSubtitles.library(),
            padNumber: 2,
            cellSize: cellSize,
            isHero: false
        ) {
            onOpenDestination(.library(.none))
            onNavigateToLibrary(.none)
            AppNavigation.shared.openLibrary(.none)
        }
    }

    private var pad3: some View {
        let lastLesson = settings.lastLessonID == 0 ? nil : lessonStore.lesson(for: settings.lastLessonID)
        let targetLesson = HomePadSubtitles.continueTarget(
            lastPlayedLesson: lastLesson,
            introFirstLesson: progression.catalog.introLessons.first,
            pathFirstLesson: progression.catalog.path.first
        )
        let subtitle = HomePadSubtitles.continueLesson(
            lastPlayedLesson: lastLesson,
            language: settings.languagePreference
        )

        return HomePadView(
            title: localizedTitle("Continue"),
            subtitle: subtitle,
            padNumber: 3,
            cellSize: cellSize,
            isHero: false
        ) {
            if let targetLesson {
                onOpenDestination(.continueToLesson(targetLesson))
                onNavigateToLibrary(.lesson(targetLesson))
                AppNavigation.shared.openLibrary(.lesson(targetLesson))
            } else {
                onOpenDestination(.continueToLibrary)
                onNavigateToLibrary(.none)
                AppNavigation.shared.openLibrary(.none)
            }
        }
    }

    private var pad4: some View {
        HomePadView(
            title: localizedTitle("Intro"),
            subtitle: HomePadSubtitles.intro(),
            isLit: introPadShouldPulse,
            padNumber: 4,
            cellSize: cellSize,
            isHero: false
        ) {
            onOpenDestination(.intro)
            onNavigateToLibrary(.intro)
            AppNavigation.shared.openLibrary(.intro)
        }
        .accessibilityFocused($introFocused)
    }

    private var pad5: some View {
        let connectedName: String? = {
            if let selectedID = midi.selectedSourceID {
                return midi.sources.first(where: { $0.id == selectedID })?.name
            }
            return midi.sources.first?.name
        }()
        let subtitle = HomePadSubtitles.controller(
            connectedName: connectedName,
            language: settings.languagePreference
        )

        return HomePadView(
            title: localizedTitle("Controller"),
            subtitle: subtitle,
            padNumber: 5,
            cellSize: cellSize,
            isHero: false
        ) {
            onOpenDestination(.controller)
        }
    }

    private var pad6: some View {
        HomePadView(
            title: localizedTitle("Badges"),
            subtitle: HomePadSubtitles.badges(earned: badgeStore.earnedCount, total: badgeStore.totalCount),
            numericTransitionValue: badgeStore.earnedCount,
            padNumber: 6,
            cellSize: cellSize,
            isHero: false
        ) {
            onOpenDestination(.badges)
        }
    }

    private var pad7: some View {
        let price = store.products[StoreManager.fullID]?.displayPrice
        let subtitle = HomePadSubtitles.fullVersion(
            hasFullAccess: store.hasFullAccess,
            price: price,
            language: settings.languagePreference
        )

        return HomePadView(
            title: localizedTitle("Full version"),
            subtitle: subtitle,
            padNumber: 7,
            cellSize: cellSize,
            isHero: false
        ) {
            onOpenDestination(.purchases)
        }
    }

    private var pad8: some View {
        HomePadView(
            title: localizedTitle("Settings"),
            subtitle: HomePadSubtitles.settings(),
            padNumber: 8,
            cellSize: cellSize,
            isHero: false
        ) {
            onOpenDestination(.settings)
        }
    }

    private var centreLogoPad: some View {
        Button {
            guard animationFinished else { return }
            onOpenDestination(.about)
        } label: {
            ZStack {
                HomeLogoMarkView(size: cellSize, darkAppearance: colorScheme == .dark)
                    .opacity(plateVisible ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.pad)
                    .fill(Theme.surface)
                    .opacity(plateVisible ? 1.0 : 0.0)
            )
            .overlay {
                // Two-tone bevel: top 1.5 pt light highlight, bottom 2 pt darker edge (ticket 112)
                VStack(spacing: 0) {
                    Theme.padBevelTop
                        .frame(height: 1.5)
                    Spacer(minLength: 0)
                    Theme.padBevelBottom
                        .frame(height: 2.0)
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pad))
                .opacity(plateVisible ? 1.0 : 0.0)
                .allowsHitTesting(false)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.pad)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
                    .opacity(plateVisible ? 1.0 : 0.0)
                    .allowsHitTesting(false)
            }
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.pad))
        }
        .buttonStyle(TactilePadButtonStyle())
        .accessibilityLabel(settings.localized("About"))
        .accessibilityAddTraits(.isButton)
        .allowsHitTesting(animationFinished)
    }
}
