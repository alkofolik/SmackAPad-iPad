//
//  ControllerSetupView.swift
//  SmackAPad
//
//  Controller setup screen: connection, calibration, controller profiles,
//  button/knob mapping, and input monitor.
//

import CoreAudioKit
import SwiftUI

@MainActor
public struct ControllerSetupView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(MIDIInput.self) private var midi
    @Environment(\.dismiss) private var dismiss

    var showsDoneButton: Bool
    var onDismiss: (() -> Void)? = nil

    @State private var showingMIDILearn = false
    @State private var profileToDelete: ControllerProfile?
    @State private var showingDeleteAlert = false
    @State private var showingControlPadWarning = false

    public init(showsDoneButton: Bool = false, onDismiss: (() -> Void)? = nil) {
        self.showsDoneButton = showsDoneButton
        self.onDismiss = onDismiss
    }

    private var connectedControllerName: String? {
        if let selectedID = midi.selectedSourceID {
            return midi.sources.first(where: { $0.id == selectedID })?.name ?? midi.sources.first?.name
        }
        return midi.sources.first?.name
    }

    private var statusTitle: String {
        connectedControllerName ?? settings.localized("Connect a controller")
    }

    private var savedLatencyText: String {
        let offset: Double? = {
            if let id = midi.selectedSourceID ?? midi.sources.first?.id, let off = settings.calibrationOffsets[id] {
                return off
            }
            if let source = midi.sources.first, let off = settings.calibrationOffsets[source.id] {
                return off
            }
            if let controllerOff = settings.calibrationOffsets.first(where: { $0.key != "touch" && $0.key != "keyboard" })?.value {
                return controllerOff
            }
            return settings.calibrationOffsets.values.first
        }()
        if let offset {
            return String(format: "%+.0f ms", offset)
        }
        return settings.localized("Not measured")
    }

    public var body: some View {
        @Bindable var settings = settings
        @Bindable var midi = midi

        Form {
            Group {
                // MARK: 1. Connection
                Section {
                    HStack {
                        Text(statusTitle)
                            .font(Theme.rowTitle)
                            .foregroundStyle(connectedControllerName != nil ? Theme.ink : Theme.secondary)
                        Spacer()
                    }
                    .frame(minHeight: Theme.Size.touch)

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
                }

                // MARK: 2. Calibration
                Section {
                    NavigationLink {
                        CalibrationView(settings: settings, midi: midi)
                    } label: {
                        HStack {
                            Text(settings.localized("Timing calibration"))
                                .font(Theme.control)
                            Spacer()
                            Text(savedLatencyText)
                                .font(Theme.meta)
                                .foregroundStyle(Theme.secondary)
                        }
                        .frame(minHeight: Theme.Size.touch)
                    }
                } header: {
                    SectionHeader(title: settings.localized("Calibration"))
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
                    SectionHeader(title: settings.localized("Controller profiles"))
                } footer: {
                    Text(settings.localized("Akai and Maschine presets use notes 36–51 starting from the bottom left. Use MIDI learn for other banks or mappings."))
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary)
                }

                // MARK: 4. Controller Buttons & Tempo Knob
                ControllerMappingSections()

                // MARK: 5. Input Monitor
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
                    SectionHeader(title: settings.localized("Input monitor"))
                }
            }
            .listRowBackground(Theme.surface)
            .listRowInsets(EdgeInsets(top: Theme.Space.small, leading: Theme.Space.regular,
                                     bottom: Theme.Space.small, trailing: Theme.Space.regular))
        }
        .appFormStyle()
        .navigationTitle(settings.localized("Controller"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { ScreenHeader(title: settings.localized("Controller")) }
            if showsDoneButton {
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.localized("Done")) {
                        if let onDismiss { onDismiss() } else { dismiss() }
                    }
                    .font(Theme.control)
                    .frame(minHeight: Theme.Size.touch)
                }
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
                stateTitle: settings.localized(isActive ? "Active" : "Preset"),
                title: profile.profileName, action: onSelect) {
            Text("\(settings.localized(profile.padCount == 8 ? "8 pads" : "16 pads")) · \(settings.localized(isCustom ? "Custom" : "Preset"))")
        } trailing: {
            if isActive {
                Text(Theme.sentenceCase(settings.localized("Active"))).font(Theme.meta).foregroundStyle(Theme.ink)
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
