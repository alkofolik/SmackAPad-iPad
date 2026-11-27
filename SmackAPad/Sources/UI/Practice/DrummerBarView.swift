import AVFoundation
import SwiftUI

enum TrainingTabMode: String, Equatable {
    case path
    case studioRig
    case library
}

/// Shared 3-way hardware navigation pill (`PATH · STUDIO RIG · LIBRARY`) used across Training, Studio Rig, and Library.
@MainActor
struct StudioHardwareTabSwitcher: View {
    @Environment(SettingsManager.self) private var settings

    let activeTab: TrainingTabMode
    let onSelect: (TrainingTabMode) -> Void

    var body: some View {
        HStack(spacing: 4) {
            tabButton(title: settings.localized("PATH"), tab: .path)
            tabButton(title: settings.localized("STUDIO RIG"), tab: .studioRig)
            tabButton(title: settings.localized("LIBRARY"), tab: .library)
        }
        .padding(4)
        .background(Theme.recessed, in: RoundedRectangle(cornerRadius: Theme.Radius.control + 2, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.control + 2, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        }
    }

    private func tabButton(title: String, tab: TrainingTabMode) -> some View {
        let active = activeTab == tab
        return Button {
            onSelect(tab)
        } label: {
            Text(title)
                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                .tracking(0.5)
                .foregroundStyle(active ? Color.black : Theme.secondary)
                .padding(.horizontal, 13)
                .frame(height: 34)
                .background(
                    active ? Theme.orange : Color.clear,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                )
                .shadow(color: active ? Theme.orange.opacity(0.45) : .clear, radius: 6)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

/// Top studio bar matching the hardware deck mockup:
/// `<` Back, `SMACK-A-PAD`, `LVL X · RANK XP/NEXT` + XP bar, `PATH | STUDIO RIG | LIBRARY` switch, and `🔑 KEYS` pill.
@MainActor
struct DrummerTopHeaderBar: View {
    @Environment(SettingsManager.self) private var settings

    let card: DrummerCardSnapshot
    let availableKeys: Int
    @Binding var selectedTab: TrainingTabMode
    let isCompact: Bool
    let onOpenLibrary: () -> Void
    let onBack: () -> Void

    private var language: AppLanguage { settings.languagePreference }

    var body: some View {
        Group {
            if isCompact {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        BackButton(action: onBack)
                        brandAndLevelBlock
                        Spacer(minLength: 4)
                        keysPill
                    }
                    tabSwitcher
                        .frame(maxWidth: .infinity)
                }
            } else {
                HStack(spacing: 16) {
                    BackButton(action: onBack)

                    brandAndLevelBlock
                        .frame(maxWidth: .infinity, alignment: .leading)

                    tabSwitcher

                    keysPill
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.sheet, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.sheet, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        }
    }

    private var brandAndLevelBlock: some View {
        HStack(spacing: 14) {
            Text("SMACK-A-PAD")
                .font(Theme.boldDisplay(20))
                .tracking(0.6)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("LVL \(card.level)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.ink)
                    Text("·")
                        .foregroundStyle(Theme.secondary)
                    Text(card.rank.title.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.orange)
                        .lineLimit(1)
                    Text("\(card.xp)/\(card.nextLevelXP)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.ledOff)
                        Capsule()
                            .fill(Theme.orange)
                            .frame(width: max(8, geo.size.width * card.levelProgress))
                            .shadow(color: Theme.orange.opacity(0.55), radius: 4)
                    }
                }
                .frame(maxWidth: 260, minHeight: 5, maxHeight: 5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Smack-a-Pad, Level \(card.level), \(card.rank.title), \(card.xp) / \(card.nextLevelXP) XP")
    }

    private var tabSwitcher: some View {
        StudioHardwareTabSwitcher(activeTab: selectedTab) { tab in
            if tab == .library {
                onOpenLibrary()
            } else {
                selectedTab = tab
            }
        }
    }

    private var keysPill: some View {
        Button {
            selectedTab = .studioRig
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "key.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(availableKeys > 0 ? Theme.orange : Theme.secondary)
                    .shadow(color: availableKeys > 0 ? Theme.orange.opacity(0.6) : .clear, radius: 4)
                Text("\(availableKeys) \(keysUnit(availableKeys).uppercased())")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(Theme.recessed, in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .strokeBorder(availableKeys > 0 ? Theme.orange : Theme.hairline, lineWidth: 1.25)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(availableKeys) \(keysUnit(availableKeys)), Studio Rig")
    }

    private func keysUnit(_ count: Int) -> String {
        switch language {
        case .czech:
            if count == 1 { return "klíč" }
            if (2...4).contains(count) { return "klíče" }
            return "klíčů"
        case .english:
            return count == 1 ? "key" : "keys"
        }
    }
}

/// Bottom-right 2×2 `DRUMMER ATTRIBUTES` (`REAL SKILL PROFILE`) hardware card with 10-segment LED bars.
@MainActor
struct DrummerAttributesCard: View {
    @Environment(SettingsManager.self) private var settings

    let card: DrummerCardSnapshot

    private var language: AppLanguage { settings.languagePreference }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(language == .czech ? "ATRIBUTY BUBENÍKA" : "DRUMMER ATTRIBUTES")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(0.6)
                    .foregroundStyle(Color.white.opacity(0.88))
                Spacer()
                Text(language == .czech ? "REÁLNÝ PROFIL" : "REAL SKILL PROFILE")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.45))
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(DrummerAttribute.allCases) { attr in
                    attributeCell(attr)
                }
            }
        }
        .padding(14)
        .background(Color(red: 0.078, green: 0.078, blue: 0.090), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1.25)
        }
    }

    private func attributeCell(_ attr: DrummerAttribute) -> some View {
        let value = card.attributes[attr]
        let litSegments = Int((Double(value) / 10.0).rounded())

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(attr.code)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 4)
                Text("\(value)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white)
                    .shadow(color: value > 0 ? Theme.orange.opacity(0.45) : .clear, radius: 4)
            }

            HStack(spacing: 2.5) {
                ForEach(0..<10, id: \.self) { idx in
                    let lit = idx < litSegments
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(lit ? Theme.orange : Color.white.opacity(0.10))
                        .frame(height: 5)
                        .shadow(color: lit ? Theme.orange.opacity(0.5) : .clear, radius: 2)
                }
            }

            Text(attributeSubtitle(attr))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.48))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color(red: 0.047, green: 0.047, blue: 0.055), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(attr.title(language: language)) \(value)")
    }

    private func attributeSubtitle(_ attr: DrummerAttribute) -> String {
        switch (attr, language) {
        case (.timing, .english): return "Pocket Precision"
        case (.timing, .czech): return "Přesnost v groovu"
        case (.speed, .english): return card.peakCleanBpm > 0 ? "Max \(card.peakCleanBpm) BPM" : "Clean Tempo Peak"
        case (.speed, .czech): return card.peakCleanBpm > 0 ? "Max \(card.peakCleanBpm) BPM" : "Nejvyšší čisté BPM"
        case (.technique, .english): return "Rudiments & Dynamics"
        case (.technique, .czech): return "Technika a dynamika"
        case (.memory, .english): return "Play Without Notation"
        case (.memory, .czech): return "Hraní zpaměti"
        }
    }
}

