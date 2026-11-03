//
//  SettingsView.swift
//  SmackAPad
//
//  Settings screen: kit selection, BPM step, controller profile management,
//  MIDI learn trigger, and language switch.
//

import CoreAudioKit
import SwiftUI
#if DEBUG
import UniformTypeIdentifiers
#endif

@MainActor
public struct SettingsView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(MIDIInput.self) private var midi
    @Environment(\.dismiss) private var dismiss

    @State private var showingMIDILearn = false
    @State private var profileToDelete: ControllerProfile?
    @State private var showingDeleteAlert = false
    @State private var showingControlPadWarning = false
    @State private var kits: [SampleKit] = []
    @AppStorage("smackapad.practice.showPads") private var showPads = true
    @AppStorage("smackapad.practice.visibleBars") private var visibleBars = 4

    public init() {}

    public var body: some View {
        @Bindable var settings = settings
        @Bindable var midi = midi

        NavigationStack {
            Form {
                Group {
                    PurchasesSection()
                    #if DEBUG
                    LegacyProgressImportSection()
                    #endif

                    // MARK: 1. Kit Selection
                    Section {
                        Picker(settings.localized("Sound kit"), selection: $settings.selectedKitId) {
                            Text(settings.localized("Automatic")).font(Theme.rowTitle).tag("auto")
                            ForEach(kits) { kit in
                                Text(kit.name).font(Theme.rowTitle).tag(kit.kitId)
                            }
                        }
                        .pickerStyle(.menu)
                    } header: {
                        SectionHeader(title: settings.localized("SOUND KIT"))
                    } footer: {
                        Text(settings.localized("All 8 kits are bundled with the app for practice and playback."))
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                    }

                    // MARK: 1b. Sound Volumes
                    Section {
                        VolumeSliderRow(
                            title: settings.localized("Metronome"),
                            value: $settings.metronomeVolume
                        )
                        VolumeSliderRow(
                            title: settings.localized("Pads"),
                            value: $settings.padsVolume
                        )
                        VolumeSliderRow(
                            title: settings.localized("Pattern sound"),
                            value: $settings.patternVolume
                        )
                    } header: {
                        SectionHeader(title: settings.localized("SOUND"))
                    } footer: {
                        Text(settings.localized("Separate volume for metronome, pads and pattern playback."))
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                    }

                    // MARK: 2. BPM Step
                    Section {
                        PlexSegmentedPicker(title: settings.localized("Tempo step"), selection: $settings.bpmStep,
                            options: BpmStep.allCases.map { ($0.rawValue, "+\($0.rawValue) BPM") })
                    } header: {
                        SectionHeader(title: settings.localized("TEMPO AUTO-STEP (BPM)"))
                    } footer: {
                        Text(settings.localized("Tempo automatically increases by this step after each clean pass until target tempo."))
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                    }

                    Section {
                        Picker(settings.localized("Practice mode"), selection: $settings.practiceMode) {
                            ForEach(PracticeMode.allCases, id: \.self) { mode in
                                Text(settings.localized(mode.title)).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(minHeight: Theme.Size.touch)
                    } header: {
                        SectionHeader(title: settings.localized("Practice mode"))
                    } footer: {
                        Text(settings.localized(settings.practiceMode.explanation))
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                    }

                    // MARK: 2b. Pad layout on the practice screen
                    Section {
                        Picker(settings.localized("Bars shown"), selection: $visibleBars) {
                            Text(settings.localized("1 bar")).tag(1)
                            Text(settings.localized("%lld bars", 2)).tag(2)
                            Text(settings.localized("All bars")).tag(4)
                        }
                        Toggle(settings.localized("Small pad layout"), isOn: $showPads)
                    } header: {
                        SectionHeader(title: settings.localized("PRACTICE SCREEN"))
                    } footer: {
                        Text(settings.localized("Shows a small pad layout in the lesson that lights up the pads you hit."))
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                    }

                    Section {
                        Picker(settings.localized("Next lesson from"), selection: $settings.nextLessonSource) {
                            ForEach(NextLessonSource.allCases) { source in
                                Text(settings.localized(source.title)).tag(source.id)
                            }
                        }
                        .frame(minHeight: Theme.Size.touch)
                    } header: {
                        SectionHeader(title: settings.localized("Next lesson from"))
                    }

                    // MARK: 3. Controller Profiles & MIDI Learn Trigger
                    Section {
                        ForEach(settings.allProfiles()) { profile in
                            ProfileRow(
                                profile: profile,
                                isActive: profile.profileName == settings.activeProfileName,
                                isCustom: settings.customProfiles.contains(where: { $0.profileName == profile.profileName }),
                                onSelect: {
                                    settings.activeProfileName = profile.profileName
                                },
                                onDelete: {
                                    profileToDelete = profile
                                    showingDeleteAlert = true
                                }
                            )
                        }

                        Button {
                            showingMIDILearn = true
                        } label: {
                            HStack {
                                Text(settings.localized("Learn a new profile (MIDI learn)"))
                                    .font(Theme.control)
                                Spacer()
                                Text("+")
                                    .font(Theme.rowTitle)
                            }
                            .frame(minHeight: Theme.Size.touch)
                            .foregroundStyle(Theme.orange)
                        }
                    } header: {
                        SectionHeader(title: settings.localized("CONTROLLER PROFILES"))
                    } footer: {
                        Text(settings.localized("Akai and Maschine presets use notes 36–51 starting from the bottom left. Use MIDI learn for other banks or mappings."))
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                    }

                    ControllerMappingSections()

                    // MARK: Keyboard
                    Section {
                        if midi.isKeyboardConnected {
                            Toggle(settings.localized("Play pads with keyboard"), isOn: $settings.playPadsWithKeyboard)
                                .tint(Theme.orange)
                        } else {
                            Text(settings.localized("No keyboard connected"))
                                .font(Theme.meta)
                                .foregroundStyle(Theme.secondary)
                        }

                        VStack(alignment: .leading, spacing: Theme.Space.tight) {
                            ForEach(KeyboardPadMapping.rows, id: \.rowNumber) { row in
                                if row.rowNumber > 1 {
                                    Divider()
                                }
                                HStack {
                                    Text(settings.localized(row.label))
                                        .font(Theme.meta)
                                        .foregroundStyle(Theme.secondary)
                                    Spacer()
                                    Text(row.keys.joined(separator: "   "))
                                        .font(Theme.control)
                                        .monospaced()
                                }
                                .frame(minHeight: 28)
                            }
                        }
                        .padding(.vertical, Theme.Space.tight)
                    } header: {
                        SectionHeader(title: settings.localized("KEYBOARD"))
                    }

                    // MARK: 4. Appearance
                    Section {
                        PlexSegmentedPicker(title: settings.localized("Appearance"), selection: $settings.appearance,
                            options: AppAppearance.allCases.map { ($0, settings.localized($0.title)) })
                    } header: {
                        SectionHeader(title: settings.localized("APPEARANCE"))
                    } footer: {
                        Text(settings.localized("Choose light, dark or follow your system appearance."))
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                    }

                    // MARK: 5. Language Switch
                    Section {
                        PlexSegmentedPicker(title: settings.localized("App language"), selection: $settings.languagePreference,
                            options: AppLanguage.allCases.map { ($0, $0.displayName) })
                    } header: {
                        SectionHeader(title: settings.localized("LANGUAGE"))
                    } footer: {
                        Text(settings.localized("Choose Czech or English. Your lesson progress and controller mappings remain preserved."))
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                    }

                    // MARK: 5. Hardware & Calibration
                    Section {
                        Picker(settings.localized("Input"), selection: $midi.selectedSourceID) {
                            Text(settings.localized("All connected controllers")).tag(String?.none)
                            ForEach(midi.sources) { source in
                                Text(source.name).tag(Optional(source.id))
                            }
                        }

                        if midi.sources.isEmpty {
                            Text(settings.localized("Connect a USB controller or pair a Bluetooth MIDI controller."))
                                .font(Theme.meta)
                                .foregroundStyle(Theme.secondary)
                        }

                        Button {
                            BluetoothMIDIPresenter.present()
                        } label: {
                            Text(settings.localized("Connect Bluetooth MIDI"))
                                .font(Theme.control)
                                .frame(minHeight: Theme.Size.touch)
                        }

                        if let error = midi.errorMessage {
                            Text(error)
                                .font(Theme.meta)
                                .foregroundStyle(Theme.markWrong)
                            Button(settings.localized("Reconnect MIDI")) {
                                midi.stop()
                                midi.start()
                            }
                        }

                        NavigationLink {
                            CalibrationView(settings: settings, midi: midi)
                        } label: {
                            HStack {
                                Text(settings.localized("Timing calibration"))
                                    .font(Theme.control)
                                Spacer()
                            }
                            .frame(minHeight: Theme.Size.touch)
                        }
                    } header: {
                        SectionHeader(title: settings.localized("HARDWARE & CALIBRATION"))
                    }

                    // MARK: 6. Input Monitor
                    Section {
                        LabeledContent(settings.localized("Received MIDI hits"), value: midi.noteOnCount.formatted())
                            .font(Theme.meta)
                        LabeledContent(settings.localized("Timestamp fallbacks"), value: midi.fallbackCount.formatted())
                            .font(Theme.meta)

                        if let message = midi.lastControlMessage, message.signal.kind == .cc {
                            LabeledContent(settings.localized("Message"), value: settings.localized("Control change"))
                                .font(Theme.meta)
                            LabeledContent(settings.localized("Channel"), value: message.signal.channel.formatted())
                                .font(Theme.meta)
                            LabeledContent(settings.localized("CC number"), value: message.signal.number.formatted())
                                .font(Theme.meta)
                            LabeledContent(settings.localized("Value"), value: message.value.formatted())
                                .font(Theme.meta)
                        } else if let note = midi.lastNote {
                            LabeledContent(settings.localized("MIDI note"), value: note.note.formatted())
                                .font(Theme.meta)
                            LabeledContent(settings.localized("Channel"), value: note.channel.formatted())
                                .font(Theme.meta)
                            LabeledContent(settings.localized("Velocity"), value: note.velocity.formatted())
                                .font(Theme.meta)
                            LabeledContent(settings.localized("Message"), value: note.isNoteOn ? settings.localized("Note on") : settings.localized("Note off"))
                                .font(Theme.meta)
                        } else {
                            Text(settings.localized("Play a pad to check the input."))
                                .font(Theme.meta)
                                .foregroundStyle(Theme.secondary)
                        }

                        if let pad = midi.lastPad {
                            LabeledContent(settings.localized("Mapped pad"), value: (pad.padIndex + 1).formatted())
                                .font(Theme.meta)
                        }
                    } header: {
                        SectionHeader(title: settings.localized("INPUT MONITOR"))
                    }

                    // MARK: 7. Touch Pads
                    Section {
                        if let pads = midi.padIndices {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Space.small), count: 4), spacing: Theme.Space.small) {
                                ForEach(Array(pads.enumerated()), id: \.offset) { slot, padIndex in
                                    TouchPad(
                                        number: slot + 1,
                                        sound: PadNames.name(for: padIndex),
                                        isActive: midi.pressedPadIndices.contains(padIndex)
                                    ) { pressed in
                                        midi.touch(padIndex: padIndex, isPressed: pressed)
                                    }
                                    .id("\(settings.activeProfileName)/\(slot)/\(padIndex)")
                                }
                            }
                            .padding(.vertical, Theme.Space.small)
                        } else {
                            Text(settings.localized("This lesson requires 16 pads."))
                                .font(Theme.meta)
                        }
                    } header: {
                        SectionHeader(title: settings.localized("TOUCH PADS"))
                    } footer: {
                        if midi.activeProfile.isEightPad {
                            Text(settings.localized("Eight physical slots follow the current lesson. Without a lesson, the base layout is shown."))
                                .font(Theme.meta)
                                .foregroundStyle(Theme.secondary)
                        } else {
                            Text(settings.localized("Touch pads send the same pad events as MIDI."))
                                .font(Theme.meta)
                                .foregroundStyle(Theme.secondary)
                        }
                    }

                    Section {
                        NavigationLink {
                            FontLicenceView()
                        } label: {
                            Text("SIL Open Font License 1.1").font(Theme.navigation)
                        }
                    } header: {
                        SectionHeader(title: "IBM Plex Sans")
                    }
                }
                .listRowBackground(Theme.surface)
                .listRowInsets(EdgeInsets(top: Theme.Space.small, leading: Theme.Space.regular,
                                         bottom: Theme.Space.small, trailing: Theme.Space.regular))
            }
            .appFormStyle()
            .navigationTitle(settings.localized("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { ScreenHeader(title: settings.localized("Settings")) }
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.localized("Done")) {
                        dismiss()
                    }
                    .font(Theme.control)
                    .frame(minHeight: Theme.Size.touch)
                }
            }
            .sheet(isPresented: $showingMIDILearn) {
                MIDILearnView()
                    .environment(settings)
                    .environment(midi)
            }
            .sheet(isPresented: $showingDeleteAlert) {
                if let profile = profileToDelete {
                    AppConfirmation(title: settings.localized("Delete profile \"%@\"?", profile.profileName),
                                    message: settings.localized("This custom profile will be permanently deleted.")) {
                        Button(settings.localized("Delete"), role: .destructive) {
                            settings.deleteProfile(named: profile.profileName)
                            showingDeleteAlert = false
                            profileToDelete = nil
                        }
                        Button(settings.localized("Cancel"), role: .cancel) {
                            showingDeleteAlert = false
                            profileToDelete = nil
                        }
                    }
                }
            }
            .task {
                loadKits()
            }
            .onChange(of: midi.pendingControlSignal) { _, signal in
                showingControlPadWarning = signal != nil
            }
            .sheet(isPresented: $showingControlPadWarning) {
                AppConfirmation(title: settings.localized("Use this pad as a controller button?"),
                                message: settings.localized("This pad will no longer play a sound.")) {
                    Button(settings.localized("Use for control")) {
                        midi.confirmControlMapping()
                        showingControlPadWarning = false
                    }
                    Button(settings.localized("Cancel"), role: .cancel) {
                        midi.cancelControlLearning()
                        showingControlPadWarning = false
                    }
                }
            }
            .onDisappear { midi.cancelControlLearning() }
        }
    }

    private func loadKits() {
        do {
            let loadedDict = try DataLoader.shared.loadSampleKits()
            let canonicalOrder = ["acoustic", "808", "jazz", "world", "rock", "brush", "worldperc", "house"]
            self.kits = loadedDict.values.sorted { lhs, rhs in
                let lIdx = canonicalOrder.firstIndex(of: lhs.kitId) ?? 999
                let rIdx = canonicalOrder.firstIndex(of: rhs.kitId) ?? 999
                if lIdx != rIdx { return lIdx < rIdx }
                return lhs.kitId < rhs.kitId
            }
        } catch {
            self.kits = []
        }
    }
}

