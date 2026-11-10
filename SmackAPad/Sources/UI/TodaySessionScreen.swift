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

    func reconcileReviews(progress: ProgressStore) {
        let previous = plan
        plan = plan.reconcilingReviews(with: progress.records)
        if !plan.finished {
            movePastDecidedReviews()
            if plan.index != previous.index { updatePhaseAfterAdvance() }
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

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: Theme.Space.page)

                        VStack(spacing: 24) {
                            Text(settings.localized("Reviews") + " · " + settings.localized("%lld today", coordinator.plan.reviewCount))
                                .font(Theme.meta)
                                .foregroundStyle(Theme.secondary)
                            TodayStepperView(plan: coordinator.plan, isLandscape: isLandscape)

                            if coordinator.plan.finished {
                                TodaySummaryView(plan: coordinator.plan, onHome: onHome)
                                    .transition(policy.cardStep)
                            } else {
                                masterConsole(isLandscape: isLandscape)
                                    .id(coordinator.plan.index)
                                    .transition(policy.cardStep)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        Spacer(minLength: Theme.Space.page)
                    }
                    .frame(maxWidth: .infinity, minHeight: max(0, geometry.size.height - 32))
                    .padding(.horizontal, Theme.Space.page)
                    .padding(.vertical, Theme.Space.small)
                    .animation(policy.animation(Theme.Motion.cardStep), value: coordinator.plan.finished)
                    .animation(policy.animation(Theme.Motion.cardStep), value: coordinator.plan.index)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
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
                let launch: LessonLaunch = step.kind == .review ? .review(lesson) : .lesson(lesson)
                PracticeScreen(lesson: lesson, settings: settings, progress: progress, midi: midi,
                               initialFromMemory: launch.reviewTempo != nil,
                               initialBpm: launch.reviewTempo,
                               mixLessons: step.kind == .mix ? step.lessonIDs.compactMap { LessonStore.shared.lesson(for: $0) } : [],
                               onStepResult: { coordinator.record($0) })
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
                        PreviousRunEvaluationView(step: previousStep, index: lastIndex, plan: coordinator.plan)
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
                        PreviousRunEvaluationView(step: previousStep, index: lastIndex, plan: coordinator.plan)
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
                TodaySummaryView(plan: coordinator.plan, onHome: onHome)
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
        guard let step = coordinator.currentStep else { return }
        let lessons = step.lessonIDs.compactMap { LessonStore.shared.lesson(for: $0) }
        guard lessons.count == step.lessonIDs.count,
              lessons.allSatisfy({ store.isUnlocked($0) && progression.isLessonOpen($0)
                  && (midi.activeProfile.padCount == 16 || EightPadLayout.slots(for: $0) != nil) }) else {
            coordinator.skip(progress: progress)
            return
        }
        coordinator.continueSession()
        showingPractice = true
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
                Text(stepTag(step: step, index: index))
                    .font(Theme.strong(11))
                    .tracking(0.55)
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

    private func stepTag(step: TodayPlan.Step, index: Int) -> String {
        let kindTitle: String = {
            switch step.kind {
            case .review: return settings.localized("Review")
            case .newLesson: return settings.localized("New lesson")
            case .mix: return settings.localized("Daily mix")
            }
        }()
        return "\(index + 1). \(kindTitle)"
    }

    private func stepStatus(step: TodayPlan.Step, isCompleted: Bool, isCurrent: Bool, isUpcoming: Bool) -> String {
        if isCompleted {
            guard let status = step.status else { return settings.localized("Not played") }
            return (status == .passed ? "✓ " : "") + settings.localized(status.titleKey)
        }
        if isCurrent {
            if plan.lastPlayedIndex == nil {
                return settings.localized("Start")
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
    let index: Int
    let plan: TodayPlan

    private var isSuccess: Bool {
        step.status == .passed
    }

    private var earnedStars: Int {
        guard let id = step.lessonIDs.first, let record = progress.progress(for: id) else { return 0 }
        return [record.passed, record.mastery, record.memory].filter { $0 }.count
    }

    private var kicker: String {
        let state = settings.localized(step.status?.titleKey ?? "Not played")
        switch step.kind {
        case .review:
            let position = plan.steps.prefix(index + 1).filter { $0.kind == .review }.count
            return settings.localized("Review %lld of %lld", position, plan.reviewCount) + " · " + state
        case .newLesson:
            return settings.localized("New lesson") + " · " + state
        case .mix:
            return settings.localized("Daily mix") + " · " + state
        }
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
            Text(kicker)
                .font(Theme.stepTag)
                .tracking(0.66)
                .foregroundStyle(Theme.secondary)

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

    private var kicker: String {
        isDayStart
            ? settings.localized("FIRST STEP OF THE DAY")
            : settings.localized("PREPARE FOR THE NEXT STEP")
    }

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
            Text(kicker)
                .font(Theme.stepTag)
                .tracking(0.66)
                .foregroundStyle(Theme.secondary)

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

            VStack(spacing: 10) {
                Button(action: onContinue) {
                    Text(primaryButtonTitle)
                        .font(Theme.strong(18))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                }
                .buttonStyle(PadPrimaryButtonStyle())

                HStack(spacing: 10) {
                    Button(action: onSkip) {
                        Text(settings.localized("Skip"))
                            .font(Theme.control)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 48)
                    }
                    .buttonStyle(PadSecondaryButtonStyle())

                    Button(action: onDone) {
                        Text(settings.localized("Done for today"))
                            .font(Theme.control)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 48)
                    }
                    .buttonStyle(PadSecondaryButtonStyle())
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - Summary View (End of Day)

private struct TodaySummaryView: View {
    @Environment(SettingsManager.self) private var settings
    let plan: TodayPlan
    let onHome: () -> Void

    private func newLessonValue(_ step: TodayPlan.Step) -> String {
        if let outcome = step.outcome, outcome.played, let score = outcome.bestScore {
            let percent = Int((score * 100).rounded())
            if let lesson = step.lessonIDs.first.flatMap({ LessonStore.shared.lesson(for: $0) }) {
                return "\(settings.localized(lesson.title)) (\(percent) %)"
            }
            return "\(percent) %"
        }
        return "—"
    }

    private func mixValue(_ step: TodayPlan.Step) -> String {
        if let outcome = step.outcome, outcome.played {
            if let score = outcome.bestScore {
                return "\(Int((score * 100).rounded())) %"
            }
            return settings.localized("Done")
        }
        return "—"
    }

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Theme.orange.opacity(0.12))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Circle()
                            .strokeBorder(Theme.orange, lineWidth: 1)
                    }

                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.orange)
            }

            VStack(spacing: 8) {
                Text(settings.localized("That's enough for today"))
                    .font(Theme.boldDisplay(32))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(settings.localized("Today's session is over. Every played step is shown below."))
                    .font(Theme.text(16))
                    .foregroundStyle(Theme.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 440)
            }

            HStack(spacing: 0) {
                if plan.reviewCount > 0 {
                    statColumn(
                        label: settings.localized("Reviews played"),
                        value: "\(plan.reviewSummary.played) \(settings.localized("of")) \(plan.reviewCount)",
                        isHighlighted: false
                    )
                }

                if let newStep = plan.steps.first(where: { $0.kind == .newLesson }) {
                    if plan.reviewCount > 0 {
                        statDivider
                    }
                    statColumn(
                        label: settings.localized("New lesson"),
                        value: newLessonValue(newStep),
                        isHighlighted: true
                    )
                }

                if let mixStep = plan.steps.first(where: { $0.kind == .mix }) {
                    if plan.reviewCount > 0 || plan.hasNewLesson {
                        statDivider
                    }
                    statColumn(
                        label: settings.localized("Daily mix"),
                        value: mixValue(mixStep),
                        isHighlighted: false
                    )
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .frame(maxWidth: 520)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.hairline, lineWidth: 1))

            if plan.reviewCount > 0 {
                Text(settings.localized("Passed: %lld · Did not count: %lld", plan.reviewSummary.passed, plan.reviewSummary.didNotCount))
                    .font(Theme.text(15))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(plan.steps.enumerated()), id: \.offset) { index, step in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(index + 1). \(resultTitle(step)) · \(settings.localized(step.status?.titleKey ?? "Not played"))")
                            .font(Theme.strong(15))
                        if let reason = step.status?.reason {
                            Text(reason.message(language: settings.languagePreference))
                                .font(Theme.text(14))
                                .foregroundStyle(Theme.secondary)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: 520, alignment: .leading)

            Button(action: onHome) {
                Text(settings.localized("Home"))
                    .font(Theme.strong(18))
                    .padding(.horizontal, 36)
                    .frame(minHeight: 52)
            }
            .buttonStyle(PadPrimaryButtonStyle())
        }
        .padding(40)
        .frame(maxWidth: 700)
        .satinPlate()
    }

    private func resultTitle(_ step: TodayPlan.Step) -> String {
        if step.kind == .mix { return settings.localized("Daily mix") }
        return step.lessonIDs.first.flatMap { LessonStore.shared.lesson(for: $0) }
            .map { settings.localized($0.title) } ?? settings.localized("Review")
    }

    private func statColumn(label: String, value: String, isHighlighted: Bool) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(Theme.strong(11))
                .tracking(0.55)
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
            Text(value)
                .font(Theme.boldDisplay(22))
                .foregroundStyle(isHighlighted ? Theme.orange : Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(width: 1, height: 36)
    }
}
