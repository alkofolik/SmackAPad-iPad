import SwiftUI

/// Tactile pad press animation style (scale 0.965 and 1.5 pt down, 60 ms light flash, spring back in 0.18 s).
/// Reduce Motion: darker fill only (0.1 s), no scale or movement.
struct TactilePadButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let policy = Theme.Motion.Policy(reduced: reduceMotion)
        let isPressed = configuration.isPressed

        configuration.label
            .overlay {
                if policy.reduced {
                    if isPressed {
                        RoundedRectangle(cornerRadius: Theme.Radius.pad)
                            .fill(Theme.black.opacity(0.12))
                            .allowsHitTesting(false)
                    }
                } else {
                    RoundedRectangle(cornerRadius: Theme.Radius.pad)
                        .fill(Theme.white)
                        .opacity(isPressed ? 0.38 : 0.0)
                        .animation(Theme.Motion.padFlash, value: isPressed)
                        .allowsHitTesting(false)
                }
            }
            .scaleEffect(policy.scale(isPressed ? 0.965 : 1.0))
            .offset(y: policy.offset(isPressed ? 1.5 : 0))
            .animation(
                policy.reduced ? .easeOut(duration: 0.1) : (isPressed ? .easeOut(duration: 0.06) : Theme.Motion.padPress),
                value: isPressed
            )
    }
}

/// The breathing light bar along the top edge of a lit pad (Training with reviews due, ticket 112).
struct PadLightBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    var body: some View {
        GeometryReader { geo in
            let inset = geo.size.width * 0.22
            VStack(spacing: 0) {
                Capsule()
                    .fill(Theme.orange)
                    .frame(height: 2)
                    .shadow(color: Theme.orange.opacity(0.8), radius: 3)
                    .padding(.horizontal, inset)
                    .padding(.top, 7)
                    .opacity(Theme.Motion.Policy(reduced: reduceMotion).breathingOpacity(animating: breathing))
                Spacer(minLength: 0)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !Theme.Motion.Policy(reduced: reduceMotion).reduced else { return }
            withAnimation(Theme.Motion.ledBreath) {
                breathing = true
            }
        }
        .onChange(of: reduceMotion) { _, isReduced in
            if isReduced {
                breathing = false
            } else {
                withAnimation(Theme.Motion.ledBreath) {
                    breathing = true
                }
            }
        }
    }
}

/// A tactile button pad on the Home screen.
struct HomePadView: View {
    let title: String
    let subtitle: String?
    var secondarySubtitle: String? = nil
    var accessibilityText: String? = nil
    var accessibilityValue: String? = nil
    var isLit: Bool = false
    let isHero: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Space.tight) {
                Spacer(minLength: 0)
                Text(title)
                    .font(isHero ? Theme.strong(26) : Theme.action)
                    .foregroundStyle(isHero ? Theme.black : Theme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(Theme.meta)
                        .foregroundStyle(isHero ? Theme.black.opacity(0.8) : Theme.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(secondarySubtitle != nil ? 1 : 2)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.8)
                }

                if let secondarySubtitle, !secondarySubtitle.isEmpty {
                    Text(secondarySubtitle)
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Space.small)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.pad)
                    .fill(isHero ? Theme.orange : Theme.surface)
                    .shadow(
                        color: isLit ? Theme.orange.opacity(0.4) : (isHero ? Theme.orange.opacity(0.25) : Theme.black.opacity(0.08)),
                        radius: isLit ? 7 : (isHero ? 3 : 2),
                        x: 0,
                        y: isLit ? 0 : (isHero ? 3 : 2)
                    )
            )
            .overlay {
                // Two-tone bevel: top 1.5 pt light highlight, bottom 2 pt darker edge (proposal A)
                VStack(spacing: 0) {
                    (isHero ? Theme.white.opacity(0.42) : Theme.padBevelTop)
                        .frame(height: 1.5)
                    Spacer(minLength: 0)
                    (isHero ? Theme.black.opacity(0.28) : Theme.padBevelBottom)
                        .frame(height: isHero ? 2.5 : 2.0)
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pad))
                .allowsHitTesting(false)
            }
            .overlay {
                // Outline: 2 pt orange for lit state, 1 pt hairline (or black opacity for hero) otherwise
                if isLit {
                    RoundedRectangle(cornerRadius: Theme.Radius.pad)
                        .strokeBorder(Theme.orange, lineWidth: 2)
                        .allowsHitTesting(false)
                } else if isHero {
                    RoundedRectangle(cornerRadius: Theme.Radius.pad)
                        .strokeBorder(Theme.black.opacity(0.12), lineWidth: 1)
                        .allowsHitTesting(false)
                } else {
                    RoundedRectangle(cornerRadius: Theme.Radius.pad)
                        .strokeBorder(Theme.hairline, lineWidth: 1)
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                if isLit {
                    PadLightBar()
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.pad))
        }
        .buttonStyle(TactilePadButtonStyle())
        .accessibilityLabel(accessibilityText ?? defaultAccessibilityText)
        .modifier(AccessibilityValueModifier(value: accessibilityValue))
    }

    private var defaultAccessibilityText: String {
        var parts: [String] = [title]
        if let subtitle, !subtitle.isEmpty {
            parts.append(subtitle)
        }
        if let secondarySubtitle, !secondarySubtitle.isEmpty {
            parts.append(secondarySubtitle)
        }
        return parts.joined(separator: ", ")
    }
}

