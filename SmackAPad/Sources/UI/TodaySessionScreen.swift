import SwiftUI
import Observation

/// Owns the daily flow independently of Home so Training can launch the same session.
@MainActor
@Observable
final class TodaySessionCoordinator {
    private(set) var plan: TodayPlan
    private let defaults: UserDefaults

    init(plan: TodayPlan, defaults: UserDefaults = .standard) {
        var normalized = plan
        if normalized.finished || normalized.steps.isEmpty || normalized.index >= normalized.steps.count {
            normalized.index = normalized.steps.count
            normalized.finished = true
            normalized.phase = .summary
        }
        self.plan = normalized
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
        if plan.isFinished {
            plan.finished = true
            plan.phase = .summary
        }
        save()
    }

    func reconcileReviews(progress: ProgressStore) {
        let previous = plan
        plan = plan.reconcilingReviews(with: progress.records)
        if !plan.finished {
            movePastDecidedReviews()
            if plan.isFinished {
                plan.finished = true
                plan.phase = .summary
            } else if plan.index != previous.index {
                updatePhaseAfterAdvance()
            }
        }
        if plan != previous { save() }
    }

    func leavePractice(progress: ProgressStore) {
        guard !plan.finished, plan.phase == .practice else { return }
        plan = plan.reconcilingReviews(with: progress.records)
        guard let step = currentStep else { return }
        postponeIfUnplayed(step, progress: progress)
        plan.lastPlayedIndex = plan.index
        advance()
    }

    func continueSession() {
        guard !plan.finished else { return }
        plan.phase = .practice
        save()
    }

    func replaceCurrentMixLessons(_ lessons: [Lesson]) {
        guard !plan.finished, plan.steps.indices.contains(plan.index),
              plan.steps[plan.index].kind == .mix,
              lessons.count >= LearningRules.minimumMixLessons else { return }
        plan.steps[plan.index].lessonIDs = lessons.map(\.id)
        save()
    }

    func skip(progress: ProgressStore) {
        guard !plan.finished else { return }
        plan = plan.reconcilingReviews(with: progress.records)
        guard let step = currentStep else { return }
        postponeIfUnplayed(step, progress: progress)
        advance()
    }

    func finish(progress: ProgressStore) {
        guard !plan.finished else { return }
        plan = plan.reconcilingReviews(with: progress.records)
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
        movePastDecidedReviews()
        updatePhaseAfterAdvance()
        save()
    }

    private func movePastDecidedReviews() {
        while let step = currentStep, step.kind == .review, step.outcome?.hasDecidedReview == true {
            plan.index += 1
        }
    }

    private func updatePhaseAfterAdvance() {
        plan.finished = plan.index >= plan.steps.count
        plan.phase = plan.finished ? .summary : .handoff
    }

    private func save() {
        guard let json = plan.encoded else { return }
        defaults.set(json, forKey: TodayPlan.storageKey)
    }
}

private enum TodayPracticePresentation: Identifiable {
    case mix(id: UUID, lessons: [Lesson])
    case lesson(id: UUID, lesson: Lesson, isReview: Bool)

