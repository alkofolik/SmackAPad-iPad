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

struct SettingsValue: View {
    private let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text).font(Theme.meta).foregroundStyle(Theme.secondary)
    }
}

enum SettingsArea: String, CaseIterable, Identifiable {
    case sound, practice, controller, purchasesAndBackup, about
    #if DEBUG
    case developer
    #endif

    var id: Self { self }

    @MainActor
    func title(in settings: SettingsManager) -> String {
        switch self {
        case .sound: settings.localized("Sound")
        case .practice: settings.localized("Practice")
        case .controller: settings.localized("Controller")
        case .purchasesAndBackup: "\(settings.localized("Purchases")) / \(settings.localized("Progress"))"
        case .about: settings.localized("About")
        #if DEBUG
        case .developer: settings.localized("Developer")
        #endif
        }
    }
}

@MainActor
public struct SettingsView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(MIDIInput.self) private var midi
    @Environment(\.dismiss) private var dismiss

    @State private var kits: [SampleKit] = []
    @State private var isInstrumentVolumeExpanded = false
    @State private var notificationsDenied = false
    @State private var helpPresentation: HelpPresentation?
    @State private var selectedArea: SettingsArea = .sound
    @AccessibilityFocusState private var helpFocused: Bool
    @AppStorage("smackapad.practice.showPads") private var showPads = true
    @AppStorage("smackapad.practice.touchPadsInPortrait") private var touchPadsInPortrait = true
    @AppStorage("smackapad.practice.visibleBars") private var visibleBars = 4

    private var controllerStatus: String {
        midi.connectedControllerName ?? settings.localized("Not connected")
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
        GeometryReader { geometry in
            let width = geometry.size.width
            NavigationStack {
                VStack(spacing: 0) {
                    ScreenTopBar {
                        HardwareBackButton {
                            if let onDismiss { onDismiss() } else { dismiss() }
                        }
                    } center: {
                        Text(settings.localized("Settings"))
                            .font(Theme.screenTitle)
                            .foregroundStyle(Theme.ink)
                    } trailing: {
                        HardwareIconButton(
                            systemName: "questionmark",
                            accessibilityLabel: settings.localized("help.title")
                        ) {
                            helpPresentation = HelpPresentation(windowWidth: width)
                        }
                        .accessibilityFocused($helpFocused)
                        .helpDeck(presentation: $helpPresentation) { helpFocused = true }
                    }
                    .padding(.horizontal, Theme.Space.page)
                    .padding(.vertical, Theme.Space.small)
                    .background(Theme.chassis)

                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(height: 1)

                    if width >= 740 {
                        HStack(spacing: 0) {
                            sidebar
                            Rectangle().fill(Theme.hairline).frame(width: 1)
                            areaContent(selectedArea)
                                .id(selectedArea)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        }
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: Theme.Space.page) {
                                HardwareCard {
                                    ForEach(Array(SettingsArea.allCases.enumerated()), id: \.element.id) { index, area in
                                        if index > 0 {
                                            HardwareDivider()
                                        }
                                        NavigationLink {
                                            areaDetailScreen(area)
                                        } label: {
                                            HStack(spacing: Theme.Space.controlGap) {
                                                areaLabel(area)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(Theme.secondary)
                                            }
                                            .padding(.horizontal, Theme.Space.regular)
                                            .padding(.vertical, 12)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .frame(maxWidth: 700, alignment: .leading)
                            .padding(Theme.Space.page)
                            .frame(maxWidth: .infinity)
                        }
                        .scrollBounceBehavior(.basedOnSize)
                    }
                }
                .background(Theme.chassis.ignoresSafeArea())
                .foregroundStyle(Theme.ink)
                .navigationBarBackButtonHidden(true)
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        .task {
            loadKits()
            await refreshNotificationStatus()
        }
    }

    private var sidebar: some View {
        ScrollView {
            VStack(spacing: Theme.Space.tight) {
                ForEach(SettingsArea.allCases) { area in
                    let isSelected = area == selectedArea
                    let shape = RoundedRectangle(cornerRadius: Theme.Radius.control)
                    Button { selectedArea = area } label: {
                        areaLabel(area)
                            .padding(.horizontal, Theme.Space.regular)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                if isSelected {
                                    shape
                                        .fill(Theme.surfaceElevated)
                                        .overlay {
                                            shape.strokeBorder(Theme.hairline, lineWidth: 1)
                                        }
                                }
                            }
                            .overlay(alignment: .leading) {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 1.5)
                                        .fill(Theme.orange)
                                        .frame(width: 3)
                                        .padding(.vertical, 8)
                                        .padding(.leading, 4)
                                }
                            }
                            .contentShape(shape)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(Theme.Space.small)
        }
        .frame(width: 250)
        .background(Theme.surface)
        .scrollBounceBehavior(.basedOnSize)
    }

    private func areaLabel(_ area: SettingsArea) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.tight) {
            Text(area.title(in: settings))
                .font(Theme.control)
                .foregroundStyle(Theme.ink)
            if area == .controller {
                Text(controllerStatus)
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
            }
        }
        .padding(.vertical, Theme.Space.tight)
        .frame(minHeight: Theme.Size.touch)
    }

    @ViewBuilder
    private func areaDetailScreen(_ area: SettingsArea) -> some View {
        if area == .controller {
            ControllerSetupView()
        } else {
            AreaDetailWrapper(title: area.title(in: settings)) {
                areaContent(area)
            }
        }
    }

    @ViewBuilder
    private func areaContent(_ area: SettingsArea) -> some View {
        if area == .controller {
            ControllerSetupView(isEmbeddedInSettings: true)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.page) {
                    switch area {
                    case .sound:
                        soundSections
                    case .practice:
                        practiceSections
                        keyboardAndTouchPadSections
                    case .controller:
                        EmptyView()
                    case .purchasesAndBackup:
                        PurchasesSection()
                        ProgressBackupSection()
                    case .about:
                        aboutSections
                    #if DEBUG
                    case .developer:
                        LegacyProgressImportSection()
                        DebugDeveloperSection()
                    #endif
                    }
                }
                .frame(maxWidth: 700, alignment: .leading)
                .padding(Theme.Space.page)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    @ViewBuilder
    private var soundSections: some View {
        @Bindable var settings = settings
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HardwareSectionHeader(title: settings.localized("Sound"))

            HardwareCard {
                NavigationLink {
                    SoundKitSelectionView(kits: kits)
                } label: {
                    HardwareRow(title: settings.localized("Sound set")) {
                        HStack(spacing: Theme.Space.small) {
                            Text(selectedKitTitle)
                                .font(Theme.meta)
                                .foregroundStyle(Theme.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                HardwareDivider()
                SoundSliderRow(
                    title: settings.localized("Metronome"),
                    value: $settings.metronomeVolume
                )
                HardwareDivider()
                SoundSliderRow(
                    title: settings.localized("Pads"),
                    value: $settings.padsVolume
                )
                HardwareDivider()
                SoundSliderRow(
                    title: settings.localized("settings.sound.pattern"),
                    value: $settings.patternVolume
                )
                HardwareDivider()

                Button {
                    withAnimation(Theme.Motion.fast) {
                        isInstrumentVolumeExpanded.toggle()
                    }
                } label: {
                    HardwareRow(title: settings.localized("Instrument volume")) {
                        HStack(spacing: Theme.Space.small) {
                            let changedCount = settings.changedInstrumentTrimCount
                            if changedCount > 0 {
                                Text(settings.localized("changed %lld", changedCount))
                                    .font(Theme.meta.monospacedDigit())
                                    .foregroundStyle(Theme.secondary)
                            }
                            Image(systemName: isInstrumentVolumeExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(settings.localized(isInstrumentVolumeExpanded ? "Expanded" : "Collapsed"))

                if isInstrumentVolumeExpanded {
                    HardwareDivider()
                    VStack(alignment: .leading, spacing: Theme.Space.controlGap) {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: Theme.Space.small),
                                GridItem(.flexible(), spacing: Theme.Space.small)
                            ],
                            spacing: Theme.Space.small
                        ) {
                            ForEach(InstrumentTrimCell.roles, id: \.self) { voice in
                                InstrumentTrimCell(voice: voice)
                            }
                        }

                        Button {
                            settings.resetInstrumentTrims()
                        } label: {
                            Text(settings.localized("Reset all to 0 dB"))
                                .font(Theme.control)
                                .frame(minHeight: Theme.Size.touch)
                        }
                        .buttonStyle(PadSecondaryButtonStyle())
                        .disabled(settings.instrumentTrims.isEmpty)
                    }
                    .padding(Theme.Space.regular)
                }
            }

            Text(settings.localized("Automatic uses the lesson's sound kit or your active kit from Studio Rig."))
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var practiceSections: some View {
        @Bindable var settings = settings
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HardwareSectionHeader(title: settings.localized("Tempo auto-step (BPM)"))
            HardwareCard(padding: Theme.Space.regular) {
                PlexSegmentedPicker(
                    title: settings.localized("Tempo step"),
                    selection: $settings.bpmStep,
                    options: BpmStep.allCases.map { ($0.rawValue, "+\($0.rawValue) BPM") },
                    fitsColumn: true
                )
            }
            Text(settings.localized("Tempo automatically increases by this step after each clean pass until target tempo."))
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }

        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HardwareSectionHeader(title: settings.localized("Practice mode"))
            HardwareCard(padding: Theme.Space.regular) {
                PlexSegmentedPicker(
                    title: settings.localized("Practice mode"),
                    selection: $settings.practiceMode,
                    options: PracticeMode.allCases.map { ($0, settings.localized($0.title)) },
                    fitsColumn: true
                )
            }
            Text(settings.localized(settings.practiceMode.explanation))
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }

        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HardwareSectionHeader(title: settings.localized("Practice screen"))
            HardwareCard {
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    Text(settings.localized("Bars shown"))
                        .font(Theme.control)
                        .foregroundStyle(Theme.ink)
                    PlexSegmentedPicker(
                        title: settings.localized("Bars shown"),
                        selection: $visibleBars,
                        options: [
                            (1, settings.localized("1 bar")),
                            (2, settings.localized("%lld bars", 2)),
                            (3, settings.localized("%lld bars", 3)),
                            (4, settings.localized("All bars"))
                        ],
                        fitsColumn: true,
                        size: .compact
                    )
                }
                .padding(.horizontal, Theme.Space.regular)
                .padding(.vertical, 12)

                HardwareDivider()
                HardwareRow(title: settings.localized("Small pad layout")) {
                    HardwareToggle(isOn: $showPads)
                }
                HardwareDivider()
                HardwareRow(title: settings.localized("Touch pads in portrait")) {
                    HardwareToggle(isOn: $touchPadsInPortrait)
                }
                HardwareDivider()
                HardwareRow(title: settings.localized("Fade notes in From memory")) {
                    HardwareToggle(isOn: $settings.fadeMemoryNotes)
                }
                HardwareDivider()
                HardwareRow(title: settings.localized("Automatic peek in From memory")) {
                    HardwareToggle(isOn: $settings.autoPeekMemory)
                }
            }
            VStack(alignment: .leading, spacing: Theme.Space.tight) {
                Text(settings.localized("Shows a small pad layout in the lesson that lights up the pads you hit."))
                Text(settings.localized("After two missed passes the notes show for one pass. That pass does not count."))
            }
            .font(Theme.meta)
            .foregroundStyle(Theme.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HardwareSectionHeader(title: settings.localized("Training"))
            HardwareCard {
                HardwareRow(title: settings.localized("Review reminder")) {
                    HardwareToggle(
                        isOn: Binding(
                            get: { settings.reviewReminderEnabled },
                            set: { handleReminderToggle($0) }
                        )
                    )
                }

                if notificationsDenied {
                    HardwareDivider()
                    Text(settings.localized("Notifications are turned off in iPad Settings."))
                        .font(Theme.meta)
                        .foregroundStyle(Theme.destructive)
                        .padding(.horizontal, Theme.Space.regular)
                        .padding(.vertical, 12)
                }

                if settings.reviewReminderEnabled {
                    HardwareDivider()
                    HardwareRow(title: settings.localized("Time")) {
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
                        .labelsHidden()
                        .tint(Theme.orange)
                    }
                }
            }
        }

        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HardwareSectionHeader(title: settings.localized("Library"))
            HardwareCard {
                HardwareRow(title: settings.localized("Hide completed lessons")) {
                    HardwareToggle(isOn: $settings.hideCompletedLessons)
                }
                HardwareDivider()
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    Text(settings.localized("Next lesson from"))
                        .font(Theme.control)
                        .foregroundStyle(Theme.ink)
                    PlexSegmentedPicker(
                        title: settings.localized("Next lesson from"),
                        selection: $settings.nextLessonSource,
                        options: NextLessonSource.allCases.map { ($0.id, settings.localized($0.title)) },
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
    private var keyboardAndTouchPadSections: some View {
        @Bindable var settings = settings
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HardwareSectionHeader(title: settings.localized("Keyboard"))
            HardwareCard {
                if midi.isKeyboardConnected {
                    HardwareRow(title: settings.localized("Play pads with keyboard")) {
                        HardwareToggle(isOn: $settings.playPadsWithKeyboard)
                    }
                } else {
                    HardwareRow(title: settings.localized("No keyboard connected"))
                        .foregroundStyle(Theme.secondary)
                }

                ForEach(KeyboardPadMapping.rows, id: \.rowNumber) { row in
                    HardwareDivider()
                    HStack {
                        Text(settings.localized(row.label))
                            .font(Theme.control)
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(row.keys, id: \.self) { key in
                                Text(key)
                                    .font(Theme.meta)
                                    .foregroundStyle(Theme.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(Theme.recessed, in: RoundedRectangle(cornerRadius: Theme.Radius.control))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: Theme.Radius.control)
                                            .strokeBorder(Theme.hairline, lineWidth: 1)
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Space.regular)
                    .padding(.vertical, 10)
                    .frame(minHeight: Theme.Size.row)
                }
            }
        }

        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HardwareSectionHeader(title: settings.localized("Touch pads"))
            HardwareCard(padding: Theme.Space.regular) {
                if let pads = midi.padIndices {
                    let profile = midi.activeProfile
                    PadProfileGrid(profile: profile) { slot in
                        let padIndex = pads[profile.target(forSlot: slot)]
                        TouchPad(
                            number: slot + 1,
                            sound: PadNames.name(for: padIndex),
                            isActive: midi.pressedPadIndices.contains(padIndex)
                        ) { pressed in
                            midi.touch(padIndex: padIndex, isPressed: pressed)
                        }
                        .id("\(settings.activeProfileName)/\(slot)/\(padIndex)")
                    }
                } else {
                    Text(settings.localized("This lesson requires 16 pads."))
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary)
                }
            }
            if midi.activeProfile.isEightPad {
                Text(settings.localized("Eight physical slots follow the current lesson. Without a lesson, the base layout is shown."))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(settings.localized("Touch pads send the same pad events as MIDI."))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var aboutSections: some View {
        @Bindable var settings = settings
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HardwareSectionHeader(title: settings.localized("Appearance"))
            HardwareCard(padding: Theme.Space.regular) {
                PlexSegmentedPicker(
                    title: settings.localized("Appearance"),
                    selection: $settings.appearance,
                    options: AppAppearance.allCases.map { ($0, settings.localized($0.title)) },
                    fitsColumn: true
                )
            }
            Text(settings.localized("Choose light, dark or follow your system appearance."))
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }

        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HardwareSectionHeader(title: settings.localized("Language"))
            HardwareCard(padding: Theme.Space.regular) {
                PlexSegmentedPicker(
                    title: settings.localized("App language"),
                    selection: $settings.languagePreference,
                    options: AppLanguage.allCases.map { ($0, $0.displayName) },
                    fitsColumn: true
                )
            }
            Text(settings.localized("Choose Czech or English. Your lesson progress and controller mappings remain preserved."))
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }

        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HardwareSectionHeader(title: "IBM Plex Sans")
            HardwareCard {
                NavigationLink {
                    FontLicenceView()
                } label: {
                    HardwareRow(title: "SIL Open Font License 1.1") {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }

        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HardwareSectionHeader(title: settings.localized("About"))
            HardwareCard {
                NavigationLink {
                    AboutDetailView()
                } label: {
                    HardwareRow(title: settings.localized("About")) {
                        HStack(spacing: Theme.Space.small) {
                            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                            Text("v\(version)")
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

private struct AreaDetailWrapper<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            ScreenTopBar {
                HardwareBackButton { dismiss() }
            } center: {
                Text(title)
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

            content()
        }
        .background(Theme.chassis.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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
        VStack(spacing: 0) {
            ScreenTopBar {
                HardwareBackButton { dismiss() }
            } center: {
                Text("IBM Plex Sans")
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
        }
        .background(Theme.chassis.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HardwareSectionHeader(title: settings.localized("Progress"))

            HardwareCard(padding: Theme.Space.regular) {
                VStack(alignment: .leading, spacing: Theme.Space.controlGap) {
                    Button {
                        do {
                            let data = try ProgressStore.shared.exportData()
                            backupDocument = BackupDocument(data: data)
                            isExporting = true
                        } catch {
                            alertMessage = error.localizedDescription
                            showAlert = true
                        }
                    } label: {
                        Text(settings.localized("Back up progress"))
                            .font(Theme.control)
                            .frame(maxWidth: .infinity, minHeight: Theme.Size.touch)
                    }
                    .buttonStyle(PadSecondaryButtonStyle())

                    Button {
                        isImporting = true
                    } label: {
                        Text(settings.localized("Restore from backup"))
                            .font(Theme.control)
                            .frame(maxWidth: .infinity, minHeight: Theme.Size.touch)
                    }
                    .buttonStyle(PadSecondaryButtonStyle())
                }
            }
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
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HardwareSectionHeader(title: settings.localized("Import from legacy backup"))

            HardwareCard(padding: Theme.Space.regular) {
                Button { showingImporter = true } label: {
                    Text(settings.localized("Choose legacy backup JSON"))
                        .font(Theme.control)
                        .frame(maxWidth: .infinity, minHeight: Theme.Size.touch)
                }
                .buttonStyle(PadSecondaryButtonStyle())
            }
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
        VStack(spacing: 0) {
            ScreenTopBar {
                HardwareBackButton { dismiss() }
            } center: {
                Text(settings.localized("Sound set"))
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

            ScrollView {
                VStack(spacing: Theme.Space.small) {
                    kitRow(id: "auto", title: settings.localized("Automatic"))
                    ForEach(kits) { kit in
                        kitRow(id: kit.kitId, title: kit.name)
                    }
                }
                .frame(maxWidth: 700, alignment: .leading)
                .padding(Theme.Space.page)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Theme.chassis.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func kitRow(id: String, title: String) -> some View {
        let isSelected = settings.selectedKitId == id
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.panel)
        return Button {
            settings.selectedKitId = id
            dismiss()
        } label: {
            HStack(spacing: Theme.Space.controlGap) {
                Circle()
                    .fill(Theme.cavity)
                    .frame(width: 14, height: 14)
                    .overlay {
                        Circle()
                            .fill(isSelected ? Theme.orange : Theme.ledOff)
                            .frame(width: 8, height: 8)
                            .shadow(color: isSelected ? Theme.accentGlow : .clear, radius: isSelected ? 5 : 0)
                    }

                Text(title)
                    .font(Theme.control)
                    .foregroundStyle(Theme.ink)
                Spacer()
                if isSelected {
                    Text(Theme.sentenceCase(settings.localized("Active")))
                        .font(Theme.strong(13))
                        .foregroundStyle(Theme.orange)
                }
            }
            .padding(.horizontal, Theme.Space.regular)
            .padding(.vertical, 12)
            .frame(minHeight: Theme.Size.row)
            .background(isSelected ? Theme.surfaceElevated : Theme.surface, in: shape)
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(isSelected ? Theme.orange : Theme.hairline, lineWidth: isSelected ? 1.5 : 1)
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// One-line volume row with label left and hardware fader + dB readout right.
struct SoundSliderRow: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        HStack(spacing: Theme.Space.regular) {
            Text(title)
                .font(Theme.control)
                .foregroundStyle(Theme.ink)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            HardwareSlider(
                title: title,
                value: Binding(
                    get: { Double(value) },
                    set: { value = SettingsManager.clampVolume(Int($0.rounded())) }
                ),
                range: 0...100,
                step: 5,
                valueFormatter: { Self.formatDB(fromPercent: Int($0.rounded())) }
            )
        }
        .padding(.horizontal, Theme.Space.regular)
        .padding(.vertical, 8)
        .frame(minHeight: Theme.Size.rowLarge)
    }

    static func formatDB(fromPercent percent: Int) -> String {
        guard percent > 0 else { return "−∞ dB" }
        guard percent < 100 else { return "0 dB" }
        let db = Int((20.0 * log10(Double(percent) / 100.0)).rounded())
        return db == 0 ? "0 dB" : "−\(abs(db)) dB"
    }
}

/// Compact cell per instrument role with its name, dB value, and hardware slider.
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

    private static func formatTrim(_ value: Int) -> String {
        if value == 0 { return "0 dB" }
        if value > 0 { return "+\(value) dB" }
        return "−\(abs(value)) dB"
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.panel)
        VStack(alignment: .leading, spacing: Theme.Space.tight) {
            (Text(PadVoice.abbreviation(pad))
                + Text(" \(PadVoice.displayName(pad))"))
            .font(Theme.control)
            .foregroundStyle(Theme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.85)

            HardwareSlider(
                title: PadVoice.displayName(pad),
                value: Binding(
                    get: { Double(trim) },
                    set: {
                        var all = settings.instrumentTrims
                        all[voice] = SampleGain.clampTrim(Int($0.rounded()))
                        settings.instrumentTrims = all
                    }
                ),
                range: Double(SampleGain.trimRange.lowerBound)...Double(SampleGain.trimRange.upperBound),
                step: 1,
                valueFormatter: { Self.formatTrim(Int($0.rounded())) }
            )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Theme.recessed, in: shape)
        .overlay {
            shape.strokeBorder(Theme.hairline, lineWidth: 1)
        }
    }
}
