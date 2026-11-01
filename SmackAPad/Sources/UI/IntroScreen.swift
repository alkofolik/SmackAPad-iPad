import SwiftUI

/// Stage grouping for the 24 introductory exercises from `intro.json`.
enum IntroStage: String, CaseIterable, Identifiable {
    case pulse = "Pulse"
    case twoHands = "Two hands"
    case eighthNotes = "Eighth notes"
    case grooveVariations = "Groove variations"
    case controlAndDetail = "Control and detail"
    case firstFills = "First fills"

    var id: String { rawValue }

    func title(language: AppLanguage = SettingsManager.shared.languagePreference) -> String {
        switch self {
        case .pulse: return language.localized("1. PULSE")
        case .twoHands: return language.localized("2. TWO HANDS")
        case .eighthNotes: return language.localized("3. EIGHTH NOTES")
        case .grooveVariations: return language.localized("4. GROOVE VARIATIONS")
        case .controlAndDetail: return language.localized("5. CONTROL AND DETAIL")
        case .firstFills: return language.localized("6. FIRST FILLS")
        }
    }

    func subtitle(language: AppLanguage = SettingsManager.shared.languagePreference) -> String {
        switch self {
        case .pulse:
            return language.localized("Steady quarter-note pulse with one and both hands · lessons 1–4")
        case .twoHands:
            return language.localized("Hand coordination and alternation · lessons 5–8")
        case .eighthNotes:
            return language.localized("Eighth-note hi-hat patterns & stability · lessons 9–12")
        case .grooveVariations:
            return language.localized("Syncopations, offbeats & clap · lessons 13–16")
        case .controlAndDetail:
            return language.localized("Dynamics, open hi-hat & rests · lessons 17–20")
        case .firstFills:
            return language.localized("Snare and tom fills with clean return · lessons 21–24")
        }
    }
}

