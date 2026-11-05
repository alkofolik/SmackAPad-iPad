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
        case .pulse: return language.localized("1. Pulse")
        case .twoHands: return language.localized("2. Two hands")
        case .eighthNotes: return language.localized("3. Eighth notes")
        case .grooveVariations: return language.localized("4. Groove variations")
        case .controlAndDetail: return language.localized("5. Control and detail")
        case .firstFills: return language.localized("6. First fills")
        }
    }

    func subtitle(language: AppLanguage = SettingsManager.shared.languagePreference) -> String {
        switch self {
        case .pulse:
            return language.localized("Steady quarter-note pulse with one and both hands · lessons 1–4")
        case .twoHands:
            return language.localized("Hand coordination and alternation · lessons 5–8")
        case .eighthNotes:
            return language.localized("Eighth-note hi-hat patterns and stability · lessons 9–12")
        case .grooveVariations:
            return language.localized("Syncopations, offbeats and clap · lessons 13–16")
        case .controlAndDetail:
            return language.localized("Dynamics, open hi-hat and rests · lessons 17–21")
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
    @Environment(\.accessibilityReduceMotion) private var reduced
    private var motion: Theme.Motion.Policy { .init(reduced: reduced) }
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

    private var isAllIntroCompleted: Bool {
        !introLessons.isEmpty && introLessons.allSatisfy { progress.isCompleted(lessonId: $0.id) }
    }

    private var visibleLessonIDs: [Int] {
        introLessons.compactMap { lesson in
            if settings.hideCompletedLessons && progress.isCompleted(lessonId: lesson.id) {
                return nil
            }
            return lesson.id
        }
    }

    private var hasAnyCompletedLesson: Bool {
        introLessons.contains { progress.isCompleted(lessonId: $0.id) }
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
                        .frame(minHeight: Theme.Size.touch, alignment: .leading)
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
            if isAllIntroCompleted && settings.hideCompletedLessons {
                Section {
                    allCompletedRow
                }
            } else {
                ForEach(IntroStage.allCases) { stage in
                    let stageLessons = introLessons.filter { $0.intro?.stage == stage.rawValue }
                    let visibleStageLessons = stageLessons.filter { !settings.hideCompletedLessons || !progress.isCompleted(lessonId: $0.id) }
                    if !visibleStageLessons.isEmpty {
                        Section {
                            ForEach(visibleStageLessons) { exerciseRow($0) }
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
                let visibleRemaining = remaining.filter { !settings.hideCompletedLessons || !progress.isCompleted(lessonId: $0.id) }
                if !visibleRemaining.isEmpty {
                    Section {
                        ForEach(visibleRemaining) { exerciseRow($0) }
                    } header: { SectionHeader(title: settings.localized("Other Intro Exercises")) }
                }
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
            if hasAnyCompletedLesson {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        settings.hideCompletedLessons.toggle()
                    } label: {
                        Label(
                            settings.localized(settings.hideCompletedLessons ? "Show completed" : "Hide completed"),
                            systemImage: settings.hideCompletedLessons ? "eye" : "eye.slash"
                        )
                        .font(Theme.control)
                        .frame(minHeight: Theme.Size.touch)
                    }
                    .accessibilityLabel(settings.localized(settings.hideCompletedLessons ? "Show completed" : "Hide completed"))
                }
            }
        }
        .motion(Theme.Motion.standard, value: visibleLessonIDs)
    }

    private var allCompletedRow: some View {
        HStack(spacing: Theme.Space.regular) {
            Text(settings.localized("All lessons completed"))
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
            Button {
                settings.hideCompletedLessons = false
            } label: {
                Text(settings.localized("Show completed"))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, Theme.Space.small)
                    .frame(minHeight: Theme.Size.touch)
                    .background(Theme.surface)
                    .overlay(
                        Rectangle()
                            .stroke(Theme.hairline, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(settings.localized("Show completed"))
        }
        .padding(.vertical, Theme.Space.small)
        .listRowInsets(EdgeInsets(top: 0, leading: Theme.Space.page, bottom: 0, trailing: Theme.Space.page))
        .listRowBackground(Theme.background)
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
            SectionHeader(title: settings.localized("Intro section rules"))
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
