//
//  TrainingScreen.swift
//  SmackAPad
//
//  New Training screen following ticket 107 and mockup frame 1.
//  Dominant orange Today band, Memory meter, Next 7 days forecast,
//  Calm review queue, Mix & Play after me, and Training badges.
//

import SwiftUI
import Observation

/// Training screen presenting the daily Today plan, memory progression meter,
/// upcoming review forecast, due lessons, Mix, Play after me, and Training badges.
@MainActor
public struct TrainingScreen: View {
    let onHome: () -> Void

    @Environment(StoreManager.self) private var store
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(ProgressionManager.self) private var progression
    @Environment(BadgeStore.self) private var badgeStore
    @Environment(MIDIInput.self) private var midi

    @State private var lessonStore = LessonStore.shared
    @State private var selectedLesson: LessonLaunch?
    @State private var selectedAfterMeLesson: Lesson?
    @State private var afterMeLessonID: Int?
    @State private var data: TrainingData?
    @State private var refreshID = UUID()
    @State private var isVisible = false
    @State private var isQueueVisible = false
    @State private var loadedDailyMixes = ""
    @State private var calendarDay = AppCalendar.today()
    @Environment(\.scenePhase) private var scenePhase
    @State private var mixPresentation: MixCoverItem?
    @State private var mixFromMemory = false
    @State private var showingQueue = false
    @State private var isMemoryExpanded = false
    @State private var showingBadges = false
    @State private var todaySession: TodaySessionCoordinator?
    @State private var todayPractice: TodayPracticePresentation?
    @State private var todayMixFromMemory = false
    @State private var todayPracticeStarted = false
    @State private var daySummary: DaySummaryPresentation?
    @State private var startMixAfterSummary = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var queueSectionOpen: [Int: Bool] = [:]
    @State private var expandedWaitingGroup: WaitingGroup?
    @State private var isSettledExpanded = false

    @AppStorage(TodayPlan.storageKey) private var savedTodayPlan = ""
    @AppStorage("smackapad.training.dailyMixes") private var dailyMixes = "{}"
    @Namespace private var lessonNamespace

    private enum WaitingGroup: String, CaseIterable, Identifiable {
        case tomorrow
        case in2to3Days
        case in4to7Days
        case later

        var id: String { rawValue }
    }

    public init(onHome: @escaping () -> Void = {}) {
        self.onHome = onHome
    }

    /// Derived data is built once per input change, never while evaluating the view tree.
    private struct TrainingData {
        let dueLessons: [Lesson]
        let nextLesson: Lesson?
        let followUpLesson: Lesson?
        var currentPlan: TodayPlan?
        let mixCandidates: [Lesson]
        let openLessonIDs: Set<Int>
        var mixLessons: [Lesson]
        let afterMeCandidates: [Lesson]
        let memoryCounts: [Int]
        let forecast: [(day: String, count: Int)]
        let hasMasteredLesson: Bool
        let nearestDueDay: String?
        let waitingTomorrow: [Lesson]
        let waitingIn2to3Days: [Lesson]
        let waitingIn4to7Days: [Lesson]
        let waitingLater: [Lesson]
        let settledLessons: [Lesson]
    }

    private struct DaySummaryPresentation: Identifiable {
        let id = UUID()
        let plan: TodayPlan
    }

    private enum TodayPracticePresentation {
        case lesson(stepIndex: Int, launch: LessonLaunch)
        case mix(stepIndex: Int, mix: MixCoverItem)
        case summary(TodayPlan)

        var stepID: String {
            switch self {
            case .lesson(let stepIndex, let launch): return "lesson-\(stepIndex)-\(launch.id)"
            case .mix(let stepIndex, let mix): return "mix-\(stepIndex)-\(mix.id.uuidString)"
            case .summary(let plan): return "summary-\(plan.day)-\(plan.index)-\(plan.finished)"
            }
        }
    }

    private var hasActiveCover: Bool {
        selectedLesson != nil || selectedAfterMeLesson != nil || mixPresentation != nil
            || todayPractice != nil || daySummary != nil
    }

    private var continueTarget: TodayContinueTarget? {
        TodayContinueTarget.resolve(
            currentPlan: currentPlan,
            today: today,
            nextLessonID: nextLesson?.id,
            mixLessonIDs: mixLessons.map(\.id)
        )
    }

    private var isTrainingActive: Bool { isVisible || isQueueVisible }
    private var today: String { calendarDay }
    private var dueLessons: [Lesson] { data?.dueLessons ?? [] }
    private var nextLesson: Lesson? { data?.nextLesson }
    private var currentPlan: TodayPlan? {
        let basePlan = TodayPlan.decode(savedTodayPlan, today: today) ?? data?.currentPlan
        return basePlan?.reconcilingReviews(with: progress.records)
    }
    private var reviewLoad: TodayPlan.ReviewLoad {
        TodayPlan.ReviewLoad(dueLessonIDs: dueLessons.map(\.id), plan: currentPlan)
    }
    private var queuedLessons: [Lesson] {
        let ids = Set(reviewLoad.queueIDs)
        return dueLessons.filter { ids.contains($0.id) }
    }

