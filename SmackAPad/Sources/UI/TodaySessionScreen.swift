import SwiftUI
import Observation

/// Owns the daily flow independently of Home so Training can launch the same session.
@MainActor
@Observable
final class TodaySessionCoordinator {
    private(set) var plan: TodayPlan
    private let defaults: UserDefaults

    init(plan: TodayPlan, defaults: UserDefaults = .standard) {
        self.plan = plan
        self.defaults = defaults
    }

    var currentStep: TodayPlan.Step? {
        plan.steps.indices.contains(plan.index) ? plan.steps[plan.index] : nil
    }

    func record(_ outcome: PracticeStepOutcome) {
        guard plan.day == AppCalendar.today(), !plan.finished, plan.phase == .practice,
              plan.steps.indices.contains(plan.index) else { return }
        var result = plan.steps[plan.index].outcome ?? PracticeStepOutcome()
        result.include(outcome)
        plan.steps[plan.index].outcome = result
        save()
    }

    func leavePractice(progress: ProgressStore) {
        guard !plan.finished, plan.phase == .practice, let step = currentStep else { return }
        postponeIfUnplayed(step, progress: progress)
        plan.lastPlayedIndex = plan.index
        advance()
    }

    func continueSession() {
        guard !plan.finished else { return }
        plan.phase = .practice
        save()
    }

    func skip(progress: ProgressStore) {
        guard !plan.finished, let step = currentStep else { return }
        postponeIfUnplayed(step, progress: progress)
        advance()
    }

    func finish(progress: ProgressStore) {
        guard !plan.finished else { return }
        for step in plan.steps.dropFirst(plan.index) { postponeIfUnplayed(step, progress: progress) }
        plan.index = plan.steps.count
        plan.finished = true
        plan.phase = .summary
        save()
    }

    private func postponeIfUnplayed(_ step: TodayPlan.Step, progress: ProgressStore) {
        guard plan.day == AppCalendar.today(), step.kind == .review, step.outcome?.played != true,
              let id = step.lessonIDs.first else { return }
        progress.postponeReview(for: id, today: plan.day)
    }

    private func advance() {
        plan.index += 1
        plan.finished = plan.index >= plan.steps.count
        plan.phase = plan.finished ? .summary : .handoff
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(plan), let json = String(data: data, encoding: .utf8) else { return }
        defaults.set(json, forKey: TodayPlan.storageKey)
    }
}

