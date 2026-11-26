import SwiftUI

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
    @Environment(MIDIInput.self) private var midi
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(TodayPlan.storageKey) private var savedTodayPlan = ""
    @State private var helpPresentation: HelpPresentation?
    @AccessibilityFocusState private var helpFocused: Bool
    @State private var calendarDay = AppCalendar.today()
    @State private var activeDestination: HomePadDestination?
    @Namespace private var homeNamespace

    @State private var lessonStore = LessonStore.shared
    @State private var homeOpacity: Double = 1.0

    // The bezel is already visible when the display powers on.
    @State private var pixelsVisible: Bool
    @State private var displayPowered: Bool
    @State private var plateVisible: Bool
    @State private var padVisible: [Bool]
    @State private var animationFinished: Bool
    @State private var animationTask: Task<Void, Never>?
    @State private var transientStatus: String?
    @State private var statusResetTask: Task<Void, Never>?
    @State private var midiLedBrightness: Double = 0.0
    @State private var ledFadeTask: Task<Void, Never>?
    @State private var homeOwnsAudio = false

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
        _pixelsVisible = State(initialValue: settled)
        _displayPowered = State(initialValue: settled)
        _plateVisible = State(initialValue: settled)
        _padVisible = State(initialValue: Array(repeating: settled, count: 8))
        _animationFinished = State(initialValue: settled)
    }

    public var body: some View {
        GeometryReader { proxy in
            let containerW = proxy.size.width
            let containerH = proxy.size.height
            let layout = HomeControllerLayout(size: proxy.size)
            let gridSize = layout.gridSize

            ZStack {
                // The chassis and unpowered display are visible from the first launch frame.
                Theme.chassis
                    .ignoresSafeArea()

                HomeControllerBody(darkAppearance: colorScheme == .dark)
                    .equatable()

                HomeHardwareDisplay(status: transientStatus ?? controllerDisplayStatus,
                                    accessibilityStatus: controllerDisplayStatus,
                                    pixelsVisible: pixelsVisible, powered: displayPowered)
                    .frame(width: layout.display.width, height: layout.display.height)
                    .position(x: layout.display.midX, y: layout.display.midY)

                // Per-hit MIDI observation lives in this tiny child view, which exists only
                // while Home is idle. HomeScreen stays mounted under the practice cover, so
                // observing every hit here would re-evaluate the whole Home body on each pad
                // hit and stall the practice screen's main thread.
                if homeIsIdle {
                    HomeMidiListener(midi: midi,
                                     onNote: handleIncomingNote,
                                     onControl: handleIncomingControlMessage)
                }

                HomeMidiActivityLed(brightness: midiLedBrightness)
                    .position(x: layout.display.minX - 28, y: layout.display.midY)
                    .opacity(plateVisible ? 1 : 0)
                    .allowsHitTesting(false)

                HomeControllerHardware(layout: layout, darkAppearance: colorScheme == .dark)
                    .equatable()
                    .opacity(plateVisible ? 1 : 0)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: plateVisible)

                HomeControllerFaders(layout: layout, darkAppearance: colorScheme == .dark)
                    .opacity(plateVisible ? 1 : 0)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: plateVisible)
                    .allowsHitTesting(plateVisible && animationFinished)

                HomePadGrid(
                    cellSize: layout.cellSize,
                    gap: layout.gap,
                    plateVisible: plateVisible,
                    padVisible: padVisible,
                    animationFinished: animationFinished,
                    todayPlan: todayPlan,
                    lessonStore: lessonStore,
                    homeNamespace: homeNamespace,
                    onSelectToday: openToday,
                    onOpenDestination: { activeDestination = $0 },
                    onNavigateToLibrary: onNavigateToLibrary
                )
                .frame(width: gridSize, height: gridSize)
                .position(x: layout.plate.midX, y: layout.plate.midY)

                hardwareSettings(layout: layout)
                    .opacity(plateVisible ? 1 : 0)
                    .allowsHitTesting(animationFinished)

                helpButton(containerWidth: containerW, layout: layout)
                    .opacity(plateVisible ? 1 : 0)
                    .allowsHitTesting(animationFinished)
            }
            .frame(width: containerW, height: containerH)
            .opacity(homeOpacity)
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
            await startHomeAudioIfNeeded()
        }
        .onDisappear {
            stopHomeAudio()
        }
        .onChange(of: homeIsIdle) { _, isIdle in
            if isIdle && scenePhase == .active {
                Task { await startHomeAudioIfNeeded() }
            } else {
                stopHomeAudio()
            }
        }
        #if DEBUG
        .debugTestMarker()
        #endif
        .padPresentation(item: $activeDestination, namespace: homeNamespace) { destination in
            let view = HomeDestinationView(
                destination: destination,
                onReviewOpen: preserveTodayPlan(for:),
                onClearDestination: { activeDestination = nil }
            )
            #if DEBUG
            view.debugTestMarker()
            #else
            view
            #endif
        }
        .onChange(of: AppNavigation.shared.route) { _, route in
            syncWithNavigationRoute(route)
        }
        .onAppear {
            syncWithNavigationRoute(AppNavigation.shared.route)
        }
        .onChange(of: activeDestination) { _, destination in
            if destination == nil, AppNavigation.shared.route != .home {
                AppNavigation.shared.openHome()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                calendarDay = AppCalendar.today()
                if homeIsIdle {
                    Task { await startHomeAudioIfNeeded() }
                }
            } else {
                stopHomeAudio()
            }
        }
        .onChange(of: settings.padsVolume) { _, newVolume in
            if homeIsIdle {
                AudioEngine.practice.setPadsVolume(Float(newVolume) / 100)
            }
        }
        .onChange(of: settings.metronomeVolume) { _, newVolume in
            if homeIsIdle {
                AudioEngine.practice.setMetronomeVolume(Float(newVolume) / 100)
            }
        }
        .onChange(of: settings.patternVolume) { _, newVolume in
            if homeIsIdle {
                AudioEngine.practice.setPatternVolume(Float(newVolume) / 100)
            }
        }
        .onChange(of: settings.instrumentTrims) { _, newTrims in
            if homeIsIdle {
                AudioEngine.practice.setInstrumentTrims(newTrims)
            }
        }
        .onChange(of: settings.selectedKitId) { _, _ in
            if homeIsIdle {
                Task { await startHomeAudioIfNeeded() }
            }
        }
        .onChange(of: settings.lastLessonID) { _, _ in
            if homeIsIdle {
                Task { await startHomeAudioIfNeeded() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            calendarDay = AppCalendar.today()
        }
    }

    // MARK: - MIDI Reaction & Audio (Ticket 207)

    private var resolvedHomeKitId: String {
        let candidate: String
        if settings.selectedKitId != SoundKitResolver.automaticKitId {
            candidate = settings.selectedKitId
        } else if let lastLesson = settings.lastLessonID == 0 ? nil : lessonStore.lesson(for: settings.lastLessonID) {
            return SoundKitResolver.resolveKitId(for: lastLesson, settings: settings, pathState: progress.drummerPath)
        } else {
            return SoundKitResolver.fallbackKitId
        }
        if settings.playMode == .story && !progress.drummerPath.isKitUnlocked(candidate) {
            return DrumKitCatalog.starterKitId
        }
        return candidate
    }

    private func startHomeAudioIfNeeded() async {
        guard homeIsIdle, scenePhase == .active else { return }
        let audio = AudioEngine.practice
        do {
            _ = try await audio.prepare()
            let kitId = resolvedHomeKitId
            let kit = try await audio.loadKit(kitId)
            // A lesson may have opened while the kit was loading; never touch its audio.
            guard homeIsIdle, scenePhase == .active else { return }
            audio.selectKit(kit)
            audio.setMetronomeVolume(Float(settings.metronomeVolume) / 100)
            audio.setPadsVolume(Float(settings.padsVolume) / 100)
            audio.setPatternVolume(Float(settings.patternVolume) / 100)
            audio.setInstrumentTrims(settings.instrumentTrims)
            if !audio.isRunning {
                try audio.start()
            }
            midi.setPracticeSound(audio)
            homeOwnsAudio = true
        } catch {
            // Audio engine couldn't start (e.g. system interruption)
        }
    }

    private func stopHomeAudio() {
        if homeOwnsAudio {
            homeOwnsAudio = false
            midi.setPracticeSound(nil)
            AudioEngine.practice.stop()
        }
        statusResetTask?.cancel()
        transientStatus = nil
        ledFadeTask?.cancel()
        midiLedBrightness = 0.0
    }

    private func showTransientStatus(_ status: String) {
        transientStatus = status
        statusResetTask?.cancel()
        statusResetTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1500))
            guard !Task.isCancelled else { return }
            transientStatus = nil
        }
    }

    private func handleIncomingNote(_ event: MIDINoteEvent) {
        // On Home, a hit on the MIDI controller plays audio and updates the display/LED,
        // but never navigates or lights the eight Home tiles. The tiles are menu buttons,
        // and lighting them would look like a selection.
        guard homeIsIdle, scenePhase == .active else { return }
        guard event.isNoteOn && event.velocity > 0 else { return }

        triggerMidiLed(velocity: event.velocity)

        let status = HomeDisplayStatusBuilder.statusText(
            for: event.note,
            channel: event.channel,
            profile: midi.activeProfile,
            padIndices: midi.padIndices,
            controls: settings.midiControls
        )
        showTransientStatus(status)
    }

    private func handleIncomingControlMessage(_ message: MIDIControlMessage) {
        guard homeIsIdle, scenePhase == .active else { return }
        guard message.signal.kind == .cc, message.value > 0 else { return }

        let status = HomeDisplayStatusBuilder.statusText(
            for: message.signal,
            profile: midi.activeProfile,
            padIndices: midi.padIndices,
            controls: settings.midiControls
        )

        if settings.midiControls.buttons.values.contains(where: { $0.signal == message.signal }) {
            showTransientStatus(status)
        }
    }

    private func triggerMidiLed(velocity: Int) {
        let targetBrightness = max(0.2, min(1.0, Double(velocity) / 127.0))
        midiLedBrightness = targetBrightness
        ledFadeTask?.cancel()
        ledFadeTask = Task { @MainActor in
            if reduceMotion {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                midiLedBrightness = 0.0
            } else {
                try? await Task.sleep(for: .milliseconds(50))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.35)) {
                    midiLedBrightness = 0.0
                }
            }
        }
    }

    private var controllerDisplayStatus: String {
        let source = midi.selectedSourceID.flatMap { selected in
            midi.sources.first { $0.id == selected }
        } ?? (midi.selectedSourceID == nil ? midi.sources.first : nil)
        guard let source else { return settings.localized("home.controller.none") }
        return "\(HomePadSubtitles.singleLine(source.name)) · \(settings.localized("home.controller.connected"))"
    }

    @ViewBuilder
    private func hardwareSettings(layout: HomeControllerLayout) -> some View {
        let bayWidth = layout.plate.minX
        let width = layout.landscape ? min(180, max(0, bayWidth - 2 * layout.margin)) : layout.portraitControlWidth
        let leftX = layout.landscape ? bayWidth / 2 : layout.margin + width / 2
        let rightX = layout.size.width - leftX
        let faderUnit = min(layout.unit, max(0, bayWidth - 2 * layout.margin) / 134)
        let centerY = layout.landscape
            ? layout.plate.minY + 217 * faderUnit + Theme.Space.page + 72
            : min(layout.size.height - layout.margin - 72,
                  layout.portraitBayTop + max(72, layout.portraitFaderHeight / 2))
        HomeLanguageKnob()
            .frame(width: width)
            .position(x: leftX, y: centerY)
        HomeAppearanceSwitch()
            .frame(width: width)
            .position(x: rightX, y: centerY)
    }

    private func helpButton(containerWidth: CGFloat, layout: HomeControllerLayout) -> some View {
        VStack(spacing: 4) {
            HardwareIconButton(
                systemName: "questionmark",
                accessibilityLabel: settings.localized("help.title"),
                compact: true
            ) {
                helpPresentation = HelpPresentation(windowWidth: containerWidth)
            }
            .accessibilityFocused($helpFocused)
            .helpDeck(presentation: $helpPresentation, arrowEdge: .top) {
                helpFocused = true
            }

            Text(settings.localized("Help").uppercased(with: Locale(identifier: settings.languagePreference.rawValue)))
                .font(Theme.canvasDisplay(9))
                .tracking(0.5)
                .foregroundStyle(Theme.secondary)
                .accessibilityHidden(true)
        }
        .position(x: layout.display.maxX + (containerWidth - layout.display.maxX) / 2,
                  y: layout.display.midY)
    }

    private var homeIsIdle: Bool {
        AppNavigation.shared.route == .home && activeDestination == nil && helpPresentation == nil
    }

    private func syncWithNavigationRoute(_ route: AppRoute) {
        switch route {
        case .home:
            if activeDestination == .training || activeDestination?.libraryTarget != nil {
                activeDestination = nil
            }
        case .training:
            helpPresentation = nil
            if activeDestination != .training {
                activeDestination = .training
            }
        case .library(let target):
            helpPresentation = nil
            // Keep the originating pad's cover identity when its route is echoed back.
            // Replacing Continue/Intro here dismisses and re-presents a zoom mid-transition.
            if activeDestination?.libraryTarget != target {
                activeDestination = .library(target)
            }
        }
    }

    private var todayPlan: TodayPlan? {
        if let saved = TodayPlan.decode(savedTodayPlan, today: calendarDay) {
            return saved.reconcilingReviews(with: progress.records)
        }
        let isAvailableForToday: (Lesson) -> Bool = { lesson in
            store.isUnlocked(lesson)
        }
        let lessons = progression.dailyLessons(isAvailable: isAvailableForToday)
        let openIDs = Set(progression.catalog.lessons.filter {
            isAvailableForToday($0) && progression.isLessonOpen($0)
        }.map(\.id))
        let padCount = midi.activeProfile.padCount
        let dueCandidates = progress.dueLessonIds(today: calendarDay).compactMap { lessonStore.lesson(for: $0) }.filter { lesson in
            guard openIDs.contains(lesson.id) else { return false }
            return padCount == 16 || EightPadLayout.slots(for: lesson) != nil
        }
        let due = ReviewQueue.order(dueCandidates, records: progress.records, today: calendarDay)
        return TodayPlan.make(day: calendarDay,
            dueLessonIDs: due.map(\.id),
            nextLessonID: lessons.next?.id, followUpLessonID: lessons.followUp?.id)
    }

    private func preserveTodayPlan(for lessonID: Int) {
        guard TodayPlan.decode(savedTodayPlan, today: calendarDay) == nil,
              let plan = todayPlan,
              plan.steps.contains(where: { $0.kind == .review && $0.lessonIDs.first == lessonID }),
              let json = plan.encoded else { return }
        savedTodayPlan = json
    }

    private func openToday() {
        guard activeDestination == nil, helpPresentation == nil else { return }
        TrainingOpenMeasurement.begin()
        activeDestination = .training
        onNavigateToTraining()
        AppNavigation.shared.openTraining()
    }

    // MARK: - Animation Sequence

    private func startAnimation() {
        animationTask?.cancel()
        animationTask = Task { @MainActor in
            if reduceMotion {
                revealAllHardware()
                homeOpacity = 0
                withAnimation(.easeOut(duration: 0.2)) { homeOpacity = 1 }
                finishOnce()
                return
            }

            // 0.00–0.15 s: the unlit matrix appears inside the already visible bezel.
            withAnimation(.easeOut(duration: 0.15)) { pixelsVisible = true }
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            // 0.15–0.45 s: the logo and status line light up.
            withAnimation(.easeOut(duration: 0.3)) { displayPowered = true }
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            // 0.45–0.75 s: the plate and pads finish in their real Home positions.
            withAnimation(.easeOut(duration: 0.3)) {
                plateVisible = true
                padVisible = Array(repeating: true, count: 8)
            }
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            finishOnce()
        }
    }

    private func skipAnimation() {
        guard !animationFinished else { return }
        animationTask?.cancel()
        revealAllHardware()
        homeOpacity = 1
        finishOnce()
    }

    private func revealAllHardware() {
        pixelsVisible = true
        displayPowered = true
        plateVisible = true
        padVisible = Array(repeating: true, count: 8)
    }

    private func finishOnce() {
        guard !animationFinished else { return }
        animationFinished = true
        onColdStartFinished()
    }
}

/// Invisible helper that observes per-hit MIDI state for the Home screen.
/// Keeping this observation out of HomeScreen.body means a pad hit re-evaluates
/// only this empty view, never the whole Home hierarchy.
@MainActor
private struct HomeMidiListener: View {
    let midi: MIDIInput
    let onNote: (MIDINoteEvent) -> Void
    let onControl: (MIDIControlMessage) -> Void

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onChange(of: midi.lastNote?.timestamp) { _, _ in
                if let note = midi.lastNote { onNote(note) }
            }
            .onChange(of: midi.lastControlMessage?.timestamp) { _, _ in
                if let message = midi.lastControlMessage { onControl(message) }
            }
    }
}
