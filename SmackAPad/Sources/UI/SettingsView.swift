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

    private var czech: Bool { settings.languagePreference == .czech }
    private func label(_ cs: String, _ en: String) -> String { czech ? cs : en }

    public init() {}

    public var body: some View {
        @Bindable var settings = settings
        @Bindable var midi = midi

        NavigationStack {
            Form {
                // MARK: 1. Kit Selection
                Section {
                    Picker(label("Bicí souprava", "Sound kit"), selection: $settings.selectedKitId) {
                        ForEach(kits) { kit in
                            Text(kit.name).tag(kit.kitId)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text(label("ZVUKOVÁ SADA", "SOUND KIT"))
                        .font(Theme.text(Theme.Size.dense))
                        .foregroundStyle(Theme.orange)
                } footer: {
                    Text(label("Všech 8 sad je součástí aplikace. Používají se při cvičení i přehrávání.",
                               "All 8 kits are bundled with the app for practice and playback."))
                        .font(Theme.text(Theme.Size.dense))
                        .foregroundStyle(Theme.secondary)
                }

                // MARK: 2. BPM Step
                Section {
                    Picker(label("Krok zrychlení", "Tempo step"), selection: $settings.bpmStep) {
                        ForEach(BpmStep.allCases) { step in
                            Text("+\(step.rawValue) BPM").tag(step.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(label("ZRYCHLENÍ TEMPA (BPM)", "TEMPO AUTO-STEP (BPM)"))
                        .font(Theme.text(Theme.Size.dense))
                        .foregroundStyle(Theme.orange)
                } footer: {
                    Text(label("Po každém čistém průchodu se tempo automaticky zvýší o zvolený počet BPM až do cílového tempa.",
                               "Tempo automatically increases by this step after each clean pass until target tempo."))
                        .font(Theme.text(Theme.Size.dense))
                        .foregroundStyle(Theme.secondary)
                }

                // MARK: 2b. Pad layout on the practice screen
                Section {
                    Toggle(label("Malá mapa padů", "Small pad layout"), isOn: $showPads)
                } header: {
                    Text(label("OBRAZOVKA CVIČENÍ", "PRACTICE SCREEN"))
                        .font(Theme.text(Theme.Size.dense))
                        .foregroundStyle(Theme.orange)
                } footer: {
                    Text(label("Zobrazí v lekci malé rozložení padů, na kterém se rozsvěcují stisknuté pady.",
                               "Shows a small pad layout in the lesson that lights up the pads you hit."))
                        .font(Theme.text(Theme.Size.dense))
                        .foregroundStyle(Theme.secondary)
                }

                // MARK: 3. Controller Profiles & MIDI Learn Trigger
                Section {
                    ForEach(settings.allProfiles()) { profile in
                        ProfileRow(
                            profile: profile,
                            isActive: profile.profileName == settings.activeProfileName,
                            isCustom: settings.customProfiles.contains(where: { $0.profileName == profile.profileName }),
                            czech: czech,
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
                            Text(label("Naučit nový profil (MIDI learn)", "Learn a new profile (MIDI learn)"))
                                .font(Theme.text())
                            Spacer()
                            Text("+")
                                .font(Theme.display(Theme.Size.body))
                        }
                        .frame(minHeight: Theme.Size.touch)
                        .foregroundStyle(Theme.orange)
                    }
                } header: {
                    Text(label("PROFILY KONTROLÉRU", "CONTROLLER PROFILES"))
                        .font(Theme.text(Theme.Size.dense))
                        .foregroundStyle(Theme.orange)
                } footer: {
                    Text(label("Profily Akai a Maschine používají noty 36–51 (od levého dolního padu). Pro jiné kontroléry nebo banky použij MIDI learn.",
                               "Akai and Maschine presets use notes 36–51 starting from the bottom left. Use MIDI learn for other banks or mappings."))
                        .font(Theme.text(Theme.Size.dense))
                        .foregroundStyle(Theme.secondary)
                }

                // MARK: 4. Language Switch
                Section {
                    Picker(label("Jazyk aplikace", "App language"), selection: $settings.languagePreference) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(label("JAZYK", "LANGUAGE"))
                        .font(Theme.text(Theme.Size.dense))
                        .foregroundStyle(Theme.orange)
                } footer: {
                    Text(label("Zvol češtinu nebo angličtinu. Postup v lekcích i nastavení kontroléru zůstanou zachovány.",
                               "Choose Czech or English. Your lesson progress and controller mappings remain preserved."))
                        .font(Theme.text(Theme.Size.dense))
                        .foregroundStyle(Theme.secondary)
                }

                // MARK: 5. Hardware & Calibration
                Section {
                    Picker(label("Vstup", "Input"), selection: $midi.selectedSourceID) {
                        Text(label("Všechny připojené kontroléry", "All connected controllers")).tag(String?.none)
                        ForEach(midi.sources) { source in
                            Text(source.name).tag(Optional(source.id))
                        }
                    }

                    if midi.sources.isEmpty {
                        Text(label("Připoj USB kontrolér nebo spáruj Bluetooth MIDI kontrolér.",
                                   "Connect a USB controller or pair a Bluetooth MIDI controller."))
                            .font(Theme.text(Theme.Size.small))
                            .foregroundStyle(Theme.secondary)
                    }

                    Button {
                        BluetoothMIDIPresenter.present()
                    } label: {
                        Text(label("Připojit Bluetooth MIDI", "Connect Bluetooth MIDI"))
                            .font(Theme.text())
                            .frame(minHeight: Theme.Size.touch)
                    }

                    if let error = midi.errorMessage {
                        Text(error)
                            .font(Theme.text(Theme.Size.small))
                            .foregroundStyle(Theme.markWrong)
                        Button(label("Znovu připojit MIDI", "Reconnect MIDI")) {
                            midi.stop()
                            midi.start()
                        }
                    }

                    NavigationLink {
                        CalibrationView(settings: settings, midi: midi)
                    } label: {
                        HStack {
                            Text(label("Kalibrace časování", "Timing calibration"))
                                .font(Theme.text())
                            Spacer()
                        }
                        .frame(minHeight: Theme.Size.touch)
                    }
                } header: {
                    Text(label("HARDWARE A KALIBRACE", "HARDWARE & CALIBRATION"))
                        .font(Theme.text(Theme.Size.dense))
                        .foregroundStyle(Theme.orange)
                }

                // MARK: 6. Input Monitor
                Section {
                    LabeledContent(label("Přijaté MIDI údery", "Received MIDI hits"), value: midi.noteOnCount.formatted())
                        .font(Theme.text(Theme.Size.small))
                    LabeledContent(label("Nahrazené časové značky", "Timestamp fallbacks"), value: midi.fallbackCount.formatted())
                        .font(Theme.text(Theme.Size.small))

                    if let note = midi.lastNote {
                        LabeledContent(label("MIDI nota", "MIDI note"), value: note.note.formatted())
                            .font(Theme.text(Theme.Size.small))
                        LabeledContent(label("Kanál", "Channel"), value: note.channel.formatted())
                            .font(Theme.text(Theme.Size.small))
                        LabeledContent(label("Síla úderu", "Velocity"), value: note.velocity.formatted())
                            .font(Theme.text(Theme.Size.small))
                        LabeledContent(label("Zpráva", "Message"), value: note.isNoteOn ? label("Stisknutí", "Note on") : label("Uvolnění", "Note off"))
                            .font(Theme.text(Theme.Size.small))
                    } else {
                        Text(label("Uhoď do padu a zkontroluj přijetí úderu.", "Play a pad to check the input."))
                            .font(Theme.text(Theme.Size.small))
                            .foregroundStyle(Theme.secondary)
                    }

                    if let pad = midi.lastPad {
                        LabeledContent(label("Přiřazený pad", "Mapped pad"), value: (pad.padIndex + 1).formatted())
                            .font(Theme.text(Theme.Size.small))
                    }
                } header: {
                    Text(label("KONTROLA VSTUPU", "INPUT MONITOR"))
                        .font(Theme.text(Theme.Size.dense))
                        .foregroundStyle(Theme.orange)
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
                        Text(label("Tato lekce vyžaduje 16 padů.", "This lesson requires 16 pads."))
                            .font(Theme.text(Theme.Size.small))
                    }
                } header: {
                    Text(label("DOTYKOVÉ PADY", "TOUCH PADS"))
                        .font(Theme.text(Theme.Size.dense))
                        .foregroundStyle(Theme.orange)
                } footer: {
                    if midi.activeProfile.isEightPad {
                        Text(label("Osm fyzických pozic se přiřazuje podle aktuální lekce. Bez lekce se zobrazuje základní rozložení.",
                                   "Eight physical slots follow the current lesson. Without a lesson, the base layout is shown."))
                            .font(Theme.text(Theme.Size.dense))
                            .foregroundStyle(Theme.secondary)
                    } else {
                        Text(label("Dotykové pady posílají stejné události jako MIDI.",
                                   "Touch pads send the same pad events as MIDI."))
                            .font(Theme.text(Theme.Size.dense))
                            .foregroundStyle(Theme.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .foregroundStyle(Theme.ink)
            .tint(Theme.orange)
            .navigationTitle(label("Nastavení", "Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(label("Hotovo", "Done")) {
                        dismiss()
                    }
                    .font(Theme.text())
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
                    ? label("Smazat profil „\(profileToDelete?.profileName ?? "")“?",
                            "Delete profile \"\(profileToDelete?.profileName ?? "")\"?")
                    : "",
                isPresented: $showingDeleteAlert,
                presenting: profileToDelete
            ) { profile in
                Button(label("Smazat", "Delete"), role: .destructive) {
                    settings.deleteProfile(named: profile.profileName)
                    profileToDelete = nil
                }
                Button(label("Zrušit", "Cancel"), role: .cancel) {
                    profileToDelete = nil
                }
            } message: { _ in
                Text(label("Tento vlastní profil bude trvale smazán.",
                           "This custom profile will be permanently deleted."))
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
    let profile: ControllerProfile
    let isActive: Bool
    let isCustom: Bool
    let czech: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Theme.Space.regular) {
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: Theme.Space.tight) {
                        Text(profile.profileName)
                            .font(Theme.text(Theme.Size.body))
                            .foregroundStyle(isActive ? Theme.orange : Theme.ink)

                        HStack(spacing: Theme.Space.small) {
                            Text(profile.padCount == 8 ? (czech ? "8 padů" : "8 pads") : (czech ? "16 padů" : "16 pads"))
                                .font(Theme.text(Theme.Size.dense))
                                .foregroundStyle(Theme.secondary)

                            Text("·")
                                .font(Theme.text(Theme.Size.dense))
                                .foregroundStyle(Theme.secondary)

                            Text(isCustom ? (czech ? "Vlastní" : "Custom") : (czech ? "Výchozí" : "Preset"))
                                .font(Theme.text(Theme.Size.dense))
                                .foregroundStyle(Theme.secondary)
                        }
                    }

                    Spacer()

                    if isActive {
                        HStack(spacing: Theme.Space.tight) {
                            Text(czech ? "AKTIVNÍ" : "ACTIVE")
                                .font(Theme.text(Theme.Size.dense))
                                .padding(.horizontal, Theme.Space.small)
                                .padding(.vertical, 2)
                                .background(Theme.orange)
                                .foregroundStyle(Theme.black)

                            Image(systemName: "checkmark")
                                .font(Theme.text(Theme.Size.small))
                                .foregroundStyle(Theme.orange)
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(minHeight: Theme.Size.touch)

            if isCustom {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(Theme.text())
                        .foregroundStyle(Theme.markWrong)
                        .frame(width: Theme.Size.touch, height: Theme.Size.touch)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(czech ? "Smazat profil" : "Delete profile")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if isCustom {
                Button(role: .destructive, action: onDelete) {
                    Label(czech ? "Smazat" : "Delete", systemImage: "trash")
                }
            }
        }
    }
}
