import SwiftUI

@MainActor
struct PracticeScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissLesson) private var dismissLesson
    @Environment(\.accessibilityReduceMotion) private var reduced
    private var motion: Theme.Motion.Policy { .init(reduced: reduced) }
    @Environment(\.scenePhase) private var scenePhase
    @Environment(SettingsManager.self) private var settings
    @Environment(MIDIInput.self) private var midi
    @State private var session: PracticeSession
    @AppStorage("smackapad.practice.scrolling") private var scrolling = false
    @AppStorage("smackapad.practice.visibleBars") private var visibleBars = 4
    @AppStorage("smackapad.practice.showPads") private var showPads = true
    @State private var showingLegend = false
    @State private var showingTools = false
    @State private var showingTempo = false
    @State private var showingDetails = false
    @State private var showingMIDI = false
    @State private var showingMemoryHint = false
    @State private var showingInfo = false

    init(lesson: Lesson, settings: SettingsManager, progress: ProgressStore, midi: MIDIInput) {
        _session = State(initialValue: PracticeSession(lesson: lesson, settings: settings, progress: progress, midi: midi))
    }

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 1_000
            VStack(spacing: Theme.Space.regular) {
                header(compact: compact)
                status(compact: compact)
                TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !session.running)) { _ in
                    PatternField(lesson: session.practiceLesson, hits: session.patternHits,
                                 position: session.position, running: session.running && session.countdown == nil,
                                 hidden: session.fromMemory && session.running && !session.listen,
                                 scrolling: scrolling, visibleBars: [1, 2, 4].contains(visibleBars) ? visibleBars : 4,
                                 verdicts: session.barVerdicts,
                                 judgments: session.hitJudgments, bpm: session.bpm,
                                 playedHits: session.playedHits, pass: session.passNumber,
                                 scoring: session.running && !session.listen && session.countdown == nil,
                                 missGraceSteps: session.missGraceSteps, countdown: session.countdown)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    Theme.background.opacity(session.starEvent == nil ? 0 : 0.18)
                        .allowsHitTesting(false)
                        .motion(Theme.Motion.standard, value: session.starEvent?.id)
                }
                .overlay(alignment: session.starEvent?.award.shouldStop == true ? .center : .topTrailing) {
                    if let event = session.starEvent {
                        StarBurst(event: event, announcement: starAnnouncement(for: event))
                            .id(event.id)
                            .padding(Theme.Space.regular)
                    }
                }
                footer(compact: compact)
                    .motion(Theme.Motion.emphasis, value: session.summary?.id)
                if let error = session.errorMessage {
                    Text(error).font(Theme.meta).foregroundStyle(Theme.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(Theme.Space.page)
            .background(Theme.background.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await session.prepare()
            checkMemoryHint()
        }
        .onDisappear {
            dismissMemoryHint()
            session.close()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { session.resume() } else { session.suspend() }
        }
        .onChange(of: settings.activeProfileName) { _, _ in session.stop() }
        .onChange(of: session.running) { _, running in
            if running {
                dismissMemoryHint()
                showingInfo = false
            } else {
                checkMemoryHint()
            }
        }
        .onChange(of: session.fromMemory) { _, memory in
            if memory { dismissMemoryHint() }
        }
        .onChange(of: showingMIDI) { _, showing in
            if showing { session.suspend() }
        }
        .sheet(isPresented: $showingMIDI, onDismiss: { session.resume() }) {
            MIDISettingsView()
                .presentationDragIndicator(.visible)
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
                icon(.back, settings.localized("Back to lessons")) { session.stop(); if let dismissLesson { dismissLesson() } else { dismiss() } }
                VStack(alignment: .leading, spacing: Theme.Space.tight) {
                    Text(settings.localized(session.lesson.title)).font(Theme.screenTitle).lineLimit(2)
                    Text("\(session.lesson.cat.uppercased()) · \(settings.localized("LEVEL")) \(session.lesson.level)")
                        .font(Theme.meta).foregroundStyle(Theme.secondary).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if !compact { tools }
            }
            if compact { HStack { Spacer(minLength: 0); tools } }
        }
    }

    private var tools: some View {
        HStack(spacing: Theme.Space.small) {
            HStack(spacing: 0) {
                Button(settings.localized("Listen")) { session.listen = true }
                    .buttonStyle(InstrumentButtonStyle(selected: session.listen))
                Button(settings.localized("Play")) { session.listen = false }
                    .buttonStyle(InstrumentButtonStyle(selected: !session.listen))
            }
            .disabled(session.running)
            .accessibilityLabel(settings.localized("Lesson mode"))
            Menu {
                ForEach([1, 2, 4], id: \.self) { count in
                    Button(count == 4 ? settings.localized("All bars") : settings.localized("%lld bars", count)) {
                        visibleBars = count; scrolling = false
                    }
                }
            } label: {
                PracticeGlyph(kind: .grid).frame(width: 24, height: 24)
            }
            .buttonStyle(InstrumentButtonStyle(selected: !scrolling))
            .accessibilityLabel(settings.localized("Static view, bar count"))
            icon(.scrolling, settings.localized("Scrolling view"), selected: scrolling) { scrolling = true }
            icon(.eye, settings.localized("From memory"), selected: session.fromMemory) {
                dismissMemoryHint()
                session.fromMemory.toggle()
            }
                .disabled(session.running)
                .accessibilityValue(session.fromMemory ? settings.localized("On") : settings.localized("Off"))
                .overlay(alignment: .bottom) {
                    if showingMemoryHint {
                        memoryHintCallout
                            .alignmentGuide(.bottom) { d in d[.top] - 6 }
                    }
                }
            if !session.running {
                icon(.info, settings.localized("Lesson info")) { showingInfo.toggle() }
                    .popover(isPresented: $showingInfo, arrowEdge: .top) { lessonInfo }
            }
            icon(.legend, settings.localized("Legend")) { showingLegend.toggle() }
                .popover(isPresented: $showingLegend, arrowEdge: .top) { legend }
            icon(.tools, settings.localized("More tools")) { showingTools.toggle() }
                .popover(isPresented: $showingTools, arrowEdge: .top) {
                    PracticeTools(session: session, showPads: $showPads, openMIDI: {
                        showingTools = false; showingMIDI = true
                    })
                }
        }
    }

    private func icon(_ kind: PracticeGlyph.Kind, _ text: String, selected: Bool = false,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) { PracticeGlyph(kind: kind).frame(width: 24, height: 24) }
            .buttonStyle(InstrumentButtonStyle(selected: selected))
            .accessibilityLabel(text)
            .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func status(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HStack(spacing: Theme.Space.regular) {
                Button { showingTempo.toggle() } label: {
                    Text("\(session.bpm) → \(session.lesson.targetBpm) BPM").font(Theme.control)
                        .contentTransition(motion.numeric).motion(value: session.bpm)
                }
                .buttonStyle(InstrumentButtonStyle())
                .opacity(session.running ? 0.45 : 1)
                .disabled(session.running)
                .popover(isPresented: $showingTempo) {
                    tempoControls.padding(Theme.Space.page).background(Theme.background)
                }
                // The slot includes room for the pulse. It stays reserved throughout a run.
                if session.running {
                    ZStack {
                        Color.clear
                        if session.countdown == nil, let event = session.tempoUpEvent {
                            TempoUpBanner(event: event,
                                          label: settings.localized("Tempo up: %lld → %lld BPM", event.from, event.to),
                                          announcement: settings.localized("Tempo %lld", event.to))
                                .id(event.id)
                                .frame(width: 220)
                        }
                    }
                    .frame(width: 240, height: Theme.Size.touch)
                }
                Text(session.listen ? "— %" : session.lastResult.map { "\(Int(($0.score * 100).rounded())) %" } ?? "— %")
                    .font(Theme.control).fixedSize()
                    .accessibilityLabel(settings.localized("Score"))
                Spacer(minLength: 0)
                if !compact { handLegend }
            }
            HStack(spacing: Theme.Space.regular) {
                TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !session.running)) { _ in
                    let total = max(16, session.practiceLesson.bars * 16)
                    let position = session.position
                    VStack(alignment: .leading, spacing: Theme.Space.tight) {
                        Text(settings.localized("Bar %lld / %lld", min(session.practiceLesson.bars, Int(position) / 16 + 1),
                                                session.practiceLesson.bars))
                            .font(Theme.meta)
                        ProgressView(value: position / Double(total))
                            .tint(Theme.ink)
                            .accessibilityLabel(settings.localized("Position in the current pass"))
                    }
                    .frame(width: 160)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(settings.localized("Position in the current pass"))
                    .accessibilityValue(settings.localized("Bar %lld / %lld, %lld percent",
                        min(session.practiceLesson.bars, Int(position) / 16 + 1), session.practiceLesson.bars,
                        Int(position / Double(total) * 100)))
                }
                if let progress = session.starRunProgress {
                    Text(settings.localized("%lld / %lld", progress.count, progress.required))
                        .font(Theme.meta).foregroundStyle(Theme.secondary)
                        .accessibilityLabel(settings.localized("Consecutive passes for %@", settings.localized(progress.name)))
                        .accessibilityValue(settings.localized("%lld / %lld", progress.count, progress.required))
                }
                Spacer(minLength: 0)
            }
            .opacity(session.countdown == nil ? 1 : 0)
            .accessibilityHidden(session.countdown != nil)
        }
    }

    private var handLegend: some View {
        HStack(spacing: Theme.Space.regular) {
            HStack(spacing: Theme.Space.small) {
                Rectangle().fill(Theme.black).frame(width: 12, height: 18)
                    .overlay(Rectangle().stroke(Theme.white, lineWidth: 1))
                Text(settings.localized("left"))
            }
            HStack(spacing: Theme.Space.small) {
                Rectangle().fill(Theme.white).frame(width: 12, height: 18)
                    .overlay(Rectangle().stroke(Theme.black, lineWidth: 1))
                Text(settings.localized("right"))
            }
        }
        .font(Theme.control)
    }

    private var tempoControls: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            Text(settings.localized("Tempo")).font(Theme.screenTitle)
            Text("\(session.bpm) → \(session.lesson.targetBpm) BPM").font(Theme.control)
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
    private func footer(compact: Bool) -> some View {
        if compact {
            VStack(alignment: .trailing, spacing: Theme.Space.small) {
                HStack(alignment: .bottom) { footerContent; Spacer(minLength: 0) }
                transport
            }
        } else {
            HStack(alignment: .bottom, spacing: Theme.Space.page) {
                footerContent
                Spacer(minLength: 0)
                transport
            }
        }
    }

    private var transport: some View {
        TransportControls(running: session.running, enabled: session.ready && session.available,
                          start: { dismissMemoryHint(); showingInfo = false; session.start() },
                          stop: session.stop,
                          restart: { dismissMemoryHint(); showingInfo = false; session.restart() })
    }

    @ViewBuilder
    private var footerContent: some View {
        if showPads, let pads = midi.padIndices {
            PadLayoutGrid(pads: pads, used: Set(session.patternHits.map(\.padIndex)), flashes: session.padFlashes)
        }
        if let summary = session.summary {
            let nextStar = StarRequirement.nextMissingStarText(
                progress: session.savedProgress,
                lesson: session.lesson,
                padCount: midi.activeProfile.padCount,
                settings: settings
            )
            SummaryStrip(summary: summary, nextStarText: nextStar, dismiss: session.dismissSummary) { showingDetails = true }
                .id(summary.id)
                .transition(motion.summary)
                .popover(isPresented: $showingDetails) {
                    VStack(alignment: .leading, spacing: Theme.Space.regular) {
                        Text(settings.localized("Practice summary")).font(Theme.screenTitle)
                        Text("\(summary.bpm) BPM · \(settings.localized("%lld completed passes", summary.passes))")
                        Text(settings.localized("Stars: passed / goal tempo / from memory"))
                        Text(settings.localized("Score is from the last completed pass. Stars are earned across this run."))
                    }
                    .font(Theme.control).padding(Theme.Space.page).frame(maxWidth: 440)
                    .foregroundStyle(Theme.ink).background(Theme.background)
                }
        } else if !session.available {
            Text(settings.localized("This lesson requires 16 pads."))
                .font(Theme.control)
        } else if !session.ready {
            Text(settings.localized("Preparing sound…")).font(Theme.control)
        } else if session.fromMemory && !session.running && !session.listen {
            Text(settings.localized("From memory · notes hide after START"))
                .font(Theme.meta)
        }
    }

    private func checkMemoryHint() {
        guard !session.running,
              !session.fromMemory,
              session.savedProgress?.mastery == true,
              session.savedProgress?.memory != true,
              !settings.hasShownMemoryHint(for: session.lesson.id) else {
            showingMemoryHint = false
            return
        }
        showingMemoryHint = true
    }

    private func dismissMemoryHint() {
        if showingMemoryHint {
            showingMemoryHint = false
            settings.markMemoryHintShown(for: session.lesson.id)
        }
    }

    private var memoryHintCallout: some View {
        Button(action: dismissMemoryHint) {
            VStack(spacing: 2) {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: Theme.Space.small) {
                    PracticeGlyph(kind: .eye).frame(width: 16, height: 16)
                    Text(settings.localized("For the 3rd star, turn on From memory"))
                        .font(Theme.meta)
                        .foregroundStyle(Theme.ink)
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.secondary)
                }
                .padding(.horizontal, Theme.Space.small)
                .frame(minHeight: Theme.Size.touch)
                .background(Theme.background)
                .overlay(Rectangle().stroke(Theme.ink, lineWidth: 1))
            }
            .fixedSize()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(settings.localized("For the 3rd star, turn on From memory"))
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
            }
            .padding(Theme.Space.page)
        }
        .frame(width: 420, height: min(620, CGFloat(Set(session.patternHits.map { "\($0.padIndex):\($0.hand)" }).count) * 64 + 160))
        .foregroundStyle(Theme.ink).background(Theme.background)
    }

    private var lessonInfo: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.regular) {
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
                    Text("\(settings.localized("LEVEL")) \(session.lesson.level) · \(barsText) · \(session.lesson.startBpm) → \(session.lesson.targetBpm) BPM")
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary)
                }

                if !session.lesson.text.isEmpty {
                    Text(settings.localized(session.lesson.text))
                        .font(Theme.control)
                }

                if let intro = session.lesson.intro {
                    if !intro.goal.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Space.tight) {
                            Text(settings.localized("Goal")).font(Theme.rowTitle)
                            Text(settings.localized(intro.goal)).font(Theme.control)
                        }
                    }
                    if !intro.watch.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Space.tight) {
                            Text(settings.localized("Watch for")).font(Theme.rowTitle)
                            Text(settings.localized(intro.watch)).font(Theme.control)
                        }
                    }
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

                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    Text(settings.localized("How to earn the stars")).font(Theme.rowTitle)
                    ForEach(0..<3, id: \.self) { index in
                        let earned = isStarEarned(index)
                        let reqText = StarRequirement.requirementText(
                            for: index,
                            lesson: session.lesson,
                            padCount: midi.activeProfile.padCount,
                            settings: settings
                        )
                        HStack(spacing: Theme.Space.small) {
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
    let openMIDI: () -> Void
    @AppStorage("smackapad.practice.appearance") private var appearance = "dark"

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section(settings.localized("Practice")) {
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
                Picker(settings.localized("Appearance"), selection: $appearance) {
                    Text(settings.localized("Dark")).tag("dark")
                    Text(settings.localized("Light")).tag("light")
                }
            }
            Button(settings.localized("MIDI and controller"), action: openMIDI).disabled(session.running)
        }
        .font(Theme.control).tint(Theme.ink)
        .frame(width: 480, height: 640)
        .scrollContentBackground(.hidden).background(Theme.background).foregroundStyle(Theme.ink)
    }
}
