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
    @State private var showingLegend = false
    @State private var showingTools = false
    @State private var showingTempo = false
    @State private var showingDetails = false
    @State private var showingStarRules = false
    @State private var showingMIDI = false
    @State private var showingInfo = false
    @State private var purchaseAccess: String?

    init(lesson: Lesson, settings: SettingsManager, progress: ProgressStore, midi: MIDIInput) {
        _session = State(initialValue: PracticeSession(lesson: lesson, settings: settings, progress: progress, midi: midi))
    }

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 1_000 || dynamicType > .large
            let portraitPads = geometry.size.height > geometry.size.width
                && touchPadsInPortrait && midi.padIndices?.count == 16
            VStack(spacing: Theme.Space.regular) {
                ViewThatFits(in: .vertical) {
                    practiceContent(compact: compact)
                    // Only undersized windows scroll; transport stays outside this region.
                    ScrollView {
                        practiceContent(compact: compact)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                if portraitPads, let pads = midi.padIndices {
                    VStack(alignment: .trailing, spacing: Theme.Space.small) {
                        sessionStatus
                        transport(width: 380)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .fixedSize(horizontal: false, vertical: true)
                    PracticeTouchPadGrid(pads: pads,
                                         used: Set(session.patternHits.map(\.padIndex)),
                                         flashes: session.padFlashes,
                                         enabled: touchPadsReady) { pad, pressed in
                        // Releases must still reach MIDI when readiness changes mid-touch.
                        guard !pressed || touchPadsReady else { return }
                        midi.touch(padIndex: pad, isPressed: pressed)
                    }
                    .id(session.lesson.id)
                    .frame(height: min(624, max(424, (geometry.size.height - 48) * 0.48)))
                } else {
                    footer
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Theme.Space.page)
            .background(Theme.background.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task(id: session.lesson.id) {
            await session.prepare()
        }
        .onDisappear {
            session.close()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { session.resume() } else { session.suspend() }
        }
        .onChange(of: settings.activeProfileName) { _, _ in session.stop() }
        .onChange(of: settings.metronomeVolume) { _, newVolume in session.setMetronomeVolume(newVolume) }
        .onChange(of: settings.padsVolume) { _, newVolume in session.setPadsVolume(newVolume) }
        .onChange(of: settings.patternVolume) { _, newVolume in session.setPatternVolume(newVolume) }
        .onChange(of: session.running) { _, running in
            if running { showingInfo = false }
        }
        .onChange(of: showingMIDI) { _, showing in
            if showing { session.suspend() }
        }
        .sheet(isPresented: Binding(get: { purchaseAccess != nil }, set: { if !$0 { purchaseAccess = nil } })) {
            PurchaseSheet(access: purchaseAccess ?? "full")
        }
        .sheet(isPresented: $showingMIDI, onDismiss: { session.resume() }) {
            MIDISettingsView()
                .presentationDragIndicator(.visible)
        }
    }

    private var touchPadsReady: Bool {
        session.ready && session.available && scenePhase == .active && !showingMIDI
            && midi.lesson?.id == session.lesson.id && midi.padIndices?.count == 16
    }

    private var lessonCategoryTitle: String {
        if session.lesson.cat == "intro" || session.lesson.cat == "starter" { return "Intro" }
        return LessonStore.shared.categories.first { $0.id == session.lesson.cat }?.title ?? session.lesson.genre
    }

    private func practiceContent(compact: Bool) -> some View {
        VStack(spacing: Theme.Space.regular) {
            header(compact: compact)
                .fixedSize(horizontal: false, vertical: true)
            instrumentRow
                .fixedSize(horizontal: false, vertical: true)
            TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !session.running)) { timeline in
                let frame = session.patternFrame(at: timeline.date)
                let scored = session.running && !session.listen && frame.countdown == nil
                PatternField(lesson: session.practiceLesson, hits: session.patternHits,
                             position: frame.position, tapePosition: frame.tapePosition,
                             running: session.running && frame.countdown == nil,
                             hidden: session.fromMemory && session.running && !session.listen,
                             scrolling: scrolling, visibleBars: [1, 2, 4].contains(visibleBars) ? visibleBars : 4,
                             verdicts: session.barVerdicts,
                             judgments: session.hitJudgments, bpm: frame.bpm,
                             playedHits: session.playedHits, pass: frame.pass,
                             scoring: session.running && !session.listen && frame.countdown == nil,
                             missGraceSteps: frame.missGraceSteps, countdown: frame.countdown,
                             band: BandTone.color(listen: session.listen,
                                                  memory: session.fromMemory && !session.listen,
                                                  bpm: session.bpm, startBpm: session.lesson.startBpm,
                                                  targetBpm: session.lesson.targetBpm),
                             edgeTendency: scored ? BandTone.edgeTendency(session.timingHistory, at: timeline.date) : 0)
            }
            .frame(minHeight: 160,
                   maxHeight: .infinity)
            .layoutPriority(-1)
            if session.summary == nil {
                HitTimingBar(history: session.timingHistory, windows: session.timingWindows,
                             active: session.running && !session.listen && session.countdown == nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            result
                .fixedSize(horizontal: false, vertical: true)
            if let error = session.errorMessage {
                Text(error).font(Theme.meta).foregroundStyle(Theme.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func starAnnouncement(for event: StarEvent) -> String {
        let names = [settings.localized("Passed"), settings.localized("Goal tempo"), settings.localized("From memory")]
        return names.indices.filter { event.award.fresh[$0] }.map {
            settings.localized("Star earned: %@", names[$0])
        }.joined(separator: ". ")
    }

    private func header(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HStack(spacing: Theme.Space.regular) {
                Button {
                    session.stop()
                    if let dismissLesson { dismissLesson() } else { dismiss() }
                } label: {
                    Label(settings.localized("Library"), systemImage: "square.grid.2x2")
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .buttonStyle(InstrumentButtonStyle())
                VStack(alignment: .leading, spacing: Theme.Space.tight) {
                    Text(settings.localized(session.lesson.title)).font(Theme.rowTitle).fixedSize(horizontal: false, vertical: true)
                    Text("\(Theme.sentenceCase(settings.localized(lessonCategoryTitle))) · \(Theme.sentenceCase(settings.localized("Level"))) \(session.lesson.level)")
                        .font(Theme.meta).foregroundStyle(Theme.secondary).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if !compact { tools }
            }
            if compact {
                ScrollView(.horizontal) { HStack { Spacer(minLength: 0); tools } }
                    .fixedSize(horizontal: false, vertical: true)
                    .scrollBounceBehavior(.basedOnSize)
            }
        }
    }

    private var tools: some View {
        HStack(spacing: Theme.Space.regular) {
            HStack(spacing: 0) {
                Button(settings.localized("Listen")) { session.listen = true }
                    .buttonStyle(InstrumentButtonStyle(selected: session.listen))
                Button(settings.localized("Play")) { session.listen = false }
                    .buttonStyle(InstrumentButtonStyle(selected: !session.listen))
            }
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .disabled(session.running)
            .accessibilityLabel(settings.localized("Lesson mode"))

            HStack(spacing: Theme.Space.small) {
                icon("eye.slash", settings.localized("From memory"), selected: session.fromMemory) {
                    session.fromMemory.toggle()
                }
                .disabled(session.running)
                .accessibilityValue(settings.localized(session.fromMemory ? "On" : "Off"))

                toolSeparator

                HStack(spacing: 0) {
                    icon("rectangle.split.2x2", settings.localized("Static view"), selected: !scrolling) { scrolling = false }
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
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var toolSeparator: some View {
        Rectangle().fill(Theme.hairline).frame(width: 1, height: 28)
            .accessibilityHidden(true)
    }

    private func icon(_ symbol: String, _ text: String, selected: Bool = false,
                      action: @escaping () -> Void) -> some View {
        PracticeIconButton(symbol: symbol, title: text, selected: selected, action: action)
    }

    /// Tempo left, this run's accuracy right; everything else lives behind Details or the legend.
    private var instrumentRow: some View {
        HStack(alignment: .center, spacing: Theme.Space.regular) {
            TempoTile(bpm: session.bpm, targetBpm: session.lesson.targetBpm, editable: !session.running) {
                showingTempo.toggle()
            }
            .popover(isPresented: $showingTempo) {
                tempoControls.padding(Theme.Space.page).background(Theme.background)
            }
            ZStack(alignment: .leading) {
                Color.clear
                if session.running, session.countdown == nil, let event = session.tempoUpEvent {
                    TempoUpBanner(event: event,
                                  label: settings.localized("Tempo up: %lld → %lld BPM", event.from, event.to),
                                  announcement: settings.localized("Tempo %lld", event.to))
                        .id(event.id)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            Spacer(minLength: 0)
            if let progress = session.starRunProgress {
                Text(settings.localized("%lld / %lld", progress.count, progress.required))
                    .font(Theme.meta).foregroundStyle(Theme.secondary)
                    .accessibilityLabel(settings.localized("Consecutive passes for %@", settings.localized(progress.name)))
                    .accessibilityValue(settings.localized("%lld / %lld", progress.count, progress.required))
            }
        }
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
            Text(settings.localized("Tempo")).font(Theme.screenTitle)
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

    @ViewBuilder
    private var result: some View {
        if let summary = session.summary, !session.running {
            ResultCard(summary: summary, saved: session.savedProgress,
                       event: session.starEvent,
                       announcement: session.starEvent.map(starAnnouncement) ?? "",
                       detail: { showingDetails = true }, rules: { showingStarRules = true }) {
                resultActions
            }
            .popover(isPresented: $showingDetails) { runDetails(summary) }
            .popover(isPresented: $showingStarRules) { starRules }
        }
    }

    @ViewBuilder
    private var resultActions: some View {
        if showsMemoryChallenge {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Space.small) {
                    memoryChallengeControl
                    nextLessonControl
                }
                VStack(alignment: .trailing, spacing: Theme.Space.small) {
                    memoryChallengeControl
                    nextLessonControl
                }
            }
        } else if session.savedProgress?.passed == true {
            nextLessonControl
        }
    }

    private var memoryChallengeControl: some View {
        Button(action: startMemoryChallenge) {
            Text(settings.localized("From memory for ★3"))
        }
        .buttonStyle(MemoryChallengeButtonStyle())
        .accessibilityHint(settings.localized("Starts Play from memory for the 3rd star"))
    }

    private var footer: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .bottom, spacing: Theme.Space.page) {
                footerContent
                Spacer(minLength: 0)
                transport
            }
            VStack(alignment: .trailing, spacing: Theme.Space.small) {
                HStack(alignment: .bottom) { footerContent; Spacer(minLength: 0) }
                transport
            }
        }
    }

    private var transport: some View {
        transport(width: Theme.Size.transportWidth)
    }

    private func transport(width: CGFloat) -> some View {
        TransportControls(running: session.running, enabled: session.ready && session.available,
                          showsResult: session.summary != nil && !session.running,
                          preferredWidth: width,
                          start: { showingInfo = false; session.start() },
                          stop: session.stop,
                          restart: { showingInfo = false; session.restart() })
    }

    /// After the 2nd star and until the 3rd: a direct way into the from-memory run.
    private var showsMemoryChallenge: Bool {
        session.ready && session.available && session.savedProgress?.mastery == true
            && session.savedProgress?.memory != true
    }

    private func startMemoryChallenge() {
        showingInfo = false
        session.dismissSummary()
        session.listen = false
        session.fromMemory = true
        session.start()
    }

    private var nextLesson: Lesson? {
        progression.nextLesson(after: session.lesson,
                               source: NextLessonSource(rawValue: settings.nextLessonSource) ?? .path)
    }

    @ViewBuilder
    private var nextLessonControl: some View {
        if let next = nextLesson {
            Button { openNextLesson(next) } label: {
                Label(settings.localized("Next lesson"), systemImage: store.isUnlocked(next) ? "arrow.right" : "lock")
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .buttonStyle(PracticeNextButtonStyle())
            .accessibilityHint(settings.localized(next.title))
        } else {
            Button(settings.localized("Next lesson")) {}
                .buttonStyle(PracticeNextButtonStyle())
                .disabled(true)
                .accessibilityHint(settings.localized("No next lesson available"))
        }
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

    @ViewBuilder
    private var footerContent: some View {
        if showPads, let pads = midi.padIndices {
            PadLayoutGrid(
                pads: pads,
                used: Set(session.patternHits.map(\.padIndex)),
                flashes: session.padFlashes,
                showKeyboardKeys: midi.isKeyboardConnected && settings.playPadsWithKeyboard && midi.activeProfile.isSixteenPad
            )
        }
        sessionStatus
    }

    @ViewBuilder
    private var sessionStatus: some View {
        if !session.available {
            Text(settings.localized("This lesson requires 16 pads."))
                .font(Theme.control)
        } else if !session.ready {
            Text(settings.localized("Preparing sound…")).font(Theme.control)
        } else if session.fromMemory && !session.running && !session.listen {
            Text(settings.localized("From memory · notes hide once you start"))
                .font(Theme.meta)
        }
    }

    private func runDetails(_ summary: RunSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.regular) {
                Text(settings.localized("Practice summary")).font(Theme.screenTitle)
                if let star = summary.finishedByStar {
                    Text(settings.localized(star == 3
                        ? "Run finished: star 3 earned, from memory"
                        : "Run finished: star 2 earned, goal tempo"))
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
            .font(Theme.control).padding(Theme.Space.page).frame(maxWidth: 440)
            .foregroundStyle(Theme.ink).background(Theme.background)
        }
        .frame(idealWidth: 440, maxHeight: 600)
    }

    private var starRules: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.regular) {
                Text(settings.localized("Star requirements")).font(Theme.sectionTitle)
                ForEach(0..<3, id: \.self) { index in
                    HStack(alignment: .top, spacing: Theme.Space.small) {
                        Image(systemName: isStarEarned(index) ? "star.fill" : "star")
                            .foregroundStyle(isStarEarned(index) ? PracticeBandStyle.orange : Theme.ink)
                            .frame(width: 24, height: 24)
                            .accessibilityHidden(true)
                        Text(StarRequirement.requirementText(for: index, lesson: session.lesson,
                            padCount: midi.activeProfile.padCount, settings: settings))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(Theme.control)
                }
                Button(settings.localized("Close")) { showingStarRules = false }
                    .font(Theme.control).frame(minHeight: Theme.Size.touch)
            }
            .padding(Theme.Space.page)
        }
        .frame(width: 420, height: 360)
        .foregroundStyle(Theme.ink).background(Theme.background)
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
                    Text(settings.localized("All bars")).tag(4)
                }
                Toggle(settings.localized("Small pad layout"), isOn: $showPads)
                Toggle(settings.localized("Pattern sound in Play"), isOn: $session.lessonSound)
                    .disabled(session.running)
                Toggle(settings.localized("Metronome"), isOn: $session.metronome).disabled(session.running)
                Picker(settings.localized("Tempo step after a clean pass"), selection: $settings.bpmStep) {
                    ForEach(BpmStep.allCases) { step in Text("+\(step.rawValue) BPM").tag(step.rawValue) }
                }.disabled(session.running)
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
            }.disabled(session.running)
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
