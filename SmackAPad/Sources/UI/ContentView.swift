import CoreAudioKit
import SwiftUI

@MainActor
struct MIDISettingsView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(MIDIInput.self) private var midi
    @State private var showingLearn = false
    @State private var showingBluetooth = false

    var body: some View {
        @Bindable var settings = settings
        @Bindable var midi = midi
        NavigationStack {
            Form {
                Section("MIDI controller") {
                    Picker("Input", selection: $midi.selectedSourceID) {
                        Text("All connected controllers").tag(String?.none)
                        ForEach(midi.sources) { source in
                            Text(source.name).tag(Optional(source.id))
                        }
                    }
                    if midi.sources.isEmpty {
                        Text("Connect a USB controller or pair a Bluetooth MIDI controller.")
                            .foregroundStyle(.secondary)
                    }
                    Button("Connect Bluetooth MIDI") { showingBluetooth = true }
                    if let error = midi.errorMessage {
                        Text(error).foregroundStyle(.red)
                        Button("Reconnect MIDI") { midi.stop(); midi.start() }
                    }
                }

                Section {
                    Picker("Profile", selection: $settings.activeProfileName) {
                        ForEach(settings.allProfiles()) { profile in
                            Text(profile.profileName).tag(profile.profileName)
                        }
                    }
                    Button("Learn a new profile") { showingLearn = true }
                    if settings.customProfiles.contains(where: { $0.profileName == settings.activeProfileName }) {
                        Button("Delete selected profile", role: .destructive) {
                            settings.deleteProfile(named: settings.activeProfileName)
                        }
                    }
                } header: {
                    Text("Controller profile")
                } footer: {
                    Text("Akai and Maschine presets use notes 36–51, starting at the bottom left. Use MIDI learn for other banks or mappings.")
                }

                Section {
                    NavigationLink("Timing calibration") {
                        CalibrationView(settings: settings, midi: midi)
                    }
                }

                Section("Input monitor") {
                    LabeledContent("Received MIDI hits", value: midi.noteOnCount.formatted())
                    LabeledContent("Timestamp fallbacks", value: midi.fallbackCount.formatted())
                    if let note = midi.lastNote {
                        LabeledContent("MIDI note", value: note.note.formatted())
                        LabeledContent("Channel", value: note.channel.formatted())
                        LabeledContent("Velocity", value: note.velocity.formatted())
                        LabeledContent("Message") {
                            Text(LocalizedStringKey(note.isNoteOn ? "Note on" : "Note off"))
                        }
                    } else {
                        Text("Play a pad to check the input.").foregroundStyle(.secondary)
                    }
                    if let pad = midi.lastPad {
                        // UI pad numbers are one-based; the shared output remains padIndex 0–15.
                        LabeledContent("Mapped pad", value: (pad.padIndex + 1).formatted())
                    }
                }

                Section {
                    if let pads = midi.padIndices {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                            ForEach(Array(pads.enumerated()), id: \.offset) { slot, padIndex in
                                TouchPad(
                                    number: slot + 1, sound: PadNames.name(for: padIndex),
                                    isActive: midi.pressedPadIndices.contains(padIndex)
                                ) { pressed in
                                    midi.touch(padIndex: padIndex, isPressed: pressed)
                                }
                                .id("\(settings.activeProfileName)/\(slot)/\(padIndex)")
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        Text("This lesson requires 16 pads.")
                    }
                } header: {
                    Text("Touch pads")
                } footer: {
                    if midi.activeProfile.isEightPad {
                        Text("Eight physical slots follow the current lesson. Without a lesson, the base layout is shown.")
                    } else {
                        Text("Touch pads send the same pad events as MIDI. Sound playback is added by the audio module.")
                    }
                }

                Section("Language") {
                    Picker("App language", selection: $settings.languagePreference) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                }
            }
            .navigationTitle("Smack-a-Pad · MIDI")
            .sheet(isPresented: $showingLearn) {
                MIDILearnView().environment(settings).environment(midi)
            }
            .sheet(isPresented: $showingBluetooth) {
                NavigationStack {
                    BluetoothMIDIView()
                        .navigationTitle("Bluetooth MIDI")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showingBluetooth = false }
                            }
                        }
                }
            }
        }
    }
}