    var id: UUID {
        switch self {
        case .mix(let id, _), .lesson(let id, _, _):
            return id
        }
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
    @State private var practicePresentation: TodayPracticePresentation?
    @State private var todayMixFromMemory = false
    @State private var mixFlowEnteredPractice = false
    @State private var extraMixPresentation: MixCoverItem?
    @State private var extraMixFromMemory = false
    @AppStorage("smackapad.training.dailyMixes") private var dailyMixes = "{}"
    let onHome: () -> Void

    private var hasActiveCover: Bool {
        practicePresentation != nil || extraMixPresentation != nil
    }

    init(plan: TodayPlan, onHome: @escaping () -> Void) {
        #if DEBUG
        _coordinator = State(initialValue: TodaySessionCoordinator(plan: plan, defaults: DebugProfileStorage.defaults))
        #else
        _coordinator = State(initialValue: TodaySessionCoordinator(plan: plan))
        #endif
        self.onHome = onHome
    }

    var body: some View {
        let policy = Theme.Motion.Policy(reduced: reduceMotion)

        NavigationStack {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width >= 768 && geometry.size.width > geometry.size.height

                if coordinator.plan.finished || coordinator.currentStep == nil {
                    DaySummaryView(
                        plan: coordinator.plan,
                        isLandscape: isLandscape,
                        canStartExtraMix: extraMixCandidates().count >= LearningRules.minimumMixLessons,
                        onBack: onHome,
                        onExtraMix: { startExtraMix() },
                        onEndTraining: onHome
                    )
                    .transition(policy.cardStep)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            HStack {
                                BackButton(action: onHome)
                                Spacer()
                            }
                            .frame(height: 56)

                            Spacer(minLength: Theme.Space.small)

                            VStack(spacing: 24) {
                                Text(settings.localized("Reviews") + " · " + settings.localized("%lld today", coordinator.plan.reviewCount))
                                    .font(Theme.meta)
                                    .foregroundStyle(Theme.secondary)
                                TodayStepperView(plan: coordinator.plan, isLandscape: isLandscape)

                                masterConsole(isLandscape: isLandscape)
                                    .id(coordinator.plan.index)
                                    .transition(policy.cardStep)
                            }
                            .frame(maxWidth: .infinity)

                            Spacer(minLength: Theme.Space.page)
                        }
                        .frame(maxWidth: .infinity, minHeight: max(0, geometry.size.height - Theme.Space.page * 2))
                        .padding(.horizontal, Theme.Space.page)
                        .padding(.vertical, Theme.Space.page)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
            .animation(policy.animation(Theme.Motion.cardStep), value: coordinator.plan.finished)
            .animation(policy.animation(Theme.Motion.cardStep), value: coordinator.plan.index)
            .foregroundStyle(Theme.ink)
            .calmChassisBackground()
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
        #if DEBUG
        .debugTestMarker()
        #endif
        .task {
            if coordinator.plan.day != AppCalendar.today() {
                onHome()
                return
            }
            coordinator.reconcileReviews(progress: progress)
            if coordinator.plan.phase == .practice && coordinator.plan.lastPlayedIndex != nil {
                openPractice()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, coordinator.plan.day != AppCalendar.today() {
                practicePresentation = nil
                extraMixPresentation = nil
                onHome()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            if coordinator.plan.day != AppCalendar.today() {
                practicePresentation = nil
                extraMixPresentation = nil
                onHome()
            }
        }
        .fullScreenCover(item: $practicePresentation, onDismiss: {
            if coordinator.currentStep?.kind == .mix && !mixFlowEnteredPractice {
                return
            }
            withAnimation(Theme.Motion.Policy(reduced: reduceMotion).animation(Theme.Motion.cardStep)) {
                coordinator.leavePractice(progress: progress)
            }
        }) { item in
            switch item {
            case .mix(_, let lessons):
                if lessons.isEmpty {
                    EmptyCoverFallbackView(context: "TodaySessionScreen.todayMix") {
                        practicePresentation = nil
                    }
                } else {
                    MixFlowScreen(
                        lessons: todayMixLessonsBinding(fallback: lessons),
                        fromMemory: $todayMixFromMemory,
                        onAnotherMix: { rerollTodayMix() },
                        onMixStarted: {
                            mixFlowEnteredPractice = true
                            coordinator.continueSession()
                        },
                        onStepResult: { coordinator.record($0) }
                    )
                }
            case .lesson(_, let lesson, let isReview):
                let launch: LessonLaunch = isReview ? .review(lesson) : .lesson(lesson)
                PracticeScreen(lesson: lesson, settings: settings, progress: progress, midi: midi,
                               initialFromMemory: launch.reviewTempo != nil,
                               initialBpm: launch.reviewTempo,
                               onStepResult: { coordinator.record($0) })
            }
        }
        .fullScreenCover(item: $extraMixPresentation) { item in
            if item.lessons.isEmpty {
                EmptyCoverFallbackView(context: "TodaySessionScreen.extraMix") {
                    extraMixPresentation = nil
                }
            } else {
                MixFlowScreen(
                    lessons: extraMixLessonsBinding(fallback: item.lessons),
                    fromMemory: $extraMixFromMemory,
                    onAnotherMix: { rerollExtraMix() },
                    onMixStarted: {},
                    onStepResult: { _ in }
                )
            }
        }
    }

    @ViewBuilder
    private func masterConsole(isLandscape: Bool) -> some View {
        if let lastIndex = coordinator.plan.lastPlayedIndex, coordinator.plan.steps.indices.contains(lastIndex) {
            let previousStep = coordinator.plan.steps[lastIndex]
            if let nextStep = coordinator.currentStep {
                if isLandscape {
                    HStack(alignment: .top, spacing: 0) {
                        PreviousRunEvaluationView(step: previousStep)
                            .padding(34)
                            .frame(maxWidth: .infinity, alignment: .topLeading)

                        Rectangle()
                            .fill(Theme.hairline)
                            .frame(width: 1)

                        NextStepPreparationView(step: nextStep, isDayStart: false, plan: coordinator.plan,
                                                onContinue: { openPractice() },
                                                onSkip: { skipStep() },
                                                onDone: { finishSession() })
                            .padding(34)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .background(Theme.ink.opacity(0.02))
                    }
                    .frame(maxWidth: 960)
                    .satinPlate()
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        PreviousRunEvaluationView(step: previousStep)
                            .padding(26)
                            .frame(maxWidth: .infinity, alignment: .topLeading)

                        Rectangle()
                            .fill(Theme.hairline)
                            .frame(height: 1)

                        NextStepPreparationView(step: nextStep, isDayStart: false, plan: coordinator.plan,
                                                onContinue: { openPractice() },
                                                onSkip: { skipStep() },
                                                onDone: { finishSession() })
                            .padding(26)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .background(Theme.ink.opacity(0.02))
                    }
                    .frame(maxWidth: 680)
                    .satinPlate()
                }
            } else {
                EmptyView()
            }
        } else if let step = coordinator.currentStep {
            NextStepPreparationView(step: step, isDayStart: true, plan: coordinator.plan,
                                    onContinue: { openPractice() },
                                    onSkip: { skipStep() },
                                    onDone: { finishSession() })
                .padding(isLandscape ? 34 : 26)
                .frame(maxWidth: 620)
                .satinPlate()
        }
    }

    private func openPractice() {
        guard !hasActiveCover else { return }
        guard let step = coordinator.currentStep else { return }
        let lessons = step.lessonIDs.compactMap { LessonStore.shared.lesson(for: $0) }
        guard lessons.count == step.lessonIDs.count,
              lessons.allSatisfy({ store.isUnlocked($0) && progression.isLessonOpen($0)
                  && (midi.activeProfile.padCount == 16 || EightPadLayout.slots(for: $0) != nil) }) else {
            coordinator.skip(progress: progress)
            return
        }
        if step.kind == .mix {
            guard !lessons.isEmpty else { return }
            mixFlowEnteredPractice = false
            practicePresentation = .mix(id: UUID(), lessons: lessons)
            return
        }
        guard let lesson = lessons.first else {
            coordinator.skip(progress: progress)
            return
        }
        coordinator.continueSession()
        practicePresentation = .lesson(id: UUID(), lesson: lesson, isReview: step.kind == .review)
    }

    private var openMixLessonIDs: Set<Int> {
        Set(progression.catalog.lessons.filter {
            store.isUnlocked($0) && progression.isLessonOpen($0)
        }.map(\.id))
    }

    private func extraMixCandidates() -> [Lesson] {
        TrainingMix.candidates(
            lessons: progression.catalog.lessons,
            progress: progress.records,
            padCount: midi.activeProfile.padCount,
            openLessonIDs: openMixLessonIDs
        )
    }

    private func startExtraMix() {
        guard !hasActiveCover else { return }
        let excludedIDs = coordinator.plan.steps.first(where: { $0.kind == .mix })?.lessonIDs ?? []
        let chosen = pickExtraMix(excluding: excludedIDs)
        guard chosen.count >= LearningRules.minimumMixLessons else { return }
        extraMixPresentation = MixCoverItem(lessons: chosen)
    }

    private func rerollExtraMix() {
        guard var current = extraMixPresentation else { return }
        let chosen = pickExtraMix(excluding: current.lessons.map(\.id))
        if chosen.count >= LearningRules.minimumMixLessons {
            current.lessons = chosen
            extraMixPresentation = current
        }
    }

    private func pickExtraMix(excluding excludedIDs: [Int]) -> [Lesson] {
        let rerolled = TrainingMix.reroll(
            excluding: excludedIDs,
            lessons: progression.catalog.lessons,
            progress: progress.records,
            padCount: midi.activeProfile.padCount,
            openLessonIDs: openMixLessonIDs,
            day: coordinator.plan.day
        )
        if rerolled.count >= LearningRules.minimumMixLessons {
            return rerolled
        }
        return TrainingMix.select(
            lessons: progression.catalog.lessons,
            progress: progress.records,
            padCount: midi.activeProfile.padCount,
            openLessonIDs: openMixLessonIDs,
            day: coordinator.plan.day
        )
    }

    private func rerollTodayMix() {
        guard case .mix(let id, let currentLessons) = practicePresentation else { return }
        let chosen = TrainingMix.reroll(
            excluding: currentLessons.map(\.id),
            lessons: progression.catalog.lessons,
            progress: progress.records,
            padCount: midi.activeProfile.padCount,
            openLessonIDs: openMixLessonIDs,
            day: coordinator.plan.day
        )
        guard chosen.count >= LearningRules.minimumMixLessons else { return }
        practicePresentation = .mix(id: id, lessons: chosen)
        coordinator.replaceCurrentMixLessons(chosen)
        var saved = (try? JSONDecoder().decode([String: [Int]].self, from: Data(dailyMixes.utf8))) ?? [:]
        saved["\(coordinator.plan.day):\(midi.activeProfile.padCount)"] = chosen.map(\.id)
        if let data = try? JSONEncoder().encode(saved),
           let json = String(data: data, encoding: .utf8) {
            dailyMixes = json
        }
    }

    private func todayMixLessonsBinding(fallback: [Lesson]) -> Binding<[Lesson]> {
        Binding(
            get: {
                if case .mix(_, let lessons) = practicePresentation { return lessons }
                return fallback
            },
            set: { updated in
                if case .mix(let id, _) = practicePresentation {
                    practicePresentation = .mix(id: id, lessons: updated)
                }
            }
        )
    }

    private func extraMixLessonsBinding(fallback: [Lesson]) -> Binding<[Lesson]> {
        Binding(
            get: { extraMixPresentation?.lessons ?? fallback },
            set: { updated in
                guard var current = extraMixPresentation else { return }
                current.lessons = updated
                extraMixPresentation = current
            }
        )
    }

    private func skipStep() {
        withAnimation(Theme.Motion.Policy(reduced: reduceMotion).animation(Theme.Motion.cardStep)) {
            coordinator.skip(progress: progress)
        }
    }

    private func finishSession() {
        withAnimation(Theme.Motion.Policy(reduced: reduceMotion).animation(Theme.Motion.cardStep)) {
            coordinator.finish(progress: progress)
        }
    }
}

// MARK: - Stepper View

private struct TodayStepperView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.colorScheme) private var colorScheme
    let plan: TodayPlan
    let isLandscape: Bool

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(plan.steps.enumerated()), id: \.offset) { index, step in
                stepCard(step: step, index: index)
            }
        }
        .frame(maxWidth: isLandscape ? 960 : 680)
    }

    private func stepCard(step: TodayPlan.Step, index: Int) -> some View {
        let isCompleted = plan.finished || index < plan.index
            || (step.kind == .review && step.outcome?.hasDecidedReview == true)
        let isCurrent = !isCompleted && index == plan.index
        let isUpcoming = !isCompleted && index > plan.index
        let isPassed = step.status == .passed

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(stepTag(step: step))
                    .font(Theme.strong(11))
                    .lineLimit(1)
                Spacer(minLength: 4)
                if isCompleted, let symbol = step.markerSymbol {
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 14, height: 14)
                        .accessibilityHidden(true)
                }
                Text(stepStatus(step: step, isCompleted: isCompleted, isCurrent: isCurrent, isUpcoming: isUpcoming))
                    .font(Theme.strong(11))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(headerColor(isCompleted: isPassed, isCurrent: isCurrent, isUpcoming: isUpcoming))

            Text(stepName(step: step))
                .font(Theme.strong(14))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)

            if isCompleted, let reason = step.status?.reason {
                Text(reason.message(language: settings.languagePreference))
                    .font(Theme.text(12))
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if isCompleted, let score = step.outcome?.bestScore {
                Text("\(Int((score * 100).rounded())) %")
                    .font(Theme.text(12))
                    .foregroundStyle(Theme.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor(isCompleted: isPassed, isCurrent: isCurrent))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(borderColor(isCompleted: isPassed, isCurrent: isCurrent), lineWidth: isCurrent ? 1.5 : 1)
                }
                .shadow(color: isCurrent ? Theme.orange.opacity(0.18) : .clear, radius: 4, y: 1)
        }
        .opacity(isUpcoming ? 0.65 : 1.0)
    }

    private func stepTag(step: TodayPlan.Step) -> String {
        switch step.kind {
        case .review: return settings.localized("Review")
        case .newLesson: return settings.localized("New lesson")
        case .mix: return settings.localized("Daily mix")
        }
    }

    private func stepStatus(step: TodayPlan.Step, isCompleted: Bool, isCurrent: Bool, isUpcoming: Bool) -> String {
        if isCompleted {
            guard let status = step.status else { return settings.localized("Not played") }
            return (status == .passed ? "✓ " : "") + settings.localized(status.titleKey)
        }
        if isCurrent {
            if plan.lastPlayedIndex == nil {
                return settings.localized("Start of plan")
            }
            return settings.localized("Next")
        }
        return settings.localized("Waiting")
    }

    private func stepName(step: TodayPlan.Step) -> String {
        if step.kind == .mix {
            return settings.localized("Daily mix")
        }
        if let lesson = step.lessonIDs.first.flatMap({ LessonStore.shared.lesson(for: $0) }) {
            return settings.localized(lesson.title)
        }
        return "—"
    }

    private func headerColor(isCompleted: Bool, isCurrent: Bool, isUpcoming: Bool) -> Color {
        if isCompleted {
            return colorScheme == .dark
                ? Color(red: 0.51, green: 0.78, blue: 0.52)
                : Color(red: 0.18, green: 0.49, blue: 0.20)
        }
        if isCurrent {
            return Theme.orange
        }
        return Theme.secondary
    }

    private func backgroundColor(isCompleted: Bool, isCurrent: Bool) -> Color {
        if isCompleted {
            return colorScheme == .dark
                ? Color(red: 0.30, green: 0.69, blue: 0.31).opacity(0.12)
                : Color(red: 0.18, green: 0.49, blue: 0.20).opacity(0.06)
        }
        return Theme.surface
    }

    private func borderColor(isCompleted: Bool, isCurrent: Bool) -> Color {
        if isCompleted {
            return colorScheme == .dark
                ? Color(red: 0.30, green: 0.69, blue: 0.31).opacity(0.40)
                : Color(red: 0.18, green: 0.49, blue: 0.20).opacity(0.35)
        }
        if isCurrent {
            return Theme.orange
        }
        return Theme.hairline
    }
}

