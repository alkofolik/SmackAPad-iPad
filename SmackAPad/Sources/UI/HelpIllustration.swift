import SwiftUI

struct HelpIllustration: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @ScaledMetric(relativeTo: .body) private var labelSize = 16.0
    @ScaledMetric(relativeTo: .body) private var captionSize = 18.0
    @State private var startedAt = Date.now

    private enum Drawing {
        case playLesson, hitColours, modes, starsAndTempo, whereNext
        case lesson, signals, stars, tempo, memory, reviews, training, library, controller, keyboard, setup

        var cycleDuration: TimeInterval? {
            switch self {
            case .playLesson, .signals, .starsAndTempo, .tempo: 6
            case .modes, .memory: 9
            default: nil
            }
        }
    }

    private let drawing: Drawing
    private let captionKey: String
    private let topic: HelpTopic?

    init(topic: HelpTopic) {
        self.topic = topic
        captionKey = topic.captionKey
        drawing = switch topic {
        case .lesson: .lesson
        case .modes: .modes
        case .signals: .signals
        case .stars: .stars
        case .tempo: .tempo
        case .memory: .memory
        case .reviews: .reviews
        case .training: .training
        case .library: .library
        case .controller: .controller
        case .keyboard: .keyboard
        case .setup: .setup
        }
    }

    init(card: TutorialCard) {
        topic = nil
        captionKey = card.captionKey
        drawing = switch card {
        case .playLesson: .playLesson
        case .hitColours: .hitColours
        case .modes: .modes
        case .starsAndTempo: .starsAndTempo
        case .whereNext: .whereNext
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            if let duration = drawing.cycleDuration, !reduceMotion, !voiceOver {
                TimelineView(.animation(minimumInterval: 1.0 / 24)) { timeline in
                    let elapsed = max(0, timeline.date.timeIntervalSince(startedAt))
                    illustration(elapsed.truncatingRemainder(dividingBy: duration) / duration)
                }
                .onAppear { startedAt = .now }
            } else {
                illustration(nil)
            }

            let lines = caption.components(separatedBy: "\n")
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                ForEach(lines.indices, id: \.self) { index in
                    Text(lines[index]).fixedSize(horizontal: false, vertical: true)
                }
            }
            .font(Theme.text(captionSize))
        }
        .font(Theme.text(labelSize))
        .padding(.vertical, Theme.Space.regular)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var caption: String {
        switch topic {
        case .stars:
            settings.localized(captionKey, Int((Scoring.passMark * 100).rounded()))
        case .memory:
            settings.localized(captionKey, settings.localized("Fade notes in From memory"))
        case .reviews:
            settings.localized(captionKey, Int((Scoring.passMark * 100).rounded()))
        default:
            settings.localized(captionKey)
        }
    }

    @ViewBuilder
    private func illustration(_ progress: Double?) -> some View {
        switch drawing {
        case .playLesson: lessonExample(progress)
        case .hitColours:
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                HelpPatternBand(height: 86, showHitColours: true)
                hitKey
            }
        case .modes: modesExample(progress)
        case .starsAndTempo:
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                starKey
                tempoExample(progress, showIncrease: false)
            }
        case .whereNext: destinations
        case .lesson: lessonMap
        case .signals: signalsExample(progress)
        case .stars:
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                starKey
                tags([
                    (PracticeMode.learning.title, "plus.circle"),
                    (PracticeMode.challenge.title, "arrow.right")
                ])
            }
        case .tempo: tempoExample(progress, showIncrease: true)
        case .memory: memoryExample(progress)
        case .reviews: reviewExample
        case .training: trainingExample
        case .library:
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                tags([("Path", "signpost.right"), ("Genres", "music.note"), ("Techniques", "hand.tap")])
                tags([("help.library.stage", "lock"), ("help.library.progress", "star.fill")])
            }
        case .controller: controllerExample
        case .keyboard: keyboardExample
        case .setup:
            tags([("Sound kit", "speaker.wave.2"), ("Timing calibration", "metronome"),
                  ("Back up progress", "square.and.arrow.up")])
        }
    }

    private func lessonExample(_ progress: Double?) -> some View {
        let step = progress.map { min($0 / 0.85, 1) * 31 } ?? 4
        let matched = progress == nil || (4..<7).contains(step) || (20..<23).contains(step)
        return VStack(alignment: .leading, spacing: Theme.Space.small) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Space.regular) {
                    label("help.lesson.padRow", "arrow.down").fixedSize()
                    label("help.lesson.now", "arrow.down").fixedSize()
                }
                VStack(alignment: .leading) {
                    label("help.lesson.padRow", "arrow.down")
                    label("help.lesson.now", "arrow.down")
                }
            }
            HelpPatternBand(position: step, matchedHit: matched, height: 108, bars: 2)
            HStack {
                pad("SN", active: matched)
                    .accessibilityHidden(true)
                Spacer()
                key("Start")
            }
        }
    }

    private var lessonMap: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                HStack(spacing: Theme.Space.regular) {
                    marker(1, "info.circle")
                    marker(2, "list.bullet.rectangle")
                    marker(3, "questionmark.circle")
                    marker(4, "slider.horizontal.3")
                }
                HStack(spacing: Theme.Space.regular) {
                    marker(5, "eye.slash")
                    marker(6, "rectangle.split.2x2")
                }
            }
            .accessibilityHidden(true)
            HelpPatternBand(position: 4, matchedHit: true, height: 86)
            HStack(spacing: Theme.Space.regular) {
                marker(7, "metronome")
                marker(8, "star")
                marker(9, "play.fill")
            }
            .accessibilityHidden(true)
        }
    }

    private func marker(_ number: Int, _ symbol: String) -> some View {
        HStack(spacing: Theme.Space.tight) {
            Text("\(number)")
                .font(Theme.canvasDisplay(14))
                .frame(width: 24, height: 24)
                .foregroundStyle(Theme.black)
                .background(Theme.orange, in: Circle())
            Image(systemName: symbol).frame(minWidth: 22)
        }
    }

    private func modesExample(_ progress: Double?) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.tight) {
            ForEach(Array(LessonPlaybackMode.allCases.enumerated()), id: \.element) { index, mode in
                let active = progress.map { Int($0 * 3) == index } ?? (mode == .play)
                HStack(spacing: Theme.Space.small) {
                    key(mode.rawValue, selected: active)
                    Spacer(minLength: 0)
                    Image(systemName: mode == .listen ? "speaker.wave.2" : mode == .play ? "hand.tap" : "repeat")
                    Image(systemName: mode == .play ? "star.fill" : "star.slash")
                }
            }
        }
        .accessibilityHidden(true)
    }

    private var hitKey: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            hitRow("help.hit.correct", mark: .correct, symbol: "checkmark")
            hitRow("help.hit.off", mark: .off, symbol: "clock")
            hitRow("help.hit.wrong", mark: .wrong, symbol: "xmark")
        }
    }

    private func hitRow(_ key: String, mark: HitMark, symbol: String) -> some View {
        HStack(spacing: Theme.Space.small) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 38, height: 32)
                .foregroundStyle(Theme.black)
                .background(PracticeBandStyle.hitColor(mark), in: RoundedRectangle(cornerRadius: Theme.Radius.button))
                .accessibilityHidden(true)
            Text(settings.localized(key))
        }
    }

    private func signalsExample(_ progress: Double?) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            hitKey
            let tempo = progress.map { $0 < 0.5 ? 75 : 100 } ?? 100
            TimingCue(offset: progress.map { $0 < 0.5 ? -1 : 1 } ?? 1)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            HelpPatternBand(band: BandTone.color(listen: false, memory: false, bpm: tempo, startBpm: 75, targetBpm: 100), height: 72)
            tags([("help.signals.behind", "arrow.right"), ("help.signals.ahead", "arrow.left"), ("Details", "list.bullet")])
        }
    }

    private var starKey: some View {
        VStack(alignment: .leading, spacing: Theme.Space.tight) {
            ForEach(Array(StarRequirement.titleKeys.enumerated()), id: \.offset) { index, title in
                HStack(spacing: Theme.Space.small) {
                    Text(String(repeating: "★", count: index + 1))
                        .foregroundStyle(Theme.starColor(for: 1))
                        .accessibilityHidden(true)
                    Text(settings.localized(title))
                        .font(Theme.strong(labelSize))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(settings.localized("help.stars.label", index + 1, settings.localized(title)))
            }
        }
    }

    private func tempoExample(_ progress: Double?, showIncrease: Bool) -> some View {
        let before = 80
        let after = min(100, before + settings.bpmStep)
        let increased = progress.map { $0 > 0.55 } ?? false
        return VStack(alignment: .leading, spacing: Theme.Space.small) {
            keyFace("\(increased ? after : before) → 100 BPM", selected: true)
            label("help.tempo.tap", "arrow.down")
            VStack(alignment: .leading, spacing: Theme.Space.tight) {
                Text(settings.localized("Tempo")).font(Theme.strong(labelSize))
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Space.tight) { tempoSteps }.fixedSize()
                    VStack(alignment: .leading, spacing: Theme.Space.tight) { tempoSteps }
                }
                key("Starting tempo")
            }
            .padding(Theme.Space.small)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
            if showIncrease {
                TempoUpLabel(label: settings.localized("Tempo up: %lld → %lld BPM", before, after), size: labelSize)
                    .opacity(increased || progress == nil ? 1 : 0)
            }
        }
    }

    private var tempoSteps: some View {
        ForEach(["−5", "−1", "+1", "+5"], id: \.self) { keyFace($0) }
    }

    private func memoryExample(_ progress: Double?) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            tags([("From memory", "eye.slash"), ("Start", "play.fill"), ("help.lesson.countIn", "arrow.right")])
            if settings.fadeMemoryNotes {
                memoryPass("help.memory.shown", .shown, highlighted: progress.map { $0 < 1.0 / 3 } ?? false)
                memoryPass("help.memory.fading", .faded, highlighted: progress.map { (1.0 / 3..<2.0 / 3).contains($0) } ?? false)
                memoryPass("help.memory.hiddenFromThird", .hidden, highlighted: progress.map { $0 >= 2.0 / 3 } ?? false)
            } else {
                memoryPass("help.memory.hidden", .hidden, highlighted: false)
            }
        }
    }

    private func memoryPass(_ key: String, _ visibility: NoteVisibility, highlighted: Bool) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.tight) {
            Text(settings.localized(key))
            HelpPatternBand(visibility: visibility, band: memoryBand, height: 58)
                .overlay { Rectangle().strokeBorder(Theme.ink, lineWidth: highlighted ? 2 : 0) }
        }
    }

    private var memoryBand: Color {
        BandTone.color(listen: false, memory: true, bpm: 100, startBpm: 75, targetBpm: 100)
    }

    private var reviewExample: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            Text(settings.localized("help.reviews.timeline",
                ReviewScheduler.gaps[0], ReviewScheduler.gaps[1], ReviewScheduler.gaps[2], ReviewScheduler.gaps[3],
                settings.localized("Settled")))
                .font(Theme.strong(labelSize))
                .fixedSize(horizontal: false, vertical: true)
            if settings.fadeMemoryNotes {
                label("help.reviews.warmups", "eye")
            }
            label("help.reviews.twoPasses", "eye.slash")
            HStack(spacing: Theme.Space.small) {
                HelpPatternBand(visibility: .hidden, band: memoryBand, passed: true, height: 54)
                HelpPatternBand(visibility: .hidden, band: memoryBand, passed: true, height: 54)
            }
            label("Did not count", "exclamationmark.circle")
        }
    }

    private var destinations: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            Text(settings.localized("Home")).font(Theme.strong(labelSize))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: Theme.Space.small)],
                      alignment: .leading, spacing: Theme.Space.small) {
                destination("Intro", "play.circle", highlighted: true)
                destination("Library", "square.grid.2x2")
                destination("Training", "arrow.clockwise")
                destination("Today", "sun.max")
            }
            label("help.title", "questionmark.circle")
        }
    }

    private func destination(_ key: String, _ symbol: String, highlighted: Bool = false) -> some View {
        label(key, symbol)
            .padding(Theme.Space.small)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.touch, alignment: .leading)
            .foregroundStyle(highlighted ? Theme.black : Theme.ink)
            .background(highlighted ? Theme.orange : Theme.surface,
                        in: RoundedRectangle(cornerRadius: Theme.Radius.button))
    }

    private var trainingExample: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            label("Reviews", "1.circle")
            label("New lesson", "2.circle")
            label("Mix", "3.circle")
        }
    }

    private var controllerExample: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            padGrid()
                .accessibilityHidden(true)
            tags(MIDIPracticeAction.allCases.map { ($0.title, "circle") } + [("Tempo knob", "dial.medium")])
        }
    }

    private var keyboardExample: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            label("Play pads with keyboard", "keyboard")
            padGrid(["1234", "QWER", "ASDF", "ZXCV"])
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(settings.localized("help.keyboard.mapping"))
        }
    }

    private func padGrid(_ rows: [String] = Array(repeating: "    ", count: 4)) -> some View {
        VStack(spacing: Theme.Space.tight) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: Theme.Space.tight) {
                    ForEach(Array(rows[row].enumerated()), id: \.offset) { column, character in
                        pad(String(character), active: row == 0 && column == 0)
                    }
                }
            }
        }
    }

    private func pad(_ text: String, active: Bool) -> some View {
        Text(text)
            .font(Theme.canvasDisplay(16))
            .foregroundStyle(active ? Theme.black : Theme.ink)
            .frame(width: 36, height: 32)
            .background(active ? Theme.orange : Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.button).strokeBorder(Theme.hairline))
    }

    private func tags(_ items: [(String, String)]) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Theme.Space.regular) { tagLabels(items) }.fixedSize()
            VStack(alignment: .leading, spacing: Theme.Space.small) { tagLabels(items) }
        }
    }

    private func tagLabels(_ items: [(String, String)]) -> some View {
        ForEach(items.indices, id: \.self) { index in
            label(items[index].0, items[index].1)
        }
    }

    private func label(_ key: String, _ symbol: String) -> some View {
        Label {
            Text(settings.localized(key)).fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: symbol).accessibilityHidden(true)
        }
    }

    private func key(_ key: String, selected: Bool = false) -> some View {
        keyFace(settings.localized(key), selected: selected)
    }

    private func keyFace(_ title: String, selected: Bool = false) -> some View {
        HardwareKeyFace(isSelected: selected) {
            Text(title)
                .font(Theme.strong(labelSize))
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Theme.Space.small)
                .frame(minHeight: 34)
        }
    }
}
