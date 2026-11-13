import SwiftUI

@MainActor
struct PracticeScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissLesson) private var dismissLesson
    @Environment(\.accessibilityReduceMotion) private var reduced
    private var motion: Theme.Motion.Policy { .init(reduced: reduced) }
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicType
    @Environment(SettingsManager.self) private var settings
    @Environment(MIDIInput.self) private var midi
    @Environment(ProgressStore.self) private var progress
    @Environment(ProgressionManager.self) private var progression
    @Environment(StoreManager.self) private var store
    @State private var session: PracticeSession
    @AppStorage("smackapad.practice.scrolling") private var scrolling = false
    @AppStorage("smackapad.practice.visibleBars") private var visibleBars = 4
    @AppStorage("smackapad.practice.showPads") private var showPads = true
    @AppStorage("smackapad.practice.touchPadsInPortrait") private var touchPadsInPortrait = true
    @AppStorage("smackapad.legend.shownOnce") private var legendShownOnce = false
    @State private var padLayoutModel: PadLayoutModel
    @State private var showingLegend = false
    @State private var showingLoop = false
    @State private var showingTools = false
    @State private var showingTempo = false
    @State private var showingDetails = false
    @State private var showingStarRules = false
    @State private var showingMIDI = false
    @State private var showingInfo = false
    @State private var helpPresentation: HelpPresentation?
    @State private var didOpenHelpOrInfo = false
    @AccessibilityFocusState private var helpFocused: Bool
    @State private var purchaseAccess: String?
    @State private var midLessonStarMomentActive = false
    #if DEBUG
    @State private var debugShowResult = false
    #endif
    private let onStepResult: ((PracticeStepOutcome) -> Void)?

    init(lesson: Lesson, settings: SettingsManager, progress: ProgressStore, midi: MIDIInput,
         initialFromMemory: Bool = false, initialBpm: Int? = nil, mixLessons: [Lesson] = [], initialAfterMe: Bool = false,
         unscored: Bool = false,
         onStepResult: ((PracticeStepOutcome) -> Void)? = nil) {
        self.onStepResult = onStepResult
        _session = State(initialValue: PracticeSession(
            lesson: lesson,
            settings: settings,
            progress: progress,
            midi: midi,
            initialFromMemory: initialFromMemory,
            initialBpm: initialBpm,
            mixLessons: mixLessons,
            initialAfterMe: initialAfterMe,
            unscored: unscored
        ))
        if let initialPads = midi.padIndices {
            let initialPadCount = midi.activeProfile.padCount
            let initialUsed = Set(lesson.hits(forPadCount: initialPadCount).map(\.padIndex))
            _padLayoutModel = State(initialValue: PadLayoutModel(
                pads: initialPads,
                used: initialUsed,
                canShowKeys: midi.activeProfile.isSixteenPad,
                settings: settings
            ))
        } else {
            _padLayoutModel = State(initialValue: PadLayoutModel(
                pads: [],
                used: [],
                canShowKeys: false,
                settings: settings
            ))
        }
    }

    private var focusActive: Bool { session.running && !session.listen }
    private var focusFade: Animation { reduced ? Theme.Motion.fast : Theme.Motion.standard }

    private var activeSummary: RunSummary? {
        #if DEBUG
        return session.summary ?? (debugShowResult ? RunSummary(score: 0.94, bpm: session.lesson.targetBpm, passes: 2, passed: true, mastery: true, memory: false) : nil)
        #else
        return session.summary
        #endif
    }

    private var isShowingResult: Bool {
        activeSummary != nil && !session.running
    }

    private func dismissDebugResult() {
        #if DEBUG
        debugShowResult = false
        #endif
    }

    var body: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.height > geometry.size.width
            let portraitPads = isPortrait && touchPadsInPortrait && midi.padIndices?.count == 16
            let availableWidth = max(0, geometry.size.width - 2 * Theme.Space.page)
            let defaultS: CGFloat = 2 * Theme.Size.control + Theme.Space.small
            let s = min(defaultS, max(80, (availableWidth - 2 * Theme.Space.small) / 3))

            VStack(spacing: Theme.Space.regular) {
                if !focusActive {
                    topZone(isPortrait: isPortrait, width: geometry.size.width, screenHeight: geometry.size.height)
                        .fixedSize(horizontal: false, vertical: true)
                        .zIndex(20)
                        .transition(.opacity)
                }

                if let event = session.badgeBannerEvent {
                    BadgeBanner(event: event) { session.clearBadgeBannerEvent() }
                        .id(event.id)
                }

                middleZone
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomZone(s: s, isPortrait: isPortrait, portraitPads: portraitPads, screenHeight: geometry.size.height, availableWidth: availableWidth)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Theme.Space.page)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .animation(reduced ? nil : Theme.Motion.standard, value: focusActive)
            .calmChassisBackground()
            .foregroundStyle(Theme.ink)
        }
        #if DEBUG
        .debugTestMarker()
        #endif
        .toolbar(.hidden, for: .navigationBar)
        .task(id: ObjectIdentifier(session)) {
            await session.prepare()
            updatePadLayoutModel()
            handleDebugLaunchArguments()
            if session.isMix && !session.unscored && session.mixIndex == 0 && session.mixResults.isEmpty {
                session.start()
            } else if !Task.isCancelled && !session.isMix {
                showFirstLegendIfNeeded()
            }
        }
        .onDisappear {
            session.close()
            reportStepResult()
        }
        .onChange(of: session.runResults) { _, _ in reportStepResult() }
        .onChange(of: session.reviewFeedback) { _, _ in reportStepResult() }
        .onChange(of: scenePhase) { _, phase in
            // An overlay such as Siri can make the scene inactive before audio is interrupted.
            if phase == .active { session.resume() }
            else if phase == .background || !session.running { session.suspend() }
        }
        .onChange(of: session.lesson.id) { _, _ in updatePadLayoutModel() }
        .onChange(of: settings.activeProfileName) { _, _ in
            session.stop()
            updatePadLayoutModel()
        }
        .onChange(of: settings.metronomeVolume) { _, newVolume in session.setMetronomeVolume(newVolume) }
        .onChange(of: settings.padsVolume) { _, newVolume in session.setPadsVolume(newVolume) }
        .onChange(of: settings.patternVolume) { _, newVolume in session.setPatternVolume(newVolume) }
        .onChange(of: settings.instrumentTrims) { _, trims in session.setInstrumentTrims(trims) }
        .onChange(of: session.running) { _, running in
            if running {
                showingInfo = false
                showingLegend = false
                showingLoop = false
                showingTools = false
                showingStarRules = false
                showingDetails = false
                showingTempo = false
            }
        }
        .onChange(of: showingMIDI) { _, showing in
            if showing { session.suspend() }
        }
        .onChange(of: session.starEvent?.id) { _, id in
            guard let event = session.starEvent, id != nil else { return }
            if !event.award.shouldStop {
                let starNumber = (event.award.fresh.firstIndex(of: true) ?? 0) + 1
                UIAccessibility.post(
                    notification: .announcement,
                    argument: settings.localized("Star %lld earned", starNumber)
                )
                midLessonStarMomentActive = true
                Task {
                    try? await Task.sleep(for: .milliseconds(700))
                    midLessonStarMomentActive = false
                }
            }
        }
        .sheet(isPresented: Binding(get: { purchaseAccess != nil }, set: { if !$0 { purchaseAccess = nil } })) {
            PurchaseSheet(access: purchaseAccess ?? "full")
        }
        .sheet(isPresented: $showingMIDI, onDismiss: { session.resume() }) {
            MIDISettingsView()
                .presentationDragIndicator(.visible)
        }
    }

    private func handleDebugLaunchArguments() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-light") {
            settings.appearance = .light
        } else if args.contains("-dark") {
            settings.appearance = .dark
        }
        if args.contains("-landscape") {
            if let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
            }
        } else if args.contains("-portrait") {
            if let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }
        if args.contains("-mode-listen") {
            session.selectPlaybackMode(.listen)
        } else if args.contains("-mode-afterme") {
            session.selectPlaybackMode(.afterMe)
        }
        if args.contains("-with-result") {
            debugShowResult = true
        }
        #endif
    }

    private var touchPadsReady: Bool {
        session.ready && session.available && scenePhase == .active && !showingMIDI
            && midi.lesson?.id == session.lesson.id && midi.padIndices?.count == 16
    }

    private func reportStepResult() {
        guard let outcome = session.todayStepOutcome else { return }
        onStepResult?(outcome)
    }

    private func topZone(isPortrait: Bool, width: CGFloat, screenHeight: CGFloat) -> some View {
        let stacked = isPortrait || width < 960 || dynamicType.isAccessibilitySize

        return Group {
            if stacked {
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    let headerLayout = width < 380 || dynamicType.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Space.small))
                        : AnyLayout(HStackLayout(alignment: .center, spacing: 20))
                    headerLayout {
                        libraryButton
                        titleAndSubtitle
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .zIndex(1)

                    FlowLayout(spacing: 20) {
                        modeGroup
                        patternGroup
                        infoGroup(windowWidth: width, screenHeight: screenHeight)
                        settingsButton
                    }
                }
            } else {
                HStack(alignment: .center, spacing: 20) {
                    libraryButton
                    titleAndSubtitle
                    modeGroup
                    patternGroup
                    infoGroup(windowWidth: width, screenHeight: screenHeight)
                    settingsButton
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var libraryButton: some View {
        BackButton {
            session.stop()
            reportStepResult()
            if let dismissLesson { dismissLesson() } else { dismiss() }
        }
        .practiceToolbarHint(settings.localized("Back"))
    }

    private var titleAndSubtitle: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(settings.localized(session.lesson.title))
                .font(Theme.strong(22))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            lessonSubtitle
        }
        .frame(minWidth: 160, maxWidth: .infinity, alignment: .leading)
        .layoutPriority(1)
    }

    private var headerStars: some View {
        let earned = [
            session.savedProgress?.passed ?? false,
            session.savedProgress?.mastery ?? false,
            session.savedProgress?.memory ?? false
        ]
        return HStack(spacing: 2) {
            ForEach(earned.indices, id: \.self) { index in
                Image(systemName: earned[index] ? "star.fill" : "star")
                    .font(.system(size: 14, weight: .regular))
                    .frame(width: 16, height: 16)
                    .foregroundStyle(earned[index] ? Theme.orange : Theme.secondary)
            }
        }
    }

    @ViewBuilder
    private var lessonSubtitle: some View {
        if let message = session.errorMessage {
            Text(message)
                .font(Theme.display(14))
                .foregroundStyle(Theme.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            let barText = localizedBarCount(session.lesson.bars)
            let earnedCount = [
                session.savedProgress?.passed == true,
                session.savedProgress?.mastery == true,
                session.savedProgress?.memory == true
            ].filter { $0 }.count

            HStack(spacing: 8) {
                if !session.isMix {
                    headerStars
                }
                Text(barText)
                    .font(Theme.display(14))
                    .foregroundStyle(Theme.secondary)
            }
            .lineLimit(1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                session.isMix
                    ? barText
                    : "\(settings.localized("%lld of 3 stars", earnedCount)), \(barText)"
            )
        }
    }

    private func localizedBarCount(_ bars: Int) -> String {
        settings.localizedBarCount(bars)
    }

    private var modeGroup: some View {
        HStack(spacing: 4) {
            PracticeIconButton(
                symbol: "ear",
                title: settings.localized("Listen"),
                appearance: .segmented,
                selected: session.playbackMode == .listen,
                disabled: session.running || session.isMix
            ) {
                session.selectPlaybackMode(.listen)
            }

            PracticeIconButton(
                icon: .crossedSticks,
                title: settings.localized("Play"),
                appearance: .segmented,
                selected: session.playbackMode == .play,
                disabled: session.running || (session.isMix && session.playbackMode != .play)
            ) {
                session.selectPlaybackMode(.play)
            }

            if !session.isMix {
                PracticeIconButton(
                    symbol: "bubble.left.and.bubble.right",
                    title: settings.localized("After me"),
                    appearance: .segmented,
                    selected: session.playbackMode == .afterMe,
                    disabled: session.running
                ) {
                    session.selectPlaybackMode(.afterMe)
                }
            }

            Rectangle()
                .fill(Theme.ink.opacity(0.2))
                .frame(width: 1, height: 32)
                .padding(.horizontal, 2)
                .accessibilityHidden(true)

            PracticeIconButton(
                symbol: "brain.head.profile",
                title: settings.localized("From memory"),
                appearance: .segmented,
                selected: session.fromMemory && !session.afterMe,
                disabled: session.running || session.isMix || session.afterMe,
                accessibilityValue: settings.localized(session.fromMemory ? "On" : "Off")
            ) {
                session.fromMemory.toggle()
            }
        }
        .padding(4)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(settings.localized("Lesson mode"))
    }

    private var patternGroup: some View {
        let maxSelectableBars = max(1, min(session.lesson.bars, 4))
        let effectiveBars = min(max(1, visibleBars), maxSelectableBars)

        return HStack(spacing: 4) {
            PracticeIconButton(
                symbol: "arrow.right.to.line",
                title: settings.localized(scrolling ? "Scrolling view" : "Static view"),
                appearance: .segmented,
                selected: scrolling,
                accessibilityValue: settings.localized(scrolling ? "Scrolling view" : "Static view")
            ) {
                scrolling.toggle()
            }

            PracticeIconButton(
                symbol: "rectangle.split.2x1",
                title: settings.localized("Bars shown"),
                appearance: .segmented,
                width: 56,
                count: effectiveBars,
                selected: false,
                accessibilityValue: staticViewAccessibilityValue(effectiveBars),
                accessibilityHint: maxSelectableBars > 1 ? settings.localized("Tap again to show more bars") : nil
            ) {
                handleStaticViewTap()
            }

            if !session.isMix {
                PracticeIconButton(
                    symbol: "repeat",
                    title: settings.localized("Section loop"),
                    appearance: .segmented,
                    selected: session.isSectionLoop || showingLoop,
                    disabled: session.running || session.lesson.bars <= 1,
                    accessibilityValue: session.isSectionLoop
                        ? "\(session.loopStartBar + 1)–\(session.loopEndBar + 1)"
                        : settings.localized("All bars")
                ) {
                    closeToolbarPopovers(except: .loop)
                    showingLoop.toggle()
                }
                .popover(isPresented: $showingLoop, arrowEdge: .top) { barLoopPopover }
            }
        }
        .padding(4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Theme.ink, lineWidth: 1.5)
        )
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(settings.localized("Pattern view"))
    }

    private func infoGroup(windowWidth: CGFloat, screenHeight: CGFloat) -> some View {
        HStack(spacing: 8) {
            PracticeIconButton(
                symbol: "info.circle",
                title: settings.localized("Lesson info"),
                appearance: .outline,
                selected: showingInfo,
                disabled: session.running
            ) {
                didOpenHelpOrInfo = true
                closeToolbarPopovers(except: .info)
                showingInfo.toggle()
            }
            .popover(isPresented: $showingInfo, arrowEdge: .top) { lessonInfo(screenHeight: screenHeight) }

            PracticeIconButton(
                icon: .padLegend,
                title: settings.localized("Pad legend"),
                appearance: .outline,
                selected: showingLegend,
                disabled: session.running || session.countdown != nil
            ) {
                closeToolbarPopovers(except: .legend)
                showingLegend.toggle()
            }
            .popover(isPresented: $showingLegend, arrowEdge: .top) {
                legend(screenHeight: screenHeight).onAppear {
                    if showingLegend && helpPresentation == nil && !showingInfo
                        && !session.running && session.countdown == nil && !session.patternHits.isEmpty {
                        legendShownOnce = true
                    }
                }
            }

            PracticeIconButton(
                symbol: "questionmark.circle",
                title: settings.localized("help.title"),
                appearance: .outline,
                selected: helpPresentation != nil
            ) {
                didOpenHelpOrInfo = true
                closeToolbarPopovers()
                showingTempo = false
                showingDetails = false
                showingStarRules = false
                helpPresentation = HelpPresentation(windowWidth: windowWidth)
            }
            .accessibilityFocused($helpFocused)
            .helpDeck(presentation: $helpPresentation, initialTopic: .lesson) { helpFocused = true }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var settingsButton: some View {
        PracticeIconButton(
            symbol: "switch.2",
            title: settings.localized("Settings"),
            appearance: .solidDark,
            selected: showingTools
        ) {
            closeToolbarPopovers(except: .tools)
            showingTools.toggle()
        }
        .popover(isPresented: $showingTools, arrowEdge: .top) {
            PracticeTools(session: session, showPads: $showPads, openMIDI: {
                showingTools = false; showingMIDI = true
            })
        }
    }

    private enum ToolbarPopover { case info, legend, loop, tools }

    private func closeToolbarPopovers(except kept: ToolbarPopover? = nil) {
        if kept != .info { showingInfo = false }
        if kept != .legend { showingLegend = false }
        if kept != .loop { showingLoop = false }
        if kept != .tools { showingTools = false }
    }

    private var barLoopPopover: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            Text(settings.localized("Bar loop"))
                .font(Theme.strong(18))

            HStack(spacing: Theme.Space.regular) {
                Text(settings.localized("First bar"))
                    .font(Theme.control)
                Spacer()
                Picker(settings.localized("First bar"), selection: $session.loopStartBar) {
                    ForEach(0..<session.lesson.bars, id: \.self) { bar in
                        Text("\(bar + 1)").tag(bar)
                    }
                }
                .labelsHidden()
            }

            HStack(spacing: Theme.Space.regular) {
                Text(settings.localized("Last bar"))
                    .font(Theme.control)
                Spacer()
                Picker(settings.localized("Last bar"), selection: $session.loopEndBar) {
                    ForEach(session.loopStartBar..<session.lesson.bars, id: \.self) { bar in
                        Text("\(bar + 1)").tag(bar)
                    }
                }
                .labelsHidden()
            }

            if session.isSectionLoop {
                Button(settings.localized("All bars")) {
                    session.loopStartBar = 0
                    session.loopEndBar = max(0, session.lesson.bars - 1)
                }
                .font(Theme.control)
                .buttonStyle(PadSecondaryButtonStyle())
            }

            Text(settings.localized("Section loops do not earn lesson stars."))
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Space.page)
        .frame(width: 280)
        .foregroundStyle(Theme.ink)
        .background(Theme.background)
        .tint(Theme.ink)
        .disabled(session.running || session.isMix)
        .presentationCompactAdaptation(.popover)
    }

    private func handleStaticViewTap() {
        if scrolling {
            scrolling = false
            return
        }
        let maxBars = min(session.lesson.bars, 4)
        guard maxBars > 1 else { return }
        let current = min(max(1, visibleBars), maxBars)
        visibleBars = current >= maxBars ? 1 : current + 1
    }

    private func staticViewAccessibilityValue(_ bars: Int) -> String {
        if bars == 1 {
            return settings.localized("%lld bar shown", 1)
        }
        return settings.localized("%lld bars shown", bars)
    }

    private var middleZone: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !session.running)) { timeline in
            let frame = session.patternFrame(at: timeline.date)
            let scored = focusActive && frame.countdown == nil
                && (!session.afterMe || frame.pass.isMultiple(of: 2))
            let showingResult = isShowingResult
            let passLineReserve: CGFloat = session.running ? 24 : 0
            let showMixHeader = session.isMix && !focusActive && !showingResult
            let mixHeaderReserve: CGFloat = showMixHeader ? 40 : 0

            VStack(spacing: Theme.Space.small) {
                if focusActive || session.listen {
                    practiceHUD(frame: frame, date: timeline.date, scored: scored)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }

                if session.afterMe && focusActive {
                    Text(settings.localized(session.afterMePhase(at: frame)))
                        .font(Theme.rowTitle)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .allowsHitTesting(false)
                }

                GeometryReader { geometry in
                    let rows = Set(session.patternHits.map(\.padIndex)).count
                    let bandAvailableHeight = max(0, geometry.size.height - passLineReserve - mixHeaderReserve)
                    let bandHeight = min(bandAvailableHeight,
                        PracticeBandStyle.bandHeight(rows: rows, availableHeight: bandAvailableHeight))

                    VStack(spacing: Theme.Space.controlGap) {
                        if showMixHeader {
                            mixStatusHeader
                        }

                        practiceBand(frame: frame, scored: scored)
                            .frame(height: bandHeight)
                            .opacity(showingResult ? 0.55 : 1)
                            .animation(focusFade, value: showingResult)

                        if session.running {
                            PassProgressBar(
                                pass: frame.pass,
                                position: frame.position,
                                bars: session.practiceLesson.bars,
                                active: session.running && frame.countdown == nil,
                                date: timeline.date
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    private func practiceHUD(frame: PatternFrame, date: Date, scored: Bool) -> some View {
        VStack(spacing: Theme.Space.small) {
            ZStack {
                tempoUpBanner

                HStack(alignment: .center) {
                    hudTempo(bpm: frame.bpm)
                    Spacer(minLength: 0)
                    runMeter(frame: frame, scored: scored)
                }
            }
            .frame(maxWidth: .infinity)

            HStack {
                Spacer(minLength: 0)
                TimingCue(offset: scored ? session.timingHistory.cueOffset(at: date) : 0, active: scored)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private func hudTempo(bpm: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(bpm)")
                .font(Theme.display(28).bold())
                .monospacedDigit()
            Text("BPM").font(Theme.meta)
        }
        .fixedSize()
        .accessibilityElement(children: .combine)
        .opacity(focusActive ? 1 : 0)
        .accessibilityHidden(!focusActive)
        .animation(focusFade, value: focusActive)
    }

    @ViewBuilder
    private func runMeter(frame: PatternFrame, scored: Bool) -> some View {
        if focusActive {
            PracticeProgressMeter(
                showWarmUps: session.showsMemoryFadePhase,
                completedWarmUps: session.completedWarmUps,
                starProgress: session.starRunProgress,
                reviewProgress: session.reviewRunProgress,
                fraction: scored ? session.runMeterFraction(at: frame) : 0,
                verdict: session.lastVerdict,
                starMomentActive: midLessonStarMomentActive,
                currentAccuracy: session.currentRunAccuracy
            )
        }
    }

    @ViewBuilder
    private var tempoUpBanner: some View {
        if focusActive, session.countdown == nil, let event = session.tempoUpEvent {
            TempoUpBanner(event: event,
                          announcement: settings.localized("Tempo %lld", event.to))
                .id(event.id)
        }
    }

    @ViewBuilder
    private var mixStatusHeader: some View {
        HStack(spacing: Theme.Space.small) {
            if let prev = session.previousMixResult {
                previousMixResultChip(index: prev.index, result: prev.result)
            }
            Spacer(minLength: Theme.Space.small)
            mixProgressChip
                .layoutPriority(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func previousMixResultChip(index: Int, result: MixLessonResult) -> some View {
        let iconName: String
        let iconColor: Color
        if result.score == nil {
            iconName = "forward.end"
            iconColor = Theme.secondary
        } else if result.met {
            iconName = "checkmark"
            iconColor = Theme.orange
        } else if !result.counted {
            iconName = "exclamationmark.circle"
            iconColor = Theme.orange
        } else {
            iconName = "xmark"
            iconColor = Theme.ink
        }

        let labelText: String
        if let score = result.score {
            labelText = settings.localized("%lld · %@ · %lld %%", index + 1, settings.localized(result.title), Int(score.rounded()))
        } else {
            labelText = settings.localized("%lld · %@ · %@", index + 1, settings.localized(result.title), settings.localized("Skipped"))
        }

        return HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(iconColor)
            Text(labelText)
                .font(Theme.display(13).weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Theme.white, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
    }

    private var mixProgressChip: some View {
        HStack(spacing: 10) {
            Text(settings.localized("MIX %lld / %lld", session.mixIndex + 1, session.mixLessons.count))
                .font(Theme.strong(12).monospacedDigit())
                .foregroundStyle(Theme.white)
                .lineLimit(1)

            HStack(spacing: 4) {
                ForEach(session.mixLessons.indices, id: \.self) { index in
                    let fill: Color = if index < session.mixIndex {
                        Theme.white
                    } else if index == session.mixIndex {
                        Theme.orange
                    } else {
                        Theme.white.opacity(0.28)
                    }
                    Capsule()
                        .fill(fill)
                        .frame(width: 20, height: 5)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Theme.black, in: Capsule())
    }

    private func practiceBand(frame: PatternFrame, scored: Bool) -> some View {
        PatternField(lesson: session.practiceLesson, hits: session.patternHits,
                     position: frame.position, tapePosition: frame.tapePosition,
                     running: session.running && frame.countdown == nil,
                     visibility: session.noteVisibility(at: frame),
                     fromMemory: session.fromMemory && !session.afterMe,
                     afterMe: session.afterMe,
                     scrolling: scrolling, visibleBars: [1, 2, 3, 4].contains(visibleBars) ? visibleBars : 4,
                     verdicts: session.barVerdicts,
                     judgments: session.hitJudgments, bpm: frame.bpm,
                     playedHits: session.playedHits, pass: frame.pass,
                     scoring: scored,
                     missGraceSteps: frame.missGraceSteps, countdown: frame.countdown,
                     band: BandTone.color(listen: session.listen,
                                          memory: session.fromMemory && !session.listen && !session.afterMe,
                                          bpm: session.bpm, startBpm: session.lesson.startBpm,
                                          targetBpm: session.lesson.targetBpm),
                     runBars: session.repeatsPerRun * session.practiceLesson.bars,
                     starMomentBeamActive: midLessonStarMomentActive)
            .frame(maxWidth: .infinity)
    }

    private func bottomZone(s: CGFloat, isPortrait: Bool, portraitPads: Bool, screenHeight: CGFloat, availableWidth: CGFloat) -> some View {
        let padsHeight: CGFloat = (portraitPads && midi.padIndices != nil) ? {
            let availableForPads = max(260, screenHeight - 48 - 110 - s - 280)
            return min(520, max(280, min((screenHeight - 48) * 0.44, availableForPads)))
        }() : 0

        let spaceAbove = padsHeight > 0
            ? (screenHeight - Theme.Space.page - padsHeight - Theme.Space.regular - s)
            : (screenHeight - Theme.Space.page - s)

        return VStack(spacing: Theme.Space.regular) {
            bottomZoneRow(s: s, isPortrait: isPortrait, availableWidth: availableWidth, spaceAbove: spaceAbove)

            if portraitPads, let pads = midi.padIndices {
                PracticeTouchPadGrid(pads: pads,
                                     used: Set(session.patternHits.map(\.padIndex)),
                                     flashes: session.padFlashes,
                                     enabled: touchPadsReady) { pad, pressed in
                    guard !pressed || touchPadsReady else { return }
                    midi.touch(padIndex: pad, isPressed: pressed)
                }
                .id(session.lesson.id)
                .frame(maxWidth: .infinity)
                .frame(height: padsHeight)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func bottomZoneRow(s: CGFloat, isPortrait: Bool, availableWidth: CGFloat, spaceAbove: CGFloat) -> some View {
        let showingResult = isShowingResult
        let transportWidth = min(200, max(s, 176))
        let resultGap = Theme.Space.regular
        let stackedResult = isPortrait || availableWidth < 840
        let cardWidth = stackedResult
            ? availableWidth
            : max(0, availableWidth - transportWidth - resultGap)
        let cardHeight: CGFloat = 168

        return Group {
            if showingResult, let summary = activeSummary {
                let resultView: AnyView = if session.isMix {
                    AnyView(mixResultsCard(summary: summary, minHeight: cardHeight, spaceAbove: spaceAbove))
                } else {
                    AnyView(
                        ResultCard(
                            summary: summary,
                            runs: session.runResults,
                            saved: session.savedProgress,
                            event: session.starEvent,
                            announcement: resultAnnouncement,
                            reviewFeedback: session.isMix || session.afterMe ? nil : session.reviewFeedback,
                            isDueReview: session.isDueReview && !session.isSectionLoop,
                            reviewPendingReason: session.reviewPendingReason,
                            badgeCount: session.earnedBadgesInRun.count,
                            isAfterMe: session.afterMe,
                            isSectionLoop: session.isSectionLoop,
                            bestResponseScore: session.bestResponseScore,
                            cardWidth: cardWidth,
                            openRules: {
                                showingDetails = false
                                showingTempo = false
                                showingStarRules = true
                            },
                            openSessionResults: {
                                showingStarRules = false
                                showingTempo = false
                                showingDetails = true
                            },
                            starRulesAttachment: AnyView(
                                Color.clear
                                    .adaptivePopoverOrSheet(
                                        isPresented: $showingStarRules,
                                        asSheet: spaceAbove < 415,
                                        arrowEdge: .bottom
                                    ) {
                                        starRules
                                    }
                            )
                        )
                        .adaptivePopoverOrSheet(
                            isPresented: $showingDetails,
                            asSheet: spaceAbove < 650,
                            arrowEdge: .bottom
                        ) {
                            sessionResultsView(summary)
                        }
                    )
                }

                if stackedResult {
                    VStack(spacing: Theme.Space.controlGap) {
                        resultView
                            .frame(maxWidth: .infinity)
                        transportSquare(
                            s: s,
                            resultSize: nil,
                            horizontalResultButtons: true
                        )
                    }
                } else {
                    HStack(alignment: .center, spacing: resultGap) {
                        resultView
                            .frame(width: cardWidth)
                        transportSquare(
                            s: s,
                            resultSize: CGSize(width: transportWidth, height: cardHeight),
                            horizontalResultButtons: false
                        )
                    }
                }
            } else {
                HStack(spacing: 0) {
                    padLayoutSquare(s: s)
                    Spacer(minLength: 0)
                    tempoSquare(s: s, spaceAbove: spaceAbove)
                        .opacity(focusActive ? 0 : 1)
                        .allowsHitTesting(!focusActive)
                        .accessibilityHidden(focusActive)
                        .animation(focusFade, value: focusActive)
                    Spacer(minLength: 0)
                    transportSquare(s: s, resultSize: nil, horizontalResultButtons: false)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func mixResultsCard(summary: RunSummary, minHeight: CGFloat, spaceAbove: CGFloat) -> some View {
        HStack(alignment: .center, spacing: Theme.Space.regular) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    if session.isMixFullyMet {
                        HStack(spacing: Theme.Space.small) {
                            if let starEvent = session.starEvent {
                                StarBurst(
                                    earned: starEvent.award.earned,
                                    event: starEvent,
                                    announcement: resultAnnouncement,
                                    size: 20
                                )
                            } else {
                                Image(systemName: "checkmark")
                                    .font(Theme.control)
                                    .foregroundStyle(Theme.orange)
                                Text(settings.localized("Done"))
                                    .font(Theme.control)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.bottom, Theme.Space.tight)
                    }

                    ForEach(session.mixResults) { result in
                        VStack(alignment: .leading, spacing: Theme.Space.tight) {
                            HStack(alignment: .center, spacing: Theme.Space.small) {
                                if result.score != nil {
                                    if result.met {
                                        Image(systemName: "checkmark")
                                            .font(Theme.meta)
                                            .foregroundStyle(Theme.orange)
                                            .accessibilityLabel(settings.localized("Passed"))
                                    } else if !result.counted {
                                        Image(systemName: "exclamationmark.circle")
                                            .font(Theme.meta)
                                            .foregroundStyle(Theme.orange)
                                            .accessibilityLabel(settings.localized("Did not count"))
                                    } else {
                                        Image(systemName: "xmark")
                                            .font(Theme.meta)
                                            .foregroundStyle(Theme.markWrong)
                                            .accessibilityLabel(settings.localized("not passed"))
                                    }
                                }
                                Text(settings.localized(result.title))
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                                if result.score != nil {
                                    StarBurst(
                                        earned: result.earnedStars,
                                        event: result.starEvent,
                                        announcement: result.starEvent.map { starAnnouncement(for: $0) } ?? "",
                                        size: 11
                                    )
                                }
                                Text(result.score.map { "\(Int(($0 * 100).rounded()))\u{00a0}%" } ?? "—")
                                    .monospacedDigit()
                            }
                            Text(mixBarSummary(result))
                                .foregroundStyle(Theme.white.opacity(0.68))
                                .fixedSize(horizontal: false, vertical: true)
                            if let review = result.reviewFeedback?.message(language: settings.languagePreference)
                                ?? session.reviewStatusText(for: result.id, settings: settings) {
                                Text(review)
                                    .foregroundStyle(Theme.white.opacity(0.68))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .font(Theme.meta)
                    }
                }
            }

            if !session.runResults.isEmpty {
                ResultDetailButton {
                    showingStarRules = false
                    showingTempo = false
                    showingDetails = true
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
        .foregroundStyle(Theme.white)
        .frame(maxWidth: .infinity, minHeight: minHeight, maxHeight: minHeight, alignment: .leading)
        .background(Theme.black, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .adaptivePopoverOrSheet(
            isPresented: $showingDetails,
            asSheet: spaceAbove < 650,
            arrowEdge: .bottom
        ) {
            sessionResultsView(summary)
        }
        .accessibilityLabel(settings.localized("Mix results"))
    }

    private func mixBarSummary(_ result: MixLessonResult) -> String {
        var parts = ["clean", "ahead", "behind", "uneven"].compactMap { verdict -> String? in
            guard let count = result.barCounts[verdict], count > 0 else { return nil }
            return "\(count) \(settings.localized(verdict))"
        }
        if result.unmeasuredBars > 0 {
            parts.append(settings.localized("%lld not measured", result.unmeasuredBars))
        }
        return settings.localized("Bars: %@", parts.joined(separator: " · "))
    }

    private func updatePadLayoutModel() {
        guard let pads = midi.padIndices else {
            padLayoutModel = PadLayoutModel(pads: [], used: [], canShowKeys: false, settings: settings)
            return
        }
        let used = Set(session.patternHits.map(\.padIndex))
        padLayoutModel = PadLayoutModel(
            pads: pads,
            used: used,
            canShowKeys: midi.activeProfile.isSixteenPad,
            settings: settings
        )
    }

    private func padLayoutSquare(s: CGFloat) -> some View {
        PracticePadLayoutSquare(
            side: s,
            model: padLayoutModel,
            flashes: session.padFlashes,
            showPads: showPads
        )
        .id(session.lesson.id)
    }

    private func tempoSquare(s: CGFloat, spaceAbove: CGFloat) -> some View {
        let editable = !session.running && session.ready && session.available
        return Button {
            showingDetails = false
            showingStarRules = false
            showingTempo.toggle()
        } label: {
            ZStack {
                if !session.available {
                    Text(settings.localized("This lesson requires 16 pads."))
                        .font(Theme.meta)
                        .multilineTextAlignment(.center)
                        .padding(Theme.Space.small)
                } else if !session.ready {
                    Text(settings.localized("Preparing sound…"))
                        .font(Theme.meta)
                        .multilineTextAlignment(.center)
                        .padding(Theme.Space.small)
                } else {
                    VStack(spacing: 2) {
                        Text("\(session.bpm)")
                            .font(Theme.display(min(56, s * 0.36)))
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .contentTransition(motion.numeric)
                            .motion(value: session.bpm)
                        Text("BPM")
                            .font(Theme.meta)
                        Text("→ \(session.lesson.targetBpm)")
                            .font(Theme.meta)
                            .monospacedDigit()
                            .foregroundStyle(Theme.Skin.Display.secondary)
                    }
                    .opacity(editable ? 1 : 0.6)
                }
            }
            .frame(width: s, height: s)
            .insetDisplay()
            .contentShape(RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius))
        }
        .buttonStyle(.plain)
        .disabled(!editable)
        .adaptivePopoverOrSheet(
            isPresented: $showingTempo,
            asSheet: spaceAbove < 285,
            arrowEdge: .bottom
        ) {
            tempoControls
                .padding(Theme.Space.page)
                .background(Theme.background)
                .presentationDetents([.height(300), .medium])
        }
        .accessibilityLabel(settings.localized("Tempo %lld BPM, goal %lld", session.bpm, session.lesson.targetBpm))
    }

    private func transportSquare(
        s: CGFloat,
        resultSize: CGSize?,
        horizontalResultButtons: Bool
    ) -> some View {
        let showingResult = isShowingResult
        let target = ResultNextTarget.resolve(
            isStepResult: onStepResult != nil,
            isMix: session.isMix,
            afterMe: session.afterMe,
            finishedByReview: session.finishedByReview,
            isDueReview: session.isDueReview,
            reviewFeedback: session.reviewFeedback,
            lessonPassed: session.savedProgress?.passed == true,
            nextDueReview: nextDueReviewLesson,
            nextPathLesson: nextLesson
        )

        var nextEnabled = false
        var nextLocked = false
        var nextHint: String?
        var nextAction: (() -> Void)?

        switch target {
        case .stepResult:
            nextEnabled = true
            nextAction = {
                dismissDebugResult()
                session.stop()
                reportStepResult()
                if let dismissLesson { dismissLesson() } else { dismiss() }
            }
        case .lesson(let next):
            nextEnabled = true
            nextLocked = !store.isUnlocked(next)
            nextHint = settings.localized(next.title)
            nextAction = {
                dismissDebugResult()
                openNextLesson(next)
            }
        case .hidden:
            nextHint = settings.localized("No next lesson available")
        }

        return TransportControls(
            running: session.running,
            enabled: session.ready && session.available,
            showsResult: showingResult,
            nextEnabled: nextEnabled,
            nextLocked: nextLocked,
            nextHint: nextHint,
            nextAction: nextAction,
            squareSize: s,
            resultSize: resultSize,
            horizontalResultButtons: horizontalResultButtons,
            start: {
                dismissDebugResult()
                showingInfo = false
                session.start()
            },
            stop: session.stop,
            restart: {
                dismissDebugResult()
                showingInfo = false
                session.restart()
            },
            skipAction: (session.isMix && !session.running && !showingResult) ? {
                dismissDebugResult()
                showingInfo = false
                session.skipMixLesson()
            } : nil
        )
    }

    private var tempoControls: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            HStack(spacing: Theme.Space.regular) {
                BackButton { showingTempo = false }
                Text(settings.localized("Tempo")).font(Theme.screenTitle)
                Spacer()
            }
            Text("\(session.bpm) → \(session.lesson.targetBpm) BPM").font(Theme.control).monospacedDigit()
                        .contentTransition(motion.numeric).motion(value: session.bpm)
            HStack(spacing: Theme.Space.controlGap) {
                ForEach([-5, -1, 1, 5], id: \.self) { step in
                    Button(step > 0 ? "+\(step)" : "\(step)") { session.setTempo(session.bpm + step) }
                        .buttonStyle(InstrumentButtonStyle())
                }
            }
            Button(settings.localized("Starting tempo")) { session.setTempo(session.lesson.startBpm) }
                .buttonStyle(InstrumentButtonStyle())
        }
        .disabled(session.running)
        .foregroundStyle(Theme.ink)
    }



    private func starAnnouncement(for event: StarEvent) -> String {
        let names = StarRequirement.titleKeys.map { settings.localized($0) }
        return names.indices.filter { event.award.fresh[$0] }.map {
            settings.localized("Star earned: %@", names[$0])
        }.joined(separator: ". ")
    }

    private var resultAnnouncement: String {
        var parts: [String] = []
        if let reviewMessage = session.reviewFeedback?.message(language: settings.languagePreference) {
            parts.append(reviewMessage)
        }
        if let starEvent = session.starEvent {
            let stars = starAnnouncement(for: starEvent)
            if !stars.isEmpty { parts.append(stars) }
        }
        if session.summary?.firstStar2 == true {
            parts.append(settings.localized("Comes back tomorrow for a review"))
        }
        return parts.joined(separator: ". ")
    }

    private var nextDueReviewLesson: Lesson? {
        guard onStepResult == nil else { return nil }
        let today = AppCalendar.today()
        let padCount = midi.activeProfile.padCount
        let candidates = progress.dueLessonIds(today: today)
            .filter { $0 != session.lesson.id }
            .compactMap { id in progression.catalog.lessons.first { $0.id == id } }
            .filter { lesson in
                progression.isLessonOpen(lesson)
                    && (padCount == 16 || EightPadLayout.slots(for: lesson) != nil)
            }
        return ReviewQueue.order(candidates, records: progress.records, today: today).first
    }

    private var nextLesson: Lesson? {
        guard onStepResult == nil else { return nil }
        return progression.nextLesson(after: session.lesson,
                               source: NextLessonSource(rawValue: settings.nextLessonSource) ?? .path)
    }

    private func openNextLesson(_ lesson: Lesson) {
        guard store.isUnlocked(lesson) else {
            purchaseAccess = lesson.access ?? "full"
            return
        }
        guard progression.isLessonOpen(lesson) else { return }
        showingInfo = false
        showingLegend = false
        showingLoop = false
        showingTools = false
        showingTempo = false
        showingDetails = false
        showingStarRules = false
        helpPresentation = nil
        didOpenHelpOrInfo = false
        session.close()
        let launch = LessonLaunch.library(lesson, progress: progress.progress(for: lesson.id), today: AppCalendar.today())
        session = PracticeSession(
            lesson: lesson,
            settings: settings,
            progress: progress,
            midi: midi,
            initialFromMemory: launch.reviewTempo != nil,
            initialBpm: launch.reviewTempo
        )
    }

    private func sessionResultsView(_ summary: RunSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.regular) {
                HStack(spacing: Theme.Space.regular) {
                    BackButton { showingDetails = false }
                    Text(settings.localized("Session results"))
                        .font(Theme.sectionTitle)
                    Spacer()
                }

                if !session.runResults.isEmpty {
                    VStack(spacing: Theme.Space.small) {
                        ForEach(session.runResults.reversed()) { run in
                            HStack(spacing: Theme.Space.small) {
                                ZStack {
                                    if run.passed {
                                        Rectangle()
                                            .fill(Theme.orange)
                                            .frame(width: 5, height: 20)
                                    } else {
                                        Rectangle()
                                            .strokeBorder(Theme.markWrong, lineWidth: 1.5)
                                            .frame(width: 5, height: 20)
                                    }
                                }
                                .frame(width: 5, height: 20)

                                Text(settings.localized("Run %lld", run.runNumber))
                                    .font(Theme.control)

                                Spacer(minLength: 0)

                                Text("\(Int((run.score * 100).rounded()))\u{00a0}%")
                                    .font(Theme.control)
                                    .fontWeight(.medium)
                                    .monospacedDigit()

                                Text("\(run.bpm)\u{00a0}BPM")
                                    .font(Theme.meta)
                                    .foregroundStyle(Theme.secondary)
                                    .monospacedDigit()
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, Theme.Space.small)
                            .background(Theme.surface, in: Rectangle())
                            .overlay(
                                Rectangle()
                                    .strokeBorder(Theme.hairline, lineWidth: 1)
                            )
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(run.accessibilityDescription(settings: settings))
                        }
                    }
                    .padding(.bottom, Theme.Space.small)

                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(height: 1)
                }

                VStack(alignment: .leading, spacing: Theme.Space.regular) {
                    if let reviewMessage = session.reviewFeedback?.message(language: settings.languagePreference) {
                        Text(reviewMessage)
                    }
                    if let star = summary.finishedByStar {
                        Text(settings.localized(star == 3
                            ? "Run finished: star 3 earned, review"
                            : "Run finished: star 2 earned, goal tempo"))
                    }
                    if summary.firstStar2 {
                        Text(settings.localized("Comes back tomorrow for a review"))
                    }
                    Text("\(summary.bpm) BPM · \(settings.localized("%lld completed passes", summary.passes))")
                    Text(settings.localized("Best: %@", session.savedProgress.map {
                        "\(Int(($0.bestScore * 100).rounded())) %"
                    } ?? "— %"))
                    Text(settings.localized(summary.passes > 0
                        ? "Score is from the last completed pass. Stars are earned across this run."
                        : "Run stopped before the first pass finished."))
                        .foregroundStyle(Theme.secondary)
                    HitTimingPlot(history: session.timingHistory)
                }
                .font(Theme.control)
            }
            .padding(Theme.Space.page)
            .frame(idealWidth: 440, maxWidth: 480)
            .foregroundStyle(Theme.ink)
            .background(Theme.background)
        }
        .frame(idealWidth: 440, maxWidth: 480, maxHeight: 600)
        .presentationDetents([.height(600), .large])
    }

    private var starRules: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.regular) {
                HStack(spacing: Theme.Space.regular) {
                    BackButton { showingStarRules = false }
                    Text(settings.localized("Star requirements")).font(Theme.sectionTitle)
                    Spacer()
                }
                ForEach(0..<3, id: \.self) { index in
                    HStack(alignment: .top, spacing: Theme.Space.small) {
                        Image(systemName: isStarEarned(index) ? "star.fill" : "star")
                            .foregroundStyle(isStarEarned(index) ? PracticeBandStyle.orange : Theme.ink)
                            .frame(width: 24, height: 24)
                            .accessibilityHidden(true)
                        Text(StarRequirement.requirementText(for: index, lesson: session.lesson,
                            progress: session.savedProgress,
                            padCount: midi.activeProfile.padCount, settings: settings))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(Theme.control)
                }
            }
            .padding(Theme.Space.page)
        }
        .frame(width: 420, height: 360)
        .foregroundStyle(Theme.ink).background(Theme.background)
        .presentationDetents([.height(380), .medium])
    }

    private func showFirstLegendIfNeeded() {
        guard !legendShownOnce, !didOpenHelpOrInfo, helpPresentation == nil,
              !showingInfo, !showingTools, !showingTempo, !showingMIDI,
              !session.running, session.countdown == nil, !session.patternHits.isEmpty else { return }
        showingLegend = true
    }

    private func popoverBlock<Content: View>(
        title: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            if let title {
                Text(Theme.sentenceCase(settings.localized(title)))
                    .font(Theme.display(14))
                    .foregroundStyle(Theme.secondary)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Space.regular)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private func fingerName(_ finger: Int) -> String {
        switch finger {
        case 1: return settings.localized("Thumb (1)")
        case 2: return settings.localized("Index finger (2)")
        case 3: return settings.localized("Middle finger (3)")
        case 4: return settings.localized("Ring finger (4)")
        case 5: return settings.localized("Little finger (5)")
        default: return settings.localized("finger %lld", finger)
        }
    }

    private func legend(screenHeight: CGFloat) -> some View {
        PopoverHeightContainer(maxHeight: max(200, screenHeight - 100)) {
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                popoverBlock(title: "Pads in this lesson") {
                    VStack(spacing: Theme.Space.small) {
                        let usedPairs = Array(Set(session.patternHits.map { "\($0.padIndex):\($0.hand)" })).sorted()
                        ForEach(usedPairs, id: \.self) { key in
                            let parts = key.split(separator: ":")
                            let pad = Int(parts[0]) ?? 0
                            let hand = String(parts[1])
                            let padName = PadVoice.name(pad, settings: settings)
                            let handName = hand == "R" ? settings.localized("Right hand") : settings.localized("Left hand")

                            HStack(spacing: Theme.Space.regular) {
                                PatternBlock(abbreviation: PadVoice.abbreviation(pad), hand: hand)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(padName)
                                        .font(Theme.control)
                                        .foregroundStyle(Theme.ink)
                                    Text(handName)
                                        .font(Theme.meta)
                                        .foregroundStyle(Theme.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }

                popoverBlock(title: "Hands") {
                    HStack(spacing: Theme.Space.wide) {
                        HStack(spacing: Theme.Space.small) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Theme.black)
                                .frame(width: 32, height: 32)
                            Text(settings.localized("Left hand"))
                                .font(Theme.control)
                                .foregroundStyle(Theme.ink)
                        }
                        HStack(spacing: Theme.Space.small) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Theme.white)
                                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.black, lineWidth: 1.5))
                                .frame(width: 32, height: 32)
                            Text(settings.localized("Right hand"))
                                .font(Theme.control)
                                .foregroundStyle(Theme.ink)
                        }
                    }
                }

                popoverBlock(title: "Band colour") {
                    VStack(alignment: .leading, spacing: Theme.Space.small) {
                        HStack(spacing: Theme.Space.small) {
                            let modes: [(String, Color)] = [
                                ("Listen", BandTone.color(listen: true, memory: false, bpm: 0, startBpm: 0, targetBpm: 1)),
                                ("Play", BandTone.color(listen: false, memory: false, bpm: 1, startBpm: 0, targetBpm: 2)),
                                ("From memory", BandTone.color(listen: false, memory: true, bpm: 1, startBpm: 0, targetBpm: 1))
                            ]
                            ForEach(modes, id: \.0) { name, color in
                                VStack(alignment: .leading, spacing: 4) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(color)
                                        .frame(height: 32)
                                    Text(settings.localized(name))
                                        .font(Theme.meta)
                                        .foregroundStyle(Theme.ink)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        Text(settings.localized("Deeper colour = closer to the goal tempo."))
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                popoverBlock(title: "Timing glow") {
                    VStack(alignment: .leading, spacing: Theme.Space.small) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(PracticeBandStyle.orange)

                            HStack {
                                LinearGradient(
                                    colors: [Theme.white.opacity(0.95), Theme.white.opacity(0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: 48)
                                Spacer()
                                LinearGradient(
                                    colors: [Theme.white.opacity(0), Theme.white.opacity(0.95)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: 48)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .frame(height: 36)

                        HStack {
                            Text(settings.localized("Left edge: dragging"))
                                .font(Theme.meta)
                                .foregroundStyle(Theme.secondary)
                            Spacer()
                            Text(settings.localized("Right edge: rushing"))
                                .font(Theme.meta)
                                .foregroundStyle(Theme.secondary)
                        }
                    }
                }
            }
            .padding(Theme.Space.regular)
        }
    }

    private func lessonInfo(screenHeight: CGFloat) -> some View {
        PopoverHeightContainer(maxHeight: max(200, screenHeight - 100)) {
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                popoverBlock {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(session.lesson.level)")
                                .font(Theme.padTitle(size: 34))
                                .foregroundStyle(Theme.ink)
                            Text(settings.localized("Level"))
                                .font(Theme.display(13))
                                .foregroundStyle(Theme.secondary)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(session.lesson.bars)")
                                .font(Theme.padTitle(size: 34))
                                .foregroundStyle(Theme.ink)
                            Text(session.lesson.bars == 1 ? settings.localized("Bar") : settings.localized("Bars"))
                                .font(Theme.display(13))
                                .foregroundStyle(Theme.secondary)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text("\(session.lesson.startBpm)")
                                Text("→").foregroundStyle(Theme.orange)
                                Text("\(session.lesson.targetBpm)")
                            }
                            .font(Theme.padTitle(size: 34))
                            .foregroundStyle(Theme.ink)
                            Text(settings.localized("BPM, start to goal"))
                                .font(Theme.display(13))
                                .foregroundStyle(Theme.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                popoverBlock {
                    VStack(alignment: .leading, spacing: Theme.Space.tight) {
                        let goalText = (session.lesson.intro?.goal).flatMap { $0.isEmpty ? nil : $0 }
                            .map { settings.localized($0) }
                            ?? settings.localized("Play a steady groove at %lld BPM.", session.lesson.targetBpm)
                        Text(goalText)
                            .font(Theme.display(20))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(settings.localized("Goal"))
                            .font(Theme.display(13))
                            .foregroundStyle(Theme.secondary)
                    }
                }

                popoverBlock(title: "How to play") {
                    let instructions = !session.lesson.text.isEmpty
                        ? localizedInstructions(session.lesson.text)
                        : settings.localized("Follow the pattern and keep the left and right hands steady.")
                    infoParagraphs(instructions)
                }

                if let intro = session.lesson.intro {
                    let fingersDict = (midi.activeProfile.padCount == 8 ? intro.fingers8 : intro.fingers16)
                        ?? intro.fingers16
                        ?? intro.fingers8
                    if let fingersDict, !fingersDict.isEmpty {
                        popoverBlock(title: "Fingers") {
                            VStack(spacing: Theme.Space.small) {
                                let sortedKeys = fingersDict.keys.sorted { a, b in
                                    let padA = Int(a.split(separator: ":").first ?? "") ?? 0
                                    let padB = Int(b.split(separator: ":").first ?? "") ?? 0
                                    let handA = a.split(separator: ":").dropFirst().first ?? ""
                                    let handB = b.split(separator: ":").dropFirst().first ?? ""
                                    if handA != handB { return handA < handB }
                                    return padA < padB
                                }
                                ForEach(sortedKeys, id: \.self) { key in
                                    let parts = key.split(separator: ":")
                                    let pad = Int(parts[0]) ?? 0
                                    let hand = parts.count > 1 ? String(parts[1]) : "L"
                                    let finger = fingersDict[key] ?? 1
                                    let padName = PadVoice.name(pad, settings: settings)
                                    let handName = hand == "R" ? settings.localized("right hand") : settings.localized("left hand")

                                    HStack(spacing: Theme.Space.regular) {
                                        PatternBlock(abbreviation: PadVoice.abbreviation(pad), hand: hand)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(padName), \(handName)")
                                                .font(Theme.control)
                                                .foregroundStyle(Theme.ink)
                                            Text(fingerName(finger))
                                                .font(Theme.meta)
                                                .foregroundStyle(Theme.secondary)
                                        }
                                        Spacer()
                                        Text("\(hand)\(finger)")
                                            .font(Theme.padTitle(size: 28))
                                            .foregroundStyle(Theme.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(Theme.Space.regular)
        }
    }

    /// Core lessons compose hand assignments; the table contains their labels and instrument names.
    private func localizedInstructions(_ text: String) -> String {
        let translated = settings.localized(text)
        guard settings.languagePreference == .czech, translated == text else { return translated }
        let sentences = text.components(separatedBy: ". ")
        return sentences.enumerated().map { index, sentence in
            let full = sentence + (index < sentences.count - 1 ? "." : "")
            let translatedSentence = settings.localized(full)
            if translatedSentence != full { return translatedSentence }
            for hand in ["Left hand", "Right hand"] where full.hasPrefix(hand + ": ") {
                let hasPeriod = full.hasSuffix(".")
                let assignment = String(full.dropFirst(hand.count + 2).dropLast(hasPeriod ? 1 : 0))
                let names = assignment.components(separatedBy: ", ").map { name in
                    let key = name == "open hat" ? "Open hi-hat" : name.prefix(1).uppercased() + name.dropFirst()
                    return settings.localized(key)
                }
                return settings.localized(hand) + ": " + names.joined(separator: ", ") + (hasPeriod ? "." : "")
            }
            return full
        }.joined(separator: " ")
    }

    private func infoParagraphs(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            ForEach(Array(text.components(separatedBy: .newlines).filter { !$0.isEmpty }.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph).font(Theme.navigation).lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func isStarEarned(_ index: Int) -> Bool {
        guard let progress = session.savedProgress else { return false }
        switch index {
        case 0: return progress.passed
        case 1: return progress.mastery
        case 2: return progress.memory
        default: return false
        }
    }
}

@MainActor
private struct PracticeTools: View {
    @Environment(SettingsManager.self) private var settings
    @Bindable var session: PracticeSession
    @Binding var showPads: Bool
    @AppStorage("smackapad.practice.visibleBars") private var visibleBars = 4
    let openMIDI: () -> Void

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section(settings.localized("Practice")) {
                Picker(settings.localized("Bars shown"), selection: $visibleBars) {
                    Text(settings.localized("1 bar")).tag(1)
                    Text(settings.localized("%lld bars", 2)).tag(2)
                    Text(settings.localized("%lld bars", 3)).tag(3)
                    Text(settings.localized("All bars")).tag(4)
                }
                Toggle(settings.localized("Small pad layout"), isOn: $showPads)
                Toggle(settings.localized("Fade notes in From memory"), isOn: $settings.fadeMemoryNotes)
                    .disabled(session.running)
                Toggle(settings.localized("Pattern sound in Play"), isOn: $session.lessonSound)
                    .disabled(session.running || session.afterMe)
                Toggle(settings.localized("Metronome"), isOn: Binding(
                    get: { session.afterMe || session.metronome },
                    set: { session.metronome = $0 }
                )).disabled(session.running || session.afterMe)
                Picker(settings.localized("Tempo step after a clean pass"), selection: $settings.bpmStep) {
                    ForEach(BpmStep.allCases) { step in Text("+\(step.rawValue) BPM").tag(step.rawValue) }
                }.disabled(session.running || session.afterMe || session.isMix)
                Picker(settings.localized("Sound kit"), selection: Binding(
                    get: { settings.kitOverride(for: session.lesson.id) ?? "auto" },
                    set: { newValue in
                        settings.setKitOverride(newValue == "auto" ? nil : newValue, for: session.lesson.id)
                        session.applyResolvedKit()
                    }
                )) {
                    Text(session.automaticKitPickerLabel).tag("auto")
                    ForEach(session.kits) { kit in Text(kit.name).tag(kit.kitId) }
                }.disabled(session.running)
            }
            Section(settings.localized("Sound")) {
                VolumeSliderRow(
                    title: settings.localized("Metronome"),
                    value: Binding(
                        get: { settings.metronomeVolume },
                        set: {
                            settings.metronomeVolume = $0
                            session.setMetronomeVolume($0)
                        }
                    )
                )
                VolumeSliderRow(
                    title: settings.localized("Pads"),
                    value: Binding(
                        get: { settings.padsVolume },
                        set: {
                            settings.padsVolume = $0
                            session.setPadsVolume($0)
                        }
                    )
                )
                VolumeSliderRow(
                    title: settings.localized("Pattern sound"),
                    value: Binding(
                        get: { settings.patternVolume },
                        set: {
                            settings.patternVolume = $0
                            session.setPatternVolume($0)
                        }
                    )
                )
            }
            Section(settings.localized("Bar loop")) {
                Picker(settings.localized("First bar"), selection: $session.loopStartBar) {
                    ForEach(0..<session.lesson.bars, id: \.self) { bar in Text("\(bar + 1)").tag(bar) }
                }
                Picker(settings.localized("Last bar"), selection: $session.loopEndBar) {
                    ForEach(session.loopStartBar..<session.lesson.bars, id: \.self) { bar in Text("\(bar + 1)").tag(bar) }
                }
                Text(settings.localized("Section loops do not earn lesson stars."))
            }.disabled(session.running || session.isMix)
            Section(settings.localized("Appearance")) {
                PlexSegmentedPicker(title: settings.localized("Appearance"), selection: $settings.appearance,
                    options: AppAppearance.allCases.map { ($0, settings.localized($0.title)) })
            }
            Button(settings.localized("MIDI and controller"), action: openMIDI).disabled(session.running)
        }
        .font(Theme.control).tint(Theme.ink)
        .frame(width: 480, height: 640)
        .scrollContentBackground(.hidden).background(Theme.background).foregroundStyle(Theme.ink)
    }
}

private extension View {
    func adaptivePopoverOrSheet<Content: View>(
        isPresented: Binding<Bool>,
        asSheet: Bool,
        arrowEdge: Edge = .bottom,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self
            .sheet(isPresented: Binding(
                get: { isPresented.wrappedValue && asSheet },
                set: { if !$0 { isPresented.wrappedValue = false } }
            )) {
                content()
                    .presentationDragIndicator(.visible)
            }
            .popover(
                isPresented: Binding(
                    get: { isPresented.wrappedValue && !asSheet },
                    set: { if !$0 { isPresented.wrappedValue = false } }
                ),
                arrowEdge: arrowEdge
            ) {
                content()
            }
    }
}

enum ResultNextTarget: Equatable {
    case stepResult
    case lesson(Lesson)
    case hidden

    static func resolve(
        isStepResult: Bool,
        isMix: Bool,
        afterMe: Bool,
        finishedByReview: Bool,
        isDueReview: Bool,
        reviewFeedback: ReviewScheduler.ReviewFeedback?,
        lessonPassed: Bool,
        nextDueReview: Lesson?,
        nextPathLesson: Lesson?
    ) -> Self {
        if afterMe { return .hidden }
        if isStepResult { return .stepResult }
        if isMix { return .hidden }

        if finishedByReview {
            if let nextDueReview { return .lesson(nextDueReview) }
            if let nextPathLesson { return .lesson(nextPathLesson) }
            return .hidden
        }

        if isDueReview || reviewFeedback != nil {
            return .hidden
        }

        if lessonPassed, let nextPathLesson {
            return .lesson(nextPathLesson)
        }
        return .hidden
    }
}

private struct PopoverContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct PopoverHeightContainer<Content: View>: View {
    let maxHeight: CGFloat
    @ViewBuilder let content: () -> Content
    @State private var measuredHeight: CGFloat = 0

    var body: some View {
        ScrollView {
            content()
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: PopoverContentHeightKey.self,
                            value: geo.size.height
                        )
                    }
                )
        }
        .onPreferenceChange(PopoverContentHeightKey.self) { height in
            measuredHeight = height
        }
        .frame(width: 420)
        .frame(height: measuredHeight > 0 ? min(measuredHeight, maxHeight) : nil)
        .foregroundStyle(Theme.ink)
        .background(Theme.background)
    }
}