private struct AccessibilityValueModifier: ViewModifier {
    let value: String?
    @ViewBuilder
    func body(content: Content) -> some View {
        if let value, !value.isEmpty {
            content.accessibilityValue(value)
        } else {
            content
        }
    }
}


/// The centre logo mark (three pads + rotated orange pad at 8°, optically centred).
struct HomeLogoMarkView: View {
    let size: CGFloat
    let darkAppearance: Bool
    var reduceMotion: Bool = false
    var pad1Popped: Bool = true
    var pad2Popped: Bool = true
    var pad3Popped: Bool = true
    var orangeVisible: Bool = true
    var orangeLanded: Bool = true
    var blackBounce: CGFloat = 0

    private static let blackPad = Color(red: 17 / 255.0, green: 17 / 255.0, blue: 17 / 255.0)
    private static let creamPad = Color(red: 242 / 255.0, green: 240 / 255.0, blue: 234 / 255.0)
    private static let orangePad = Color(red: 255 / 255.0, green: 91 / 255.0, blue: 31 / 255.0)

    var body: some View {
        let unit = size / 100.0
        let padDimension = 32.0 * unit
        let cornerRadius = 3.0 * unit
        let neutralPadColor = darkAppearance ? Self.creamPad : Self.blackPad

        ZStack {
            // Three neutral pads
            ZStack {
                // Top-left
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(neutralPadColor)
                    .frame(width: padDimension, height: padDimension)
                    .scaleEffect(reduceMotion ? 1.0 : (pad1Popped ? 1.0 : 0.4))
                    .opacity(reduceMotion ? 1.0 : (pad1Popped ? 1.0 : 0.0))
                    .position(x: 28.4086 * unit, y: 32.5914 * unit)

                // Bottom-left
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(neutralPadColor)
                    .frame(width: padDimension, height: padDimension)
                    .scaleEffect(reduceMotion ? 1.0 : (pad2Popped ? 1.0 : 0.4))
                    .opacity(reduceMotion ? 1.0 : (pad2Popped ? 1.0 : 0.0))
                    .position(x: 28.4086 * unit, y: 72.5914 * unit)

                // Bottom-right
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(neutralPadColor)
                    .frame(width: padDimension, height: padDimension)
                    .scaleEffect(reduceMotion ? 1.0 : (pad3Popped ? 1.0 : 0.4))
                    .opacity(reduceMotion ? 1.0 : (pad3Popped ? 1.0 : 0.0))
                    .position(x: 68.4086 * unit, y: 72.5914 * unit)
            }
            .frame(width: size, height: size)
            .offset(y: reduceMotion ? 0 : blackBounce)

            // Top-right orange smack pad
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Self.orangePad)
                .frame(width: padDimension, height: padDimension)
                .scaleEffect(reduceMotion ? 1.0 : (orangeLanded ? 1.0 : 1.35))
                .rotationEffect(.degrees(reduceMotion ? 8.0 : (orangeLanded ? 8.0 : 0.0)))
                .offset(y: reduceMotion ? 0 : (orangeLanded ? 0 : -36 * unit))
                .opacity(reduceMotion ? 1.0 : (orangeVisible ? 1.0 : 0.0))
                .position(x: 69.9086 * unit, y: 29.0914 * unit)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Smack-a-Pad")
        .accessibilityAddTraits(.isImage)
    }
}

