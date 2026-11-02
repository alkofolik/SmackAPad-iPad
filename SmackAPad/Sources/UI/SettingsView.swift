//
//  SettingsView.swift
//  SmackAPad
//
//  Settings screen: kit selection, BPM step, controller profile management,
//  MIDI learn trigger, and language switch.
//

import CoreAudioKit
import SwiftUI

@MainActor
public struct SettingsView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(MIDIInput.self) private var midi
    @Environment(\.dismiss) private var dismiss

    @State private var showingMIDILearn = false
    @State private var profileToDelete: ControllerProfile?
    @State private var showingDeleteAlert = false
    @State private var kits: [SampleKit] = []
    @AppStorage("smackapad.practice.showPads") private var showPads = true

    public init() {}

    public var body: some View {
        @Bindable var settings = settings
        @Bindable var midi = midi

        NavigationStack {
            Form {
                Group {
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

                    // MARK: 2. BPM Step
                    Section {
                        Picker(settings.localized("Tempo step"), selection: $settings.bpmStep) {
                            ForEach(BpmStep.allCases) { step in
                                Text("+\(step.rawValue) BPM").tag(step.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
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

                    // MARK: 4. Language Switch
                    Section {
                        Picker(settings.localized("App language"), selection: $settings.languagePreference) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(.segmented)
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

                        if let note = midi.lastNote {
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
            .alert(
                profileToDelete != nil
                    ? settings.localized("Delete profile \"%@\"?", profileToDelete?.profileName ?? "")
                    : "",
                isPresented: $showingDeleteAlert,
                presenting: profileToDelete
            ) { profile in
                Button(settings.localized("Delete"), role: .destructive) {
                    settings.deleteProfile(named: profile.profileName)
                    profileToDelete = nil
                }
                Button(settings.localized("Cancel"), role: .cancel) {
                    profileToDelete = nil
                }
            } message: { _ in
                Text(settings.localized("This custom profile will be permanently deleted."))
            }
            .task {
                loadKits()
            }
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
                Text(settings.localized("ACTIVE")).font(Theme.meta).foregroundStyle(Theme.orange)
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