@MainActor
private struct ProfileRow: View {
    @Environment(SettingsManager.self) private var settings
    let profile: ControllerProfile
    let isActive: Bool
    let isCustom: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ListRow(symbol: isActive ? "checkmark.circle.fill" : "circle",
                stateTitle: settings.localized(isActive ? "ACTIVE" : "Preset"),
                title: profile.profileName, action: onSelect) {
            Text("\(settings.localized(profile.padCount == 8 ? "8 pads" : "16 pads")) · \(settings.localized(isCustom ? "Custom" : "Preset"))")
        } trailing: {
            if isActive {
                Text(Theme.sentenceCase(settings.localized("ACTIVE"))).font(Theme.meta).foregroundStyle(Theme.orange)
            }
            if isCustom {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash").font(Theme.control).foregroundStyle(Theme.markWrong)
                        .frame(width: Theme.Size.touch, height: Theme.Size.touch)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.localized("Delete profile"))
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if isCustom {
                Button(role: .destructive, action: onDelete) {
                    Label(settings.localized("Delete"), systemImage: "trash")
                }
            }
        }
    }
}

private struct FontLicenceView: View {
    private static let licence: String = {
        guard let url = Bundle.main.url(forResource: "ibmplexsans-OFL", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            preconditionFailure("Missing bundled IBM Plex Sans licence")
        }
        return text
    }()

