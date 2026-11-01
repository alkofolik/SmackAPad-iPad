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

    func title(czech: Bool) -> String {
        switch self {
        case .pulse: return czech ? "1. PULS" : "1. PULSE"
        case .twoHands: return czech ? "2. OBĚ RUCE" : "2. TWO HANDS"
        case .eighthNotes: return czech ? "3. OSMINOVÉ NOTY" : "3. EIGHTH NOTES"
        case .grooveVariations: return czech ? "4. VARIACE GROOVŮ" : "4. GROOVE VARIATIONS"
        case .controlAndDetail: return czech ? "5. KONTROLA A DETAIL" : "5. CONTROL AND DETAIL"
        case .firstFills: return czech ? "6. PRVNÍ PŘECHODY" : "6. FIRST FILLS"
        }
    }

    func subtitle(czech: Bool) -> String {
        switch self {
        case .pulse:
            return czech ? "Stabilní čtvrťový tep jedné i obou rukou · lekce 1–4" : "Steady quarter-note pulse with one and both hands · lessons 1–4"
        case .twoHands:
            return czech ? "Souhra a střídání levé a pravé ruky · lekce 5–8" : "Hand coordination and alternation · lessons 5–8"
        case .eighthNotes:
            return czech ? "Osminový hi-hat doprovod a stabilita · lekce 9–12" : "Eighth-note hi-hat patterns & stability · lessons 9–12"
        case .grooveVariations:
            return czech ? "Synkopy, offbeaty a clap · lekce 13–16" : "Syncopations, offbeats & clap · lessons 13–16"
        case .controlAndDetail:
            return czech ? "Dynamika, otevřený hi-hat a pauzy · lekce 17–20" : "Dynamics, open hi-hat & rests · lessons 17–20"
        case .firstFills:
            return czech ? "Přechody na snare a tomy s návratem · lekce 21–24" : "Snare and tom fills with clean return · lessons 21–24"
        }
    }
}

