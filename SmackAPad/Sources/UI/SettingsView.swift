//
//  SettingsView.swift
//  SmackAPad
//
//  Settings screen: kit selection, BPM step, controller profile management,
//  MIDI learn trigger, and language switch.
//

import SwiftUI
#if DEBUG
import UniformTypeIdentifiers
#endif

@MainActor
public struct SettingsView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(MIDIInput.self) private var midi
    @Environment(\.dismiss) private var dismiss

    @State private var kits: [SampleKit] = []
    @AppStorage("smackapad.practice.showPads") private var showPads = true
    @AppStorage("smackapad.practice.touchPadsInPortrait") private var touchPadsInPortrait = true
    @AppStorage("smackapad.practice.visibleBars") private var visibleBars = 4

    private var controllerStatus: String {
        let name: String? = {
            if let selectedID = midi.selectedSourceID {
                return midi.sources.first(where: { $0.id == selectedID })?.name ?? midi.sources.first?.name
            }
            return midi.sources.first?.name
        }()
        return name ?? settings.localized("Not connected")
    }

    public init() {}

    public var body: some View {
        @Bindable var settings = settings
        @Bindable var midi = midi

        NavigationStack {
            Form {
                Group {
                    Section {
                        NavigationLink {
                            ControllerSetupView()
                        } label: {
                            HStack {
                                Text(settings.localized("Controller and calibration"))
                                    .font(Theme.control)
                                Spacer()
                                Text(controllerStatus)
                                    .font(Theme.meta)
                                    .foregroundStyle(Theme.secondary)
                            }
                            .frame(minHeight: Theme.Size.touch)
                        }
                    }

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
                        SectionHeader(title: settings.localized("Sound kit"))
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
                        SectionHeader(title: settings.localized("Sound"))
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
                        SectionHeader(title: settings.localized("Tempo auto-step (BPM)"))
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
                        Toggle(settings.localized("Touch pads in portrait"), isOn: $touchPadsInPortrait)
                    } header: {
                        SectionHeader(title: settings.localized("Practice screen"))
                    } footer: {
                        Text(settings.localized("Shows a small pad layout in the lesson that lights up the pads you hit."))
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                    }

                    Section {
                        Toggle(settings.localized("Hide completed lessons"), isOn: $settings.hideCompletedLessons)
                        Picker(settings.localized("Next lesson from"), selection: $settings.nextLessonSource) {
                            ForEach(NextLessonSource.allCases) { source in
                                Text(settings.localized(source.title)).tag(source.id)
                            }
                        }
                        .frame(minHeight: Theme.Size.touch)
                    } header: {
                        SectionHeader(title: settings.localized("Library"))
                    }

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
                        SectionHeader(title: settings.localized("Keyboard"))
                    }

                    // MARK: 4. Appearance
                    Section {
                        PlexSegmentedPicker(title: settings.localized("Appearance"), selection: $settings.appearance,
                            options: AppAppearance.allCases.map { ($0, settings.localized($0.title)) })
                    } header: {
                        SectionHeader(title: settings.localized("Appearance"))
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
                        SectionHeader(title: settings.localized("Language"))
                    } footer: {
                        Text(settings.localized("Choose Czech or English. Your lesson progress and controller mappings remain preserved."))
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
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
                        SectionHeader(title: settings.localized("Touch pads"))
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
