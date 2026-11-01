import SwiftUI

@MainActor
struct PracticeScreen: View {
    @Environment(\.dismiss) private var dismiss
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
                                 hidden: session.fromMemory && session.running,
                                 scrolling: scrolling, visibleBars: [1, 2, 4].contains(visibleBars) ? visibleBars : 4,
                                 verdicts: session.barVerdicts,
                                 judgments: session.hitJudgments,
                                 scoring: session.running && !session.listen && session.countdown == nil,
                                 missGraceSteps: session.missGraceSteps, countdown: session.countdown)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: session.starEvent?.award.shouldStop == true ? .center : .topTrailing) {
                    if let event = session.starEvent {
                        StarBurst(event: event, announcement: starAnnouncement(for: event))
                            .id(event.id)
                            .padding(Theme.Space.regular)
                    }
                }
                footer(compact: compact)
                if let error = session.errorMessage {
                    Text(error).font(Theme.text(Theme.Size.small)).foregroundStyle(Theme.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(Theme.Space.page)
            .background(Theme.background.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await session.prepare() }
        .onDisappear { session.close() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { session.resume() } else { session.suspend() }
        }
        .onChange(of: settings.activeProfileName) { _, _ in session.stop() }
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
                icon(.back, settings.localized("Back to lessons")) { session.stop(); dismiss() }
                VStack(alignment: .leading, spacing: Theme.Space.tight) {
                    Text(session.lesson.title).font(Theme.display()).lineLimit(2)
                    Text("\(session.lesson.cat.uppercased()) · \(settings.localized("LEVEL")) \(session.lesson.level)")
                        .font(Theme.text(Theme.Size.small)).foregroundStyle(Theme.secondary).lineLimit(1)
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
            icon(.eye, settings.localized("From memory"), selected: session.fromMemory) { session.fromMemory.toggle() }
                .disabled(session.running)
                .accessibilityValue(session.fromMemory ? settings.localized("On") : settings.localized("Off"))
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
        HStack(spacing: compact ? Theme.Space.regular : Theme.Space.wide) {
            Button { showingTempo.toggle() } label: {
                Text("\(session.bpm) → \(session.lesson.targetBpm) BPM").font(Theme.text())
            }
            .buttonStyle(InstrumentButtonStyle())
            .opacity(session.running ? 0.45 : 1)
            .disabled(session.running)
            .popover(isPresented: $showingTempo) {
                tempoControls.padding(Theme.Space.page).background(Theme.background)
            }
            Text(session.listen ? "— %" : session.lastResult.map { "\(Int(($0.score * 100).rounded())) %" } ?? "— %")
                .font(Theme.text()).accessibilityLabel(settings.localized("Score"))
            Spacer(minLength: 0)
            if !compact {
                handLegend
            }
        }
        .lineLimit(1)
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
        .font(Theme.text())
    }

    private var tempoControls: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            Text(settings.localized("Tempo")).font(Theme.display())
            Text("\(session.bpm) → \(session.lesson.targetBpm) BPM").font(Theme.text())
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
                          start: session.start, stop: session.stop, restart: session.restart)
    }

    @ViewBuilder
    private var footerContent: some View {
        if showPads, let pads = midi.padIndices {
            PadLayoutGrid(pads: pads, used: Set(session.patternHits.map(\.padIndex)), flashes: session.padFlashes)
        }
        if let summary = session.summary {
            SummaryStrip(summary: summary) { showingDetails = true }
                .popover(isPresented: $showingDetails) {
                    VStack(alignment: .leading, spacing: Theme.Space.regular) {
                        Text(settings.localized("Practice summary")).font(Theme.display())
                        Text("\(summary.bpm) BPM · \(settings.localized("%lld completed passes", summary.passes))")
                        Text(settings.localized("Stars: passed / goal tempo / from memory"))
                        Text(settings.localized("Score is from the last completed pass. Stars are earned across this run."))
                    }
                    .font(Theme.text()).padding(Theme.Space.page).frame(maxWidth: 440)
                    .foregroundStyle(Theme.ink).background(Theme.background)
                }
        } else if !session.available {
            Text(settings.localized("This lesson requires 16 pads."))
                .font(Theme.text())
        } else if !session.ready {
            Text(settings.localized("Preparing sound…")).font(Theme.text())
        } else if session.fromMemory && !session.running {
            Text(settings.localized("From memory · notes hide after START"))
                .font(Theme.text(Theme.Size.small))
        }
    }

    private var legend: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.regular) {
                HStack {
                    Text(settings.localized("Pad legend")).font(Theme.display(Theme.Size.emphasis))
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
                            .font(Theme.text())
                    }
                }
                handLegend
            }
            .padding(Theme.Space.page)
        }
        .frame(width: 420, height: min(620, CGFloat(Set(session.patternHits.map { "\($0.padIndex):\($0.hand)" }).count) * 64 + 160))
        .foregroundStyle(Theme.ink).background(Theme.background)
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
                Picker(settings.localized("Sound kit"), selection: $settings.selectedKitId) {
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
        .font(Theme.text()).tint(Theme.ink)
        .frame(width: 480, height: 640)
        .scrollContentBackground(.hidden).background(Theme.background).foregroundStyle(Theme.ink)
    }
}