/// Standalone screen for the 24 intro exercises.
/// Always accessible without category unlocks; communicates stricter pass and mastery rules.
@MainActor
public struct IntroScreen: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(MIDIInput.self) private var midi
    @State private var store = LessonStore.shared

    public init() {}

    private var czech: Bool { settings.languagePreference == .czech }

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
                IntroRulesCard(czech: czech, passedCount: passedCount, masteredCount: masteredCount, totalCount: introLessons.count)
            }
            .listRowInsets(EdgeInsets(top: Theme.Space.small, leading: Theme.Space.regular, bottom: Theme.Space.small, trailing: Theme.Space.regular))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            ForEach(IntroStage.allCases) { stage in
                let stageLessons = introLessons.filter { $0.intro?.stage == stage.rawValue }
                if !stageLessons.isEmpty {
                    Section {
                        ForEach(stageLessons) { lesson in
                            NavigationLink {
                                PracticeScreen(lesson: lesson, settings: settings, progress: progress, midi: midi)
                            } label: {
                                IntroExerciseRow(
                                    lesson: lesson,
                                    progressRecord: progress.progress(for: lesson.id),
                                    czech: czech
                                )
                            }
                            .listRowBackground(Theme.background)
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: Theme.Space.tight) {
                            Text(stage.title(czech: czech))
                                .font(Theme.display(Theme.Size.small))
                                .foregroundStyle(Theme.ink)
                            Text(stage.subtitle(czech: czech))
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
                Section(czech ? "Další úvodní cvičení" : "Other Intro Exercises") {
                    ForEach(remaining) { lesson in
                        NavigationLink {
                            PracticeScreen(lesson: lesson, settings: settings, progress: progress, midi: midi)
                        } label: {
                            IntroExerciseRow(
                                lesson: lesson,
                                progressRecord: progress.progress(for: lesson.id),
                                czech: czech
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
        .navigationTitle(czech ? "Úvodní cvičení" : "Intro Exercises")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Communicates stricter rules for intro exercises: pass ≥80%, mastery 0 errors, always unlocked.
struct IntroRulesCard: View {
    let czech: Bool
    let passedCount: Int
    let masteredCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            VStack(alignment: .leading, spacing: Theme.Space.tight) {
                HStack(spacing: Theme.Space.small) {
                    Text(czech ? "PRAVIDLA ÚVODNÍ SEKCE" : "INTRO SECTION RULES")
                        .font(Theme.display(Theme.Size.body))
                        .foregroundStyle(Theme.ink)

                    Spacer()

                    Text(czech ? "PŘÍSNĚJŠÍ LIMITY" : "STRICTER RULES")
                        .font(Theme.text(Theme.Size.dense))
                        .padding(.horizontal, Theme.Space.small)
                        .padding(.vertical, Theme.Space.tight)
                        .background(Theme.orange)
                        .foregroundStyle(Theme.black)
                }

                Text(czech ? "Úvodní cvičení slouží k osvojení základních motorických návyků a stabilního timingu. Jsou vždy odemčená bez nutnosti postupu, ale platí pro ně přísnější limity hodnocení než pro běžné lekce:" : "Intro exercises build foundational motor habits and steady timing. They are always accessible without unlock requirements, but enforce stricter scoring limits than standard lessons:")
                    .font(Theme.text(Theme.Size.small))
                    .foregroundStyle(Theme.secondary)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Space.regular) {
                    ruleItem(
                        value: "≥ 80 %",
                        title: czech ? "Splnění (Pass)" : "Passing",
                        detail: czech ? "Běžné lekce vyžadují 70 %" : "Standard lessons require 70%"
                    )
                    ruleItem(
                        value: czech ? "0 chyb" : "0 errors",
                        title: czech ? "Mistrovství" : "Mastery",
                        detail: czech ? "V cílovém tempu (běžně až 2)" : "At target tempo (normally up to 2)"
                    )
                    ruleItem(
                        value: "\(passedCount) / \(totalCount)",
                        title: czech ? "Splněno" : "Passed",
                        detail: czech ? "\(masteredCount) s plným mistrovstvím" : "\(masteredCount) with full mastery"
                    )
                }
                VStack(spacing: Theme.Space.small) {
                    ruleItem(
                        value: "≥ 80 %",
                        title: czech ? "Splnění (Pass)" : "Passing",
                        detail: czech ? "Běžné lekce vyžadují 70 %" : "Standard lessons require 70%"
                    )
                    ruleItem(
                        value: czech ? "0 chyb" : "0 errors",
                        title: czech ? "Mistrovství" : "Mastery",
                        detail: czech ? "V cílovém tempu (běžně až 2)" : "At target tempo (normally up to 2)"
                    )
                    ruleItem(
                        value: "\(passedCount) / \(totalCount)",
                        title: czech ? "Splněno" : "Passed",
                        detail: czech ? "\(masteredCount) s plným mistrovstvím" : "\(masteredCount) with full mastery"
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
    let lesson: Lesson
    let progressRecord: LessonProgress?
    let czech: Bool

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
                    Text("\(lesson.bars) \(lesson.bars == 1 ? (czech ? "takt" : "bar") : (czech ? "takty" : "bars"))")
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
                        .accessibilityLabel(czech ? "Splněno" : "Passed")
                        .accessibilityValue(passed ? (czech ? "ano" : "ne") : (czech ? "yes" : "no"))

                    // Star 2: Mastery (0 errors at target BPM)
                    StarShape()
                        .fill(mastery ? Theme.ink : Theme.background)
                        .overlay(StarShape().stroke(Theme.ink, lineWidth: Theme.Size.border))
                        .frame(width: 20, height: 20)
                        .accessibilityLabel(czech ? "Mistrovství" : "Mastery")
                        .accessibilityValue(mastery ? (czech ? "ano" : "ne") : (czech ? "yes" : "no"))
                }

                if let record = progressRecord, record.passed || record.bestScore > 0 {
                    let scorePercent = Int((record.bestScore * 100).rounded())
                    Text("\(scorePercent) % · \(record.currentBpm) BPM")
                        .font(Theme.text(Theme.Size.dense))
                        .monospacedDigit()
                        .foregroundStyle(Theme.ink)
                } else {
                    Text(czech ? "Nezahráno" : "Not played")
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