// MARK: - Stars Meter View

private struct StarsMeterView: View {
    let earnedStars: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(index < earnedStars ? Theme.orange : Theme.ledOff)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(earnedStars) of 3 stars")
    }
}

// MARK: - Verdict Box View

private struct VerdictBoxView: View {
    @Environment(\.colorScheme) private var colorScheme
    let isSuccess: Bool
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isSuccess ? "checkmark.circle" : "exclamationmark.circle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(inkColor)
                .frame(width: 18, height: 18)
                .padding(.top, 1.5)

            Text(text)
                .font(Theme.text(15))
                .lineSpacing(2)
                .foregroundStyle(inkColor)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 11)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(bgColor)
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .strokeBorder(borderColor, lineWidth: 1)
                }
        }
    }

    private var inkColor: Color {
        if isSuccess {
            return colorScheme == .dark
                ? Color(red: 0.51, green: 0.78, blue: 0.52)
                : Color(red: 0.11, green: 0.37, blue: 0.13)
        } else {
            return colorScheme == .dark
                ? Color(red: 1.0, green: 0.56, blue: 0.24)
                : Color(red: 0.65, green: 0.27, blue: 0.0)
        }
    }

    private var bgColor: Color {
        if isSuccess {
            return colorScheme == .dark
                ? Color(red: 0.30, green: 0.69, blue: 0.31).opacity(0.15)
                : Color(red: 0.18, green: 0.49, blue: 0.20).opacity(0.10)
        } else {
            return Theme.orange.opacity(colorScheme == .dark ? 0.15 : 0.10)
        }
    }

    private var borderColor: Color {
        if isSuccess {
            return colorScheme == .dark
                ? Color(red: 0.30, green: 0.69, blue: 0.31).opacity(0.42)
                : Color(red: 0.18, green: 0.49, blue: 0.20).opacity(0.32)
        } else {
            return Theme.orange.opacity(colorScheme == .dark ? 0.42 : 0.32)
        }
    }
}

