//
//  SettingsView.swift
//  SmackAPad
//
//  Settings screen: kit selection, BPM step, controller profile management,
//  MIDI learn trigger, and language switch.
//

import SwiftUI
import UserNotifications
#if DEBUG
import UniformTypeIdentifiers
#endif

@MainActor
public struct SettingsView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(MIDIInput.self) private var midi
    @Environment(\.dismiss) private var dismiss

    @State private var kits: [SampleKit] = []
    @State private var isInstrumentVolumeExpanded = false
    @State private var notificationsDenied = false
    @State private var helpPresentation: HelpPresentation?
    @State private var windowWidth: CGFloat = 0
    @AccessibilityFocusState private var helpFocused: Bool
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

    private var selectedKitTitle: String {
        if settings.selectedKitId == "auto" {
            return settings.localized("Automatic")
        }
        return kits.first { $0.kitId == settings.selectedKitId }?.name ?? settings.selectedKitId
    }

    var onDismiss: (() -> Void)? = nil

    public init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

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
                        Button {
                            helpPresentation = HelpPresentation(windowWidth: windowWidth)
                        } label: {
                            HelpEntryLabel()
                        }
                        .buttonStyle(.plain)
                        .accessibilityFocused($helpFocused)
                        .helpDeck(presentation: $helpPresentation) { helpFocused = true }
                    }

                    PurchasesSection()
                    ProgressBackupSection()
                    #if DEBUG
                    LegacyProgressImportSection()
                    DebugDeveloperSection()
                    #endif

                    // MARK: 1. Sound
                    Section {
                        NavigationLink {
                            SoundKitSelectionView(kits: kits)
                        } label: {
                            HStack {
                                Text(settings.localized("Sound set"))
                                    .font(Theme.display(16))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                Text(selectedKitTitle)
                                    .font(Theme.display(16))
                                    .foregroundStyle(Theme.secondary)
                            }
                            .frame(minHeight: Theme.Size.touch)
                        }
                        SoundSliderRow(
                            title: settings.localized("Metronome"),
                            value: $settings.metronomeVolume
                        )
                        SoundSliderRow(
                            title: settings.localized("Pads"),
                            value: $settings.padsVolume
                        )
                        SoundSliderRow(
                            title: settings.localized("settings.sound.pattern"),
                            value: $settings.patternVolume
                        )
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isInstrumentVolumeExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text(settings.localized("Instrument volume"))
                                    .font(Theme.strong(16))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                let changedCount = settings.changedInstrumentTrimCount
                                if changedCount > 0 {
                                    Text(settings.localized("changed %lld", changedCount))
                                        .font(Theme.strong(13).monospacedDigit())
                                        .foregroundStyle(Theme.background)
                                        .padding(.horizontal, 10)
                                        .frame(height: 26)
                                        .background(Theme.ink, in: Capsule())
                                }
                                Image(systemName: isInstrumentVolumeExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                            }
                            .frame(minHeight: Theme.Size.touch)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityValue(settings.localized(isInstrumentVolumeExpanded ? "Expanded" : "Collapsed"))

                        if isInstrumentVolumeExpanded {
                            VStack(alignment: .leading, spacing: 12) {
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(), spacing: 8),
                                        GridItem(.flexible(), spacing: 8)
                                    ],
                                    spacing: 8
                                ) {
                                    ForEach(InstrumentTrimCell.roles, id: \.self) { voice in
                                        InstrumentTrimCell(voice: voice)
                                    }
                                }

                                Button {
                                    settings.resetInstrumentTrims()
                                } label: {
                                    Text(settings.localized("Reset all to 0 dB"))
                                        .font(Theme.strong(15))
                                        .foregroundStyle(settings.instrumentTrims.isEmpty ? Theme.secondary : Theme.ink)
                                        .padding(.horizontal, 16)
                                        .frame(height: 44)
                                        .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(Theme.ink.opacity(settings.instrumentTrims.isEmpty ? 0.12 : 0.28), lineWidth: 1.5)
                                        }
                                }
                                .buttonStyle(.plain)
                                .disabled(settings.instrumentTrims.isEmpty)
                            }
                            .padding(.top, 4)
                            .padding(.bottom, 6)
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        SectionHeader(title: settings.localized("Sound"))
                    } footer: {
                        Text(settings.localized("All 8 kits are bundled with the app for practice and playback."))
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
                            Text(settings.localized("%lld bars", 3)).tag(3)
                            Text(settings.localized("All bars")).tag(4)
                        }
                        Toggle(settings.localized("Small pad layout"), isOn: $showPads)
                        Toggle(settings.localized("Touch pads in portrait"), isOn: $touchPadsInPortrait)
                        Toggle(settings.localized("Fade notes in From memory"), isOn: $settings.fadeMemoryNotes)
                    } header: {
                        SectionHeader(title: settings.localized("Practice screen"))
                    } footer: {
                        Text(settings.localized("Shows a small pad layout in the lesson that lights up the pads you hit."))
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                    }

                    // MARK: 2c. Training
                    Section {
                        Toggle(
                            settings.localized("Review reminder"),
                            isOn: Binding(
                                get: { settings.reviewReminderEnabled },
                                set: { handleReminderToggle($0) }
                            )
                        )
                        .frame(minHeight: Theme.Size.touch)

                        if notificationsDenied {
                            Text(settings.localized("Notifications are turned off in iPad Settings."))
                                .font(Theme.meta)
                                .foregroundStyle(Theme.markWrong)
                        }

                        if settings.reviewReminderEnabled {
                            DatePicker(
                                settings.localized("Time"),
                                selection: Binding(
                                    get: { settings.reviewReminderTime },
                                    set: { newTime in
                                        settings.reviewReminderTime = newTime
                                        ReviewReminderScheduler.shared.reschedule()
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .font(Theme.control)
                            .frame(minHeight: Theme.Size.touch)
                        }
                    } header: {
                        SectionHeader(title: settings.localized("Training"))
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
                            let slots = pads.count == 8 ? PhysicalPadGrid.displaySlots(padCount: pads.count) : Array(pads.indices)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Space.small), count: PhysicalPadGrid.columns), spacing: Theme.Space.small) {
                                ForEach(slots, id: \.self) { slot in
                                    let padIndex = pads[slot]
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

                    Section {
                        NavigationLink {
                            AboutDetailView()
                        } label: {
                            HStack {
                                Text(settings.localized("About"))
                                    .font(Theme.control)
                                Spacer()
                                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                                Text("v\(version)")
                                    .font(Theme.meta)
                                    .foregroundStyle(Theme.secondary)
                            }
                            .frame(minHeight: Theme.Size.touch)
                        }
                    } header: {
                        SectionHeader(title: settings.localized("About"))
                    }
                }
                .listRowBackground(Theme.surface)
                .listRowInsets(EdgeInsets(top: Theme.Space.small, leading: Theme.Space.regular,
                                         bottom: Theme.Space.small, trailing: Theme.Space.regular))
            }
            .appFormStyle()
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { windowWidth = $0 }
            .navigationTitle(settings.localized("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) { ScreenHeader(title: settings.localized("Settings")) }
                PadToolbarItem(placement: .topBarLeading) {
                    BackButton {
                        if let onDismiss { onDismiss() } else { dismiss() }
                    }
                }
            }
            .task {
                loadKits()
                await refreshNotificationStatus()
            }
        }
    }

    private func handleReminderToggle(_ enabled: Bool) {
        if enabled {
            Task {
                let center = UNUserNotificationCenter.current()
                let currentSettings = await center.notificationSettings()
                switch currentSettings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    settings.reviewReminderEnabled = true
                    notificationsDenied = false
                    ReviewReminderScheduler.shared.reschedule()
                case .denied:
                    settings.reviewReminderEnabled = false
                    notificationsDenied = true
                case .notDetermined:
                    do {
                        let granted = try await center.requestAuthorization(options: [.alert, .sound])
                        if granted {
                            settings.reviewReminderEnabled = true
                            notificationsDenied = false
                            ReviewReminderScheduler.shared.reschedule()
                        } else {
                            settings.reviewReminderEnabled = false
                            notificationsDenied = true
                        }
                    } catch {
                        settings.reviewReminderEnabled = false
                        notificationsDenied = true
                    }
                @unknown default:
                    settings.reviewReminderEnabled = false
                    notificationsDenied = true
                }
            }
        } else {
            settings.reviewReminderEnabled = false
            notificationsDenied = false
            ReviewReminderScheduler.shared.cancelAll()
        }
    }

    private func refreshNotificationStatus() async {
        let center = UNUserNotificationCenter.current()
        let currentSettings = await center.notificationSettings()
        if currentSettings.authorizationStatus != .denied {
            notificationsDenied = false
        } else if settings.reviewReminderEnabled {
            settings.reviewReminderEnabled = false
            notificationsDenied = true
            ReviewReminderScheduler.shared.cancelAll()
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
    @Environment(\.dismiss) private var dismiss

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
        .calmChassisBackground().foregroundStyle(Theme.ink)
        .navigationTitle("IBM Plex Sans")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) { ScreenHeader(title: "IBM Plex Sans") }
            PadToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
        }
    }
}