    var body: some View {
        ScrollView {
            Text(Self.licence)
                .font(Theme.meta)
                .lineSpacing(8)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 760, alignment: .leading)
                .padding(Theme.Space.page)
                .frame(maxWidth: .infinity)
        }
        .background(Theme.background).foregroundStyle(Theme.ink)
        .navigationTitle("IBM Plex Sans")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { ScreenHeader(title: "IBM Plex Sans") }
        }
    }
}

/// Shared Form sections keep controller assignments in the existing Settings style.
@MainActor
struct ControllerMappingSections: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(MIDIInput.self) private var midi
    @State private var advanced = false

    var body: some View {
        @Bindable var settings = settings
        Group {
            Section {
                actionRow(.startStop)
                DisclosureGroup(settings.localized("Advanced"), isExpanded: $advanced) {
                    ForEach(MIDIPracticeAction.allCases.filter { $0 != .startStop }, id: \.self) { action in
                        actionRow(action)
                    }
                }
            } header: {
                SectionHeader(title: settings.localized("Controller buttons"))
            } footer: {
                Text(settings.localized("Controller actions work only with an open practice lesson. Tempo changes only while stopped."))
                    .font(Theme.meta).foregroundStyle(Theme.secondary)
            }
            Section {
                mappingRow(title: "Tempo knob", signal: settings.midiControls.knob.signal, target: .knob)
                Picker(settings.localized("Knob mode"), selection: $settings.midiControls.knob.mode) {
                    ForEach(MIDIKnobMode.allCases, id: \.self) { mode in
                        Text(settings.localized(mode.title)).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                if settings.midiControls.knob.mode == .absolute {
                    Stepper(settings.localized("Minimum BPM: %lld", settings.midiControls.knob.minimumBpm),
                            value: $settings.midiControls.knob.minimumBpm,
                            in: PracticeTempo.minimumBpm...settings.midiControls.knob.maximumBpm)
                    Stepper(settings.localized("Maximum BPM: %lld", settings.midiControls.knob.maximumBpm),
                            value: $settings.midiControls.knob.maximumBpm,
                            in: settings.midiControls.knob.minimumBpm...PracticeTempo.maximumBpm)
                    Toggle(settings.localized("Pickup"), isOn: $settings.midiControls.knob.pickup)
                }
                Toggle(settings.localized("Reverse direction"), isOn: $settings.midiControls.knob.reversed)
            } header: {
                SectionHeader(title: settings.localized("Tempo knob"))
            } footer: {
                Text(settings.localized("Pickup waits until the knob reaches the current tempo. Relative steps change tempo by 1 BPM. Tempo changes only while stopped."))
                    .font(Theme.meta).foregroundStyle(Theme.secondary)
            }
        }

    }

    @ViewBuilder
    private func actionRow(_ action: MIDIPracticeAction) -> some View {
        let mapping = settings.midiControls.buttons[action.rawValue]
        mappingRow(title: action.title, signal: mapping?.signal, target: .action(action))
        if mapping?.signal.kind == .cc {
            Picker(settings.localized("CC button behaviour"), selection: Binding(
                get: { settings.midiControls.buttons[action.rawValue]?.behavior ?? .rising64 },
                set: { settings.midiControls.buttons[action.rawValue]?.behavior = $0 }
            )) {
                ForEach(MIDICCButtonBehavior.allCases, id: \.self) { behavior in
                    Text(settings.localized(behavior.title)).tag(behavior)
                }
            }
            .pickerStyle(.menu)
        }
    }

    @ViewBuilder
    private func mappingRow(title: String, signal: MIDIControlSignal?, target: MIDIControlLearnTarget) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HStack(spacing: Theme.Space.regular) {
                VStack(alignment: .leading, spacing: Theme.Space.tight) {
                    Text(settings.localized(title)).font(Theme.control)
                    Text(mappingText(signal)).font(Theme.meta).foregroundStyle(Theme.secondary)
                }
                Spacer()
                Button(settings.localized("Learn")) { midi.startControlLearning(target) }
                    .buttonStyle(.borderless)
                    .frame(minWidth: Theme.Size.touch, minHeight: Theme.Size.touch)
                    .accessibilityLabel(settings.localized("Learn: %@", settings.localized(title)))
                Button(settings.localized("Clear")) { midi.clearControlMapping(target) }
                    .buttonStyle(.borderless)
                    .frame(minWidth: Theme.Size.touch, minHeight: Theme.Size.touch)
                    .disabled(signal == nil)
                    .accessibilityLabel(settings.localized("Clear: %@", settings.localized(title)))
            }
            if midi.controlLearningTarget == target {
                Text(settings.localized(midi.controlLearningNotice ?? (target == .knob
                    ? "Turn the tempo knob slightly." : "Press the controller button once.")))
                    .font(Theme.meta).foregroundStyle(Theme.secondary)
                Button(settings.localized("Cancel")) { midi.cancelControlLearning() }
                    .buttonStyle(.borderless).frame(minHeight: Theme.Size.touch)
            }
        }
    }

    private func mappingText(_ signal: MIDIControlSignal?) -> String {
        guard let signal else { return settings.localized("Not assigned") }
        return settings.localized("%@ %lld · ch %lld", settings.localized(signal.kind == .cc ? "CC" : "Note"),
                                  signal.number, signal.channel)
    }
}

#if DEBUG
@MainActor
private struct LegacyProgressImportSection: View {
    @Environment(SettingsManager.self) private var settings
    @State private var showingImporter = false
    @State private var message: String?
    @State private var showingResult = false

    var body: some View {
        Section {
            Button(settings.localized("Choose legacy backup JSON")) { showingImporter = true }
                .font(Theme.control)
                .frame(minHeight: Theme.Size.touch)
        } header: {
            SectionHeader(title: settings.localized("Import from legacy backup"))
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                let summary = try ProgressStore.shared.importLegacyBackup(Data(contentsOf: url))
                message = settings.localized("Imported %lld lessons. Added %lld stars.", summary.lessons, summary.starsAdded)
            } catch LegacyProgressImport.ImportError.invalidBackup {
                message = settings.localized("Invalid backup. Choose a padwork backup with formatVersion 1 and rewards.stars. Progress was not changed.")
            } catch {
                message = settings.localized("Import failed. Progress was not changed. %@", error.localizedDescription)
            }
            showingResult = true
        }
        .alert(settings.localized("Import from legacy backup"), isPresented: $showingResult) {
            Button(settings.localized("Done"), role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }
}
#endif