// MARK: - Pattern Preview Card

private struct PatternPreviewCard: View {
    @Environment(SettingsManager.self) private var settings
    let hits: [LessonHit]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(settings.localized("Rhythm pattern preview"))
                .font(Theme.strong(12))
                .foregroundStyle(Theme.secondary)

            LessonPatternStrip(hits: hits)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.hairline, lineWidth: 1))
        }
    }
}

// MARK: - Previous Run Evaluation View (Left Column)

private struct PreviousRunEvaluationView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    let step: TodayPlan.Step

    private var isSuccess: Bool {
        step.status == .passed
    }

    private var earnedStars: Int {
        guard let id = step.lessonIDs.first, let record = progress.progress(for: id) else { return 0 }
        return [record.passed, record.mastery, record.memory].filter { $0 }.count
    }

    private var scoreText: String {
        guard let outcome = step.outcome, outcome.played, let score = outcome.bestScore else {
            return "—"
        }
        return "\(Int((score * 100).rounded())) %"
    }

    private var lessonTitle: String {
        if step.kind == .mix {
            return settings.localized("Mix")
        }
        if let lesson = step.lessonIDs.first.flatMap({ LessonStore.shared.lesson(for: $0) }) {
            return settings.localized(lesson.title)
        }
        return "—"
    }

    private var metaLine: String {
        if step.kind == .mix {
            return settings.localized("Daily mix · %lld lessons", step.lessonIDs.count)
        }
        guard let lesson = step.lessonIDs.first.flatMap({ LessonStore.shared.lesson(for: $0) }) else {
            return ""
        }
        if step.kind == .review {
            if lesson.bars > 1 {
                return settings.localized("%lld bars · from memory at %lld BPM", lesson.bars, lesson.targetBpm)
            } else {
                return settings.localized("1 bar · from memory at %lld BPM", lesson.targetBpm)
            }
        } else {
            if lesson.bars > 1 {
                return settings.localized("%lld bars · %lld BPM", lesson.bars, lesson.targetBpm)
            } else {
                return settings.localized("1 bar · %lld BPM", lesson.targetBpm)
            }
        }
    }

    private var verdictText: String {
        guard let outcome = step.outcome, outcome.played else {
            return settings.localized("Not played")
        }
        if step.kind == .review {
            if let reason = step.status?.reason {
                return settings.localized("Did not count") + " · " + reason.message(language: settings.languagePreference)
            }
            if let feedback = outcome.reviewFeedback {
                return feedback.message(language: settings.languagePreference)
            }
            return settings.localized("Played")
        } else if step.kind == .newLesson {
            return isSuccess
                ? settings.localized("New lesson passed successfully!")
                : settings.localized("Aim for 80% to pass the new lesson.")
        } else {
            return isSuccess
                ? settings.localized("Daily mix completed successfully!")
                : settings.localized("Mix completed · keep practicing to improve your groove.")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(scoreText)
                    .font(Theme.boldDisplay(64))
                    .foregroundStyle(Theme.ink)

                StarsMeterView(earnedStars: earnedStars)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(lessonTitle)
                    .font(Theme.boldDisplay(24))
                    .foregroundStyle(Theme.ink)

                if !metaLine.isEmpty {
                    Text(metaLine)
                        .font(Theme.text(14))
                        .foregroundStyle(Theme.secondary)
                }
            }

            VerdictBoxView(isSuccess: isSuccess, text: verdictText)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - Next Step Preparation View (Right Column)

private struct NextStepPreparationView: View {
    @Environment(SettingsManager.self) private var settings
    let step: TodayPlan.Step
    let isDayStart: Bool
    let plan: TodayPlan
    let onContinue: () -> Void
    let onSkip: () -> Void
    let onDone: () -> Void

    private var lesson: Lesson? {
        step.lessonIDs.first.flatMap { LessonStore.shared.lesson(for: $0) }
    }

    private var title: String {
        if step.kind == .mix {
            return settings.localized("Daily mix")
        }
        if let lesson {
            return settings.localized(lesson.title)
        }
        return "—"
    }

    private var meta: String {
        if step.kind == .review {
            let position = plan.steps.prefix(plan.index + 1).filter { $0.kind == .review }.count
            let bpm = lesson?.targetBpm ?? 0
            return settings.localized("Review %lld of %lld · %lld BPM from memory", position, plan.reviewCount, bpm)
        } else if step.kind == .newLesson {
            let bpm = lesson?.targetBpm ?? 0
            let bars = lesson?.bars ?? 4
            if bars > 1 {
                return settings.localized("New lesson · %lld BPM · %lld bars", bpm, bars)
            } else {
                return settings.localized("New lesson · %lld BPM · 1 bar", bpm)
            }
        } else {
            return settings.localized("Daily mix · %lld lessons", step.lessonIDs.count)
        }
    }

    private var hits: [LessonHit] {
        lesson?.hits ?? []
    }

    private var primaryButtonTitle: String {
        isDayStart
            ? settings.localized("Start training")
            : settings.localized("Continue to %@", title)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.boldDisplay(34))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                Text(meta)
                    .font(Theme.text(14))
                    .foregroundStyle(Theme.secondary)
            }

            if !hits.isEmpty {
                PatternPreviewCard(hits: hits)
            }

            VStack(spacing: Theme.Space.controlGap) {
                Button(action: onContinue) {
                    Text(primaryButtonTitle)
                        .font(Theme.strong(18))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                }
                .buttonStyle(PadPrimaryButtonStyle())

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Space.controlGap) {
                        skipButton
                        doneButton
                    }
                    VStack(spacing: Theme.Space.controlGap) {
                        skipButton
                        doneButton
                    }
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var skipButton: some View {
        Button(action: onSkip) {
            Text(settings.localized("Skip"))
                .font(Theme.control)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
        }
        .buttonStyle(PadSecondaryButtonStyle())
    }

    private var doneButton: some View {
        Button(action: onDone) {
            Text(settings.localized("Done for today"))
                .font(Theme.control)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
        }
        .buttonStyle(PadSecondaryButtonStyle())
    }
}

