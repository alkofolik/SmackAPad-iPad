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
    @State private var padLayoutModel: PadLayoutModel
    @State private var showingLegend = false
    @State private var showingTools = false
    @State private var showingTempo = false
    @State private var showingDetails = false
    @State private var showingStarRules = false
    @State private var showingMIDI = false
    @State private var showingInfo = false
    @State private var purchaseAccess: String?
    @State private var midLessonStarMomentActive = false
    #if DEBUG
    @State private var debugShowResult = false
    #endif
    private let onStepResult: ((PracticeStepOutcome) -> Void)?

    init(lesson: Lesson, settings: SettingsManager, progress: ProgressStore, midi: MIDIInput,
         initialFromMemory: Bool = false, initialBpm: Int? = nil, mixLessons: [Lesson] = [], initialAfterMe: Bool = false,
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
            initialAfterMe: initialAfterMe
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

    var body: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.height > geometry.size.width
            let portraitPads = isPortrait && touchPadsInPortrait && midi.padIndices?.count == 16
            let availableWidth = max(0, geometry.size.width - 2 * Theme.Space.page)
            let defaultS: CGFloat = 2 * Theme.Size.control + Theme.Space.small
            let s = min(defaultS, max(80, (availableWidth - 2 * Theme.Space.small) / 3))

            VStack(spacing: Theme.Space.regular) {
                topZone(isPortrait: isPortrait)
                    .fixedSize(horizontal: false, vertical: true)

                middleZone
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomZone(s: s, portraitPads: portraitPads, screenHeight: geometry.size.height, availableWidth: availableWidth)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Theme.Space.page)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .calmChassisBackground()
            .foregroundStyle(Theme.ink)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task(id: ObjectIdentifier(session)) {
            await session.prepare()
            updatePadLayoutModel()
            handleDebugLaunchArguments()
            if session.isMix { session.start() }
        }
        .onDisappear {
            session.close()
            reportStepResult()
        }
        .onChange(of: session.runResults) { _, _ in reportStepResult() }
        .onChange(of: session.reviewFeedback) { _, _ in reportStepResult() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { session.resume() } else { session.suspend() }
        }
        .onChange(of: session.lesson.id) { _, _ in updatePadLayoutModel() }
        .onChange(of: settings.activeProfileName) { _, _ in
            session.stop()
            updatePadLayoutModel()
        }
        .onChange(of: settings.metronomeVolume) { _, newVolume in session.setMetronomeVolume(newVolume) }
        .onChange(of: settings.padsVolume) { _, newVolume in session.setPadsVolume(newVolume) }
        .onChange(of: settings.patternVolume) { _, newVolume in session.setPatternVolume(newVolume) }
        .onChange(of: session.running) { _, running in
            if running {
                showingInfo = false
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
        guard !session.isSectionLoop, !session.afterMe, !session.listen,
              let best = session.runResults.map(\.score).max() else { return }
        onStepResult?(PracticeStepOutcome(bestScore: best, reviewFeedback: session.reviewFeedback))
    }

    @ViewBuilder
    private func topZone(isPortrait: Bool) -> some View {
        if isPortrait {
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                HStack(spacing: Theme.Space.regular) {
                    libraryButton
                    titleAndSubtitle
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .center) {
                    modeButtons
                    Spacer(minLength: Theme.Space.regular)
                    toolIcons
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            HStack(spacing: Theme.Space.regular) {
                libraryButton
                titleAndSubtitle
                Spacer(minLength: Theme.Space.regular)
                tools
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var libraryButton: some View {
        Button {
            session.stop()
            reportStepResult()
            if let dismissLesson { dismissLesson() } else { dismiss() }
        } label: {
            Label(settings.localized(onStepResult != nil ? "Today" : (session.isMix ? "Training" : "Library")), systemImage: "square.grid.2x2")
                .font(Theme.control)
        }
        .buttonStyle(PadSecondaryButtonStyle())
        .fixedSize(horizontal: true, vertical: false)
    }

    private var titleAndSubtitle: some View {
        VStack(alignment: .leading, spacing: Theme.Space.tight) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.small) {
                Text(session.isMix
                     ? settings.localized("Mix · %lld of %lld · %@", session.mixIndex + 1, session.mixLessons.count, settings.localized(session.lesson.title))
                     : settings.localized(session.lesson.title))
                    .font(Theme.rowTitle)
                    .fixedSize(horizontal: false, vertical: true)
                if !session.isMix {
                    headerStars
                }
            }
            lessonSubtitle
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .layoutPriority(1)
    }

    @ViewBuilder
    private var headerStars: some View {
        HStack(spacing: Theme.Space.tight) {
            if session.savedProgress?.reviewSchedule.isSettled == true {
                Image(systemName: "checkmark")
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
                    .accessibilityLabel(settings.localized("Settled"))
            }
            StarsView(record: session.savedProgress)
        }
    }

    @ScaledMetric(relativeTo: .body) private var subtitleHeight: CGFloat = 22

    private var lessonSubtitle: some View {
        ZStack(alignment: .leading) {
            Text(settings.localized("Practice only · no stars"))
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
                .opacity(session.afterMe ? 1 : 0)
                .accessibilityHidden(!session.afterMe)

            Group {
                if session.showsReviewStatus {
                    Text(session.reviewStatusText(settings: settings))
                } else if session.fromMemory && session.savedProgress?.memory != true {
                    Text(StarRequirement.requirementText(for: 2, progress: session.savedProgress, language: settings.languagePreference))
                } else {
                    HStack(spacing: 0) {
                        difficultyDots
                        Text(" · \(localizedBarCount(session.lesson.bars))")
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(settings.localized("Difficulty %lld of 5, %@", session.lesson.level, localizedBarCount(session.lesson.bars)))
                }
            }
            .font(Theme.meta)
            .foregroundStyle(Theme.secondary)
            .opacity(session.afterMe ? 0 : 1)
            .accessibilityHidden(session.afterMe)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.85)
        .frame(height: subtitleHeight, alignment: .leading)
        .animation(motion.animation(Theme.Motion.fast), value: session.afterMe)
    }

    private var difficultyDots: some View {
        HStack(spacing: Theme.Space.tight) {
            ForEach(1...5, id: \.self) { level in
                Circle().fill(level <= session.lesson.level ? Theme.ink : Theme.background)
                    .overlay(Circle().stroke(Theme.ink, lineWidth: 1))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private func localizedBarCount(_ bars: Int) -> String {
        if bars == 1 {
            return settings.localized("1 bar")
        }
        if settings.languagePreference == .czech && bars >= 5 {
            return "\(bars) taktů"
        }
        return settings.localized("%lld bars", bars)
    }

    private var tools: some View {
        HStack(spacing: Theme.Space.regular) {
            modeButtons
            toolIcons
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private var modeButtons: some View {
        if !session.isMix {
            HStack(spacing: 0) {
                ForEach(LessonPlaybackMode.allCases, id: \.self) { mode in
                    Button { session.selectPlaybackMode(mode) } label: {
                        Text(settings.localized(mode.rawValue))
                            .font(Theme.control)
                            .padding(.horizontal, Theme.Space.regular)
                            .frame(minHeight: Theme.Size.touch)
                    }
                    .buttonStyle(HardwareKeyButtonStyle(isSelected: session.playbackMode == mode))
                }
            }
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .disabled(session.running)
            .accessibilityLabel(settings.localized("Lesson mode"))
        }
    }

    private var toolIcons: some View {
        HStack(spacing: Theme.Space.small) {
            icon("eye.slash", settings.localized("From memory"), selected: session.fromMemory && !session.afterMe) {
                session.fromMemory.toggle()
            }
            .disabled(session.running || session.isMix || session.afterMe)
            .accessibilityValue(settings.localized(session.fromMemory ? "On" : "Off"))

            toolSeparator

            HStack(spacing: 0) {
                let effectiveBars = min(max(1, visibleBars), session.lesson.bars)
                icon("rectangle.split.2x2", settings.localized("Static view"),
                     selected: !scrolling,
                     count: session.lesson.bars > 1 ? effectiveBars : nil,
                     accessibilityValue: staticViewAccessibilityValue(effectiveBars),
                     accessibilityHint: session.lesson.bars > 1 ? settings.localized("Tap again to show more bars") : nil) {
                    handleStaticViewTap()
                }
                icon("arrow.right.to.line", settings.localized("Scrolling view"), selected: scrolling) { scrolling = true }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(settings.localized("Pattern view"))

            toolSeparator

            HStack(spacing: 0) {
                icon("info.circle", settings.localized("Lesson info")) { showingInfo.toggle() }
                    .disabled(session.running)
                    .popover(isPresented: $showingInfo, arrowEdge: .top) { lessonInfo }
                icon("list.bullet.rectangle", settings.localized("Legend")) { showingLegend.toggle() }
                    .popover(isPresented: $showingLegend, arrowEdge: .top) { legend }
                icon("slider.horizontal.3", settings.localized("More tools")) { showingTools.toggle() }
                    .popover(isPresented: $showingTools, arrowEdge: .top) {
                        PracticeTools(session: session, showPads: $showPads, openMIDI: {
                            showingTools = false; showingMIDI = true
                        })
                    }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func handleStaticViewTap() {
        if scrolling {
            scrolling = false
            return
        }
        guard session.lesson.bars > 1 else { return }
        let current = min(visibleBars, session.lesson.bars)
        let next = current >= session.lesson.bars ? 1 : current + 1
        visibleBars = next
    }

    private func staticViewAccessibilityValue(_ bars: Int) -> String {
        if bars == 1 {
            return settings.localized("%lld bar shown", 1)
        }
        return settings.localized("%lld bars shown", bars)
    }

    private var toolSeparator: some View {
        Rectangle().fill(Theme.hairline).frame(width: 1, height: 28)
            .accessibilityHidden(true)
    }

    private func icon(_ symbol: String, _ text: String, selected: Bool = false,
                      count: Int? = nil, accessibilityValue: String? = nil,
                      accessibilityHint: String? = nil,
                      action: @escaping () -> Void) -> some View {
        PracticeIconButton(
            symbol: symbol,
            title: text,
            count: count,
            selected: selected,
            accessibilityValue: accessibilityValue,
            accessibilityHint: accessibilityHint,
            action: action
        )
    }

    private var middleZone: some View {
        GeometryReader { middleGeo in
            let rows: [Int] = {
                let used = Set(session.patternHits.map(\.padIndex))
                return PadVoice.rowOrder.filter { used.contains($0) }
            }()
            let availableHeight = middleGeo.size.height
            let bandHeight = PracticeBandStyle.bandHeight(rows: rows.count, availableHeight: availableHeight)
            let verticalMargin = max(0, (availableHeight - bandHeight) / 2)

            ZStack {
                VStack(spacing: 0) {
                    Color.clear.frame(height: verticalMargin)

                    TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !session.running)) { timeline in
                        let frame = session.patternFrame(at: timeline.date)
                        let scored = session.running && !session.listen && frame.countdown == nil
                            && (!session.afterMe || frame.pass.isMultiple(of: 2))
                        PatternField(lesson: session.practiceLesson, hits: session.patternHits,
                                     position: frame.position, tapePosition: frame.tapePosition,
                                     running: session.running && frame.countdown == nil,
                                     visibility: session.noteVisibility(pass: frame.pass),
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
                                     edgeTendency: scored ? BandTone.edgeTendency(session.timingHistory, at: timeline.date) : 0,
                                     runBars: session.repeatsPerRun * session.practiceLesson.bars,
                                     starMomentBeamActive: midLessonStarMomentActive)
                            .overlay(alignment: .topLeading) {
                                Text(settings.localized(session.afterMePhase(at: frame)))
                                    .font(Theme.rowTitle)
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                                    .alignmentGuide(.top) { d in d.height + Theme.Space.small }
                                    .opacity(session.afterMe ? 1 : 0)
                                    .animation(motion.animation(Theme.Motion.fast), value: session.afterMe)
                                    .allowsHitTesting(false)
                            }
                    }
                    .frame(height: bandHeight)
                    .frame(maxWidth: .infinity)

                    Color.clear.frame(height: verticalMargin)
                }

                if session.running && !session.listen && session.countdown == nil {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: verticalMargin + bandHeight + Theme.Space.small)
                        HitTimingBar(history: session.timingHistory, windows: session.timingWindows,
                                     active: true)
                            .frame(maxWidth: .infinity)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topTrailing) {
                if session.running && !session.listen {
                    HStack(spacing: Theme.Space.small) {
                        if session.countdown == nil, let event = session.tempoUpEvent {
                            TempoUpBanner(event: event,
                                          label: settings.localized("Tempo up: %lld → %lld BPM", event.from, event.to),
                                          announcement: settings.localized("Tempo %lld", event.to))
                                .id(event.id)
                        }
                        PlayingLastRunChip(lastRun: session.runResults.last)
                        if session.showsMemoryFadePhase {
                            MemoryPhaseChip(phase: session.memoryPhaseText(settings: settings))
                        } else if let progress = session.starRunProgress {
                            LapVaultView(
                                progress: progress,
                                mode: session.practiceMode,
                                verdict: session.lastVerdict,
                                starEvent: session.starEvent,
                                starMomentActive: midLessonStarMomentActive,
                                settings: settings
                            )
                        }
                    }
                }
            }
            .overlay(alignment: .top) {
                if let event = session.badgeBannerEvent {
                    BadgeBanner(event: event) {
                        session.clearBadgeBannerEvent()
                    }
                    .id(event.id)
                    .padding(.top, Theme.Space.small)
                }
            }
        }
    }

    private func bottomZone(s: CGFloat, portraitPads: Bool, screenHeight: CGFloat, availableWidth: CGFloat) -> some View {
        let padsHeight: CGFloat = (portraitPads && midi.padIndices != nil) ? {
            let availableForPads = max(260, screenHeight - 48 - 110 - s - 280)
            return min(520, max(280, min((screenHeight - 48) * 0.44, availableForPads)))
        }() : 0

        let spaceAbove = padsHeight > 0
            ? (screenHeight - Theme.Space.page - padsHeight - Theme.Space.regular - s)
            : (screenHeight - Theme.Space.page - s)

        return VStack(spacing: Theme.Space.regular) {
            bottomZoneRow(s: s, availableWidth: availableWidth, spaceAbove: spaceAbove)

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

    private func bottomZoneRow(s: CGFloat, availableWidth: CGFloat, spaceAbove: CGFloat) -> some View {
        #if DEBUG
        let activeSummary = session.summary ?? (debugShowResult ? RunSummary(score: 0.94, bpm: session.lesson.targetBpm, passes: 2, passed: true, mastery: true, memory: false) : nil)
        #else
        let activeSummary = session.summary
        #endif
        let showsResult = activeSummary != nil && !session.running
        let gap = max(0, (availableWidth - 3 * s) / 2)
        let resultCardWidth = 2 * s + gap

        return HStack(spacing: 0) {
            if showsResult, session.isMix {
                mixResultsCard
                    .frame(width: resultCardWidth, height: s)
                Spacer(minLength: 0)
                transportSquare(s: s)
            } else if showsResult, session.afterMe {
                afterMeResultsCard
                    .frame(width: resultCardWidth, height: s)
                Spacer(minLength: 0)
                transportSquare(s: s)
            } else if showsResult, let summary = activeSummary {
                ResultCard(
                    summary: summary,
                    runs: session.runResults,
                    saved: session.savedProgress,
                    event: session.starEvent,
                    announcement: resultAnnouncement,
                    reviewMessage: session.finishedByReview ? session.reviewFeedback?.message(language: settings.languagePreference) : nil,
                    badgeText: session.badgeSummaryMessage(settings: settings),
                    cardWidth: resultCardWidth,
                    cardHeight: s,
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

                Spacer(minLength: 0)

                transportSquare(s: s)
            } else {
                padLayoutSquare(s: s)
                Spacer(minLength: 0)
                tempoSquare(s: s, spaceAbove: spaceAbove)
                Spacer(minLength: 0)
                transportSquare(s: s)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var afterMeResultsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            Text(settings.localized("Practice only · no stars"))
                .font(Theme.control)
            HStack {
                Text(settings.localized("Last response"))
                Spacer(minLength: 0)
                Text(responseScore(session.lastResult?.score))
            }
            HStack {
                Text(settings.localized("Best response"))
                Spacer(minLength: 0)
                Text(responseScore(session.bestResponseScore))
            }
        }
        .font(Theme.meta)
        .monospacedDigit()
        .padding(Theme.Space.regular)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .satinPlate()
        .contentShape(RoundedRectangle(cornerRadius: Theme.Skin.Plate.radius))
        .accessibilityElement(children: .combine)
    }

    private func responseScore(_ score: Double?) -> String {
        score.map { "\(Int(($0 * 100).rounded())) %" } ?? "—"
    }

    private var mixResultsCard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                ForEach(session.mixResults) { result in
                    VStack(alignment: .leading, spacing: Theme.Space.tight) {
                        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.small) {
                            Text(settings.localized(result.title))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Text(result.score.map { "\(Int(($0 * 100).rounded())) %" } ?? "—")
                                .monospacedDigit()
                        }
                        Text(mixBarSummary(result))
                            .foregroundStyle(Theme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let review = session.reviewStatusText(for: result.id, settings: settings) {
                            Text(review)
                                .foregroundStyle(Theme.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .font(Theme.meta)
                }
            }
            .padding(Theme.Space.small)
        }
        .satinPlate()
        .contentShape(RoundedRectangle(cornerRadius: Theme.Skin.Plate.radius))
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
    }

    private func tempoSquare(s: CGFloat, spaceAbove: CGFloat) -> some View {
        let editable = !session.isMix && !session.running && session.ready && session.available
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

    private func transportSquare(s: CGFloat) -> some View {
        let showsResult = session.summary != nil && !session.running
        let second = showsResult && !session.isMix && !session.afterMe
            && (!session.finishedByReview || onStepResult != nil) ? transportSecondAction(s: s) : nil
        return TransportControls(
            running: session.running,
            enabled: session.ready && session.available,
            showsResult: showsResult,
            resultStartTitle: session.finishedByReview ? "Play on" : "Again",
            squareSize: s,
            secondAction: second.map { AnyView($0) },
            start: { showingInfo = false; session.start() },
            stop: session.stop,
            restart: { showingInfo = false; session.restart() }
        )
        .frame(width: s, height: s)
    }

    @ViewBuilder
    private func transportSecondAction(s: CGFloat) -> some View {
        let buttonHeight = max(0, (s - Theme.Space.small) / 2)
        if onStepResult != nil {
            Button {
                session.stop()
                reportStepResult()
                if let dismissLesson { dismissLesson() } else { dismiss() }
            } label: {
                Text(settings.localized("Continue"))
                    .font(Theme.action)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(height: buttonHeight)
            }
            .buttonStyle(PadPrimaryButtonStyle())
        } else if session.savedProgress?.passed == true {
            nextLessonButton(buttonHeight: buttonHeight)
        }
    }

    private func nextLessonButton(buttonHeight: CGFloat) -> some View {
        Button {
            if let next = nextLesson {
                openNextLesson(next)
            }
        } label: {
            Group {
                if let next = nextLesson, !store.isUnlocked(next) {
                    Label(settings.localized("Next lesson"), systemImage: "lock")
                } else {
                    Text(settings.localized("Next lesson"))
                }
            }
            .font(Theme.action)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: buttonHeight)
        }
        .buttonStyle(PadPrimaryButtonStyle())
        .disabled(nextLesson == nil)
        .accessibilityHint(nextLesson.map { settings.localized($0.title) } ?? settings.localized("No next lesson available"))
    }

    private var handLegend: some View {
        HStack(spacing: Theme.Space.regular) {
            HStack(spacing: Theme.Space.small) {
                Rectangle().fill(Theme.black).frame(width: 12, height: 20)
                    .overlay(Rectangle().stroke(Theme.white, lineWidth: 1))
                Text(settings.localized("left"))
            }
            HStack(spacing: Theme.Space.small) {
                Rectangle().fill(Theme.white).frame(width: 12, height: 20)
                    .overlay(Rectangle().stroke(Theme.black, lineWidth: 1))
                Text(settings.localized("right"))
            }
        }
        .font(Theme.control)
    }

    private var bandLegend: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            Text(settings.localized("Band colour")).font(Theme.control)
            ForEach(["Listen", "Play", "From memory"], id: \.self) { name in
                HStack(spacing: Theme.Space.small) {
                    Rectangle().fill(BandTone.color(listen: name == "Listen", memory: name == "From memory",
                                                    bpm: 1, startBpm: 0, targetBpm: 1))
                        .frame(width: 28, height: 20)
                    Text(settings.localized(name)).font(Theme.meta)
                }
            }
            Text(settings.localized("The band gets deeper as the tempo nears the goal. A glow on the right edge: you are rushing; on the left: you are dragging."))
                .font(Theme.meta).foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var tempoControls: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            HStack {
                Text(settings.localized("Tempo")).font(Theme.screenTitle)
                Spacer()
                Button(settings.localized("Close")) {
                    showingTempo = false
                }
                .font(Theme.control)
                .frame(minHeight: Theme.Size.touch)
            }
            Text("\(session.bpm) → \(session.lesson.targetBpm) BPM").font(Theme.control).monospacedDigit()
                        .contentTransition(motion.numeric).motion(value: session.bpm)
            HStack(spacing: Theme.Space.small) {
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
        let names = [settings.localized("Passed"), settings.localized("Goal tempo"), settings.localized("From memory")]
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
        showingTools = false
        showingTempo = false
        showingDetails = false
        showingStarRules = false
        session.close()
        session = PracticeSession(lesson: lesson, settings: settings, progress: progress, midi: midi)
    }

    private func sessionResultsView(_ summary: RunSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.regular) {
                HStack {
                    Text(settings.localized("Session results"))
                        .font(Theme.sectionTitle)
                    Spacer()
                    Button(settings.localized("Close")) {
                        showingDetails = false
                    }
                    .font(Theme.control)
                    .frame(minHeight: Theme.Size.touch)
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
                            ? "Run finished: star 3 earned, from memory"
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
                HStack {
                    Text(settings.localized("Star requirements")).font(Theme.sectionTitle)
                    Spacer()
                    Button(settings.localized("Close")) { showingStarRules = false }
                        .font(Theme.control).frame(minHeight: Theme.Size.touch)
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

    private var legend: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.regular) {
                HStack {
                    Text(settings.localized("Pad legend")).font(Theme.sectionTitle)
                    Spacer()
                    Button(settings.localized("Close")) { showingLegend = false }.frame(minHeight: Theme.Size.touch)
                }
                ForEach(Array(Set(session.patternHits.map { "\($0.padIndex):\($0.hand)" })).sorted(), id: \.self) { key in
                    let parts = key.split(separator: ":")
                    let pad = Int(parts[0]) ?? 0
                    let hand = String(parts[1])
                    HStack(spacing: Theme.Space.regular) {
                        PatternBlock(abbreviation: PadVoice.abbreviation(pad), hand: hand)
                            .overlay(Rectangle().stroke(Theme.ink, lineWidth: 1))
                        Text("\(PadVoice.name(pad, settings: settings)) · \(settings.localized(hand == "R" ? "right" : "left"))")
                            .font(Theme.control)
                    }
                }
                handLegend
                bandLegend
            }
            .padding(Theme.Space.page)
        }
        .frame(width: 420, height: min(620, CGFloat(Set(session.patternHits.map { "\($0.padIndex):\($0.hand)" }).count) * 64 + 320))
        .foregroundStyle(Theme.ink).background(Theme.background)
    }

    private var lessonInfo: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.page) {
                HStack {
                    Text(settings.localized("Lesson info")).font(Theme.sectionTitle)
                    Spacer()
                    Button(settings.localized("Close")) { showingInfo = false }
                        .font(Theme.control)
                        .frame(minHeight: Theme.Size.touch)
                }

                VStack(alignment: .leading, spacing: Theme.Space.tight) {
                    Text(settings.localized(session.lesson.title))
                        .font(Theme.rowTitle)
                    let barsText = session.lesson.bars == 1
                        ? settings.localized("1 bar")
                        : settings.localized("%lld bars", session.lesson.bars)
                    Text("\(Theme.sentenceCase(settings.localized("Level"))) \(session.lesson.level) · \(barsText) · \(session.lesson.startBpm) → \(session.lesson.targetBpm) BPM")
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary)
                }

                infoBlock("Goal") {
                    if let goal = session.lesson.intro?.goal, !goal.isEmpty {
                        infoParagraphs(settings.localized(goal))
                    } else {
                        infoParagraphs(settings.localized("Play a steady groove at %lld BPM.", session.lesson.targetBpm))
                    }
                }

                infoBlock("How to play") {
                    if !session.lesson.text.isEmpty {
                        infoParagraphs(localizedInstructions(session.lesson.text))
                    } else {
                        infoParagraphs(settings.localized("Follow the pattern and keep the left and right hands steady."))
                    }
                    if let intro = session.lesson.intro {
                        let fingersDict = (midi.activeProfile.padCount == 8 ? intro.fingers8 : intro.fingers16) ?? intro.fingers16 ?? intro.fingers8
                        if let fingersDict, !fingersDict.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Space.small) {
                                Text(settings.localized("Fingers")).font(Theme.rowTitle)
                                Text(settings.localized("1 = thumb … 5 = little finger"))
                                    .font(Theme.meta)
                                    .foregroundStyle(Theme.secondary)
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
                                    let padLabel = "\(padName) \(hand)"
                                    let handLabel = hand == "L" ? settings.localized("left hand") : settings.localized("right hand")
                                    let fingerLabel = settings.localized("finger %lld", finger)
                                    HStack(spacing: Theme.Space.regular) {
                                        PatternBlock(abbreviation: PadVoice.abbreviation(pad), hand: hand)
                                            .overlay(Rectangle().stroke(Theme.ink, lineWidth: 1))
                                        Text("\(padLabel) · \(handLabel) · \(fingerLabel)")
                                            .font(Theme.control)
                                    }
                                }
                            }
                        }
                    }
                }

                infoBlock("Tips") {
                    if let watch = session.lesson.intro?.watch, !watch.isEmpty {
                        infoParagraphs(settings.localized(watch))
                    }
                    infoParagraphs(settings.localized("Listen to the pattern first. Start slowly, then work towards the goal tempo."))
                }

                infoBlock("Stars") {
                    ForEach(0..<3, id: \.self) { index in
                        let earned = isStarEarned(index)
                        let reqText = StarRequirement.requirementText(
                            for: index,
                            lesson: session.lesson,
                            progress: session.savedProgress,
                            padCount: midi.activeProfile.padCount,
                            settings: settings
                        )
                        HStack(alignment: .top, spacing: Theme.Space.small) {
                            StarShape()
                                .fill(earned ? Theme.ink : Theme.background)
                                .overlay(StarShape().stroke(Theme.ink, lineWidth: Theme.Size.border))
                                .frame(width: 20, height: 20)
                                .accessibilityLabel(settings.localized(earned ? "earned" : "not earned"))
                            Text(reqText)
                                .font(Theme.control)
                                .foregroundStyle(earned ? Theme.ink : Theme.secondary)
                        }
                    }
                }

                if !session.lesson.src.isEmpty {
                    Text(settings.localized("Source: %@", session.lesson.src))
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary)
                }
            }
            .padding(Theme.Space.page)
        }
        .frame(width: 480, height: 580)
        .foregroundStyle(Theme.ink)
        .background(Theme.background)
    }

    private func infoBlock<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            Text(settings.localized(title)).font(Theme.rowTitle)
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Space.regular)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
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