/// Bold studio hardware card showing Drummer Level, Rank, thick XP bar, 4 attribute gauges, and Keys -> Studio Rig.
@MainActor
struct DrummerBarView: View {
    @Environment(SettingsManager.self) private var settings

    let card: DrummerCardSnapshot
    let availableKeys: Int
    let isCompact: Bool
    let onOpenStudioRig: () -> Void

    private var language: AppLanguage { settings.languagePreference }

    var body: some View {
        Group {
            if isCompact {
                VStack(alignment: .leading, spacing: Theme.Space.controlGap) {
                    HStack(alignment: .center, spacing: Theme.Space.controlGap) {
                        levelAndRankBlock
                        Spacer(minLength: 8)
                        keysButton
                    }
                    attributesRow
                }
            } else {
                HStack(spacing: Theme.Space.regular) {
                    levelAndRankBlock
                        .frame(minWidth: 250, maxWidth: 290, alignment: .leading)

                    hardwareDivider

                    attributesRow
                        .frame(maxWidth: .infinity)

                    hardwareDivider

                    keysButton
                }
            }
        }
        .padding(.horizontal, Theme.Space.regular)
        .padding(.vertical, 14)
        .background(Color(red: 0.078, green: 0.078, blue: 0.090), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1.5)
        }
        .shadow(color: Color.black.opacity(0.35), radius: 8, y: 3)
    }

    private var hardwareDivider: some View {
        Rectangle()
            .fill(Color(red: 0.149, green: 0.149, blue: 0.169))
            .frame(width: 1, height: 52)
            .accessibilityHidden(true)
    }

    private var levelAndRankBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text("LVL \(card.level)")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.orange, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .shadow(color: Theme.orange.opacity(0.45), radius: 6, y: 1)

                VStack(alignment: .leading, spacing: 1) {
                    Text(card.rank.title)
                        .font(Theme.boldDisplay(19))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                    Text("\(card.xp) / \(card.nextLevelXP) XP")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.62))
                        .lineLimit(1)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(red: 0.047, green: 0.047, blue: 0.055))
                        .overlay {
                            Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                        }
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.orange, Theme.orange.opacity(0.82)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * card.levelProgress))
                        .shadow(color: Theme.orange.opacity(0.55), radius: 5)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Level \(card.level), \(card.rank.title), \(card.xp) / \(card.nextLevelXP) XP")
    }

    private var attributesRow: some View {
        HStack(spacing: Theme.Space.small) {
            ForEach(DrummerAttribute.allCases) { attr in
                let value = card.attributes[attr]
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(attr.code)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.58))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Spacer(minLength: 2)
                        Text("\(value)")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white)
                            .shadow(color: value > 0 ? Theme.orange.opacity(0.45) : .clear, radius: 5)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.10))
                            RoundedRectangle(cornerRadius: 2)
                                .fill(value > 0 ? Theme.orange : Color.clear)
                                .frame(width: geo.size.width * CGFloat(value) / 100.0)
                                .shadow(color: value > 0 ? Theme.orange.opacity(0.5) : .clear, radius: 3)
                        }
                    }
                    .frame(height: 4)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.047, green: 0.047, blue: 0.055), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(attr.title(language: language)) \(value)")
            }
        }
    }

    private var keysButton: some View {
        Button(action: onOpenStudioRig) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(availableKeys > 0 ? Theme.orange.opacity(0.22) : Color.white.opacity(0.06))
                        .frame(width: 34, height: 34)
                    Image(systemName: "key.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(availableKeys > 0 ? Theme.orange : Color.white.opacity(0.6))
                        .shadow(color: availableKeys > 0 ? Theme.orange.opacity(0.7) : .clear, radius: 4)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(availableKeys) \(keysUnit(availableKeys))")
                        .font(Theme.strong(15).monospacedDigit())
                        .foregroundStyle(Color.white)
                    Text("STUDIO RIG")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(0.6)
                        .foregroundStyle(availableKeys > 0 ? Theme.orange : Color.white.opacity(0.62))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 54)
            .background(Color(red: 0.118, green: 0.118, blue: 0.141), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(availableKeys > 0 ? Theme.orange : Color(red: 0.204, green: 0.204, blue: 0.239), lineWidth: 1.5)
            }
            .shadow(color: availableKeys > 0 ? Theme.orange.opacity(0.32) : .clear, radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(availableKeys) \(keysUnit(availableKeys)), Studio Rig")
    }

    private func keysUnit(_ count: Int) -> String {
        switch language {
        case .czech:
            if count == 1 { return "klíč" }
            if (2...4).contains(count) { return "klíče" }
            return "klíčů"
        case .english:
            return count == 1 ? "key" : "keys"
        }
    }
}