// MARK: - Shared Formatting & Button Styles

enum DayDateFormatter {
    static func format(_ day: String, language: AppLanguage) -> String {
        let parts = day.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return day }
        var comp = DateComponents()
        comp.year = parts[0]
        comp.month = parts[1]
        comp.day = parts[2]
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        guard let date = cal.date(from: comp) else { return day }

        let locale = Locale(identifier: language.rawValue)
        let fmt = DateFormatter()
        fmt.locale = locale
        fmt.dateFormat = language == .czech ? "EEEE d. M." : "EEEE d MMM"
        let str = fmt.string(from: date)
        return str.prefix(1).uppercased(with: locale) + str.dropFirst()
    }
}

struct TrainingActionButtonStyle: ButtonStyle {
    enum Variant { case primary, secondary, dark }

    let variant: Variant
    var cornerRadius: CGFloat = 14
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduced

    func makeBody(configuration: Configuration) -> some View {
        let policy = Theme.Motion.Policy(reduced: reduced)
        let shape = RoundedRectangle(cornerRadius: cornerRadius)

        configuration.label
            .foregroundStyle(foreground)
            .background {
                shape
                    .fill(background)
                    .overlay {
                        if case .secondary = variant {
                            shape.strokeBorder(Theme.ink.opacity(0.22), lineWidth: 1.5)
                        }
                    }
            }
            .contentShape(shape)
            .opacity(isEnabled ? (configuration.isPressed ? 0.84 : 1) : 0.42)
            .animation(policy.animation(Theme.Motion.padFlash), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch variant {
        case .primary: return Theme.black
        case .secondary: return Theme.ink
        case .dark: return Theme.white
        }
    }

    private var background: Color {
        switch variant {
        case .primary: return Theme.orange
        case .secondary: return Theme.surface
        case .dark: return Theme.black
        }
    }
}

// MARK: - Day Summary View (End of Day)

private struct DaySummaryView: View {
    @Environment(SettingsManager.self) private var settings
    let plan: TodayPlan
    let isLandscape: Bool
    let canStartExtraMix: Bool
    let onBack: () -> Void
    let onExtraMix: () -> Void
    let onEndTraining: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                BackButton(action: onBack)
                Spacer()
            }
            .frame(height: 56)