@MainActor
private struct MIDILearnView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(MIDIInput.self) private var midi
    @Environment(\.dismiss) private var dismiss
    @State private var padCount = 16
    @State private var profileName = ""

    private var trimmedName: String { profileName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var nameExists: Bool { settings.profile(named: trimmedName) != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("New controller profile") {
                    TextField("Profile name", text: $profileName)
                    Picker("Pad count", selection: $padCount) {
                        Text("8 pads").tag(8)
                        Text("16 pads").tag(16)
                    }
                    .pickerStyle(.segmented)
                    .disabled(midi.isLearning)
                    if nameExists {
                        Text("This profile name is already in use.").foregroundStyle(.red)
                    }
                }
                Section {
                    if midi.isLearning {
                        LabeledContent("Learned pads", value: "\(midi.learnedNotes.count) / \(padCount)")
                        if midi.learningComplete {
                            Text("All pads learned. Save the profile to use it.")
                        } else {
                            Text("Press the highlighted pad on your controller.")
                        }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                            ForEach(0..<padCount, id: \.self) { slot in
                                VStack(spacing: 4) {
                                    Text("Pad \(slot + 1)").font(.headline)
                                    if midi.learnedNotes.indices.contains(slot) {
                                        Text(midi.learnedNotes[slot].formatted()).monospacedDigit()
                                    } else {
                                        Text("—")
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 64)
                                .background(slot == midi.learnedNotes.count ? Color.orange.opacity(0.2) : Color.secondary.opacity(0.08),
                                            in: RoundedRectangle(cornerRadius: 8))
                                .accessibilityAddTraits(slot == midi.learnedNotes.count ? .isSelected : [])
                            }
                        }
                        if midi.learningNotice == "duplicateNote" {
                            Text("That note is already assigned. Press a different pad.")
                                .foregroundStyle(.secondary)
                        }
                        Button("Start again") { midi.startLearning(padCount: padCount) }
                    } else {
                        Button("Start MIDI learn") { midi.startLearning(padCount: padCount) }
                            .disabled(midi.sources.isEmpty)
                        if midi.sources.isEmpty {
                            Text("Connect a MIDI controller before starting.").foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("MIDI learn")
                } footer: {
                    Text("Press each physical pad once, left to right, starting with the top row. Use the same controller and MIDI channel throughout. In 8-pad mode, positions are slots 1–8; sounds follow the lesson.")
                }
            }
            .navigationTitle("MIDI learn")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if midi.saveLearnedProfile(name: profileName) { dismiss() }
                    }
                    .disabled(!midi.learningComplete || trimmedName.isEmpty || nameExists)
                }
            }
            .onDisappear { midi.cancelLearning() }
        }
    }
}

private struct TouchPad: View {
    let number: Int
    let sound: LocalizedStringKey
    let isActive: Bool
    let onPress: (Bool) -> Void
    @State private var isTouching = false

    var body: some View {
        VStack(spacing: 4) {
            Text("Pad \(number)").font(.caption).foregroundStyle(.secondary)
            Text(sound).font(.headline)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(isActive ? Color.orange.opacity(0.2) : Color.secondary.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isTouching else { return }
                    isTouching = true
                    onPress(true)
                }
                .onEnded { _ in release() }
        )
        .onDisappear { release() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onPress(true); onPress(false) }
    }

    private func release() {
        guard isTouching else { return }
        isTouching = false
        onPress(false)
    }
}

private enum PadNames {
    // Sound names for pad indices specified by the lesson layout.
    static func name(for padIndex: Int) -> LocalizedStringKey {
        switch padIndex {
        case 2: return "Crash"
        case 3: return "Ride"
        case 7: return "Open hi-hat"
        case 9: return "Clap"
        case 10: return "Rim"
        case 11: return "Hi-hat R"
        case 12: return "Kick L"
        case 13: return "Snare L"
        default: return "Pad \(padIndex + 1)"
        }
    }
}

private struct BluetoothMIDIView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CABTMIDICentralViewController {
        CABTMIDICentralViewController()
    }

    func updateUIViewController(_ controller: CABTMIDICentralViewController, context: Context) {}
}

#Preview {
    MIDISettingsView()
        .environment(SettingsManager.shared)
        .environment(MIDIInput(settings: .shared))
}
