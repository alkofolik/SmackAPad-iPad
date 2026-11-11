import SwiftUI

/// Pre-mix review flow: shows the drawn lineup with listen/try options,
/// and transitions smoothly into scored mix practice when Start mix is tapped.
struct MixFlowScreen: View {
    @Binding var lessons: [Lesson]
    @Binding var fromMemory: Bool
    var onAnotherMix: () -> Void
    var onMixStarted: (() -> Void)? = nil
    var onStepResult: ((PracticeStepOutcome) -> Void)? = nil

    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(MIDIInput.self) private var midi
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var mixStarted = false

    var body: some View {
        Group {
            if mixStarted, let first = lessons.first {
                PracticeScreen(
                    lesson: first,
                    settings: settings,
                    progress: progress,
                    midi: midi,
                    initialFromMemory: fromMemory,
                    mixLessons: lessons,
                    onStepResult: onStepResult
                )
            } else {
                MixLineupScreen(
                    lessons: lessons,
                    fromMemory: $fromMemory,
                    onAnotherMix: onAnotherMix,
                    onStartMix: {
                        onMixStarted?()
                        withAnimation(Theme.Motion.Policy(reduced: reduceMotion).animation(Theme.Motion.standard)) {
                            mixStarted = true
                        }
                    }
                )
            }
        }
    }
}

/// Shows the selected daily mix cards before the scored mix begins.
struct MixLineupScreen: View {
    let lessons: [Lesson]
    @Binding var fromMemory: Bool
    var onAnotherMix: () -> Void
    var onStartMix: () -> Void

    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(MIDIInput.self) private var midi
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var previewSession: PracticeSession?
    @State private var previewLessonID: Int?
    @State private var previewTask: Task<Void, Never>?
    @State private var tryLesson: Lesson?

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width >= 760 && sizeClass == .regular
            let columns = isLandscape ? 3 : 1