            if isLandscape {
                let bottomEdgeInset: CGFloat = 36
                HStack(alignment: .top, spacing: 28) {
                    heroPanel(padding: bottomEdgeInset)
                        .frame(maxWidth: 520, maxHeight: .infinity)

                    VStack(alignment: .leading, spacing: 20) {
                        ScrollView {
                            timelineList
                                .padding(.top, 4)
                                .padding(.trailing, 4)
                        }
                        .scrollBounceBehavior(.basedOnSize)

                        bottomButtons(height: 72)
                            .padding(.bottom, bottomEdgeInset)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        heroPanel(padding: 26)
                        timelineList
                        bottomButtons(height: 64)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .padding(Theme.Space.page)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func heroPanel(padding: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.orange)
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Theme.black)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 10) {
                Text(settings.localized("daySummary.title"))
                    .font(Theme.padTitle(size: 64))
                    .foregroundStyle(Theme.white)
                    .lineSpacing(-2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text(DayDateFormatter.format(plan.day, language: settings.languagePreference))
                    .font(Theme.text(17))
                    .foregroundStyle(Theme.white.opacity(0.68))
            }

            if isLandscape {
                Spacer(minLength: 16)
            }

            HStack(spacing: 12) {
                heroStatTile(
                    label: settings.localized("Reviews"),
                    value: "\(plan.reviewSummary.passed) / \(plan.reviewCount)",
                    valueColor: Theme.white
                )
                heroStatTile(
                    label: settings.localized("New lesson"),
                    value: percentStatText(for: .newLesson, allowDoneFallback: false),
                    valueColor: Theme.orange
                )
                heroStatTile(
                    label: settings.localized("Mix"),
                    value: percentStatText(for: .mix, allowDoneFallback: true),
                    valueColor: Theme.white
                )
            }
        }
        .padding(padding)
        .frame(maxWidth: .infinity, maxHeight: isLandscape ? .infinity : nil, alignment: .topLeading)
        .background(Theme.black, in: RoundedRectangle(cornerRadius: 24))
    }

