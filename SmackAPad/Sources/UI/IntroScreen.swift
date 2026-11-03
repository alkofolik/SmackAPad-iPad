import SwiftUI

/// Stage grouping for the introductory exercises from `intro.json`.
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
            return language.localized("Dynamics, open hi-hat & rests · lessons 17–21")
        case .firstFills:
            return language.localized("Snare and tom fills with clean return · lessons 22–25")
        }
    }
}

/// Standalone screen for the introductory exercises.
/// Always accessible without category unlocks; communicates stricter pass and mastery rules.
@MainActor
public struct IntroScreen: View {
    @Environment(StoreManager.self) private var purchases
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @State private var store = LessonStore.shared
    @State private var showingRules = false

    /// Called when the user taps an exercise. The host presents the practice screen.
    let onSelect: (Lesson) -> Void

    public init(onSelect: @escaping (Lesson) -> Void) {
        self.onSelect = onSelect
    }

    private var introLessons: [Lesson] {
        store.libraryCatalog.introLessons
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
                Button { showingRules = true } label: {
                    Label(settings.localized("Rules"), systemImage: "info.circle")
                        .font(Theme.control)
                        .frame(minHeight: 48, alignment: .leading)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingRules, arrowEdge: .top) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Space.page) {
                            HStack {
                                Spacer()
                                Button(settings.localized("Close")) { showingRules = false }
                                    .font(Theme.control)
                                    .frame(minHeight: Theme.Size.touch)
                            }
                            IntroRulesCard(passedCount: passedCount, masteredCount: masteredCount,
                                           totalCount: introLessons.count)
                        }
                        .padding(Theme.Space.page)
                    }
                    .frame(width: 480, height: 580)
                    .background(Theme.background)
                    .foregroundStyle(Theme.ink)
                    .tint(Theme.orange)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Theme.background)
            }
            ForEach(IntroStage.allCases) { stage in
                let stageLessons = introLessons.filter { $0.intro?.stage == stage.rawValue }
                if !stageLessons.isEmpty {
                    Section {
                        ForEach(stageLessons) { exerciseRow($0) }
                    } header: {
                        SectionHeader(title: stage.title(language: settings.languagePreference),
                                      subtitle: stage.subtitle(language: settings.languagePreference))
                            .padding(.top, Theme.Space.small)
                    }
                }
            }
            let remaining = introLessons.filter { lesson in
                !IntroStage.allCases.contains { $0.rawValue == lesson.intro?.stage }
            }
            if !remaining.isEmpty {
                Section {
                    ForEach(remaining) { exerciseRow($0) }
                } header: { SectionHeader(title: settings.localized("Other Intro Exercises")) }
            }
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 60)
        .listRowInsets(EdgeInsets(top: 0, leading: Theme.Space.page, bottom: 0, trailing: Theme.Space.page))
        .scrollContentBackground(.hidden)
        .background(Theme.background).foregroundStyle(Theme.ink)
        .navigationTitle(settings.localized("Intro Exercises"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { ScreenHeader(title: settings.localized("Intro Exercises")) }
        }
    }

    private func exerciseRow(_ lesson: Lesson) -> some View {
        LibraryLessonRow(lesson: lesson, settings: settings, progress: progress,
                         number: (introLessons.firstIndex { $0.id == lesson.id } ?? 0) + 1,
                         purchaseLocked: !purchases.isUnlocked(lesson),
                         introGoal: (lesson.intro?.goal).map { settings.localized($0) }) {
            onSelect(lesson)
        }
        .listRowInsets(EdgeInsets(top: 0, leading: Theme.Space.page, bottom: 0, trailing: Theme.Space.page))
        .listRowBackground(Theme.background)
    }
}

/// Intro scoring rules are unchanged; the summary uses the shared screen rhythm.
struct IntroRulesCard: View {
    @Environment(SettingsManager.self) private var settings
    let passedCount: Int
    let masteredCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            SectionHeader(title: settings.localized("INTRO SECTION RULES"))
            Text(settings.localized("Intro exercises build foundational motor habits and steady timing. They are always accessible without unlock requirements, but enforce stricter scoring limits than standard lessons:"))
                .font(Theme.navigation).lineSpacing(7).foregroundStyle(Theme.secondary)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Space.page) { rules }
                VStack(alignment: .leading, spacing: Theme.Space.small) { rules }
            }
            ProgressLine(full: masteredCount, partial: max(0, passedCount - masteredCount), total: totalCount)
        }
        .padding(.vertical, Theme.Space.regular)
        .listRowInsets(EdgeInsets(top: 0, leading: Theme.Space.page, bottom: 0, trailing: Theme.Space.page))
        .listRowBackground(Theme.background)
    }

    @ViewBuilder private var rules: some View {
        ruleItem(value: "≥ 80 %", title: settings.localized("Passing"),
                 detail: settings.localized("Standard lessons require 70%"))
        ruleItem(value: settings.localized("0 errors"), title: settings.localized("Mastery"),
                 detail: settings.localized("At target tempo (normally up to 2)"))
        ruleItem(value: "\(passedCount) / \(totalCount)", title: settings.localized("Passed"),
                 detail: settings.localized("%lld with full mastery", masteredCount))
    }

    private func ruleItem(value: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            Text("\(title) · \(value)").font(Theme.control)
            Text(detail).font(Theme.meta).foregroundStyle(Theme.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
