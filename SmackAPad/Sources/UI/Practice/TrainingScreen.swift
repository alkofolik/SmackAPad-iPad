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
    @State private var bossPurchaseAccess: String?
    @State private var data: TrainingData?
    @State private var refreshID = UUID()
    @State private var isVisible = false
    @State private var isQueueVisible = false
    @State private var calendarDay = AppCalendar.today()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingQueue = false
    @State private var showingBadges = false
    @State private var todaySession: TodaySessionCoordinator?
    @State private var todayPractice: TodayPracticePresentation?
    @State private var todayPracticeStarted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedQueueStep: Int?
    @State private var expandedWaitingGroup: WaitingGroup?
    @State private var isSettledExpanded = false
    @State private var selectedStageIndex = 0
    @State private var hasInitializedStageSelection = false
    @State private var selectedNodeId: Int?
    @State private var selectedTab: TrainingTabMode = .path
    @State private var showingStudioRig = false
    @State private var studioRigHighlightedKitId: String?
    @State private var selectedBonusTrack: BonusJamTrack?
    @State private var presentedStoryCardStage: DrummerPathStageModel?

    @AppStorage(TodayPlan.storageKey) private var savedTodayPlan = ""
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
        let hasMasteredLesson: Bool
        let nearestDueDay: String?
        let waitingTomorrow: [Lesson]
        let waitingIn2to3Days: [Lesson]
        let waitingIn4to7Days: [Lesson]
        let waitingLater: [Lesson]
        let settledLessons: [Lesson]
        let drummerCard: DrummerCardSnapshot
        let pathStages: [DrummerPathStageModel]
    }

    private enum TodayPracticePresentation {
        case lesson(stepIndex: Int, launch: LessonLaunch)

        var stepID: String {
            switch self {
            case .lesson(let stepIndex, let launch): return "lesson-\(stepIndex)-\(launch.id)"
            }
        }
    }

    private var hasActiveCover: Bool {
        selectedLesson != nil || todayPractice != nil || selectedBonusTrack != nil
    }

    private var continueTarget: TodayContinueTarget? {
        TodayContinueTarget.resolve(
            currentPlan: currentPlan,
            today: today,
            nextLessonID: nextLesson?.id
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
                trainingContent(in: geometry.size)
            }
            .calmChassisBackground()
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingStudioRig) {
                studioRigSheet
            }
            .calmCover(item: $selectedBonusTrack, onDismiss: {
                isVisible = true
                refreshTrainingData()
            }) { track in
                PracticeScreen(
                    lesson: track.asLesson(),
                    settings: settings,
                    progress: progress,
                    midi: midi,
                    unscored: true
                )
            }
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
                if let tab = TrainingTabMode(rawValue: AppNavigation.shared.preferredTrainingTab) {
                    selectedTab = tab
                }
                if data != nil {
                    refreshTrainingData()
                } else {
                    refreshID = UUID()
                }
                TrainingOpenMeasurement.appeared()
            }
            .onChange(of: AppNavigation.shared.preferredTrainingTab) { _, tabName in
                if let tab = TrainingTabMode(rawValue: tabName) {
                    selectedTab = tab
                }
            }
            .onDisappear { isVisible = false }
            .onChange(of: savedTodayPlan) { _, _ in refreshID = UUID() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { refreshCalendarDay() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                refreshCalendarDay()
            }
            .calmCover(item: $todayPractice, onDismiss: dailyPracticeDismissed) { presentation in
                todayPracticeCover(for: presentation)
                    .id(presentation.stepID)
            }
        }
        .environment(\.lessonNamespace, lessonNamespace)
        .practiceLessonPresentation(launch: $selectedLesson, namespace: lessonNamespace)
        .sheet(isPresented: Binding(get: { bossPurchaseAccess != nil }, set: { if !$0 { bossPurchaseAccess = nil } })) {
            PurchaseSheet(access: bossPurchaseAccess ?? "full")
        }
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
        .frame(height: 44)
    }

    // MARK: - Drummer's Path Panels

    @ViewBuilder
    private func trainingContent(in size: CGSize) -> some View {
        let isLandscape = size.width >= 768 && size.width > size.height
        let summaryWidth: CGFloat = min(384, max(320, size.width * 0.32))

        VStack(alignment: .leading, spacing: 12) {
            if let data {
                if settings.playMode == .story {
                    DrummerTopHeaderBar(
                        card: data.drummerCard,
                        availableKeys: progress.drummerPath.availableKeys,
                        selectedTab: $selectedTab,
                        isCompact: !isLandscape,
                        onOpenLibrary: {
                            onHome()
                            AppNavigation.shared.openLibrary(.none)
                        },
                        onBack: onHome
                    )

                    if selectedTab == .studioRig {
                        StudioRigContentView(
                            highlightedKitId: studioRigHighlightedKitId,
                            onOpenKitLessons: { kit in
                                refreshTrainingData()
                                onHome()
                                AppNavigation.shared.openLibrary(.kit(kit.kitId))
                            },
                            onPlayBonusTrack: { track in
                                guard !hasActiveCover else { return }
                                selectedBonusTrack = track
                            },
                            onOpenLibrary: {
                                onHome()
                                AppNavigation.shared.openLibrary(.none)
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if isLandscape {
                        HStack(alignment: .top, spacing: 14) {
                            pathMapPanel(data: data)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                            ScrollView(.vertical, showsIndicators: false) {
                                rightSummaryPanel(data: data)
                            }
                            .frame(maxHeight: .infinity, alignment: .topLeading)
                            .frame(width: summaryWidth)
                        }
                        .frame(maxHeight: .infinity, alignment: .top)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                pathMapPanel(data: data)
                                rightSummaryPanel(data: data)
                                Spacer(minLength: Theme.Space.regular)
                            }
                        }
                    }
                } else {
                    header
                    if selectedTab == .studioRig {
                        StudioRigContentView(
                            highlightedKitId: studioRigHighlightedKitId,
                            onOpenKitLessons: { kit in
                                refreshTrainingData()
                                onHome()
                                AppNavigation.shared.openLibrary(.kit(kit.kitId))
                            },
                            onPlayBonusTrack: { track in
                                guard !hasActiveCover else { return }
                                selectedBonusTrack = track
                            },
                            onOpenLibrary: {
                                onHome()
                                AppNavigation.shared.openLibrary(.none)
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: Theme.Space.page) {
                                compactTodayBlock
                                dueNowPanel
                                waitingPanel
                                settledPanel
                                compactToolsFooter
                                Spacer(minLength: Theme.Space.regular)
                            }
                        }
                    }
                }
            } else {
                header
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel(settings.localized("Training"))
            }
        }
        .padding(.horizontal, isLandscape ? Theme.Space.page : Theme.Space.regular)
        .padding(.vertical, Theme.Space.regular)
        .frame(maxWidth: 1320, maxHeight: .infinity, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.chassis.ignoresSafeArea())
        .onChange(of: progress.drummerPath.unlockedKitIds) { _, _ in
            refreshTrainingData()
        }
        .onChange(of: selectedTab) { _, tab in
            AppNavigation.shared.preferredTrainingTab = tab.rawValue
        }
    }

    private var studioRigSheet: some View {
        StudioRigQuickSheet(
            highlightedKitId: studioRigHighlightedKitId,
            onOpenKitLessons: { kit in
                refreshTrainingData()
                onHome()
                AppNavigation.shared.openLibrary(.kit(kit.kitId))
            },
            onPlayBonusTrack: { track in
                guard !hasActiveCover else { return }
                selectedBonusTrack = track
            },
            onOpenLibrary: {
                onHome()
                AppNavigation.shared.openLibrary(.none)
            }
        )
    }

    private func pathMapPanel(data: TrainingData) -> some View {
        DrummerPathMapView(
            stages: data.pathStages,
            selectedStageIndex: $selectedStageIndex,
            selectedNodeId: $selectedNodeId,
            availableKeys: progress.drummerPath.availableKeys,
            onPlayLesson: { lesson in
                guard !hasActiveCover else { return }
                preserveTodayPlan(for: lesson.id)
                selectedLesson = LessonLaunch.library(lesson, progress: progress.progress(for: lesson.id), today: today)
            },
            onUnlockKit: { kit in
                if progress.drummerPath.availableKeys >= kit.unlockCost {
                    let result = progress.unlockKit(kit.kitId)
                    if case .unlocked = result {
                        refreshTrainingData()
                        return
                    }
                }
                studioRigHighlightedKitId = kit.kitId
                selectedTab = .studioRig
            },
            onOpenStoryCard: { stage in
                presentedStoryCardStage = stage
            }
        )
        .onChange(of: selectedStageIndex) { _, _ in
            presentStoryCardIfNeeded(stages: data.pathStages)
        }
        .onChange(of: data.pathStages.count) { _, _ in
            presentStoryCardIfNeeded(stages: data.pathStages)
        }
        .onAppear {
            presentStoryCardIfNeeded(stages: data.pathStages)
        }
        .sheet(item: $presentedStoryCardStage) { stage in
            StoryStageCardView(stage: stage) {
                progress.markStoryCardSeen(stageId: stage.id)
                presentedStoryCardStage = nil
            }
        }
    }

    private func presentStoryCardIfNeeded(stages: [DrummerPathStageModel]) {
        guard settings.playMode == .story,
              presentedStoryCardStage == nil,
              !hasActiveCover,
              stages.indices.contains(selectedStageIndex)
        else { return }
        let stage = stages[selectedStageIndex]
        guard stage.id != DrummerPathEvaluator.introExamStageId,
              stage.isStageOpen,
              !progress.drummerPath.seenStoryCardStageIDs.contains(stage.id)
        else { return }
        presentedStoryCardStage = stage
    }

    private func rightSummaryPanel(data: TrainingData) -> some View {
        let stage: DrummerPathStageModel? = data.pathStages.isEmpty
            ? nil
            : data.pathStages[min(max(0, selectedStageIndex), data.pathStages.count - 1)]
        let focused = stage.flatMap { DrummerPathMapView.resolveFocusedNode(in: $0, selectedNodeId: selectedNodeId) }

        return VStack(alignment: .leading, spacing: 12) {
            DrummerModuleInspectorCard(
                stage: stage,
                node: focused,
                availableKeys: progress.drummerPath.availableKeys,
                onPlayLesson: { lesson in
                    guard !hasActiveCover else { return }
                    preserveTodayPlan(for: lesson.id)
                    selectedLesson = LessonLaunch.library(lesson, progress: progress.progress(for: lesson.id), today: today)
                },
                onPlayBoss: { encounter in
                    guard !hasActiveCover else { return }
                    guard store.isUnlocked(encounter.lesson) else {
                        bossPurchaseAccess = encounter.lesson.access ?? "full"
                        return
                    }
                    preserveTodayPlan(for: encounter.lesson.id)
                    selectedLesson = .boss(encounter)
                },
                onUnlockKit: { kit in
                    if progress.drummerPath.availableKeys >= kit.unlockCost {
                        let result = progress.unlockKit(kit.kitId)
                        if case .unlocked = result {
                            refreshTrainingData()
                            return
                        }
                    }
                    studioRigHighlightedKitId = kit.kitId
                    selectedTab = .studioRig
                }
            )

            DrummerAttributesCard(card: data.drummerCard)

            compactTodayBlock
            compactToolsFooter
        }
    }

    private var compactTodayBlock: some View {
        let target = continueTarget
        let steps = target?.plan.steps ?? []
        let currentIndex = target?.plan.index ?? 0
        let hasPlayableStep: Bool = if case .step = target { true } else { false }
        let buttonTitle: String = switch target {
        case .summary: "Done"
        case .step(let plan) where plan.index > 0: "Continue"
        default: "Start"
        }

        return VStack(alignment: .leading, spacing: Theme.Space.small) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(settings.localized("Today"))
                        .font(Theme.sectionTitle)
                        .foregroundStyle(Theme.black)
                        .accessibilityAddTraits(.isHeader)
                    Text(continueSubtitle(for: target))
                        .font(Theme.caption.monospacedDigit())
                        .foregroundStyle(Theme.black.opacity(0.75))
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Button(action: startTodayTraining) {
                    Text(settings.localized(buttonTitle))
                        .font(Theme.action)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 44)
                }
                .buttonStyle(PadPrimaryButtonStyle(darkFace: true))
                .disabled(!hasPlayableStep)
            }

            if !steps.isEmpty {
                VStack(spacing: 4) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        let isDone = index < currentIndex || step.outcome?.played == true
                        let isCurrent = !isDone && index == currentIndex
                        HStack(spacing: 8) {
                            Image(systemName: isDone ? (step.markerSymbol ?? "checkmark.circle.fill") : (isCurrent ? "play.fill" : "circle"))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.black.opacity(isDone || isCurrent ? 0.95 : 0.45))
                            Text(stepTitle(step))
                                .font(Theme.caption.weight(isCurrent ? .semibold : .regular))
                                .foregroundStyle(Theme.black)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            Text(stepTag(step))
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.black.opacity(0.65))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            (isCurrent ? Theme.white : Theme.white.opacity(isDone ? 0.65 : 0.35)),
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                    }
                }
            }
        }
        .padding(Theme.Space.controlGap)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.orange, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
    }

    private var compactToolsFooter: some View {
        HStack(spacing: Theme.Space.small) {
            Button {
                showingQueue = true
            } label: {
                HStack(spacing: 6) {
                    Text(settings.localized("Review queue"))
                        .font(Theme.caption.weight(.medium))
                    Text("\(queuedLessons.count)")
                        .font(Theme.caption.monospacedDigit())
                        .foregroundStyle(Theme.secondary)
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 38)
            }
            .buttonStyle(PadSecondaryButtonStyle())

            Button {
                showingBadges = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "rosette")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.orange)
                    Text(settings.localized("Training badges"))
                        .font(Theme.caption.weight(.medium))
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 38)
            }
            .buttonStyle(PadSecondaryButtonStyle())
        }
    }

    // MARK: - 1. Today Steps

    private func stepTitle(_ step: TodayPlan.Step) -> String {
        step.lessonIDs.first.flatMap { lessonStore.lesson(for: $0) }
            .map { settings.localized($0.title) } ?? "—"
    }

    private func stepTag(_ step: TodayPlan.Step) -> String {
        switch step.kind {
        case .review: return settings.localized("Review")
        case .newLesson: return settings.localized("New lesson")
        case .mix: return settings.localized("Review")
        }
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
        }
    }

    private func canOpenDailyStep(_ step: TodayPlan.Step) -> Bool {
        guard step.kind != .mix else { return false }
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

    private func openDailyStep() {
        guard let session = todaySession, session.plan.day == AppCalendar.today() else { return }
        while true {
            guard case .step(let plan) = session.nextAction else {
                todayPracticeStarted = false
                todayPractice = nil
                return
            }
            let stepIndex = plan.index
            let step = plan.steps[stepIndex]
            let lessons = step.lessonIDs.compactMap { lessonStore.lesson(for: $0) }
            guard canOpenDailyStep(step), let lesson = lessons.first else {
                session.skip(progress: progress)
                continue
            }
            session.continueSession()
            todayPracticeStarted = true
            todayPractice = .lesson(
                stepIndex: stepIndex,
                launch: step.kind == .review ? .review(lesson) : .lesson(lesson)
            )
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
        openDailyStep()
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
    }

    // MARK: - 2. Due Now

    private func queueLessons(forStep step: Int?) -> [Lesson] {
        let matching = step == nil ? queuedLessons : queuedLessons.filter {
            (progress.progress(for: $0.id)?.reviewStep ?? 0) == step
        }
        return ReviewQueue.displayOrder(matching)
    }

    private var dueNowPanel: some View {
        let nonEmptySteps = (0..<4).filter { !queueLessons(forStep: $0).isEmpty }
        let activeStep: Int? = {
            if let selectedQueueStep, nonEmptySteps.contains(selectedQueueStep) {
                return selectedQueueStep
            }
            return nil
        }()
        let displayedLessons = queueLessons(forStep: activeStep)
        let stepTitles = [
            settings.localized("Step 1"),
            settings.localized("Step 2"),
            settings.localized("Step 3"),
            settings.localized("Step 4")
        ]

        return VStack(alignment: .leading, spacing: Theme.Space.controlGap) {
            HardwareSectionHeader(
                title: settings.localized("%lld in queue · take these at your own pace", queuedLessons.count)
            )

            if data?.hasMasteredLesson != true {
                HardwareCard(padding: Theme.Space.regular) {
                    emptyCardText(settings.localized("Reviews start once a lesson has two stars."))
                }
            } else if queuedLessons.isEmpty && !dueLessons.isEmpty {
                HardwareCard(padding: Theme.Space.regular) {
                    emptyCardText(settings.localized("Today's reviews are in the plan above. Nothing else is waiting in the queue."))
                }
            } else if queuedLessons.isEmpty {
                let nextDateFormatted: String = {
                    if let nearest = data?.nearestDueDay {
                        return formattedDate(from: nearest)
                    } else {
                        return "—"
                    }
                }()
                HardwareCard(padding: Theme.Space.regular) {
                    emptyCardText(settings.localized("Nothing to review today. Next: %@", nextDateFormatted))
                }
            } else {
                if nonEmptySteps.count > 1 {
                    let options: [(Int?, String)] = [(nil, "\(settings.localized("All")) (\(queuedLessons.count))")]
                        + nonEmptySteps.map { step in
                            (step, "\(stepTitles[step]) (\(queueLessons(forStep: step).count))")
                        }
                    PlexSegmentedPicker(
                        title: settings.localized("Review queue"),
                        selection: Binding(
                            get: { activeStep },
                            set: { selectedQueueStep = $0 }
                        ),
                        options: options,
                        size: .compact
                    )
                }

                HardwareCard {
                    ForEach(Array(displayedLessons.enumerated()), id: \.element.id) { index, lesson in
                        if index > 0 {
                            HardwareDivider(inset: Theme.Space.regular)
                        }
                        dueLessonRow(lesson)
                            .padding(.horizontal, Theme.Space.regular)
                    }
                }
            }
        }
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
                    .font(Theme.caption.monospacedDigit())
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.recessed, in: RoundedRectangle(cornerRadius: Theme.Radius.control))
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.control)
                            .strokeBorder(Theme.hairline, lineWidth: 1)
                    }

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
            VStack(alignment: .leading, spacing: Theme.Space.controlGap) {
                HardwareSectionHeader(title: settings.localized("Waiting"))

                FlowLayout(spacing: Theme.Space.small) {
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
                        HardwareCard {
                            ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                                if index > 0 {
                                    HardwareDivider(inset: Theme.Space.regular)
                                }
                                waitingLessonRow(lesson)
                                    .padding(.horizontal, Theme.Space.regular)
                            }
                        }
                    }
                }
            }
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
                    .font(Theme.caption.monospacedDigit())
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.recessed, in: RoundedRectangle(cornerRadius: Theme.Radius.control))
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.control)
                            .strokeBorder(Theme.hairline, lineWidth: 1)
                    }

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

    // MARK: - 4. Queue Screen

    private var reviewQueueDestination: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.page) {
                HStack(spacing: Theme.Space.regular) {
                    BackButton {
                        showingQueue = false
                    }

                    Text(settings.localized("Review queue"))
                        .font(Theme.screenTitle)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .accessibilityAddTraits(.isHeader)

                    Spacer()
                }
                .frame(minHeight: Theme.Size.touch)

                dueNowPanel

                waitingPanel

                settledPanel

                Spacer(minLength: Theme.Space.page)
            }
            .padding(Theme.Space.page)
            .frame(maxWidth: 1240, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.chassis.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            isQueueVisible = true
            refreshTrainingData()
        }
        .onDisappear { isQueueVisible = false }
    }

    // MARK: - 5. Settled

    @ViewBuilder
    private var settledPanel: some View {
        let settled = data?.settledLessons ?? []
        if !settled.isEmpty {
            HardwareCard {
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                        isSettledExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(settings.localized("Settled (%lld)", settled.count))
                            .font(Theme.strong(16))
                            .foregroundStyle(Theme.ink)

                        Spacer()

                        Image(systemName: isSettledExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(isSettledExpanded ? Theme.orange : Theme.secondary)
                    }
                    .padding(.horizontal, Theme.Space.regular)
                    .frame(minHeight: Theme.Size.row)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSettledExpanded ? [.isSelected] : [])

                if isSettledExpanded {
                    ForEach(settled) { lesson in
                        HardwareDivider(inset: Theme.Space.regular)
                        settledLessonRow(lesson)
                            .padding(.horizontal, Theme.Space.regular)
                    }
                }
            }
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
        if !hasInitializedStageSelection {
            hasInitializedStageSelection = true
            if let firstActiveStage = snapshot.pathStages.first(where: { $0.activeNode != nil }) {
                selectedStageIndex = firstActiveStage.index
            }
        }
        #if DEBUG
        print(String(format: "[TrainingOpen] data refresh %.1f ms", (Date.timeIntervalSinceReferenceDate - started) * 1000))
        #endif
    }

    private func makeTrainingData() -> TrainingData {
        let records = progress.records
        let lessons = progression.catalog.lessons
        let padCount = midi.activeProfile.padCount
        let practiced = lessons.filter { lesson in
            guard let record = records[lesson.id] else { return false }
            return record.passed || record.mastery || record.memory
        }
        let isAvailableForToday: (Lesson) -> Bool = { lesson in
            store.isUnlocked(lesson)
        }
        let openIDs = Set(practiced.filter { isAvailableForToday($0) && progression.isLessonOpen($0) }.map(\.id))

        let playableLessons = practiced.filter { lesson in
            openIDs.contains(lesson.id) && (padCount == 16 || EightPadLayout.slots(for: lesson) != nil)
        }
        let playableIDs = Set(playableLessons.map(\.id))
        let playableRecords = records.filter { playableIDs.contains($0.key) }

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

        let dailyLessons = progression.dailyLessons(isAvailable: isAvailableForToday)
        let cachedPlan = TodayPlan.decode(savedTodayPlan, today: today)
        let plan = cachedPlan ?? TodayPlan.make(
            day: today, dueLessonIDs: due.map(\.id), nextLessonID: dailyLessons.next?.id,
            followUpLessonID: dailyLessons.followUp?.id)

        let nearestDueDay = playableRecords.values
            .filter { !$0.reviewSchedule.isSettled }
            .compactMap(\.reviewDueDay)
            .filter { $0 > today }
            .min()

        let drummerCard = progress.drummerCard(catalog: progression.catalog)
        let pathStages = DrummerPathMapBuilder.buildStages(
            catalog: progression.catalog,
            progress: records,
            pathState: progress.drummerPath,
            language: settings.languagePreference,
            openStageIDs: progression.storyOpenStageIDs
        )

        return TrainingData(
            dueLessons: due,
            nextLesson: dailyLessons.next,
            followUpLesson: dailyLessons.followUp,
            currentPlan: plan?.reconcilingReviews(with: records),
            hasMasteredLesson: progress.hasAnyMasteredLesson,
            nearestDueDay: nearestDueDay,
            waitingTomorrow: waitingTomorrow,
            waitingIn2to3Days: waitingIn2to3Days,
            waitingIn4to7Days: waitingIn4to7Days,
            waitingLater: waitingLater,
            settledLessons: settledLessons,
            drummerCard: drummerCard,
            pathStages: pathStages
        )
    }

    // MARK: - Helpers

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

private enum DayDateFormatter {
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