    private func heroStatTile(label: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Theme.text(13))
                .foregroundStyle(Theme.white.opacity(0.62))
                .lineLimit(1)
            Text(value)
                .font(Theme.boldDisplay(28).monospacedDigit())
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private var timelineList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(plan.steps.enumerated()), id: \.offset) { index, step in
                timelineRow(step: step, index: index, isLast: index == plan.steps.count - 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timelineRow(step: TodayPlan.Step, index: Int, isLast: Bool) -> some View {
        let status = step.status
        let isPassed = status == .passed
        let isPlayedOnly = status == .played
        let isDidNotCount: Bool = {
            if case .didNotCount = status { return true }
            return false
        }()

        return HStack(alignment: .top, spacing: 18) {
            VStack(spacing: 4) {
                stepCircle(isPassed: isPassed, isPlayedOnly: isPlayedOnly, isDidNotCount: isDidNotCount)
                if !isLast {
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(width: 2)
                        .frame(minHeight: 24, maxHeight: .infinity)
                }
            }
            .frame(width: 44)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(stepTag(for: step))
                        .font(Theme.strong(12))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)

                    Text(stepTitle(for: step))
                        .font(Theme.boldDisplay(22))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if isDidNotCount {
                        Text(settings.localized("again tomorrow"))
                            .font(Theme.strong(12))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 12)
                            .frame(height: 28)
                            .background(Theme.surface, in: Capsule())
                            .overlay {
                                Capsule().strokeBorder(Theme.hairline, lineWidth: 1)
                            }
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(stepScoreText(for: step))
                    .font(Theme.boldDisplay(24).monospacedDigit())
                    .foregroundStyle(isPassed ? Theme.ink : Theme.secondary)
                    .lineLimit(1)
            }
            .padding(.top, 2)
            .padding(.bottom, isLast ? 0 : 24)
        }
    }

    @ViewBuilder
    private func stepCircle(isPassed: Bool, isPlayedOnly: Bool, isDidNotCount: Bool) -> some View {
        if isPassed {
            Circle()
                .fill(Theme.orange)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.black)
                }
        } else if isDidNotCount {
            Circle()
                .strokeBorder(Theme.ink, lineWidth: 2)
                .frame(width: 44, height: 44)
                .overlay {
                    Text("!")
                        .font(Theme.boldDisplay(20))
                        .foregroundStyle(Theme.ink)
                }
        } else if isPlayedOnly {
            Circle()
                .strokeBorder(Theme.ink, lineWidth: 2)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                }
        } else {
            Circle()
                .strokeBorder(Theme.hairline, lineWidth: 2)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "minus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.secondary)
                }
        }
    }

    private func bottomButtons(height: CGFloat) -> some View {
        HStack(spacing: 12) {
            Button {
                onExtraMix()
            } label: {
                Text(settings.localized("Extra mix"))
                    .font(Theme.strong(17))
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
            }
            .buttonStyle(TrainingActionButtonStyle(variant: .secondary))
            .disabled(!canStartExtraMix)

            Button {
                onEndTraining()
            } label: {
                Text(settings.localized("End training"))
                    .font(Theme.strong(17))
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
            }
            .buttonStyle(TrainingActionButtonStyle(variant: .primary))
        }
    }

    private func percentStatText(for kind: TodayPlan.Step.Kind, allowDoneFallback: Bool) -> String {
        guard let step = plan.steps.first(where: { $0.kind == kind }),
              let outcome = step.outcome,
              outcome.played else {
            return "—"
        }
        if let score = outcome.bestScore {
            return "\(Int((score * 100).rounded())) %"
        }
        return allowDoneFallback ? settings.localized("Done") : "—"
    }

    private func stepTag(for step: TodayPlan.Step) -> String {
        switch step.kind {
        case .review: return settings.localized("Review")
        case .newLesson: return settings.localized("New lesson")
        case .mix: return settings.localized("Daily mix")
        }
    }

    private func stepTitle(for step: TodayPlan.Step) -> String {
        if step.kind == .mix {
            return settings.languagePreference.localizedLessonCount(step.lessonIDs.count)
        }
        return step.lessonIDs.first.flatMap { LessonStore.shared.lesson(for: $0) }
            .map { settings.localized($0.title) } ?? settings.localized("Review")
    }

    private func stepScoreText(for step: TodayPlan.Step) -> String {
        guard let outcome = step.outcome, outcome.played else { return "—" }
        if let score = outcome.bestScore {
            return "\(Int((score * 100).rounded())) %"
        }
        return settings.localized("Done")
    }
}