/// Lightweight preview player for auditioning drum kits and bonus jam tracks inside Studio Rig.
@MainActor
@Observable
final class StudioRigAudioPreview {
    private(set) var playingItemId: String?

    @ObservationIgnored private var playbackTask: Task<Void, Never>?
    @ObservationIgnored private var ownsAudio = false

    func toggleKitPreview(_ kitId: String, settings: SettingsManager) {
        let itemId = "kit:\(kitId)"
        if playingItemId == itemId {
            stop(releaseAudio: false)
            return
        }
        let demoHits: [LessonHit] = [
            LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 118),
            LessonHit(step: 0, padIndex: 2, hand: "R", velocity: 102),
            LessonHit(step: 2, padIndex: 11, hand: "R", velocity: 84),
            LessonHit(step: 4, padIndex: 13, hand: "L", velocity: 114),
            LessonHit(step: 4, padIndex: 11, hand: "R", velocity: 92),
            LessonHit(step: 6, padIndex: 12, hand: "L", velocity: 96),
            LessonHit(step: 8, padIndex: 12, hand: "L", velocity: 112),
            LessonHit(step: 10, padIndex: 11, hand: "R", velocity: 86),
            LessonHit(step: 12, padIndex: 13, hand: "L", velocity: 118),
            LessonHit(step: 14, padIndex: 7, hand: "R", velocity: 98)
        ]
        playOnce(itemId: itemId, kitId: kitId, hits: demoHits, bpm: 108, bars: 1, settings: settings)
    }

    func toggleTrackPreview(_ track: BonusJamTrack, settings: SettingsManager) {
        let itemId = "track:\(track.id)"
        if playingItemId == itemId {
            stop(releaseAudio: false)
            return
        }
        playOnce(itemId: itemId, kitId: track.kitId, hits: track.hits, bpm: track.bpm, bars: track.bars, settings: settings)
    }

    func stop(releaseAudio: Bool) {
        playbackTask?.cancel()
        playbackTask = nil
        playingItemId = nil
        let audio = AudioEngine.practice
        audio.stopPatternPlayback()
        if releaseAudio, ownsAudio {
            ownsAudio = false
            audio.stop()
        }
    }

    private func playOnce(
        itemId: String,
        kitId: String,
        hits: [LessonHit],
        bpm: Int,
        bars: Int,
        settings: SettingsManager
    ) {
        stop(releaseAudio: false)
        playingItemId = itemId

        let patternVolume = Float(settings.patternVolume) / 100
        let trims = settings.instrumentTrims
        let stepSeconds = 15.0 / Double(max(40, bpm))
        let sortedHits = hits.sorted { $0.step < $1.step }
        let barDuration = Double(max(1, bars) * 16) * stepSeconds

        playbackTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let audio = AudioEngine.practice
            do {
                _ = try await audio.prepare()
                try Task.checkCancellation()
                let kit = try await audio.loadKit(kitId)
                try Task.checkCancellation()
                guard self.playingItemId == itemId else { return }

                audio.selectKit(kit)
                audio.setPatternVolume(patternVolume)
                audio.setInstrumentTrims(trims)
                if !audio.isRunning {
                    try audio.start()
                    self.ownsAudio = true
                }

                let startSeconds = AVAudioTime.seconds(forHostTime: mach_absolute_time()) + 0.08
                var sounds: [AudioEngine.ScheduledSound] = []
                for loop in 0..<2 {
                    let loopOffset = Double(loop) * barDuration
                    for hit in sortedHits {
                        let time = startSeconds + loopOffset + Double(max(0, hit.step)) * stepSeconds
                        sounds.append(
                            AudioEngine.ScheduledSound(
                                audibleHostTime: AVAudioTime.hostTime(forSeconds: time),
                                padIndex: hit.padIndex,
                                velocity: hit.velocity
                            )
                        )
                    }
                }
                audio.schedule(sounds) { _ in }
                let totalSeconds = barDuration * 2 + 0.25
                try await Task.sleep(for: .seconds(totalSeconds))
                guard !Task.isCancelled, self.playingItemId == itemId else { return }
                self.playingItemId = nil
            } catch {
                self.playingItemId = nil
            }
        }
    }
}