/// Standalone screen for the 24 intro exercises.
/// Always accessible without category unlocks; communicates stricter pass and mastery rules.
@MainActor
public struct IntroScreen: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @State private var store = LessonStore.shared

    /// Called when the user taps an exercise. The host presents the practice screen.
    let onSelect: (Lesson) -> Void

    public init(onSelect: @escaping (Lesson) -> Void) {
        self.onSelect = onSelect
    }

    private var introLessons: [Lesson] {
        store.lessons.filter { $0.cat == "intro" }
            .sorted { ($0.intro?.number ?? $0.id) < ($1.intro?.number ?? $1.id) }
    }

    private var passedCount: Int {
        introLessons.filter { progress.isPassed(lessonId: $0.id) }.count
    }

    private var masteredCount: Int {
        introLessons.filter { progress.isMastered(lessonId: $0.id) }.count
    }

    public var body: some View {
        List {
            Section {
                IntroRulesCard(passedCount: passedCount, masteredCount: masteredCount, totalCount: introLessons.count)
            }
            .listRowInsets(EdgeInsets(top: Theme.Space.small, leading: Theme.Space.regular, bottom: Theme.Space.small, trailing: Theme.Space.regular))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            ForEach(IntroStage.allCases) { stage in
                let stageLessons = introLessons.filter { $0.intro?.stage == stage.rawValue }
                if !stageLessons.isEmpty {
                    Section {
                        ForEach(stageLessons) { lesson in
                            Button {
                                onSelect(lesson)
                            } label: {
                                IntroExerciseRow(
                                    lesson: lesson,
                                    progressRecord: progress.progress(for: lesson.id)
                                )
                            }
                            .listRowBackground(Theme.background)
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: Theme.Space.tight) {
                            Text(stage.title(language: settings.languagePreference))
                                .font(Theme.display(Theme.Size.small))
                                .foregroundStyle(Theme.ink)
                            Text(stage.subtitle(language: settings.languagePreference))
                                .font(Theme.text(Theme.Size.dense))
                                .foregroundStyle(Theme.secondary)
                        }
                        .padding(.top, Theme.Space.small)
                    }
                }
            }

            // Fallback for any intro lessons not covered by predefined stages
            let remaining = introLessons.filter { lesson in
                !IntroStage.allCases.contains { $0.rawValue == lesson.intro?.stage }
            }
            if !remaining.isEmpty {
                Section(settings.localized("Other Intro Exercises")) {
                    ForEach(remaining) { lesson in
                        Button {
                            onSelect(lesson)
                        } label: {
                            IntroExerciseRow(
                                lesson: lesson,
                                progressRecord: progress.progress(for: lesson.id)
                            )
                        }
                        .listRowBackground(Theme.background)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .foregroundStyle(Theme.ink)
        .navigationTitle(settings.localized("Intro Exercises"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Communicates stricter rules for intro exercises: pass ≥80%, mastery 0 errors, always unlocked.
struct IntroRulesCard: View {
    @Environment(SettingsManager.self) private var settings
    let passedCount: Int
    let masteredCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            VStack(alignment: .leading, spacing: Theme.Space.tight) {
                HStack(spacing: Theme.Space.small) {
                    Text(settings.localized("INTRO SECTION RULES"))
                        .font(Theme.display(Theme.Size.body))
                        .foregroundStyle(Theme.ink)

                    Spacer()

                    Text(settings.localized("STRICTER RULES"))
                        .font(Theme.text(Theme.Size.dense))
                        .padding(.horizontal, Theme.Space.small)
                        .padding(.vertical, Theme.Space.tight)
                        .background(Theme.orange)
                        .foregroundStyle(Theme.black)
                }

                Text(settings.localized("Intro exercises build foundational motor habits and steady timing. They are always accessible without unlock requirements, but enforce stricter scoring limits than standard lessons:"))
                    .font(Theme.text(Theme.Size.small))
                    .foregroundStyle(Theme.secondary)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Space.regular) {
                    ruleItem(
                        value: "≥ 80 %",
                        title: settings.localized("Passing"),
                        detail: settings.localized("Standard lessons require 70%")
                    )
                    ruleItem(
                        value: settings.localized("0 errors"),
                        title: settings.localized("Mastery"),
                        detail: settings.localized("At target tempo (normally up to 2)")
                    )
                    ruleItem(
                        value: "\(passedCount) / \(totalCount)",
                        title: settings.localized("Passed"),
                        detail: settings.localized("%lld with full mastery", masteredCount)
                    )
                }
                VStack(spacing: Theme.Space.small) {
                    ruleItem(
                        value: "≥ 80 %",
                        title: settings.localized("Passing"),
                        detail: settings.localized("Standard lessons require 70%")
                    )
                    ruleItem(
                        value: settings.localized("0 errors"),
                        title: settings.localized("Mastery"),
                        detail: settings.localized("At target tempo (normally up to 2)")
                    )
                    ruleItem(
                        value: "\(passedCount) / \(totalCount)",
                        title: settings.localized("Passed"),
                        detail: settings.localized("%lld with full mastery", masteredCount)
                    )
                }
            }
        }
        .padding(Theme.Space.regular)
        .background(Theme.surface)
        .overlay(Rectangle().stroke(Theme.ink, lineWidth: Theme.Size.border))
    }

    private func ruleItem(value: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.tight) {
            Text(value)
                .font(Theme.display(Theme.Size.emphasis))
                .foregroundStyle(Theme.ink)
            Text(title)
                .font(Theme.text(Theme.Size.small))
                .foregroundStyle(Theme.ink)
            Text(detail)
                .font(Theme.text(Theme.Size.dense))
                .foregroundStyle(Theme.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Space.small)
        .background(Theme.background)
        .overlay(Rectangle().stroke(Theme.ink.opacity(0.25), lineWidth: 1))
    }
}

/// A single row for an intro exercise showing exercise number, title, goal, tempos, and pass/mastery stars.
struct IntroExerciseRow: View {
    @Environment(SettingsManager.self) private var settings
    let lesson: Lesson
    let progressRecord: LessonProgress?

    private var number: Int {
        lesson.intro?.number ?? (lesson.id >= 10000 ? lesson.id - 10000 : lesson.id)
    }

    private var passed: Bool { progressRecord?.passed ?? false }
    private var mastery: Bool { progressRecord?.mastery ?? false }

    var body: some View {
        HStack(spacing: Theme.Space.regular) {
            // Exercise number badge
            Text(String(format: "%02d", number))
                .font(Theme.display(Theme.Size.body))
                .foregroundStyle(mastery ? Theme.background : (passed ? Theme.black : Theme.ink))
                .frame(width: 44, height: 44)
                .background(mastery ? Theme.ink : (passed ? Theme.orange : Theme.surface))
                .overlay(Rectangle().stroke(Theme.ink, lineWidth: Theme.Size.border))

            // Text column
            VStack(alignment: .leading, spacing: Theme.Space.tight) {
                Text(lesson.title)
                    .font(Theme.display(Theme.Size.listTitle))
                    .foregroundStyle(Theme.ink)

                if let goal = lesson.intro?.goal, !goal.isEmpty {
                    Text(goal)
                        .font(Theme.text(Theme.Size.small))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: Theme.Space.small) {
                    Text("\(lesson.startBpm) → \(lesson.targetBpm) BPM")
                    Text("·")
                    Text(settings.localized(lesson.bars == 1 ? "%lld bar" : "%lld bars", lesson.bars))
                    if !lesson.genre.isEmpty {
                        Text("·")
                        Text(lesson.genre)
                    }
                }
                .font(Theme.text(Theme.Size.dense))
                .foregroundStyle(Theme.secondary)
            }

            Spacer(minLength: Theme.Space.small)

            // Status stars & details
            VStack(alignment: .trailing, spacing: Theme.Space.tight) {
                HStack(spacing: Theme.Space.tight) {
                    // Star 1: Passed (≥80%)
                    StarShape()
                        .fill(passed ? Theme.ink : Theme.background)
                        .overlay(StarShape().stroke(Theme.ink, lineWidth: Theme.Size.border))
                        .frame(width: 20, height: 20)
                        .accessibilityLabel(settings.localized("Passed"))
                        .accessibilityValue(settings.localized(passed ? "yes" : "no"))

                    // Star 2: Mastery (0 errors at target BPM)
                    StarShape()
                        .fill(mastery ? Theme.ink : Theme.background)
                        .overlay(StarShape().stroke(Theme.ink, lineWidth: Theme.Size.border))
                        .frame(width: 20, height: 20)
                        .accessibilityLabel(settings.localized("Mastery"))
                        .accessibilityValue(settings.localized(mastery ? "yes" : "no"))
                }

                if let record = progressRecord, record.passed || record.bestScore > 0 {
                    let scorePercent = Int((record.bestScore * 100).rounded())
                    Text("\(scorePercent) % · \(record.currentBpm) BPM")
                        .font(Theme.text(Theme.Size.dense))
                        .monospacedDigit()
                        .foregroundStyle(Theme.ink)
                } else {
                    Text(settings.localized("Not played"))
                        .font(Theme.text(Theme.Size.dense))
                        .foregroundStyle(Theme.secondary)
                }
            }
        }
        .padding(.vertical, Theme.Space.small)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