// MARK: - Progress Backup Section

@MainActor
private struct ProgressBackupSection: View {
    @Environment(SettingsManager.self) private var settings
    @State private var isExporting = false
    @State private var backupDocument: BackupDocument?
    @State private var isImporting = false
    @State private var alertMessage: String?
    @State private var showAlert = false

    var body: some View {
        Section {
            Button(settings.localized("Back up progress")) {
                do {
                    let data = try ProgressStore.shared.exportData()
                    backupDocument = BackupDocument(data: data)
                    isExporting = true
                } catch {
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
            .font(Theme.control)
            .frame(minHeight: Theme.Size.touch)

            Button(settings.localized("Restore from backup")) {
                isImporting = true
            }
            .font(Theme.control)
            .frame(minHeight: Theme.Size.touch)
        } header: {
            SectionHeader(title: settings.localized("Progress"))
        }
        .fileExporter(
            isPresented: $isExporting,
            document: backupDocument,
            contentType: .json,
            defaultFilename: "Smack-a-Pad backup \(AppCalendar.today()).json"
        ) { _ in }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json]
        ) { result in
            do {
                let url = try result.get()
                let accessing = url.startAccessingSecurityScopedResource()
                defer {
                    if accessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                let data = try Data(contentsOf: url)
                let summary = try ProgressStore.shared.importFromData(data)
                alertMessage = settings.languagePreference == .czech
                    ? czechRestoreMessage(summary.updatedLessonsCount)
                    : englishRestoreMessage(summary.updatedLessonsCount)
                showAlert = true
            } catch ProgressBackupError.newerVersion {
                alertMessage = settings.localized("This backup was created in a newer version of Smack-a-Pad. Update the app to restore it.")
                showAlert = true
            } catch {
                alertMessage = settings.localized("This file is not a Smack-a-Pad backup. Nothing was changed.")
                showAlert = true
            }
        }
        .alert(settings.localized("Progress"), isPresented: $showAlert) {
            Button(settings.localized("OK"), role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func czechRestoreMessage(_ count: Int) -> String {
        if count == 1 {
            return "Obnoveno. Aktualizována 1 lekce."
        } else if count >= 2 && count <= 4 {
            return "Obnoveno. Aktualizovány \(count) lekce."
        } else {
            return "Obnoveno. Aktualizováno \(count) lekcí."
        }
    }

    private func englishRestoreMessage(_ count: Int) -> String {
        if count == 1 {
            return "Restored. 1 lesson updated."
        } else {
            return String(format: settings.localized("Restored. %d lessons updated."), count)
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

private struct SoundKitSelectionView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.dismiss) private var dismiss
    let kits: [SampleKit]

    var body: some View {
        Form {
            Section {
                kitRow(id: "auto", title: settings.localized("Automatic"))
                ForEach(kits) { kit in
                    kitRow(id: kit.kitId, title: kit.name)
                }
            }
            .listRowBackground(Theme.surface)
        }
        .appFormStyle()
        .navigationTitle(settings.localized("Sound set"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) { ScreenHeader(title: settings.localized("Sound set")) }
            PadToolbarItem(placement: .topBarLeading) {
                BackButton { dismiss() }
            }
        }
    }

    private func kitRow(id: String, title: String) -> some View {
        Button {
            settings.selectedKitId = id
            dismiss()
        } label: {
            HStack {
                Text(title)
                    .font(Theme.control)
                    .foregroundStyle(Theme.ink)
                Spacer()
                if settings.selectedKitId == id {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.orange)
                }
            }
            .frame(minHeight: Theme.Size.touch)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// One-line volume row with label left, slider middle, and dB readout right.
private struct SoundSliderRow: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        HStack(spacing: 16) {
            Text(title)
                .font(Theme.display(16))
                .foregroundStyle(Theme.ink)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = SettingsManager.clampVolume(Int($0.rounded())) }
                ),
                in: 0...100,
                step: 5
            )
            .tint(Theme.orange)
            .frame(minHeight: Theme.Size.minimumTouch)

            Text(Self.formatDB(fromPercent: value))
                .font(Theme.display(14).monospacedDigit())
                .foregroundStyle(Theme.secondary)
                .frame(width: 56, alignment: .trailing)
                .lineLimit(1)
        }
        .frame(minHeight: 56)
    }

    static func formatDB(fromPercent percent: Int) -> String {
        guard percent > 0 else { return "−∞ dB" }
        guard percent < 100 else { return "0 dB" }
        let db = Int((20.0 * log10(Double(percent) / 100.0)).rounded())
        return db == 0 ? "0 dB" : "−\(abs(db)) dB"
    }
}

/// Compact 2-column cell per instrument role: bold abbreviation + English name, dB value, slider.
private struct InstrumentTrimCell: View {
    @Environment(SettingsManager.self) private var settings
    let voice: String

    /// Roles used by at least one bundled lesson.
    static let roles: [String] = {
        var pads = Set<Int>()
        for lesson in LessonStore.shared.lessons {
            for hit in lesson.hits + (lesson.hits8 ?? []) { pads.insert(hit.padIndex) }
        }
        return SampleGain.roles(usedPads: pads)
    }()

    private var pad: Int { AudioEngine.defaultPadVoices.firstIndex(of: voice) ?? 0 }
    private var trim: Int { settings.instrumentTrims[voice] ?? 0 }

    private var formattedTrim: String {
        if trim == 0 { return "0 dB" }
        if trim > 0 { return "+\(trim) dB" }
        return "−\(abs(trim)) dB"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                (Text(PadVoice.abbreviation(pad))
                    .font(Theme.strong(14))
                + Text(" \(PadVoice.displayName(pad))")
                    .font(Theme.display(14)))
                .foregroundColor(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

                Spacer(minLength: 4)

                Text(formattedTrim)
                    .font(Theme.display(14).monospacedDigit())
                    .foregroundStyle(trim == 0 ? Theme.secondary : Theme.ink)
                    .lineLimit(1)
            }

            Slider(
                value: Binding(
                    get: { Double(trim) },
                    set: {
                        var all = settings.instrumentTrims
                        all[voice] = SampleGain.clampTrim(Int($0.rounded()))
                        settings.instrumentTrims = all
                    }
                ),
                in: Double(SampleGain.trimRange.lowerBound)...Double(SampleGain.trimRange.upperBound),
                step: 1
            )
            .tint(Theme.orange)
            .frame(minHeight: 36)
            .contentShape(Rectangle())
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
    }
}