/// Complete Studio Rig screen: 8 drum kits (unlock for 1 key + Test preview + open lessons),
/// instrument skin switcher, and bonus jam tracks.
@MainActor
struct StudioRigQuickSheet: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.dismiss) private var dismiss

    let highlightedKitId: String?
    let onOpenKitLessons: (DrumKitDescriptor) -> Void
    let onPlayBonusTrack: (BonusJamTrack) -> Void
    let onOpenLibrary: () -> Void

    private var language: AppLanguage { settings.languagePreference }

    var body: some View {
        NavigationStack {
            StudioRigContentView(
                highlightedKitId: highlightedKitId,
                onOpenKitLessons: onOpenKitLessons,
                onPlayBonusTrack: onPlayBonusTrack,
                onOpenLibrary: onOpenLibrary,
                onClose: { dismiss() }
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language == .czech ? "Hotovo" : "Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.orange)
                }
            }
        }
    }
}

/// Reusable Studio Rig view rendered inline under the `STUDIO RIG` tab or inside a sheet.
@MainActor
struct StudioRigContentView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(ProgressionManager.self) private var progression

    let highlightedKitId: String?
    let onOpenKitLessons: (DrumKitDescriptor) -> Void
    let onPlayBonusTrack: (BonusJamTrack) -> Void
    let onOpenLibrary: () -> Void
    var onClose: () -> Void = {}

    @State private var preview = StudioRigAudioPreview()

    private var language: AppLanguage { settings.languagePreference }
    private var availableKeys: Int { progress.drummerPath.availableKeys }
    private var card: DrummerCardSnapshot { progress.drummerCard(catalog: progression.catalog) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.wide) {
                headerBanner

                kitsSection

                skinsSection

                bonusTracksSection

                Button {
                    preview.stop(releaseAudio: true)
                    onClose()
                    onOpenLibrary()
                } label: {
                    HStack {
                        Text(language == .czech ? "Otevřít celou knihovnu lekcí" : "Open Full Lesson Library")
                            .font(Theme.action)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .padding(.horizontal, Theme.Space.regular)
                    .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(PadSecondaryButtonStyle())
            }
            .padding(Theme.Space.page)
            .frame(maxWidth: 1120)
            .frame(maxWidth: .infinity)
        }
        .background(Color(red: 0.047, green: 0.047, blue: 0.055).ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .onDisappear {
            preview.stop(releaseAudio: true)
        }
    }

    private var headerBanner: some View {
        HStack(spacing: Theme.Space.regular) {
            VStack(alignment: .leading, spacing: 4) {
                Text("STUDIO RIG")
                    .font(Theme.boldDisplay(28))
                    .foregroundStyle(Color.white)
                Text(language == .czech
                     ? "Odemykej sady bicích za klíče, testuj zvuk a přepínej vzhled přístroje."
                     : "Unlock drum kits with keys, test each sound set, and customize your deck.")
                .font(Theme.meta)
                .foregroundStyle(Color.white.opacity(0.68))
            }
            Spacer(minLength: 12)
            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.orange)
                    .shadow(color: Theme.orange.opacity(0.6), radius: 5)
                Text("\(availableKeys)")
                    .font(Theme.boldDisplay(22).monospacedDigit())
                    .foregroundStyle(Color.white)
                Text(keysLabel(availableKeys).uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.65))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(red: 0.078, green: 0.078, blue: 0.090), in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(availableKeys > 0 ? Theme.orange : Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1.5)
            }
        }
    }

    // MARK: - 1. 8 Drum Kits Grid

    private var kitsSection: some View {
        let unlockedCount = DrumKitCatalog.allKits.filter { progress.drummerPath.isKitUnlocked($0.kitId) }.count
        return VStack(alignment: .leading, spacing: Theme.Space.controlGap) {
            HStack {
                sectionHeader(language == .czech ? "SADY BICÍCH (8)" : "DRUM KITS (8)")
                Spacer()
                Text("\(unlockedCount)/\(DrumKitCatalog.allKits.count)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.orange)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: Theme.Space.controlGap)], spacing: Theme.Space.controlGap) {
                ForEach(DrumKitCatalog.allKits) { kit in
                    kitCard(kit)
                }
            }
        }
    }

    private func kitCard(_ kit: DrumKitDescriptor) -> some View {
        let unlocked = progress.drummerPath.isKitUnlocked(kit.kitId)
        let canUnlock = availableKeys >= kit.unlockCost
        let isHighlighted = kit.kitId == highlightedKitId
        let isTesting = preview.playingItemId == "kit:\(kit.kitId)"
        let genres = kit.boundGenres.prefix(3).joined(separator: " · ")

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(kit.name)
                        .font(Theme.strong(17))
                        .foregroundStyle(Color.white)
                    let epithet = kit.localizedClanEpithet(language: language)
                    Text(epithet.isEmpty ? kit.studioTitle : epithet)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                if unlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.orange)
                } else {
                    HStack(spacing: 3) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(kit.unlockCost)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(canUnlock ? Theme.orange : Color.white.opacity(0.45))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.06), in: Capsule())
                }
            }

            Text(genres)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.5))
                .lineLimit(1)

            HStack(spacing: 8) {
                Button {
                    preview.toggleKitPreview(kit.kitId, settings: settings)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isTesting ? "stop.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(isTesting ? (language == .czech ? "Stop" : "Stop") : "Test")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(isTesting ? Color.black : Color.white)
                    .padding(.horizontal, 10)
                    .frame(height: 36)
                    .background(
                        isTesting ? Theme.orange : Color(red: 0.118, green: 0.118, blue: 0.141),
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(isTesting ? Theme.orange : Color(red: 0.204, green: 0.204, blue: 0.239), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)

                if unlocked {
                    Button {
                        preview.stop(releaseAudio: true)
                        onClose()
                        onOpenKitLessons(kit)
                    } label: {
                        Text(language == .czech ? "Lekce" : "Lessons")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(Color(red: 0.118, green: 0.118, blue: 0.141), in: RoundedRectangle(cornerRadius: 6))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Theme.orange.opacity(0.65), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        let result = progress.unlockKit(kit.kitId)
                        if case .unlocked = result {
                            preview.stop(releaseAudio: true)
                            onClose()
                            onOpenKitLessons(kit)
                        }
                    } label: {
                        Text(language == .czech ? "Odemknout" : "Unlock")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(canUnlock ? Color.black : Color.white.opacity(0.45))
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(
                                canUnlock ? Theme.orange : Color.white.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canUnlock)
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.078, green: 0.078, blue: 0.090), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    isHighlighted ? Theme.orange : (unlocked ? Theme.orange.opacity(0.45) : Color(red: 0.149, green: 0.149, blue: 0.169)),
                    lineWidth: isHighlighted ? 2 : 1.25
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            if unlocked {
                preview.stop(releaseAudio: true)
                onClose()
                onOpenKitLessons(kit)
            } else if canUnlock {
                let result = progress.unlockKit(kit.kitId)
                if case .unlocked = result {
                    preview.stop(releaseAudio: true)
                    onClose()
                    onOpenKitLessons(kit)
                }
            }
        }
    }

    // MARK: - 2. Instrument Skin Switcher

    private var skinsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.controlGap) {
            sectionHeader(language == .czech ? "VZHLED PŘÍSTROJE" : "INSTRUMENT APPEARANCE")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: Theme.Space.controlGap)], spacing: Theme.Space.controlGap) {
                ForEach(StudioRigCatalog.skins) { skin in
                    skinCard(skin)
                }
            }
        }
    }

    private func skinCard(_ skin: InstrumentSkin) -> some View {
        let unlocked = progress.drummerPath.isSkinUnlocked(skin.id)
        let isSelected = settings.selectedInstrumentSkinId == skin.id
        let accent = hexColor(skin.accentHex)
        let chassis = hexColor(skin.chassisHex)
        let pad = hexColor(skin.padSurfaceHex)

        return Button {
            guard unlocked else { return }
            settings.selectedInstrumentSkinId = skin.id
        } label: {
            HStack(spacing: 12) {
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 4).fill(chassis).frame(width: 14, height: 34)
                    RoundedRectangle(cornerRadius: 4).fill(pad).frame(width: 14, height: 34)
                    RoundedRectangle(cornerRadius: 4).fill(accent).frame(width: 14, height: 34)
                        .shadow(color: accent.opacity(0.6), radius: 4)
                }
                .padding(4)
                .background(Color.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(skin.name)
                            .font(Theme.strong(14))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(accent)
                        } else if !unlocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.white.opacity(0.45))
                        }
                    }
                    Text(unlocked ? skin.subtitle : skin.unlockRequirement.description(language: language))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.58))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.078, green: 0.078, blue: 0.090), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? accent : Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: isSelected ? 2 : 1)
            }
            .opacity(unlocked ? 1 : 0.65)
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }

    // MARK: - 3. Bonus Jam Tracks

    private var bonusTracksSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.controlGap) {
            sectionHeader(language == .czech ? "BONUSOVÉ JAM TRACKY" : "BONUS JAM TRACKS")

            VStack(spacing: 8) {
                ForEach(StudioRigCatalog.bonusTracks) { track in
                    bonusTrackRow(track)
                }
            }
        }
    }

    private func bonusTrackRow(_ track: BonusJamTrack) -> some View {
        let unlocked = progress.drummerPath.isBonusTrackUnlocked(track.id)
            || track.unlockRequirement.isSatisfied(by: progress.drummerPath, card: card)
        let isPlaying = preview.playingItemId == "track:\(track.id)"

        return HStack(spacing: 12) {
            Image(systemName: unlocked ? "waveform" : "lock.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(unlocked ? Theme.orange : Color.white.opacity(0.42))
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(Theme.strong(15))
                    .foregroundStyle(Color.white)
                Text(unlocked
                     ? "\(track.genre) · \(track.bpm) BPM · \(track.subtitle)"
                     : track.unlockRequirement.description(language: language))
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.6))
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            if unlocked {
                Button {
                    preview.toggleTrackPreview(track, settings: settings)
                } label: {
                    Image(systemName: isPlaying ? "stop.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isPlaying ? Color.black : Color.white)
                        .frame(width: 38, height: 36)
                        .background(
                            isPlaying ? Theme.orange : Color(red: 0.118, green: 0.118, blue: 0.141),
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color(red: 0.204, green: 0.204, blue: 0.239), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)

                Button {
                    preview.stop(releaseAudio: true)
                    onClose()
                    onPlayBonusTrack(track)
                } label: {
                    Text(language == .czech ? "Hrát" : "Jam")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .background(Theme.orange, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(red: 0.078, green: 0.078, blue: 0.090), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color(red: 0.149, green: 0.149, blue: 0.169), lineWidth: 1)
        }
        .opacity(unlocked ? 1 : 0.72)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .tracking(0.8)
            .foregroundStyle(Color.white.opacity(0.68))
    }

    private func hexColor(_ hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }

    private func keysLabel(_ count: Int) -> String {
        switch language {
        case .czech:
            if count == 1 { return "klíč" }
            if (2...4).contains(count) { return "klíče" }
            return "klíčů"
        case .english:
            return count == 1 ? "key" : "keys"
        }
    }
}
