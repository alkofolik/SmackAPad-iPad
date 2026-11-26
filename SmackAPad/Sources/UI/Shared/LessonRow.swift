import SwiftUI

/// 10pt-radius hardware card container for a list of `LessonRow` items separated by 1pt hairlines.
struct LessonRowsPanel<Row: View>: View {
    let lessons: [Lesson]
    @ViewBuilder let row: (Lesson) -> Row

    var body: some View {
        HardwareCard {
            ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                if index > 0 {
                    HardwareDivider(inset: 0)
                }
                row(lesson)
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

/// Shared hardware lesson row used across `LibraryScreen`, `IntroScreen`, and review lists.
/// Replaces the redundant status circle with a vertical LED status bar and monospaced lesson number,
/// and aligns preview controls, `LessonPatternStrip`, stars, and the 6pt `ⓘ` button.
struct LessonRow: View {
    let lesson: Lesson
    let settings: SettingsManager
    let progress: ProgressStore
    var number: Int = 0
    var showTechnique: Bool = false
    var locked: Bool = false
    var purchaseLocked: Bool = false
    var isNext: Bool = false
    var introGoal: String? = nil
    var isPreviewPlaying: Bool = false
    var previewAnchorHostTime: UInt64 = 0
    var previewSecondsPerStep: Double = 0
    var onTogglePreview: (() -> Void)? = nil
    let onSelect: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicType

    private var record: LessonProgress? { progress.progress(for: lesson.id) }
    private var stars: Int { LibraryStarFilter.stars(record) }

    private var stateTitle: String {
        if purchaseLocked { return "Purchase required" }
        if locked { return "Locked" }
        if isNext { return "Up next" }
        if record?.lastReviewFailDay == AppCalendar.today() {
            return "Tried today · not met yet"
        }
        return LibraryStarFilter.classify(record).title
    }

    private var ledColor: Color {
        if locked || purchaseLocked { return Theme.ledOff }
        if isNext || stars == 3 { return Theme.accent }
        if stars > 0 { return Theme.progressSegmentColor(for: stars) }
        if record?.hasPlayed == true { return Theme.secondary.opacity(0.55) }
        return Theme.ledOff
    }

    private var isDue: Bool {
        record?.reviewSchedule.isSettled != true && record?.reviewSchedule.isDue(on: AppCalendar.today()) == true
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            if !dynamicType.isAccessibilitySize {
                HStack(spacing: Theme.Space.controlGap) {
                    rowPrimaryContent
                    trailingControls.fixedSize(horizontal: true, vertical: false)
                }
            }
            VStack(alignment: .leading, spacing: Theme.Space.controlGap) {
                rowPrimaryContent
                trailingControls
            }
        }
        .padding(.horizontal, Theme.Space.regular)
        .padding(.vertical, Theme.Space.small)
        .frame(minHeight: Theme.Size.listRow)
        .background {
            // Keep the full row tappable without nesting its trailing controls.
            Button(action: onSelect) {
                Color.clear
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)
        }
        .background(isNext ? Theme.activeFill.opacity(0.45) : Color.clear)
        .lessonSource(lesson.id)
    }

    private var rowPrimaryContent: some View {
        Button(action: onSelect) {
            HStack(spacing: Theme.Space.controlGap) {
                statusLED
                    .accessibilityLabel(settings.localized(stateTitle))

                if number > 0 {
                    Text("\(number)")
                        .font(Theme.meta)
                        .monospacedDigit()
                        .foregroundStyle(Theme.secondary)
                        .frame(minWidth: 24, alignment: .trailing)
                }

                VStack(alignment: .leading, spacing: Theme.Space.tight) {
                    Text(settings.localized(lesson.title))
                        .font(Theme.rowTitle)
                        .foregroundStyle(locked ? Theme.secondary : Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    subtitleView
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: Theme.Size.listRow)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var statusLED: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(ledColor)
            .frame(width: 3, height: 28)
            .shadow(color: (isNext || stars == 3) && !locked ? Theme.accentGlow : .clear, radius: 4)
    }

    @ViewBuilder
    private var subtitleView: some View {
        if let introGoal {
            Text(introGoal)
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Space.small) {
                    genre
                    difficulty
                    tempo
                    padRequirement
                }
                .fixedSize(horizontal: true, vertical: false)
                VStack(alignment: .leading, spacing: Theme.Space.tight) {
                    HStack(spacing: Theme.Space.small) {
                        genre
                        difficulty
                        padRequirement
                    }
                    tempo
                }
            }
        }
    }

    private var trailingControls: some View {
        HStack(spacing: Theme.Space.small) {
            if purchaseLocked {
                HardwareIconButton(
                    systemName: "lock",
                    accessibilityLabel: settings.localized("Purchase required"),
                    compact: true,
                    action: onSelect
                )
            } else if locked {
                Image(systemName: "lock")
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
                    .frame(width: 24, alignment: .center)
                    .accessibilityLabel(settings.localized("Locked"))
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Space.regular) {
                    if onTogglePreview != nil || !lesson.hits.isEmpty {
                        HStack(spacing: Theme.Space.small) {
                            previewButton
                            LessonPatternStrip(
                                hits: lesson.hits,
                                dimmed: locked,
                                isPlaying: isPreviewPlaying,
                                anchorHostTime: previewAnchorHostTime,
                                secondsPerStep: previewSecondsPerStep
                            )
                        }
                    }
                    statusMarksAndStars
                }
                HStack(spacing: Theme.Space.small) {
                    previewButton
                    statusMarksAndStars
                }
            }
        }
    }

    private var statusMarksAndStars: some View {
        HStack(spacing: Theme.Space.small) {
            settledMark
            dueMark
            StarsView(record: record, lesson: lesson)
        }
    }

    @ViewBuilder
    private var previewButton: some View {
        if let onTogglePreview {
            HardwareIconButton(
                systemName: isPreviewPlaying ? "stop.fill" : "play.fill",
                accessibilityLabel: settings.localized(isPreviewPlaying ? "Stop preview" : "Play preview"),
                compact: true,
                isActive: isPreviewPlaying,
                action: onTogglePreview
            )
        }
    }

    @ViewBuilder
    private var settledMark: some View {
        if record?.reviewSchedule.isSettled == true {
            Image(systemName: "checkmark")
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
                .accessibilityLabel(settings.localized("Settled"))
        }
    }

    @ViewBuilder
    private var dueMark: some View {
        if isDue {
            let isTried = record?.lastReviewFailDay == AppCalendar.today()
            Image(systemName: "clock")
                .font(Theme.meta)
                .foregroundStyle(isTried ? Theme.accent : Theme.ink)
                .accessibilityLabel(settings.localized(isTried ? "Tried today · not met yet" : "Due for review"))
        }
    }

    private var genre: some View {
        Text(settings.localized(showTechnique ? LessonTechnique.classify(lesson).title : lesson.genre))
    }

    @ViewBuilder
    private var padRequirement: some View {
        if settings.activeProfile().isEightPad && EightPadLayout.slots(for: lesson) == nil {
            Text(settings.localized("16 pads"))
                .accessibilityLabel(settings.localized("Requires 16 pads"))
        }
    }

    private var difficulty: some View {
        HStack(spacing: Theme.Space.tight) {
            ForEach(1...5, id: \.self) { level in
                Circle()
                    .fill(level <= lesson.level ? Theme.ink : Theme.ledOff)
                    .overlay(Circle().stroke(level <= lesson.level ? Theme.ink : Theme.hairline, lineWidth: 1))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(settings.localized("Level %lld", lesson.level))
    }

    private var tempo: some View {
        let bpm = (record?.currentBpm ?? 0) > 0 ? record!.currentBpm : lesson.startBpm
        return Text("\(settings.localized(lesson.bars == 1 ? "%lld bar" : "%lld bars", lesson.bars)) · \(bpm) → \(lesson.targetBpm) BPM")
            .font(Theme.meta)
            .monospacedDigit()
            .fixedSize(horizontal: false, vertical: true)
    }
}