/// The vector wordmark "Smack-a-Pad".
struct HomeWordmarkView: View {
    let width: CGFloat
    let darkAppearance: Bool
    var reduceMotion: Bool = false
    var isVisible: Bool = true

    private static let aspectRatio: CGFloat = 490.455 / 73.8
    private static let blackPad = Color(red: 17 / 255.0, green: 17 / 255.0, blue: 17 / 255.0)
    private static let creamPad = Color(red: 242 / 255.0, green: 240 / 255.0, blue: 234 / 255.0)

    var body: some View {
        Image("LaunchWordmark")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(darkAppearance ? Self.creamPad : Self.blackPad)
            .frame(width: width, height: width / Self.aspectRatio)
            .offset(y: reduceMotion ? 0 : (isVisible ? 0 : 8))
            .opacity(reduceMotion ? 1.0 : (isVisible ? 1.0 : 0.0))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Smack-a-Pad")
    }
}

/// Home screen with a 3×3 pad grid and the Smack-a-Pad logo in the centre cell.
/// On cold start, it plays the brand launch animation settling into the finished grid.
@MainActor
public struct HomeScreen: View {
    let isColdStart: Bool
    let onColdStartFinished: () -> Void
    let onNavigateToLibrary: (LibraryLaunchTarget) -> Void
    let onNavigateToTraining: () -> Void

    @Environment(StoreManager.self) private var store
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(ProgressionManager.self) private var progression
    @Environment(BadgeStore.self) private var badgeStore
    @Environment(MIDIInput.self) private var midi
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("smackapad.training.today") private var savedTodayPlan = ""
    @AppStorage("smackapad.training.dailyMixes") private var dailyMixes = "{}"
    @State private var calendarDay = AppCalendar.today()
    @State private var showingToday = false
    @State private var activeTodayPlan: TodayPlan?

    @State private var lessonStore = LessonStore.shared
    @State private var containerOpacity: Double = 1.0

    // Launch animation sequence states
    @State private var pad1Popped: Bool
    @State private var pad2Popped: Bool
    @State private var pad3Popped: Bool
    @State private var orangeVisible: Bool
    @State private var orangeLanded: Bool
    @State private var blackBounce: CGFloat = 0
    @State private var wordmarkVisible: Bool
    @State private var isSettled: Bool
    @State private var padVisible: [Bool]
    @State private var animationFinished: Bool
    @State private var animationTask: Task<Void, Never>?

    // Sheet / Popover presentation states
    @State private var showingSettings = false
    @State private var showingControllerSetup = false
    @State private var showingPurchases = false
    @State private var showingBadges = false

    private static let cream = Color(red: 242 / 255.0, green: 240 / 255.0, blue: 234 / 255.0)

    public init(
        isColdStart: Bool = false,
        onColdStartFinished: @escaping () -> Void = {},
        onNavigateToLibrary: @escaping (LibraryLaunchTarget) -> Void = { _ in },
        onNavigateToTraining: @escaping () -> Void = {}
    ) {
        self.isColdStart = isColdStart
        self.onColdStartFinished = onColdStartFinished
        self.onNavigateToLibrary = onNavigateToLibrary
        self.onNavigateToTraining = onNavigateToTraining

        let settled = !isColdStart
        _pad1Popped = State(initialValue: settled)
        _pad2Popped = State(initialValue: settled)
        _pad3Popped = State(initialValue: settled)
        _orangeVisible = State(initialValue: settled)
        _orangeLanded = State(initialValue: settled)
        _wordmarkVisible = State(initialValue: settled)
        _isSettled = State(initialValue: settled)
        _padVisible = State(initialValue: Array(repeating: settled, count: 8))
        _animationFinished = State(initialValue: settled)
    }

