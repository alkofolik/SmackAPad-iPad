import SwiftUI

struct HelpIllustration: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var labelSize = 16.0
    @ScaledMetric(relativeTo: .body) private var captionSize = 20.0
    @State private var startedAt: Date?
    @State private var hasAnimated = false

    let topic: HelpTopic
    let lesson: Lesson?

    private var still: Bool { reduceMotion || voiceOver }
    private var goalBpm: Int { lesson?.targetBpm ?? 100 }
    private var memoryBand: Color {
        BandTone.color(listen: false, memory: true, bpm: goalBpm, startBpm: 75, targetBpm: goalBpm)
    }

    private var animationDuration: Double? {
        switch topic {
        case .goal, .stars, .tempo: 0.8
        case .modes, .memory: 1.6
        case .reviews, .overview, .inputs: nil
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: still || startedAt == nil)) { timeline in
            let animatedProgress = startedAt.flatMap { start in
                animationDuration.map { min(1, max(0, timeline.date.timeIntervalSince(start) / $0)) }
            }
            let progress = still ? 1 : animatedProgress ?? (hasAnimated ? 1 : 0)

            VStack(alignment: .leading, spacing: Theme.Space.regular) {
                switch topic {
                case .goal: lessonExample(progress)
                case .modes: modesExample(progress)
                case .memory: memoryExample(progress)
                case .stars: starsExample(progress)
                case .tempo: tempoExample(progress)
                case .reviews: reviewsExample
                case .overview: overviewExample
                case .inputs: inputsExample
                }
                if topic != .overview && topic != .reviews { caption }
            }
            .font(Theme.text(labelSize))
        }
        .task(id: still) {
            guard !still, !hasAnimated, let animationDuration else {
                startedAt = nil
                return
            }
            hasAnimated = true
            startedAt = .now
            do { try await Task.sleep(for: .seconds(animationDuration)) } catch { return }
            startedAt = nil
        }
    }

    private var caption: some View {
        Text(settings.localized(topic.captionKey))
            .font(Theme.strong(captionSize))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func lessonExample(_ progress: Double) -> some View {
        let matched = progress >= 0.95
        return VStack(spacing: Theme.Space.regular) {
            HelpPatternBand(position: 4 * min(progress / 0.95, 1), matchedHit: matched, height: 116)
            HStack {
                VStack(spacing: Theme.Space.tight) {
                    HStack(spacing: Theme.Space.tight) {
                        pad(PadVoice.abbreviation(HelpPatternBand.hiHat))
                        pad(PadVoice.abbreviation(HelpPatternBand.snare), active: matched)
                    }
                    HStack(spacing: Theme.Space.tight) {
                        pad(PadVoice.abbreviation(HelpPatternBand.kick))
                        pad()
                    }
                }
                Spacer()
                starPair(count: 3, earned: matched ? 1 : 0)
            }
        }
        .accessibilityHidden(true)
    }

    private func modesExample(_ progress: Double) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            modeStrip("Listen", sound: "Pattern sound", symbol: "speaker.wave.2", scored: false,
                      position: progress < 0.5 ? progress * 30 : nil)
            modeStrip("Play", sound: "Metronome", symbol: "metronome", scored: true,
                      position: (0.5..<1).contains(progress) ? (progress - 0.5) * 30 : nil,
                      earned: progress == 1)
        }
    }

    private func modeStrip(
        _ mode: String, sound: String, symbol: String, scored: Bool, position: Double?, earned: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            FlowLayout(spacing: Theme.Space.regular) {
                hardwareLabel(mode)
                labeledSymbol(sound, symbol: symbol)
                labeledSymbol(scored ? "help.modes.scored" : "help.modes.unscored",
                              symbol: earned ? "star.fill" : (scored ? "star" : "minus.circle"))
            }
            HelpPatternBand(position: position, band: BandTone.color(
                listen: !scored, memory: false, bpm: 80, startBpm: 75, targetBpm: 100
            ))
        }
    }

    private func memoryExample(_ progress: Double) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            HStack(spacing: Theme.Space.small) {
                hardwareLabel("Start")
                Image(systemName: "arrow.right").accessibilityHidden(true)
                Text(4, format: .number.locale(Locale(identifier: settings.languagePreference.rawValue)))
                    .font(Theme.display(captionSize))
                    .padding(.horizontal, Theme.Space.regular)
                    .frame(minHeight: 38)
                    .foregroundStyle(Theme.black)
                    .background(memoryBand, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
                Image(systemName: "arrow.right").accessibilityHidden(true)
            }
            HelpPatternBand(height: 64)

            if settings.fadeMemoryNotes {
                diagramColumns {
                    memoryPhase("Pass 1 · notes shown", visibility: .shown,
                                emphasized: progress < 1.0 / 3)
                    memoryPhase("Pass 2 · notes fading", visibility: .faded,
                                emphasized: (1.0 / 3..<2.0 / 3).contains(progress))
                    memoryPhase("help.memory.hiddenFromThird", visibility: .hidden,
                                emphasized: (2.0 / 3..<1).contains(progress))
                }
            } else {
                memoryPhase("help.memory.hidden", visibility: .hidden)
            }
        }
    }

    private func memoryPhase(_ label: String, visibility: NoteVisibility, emphasized: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HelpPatternBand(visibility: visibility, band: memoryBand)
                .frame(minWidth: 145)
                .overlay { Rectangle().strokeBorder(Theme.ink, lineWidth: emphasized ? 2 : 0) }
            Text(settings.localized(label)).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func starsExample(_ progress: Double) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            ForEach(0..<3) { index in
                VStack(alignment: .leading, spacing: Theme.Space.tight) {
                    HStack(alignment: .top, spacing: Theme.Space.small) {
                        star(earned: progress >= Double(index + 1) / 4)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: Theme.Space.tight) {
                            Text(settings.localized(["Passed", "Goal tempo", "From memory"][index]))
                                .font(Theme.strong(labelSize))
                            Text(starRequirement(index))
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    if index == 2 {
                        HStack(spacing: Theme.Space.small) {
                            reviewDay
                            Image(systemName: "arrow.right")
                            reviewDay
                        }
                        .padding(.leading, 36)
                        .accessibilityHidden(true)
                    }
                }
            }
            Divider()
            HStack(spacing: Theme.Space.small) {
                starPair(count: 2, earned: 2)
                Image(systemName: "arrow.right")
                Label(settings.localized("Path"), systemImage: "point.topleft.down.to.point.bottomright.curvepath")
            }
            .accessibilityHidden(true)
        }
    }

    private var reviewDay: some View {
        Label(settings.localized("Review"), systemImage: "calendar.badge.checkmark")
            .padding(Theme.Space.small)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
    }

    private func starRequirement(_ index: Int) -> String {
        if index == 2 { return settings.localized("help.stars.reviews") }
        if let lesson {
            return StarRequirement.requirementText(for: index, lesson: lesson,
                padCount: settings.activeProfile().padCount, settings: settings)
        }
        return StarRequirement.requirementText(for: index,
            requiredRuns: StarStreak.requiredRuns(expectedHits: 8, isIntro: false),
            targetBpm: goalBpm, language: settings.languagePreference)
    }

    private func tempoExample(_ progress: Double) -> some View {
        // Keep both values below the same goal to illustrate an ordinary rise.
        let goal = 100
        let before = 80
        let after = 85
        return VStack(alignment: .leading, spacing: Theme.Space.regular) {
            FlowLayout(spacing: Theme.Space.small) {
                Text(settings.localized("Tempo")).font(Theme.strong(labelSize))
                Image(systemName: "minus.circle").accessibilityHidden(true)
                Text(bpm(before))
                Image(systemName: "plus.circle").accessibilityHidden(true)
            }
            .padding(Theme.Space.small)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.button))

            hardwareLabel("Play")
            HelpPatternBand(position: progress < 1 ? 15 * progress : nil, passed: progress >= 0.75)
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                TempoUpLabel(label: settings.localized("Tempo up: %lld → %lld BPM", before, after), size: captionSize)
                    .opacity(progress >= 0.75 ? 1 : 0)
                    .accessibilityHidden(progress < 0.75)
                Text("\(settings.localized("Goal tempo")) · \(bpm(goal))")
            }
        }
    }

    private var reviewsExample: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            caption
            FlowLayout(spacing: Theme.Space.regular) {
                labeledSymbol("From memory", symbol: "eye.slash")
                Text(bpm(goalBpm)).font(Theme.strong(labelSize))
            }
            if settings.fadeMemoryNotes {
                Text(settings.localized("help.reviews.warmups")).font(Theme.strong(labelSize))
                diagramColumns {
                    HelpPatternBand(band: memoryBand, height: 66)
                    HelpPatternBand(visibility: .faded, band: memoryBand, height: 66)
                }
            }
            Text(settings.localized("help.reviews.passes")).font(Theme.strong(labelSize))
            diagramColumns {
                HelpPatternBand(visibility: .hidden, band: memoryBand, passed: true, height: 66)
                HelpPatternBand(visibility: .hidden, band: memoryBand, passed: true, height: 66)
            }
            labeledSymbol("Did not count", symbol: "exclamationmark.circle")
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var overviewExample: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            overviewRow("Today", "help.overview.today", symbol: "sun.max")
            overviewRow("Training", "help.overview.training", symbol: "arrow.clockwise")
            overviewRow("Library", "help.overview.library", symbol: "square.grid.2x2")
            VStack(alignment: .leading, spacing: Theme.Space.tight) {
                Text(settings.localized("Training"))
                    .font(Theme.strong(labelSize))
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    overviewRow("Mix", "help.overview.mix", symbol: "shuffle")
                    overviewRow("Play after me", "App plays, you repeat. Without sheet music.", symbol: "repeat")
                }
                .padding(.leading, Theme.Space.regular)
            }
        }
    }

    private func overviewRow(_ title: String, _ detail: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Space.small) {
            Image(systemName: symbol).frame(width: 24).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.Space.tight) {
                Text(settings.localized(title)).font(Theme.strong(labelSize))
                Text(settings.localized(detail))
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Space.small)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
        .accessibilityElement(children: .combine)
    }

    private var inputsExample: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            Text(settings.localized("Settings"))
                .font(Theme.strong(labelSize))
                .accessibilityAddTraits(.isHeader)
            diagramColumns {
                input("Controller and calibration") {
                    HStack(spacing: Theme.Space.small) {
                        padMatrix(columns: 2, rows: 2)
                        Image(systemName: "slider.vertical.3").font(.system(size: 30))
                    }
                }
                input("Touch pads in portrait") {
                    padMatrix(columns: 4, rows: 4)
                        .padding(Theme.Space.small)
                        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.pad).strokeBorder(Theme.ink))
                }
                input("Keyboard") {
                    VStack(spacing: Theme.Space.tight) {
                        padMatrix(columns: 5, rows: 2)
                        pad(width: 64, height: 14)
                    }
                    .padding(Theme.Space.small)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.pad))
                }
            }
        }
    }

    private func input(_ title: String, @ViewBuilder drawing: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            drawing().frame(height: 106).accessibilityHidden(true)
            Text(settings.localized(title)).font(Theme.strong(labelSize))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func padMatrix(columns: Int, rows: Int) -> some View {
        VStack(spacing: Theme.Space.tight) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: Theme.Space.tight) {
                    ForEach(0..<columns, id: \.self) { _ in pad(width: 17, height: 17) }
                }
            }
        }
    }

    private func pad(_ label: String = "", active: Bool = false, width: CGFloat = 49, height: CGFloat = 38) -> some View {
        Text(label)
            .font(Theme.canvasDisplay(16))
            .foregroundStyle(active ? Theme.black : Theme.ink)
            .frame(width: width, height: height)
            .background(active ? Theme.orange : Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.button).strokeBorder(Theme.ink, lineWidth: active ? 2 : 1))
            .offset(y: active ? 2 : 0)
    }

    private func starPair(count: Int, earned: Int) -> some View {
        HStack(spacing: Theme.Space.small) {
            ForEach(0..<count, id: \.self) { index in star(earned: index < earned) }
        }
    }

    private func star(earned: Bool) -> some View {
        Image(systemName: earned ? "star.fill" : "star")
            .font(.system(size: 23, weight: .semibold))
            .foregroundStyle(earned ? Theme.starColor(for: 1) : Theme.ink)
    }

    private func hardwareLabel(_ key: String) -> some View {
        HardwareKeyFace(isSelected: false) {
            Text(settings.localized(key)).font(Theme.strong(labelSize))
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 34)
        }
    }

    private func labeledSymbol(_ key: String, symbol: String) -> some View {
        Label {
            Text(settings.localized(key)).fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: symbol).accessibilityHidden(true)
        }
    }

    private func bpm(_ value: Int) -> String {
        "\(value.formatted(.number.locale(Locale(identifier: settings.languagePreference.rawValue)))) BPM"
    }

    private func diagramColumns(@ViewBuilder content: () -> some View) -> some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Theme.Space.regular, content: content)
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: Theme.Space.regular, content: content)
                    VStack(alignment: .leading, spacing: Theme.Space.regular, content: content)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