    public var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width >= 768 && geometry.size.width > geometry.size.height

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Space.page) {
                        header

                        if data == nil {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 160)
                                .accessibilityLabel(settings.localized("Training"))
                        } else {
                            VStack(spacing: Theme.Space.controlGap) {
                                todayPanel(isLandscape: isLandscape)
                                WeeklyRhythmStrip(day: today, practiceDays: progress.trainingLog.practiceDays)
                            }

                            if isLandscape {
                                Grid(alignment: .topLeading, horizontalSpacing: Theme.Space.regular) {
                                    GridRow {
                                        afterMeCard
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                        extraMixCard
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    }
                                }
                            } else {
                                afterMeCard
                                extraMixCard
                            }

                            trainingTools(isLandscape: isLandscape)
                        }

                        Spacer(minLength: Theme.Space.page)
                    }
                    .padding(Theme.Space.page)
                    .frame(maxWidth: 1240, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
            }
            .calmChassisBackground()
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showingQueue) {
                reviewQueueDestination
            }
            .navigationDestination(isPresented: $showingBadges) {
                BadgesView(initialGroup: .training) {
                    showingBadges = false
                }
            }
            .task(id: refreshID) {
                if data == nil {
                    // Let the lightweight shell and pad zoom reach the screen before loading data.
                    do { try await Task.sleep(for: .milliseconds(50)) }
                    catch { return }
                }
                refreshTrainingData()
            }
            .onAppear {
                isVisible = true
                if data != nil {
                    refreshTrainingData()
                } else {
                    refreshID = UUID()
                }
                TrainingOpenMeasurement.appeared()
            }
            .onDisappear { isVisible = false }
            .onChange(of: savedTodayPlan) { _, _ in refreshID = UUID() }
            .onChange(of: dailyMixes) { _, value in
                if value != loadedDailyMixes { refreshID = UUID() }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { refreshCalendarDay() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                refreshCalendarDay()
            }
            .fullScreenCover(item: $selectedAfterMeLesson, onDismiss: {
                isVisible = true
                refreshTrainingData()
            }) { lesson in
                PracticeLessonDestination(launch: .afterMe(lesson))
            }
            .fullScreenCover(item: $mixPresentation, onDismiss: {
                isVisible = true
                refreshTrainingData()
            }) { mix in
                if mix.lessons.isEmpty {
                    EmptyCoverFallbackView(context: "TrainingScreen.mixPresentation") {
                        mixPresentation = nil
                    }
                } else {
                    MixFlowScreen(
                        lessons: Binding(
                            get: { mixPresentation?.lessons ?? mix.lessons },
                            set: { mixPresentation?.lessons = $0 }
                        ),
                        fromMemory: $mixFromMemory,
                        onAnotherMix: {
                            refreshMix(newDraw: true)
                            if !mixLessons.isEmpty {
                                mixPresentation?.lessons = mixLessons
                            }
                        }
                    )
                }
            }
            .fullScreenCover(
                isPresented: Binding(
                    get: { todayPractice != nil },
                    set: { if !$0 { todayPractice = nil } }
                ),
                onDismiss: dailyPracticeDismissed
            ) {
                if let presentation = todayPractice {
                    todayPracticeCover(for: presentation)
                        .id(presentation.stepID)
                }
            }
            .fullScreenCover(item: $daySummary, onDismiss: {
                isVisible = true
                refreshTrainingData()
                if startMixAfterSummary {
                    startMixAfterSummary = false
                    refreshMix(newDraw: true)
                    if !mixLessons.isEmpty { mixPresentation = MixCoverItem(lessons: mixLessons) }
                }
            }) { summary in
                GeometryReader { geometry in
                    DaySummaryView(
                        plan: summary.plan,
                        isLandscape: geometry.size.width >= 768 && geometry.size.width > geometry.size.height,
                        canStartExtraMix: mixCandidates.count >= LearningRules.minimumMixLessons,
                        onBack: { daySummary = nil },
                        onExtraMix: {
                            startMixAfterSummary = true
                            daySummary = nil
                        },
                        onEndTraining: { daySummary = nil }
                    )
                    .calmChassisBackground()
                }
            }
        }
        .environment(\.lessonNamespace, lessonNamespace)
        .practiceLessonPresentation(launch: $selectedLesson, namespace: lessonNamespace)
        .onChange(of: selectedLesson?.id) { _, id in
            if id == nil {
                isVisible = true
                refreshTrainingData()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            BackButton(action: onHome)

            Text(settings.localized("Training"))
                .font(Theme.screenTitle)
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 16)

            Text(DayDateFormatter.format(today, language: settings.languagePreference))
                .font(Theme.text(15))
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
        }
        .frame(height: 56)
    }

    // MARK: - 1. Today Panel

    private func stepTitle(_ step: TodayPlan.Step) -> String {
        if step.kind == .mix { return settings.localized("Daily mix") }
        return step.lessonIDs.first.flatMap { lessonStore.lesson(for: $0) }
            .map { settings.localized($0.title) } ?? "—"
    }

    private func stepTag(_ step: TodayPlan.Step) -> String {
        switch step.kind {
        case .review: return settings.localized("Review")
        case .newLesson: return settings.localized("New lesson")
        case .mix: return settings.localized("Mix · optional")
        }
    }

    private func todayPanel(isLandscape: Bool) -> some View {
        let target = continueTarget
        let steps = target?.plan.steps ?? []
        let tiles = ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
            dailyStepTile(step, index: index, currentIndex: target?.plan.index ?? 0)
        }

        return VStack(alignment: .leading, spacing: Theme.Space.controlGap) {
            Text(settings.localized("Today"))
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.black)
                .accessibilityAddTraits(.isHeader)

            if isLandscape && (1...3).contains(steps.count) {
                HStack(alignment: .top, spacing: Theme.Space.small) {
                    tiles
                    continueButton(for: target).frame(width: 192)
                }
            } else {
                if !steps.isEmpty {
                    let columns = Array(repeating: GridItem(.flexible(), spacing: Theme.Space.small),
                                        count: isLandscape ? 3 : 2)
                    LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.Space.small) {
                        tiles
                    }
                }
                continueButton(for: target)
            }
        }
        .padding(Theme.Space.regular)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.orange, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
    }

    private func dailyStepTile(_ step: TodayPlan.Step, index: Int, currentIndex: Int) -> some View {
        let isDone = index < currentIndex || step.outcome?.played == true
        let isCurrent = !isDone && index == currentIndex
        let status = settings.localized(isDone ? step.status?.titleKey ?? "Not played" : isCurrent ? "training.now" : "Waiting")
        let detail: String = {
            if isDone {
                if step.kind == .review,
                   let reason = step.reviewFailureReason(language: settings.languagePreference) { return reason }
                if let score = step.outcome?.bestScore { return "\(Int((score * 100).rounded())) %" }
                return settings.localized("Not played")
            }
            if step.kind == .mix { return settings.languagePreference.localizedLessonCount(step.lessonIDs.count) }
            return isCurrent ? "" : status
        }()
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.panel)

        return VStack(alignment: .leading, spacing: Theme.Space.tight) {
            HStack(spacing: Theme.Space.tight) {
                Text(stepTag(step))
                    .font(Theme.caption)
                Spacer(minLength: 0)
                if isDone {
                    Image(systemName: step.markerSymbol ?? (step.outcome?.played == true ? "checkmark" : "minus"))
                        .font(.system(size: 13, weight: .semibold))
                } else if isCurrent {
                    Text(status.uppercased(with: Locale(identifier: settings.languagePreference.rawValue)))
                        .font(Theme.strong(12))
                        .padding(.horizontal, Theme.Space.tight)
                        .foregroundStyle(Theme.white)
                        .background(Theme.black, in: RoundedRectangle(cornerRadius: Theme.Radius.button))
                }
            }

            Text(stepTitle(step))
                .font(Theme.sectionTitle)
            if !detail.isEmpty {
                Text(detail)
                    .font(Theme.caption.monospacedDigit())
            }
        }
        .foregroundStyle(Theme.black)
        .padding(Theme.Space.controlGap)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .background {
            shape.fill(isDone || isCurrent ? Theme.white : Theme.Skin.Plate.top)
                .environment(\.colorScheme, .light)
        }
        .overlay {
            if isCurrent {
                shape.strokeBorder(Theme.black, lineWidth: 2)
            } else if !isDone {
                shape.strokeBorder(Theme.black.opacity(0.20), lineWidth: 1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([stepTag(step), stepTitle(step), status, detail == status ? "" : detail]
            .filter { !$0.isEmpty }.joined(separator: ", "))
    }

    private func continueButton(for target: TodayContinueTarget?) -> some View {
        let title: String = switch target {
        case .summary: "Summary"
        case .step(let plan) where plan.index > 0: "Continue"
        default: "Start"
        }

        return Button(action: startTodayTraining) {
            VStack(alignment: .leading, spacing: Theme.Space.tight) {
                Text(settings.localized(title))
                    .font(Theme.sectionTitle)
                Text(continueSubtitle(for: target))
                    .font(Theme.caption.monospacedDigit())
                    .lineLimit(2)
            }
            .padding(.vertical, Theme.Space.controlGap)
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        }
        .buttonStyle(PadPrimaryButtonStyle(darkFace: true))
        .disabled(target == nil)
    }

    private func continueSubtitle(for target: TodayContinueTarget?) -> String {
        guard let target else { return settings.localized("training.nothingDue") }
        guard case .step(let plan) = target else { return settings.localized("training.doneForToday") }
        let remaining = plan.remainingStepCount
        let format: String = if remaining == 1 {
            "%lld step · ~%lld min"
        } else if settings.languagePreference == .czech && remaining >= 5 {
            "%lld kroků · ~%lld min"
        } else {
            "%lld steps · ~%lld min"
        }
        return settings.localized(format, remaining, plan.estimatedMinutes)
    }

    private func preserveTodayPlan(for lessonID: Int) {
        guard TodayPlan.decode(savedTodayPlan, today: today) == nil,
              let plan = currentPlan,
              plan.steps.contains(where: { $0.kind == .review && $0.lessonIDs.first == lessonID }),
              let json = plan.encoded else { return }
        savedTodayPlan = json
    }

    private func startTodayTraining() {
        guard !hasActiveCover, let target = continueTarget else { return }
        let session = makeTodaySession(target.plan)
        todaySession = session
        session.reconcileReviews(progress: progress)
        openDailyStep()
    }

    private func makeTodaySession(_ plan: TodayPlan) -> TodaySessionCoordinator {
        #if DEBUG
        TodaySessionCoordinator(plan: plan, defaults: DebugProfileStorage.defaults)
        #else
        TodaySessionCoordinator(plan: plan)
        #endif
    }

    @ViewBuilder
    private func todayPracticeCover(for presentation: TodayPracticePresentation) -> some View {
        switch presentation {
        case .lesson(let stepIndex, let launch):
            PracticeScreen(
                lesson: launch.lesson,
                settings: settings,
                progress: progress,
                midi: midi,
                initialFromMemory: launch.reviewTempo != nil,
                initialBpm: launch.reviewTempo,
                onStepResult: { todaySession?.record($0, at: stepIndex) },
                dailyNextTitle: dailyNextTitle(after: stepIndex),
                onAdvanceDailyStep: { advanceDailyStep() }
            )
        case .mix(let stepIndex, let mix):
            MixFlowScreen(
                lessons: dailyMixBinding(fallback: mix.lessons),
                fromMemory: $todayMixFromMemory,
                onAnotherMix: rerollDailyMix,
                onMixStarted: {
                    todayPracticeStarted = true
                    todaySession?.continueSession()
                },
                onStepResult: { todaySession?.record($0, at: stepIndex) },
                dailyNextTitle: dailyNextTitle(after: stepIndex),
                onAdvanceDailyStep: { advanceDailyStep() }
            )
        case .summary(let plan):
            GeometryReader { geometry in
                DaySummaryView(
                    plan: plan,
                    isLandscape: geometry.size.width >= 768 && geometry.size.width > geometry.size.height,
                    canStartExtraMix: mixCandidates.count >= LearningRules.minimumMixLessons,
                    onBack: { todayPractice = nil },
                    onExtraMix: {
                        startMixAfterSummary = true
                        todayPractice = nil
                    },
                    onEndTraining: { todayPractice = nil }
                )
                .calmChassisBackground()
            }
        }
    }

    private func canOpenDailyStep(_ step: TodayPlan.Step) -> Bool {
        let lessons = step.lessonIDs.compactMap { lessonStore.lesson(for: $0) }
        guard lessons.count == step.lessonIDs.count else { return false }
        return lessons.allSatisfy {
            store.isUnlocked($0) && progression.isLessonOpen($0)
                && (midi.activeProfile.padCount == 16 || EightPadLayout.slots(for: $0) != nil)
        }
    }

    private func dailyNextTitle(after stepIndex: Int) -> String {
        guard let plan = todaySession?.plan else {
            return settings.localized("Finish training")
        }
        let nextStep = plan.steps.enumerated().first { idx, step in
            idx > stepIndex && step.outcome?.played != true && canOpenDailyStep(step)
        }?.element
        if let nextStep {
            return settings.localized("Continue · %@", stepTitle(nextStep))
        }
        return settings.localized("Finish training")
    }

    private func openDailyStep(inActiveCover: Bool = false) {
        guard let session = todaySession, session.plan.day == AppCalendar.today() else { return }
        while true {
            guard case .step(let plan) = session.nextAction else {
                todayPracticeStarted = false
                if inActiveCover {
                    todayPractice = .summary(session.plan)
                } else {
                    showDaySummary()
                }
                return
            }
            let stepIndex = plan.index
            let step = plan.steps[stepIndex]
            let lessons = step.lessonIDs.compactMap { lessonStore.lesson(for: $0) }
            guard canOpenDailyStep(step) else {
                session.skip(progress: progress)
                continue
            }
            if step.kind == .mix {
                todayPracticeStarted = false
                todayPractice = .mix(stepIndex: stepIndex, mix: MixCoverItem(lessons: lessons))
            } else if let lesson = lessons.first {
                session.continueSession()
                todayPracticeStarted = true
                todayPractice = .lesson(
                    stepIndex: stepIndex,
                    launch: step.kind == .review ? .review(lesson) : .lesson(lesson)
                )
            }
            return
        }
    }

    private func advanceDailyStep() {
        guard let session = todaySession, session.plan.day == AppCalendar.today() else {
            todayPractice = nil
            return
        }
        if todayPracticeStarted {
            session.leavePractice(progress: progress)
        }
        openDailyStep(inActiveCover: true)
    }

    private func dailyPracticeDismissed() {
        isVisible = true
        guard let session = todaySession, session.plan.day == AppCalendar.today() else {
            todayPracticeStarted = false
            refreshCalendarDay()
            return
        }
        if todayPracticeStarted {
            session.leavePractice(progress: progress)
        }
        todayPracticeStarted = false
        refreshTrainingData()
        if startMixAfterSummary {
            startMixAfterSummary = false
            refreshMix(newDraw: true)
            if !mixLessons.isEmpty { mixPresentation = MixCoverItem(lessons: mixLessons) }
        }
    }

    private func showDaySummary() {
        guard let session = todaySession else { return }
        daySummary = DaySummaryPresentation(plan: session.plan)
    }

    private func dailyMixBinding(fallback: [Lesson]) -> Binding<[Lesson]> {
        Binding(
            get: {
                if case .mix(_, let mix) = todayPractice { return mix.lessons }
                return fallback
            },
            set: { lessons in
                if case .mix(let stepIndex, var mix) = todayPractice {
                    mix.lessons = lessons
                    todayPractice = .mix(stepIndex: stepIndex, mix: mix)
                    todaySession?.replaceCurrentMixLessons(lessons)
                }
            }
        )
    }

    private func rerollDailyMix() {
        guard case .mix(let stepIndex, var mix) = todayPractice else { return }
        let chosen = TrainingMix.reroll(
            excluding: mix.lessons.map(\.id), lessons: progression.catalog.lessons,
            progress: progress.records, padCount: midi.activeProfile.padCount,
            openLessonIDs: data?.openLessonIDs ?? [], day: today
        )
        guard chosen.count >= LearningRules.minimumMixLessons else { return }
        mix.lessons = chosen
        todayPractice = .mix(stepIndex: stepIndex, mix: mix)
        todaySession?.replaceCurrentMixLessons(chosen)
        saveMix(chosen.map(\.id))
        updateMix(chosen.map(\.id))
    }

    // MARK: - 2. Memory Meter & Next 7 Days

    private var memoryMeterPanel: some View {
        let counts = data?.memoryCounts ?? [0, 0, 0, 0, 0]
        let learned = counts[0], step1 = counts[1], step2 = counts[2]
        let step3 = counts[3], settled = counts[4]

        let largest = max(1, max(learned, max(step1, max(step2, max(step3, settled)))))

        return VStack(alignment: .leading, spacing: Theme.Space.regular) {
            panelHeader(settings.localized("Memory"))

            HStack(alignment: .top, spacing: 10) {
                meterColumn(label: settings.localized("Learned ★★"), count: learned, largest: largest, isSettled: false,
                            accessibilityPrefix: settings.localized("Learned ★★"))
                meterColumn(label: settings.localized("Step 1"), count: step1, largest: largest, isSettled: false,
                            accessibilityPrefix: settings.localized("Step 1"))
                meterColumn(label: settings.localized("Step 2"), count: step2, largest: largest, isSettled: false,
                            accessibilityPrefix: settings.localized("Step 2"))
                meterColumn(label: settings.localized("Step 3"), count: step3, largest: largest, isSettled: false,
                            accessibilityPrefix: settings.localized("Step 3"))
                meterColumn(label: settings.localized("Settled"), count: settled, largest: largest, isSettled: true,
                            accessibilityPrefix: settings.localized("Settled"))
            }
        }
        .padding(Theme.Space.regular)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.panel)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        }
    }

    private func meterColumn(label: String, count: Int, largest: Int, isSettled: Bool, accessibilityPrefix: String) -> some View {
        let litCount: Int = {
            guard count > 0 else { return 0 }
            let raw = Int((Double(count) / Double(largest) * 8.0).rounded())
            return min(8, max(1, raw))
        }()

        let offColor = Theme.ledOff
        let litColor = isSettled ? Theme.orange : Theme.ink

        let lessonCountPlural = settings.languagePreference.localizedLessonCount(count)

        return VStack(alignment: .leading, spacing: 6) {
            // Segment stack: 8 segments, top to bottom is 7 down to 0
            VStack(spacing: 3) {
                ForEach((0..<8).reversed(), id: \.self) { segIndex in
                    Rectangle()
                        .fill(segIndex < litCount ? litColor : offColor)
                        .frame(height: 9)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 93)

            Text("\(count)")
                .font(Theme.strong(20).monospacedDigit())
                .foregroundStyle(Theme.ink)

            Text(label)
                .font(Theme.text(13))
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(accessibilityPrefix): \(lessonCountPlural)")
    }

    private var next7DaysPanel: some View {
        let forecast = data?.forecast ?? []
        let offColor = Theme.ledOff

        return VStack(alignment: .leading, spacing: Theme.Space.regular) {
            panelHeader(settings.localized("Next 7 days"))

            HStack(spacing: Theme.Space.segmentedGap) {
                ForEach(forecast, id: \.day) { entry in
                    let isToday = (entry.day == today)
                    let (shortName, fullName) = weekdayNames(from: entry.day)
                    let countPlural = settings.languagePreference.localizedLessonCount(entry.count)

                    let offset = AppCalendar.daysBetween(today, entry.day) ?? 0
                    let targetGroup: WaitingGroup? = {
                        guard offset > 0 else { return nil }
                        if offset == 1 { return .tomorrow }
                        if offset == 2 || offset == 3 { return .in2to3Days }
                        if offset >= 4 && offset <= 7 { return .in4to7Days }
                        return .later
                    }()
                    let isTappable = entry.count > 0 && targetGroup != nil

                    let cellContent = VStack(spacing: 4) {
                        Text(shortName)
                            .font(Theme.text(13))
                            .foregroundStyle(Theme.secondary)

                        Text("\(entry.count)")
                            .font(Theme.strong(22).monospacedDigit())
                            .foregroundStyle(entry.count > 0 ? Theme.ink : offColor)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 2)
                    .frame(maxWidth: .infinity)
                    .background(isToday ? Theme.background : Color.clear, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.panel)
                            .stroke(isToday ? Theme.ink : Theme.hairline, lineWidth: isToday ? 2 : 1)
                    )
                    .overlay(alignment: .bottom) {
                        if isToday {
                            HardwareLightBar(active: true, breathes: false)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.panel))
                    .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.panel))

                    if isTappable {
                        Button {
                            if let targetGroup {
                                expandedWaitingGroup = targetGroup
                                showingQueue = true
                            }
                        } label: {
                            cellContent
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(fullName), \(countPlural)")
                        .accessibilityAddTraits(.isButton)
                    } else {
                        cellContent
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(fullName), \(countPlural)")
                    }
                }
            }

            Text(settings.localized("Total review queue by that day if nothing is played. Includes earlier reviews; Today still selects at most two."))
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
        }
        .padding(Theme.Space.regular)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.panel)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        }
    }

    private func weekdayNames(from dayString: String) -> (short: String, full: String) {
        let parts = dayString.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return (dayString, dayString) }
        var comp = DateComponents()
        comp.year = parts[0]; comp.month = parts[1]; comp.day = parts[2]
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        guard let date = cal.date(from: comp) else { return (dayString, dayString) }

        let locale = Locale(identifier: settings.languagePreference.rawValue)
        let shortFmt = DateFormatter()
        shortFmt.locale = locale
        shortFmt.dateFormat = "EE"
        let short = shortFmt.string(from: date).capitalized(with: locale)

        let fullFmt = DateFormatter()
        fullFmt.locale = locale
        fullFmt.dateFormat = "EEEE"
        let full = fullFmt.string(from: date).capitalized(with: locale)

        return (short, full)
    }

    // MARK: - 3. Due Now

    /// Section keys: 0...3 are review steps 1...4, `allSectionKey` is "All lessons".
    private static let allSectionKey = -1

    private var firstOpenQueueStep: Int? {
        (0...3).first { step in
            queuedLessons.contains { (progress.progress(for: $0.id)?.reviewStep ?? 0) == step }
        }
    }

    private func queueLessons(forStep step: Int?) -> [Lesson] {
        let matching = step == nil ? queuedLessons : queuedLessons.filter {
            (progress.progress(for: $0.id)?.reviewStep ?? 0) == step
        }
        return ReviewQueue.displayOrder(matching)
    }

    private func isQueueSectionOpen(_ key: Int) -> Bool {
        queueSectionOpen[key] ?? (key == firstOpenQueueStep)
    }

    private func queueSection(key: Int, title: String, lessons: [Lesson]) -> some View {
        let isEmpty = lessons.isEmpty
        let isOpen = !isEmpty && isQueueSectionOpen(key)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                    queueSectionOpen[key] = !isOpen
                }
            } label: {
                HStack(spacing: Theme.Space.regular) {
                    Text(title)
                        .font(Theme.strong(18))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(settings.localized("%lld lessons", lessons.count))
                        .font(Theme.meta.monospacedDigit())
                        .foregroundStyle(Theme.secondary)
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isOpen ? Theme.orange : Theme.secondary)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: Theme.Size.touch)
                .background(isOpen ? Theme.activeFill : Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .stroke(isOpen ? Theme.orange : Theme.hairline, lineWidth: isOpen ? 1.5 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isEmpty)
            .opacity(isEmpty ? 0.35 : 1.0)
            .accessibilityAddTraits(isOpen ? [.isSelected] : [])

            if isOpen {
                VStack(spacing: 0) {
                    ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                        if index > 0 {
                            Rectangle()
                                .fill(Theme.hairline)
                                .frame(height: 1)
                        }
                        dueLessonRow(lesson)
                    }
                }
                .padding(.top, Theme.Space.small)
            }
        }
    }

    private var dueNowPanel: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            panelHeader(settings.localized("Review queue"))

            Text(settings.localized("%lld in queue · take these at your own pace", queuedLessons.count))
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                if data?.hasMasteredLesson != true {
                    emptyCardText(settings.localized("Reviews start once a lesson has two stars."))
                } else if queuedLessons.isEmpty && !dueLessons.isEmpty {
                    emptyCardText(settings.localized("Today's reviews are in the plan above. Nothing else is waiting in the queue."))
                } else if queuedLessons.isEmpty {
                    let nextDateFormatted: String = {
                        if let nearest = data?.nearestDueDay {
                            return formattedDate(from: nearest)
                        } else {
                            return "—"
                        }
                    }()
                    emptyCardText(settings.localized("Nothing to review today. Next: %@", nextDateFormatted))
                } else {
                    VStack(alignment: .leading, spacing: Theme.Space.small) {
                        ForEach(0..<4, id: \.self) { step in
                            queueSection(
                                key: step,
                                title: [settings.localized("Step 1"), settings.localized("Step 2"), settings.localized("Step 3"), settings.localized("Step 4")][step],
                                lessons: queueLessons(forStep: step)
                            )
                        }
                        queueSection(
                            key: Self.allSectionKey,
                            title: settings.localized("All lessons"),
                            lessons: queueLessons(forStep: nil)
                        )
                    }
                }
            }
        }
        .padding(Theme.Space.regular)
        .frame(maxWidth: .infinity, alignment: .leading)
        .satinPlate()
    }

    private func emptyCardText(_ text: String) -> some View {
        Text(text)
            .font(Theme.meta)
            .foregroundStyle(Theme.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dueLessonRow(_ lesson: Lesson) -> some View {
        let record = progress.progress(for: lesson.id)
        let step = (record?.reviewStep ?? 0) + 1

        return Button {
            guard !hasActiveCover else { return }
            preserveTodayPlan(for: lesson.id)
            selectedLesson = .review(lesson)
        } label: {
            HStack(alignment: .center, spacing: Theme.Space.regular) {
                Text(settings.localized(lesson.title))
                    .font(Theme.strong(20))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                StarsView(record: record, lesson: lesson)

                Text(settings.localized("Step %lld of 4", step))
                    .font(Theme.meta.monospacedDigit())
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .overlay(Rectangle().stroke(Theme.ink, lineWidth: 2))

                let subtext = record?.lastReviewFailDay == today
                    ? settings.localized("Tried today · not met yet")
                    : settings.localized("Ready for review")
                Text(subtext)
                    .font(Theme.text(14))
                    .foregroundStyle(record?.lastReviewFailDay == today ? Theme.orange : Theme.secondary)
                    .fixedSize()
            }
            .padding(.vertical, 8)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .lessonSource(lesson.id)
    }

    // MARK: - 3b. Waiting (reviews not yet due)

    @ViewBuilder
    private var waitingPanel: some View {
        let tomorrowLessons = data?.waitingTomorrow ?? []
        let in2to3Lessons = data?.waitingIn2to3Days ?? []
        let in4to7Lessons = data?.waitingIn4to7Days ?? []
        let laterLessons = data?.waitingLater ?? []

        let hasAny = !tomorrowLessons.isEmpty || !in2to3Lessons.isEmpty || !in4to7Lessons.isEmpty || !laterLessons.isEmpty

        if hasAny {
            VStack(alignment: .leading, spacing: Theme.Space.regular) {
                panelHeader(settings.localized("Waiting"))

                FlowLayout(spacing: Theme.Space.controlGap) {
                    if !tomorrowLessons.isEmpty {
                        waitingBoxButton(
                            group: .tomorrow,
                            title: settings.localized("Tomorrow (%lld)", tomorrowLessons.count)
                        )
                    }
                    if !in2to3Lessons.isEmpty {
                        waitingBoxButton(
                            group: .in2to3Days,
                            title: settings.localized("In 2–3 days (%lld)", in2to3Lessons.count)
                        )
                    }
                    if !in4to7Lessons.isEmpty {
                        waitingBoxButton(
                            group: .in4to7Days,
                            title: settings.localized("In 4–7 days (%lld)", in4to7Lessons.count)
                        )
                    }
                    if !laterLessons.isEmpty {
                        waitingBoxButton(
                            group: .later,
                            title: settings.localized("Later (%lld)", laterLessons.count)
                        )
                    }
                }

                if let openGroup = expandedWaitingGroup {
                    let lessons: [Lesson] = {
                        switch openGroup {
                        case .tomorrow: return tomorrowLessons
                        case .in2to3Days: return in2to3Lessons
                        case .in4to7Days: return in4to7Lessons
                        case .later: return laterLessons
                        }
                    }()

                    if !lessons.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                                if index > 0 {
                                    Rectangle()
                                        .fill(Theme.hairline)
                                        .frame(height: 1)
                                }
                                waitingLessonRow(lesson)
                            }
                        }
                        .padding(.top, Theme.Space.small)
                    }
                }
            }
            .padding(Theme.Space.regular)
            .frame(maxWidth: .infinity, alignment: .leading)
            .satinPlate()
        }
    }

    private func waitingBoxButton(group: WaitingGroup, title: String) -> some View {
        let isOpen = (expandedWaitingGroup == group)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if expandedWaitingGroup == group {
                    expandedWaitingGroup = nil
                } else {
                    expandedWaitingGroup = group
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(Theme.strong(15))
                    .foregroundStyle(Theme.ink)
                Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isOpen ? Theme.orange : Theme.secondary)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: Theme.Size.touch)
            .background(isOpen ? Theme.activeFill : Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(isOpen ? Theme.orange : Theme.hairline, lineWidth: isOpen ? 1.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOpen ? [.isSelected] : [])
    }

    private func waitingLessonRow(_ lesson: Lesson) -> some View {
        let record = progress.progress(for: lesson.id)
        let step = (record?.reviewStep ?? 0) + 1
        let subtext = record?.lastReviewFailDay == today
            ? settings.localized("Tried today · not met yet")
            : waitingSubtext(for: record?.reviewDueDay)

        return Button {
            guard !hasActiveCover else { return }
            selectedLesson = .lesson(lesson)
        } label: {
            HStack(alignment: .center, spacing: Theme.Space.regular) {
                Text(settings.localized(lesson.title))
                    .font(Theme.strong(20))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                StarsView(record: record, lesson: lesson)

                Text(settings.localized("Step %lld of 4", step))
                    .font(Theme.meta.monospacedDigit())
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .overlay(Rectangle().stroke(Theme.ink, lineWidth: 2))

                Text(subtext)
                    .font(Theme.text(14))
                    .foregroundStyle(Theme.secondary)
                    .fixedSize()
            }
            .padding(.vertical, 8)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .lessonSource(lesson.id)
    }

    private func waitingSubtext(for dueDay: String?) -> String {
        guard let dueDay else { return "" }
        let diff = AppCalendar.daysBetween(today, dueDay) ?? 0
        if settings.languagePreference == .czech {
            if diff <= 1 {
                return "Opakování zítra · jen cvičení"
            } else if diff >= 2 && diff <= 4 {
                return "Opakování za \(diff) dny · jen cvičení"
            } else {
                return "Opakování za \(diff) dní · jen cvičení"
            }
        } else {
            if diff <= 1 {
                return settings.localized("Review tomorrow · practice only")
            } else {
                return settings.localized("Review in %lld days · practice only", diff)
            }
        }
    }

    // MARK: - 4. Extra Mix & Play After Me Cards

    private var mixCandidates: [Lesson] { data?.mixCandidates ?? [] }
    private var openMixLessonIDs: Set<Int> { data?.openLessonIDs ?? [] }
    private var mixLessons: [Lesson] { data?.mixLessons ?? [] }

    private var extraMixCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Text(settings.localized("Extra mix"))
                    .font(Theme.sectionTitle)
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Toggle(isOn: $mixFromMemory) {
                    Text(settings.localized("From memory"))
                        .font(Theme.text(14))
                        .foregroundStyle(Theme.secondary)
                }
                .fixedSize()
                .tint(Theme.orange)
                .disabled(mixLessons.count < LearningRules.minimumMixLessons)
            }

            VStack(alignment: .leading, spacing: 6) {
                if mixLessons.count >= LearningRules.minimumMixLessons {
                    ForEach(mixLessons) { lesson in
                        Text(settings.localized(lesson.title))
                            .font(Theme.strong(17))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                    }
                } else {
                    Text(settings.localized("Mix needs two lessons with two stars."))
                        .font(Theme.text(15))
                        .foregroundStyle(Theme.secondary)
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 12) {
                Button {
                    refreshMix(newDraw: true)
                } label: {
                    Text(settings.localized("Another mix"))
                        .font(Theme.strong(16))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(PadSecondaryButtonStyle())
                .disabled(mixLessons.count < LearningRules.minimumMixLessons)

                Button {
                    guard !hasActiveCover, mixLessons.count >= LearningRules.minimumMixLessons else { return }
                    mixPresentation = MixCoverItem(lessons: mixLessons)
                } label: {
                    Text(settings.localized("Start mix"))
                        .font(Theme.strong(16))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(PadPrimaryButtonStyle())
                .disabled(mixLessons.count < LearningRules.minimumMixLessons)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.panel)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        }
    }

    private func refreshMix(newDraw: Bool = false) {
        func draw(_ seed: UInt64) -> [Int] {
            TrainingMix.select(lessons: progression.catalog.lessons, progress: progress.records,
                padCount: midi.activeProfile.padCount, openLessonIDs: openMixLessonIDs,
                day: today, draw: seed).map(\.id)
        }
        var chosen = newDraw ? draw(UInt64.random(in: 1...1_000_000))
            : TrainingMix.dailySelection(lessons: progression.catalog.lessons, progress: progress.records,
                padCount: midi.activeProfile.padCount, openLessonIDs: openMixLessonIDs,
                day: today, savedJSON: dailyMixes).map(\.id)
        if newDraw, Set(chosen) == Set(mixLessons.map(\.id)) {
            for seed in 1...50 {
                let alternative = draw(UInt64(seed))
                if Set(alternative) != Set(mixLessons.map(\.id)) { chosen = alternative; break }
            }
            if chosen == mixLessons.map(\.id), let first = chosen.first {
                chosen = Array(chosen.dropFirst()) + [first]
            }
        }
        updateMix(chosen)
        saveMix(chosen)
    }

    private var afterMeCandidates: [Lesson] { data?.afterMeCandidates ?? [] }

    private func chooseAfterMeLesson(another: Bool = false) {
        let candidates = afterMeCandidates
        if !another, candidates.contains(where: { $0.id == afterMeLessonID }) { return }
        let alternatives = candidates.filter { $0.id != afterMeLessonID }
        let preferred = alternatives.filter { progress.progress(for: $0.id)?.memory != true }
        let pool = preferred.isEmpty ? alternatives : preferred
        afterMeLessonID = (another ? pool.randomElement() : pool.first)?.id ?? candidates.first?.id
    }

    private var afterMeCard: some View {
        let candidate = afterMeCandidates.first(where: { $0.id == afterMeLessonID })

        return VStack(alignment: .leading, spacing: 14) {
            Text(settings.localized("Play after me"))
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
                .lineLimit(1)

            if let lesson = candidate {
                HStack(spacing: 12) {
                    Text(settings.localized(lesson.title))
                        .font(Theme.boldDisplay(22))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    StarsView(record: progress.progress(for: lesson.id), lesson: lesson)
                }

                Text(settings.localized("App plays, you repeat."))
                    .font(Theme.text(15))
                    .foregroundStyle(Theme.secondary)
            } else {
                Text(settings.localized("Learn a lesson to play after me."))
                    .font(Theme.text(15))
                    .foregroundStyle(Theme.secondary)
            }

            Spacer(minLength: 8)

            HStack(spacing: 12) {
                Button {
                    chooseAfterMeLesson(another: true)
                } label: {
                    Text(settings.localized("Another lesson"))
                        .font(Theme.strong(16))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(PadSecondaryButtonStyle())
                .disabled(afterMeCandidates.count < 2)

                Button {
                    if let candidate, !hasActiveCover {
                        selectedAfterMeLesson = candidate
                    }
                } label: {
                    Text(settings.localized("Start"))
                        .font(Theme.strong(16))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(PadPrimaryButtonStyle())
                .disabled(candidate == nil)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.panel)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        }
    }

    // MARK: - 5. Compact Rows & Queue Screen

    private func trainingTools(isLandscape: Bool) -> some View {
        VStack(spacing: 0) {
            reviewQueueRow
            Rectangle().fill(Theme.hairline).frame(height: 1)
            memoryAndForecastRow
            if isMemoryExpanded {
                Group {
                    if isLandscape {
                        HStack(alignment: .top, spacing: Theme.Space.controlGap) {
                            memoryMeterPanel
                            next7DaysPanel
                        }
                    } else {
                        VStack(spacing: Theme.Space.controlGap) {
                            memoryMeterPanel
                            next7DaysPanel
                        }
                    }
                }
                .padding(Theme.Space.controlGap)
            }
            Rectangle().fill(Theme.hairline).frame(height: 1)
            trainingBadgesRow
        }
        .padding(.horizontal, Theme.Space.small)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
    }

    private var reviewQueueRow: some View {
        trainingListRow(
            title: settings.localized("Review queue"),
            detail: "\(queuedLessons.count)",
            chevron: "chevron.right"
        ) {
            showingQueue = true
        }
    }

    private var memoryAndForecastRow: some View {
        trainingListRow(
            title: settings.localized("Memory and next 7 days"),
            detail: nil,
            chevron: isMemoryExpanded ? "chevron.up" : "chevron.down"
        ) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isMemoryExpanded.toggle()
            }
        }
    }

    private var trainingBadgesRow: some View {
        let trainingDefs = badgeStore.definitions.filter { $0.group == .training }
        let earnedCount = trainingDefs.filter { badgeStore.earnedDate(for: $0.id) != nil }.count

        return trainingListRow(
            title: settings.localized("Training badges"),
            detail: "\(earnedCount) / \(trainingDefs.count)",
            chevron: "chevron.right"
        ) {
            showingBadges = true
        }
    }

    private func trainingListRow(
        title: String,
        detail: String?,
        chevron: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(Theme.strong(16))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                Spacer(minLength: 12)

                if let detail {
                    Text(detail)
                        .font(Theme.text(15).monospacedDigit())
                        .foregroundStyle(Theme.secondary)
                }

                Image(systemName: chevron)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
            }
            .padding(.horizontal, Theme.Space.small)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.row)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var reviewQueueDestination: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.page) {
                HStack(spacing: 16) {
                    BackButton {
                        showingQueue = false
                    }

                    Text(settings.localized("Review queue"))
                        .font(Theme.boldDisplay(28))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)

                    Spacer()
                }
                .frame(height: 56)

                dueNowPanel

                waitingPanel

                settledPanel

                Spacer(minLength: Theme.Space.page)
            }
            .padding(Theme.Space.page)
            .frame(maxWidth: 1240, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .calmChassisBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            isQueueVisible = true
            refreshTrainingData()
        }
        .onDisappear { isQueueVisible = false }
    }

    // MARK: - 6. Settled

    @ViewBuilder
    private var settledPanel: some View {
        let settled = data?.settledLessons ?? []
        if !settled.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Space.regular) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSettledExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(settings.localized("Settled (%lld)", settled.count))
                            .font(Theme.strong(18))
                            .foregroundStyle(Theme.ink)

                        Spacer()

                        Image(systemName: isSettledExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.secondary)
                    }
                    .padding(Theme.Space.regular)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .stroke(isSettledExpanded ? Theme.orange : Theme.hairline, lineWidth: isSettledExpanded ? 1.5 : 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSettledExpanded ? [.isSelected] : [])

                if isSettledExpanded {
                    VStack(spacing: 0) {
                        ForEach(Array(settled.enumerated()), id: \.element.id) { index, lesson in
                            if index > 0 {
                                Rectangle()
                                    .fill(Theme.hairline)
                                    .frame(height: 1)
                            }
                            settledLessonRow(lesson)
                        }
                    }
                    .padding(.horizontal, Theme.Space.regular)
                    .padding(.bottom, Theme.Space.small)
                }
            }
            .satinPlate()
        }
    }

    private func settledLessonRow(_ lesson: Lesson) -> some View {
        let record = progress.progress(for: lesson.id)

        return Button {
            guard !hasActiveCover else { return }
            selectedLesson = .lesson(lesson)
        } label: {
            HStack(alignment: .center, spacing: Theme.Space.regular) {
                Text(settings.localized(lesson.title))
                    .font(Theme.strong(18))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                StarsView(record: record, lesson: lesson)
            }
            .padding(.vertical, 10)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .lessonSource(lesson.id)
    }

    // MARK: - Refresh

    private func refreshCalendarDay() {
        calendarDay = AppCalendar.today()
        if todaySession?.plan.day != calendarDay {
            todayPractice = nil
            daySummary = nil
            todaySession = nil
        }
        refreshID = UUID()
    }

    private func refreshTrainingData() {
        guard isTrainingActive else { return }
        let generation = refreshID
        let started = Date.timeIntervalSinceReferenceDate
        // Observation invalidates this snapshot once when an actual input changes.
        // It does not enumerate candidates to manufacture a task identifier on each render.
        let snapshot = withObservationTracking {
            makeTrainingData()
        } onChange: {
            Task { @MainActor in
                guard isTrainingActive, refreshID == generation else { return }
                refreshID = UUID()
            }
        }
        data = snapshot
        chooseAfterMeLesson()
        saveMix(snapshot.mixLessons.map(\.id))
        #if DEBUG
        print(String(format: "[TrainingOpen] data refresh %.1f ms", (Date.timeIntervalSinceReferenceDate - started) * 1000))
        #endif
    }

    private func makeTrainingData() -> TrainingData {
        let records = progress.records
        let lessons = progression.catalog.lessons
        let padCount = midi.activeProfile.padCount
        // Neither Mix nor After me can offer an unplayed lesson. Avoid expensive
        // progression checks for the rest of the catalogue, especially on first launch.
        let practiced = lessons.filter { lesson in
            guard let record = records[lesson.id] else { return false }
            return record.passed || record.mastery || record.memory
        }
        let openIDs = Set(practiced.filter { store.isUnlocked($0) && progression.isLessonOpen($0) }.map(\.id))

        let playableLessons = practiced.filter { lesson in
            openIDs.contains(lesson.id) && (padCount == 16 || EightPadLayout.slots(for: lesson) != nil)
        }
        let playableIDs = Set(playableLessons.map(\.id))
        let playableRecords = records.filter { playableIDs.contains($0.key) }

        let candidates = TrainingMix.candidates(lessons: lessons, progress: records,
            padCount: padCount, openLessonIDs: openIDs)
        let mix = TrainingMix.dailySelection(lessons: lessons, progress: records,
            padCount: padCount, openLessonIDs: openIDs, day: today, savedJSON: dailyMixes)

        let dueCandidates = progress.dueLessonIds(today: today).compactMap { lessonStore.lesson(for: $0) }.filter {
            playableIDs.contains($0.id)
        }
        let due = ReviewQueue.order(dueCandidates, records: records, today: today)

        var tomorrowCandidates: [Lesson] = []
        var in2to3Candidates: [Lesson] = []
        var in4to7Candidates: [Lesson] = []
        var laterCandidates: [Lesson] = []
        var settledCandidates: [Lesson] = []

        for lesson in playableLessons {
            guard let record = records[lesson.id] else { continue }
            if record.settled == true || record.reviewSchedule.isSettled {
                settledCandidates.append(lesson)
            } else if record.lastReviewFailDay == today {
                // Open failure today stays in the due list; never in tomorrowCandidates.
            } else if let dueDay = record.reviewDueDay, dueDay > today {
                let offset = AppCalendar.daysBetween(today, dueDay) ?? 0
                if offset == 1 {
                    tomorrowCandidates.append(lesson)
                } else if offset == 2 || offset == 3 {
                    in2to3Candidates.append(lesson)
                } else if offset >= 4 && offset <= 7 {
                    in4to7Candidates.append(lesson)
                } else if offset > 7 {
                    laterCandidates.append(lesson)
                }
            }
        }

        let waitingTomorrow = ReviewQueue.orderWaiting(tomorrowCandidates, records: records, today: today)
        let waitingIn2to3Days = ReviewQueue.orderWaiting(in2to3Candidates, records: records, today: today)
        let waitingIn4to7Days = ReviewQueue.orderWaiting(in4to7Candidates, records: records, today: today)
        let waitingLater = ReviewQueue.orderWaiting(laterCandidates, records: records, today: today)

        let settledLessons = settledCandidates.sorted {
            let t1 = settings.localized($0.title)
            let t2 = settings.localized($1.title)
            let cmp = t1.localizedCaseInsensitiveCompare(t2)
            return cmp != .orderedSame ? cmp == .orderedAscending : $0.id < $1.id
        }

        let dailyLessons = progression.dailyLessons(isAvailable: store.isUnlocked)
        let plan = TodayPlan.decode(savedTodayPlan, today: today) ?? TodayPlan.make(
            day: today, dueLessonIDs: due.map(\.id), nextLessonID: dailyLessons.next?.id,
            followUpLessonID: dailyLessons.followUp?.id, mixLessonIDs: mix.map(\.id))
        let afterMe = playableLessons.sorted {
            let leftMemory = records[$0.id]?.memory == true
            let rightMemory = records[$1.id]?.memory == true
            return leftMemory != rightMemory ? !leftMemory : $0.id < $1.id
        }
        var counts = [0, 0, 0, 0, 0]
        for record in records.values {
            if record.settled == true { counts[4] += 1 }
            else if record.mastery {
                let step = record.reviewStep ?? 0
                if (0...3).contains(step) { counts[step] += 1 }
            }
        }

        let nearestDueDay = playableRecords.values
            .filter { !$0.reviewSchedule.isSettled }
            .compactMap(\.reviewDueDay)
            .filter { $0 > today }
            .min()

        return TrainingData(
            dueLessons: due,
            nextLesson: dailyLessons.next,
            followUpLesson: dailyLessons.followUp,
            currentPlan: plan?.reconcilingReviews(with: records),
            mixCandidates: candidates,
            openLessonIDs: openIDs,
            mixLessons: mix,
            afterMeCandidates: afterMe,
            memoryCounts: counts,
            forecast: ReviewForecast.dueCounts(playableRecords, from: today, days: 7).map { ($0.day, $0.count) },
            hasMasteredLesson: progress.hasAnyMasteredLesson,
            nearestDueDay: nearestDueDay,
            waitingTomorrow: waitingTomorrow,
            waitingIn2to3Days: waitingIn2to3Days,
            waitingIn4to7Days: waitingIn4to7Days,
            waitingLater: waitingLater,
            settledLessons: settledLessons
        )
    }

    private func updateMix(_ ids: [Int]) {
        guard var snapshot = data else { return }
        let byID = Dictionary(uniqueKeysWithValues: snapshot.mixCandidates.map { ($0.id, $0) })
        snapshot.mixLessons = ids.compactMap { byID[$0] }
        snapshot.currentPlan = TodayPlan.decode(savedTodayPlan, today: today)?.reconcilingReviews(with: progress.records)
            ?? TodayPlan.make(day: today, dueLessonIDs: snapshot.dueLessons.map(\.id),
                              nextLessonID: snapshot.nextLesson?.id, followUpLessonID: snapshot.followUpLesson?.id,
                              mixLessonIDs: snapshot.mixLessons.map(\.id))
        data = snapshot
    }

    private func saveMix(_ ids: [Int]) {
        var saved = (try? JSONDecoder().decode([String: [Int]].self, from: Data(dailyMixes.utf8))) ?? [:]
        saved = saved.filter { $0.key.hasPrefix(today + ":") }
        saved["\(today):\(midi.activeProfile.padCount)"] = ids
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        if let encoded = try? encoder.encode(saved), let json = String(data: encoded, encoding: .utf8),
           json != dailyMixes {
            dailyMixes = json
        }
        loadedDailyMixes = dailyMixes
    }

    // MARK: - Helpers

    private func panelHeader(_ title: String) -> some View {
        Text(title.uppercased(with: Locale(identifier: settings.languagePreference.rawValue)))
            .font(Theme.strong(15))
            .foregroundStyle(Theme.ink)
            .accessibilityAddTraits(.isHeader)
    }

    private func formattedDate(from dayString: String) -> String {
        let parts = dayString.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return dayString }
        var components = DateComponents()
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        guard let date = cal.date(from: components) else { return dayString }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: settings.languagePreference.rawValue)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
