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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var coordinator: TodaySessionCoordinator
    @State private var showingPractice = false
    let onHome: () -> Void

    init(plan: TodayPlan, onHome: @escaping () -> Void) {
        _coordinator = State(initialValue: TodaySessionCoordinator(plan: plan))
        self.onHome = onHome
    }

    var body: some View {
        let policy = Theme.Motion.Policy(reduced: reduceMotion)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.regular) {
                    if coordinator.plan.finished {
                        endCard
                            .transition(policy.cardStep)
                    } else {
                        handoffCard
                    }
                }
                .animation(policy.animation(Theme.Motion.cardStep), value: coordinator.plan.finished)
                .animation(policy.animation(Theme.Motion.cardStep), value: coordinator.plan.index)
                .padding(Theme.Space.handoff)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .foregroundStyle(Theme.ink)
            .calmChassisBackground()
            .toolbar {
                PadToolbarItem(placement: .confirmationAction) {
                    Button(action: onHome) {
                        Text(settings.localized("Home"))
                            .font(Theme.control)
                            .frame(minHeight: Theme.Size.touch)
                    }
                    .buttonStyle(PadSecondaryButtonStyle())
                }
            }
        }
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
            withAnimation(Theme.Motion.Policy(reduced: reduceMotion).animation(Theme.Motion.cardStep)) {
                coordinator.leavePractice(progress: progress)
            }
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

    @ViewBuilder
    private var handoffCard: some View {
        let policy = Theme.Motion.Policy(reduced: reduceMotion)

        ZStack(alignment: .topLeading) {
            handoffCardContent
                .id(coordinator.plan.index)
                .transition(policy.cardStep)
        }
        .frame(minHeight: 220, alignment: .topLeading)
        .satinPlate()

        if coordinator.currentStep != nil {
            buttonRow
        }
    }

    @ViewBuilder
    private var handoffCardContent: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            if let index = coordinator.plan.lastPlayedIndex, coordinator.plan.steps.indices.contains(index) {
                let step = coordinator.plan.steps[index]
                playedStepTag(step, index: index)
                resultSentence(step)
                metaLine(step)
            }

            if let step = coordinator.currentStep {
                nextStepSection(step)
            }
        }
    }

    private func playedStepTag(_ step: TodayPlan.Step, index: Int) -> some View {
        let tagText: String
        switch step.kind {
        case .review:
            let position = coordinator.plan.steps.prefix(index + 1).filter { $0.kind == .review }.count
            tagText = settings.localized("REVIEW %lld OF %lld", position, coordinator.plan.reviewCount)
        case .newLesson:
            tagText = settings.localized("NEW LESSON")
        case .mix:
            tagText = settings.localized("MIX")
        }
        return Text(tagText)
            .font(Theme.stepTag)
            .tracking(0.72)
            .foregroundStyle(Theme.secondary)
    }

    private func resultSentence(_ step: TodayPlan.Step) -> some View {
        Text(outcomeText(step))
            .font(Theme.handoffTitle)
            .foregroundStyle(Theme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private func metaLine(_ step: TodayPlan.Step) -> some View {
        Text(metaText(step))
            .font(Theme.meta)
            .foregroundStyle(Theme.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func metaText(_ step: TodayPlan.Step) -> String {
        var parts: [String] = []
        let lesson = step.lessonIDs.first.flatMap { LessonStore.shared.lesson(for: $0) }
        let title: String = {
            if step.kind == .mix { return settings.localized("Mix") }
            if let lesson { return settings.localized(lesson.title) }
            return "—"
        }()
        parts.append(title)

        if let outcome = step.outcome, outcome.played, let score = outcome.bestScore {
            let percent = Int((score * 100).rounded())
            if step.kind == .review {
                if let bpm = lesson?.targetBpm, bpm > 0 {
                    parts.append(settings.localized("%lld %% from memory at %lld BPM", percent, bpm))
                } else {
                    parts.append(settings.localized("%lld %% from memory", percent))
                }
            } else {
                parts.append(settings.localized("%lld %%", percent))
            }
        }
        return parts.joined(separator: " · ")
    }

    @ViewBuilder
    private func nextStepSection(_ step: TodayPlan.Step) -> some View {
        Text(settings.localized("NEXT"))
            .font(Theme.stepTag)
            .tracking(0.72)
            .foregroundStyle(Theme.secondary)
            .padding(.top, coordinator.plan.lastPlayedIndex != nil ? Theme.Space.small : 0)

        Text(nextStepTitle(step))
            .font(Theme.handoffNext)
            .foregroundStyle(Theme.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func nextStepTitle(_ step: TodayPlan.Step) -> String {
        let title = step.kind == .mix ? settings.localized("Mix")
            : step.lessonIDs.first.flatMap { LessonStore.shared.lesson(for: $0) }.map { settings.localized($0.title) } ?? "—"
        if step.kind == .review {
            let position = coordinator.plan.steps.prefix(coordinator.plan.index + 1).filter { $0.kind == .review }.count
            return settings.localized("%@ (review %lld of %lld)", title, position, coordinator.plan.reviewCount)
        }
        return title
    }

    private var buttonRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Theme.Space.small) {
                continueButton
                skipButton
                doneButton
            }
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                continueButton
                HStack(spacing: Theme.Space.small) {
                    skipButton
                    doneButton
                }
            }
        }
    }

    private var continueButton: some View {
        Button { openPractice() } label: {
            Text(settings.localized("Continue"))
                .font(Theme.action)
                .frame(minHeight: Theme.Size.touch)
        }
        .buttonStyle(PadPrimaryButtonStyle())
    }

    private var skipButton: some View {
        Button {
            withAnimation(Theme.Motion.Policy(reduced: reduceMotion).animation(Theme.Motion.cardStep)) {
                coordinator.skip(progress: progress)
            }
        } label: {
            Text(settings.localized("Skip"))
                .font(Theme.control)
                .frame(minHeight: Theme.Size.touch)
        }
        .buttonStyle(PadSecondaryButtonStyle())
    }

    private var doneButton: some View {
        Button {
            withAnimation(Theme.Motion.Policy(reduced: reduceMotion).animation(Theme.Motion.cardStep)) {
                coordinator.finish(progress: progress)
            }
        } label: {
            Text(settings.localized("Done for today"))
                .font(Theme.control)
                .frame(minHeight: Theme.Size.touch)
        }
        .buttonStyle(PadSecondaryButtonStyle())
    }

    @ViewBuilder
    private var endCard: some View {
        Text(settings.localized("That's enough for today"))
            .font(Theme.handoffTitle)
            .foregroundStyle(Theme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)

        let passed = coordinator.plan.steps.filter { step in
            guard step.kind == .review, let feedback = step.outcome?.reviewFeedback else { return false }
            switch feedback { case .passed, .settled: return true; default: return false }
        }.count

        if coordinator.plan.reviewCount > 0 {
            Text(settings.localized("Reviews passed: %lld of %lld", passed, coordinator.plan.reviewCount))
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
        }

        ForEach(Array(coordinator.plan.steps.enumerated()), id: \.offset) { _, step in
            if step.kind == .newLesson {
                Text(settings.localized("New lesson: %@", outcomeText(step)))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
            } else if step.kind == .mix {
                Text(settings.localized("Mix: %@", outcomeText(step)))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
            }
        }

        Button(action: onHome) {
            Text(settings.localized("Home"))
                .font(Theme.action)
                .frame(minHeight: Theme.Size.touch)
        }
        .buttonStyle(PadPrimaryButtonStyle())
        .padding(.top, Theme.Space.small)
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

    private func outcomeText(_ step: TodayPlan.Step) -> String {
        guard let outcome = step.outcome, outcome.played else { return settings.localized("Not played") }
        if step.kind == .review {
            if let feedback = outcome.reviewFeedback { return feedback.message(language: settings.languagePreference) }
            return settings.localized("Does not count · finish a hidden pass")
        }
        return settings.localized("Best score: %lld %%", Int(((outcome.bestScore ?? 0) * 100).rounded()))
    }
}