    public var body: some View {
        GeometryReader { proxy in
            let containerW = proxy.size.width
            let containerH = proxy.size.height
            let shorterSide = min(containerW, containerH)

            let gap = Theme.Space.regular // 16
            let minMargin: CGFloat = 20

            let availableW = max(0, containerW - 2 * minMargin)
            let availableH = max(0, containerH - 2 * minMargin)

            let aspectRatio: CGFloat = 490.455 / 73.8
            let settledWordmarkW = min(availableW * 0.55, 360)
            let settledWordmarkH = settledWordmarkW / aspectRatio
            let wordmarkSpacing: CGFloat = 28

            let maxGridWidth: CGFloat = 680
            let maxCellSize: CGFloat = (maxGridWidth - 2 * gap) / 3

            let availableGridH = max(0, availableH - (settledWordmarkH + wordmarkSpacing))
            let maxCellW = (availableW - 2 * gap) / 3
            let maxCellH = (availableGridH - 2 * gap) / 3
            let cellSize = max(0, floor(min(maxCellW, maxCellH, maxCellSize)))
            let gridSize = 3 * cellSize + 2 * gap

            let totalH = settledWordmarkH + wordmarkSpacing + gridSize
            let layoutTopY = (containerH - totalH) / 2

            let settledWordmarkY = layoutTopY + settledWordmarkH / 2
            let settledGridCenterY = layoutTopY + settledWordmarkH + wordmarkSpacing + gridSize / 2

            // Initial animation geometry (centered on screen)
            let initialLogoSize = shorterSide * 0.28
            let initialWordmarkW = initialLogoSize * 1.12
            let initialWordmarkH = initialWordmarkW / aspectRatio
            let initialSpacing = initialLogoSize * 0.12
            let totalInitialH = initialLogoSize + initialSpacing + initialWordmarkH

            let initialLogoY = containerH / 2 - totalInitialH / 2 + initialLogoSize / 2
            let initialWordmarkY = initialLogoY + initialLogoSize / 2 + initialSpacing + initialWordmarkH / 2

            let darkLogo = isSettled && (colorScheme == .dark)

            ZStack {
                // Background: fades from solid cream to Theme.background during settlement
                Theme.background
                    .ignoresSafeArea()

                Self.cream
                    .ignoresSafeArea()
                    .opacity(isSettled ? 0.0 : 1.0)

                // 3x3 Pad Grid (outer pads)
                gridContent(cellSize: cellSize, gap: gap)
                    .frame(width: gridSize, height: gridSize)
                    .position(x: containerW / 2, y: settledGridCenterY)

                // Centre Logo Mark
                HomeLogoMarkView(
                    size: isSettled ? cellSize : initialLogoSize,
                    darkAppearance: darkLogo,
                    reduceMotion: reduceMotion,
                    pad1Popped: pad1Popped,
                    pad2Popped: pad2Popped,
                    pad3Popped: pad3Popped,
                    orangeVisible: orangeVisible,
                    orangeLanded: orangeLanded,
                    blackBounce: blackBounce
                )
                .position(x: containerW / 2, y: isSettled ? settledGridCenterY : initialLogoY)

                // Wordmark "Smack-a-Pad"
                HomeWordmarkView(
                    width: isSettled ? settledWordmarkW : initialWordmarkW,
                    darkAppearance: darkLogo,
                    reduceMotion: reduceMotion,
                    isVisible: wordmarkVisible
                )
                .position(x: containerW / 2, y: isSettled ? settledWordmarkY : initialWordmarkY)
            }
            .frame(width: containerW, height: containerH)
            .opacity(containerOpacity)
            .contentShape(Rectangle())
            .onTapGesture {
                if !animationFinished {
                    skipAnimation()
                }
            }
        }
        .ignoresSafeArea()
        .task {
            if isColdStart && !animationFinished {
                startAnimation()
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingControllerSetup) {
            NavigationStack {
                ControllerSetupView(showsDoneButton: true)
            }
            .environment(settings)
            .environment(midi)
        }
        .sheet(isPresented: $showingPurchases) {
            PurchaseSheet()
        }
        .sheet(isPresented: $showingBadges) {
            BadgesView()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { calendarDay = AppCalendar.today() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            calendarDay = AppCalendar.today()
        }
        .fullScreenCover(isPresented: $showingToday) {
            if let plan = activeTodayPlan {
                TodaySessionScreen(plan: plan) { showingToday = false }
            }
        }
    }

    // MARK: - 3×3 Grid Content

    @ViewBuilder
    private func gridContent(cellSize: CGFloat, gap: CGFloat) -> some View {
        VStack(spacing: gap) {
            // Row 0: Continue/Start (1) · Library (2) · Training (3)
            HStack(spacing: gap) {
                bootPad(pad1, isVisible: padVisible[0])
                    .frame(width: cellSize, height: cellSize)
                bootPad(pad2, isVisible: padVisible[1])
                    .frame(width: cellSize, height: cellSize)
                bootPad(pad3, isVisible: padVisible[2])
                    .frame(width: cellSize, height: cellSize)
            }
            // Row 1: Intro (4) · [Centre Logo Placeholder] · Controller (5)
            HStack(spacing: gap) {
                bootPad(pad4, isVisible: padVisible[3])
                    .frame(width: cellSize, height: cellSize)
                Color.clear
                    .frame(width: cellSize, height: cellSize)
                    .accessibilityHidden(true)
                bootPad(pad5, isVisible: padVisible[4])
                    .frame(width: cellSize, height: cellSize)
            }
            // Row 2: Badges (6) · Full Version (7) · Settings (8)
            HStack(spacing: gap) {
                bootPad(pad6, isVisible: padVisible[5])
                    .frame(width: cellSize, height: cellSize)
                bootPad(pad7, isVisible: padVisible[6])
                    .frame(width: cellSize, height: cellSize)
                bootPad(pad8, isVisible: padVisible[7])
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

    // MARK: - Pad Definitions

    private var todayPlan: TodayPlan? {
        if let saved = TodayPlan.decode(savedTodayPlan, today: calendarDay) {
            return saved.finished ? nil : saved
        }
        let source = NextLessonSource(rawValue: settings.nextLessonSource) ?? .path
        let next = progression.nextLesson(after: lessonStore.lesson(for: settings.lastLessonID), source: source)
        let openIDs = Set(progression.catalog.lessons.filter {
            store.isUnlocked($0) && progression.isLessonOpen($0)
        }.map(\.id))
        let mix = TrainingMix.dailySelection(lessons: progression.catalog.lessons, progress: progress.records,
            padCount: midi.activeProfile.padCount, openLessonIDs: openIDs, day: calendarDay, savedJSON: dailyMixes)
        return TodayPlan.make(day: calendarDay,
            dueLessonIDs: progress.dueLessonIds(today: calendarDay).filter { lessonStore.lesson(for: $0) != nil },
            nextLessonID: next?.id, mixLessonIDs: mix.map(\.id))
    }

    private func todaySubtitle(_ plan: TodayPlan) -> String {
        let count = plan.reviewCount
        let key: String
        if count == 1 {
            key = plan.hasNewLesson ? "1 review · then new lesson" : "1 review"
            return settings.localized(key)
        }
        key = plan.hasNewLesson ? "%lld reviews · then new lesson" : "%lld reviews"
        return settings.localized(key, count)
    }

    private var pad1: some View {
        if let plan = todayPlan {
            return AnyView(HomePadView(title: settings.localized("Today").uppercased(with: Locale(identifier: settings.languagePreference.rawValue)),
                                      subtitle: todaySubtitle(plan), isHero: true) {
                activeTodayPlan = plan
                // Keep the same Mix visible on Training even if reviews change recency first.
                if let mix = plan.steps.first(where: { $0.kind == .mix }) {
                    var saved = (try? JSONDecoder().decode([String: [Int]].self, from: Data(dailyMixes.utf8))) ?? [:]
                    saved = saved.filter { $0.key.hasPrefix(calendarDay + ":") }
                    saved["\(calendarDay):\(midi.activeProfile.padCount)"] = mix.lessonIDs
                    if let data = try? JSONEncoder().encode(saved), let json = String(data: data, encoding: .utf8) {
                        dailyMixes = json
                    }
                }
                showingToday = true
            })
        }
        let isFirstRun = settings.lastLessonID == 0
        let label = settings.localized(isFirstRun ? "Start" : "Continue").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))

        let targetLesson: Lesson? = {
            if isFirstRun {
                return progression.catalog.introLessons.first ?? progression.catalog.path.first
            }
            let source = NextLessonSource(rawValue: settings.nextLessonSource) ?? .path
            return progression.nextLesson(after: lessonStore.lesson(for: settings.lastLessonID), source: source) ?? progression.catalog.path.first
        }()

        let subtitle: String? = {
            guard let targetLesson else { return nil }
            let title = settings.localized(targetLesson.title)
            let record = progress.progress(for: targetLesson.id)
            let stars = LibraryStarFilter.stars(record)
            if stars > 0 {
                return "\(title) · \(String(repeating: "★", count: stars))"
            }
            return title
        }()

        return AnyView(HomePadView(title: label, subtitle: subtitle, isHero: true) {
            if let targetLesson {
                onNavigateToLibrary(.lesson(targetLesson))
            } else {
                onNavigateToLibrary(.none)
            }
        })
    }

    private var pad2: some View {
        let label = settings.localized("Library").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        let allLessons = progression.catalog.path
        let three = allLessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 3 }.count
        let two = allLessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 2 }.count
        let one = allLessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 1 }.count
        let earnedStars = three * 3 + two * 2 + one
        let maxStars = allLessons.count * 3
        let subtitle = "\(earnedStars) / \(maxStars) ★"

        return HomePadView(title: label, subtitle: subtitle, isHero: false) {
            onNavigateToLibrary(.none)
        }
    }