@MainActor
struct TodaySessionScreen: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(MIDIInput.self) private var midi
    @Environment(StoreManager.self) private var store
    @Environment(ProgressionManager.self) private var progression
    @Environment(\.scenePhase) private var scenePhase
    @State private var coordinator: TodaySessionCoordinator
    @State private var showingPractice = false
    let onHome: () -> Void

    init(plan: TodayPlan, onHome: @escaping () -> Void) {
        _coordinator = State(initialValue: TodaySessionCoordinator(plan: plan))
        self.onHome = onHome
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.page) {
                Text(settings.localized(coordinator.plan.finished ? "That's enough for today" : "Today"))
                    .font(Theme.screenTitle)
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: Theme.Space.page) {
                    if coordinator.plan.finished {
                        summary
                        Button(settings.localized("Home"), action: onHome)
                            .buttonStyle(InstrumentButtonStyle(filled: true, main: true))
                    } else {
                        if let index = coordinator.plan.lastPlayedIndex {
                            outcomeCard(coordinator.plan.steps[index])
                        }
                        if let step = coordinator.currentStep {
                            Text(nextText(step))
                                .font(Theme.rowTitle)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        VStack(alignment: .leading, spacing: Theme.Space.small) {
                            Button(settings.localized("Continue")) { openPractice() }
                                .buttonStyle(InstrumentButtonStyle(filled: true, main: true))
                            Button(settings.localized("Skip")) { coordinator.skip(progress: progress) }
                                .buttonStyle(InstrumentButtonStyle())
                            Button(settings.localized("Done for today")) { coordinator.finish(progress: progress) }
                                .buttonStyle(InstrumentButtonStyle())
                        }
                    }
                }
                .padding(Theme.Space.page)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface)
                .overlay(Rectangle().stroke(Theme.hairline, lineWidth: 1))
            }
            .padding(Theme.Space.page)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Theme.ink)
        .background(Theme.background.ignoresSafeArea())
        .task {
            if coordinator.plan.day != AppCalendar.today() { onHome() }
            else if coordinator.plan.phase == .practice { openPractice() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, coordinator.plan.day != AppCalendar.today() {
                showingPractice = false
                onHome()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            if coordinator.plan.day != AppCalendar.today() {
                showingPractice = false
                onHome()
            }
        }
        .fullScreenCover(isPresented: $showingPractice, onDismiss: {
            coordinator.leavePractice(progress: progress)
        }) {
            if let step = coordinator.currentStep,
               let lesson = step.lessonIDs.first.flatMap({ LessonStore.shared.lesson(for: $0) }) {
                PracticeScreen(lesson: lesson, settings: settings, progress: progress, midi: midi,
                               initialFromMemory: step.kind == .review,
                               initialBpm: step.kind == .review ? lesson.targetBpm : nil,
                               mixLessons: step.kind == .mix ? step.lessonIDs.compactMap { LessonStore.shared.lesson(for: $0) } : [],
                               onStepResult: { coordinator.record($0) })
            }
        }
    }

    private func openPractice() {
        guard let step = coordinator.currentStep else { return }
        let lessons = step.lessonIDs.compactMap { LessonStore.shared.lesson(for: $0) }
        // Access and controller compatibility may change after the plan has been saved.
        guard lessons.count == step.lessonIDs.count,
              lessons.allSatisfy({ store.isUnlocked($0) && progression.isLessonOpen($0)
                  && (midi.activeProfile.padCount == 16 || EightPadLayout.slots(for: $0) != nil) }) else {
            coordinator.skip(progress: progress)
            return
        }
        coordinator.continueSession()
        showingPractice = true
    }

    private func nextText(_ step: TodayPlan.Step) -> String {
        let title = step.kind == .mix ? settings.localized("Mix")
            : step.lessonIDs.first.flatMap { LessonStore.shared.lesson(for: $0) }.map { settings.localized($0.title) } ?? "—"
        if step.kind == .review {
            let position = coordinator.plan.steps.prefix(coordinator.plan.index + 1).filter { $0.kind == .review }.count
            return settings.localized("Next: %@ (review %lld of %lld)", title, position, coordinator.plan.reviewCount)
        }
        return settings.localized("Next: %@", title)
    }

    private func outcomeCard(_ step: TodayPlan.Step) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            Text(step.lessonIDs.first.flatMap { LessonStore.shared.lesson(for: $0) }
                .map { step.kind == .mix ? settings.localized("Mix") : settings.localized($0.title) } ?? "—")
                .font(Theme.rowTitle)
            Text(outcomeText(step)).font(Theme.control)
        }
        .accessibilityElement(children: .combine)
    }

    private func outcomeText(_ step: TodayPlan.Step) -> String {
        guard let outcome = step.outcome, outcome.played else { return settings.localized("Not played") }
        if step.kind == .review {
            if let feedback = outcome.reviewFeedback { return feedback.message(language: settings.languagePreference) }
            return settings.localized("Does not count · finish a hidden pass")
        }
        return settings.localized("Best score: %lld %%", Int(((outcome.bestScore ?? 0) * 100).rounded()))
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            let passed = coordinator.plan.steps.filter { step in
                guard step.kind == .review, let feedback = step.outcome?.reviewFeedback else { return false }
                switch feedback { case .passed, .settled: return true; default: return false }
            }.count
            Text(settings.localized("Reviews passed: %lld of %lld", passed, coordinator.plan.reviewCount))
                .font(Theme.rowTitle)
            ForEach(Array(coordinator.plan.steps.enumerated()), id: \.offset) { _, step in
                if step.kind == .newLesson {
                    Text(settings.localized("New lesson: %@", outcomeText(step))).font(Theme.control)
                }
            }
            if let index = coordinator.plan.lastPlayedIndex {
                outcomeCard(coordinator.plan.steps[index])
            }
        }
    }
}