            VStack(alignment: .leading, spacing: Theme.Space.regular) {
                header

                ScrollView(.vertical) {
                    cardGrid(columns: columns, width: geometry.size.width - Theme.Space.page * 2)
                        .padding(.vertical, 2)
                }
                .scrollBounceBehavior(.basedOnSize)

                bottomBar(narrow: geometry.size.width < 660)
            }
            .padding(Theme.Space.page)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .calmChassisBackground()
            .foregroundStyle(Theme.ink)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear { stopPreview() }
        .onChange(of: lessons.map(\.id)) { _, _ in stopPreview() }
        .fullScreenCover(item: $tryLesson) { lesson in
            PracticeScreen(
                lesson: lesson,
                settings: settings,
                progress: progress,
                midi: midi,
                unscored: true
            )
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: Theme.Space.regular) {
            BackButton {
                stopPreview()
                dismiss()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(settings.localized("Daily mix"))
                    .font(Theme.display(30))
                    .foregroundStyle(Theme.ink)
                Text(mixSubtitle)
                    .font(Theme.display(15))
                    .foregroundStyle(Theme.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mixSubtitle: String {
        let countText = settings.languagePreference.localizedLessonCount(lessons.count)
        let barCounts = Set(lessons.map(\.bars))
        guard barCounts.count == 1, let bars = barCounts.first else {
            let totalBars = lessons.reduce(0) { $0 + $1.bars }
            return settings.localized("%@ · %@", countText, settings.localizedBarCount(totalBars))
        }
        if bars == 1 {
            return settings.localized("%@ · %lld bar each", countText, bars)
        }
        return settings.localized("%@ · %lld bars each", countText, bars)
    }

    @ViewBuilder
    private func cardGrid(columns: Int, width: CGFloat) -> some View {
        let rows = chunkedLessons(columns: columns)
        if columns == 1 {
            VStack(spacing: Theme.Space.regular) {
                ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                    cardView(index: index, lesson: lesson)
                }
            }
        } else {
            Grid(horizontalSpacing: Theme.Space.regular, verticalSpacing: Theme.Space.regular) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    GridRow {
                        ForEach(row, id: \.element.id) { item in
                            cardView(index: item.offset, lesson: item.element)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                        if row.count < columns {
                            ForEach(0..<(columns - row.count), id: \.self) { _ in
                                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func chunkedLessons(columns: Int) -> [[EnumeratedSequence<[Lesson]>.Element]] {
        let enumerated = Array(lessons.enumerated())
        guard columns > 1 else { return enumerated.map { [$0] } }
        return stride(from: 0, to: enumerated.count, by: columns).map { start in
            Array(enumerated[start..<min(start + columns, enumerated.count)])
        }
    }

    private func cardView(index: Int, lesson: Lesson) -> some View {
        let padCount = midi.activeProfile.padCount
        let today = AppCalendar.today()
        let isDue = progress.progress(for: lesson.id)?.reviewSchedule.isDueReview(on: today) == true
        let kindText = settings.localized(isDue ? "Review" : "Practice")

        return MixLineupCard(
            index: index,
            lesson: lesson,
            kindText: kindText,
            isReview: isDue,
            padCount: padCount,
            isPreviewing: previewLessonID == lesson.id,
            onTogglePreview: { togglePreview(for: lesson) },
            onTry: {
                stopPreview()
                tryLesson = lesson
            }
        )
    }

    @ViewBuilder
    private func bottomBar(narrow: Bool) -> some View {
        let memoryToggle = Toggle(isOn: $fromMemory) {
            Text(settings.localized("From memory"))
                .font(Theme.control)
                .foregroundStyle(Theme.white)
        }
        .tint(Theme.orange)
        .frame(minHeight: Theme.Size.touch)

        let anotherButton = Button {
            stopPreview()
            onAnotherMix()
        } label: {
            Text(settings.localized("Another mix"))
                .font(Theme.control)
                .foregroundStyle(Theme.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, Theme.Space.regular)
                .frame(minHeight: Theme.Size.control)
                .frame(maxWidth: narrow ? .infinity : nil)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .strokeBorder(Theme.white.opacity(0.35), lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .disabled(lessons.count < LearningRules.minimumMixLessons)

        let startButton = Button {
            stopPreview()
            onStartMix()
        } label: {
            Text(settings.localized("Start mix"))
                .font(Theme.action)
                .lineLimit(1)
                .frame(minWidth: narrow ? nil : 184, minHeight: Theme.Size.control)
                .frame(maxWidth: narrow ? .infinity : nil)
        }
        .buttonStyle(PadPrimaryButtonStyle())
        .disabled(lessons.count < LearningRules.minimumMixLessons)

        Group {
            if narrow {
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    memoryToggle
                    HStack(spacing: Theme.Space.small) {
                        anotherButton
                        startButton
                    }
                }
            } else {
                HStack(spacing: Theme.Space.regular) {
                    memoryToggle
                        .fixedSize()
                    Spacer(minLength: Theme.Space.regular)
                    HStack(spacing: Theme.Space.regular) {
                        anotherButton
                        startButton
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Space.regular)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Theme.black, in: RoundedRectangle(cornerRadius: 20))
    }

    private func togglePreview(for lesson: Lesson) {
        if previewLessonID == lesson.id {
            stopPreview()
            return
        }
        stopPreview()
        let session = PracticeSession(
            lesson: lesson,
            settings: settings,
            progress: progress,
            midi: midi,
            initialBpm: lesson.targetBpm,
            unscored: true,
            stopAfterSinglePass: true
        )
        session.onSinglePassEnded = { [weak session] in
            if previewSession === session {
                stopPreview()
            }
        }
        previewSession = session
        previewLessonID = lesson.id
        previewTask = Task { @MainActor in
            await session.prepare()
            guard !Task.isCancelled, previewLessonID == lesson.id, session.available else {
                if previewSession === session {
                    stopPreview()
                } else {
                    session.close()
                }
                return
            }
            session.listen = true
            session.start()
        }
    }

    private func stopPreview() {
        previewTask?.cancel()
        previewTask = nil
        previewSession?.onSinglePassEnded = nil
        previewSession?.close()
        previewSession = nil
        previewLessonID = nil
    }
}

private struct MixLineupCard: View {
    let index: Int
    let lesson: Lesson
    let kindText: String
    let isReview: Bool
    let padCount: Int
    let isPreviewing: Bool
    let onTogglePreview: () -> Void
    let onTry: () -> Void

    @Environment(SettingsManager.self) private var settings

    var body: some View {
        let padLabels = MixLineupLabels.labels(for: lesson, padCount: padCount)

        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HStack(alignment: .center, spacing: Theme.Space.small) {
                Text("\(index + 1)")
                    .font(Theme.strong(14).monospacedDigit())
                    .foregroundStyle(Theme.white)
                    .frame(width: 28, height: 28)
                    .background(Theme.black, in: Circle())

                Spacer(minLength: Theme.Space.tight)

                Text(kindText)
                    .font(Theme.display(12).weight(.semibold))
                    .foregroundStyle(isReview ? Theme.orange : Theme.secondary)
                    .lineLimit(1)
            }

            Text(settings.localized(lesson.title))
                .font(Theme.strong(20))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: Theme.Space.small)

            MixCardMiniPattern(lesson: lesson, padCount: padCount, labels: padLabels)
                .frame(maxWidth: .infinity)

            Spacer(minLength: Theme.Space.small)

            VStack(alignment: .leading, spacing: Theme.Space.small) {
                FlowLayout(spacing: 6) {
                    Text(settings.localized("%lld BPM", lesson.targetBpm))
                        .font(Theme.display(12).weight(.semibold).monospacedDigit())
                        .foregroundStyle(Theme.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.black, in: Capsule())

                    ForEach(padLabels.orderedPads, id: \.self) { pad in
                        if let name = padLabels.byPad[pad] {
                            Text(name)
                                .font(Theme.display(12).weight(.medium))
                                .foregroundStyle(Theme.ink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Theme.white, in: Capsule())
                                .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
                        }
                    }
                }

                HStack(spacing: Theme.Space.small) {
                    Button(action: onTogglePreview) {
                        HStack(spacing: 6) {
                            Image(systemName: isPreviewing ? "stop.fill" : "speaker.wave.2")
                                .font(.system(size: 13, weight: .semibold))
                            Text(settings.localized(isPreviewing ? "Stop" : "Listen"))
                                .font(Theme.control)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, minHeight: Theme.Size.touch)
                    }
                    .buttonStyle(PadSecondaryButtonStyle())

                    Button(action: onTry) {
                        Text(settings.localized("Try"))
                            .font(Theme.control)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, minHeight: Theme.Size.touch)
                    }
                    .buttonStyle(PadSecondaryButtonStyle())
                }
            }
        }
        .padding(Theme.Space.regular)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }
}

private struct MixLineupLabels {
    let orderedPads: [Int]
    let byPad: [Int: String]

    static func labels(for lesson: Lesson, padCount: Int) -> MixLineupLabels {
        let hits = lesson.hits(forPadCount: padCount)
        let used = Set(hits.map(\.padIndex))
        let rows = PadVoice.rowOrder.filter { used.contains($0) }
        var counts: [String: Int] = [:]
        for pad in rows {
            counts[PadVoice.displayName(pad), default: 0] += 1
        }
        var byPad: [Int: String] = [:]
        for pad in rows {
            let base = PadVoice.displayName(pad)
            byPad[pad] = (counts[base] ?? 0) > 1 ? "\(base) \(pad + 1)" : base
        }
        return MixLineupLabels(orderedPads: rows, byPad: byPad)
    }
}

private struct MixCardMiniPattern: View {
    let lesson: Lesson
    let padCount: Int
    let labels: MixLineupLabels

    private let barSteps = 16

    var body: some View {
        let barOneHits = lesson.hits(forPadCount: padCount).filter { $0.step >= 0 && $0.step < barSteps }
        let hitsByPad = Dictionary(grouping: barOneHits, by: \.padIndex).mapValues { hits in
            Set(hits.map(\.step))
        }

        VStack(alignment: .leading, spacing: 5) {
            ForEach(labels.orderedPads, id: \.self) { pad in
                let activeSteps = hitsByPad[pad] ?? []
                HStack(spacing: 8) {
                    Text(labels.byPad[pad] ?? PadVoice.displayName(pad))
                        .font(Theme.strong(11))
                        .foregroundStyle(Theme.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(width: 66, alignment: .leading)

                    HStack(spacing: 2) {
                        ForEach(0..<barSteps, id: \.self) { step in
                            let isHit = activeSteps.contains(step)
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(isHit ? Theme.white : Theme.black.opacity(step.isMultiple(of: 4) ? 0.18 : 0.10))
                                .frame(maxWidth: .infinity)
                                .frame(height: 13)
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(PracticeBandStyle.orange, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
    }
}