    private var pad3: some View {
        let label = settings.localized("Training").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        let dueCount = progress.dueLessonsCount(today: calendarDay)
        let subtitle: String? = {
            guard dueCount > 0 else { return nil }
            return settings.localized("%lld due", dueCount)
        }()

        return HomePadView(
            title: label,
            subtitle: subtitle,
            accessibilityText: label,
            accessibilityValue: dueCount > 0 ? settings.localized("%lld due", dueCount) : nil,
            isLit: dueCount > 0,
            isHero: false
        ) {
            onNavigateToTraining()
        }
    }

    private var pad4: some View {
        let label = settings.localized("Intro").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        return HomePadView(title: label, subtitle: nil, isHero: false) {
            onNavigateToLibrary(.intro)
        }
    }

    private var pad5: some View {
        let label = settings.localized("Controller").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        let profileName = settings.activeProfile().profileName

        let inputName: String = {
            if let selectedID = midi.selectedSourceID {
                return midi.sources.first(where: { $0.id == selectedID })?.name ?? settings.localized("Not connected")
            } else if let firstSource = midi.sources.first {
                return firstSource.name
            } else {
                return settings.localized("Not connected")
            }
        }()

        let voiceOverText = "\(label), \(inputName), \(profileName)"

        return HomePadView(
            title: label,
            subtitle: inputName,
            secondarySubtitle: profileName,
            accessibilityText: voiceOverText,
            isHero: false
        ) {
            showingControllerSetup = true
        }
    }

