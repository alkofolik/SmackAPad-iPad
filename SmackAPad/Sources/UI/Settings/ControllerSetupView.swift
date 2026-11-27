//
//  ControllerSetupView.swift
//  SmackAPad
//
//  Controller setup screen: connection, calibration, controller profiles,
//  button/knob mapping, and input monitor.
//

import CoreBluetooth
import SwiftUI

@MainActor
public struct ControllerSetupView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(MIDIInput.self) private var midi
    @Environment(\.dismiss) private var dismiss

    var onDismiss: (() -> Void)? = nil
    private var isEmbeddedInSettings = false

    @State private var showingMIDILearn = false
    @State private var profileToDelete: ControllerProfile?
    @State private var showingDeleteAlert = false
    @State private var showingControlPadWarning = false
    @State private var bluetoothAccessMessage: String?

    public init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    init(isEmbeddedInSettings: Bool) {
        self.isEmbeddedInSettings = isEmbeddedInSettings
    }

    private var isConnected: Bool {
        midi.connectedControllerName != nil
    }

    private var statusTitle: String {
        midi.connectedControllerName ?? settings.localized("Not connected")
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
        if isEmbeddedInSettings {
            controllerScrollView
                .background(Theme.chassis.ignoresSafeArea())
                .foregroundStyle(Theme.ink)
        } else {
            VStack(spacing: 0) {
                ScreenTopBar {
                    HardwareBackButton {
                        if let onDismiss { onDismiss() } else { dismiss() }
                    }
                } center: {
                    Text(settings.localized("Controller"))
                        .font(Theme.screenTitle)
                        .foregroundStyle(Theme.ink)
                } trailing: {
                    EmptyView()
                }
                .padding(.horizontal, Theme.Space.page)
                .padding(.vertical, Theme.Space.small)
                .background(Theme.chassis)

                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 1)

                controllerScrollView
            }
            .background(Theme.chassis.ignoresSafeArea())
            .foregroundStyle(Theme.ink)
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    @ViewBuilder
    private var controllerScrollView: some View {
        @Bindable var settings = settings
        @Bindable var midi = midi

        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.page) {
                // MARK: 1. Connection
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    HardwareSectionHeader(title: settings.localized("Controller"))

                    HardwareCard {
                        HStack(spacing: Theme.Space.controlGap) {
                            HStack(spacing: Theme.Space.small) {
                                Circle()
                                    .fill(Theme.cavity)
                                    .frame(width: 14, height: 14)
                                    .overlay {
                                        Circle()
                                            .fill(isConnected ? Theme.orange : Theme.ledOff)
                                            .frame(width: 8, height: 8)
                                            .shadow(color: isConnected ? Theme.accentGlow : .clear, radius: isConnected ? 5 : 0)
                                    }

                                Text(statusTitle)
                                    .font(Theme.control)
                                    .foregroundStyle(isConnected ? Theme.ink : Theme.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                switch CBManager.authorization {
                                case .denied:
                                    bluetoothAccessMessage = "Allow Bluetooth access in iPad Settings to pair a controller."
                                case .restricted:
                                    bluetoothAccessMessage = "Bluetooth access is restricted on this iPad."
                                default:
                                    BluetoothMIDIPresenter.present()
                                }
                            } label: {
                                Text(settings.localized("Connect Bluetooth MIDI"))
                                    .font(Theme.control)
                                    .frame(minHeight: Theme.Size.touch)
                            }
                            .buttonStyle(PadSecondaryButtonStyle())
                        }
                        .padding(.horizontal, Theme.Space.regular)
                        .padding(.vertical, 12)

                        if !midi.sources.isEmpty {
                            HardwareDivider()
                            VStack(alignment: .leading, spacing: Theme.Space.small) {
                                Text(settings.localized("Input"))
                                    .font(Theme.control)
                                    .foregroundStyle(Theme.ink)
                                let sourceOptions: [(String, String)] = [("", settings.localized("All connected controllers"))]
                                    + midi.sources.map { ($0.id, $0.name) }
                                PlexSegmentedPicker(
                                    title: settings.localized("Input"),
                                    selection: Binding(
                                        get: { midi.selectedSourceID ?? "" },
                                        set: { midi.selectedSourceID = $0.isEmpty ? nil : $0 }
                                    ),
                                    options: sourceOptions,
                                    size: .compact
                                )
                            }
                            .padding(.horizontal, Theme.Space.regular)
                            .padding(.vertical, 12)
                        }

                        if let error = midi.errorMessage {
                            HardwareDivider()
                            VStack(alignment: .leading, spacing: Theme.Space.small) {
                                Text(error)
                                    .font(Theme.meta)
                                    .foregroundStyle(Theme.destructive)
                                Button {
                                    midi.stop()
                                    midi.start()
                                } label: {
                                    Text(settings.localized("Reconnect MIDI"))
                                        .font(Theme.control)
                                        .frame(minHeight: Theme.Size.touch)
                                }
                                .buttonStyle(PadSecondaryButtonStyle())
                            }
                            .padding(.horizontal, Theme.Space.regular)
                            .padding(.vertical, 12)
                        }
                    }

                    if midi.sources.isEmpty {
                        Text(settings.localized("Without a MIDI controller, you can play using the on-screen pads or a hardware keyboard."))
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // MARK: 2. Calibration
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    HardwareSectionHeader(title: settings.localized("Calibration"))

                    HardwareCard {
                        NavigationLink {
                            CalibrationView(settings: settings, midi: midi)
                        } label: {
                            HardwareRow(title: settings.localized("Timing calibration")) {
                                HStack(spacing: Theme.Space.small) {
                                    Text(savedLatencyText)
                                        .font(Theme.meta.monospacedDigit())
                                        .foregroundStyle(Theme.secondary)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Theme.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                // MARK: 3. Controller Profiles & MIDI Learn Trigger
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    HardwareSectionHeader(title: settings.localized("Controller profiles"))

                    VStack(spacing: Theme.Space.small) {
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
                    }

                    Button {
                        showingMIDILearn = true
                    } label: {
                        HStack {
                            Text(settings.localized("Learn a new profile (MIDI learn)"))
                                .font(Theme.control)
                            Spacer()
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity, minHeight: Theme.Size.touch)
                    }
                    .buttonStyle(PadSecondaryButtonStyle())

                    Text(settings.localized("The 16-pad preset maps notes 36–51 from the bottom-left pad. Use MIDI learn for other banks."))
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // MARK: 4. Controller Buttons & Tempo Knob
                ControllerMappingSections()

                // MARK: 5. Input Monitor
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    HardwareSectionHeader(title: settings.localized("Input monitor"))

                    HardwareCard {
                        VStack(alignment: .leading, spacing: Theme.Space.small) {
                            ControllerLivePadGrid()
                            if let note = midi.lastNote, midi.activeProfile.target(forMidiNote: note.note) == nil {
                                Text(settings.localized("Note %lld is not mapped", note.note))
                                    .font(Theme.meta)
                                    .foregroundStyle(Theme.orange)
                            }
                        }
                        .padding(Theme.Space.regular)

                        HardwareDivider()
                        monitorRow(title: settings.localized("Received MIDI hits"), value: midi.noteOnCount.formatted())
                        HardwareDivider()
                        monitorRow(title: settings.localized("Timestamp fallbacks"), value: midi.fallbackCount.formatted())

                        if let message = midi.lastControlMessage, message.signal.kind == .cc {
                            HardwareDivider()
                            monitorRow(title: settings.localized("Message"), value: settings.localized("Control change"))
                            HardwareDivider()
                            monitorRow(title: settings.localized("Channel"), value: message.signal.channel.formatted())
                            HardwareDivider()
                            monitorRow(title: settings.localized("CC number"), value: message.signal.number.formatted())
                            HardwareDivider()
                            monitorRow(title: settings.localized("Value"), value: message.value.formatted())
                        } else if let note = midi.lastNote {
                            HardwareDivider()
                            monitorRow(title: settings.localized("MIDI note"), value: note.note.formatted())
                            HardwareDivider()
                            monitorRow(title: settings.localized("Channel"), value: note.channel.formatted())
                            HardwareDivider()
                            monitorRow(title: settings.localized("Velocity"), value: note.velocity.formatted())
                            HardwareDivider()
                            monitorRow(title: settings.localized("Message"), value: note.isNoteOn ? settings.localized("Note on") : settings.localized("Note off"))
                        } else {
                            HardwareDivider()
                            HardwareRow(title: settings.localized("Play a pad to check the input."))
                                .foregroundStyle(Theme.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: 700, alignment: .leading)
            .padding(Theme.Space.page)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .sheet(isPresented: $showingMIDILearn) {
            MIDILearnView()
                .environment(settings)
                .environment(midi)
        }
        .alert(settings.localized("Bluetooth MIDI"), isPresented: Binding(
            get: { bluetoothAccessMessage != nil },
            set: { if !$0 { bluetoothAccessMessage = nil } }
        ), presenting: bluetoothAccessMessage) { _ in
            Button(settings.localized("Done"), role: .cancel) {}
        } message: { message in
            Text(settings.localized(message))
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
        .onAppear { midi.isControllerMonitorActive = true }
        .onDisappear {
            midi.isControllerMonitorActive = false
            midi.cancelControlLearning()
        }
    }

    private func monitorRow(title: String, value: String) -> some View {
        HardwareRow(title: title) {
            Text(value)
                .font(Theme.meta.monospacedDigit())
                .foregroundStyle(Theme.secondary)
        }
    }
}

/// Passive hardware display: input feedback has no touch or navigation action.
@MainActor
private struct ControllerLivePadGrid: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(MIDIInput.self) private var midi

    var body: some View {
        let profile = midi.activeProfile
        PadProfileGrid(profile: profile) { slot in
            let target = profile.target(forSlot: slot)
            let note = profile.midiNote(forTarget: target)
            let control = MIDIPracticeAction.allCases.first { action in
                guard let signal = settings.midiControls.buttons[action.rawValue]?.signal else { return false }
                return signal.kind == .note && signal.number == note
            }
            let pad = midi.padIndices.flatMap { $0.indices.contains(target) ? $0[target] : nil }
            let velocity = pad.map { midi.pressedPadVelocities[$0] ?? 0 } ?? 0
            let strength = pad.map { midi.pressedPadIndices.contains($0) ? Double(velocity) / 127 : 0 } ?? 0
            let signal = control.flatMap { settings.midiControls.buttons[$0.rawValue]?.signal }
            let controlStrength = signal.map { Double(midi.pressedControlVelocities[$0] ?? 0) / 127 } ?? 0
            ControllerLivePad(label: control.map { settings.localized($0.title) } ?? note.map { $0.formatted() } ?? "—",
                              strength: control == nil ? strength : controlStrength)
        }
        .padding(Theme.Space.small)
        .background(Theme.cavity, in: RoundedRectangle(cornerRadius: Theme.Radius.pad))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("Controller, %lld rows by %lld columns", profile.rows, profile.columns))
        .allowsHitTesting(false)
    }
}

private struct ControllerLivePad: View {
    let label: String
    let strength: Double

    var body: some View {
        Text(label)
            .font(Theme.control)
            .monospacedDigit()
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minWidth: Theme.Size.touch, minHeight: Theme.Size.touch)
            .aspectRatio(1, contentMode: .fit)
            .foregroundStyle(Theme.ink)
            .background {
                PadSurface(activeStrength: strength, hasBorder: false, hasShadow: false)
            }
            .animation(strength == 0 ? Theme.Motion.padFlash : nil, value: strength)
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
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.panel)
        HStack(spacing: Theme.Space.controlGap) {
            Button(action: onSelect) {
                HStack(spacing: Theme.Space.controlGap) {
                    Circle()
                        .fill(Theme.cavity)
                        .frame(width: 14, height: 14)
                        .overlay {
                            Circle()
                                .fill(isActive ? Theme.orange : Theme.ledOff)
                                .frame(width: 8, height: 8)
                                .shadow(color: isActive ? Theme.accentGlow : .clear, radius: isActive ? 5 : 0)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(settings.displayName(for: profile))
                            .font(Theme.control)
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(settings.localized(profile.padCount == 8 ? "8 pads" : "16 pads")) · \(settings.localized(isCustom ? "Custom" : "Preset"))")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if isActive {
                        Text(Theme.sentenceCase(settings.localized("Active")))
                            .font(Theme.strong(13))
                            .foregroundStyle(Theme.orange)
                    }
                }
                .padding(.horizontal, Theme.Space.regular)
                .padding(.vertical, 12)
                .frame(minHeight: Theme.Size.listRow)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(settings.displayName(for: profile))
            .accessibilityAddTraits(isActive ? .isSelected : [])

            if isCustom {
                HardwareIconButton(
                    systemName: "trash",
                    accessibilityLabel: settings.localized("Delete profile"),
                    compact: true,
                    action: onDelete
                )
                .padding(.trailing, Theme.Space.small)
            }
        }
        .background(isActive ? Theme.surfaceElevated : Theme.surface, in: shape)
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(isActive ? Theme.orange : Theme.hairline, lineWidth: isActive ? 1.5 : 1)
                .allowsHitTesting(false)
        }
    }
}

/// Shared hardware sections keep controller assignments in the hardware style.
@MainActor
struct ControllerMappingSections: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(MIDIInput.self) private var midi
    @State private var advanced = false

    var body: some View {
        @Bindable var settings = settings
        VStack(alignment: .leading, spacing: Theme.Space.page) {
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                HardwareSectionHeader(title: settings.localized("Controller buttons"))

                HardwareCard {
                    actionRow(.startStop)
                    HardwareDivider()
                    actionRow(.peek)
                    HardwareDivider()

                    Button {
                        withAnimation(Theme.Motion.fast) {
                            advanced.toggle()
                        }
                    } label: {
                        HardwareRow(title: settings.localized("Advanced")) {
                            Image(systemName: advanced ? "chevron.up" : "chevron.down")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(settings.localized(advanced ? "Expanded" : "Collapsed"))

                    if advanced {
                        ForEach(MIDIPracticeAction.allCases.filter { $0 != .startStop && $0 != .peek }, id: \.self) { action in
                            HardwareDivider()
                            actionRow(action)
                        }
                    }
                }

                Text(settings.localized("Controller actions work only with an open practice lesson. Tempo changes only while stopped."))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: Theme.Space.small) {
                HardwareSectionHeader(title: settings.localized("Tempo knob"))

                HardwareCard {
                    mappingRow(title: "Tempo knob", signal: settings.midiControls.knob.signal, target: .knob)

                    HardwareDivider()

                    VStack(alignment: .leading, spacing: Theme.Space.small) {
                        Text(settings.localized("Knob mode"))
                            .font(Theme.control)
                            .foregroundStyle(Theme.ink)
                        PlexSegmentedPicker(
                            title: settings.localized("Knob mode"),
                            selection: $settings.midiControls.knob.mode,
                            options: MIDIKnobMode.allCases.map { ($0, settings.localized($0.title)) },
                            fitsColumn: true,
                            size: .compact
                        )
                    }
                    .padding(.horizontal, Theme.Space.regular)
                    .padding(.vertical, 12)

                    if settings.midiControls.knob.mode == .absolute {
                        HardwareDivider()
                        bpmStepperRow(
                            title: settings.localized("Minimum BPM: %lld", settings.midiControls.knob.minimumBpm),
                            value: $settings.midiControls.knob.minimumBpm,
                            range: PracticeTempo.minimumBpm...settings.midiControls.knob.maximumBpm
                        )
                        HardwareDivider()
                        bpmStepperRow(
                            title: settings.localized("Maximum BPM: %lld", settings.midiControls.knob.maximumBpm),
                            value: $settings.midiControls.knob.maximumBpm,
                            range: settings.midiControls.knob.minimumBpm...PracticeTempo.maximumBpm
                        )
                        HardwareDivider()
                        HardwareRow(title: settings.localized("Pickup")) {
                            HardwareToggle(isOn: $settings.midiControls.knob.pickup)
                        }
                    }

                    HardwareDivider()

                    HardwareRow(title: settings.localized("Reverse direction")) {
                        HardwareToggle(isOn: $settings.midiControls.knob.reversed)
                    }
                }

                Text(settings.localized("Pickup waits until the knob reaches the current tempo. Relative steps change tempo by 1 BPM. Tempo changes only while stopped."))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func bpmStepperRow(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HardwareRow(title: title) {
            HStack(spacing: Theme.Space.small) {
                HardwareIconButton(systemName: "minus", accessibilityLabel: "−", compact: true) {
                    value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1)
                }
                .disabled(value.wrappedValue <= range.lowerBound)

                HardwareIconButton(systemName: "plus", accessibilityLabel: "+", compact: true) {
                    value.wrappedValue = min(range.upperBound, value.wrappedValue + 1)
                }
                .disabled(value.wrappedValue >= range.upperBound)
            }
        }
    }

    @ViewBuilder
    private func actionRow(_ action: MIDIPracticeAction) -> some View {
        let mapping = settings.midiControls.buttons[action.rawValue]
        VStack(alignment: .leading, spacing: 0) {
            mappingRow(title: action.title, signal: mapping?.signal, target: .action(action))
            if mapping?.signal.kind == .cc {
                HardwareDivider()
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    Text(settings.localized("CC button behaviour"))
                        .font(Theme.control)
                        .foregroundStyle(Theme.ink)
                    PlexSegmentedPicker(
                        title: settings.localized("CC button behaviour"),
                        selection: Binding(
                            get: { settings.midiControls.buttons[action.rawValue]?.behavior ?? .rising64 },
                            set: { settings.midiControls.buttons[action.rawValue]?.behavior = $0 }
                        ),
                        options: MIDICCButtonBehavior.allCases.map { ($0, settings.localized($0.title)) },
                        fitsColumn: true,
                        size: .compact
                    )
                }
                .padding(.horizontal, Theme.Space.regular)
                .padding(.vertical, 12)
            }
        }
    }

    @ViewBuilder
    private func mappingRow(title: String, signal: MIDIControlSignal?, target: MIDIControlLearnTarget) -> some View {
        let description = VStack(alignment: .leading, spacing: Theme.Space.tight) {
            Text(settings.localized(title))
                .font(Theme.control)
                .foregroundStyle(Theme.ink)
            Text(mappingText(signal))
                .font(Theme.meta.monospacedDigit())
                .foregroundStyle(Theme.secondary)
        }
        let actions = HStack(spacing: Theme.Space.controlGap) {
            Button { midi.startControlLearning(target) } label: {
                Text(settings.localized("Learn"))
                    .frame(minWidth: Theme.Size.touch, minHeight: Theme.Size.touch)
            }
            .buttonStyle(PadSecondaryButtonStyle())
            .accessibilityLabel(settings.localized("Learn: %@", settings.localized(title)))
            Button { midi.clearControlMapping(target) } label: {
                Text(settings.localized("Clear"))
                    .frame(minWidth: Theme.Size.touch, minHeight: Theme.Size.touch)
            }
            .buttonStyle(PadSecondaryButtonStyle())
            .disabled(signal == nil)
            .accessibilityLabel(settings.localized("Clear: %@", settings.localized(title)))
        }
        .fixedSize(horizontal: true, vertical: false)

        VStack(alignment: .leading, spacing: Theme.Space.small) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Space.regular) {
                    description
                    Spacer(minLength: 0)
                    actions
                }
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    description
                    actions
                }
            }
            if midi.controlLearningTarget == target {
                Text(settings.localized(midi.controlLearningNotice ?? (target == .knob
                    ? "Turn the tempo knob slightly." : "Press the controller button once.")))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
                Button { midi.cancelControlLearning() } label: {
                    Text(settings.localized("Cancel"))
                        .frame(minHeight: Theme.Size.touch)
                }
                .buttonStyle(PadSecondaryButtonStyle())
            }
        }
        .padding(.horizontal, Theme.Space.regular)
        .padding(.vertical, 12)
    }

    private func mappingText(_ signal: MIDIControlSignal?) -> String {
        guard let signal else { return settings.localized("Not assigned") }
        return settings.localized("%@ %lld · ch %lld", settings.localized(signal.kind == .cc ? "CC" : "Note"),
                                  signal.number, signal.channel)
    }
}