    private var pad6: some View {
        let label = settings.localized("Badges").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        let subtitle = "\(badgeStore.earnedCount) / \(badgeStore.totalCount)"

        return HomePadView(title: label, subtitle: subtitle, isHero: false) {
            showingBadges = true
        }
    }

    private var pad7: some View {
        let label = settings.localized("Full version").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        let subtitle = store.hasFullAccess ? settings.localized("Unlocked") : settings.localized("Unlock")

        return HomePadView(title: label, subtitle: subtitle, isHero: false) {
            showingPurchases = true
        }
    }

    private var pad8: some View {
        let label = settings.localized("Settings").uppercased(with: Locale(identifier: settings.languagePreference.rawValue))
        return HomePadView(title: label, subtitle: nil, isHero: false) {
            showingSettings = true
        }
    }

    // MARK: - Animation Sequence

    private func startAnimation() {
        animationTask?.cancel()
        animationTask = Task { @MainActor in
            let policy = Theme.Motion.Policy(reduced: reduceMotion)
            if policy.reduced {
                skipAnimation()
                containerOpacity = 0.0
                withAnimation(.easeOut(duration: 0.2)) {
                    containerOpacity = 1.0
                }
                return
            }

            containerOpacity = 1.0

            // 0.00–0.45 s: three black pads appear 0.12 s apart
            withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                pad1Popped = true
            }
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }

            withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                pad2Popped = true
            }
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }

            withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                pad3Popped = true
            }
            // Wait until 0.55 s (elapsed: 240 ms -> sleep 310 ms)
            try? await Task.sleep(for: .milliseconds(310))
            guard !Task.isCancelled else { return }

            // 0.55 s: orange pad smacks in
            orangeVisible = true
            withAnimation(.spring(response: 0.28, dampingFraction: 0.54)) {
                orangeLanded = true
            }

            // Impact at ~0.64 s: 2 pt bounce on black pads
            try? await Task.sleep(for: .milliseconds(90))
            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: 0.06)) {
                blackBounce = 2
            }
            try? await Task.sleep(for: .milliseconds(60))
            guard !Task.isCancelled else { return }

            withAnimation(.easeOut(duration: 0.10)) {
                blackBounce = 0
            }

            // Wait until 0.95 s (elapsed: 550 + 90 + 60 + 100 = 800 ms -> sleep 150 ms)
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }

            // 0.95–1.25 s: wordmark fades and rises
            withAnimation(.easeOut(duration: 0.30)) {
                wordmarkVisible = true
            }

            // Hold until 1.50 s (elapsed: 950 + 300 = 1250 ms -> sleep 250 ms)
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }

            // 1.50–2.10 s: Logo scales to centre cell, wordmark moves up, background cross-fades
            withAnimation(.easeInOut(duration: 0.60)) {
                isSettled = true
            }

            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }

            // 2.10–2.80 s: 8 pads appear in a diagonal wave from top-left to bottom-right (ticket 112)
            // Wave 0: Pad 1 (top-left)
            withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                padVisible[0] = true
            }
            try? await Task.sleep(for: Theme.Motion.bootStagger)
            guard !Task.isCancelled else { return }

            // Wave 1: Pad 2 and Pad 4
            withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                padVisible[1] = true
                padVisible[3] = true
            }
            try? await Task.sleep(for: Theme.Motion.bootStagger)
            guard !Task.isCancelled else { return }

            // Wave 2: Pad 3 and Pad 6
            withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                padVisible[2] = true
                padVisible[5] = true
            }
            try? await Task.sleep(for: Theme.Motion.bootStagger)
            guard !Task.isCancelled else { return }

            // Wave 3: Pad 5 and Pad 7
            withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                padVisible[4] = true
                padVisible[6] = true
            }
            try? await Task.sleep(for: Theme.Motion.bootStagger)
            guard !Task.isCancelled else { return }

            // Wave 4: Pad 8 (bottom-right)
            withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                padVisible[7] = true
            }

            // Settle time
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            finishOnce()
        }
    }

    private func skipAnimation() {
        guard !animationFinished else { return }
        animationTask?.cancel()
        withAnimation(.easeOut(duration: 0.15)) {
            pad1Popped = true
            pad2Popped = true
            pad3Popped = true
            orangeVisible = true
            orangeLanded = true
            blackBounce = 0
            wordmarkVisible = true
            isSettled = true
            for i in 0..<8 {
                padVisible[i] = true
            }
        }
        finishOnce()
    }

    private func finishOnce() {
        guard !animationFinished else { return }
        animationFinished = true
        onColdStartFinished()
    }
}
