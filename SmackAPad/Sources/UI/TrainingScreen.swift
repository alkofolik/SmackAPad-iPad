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
    @State private var playingMix: [Lesson] = []
    @State private var showingMix = false
    @State private var mixFromMemory = false
    @State private var showingQueue = false
    @State private var isMemoryExpanded = false
    @State private var showingBadges = false
    @State private var showingToday = false
    @State private var activeTodayPlan: TodayPlan?
    @State private var isDueExpanded = false
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

    private enum DueStepFilter: String, CaseIterable, Identifiable {
        case all = "all"
        case step1 = "step1"
        case step2 = "step2"
        case step3 = "step3"
        case step4 = "step4"

        var id: String { rawValue }

        var stepIndex: Int? {
            switch self {
            case .all: return nil
            case .step1: return 0
            case .step2: return 1
            case .step3: return 2
            case .step4: return 3
            }
        }

        func title(settings: SettingsManager) -> String {
            switch self {
            case .all: return settings.localized("All")
            case .step1: return settings.localized("Step 1")
            case .step2: return settings.localized("Step 2")
            case .step3: return settings.localized("Step 3")
            case .step4: return settings.localized("Step 4")
            }
        }
    }

    public init(onHome: @escaping () -> Void = {}) {
        self.onHome = onHome
    }

    /// Derived data is built once per input change, never while evaluating the view tree.
    private struct TrainingData {
        let dueLessons: [Lesson]
        let nextLesson: Lesson?
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

    private var isTrainingActive: Bool { isVisible || isQueueVisible }
    private var today: String { calendarDay }
    private var dueLessons: [Lesson] { data?.dueLessons ?? [] }
    private var nextLesson: Lesson? { data?.nextLesson }
    private var currentPlan: TodayPlan? { data?.currentPlan }
    private var isPlanFinished: Bool { currentPlan?.finished == true }
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
                            todayPanel(isLandscape: isLandscape)

                            if isLandscape {
                                Grid(alignment: .topLeading, horizontalSpacing: 24, verticalSpacing: 24) {
                                    GridRow {
                                        extraMixCard
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                        afterMeCard
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    }
                                }
                            } else {
                                extraMixCard
                                afterMeCard
                            }

                            VStack(spacing: 8) {
                                reviewQueueRow
                                memoryAndForecastRow
                                if isMemoryExpanded {
                                    if isLandscape {
                                        HStack(alignment: .top, spacing: Theme.Space.page) {
                                            memoryMeterPanel
                                                .frame(maxWidth: .infinity)
                                            next7DaysPanel
                                                .frame(maxWidth: .infinity)
                                        }
                                        .padding(.top, 8)
                                    } else {
                                        memoryMeterPanel
                                            .padding(.top, 8)
                                        next7DaysPanel
                                    }
                                }
                                trainingBadgesRow
                            }
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
            .fullScreenCover(item: $selectedAfterMeLesson) { lesson in
                PracticeLessonDestination(launch: .afterMe(lesson))
            }
            .fullScreenCover(isPresented: $showingMix) {
                if !playingMix.isEmpty {
                    MixFlowScreen(
                        lessons: $playingMix,
                        fromMemory: $mixFromMemory,
                        onAnotherMix: {
                            refreshMix(newDraw: true)
                            playingMix = mixLessons
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $showingToday, onDismiss: {
                refreshTrainingData()
            }) {
                if let plan = activeTodayPlan {
                    TodaySessionScreen(plan: plan) { showingToday = false }
                }
            }
        }
        .environment(\.lessonNamespace, lessonNamespace)
        .practiceLessonPresentation(launch: $selectedLesson, namespace: lessonNamespace)
        .onChange(of: selectedLesson?.id) { _, id in
            if id == nil {
                refreshTrainingData()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            BackButton(action: onHome)

            Text(settings.localized("Training"))
                .font(Theme.boldDisplay(28))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)

            Spacer(minLength: 16)

            Text(DayDateFormatter.format(today, language: settings.languagePreference))
                .font(Theme.text(15))
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
        }
        .frame(height: 56)
    }

    // MARK: - 1. Today Panel

    private enum StepCardVisualState {
        case current
        case done(exclamation: Bool)
        case upcoming
        case optional
    }

    private var effectiveNextStep: TodayPlan.Step? {
        guard let plan = currentPlan, !plan.finished else { return nil }
        let candidates = plan.steps.dropFirst(plan.index)
        return candidates.first { step in
            if step.kind == .review, step.outcome?.hasDecidedReview == true { return false }
            if step.outcome?.played == true { return false }
            return true
        }
    }

    private var effectiveCurrentKind: TodayPlan.Step.Kind? {
        if isPlanFinished { return nil }
        if let step = effectiveNextStep { return step.kind }
        if currentPlan == nil {
            if !reviewLoad.todayIDs.isEmpty { return .review }
            if nextLesson != nil { return .newLesson }
            if mixLessons.count >= LearningRules.minimumMixLessons { return .mix }
        }
        return nil
    }

    @ViewBuilder
    private func todayPanel(isLandscape: Bool) -> some View {
        let isEmptyFirstRun = data?.hasMasteredLesson != true
            && dueLessons.isEmpty
            && currentPlan?.steps.contains(where: { $0.outcome?.played == true }) != true
            && currentPlan?.finished != true

        VStack(alignment: .leading, spacing: 18) {
            Text(settings.localized("Today").uppercased(with: Locale(identifier: settings.languagePreference.rawValue)))
                .font(Theme.padTitle(size: 40))
                .foregroundStyle(Theme.black)
                .accessibilityAddTraits(.isHeader)

            if isEmptyFirstRun {
                emptyFirstRunBlock
            } else if isLandscape {
                Grid(alignment: .topLeading, horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        reviewStepCard
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        newLessonStepCard
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        mixStepCard
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        continueButton
                            .frame(width: 200)
                            .frame(maxHeight: .infinity)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Grid(alignment: .topLeading, horizontalSpacing: 12, verticalSpacing: 12) {
                        GridRow {
                            reviewStepCard
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            newLessonStepCard
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                        GridRow {
                            mixStepCard
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .gridCellColumns(2)
                        }
                    }

                    continueButton
                        .frame(maxWidth: .infinity, minHeight: 68)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.orange, in: RoundedRectangle(cornerRadius: 24))
    }

    private var emptyFirstRunBlock: some View {
        Button {
            if let nextLesson { selectedLesson = .lesson(nextLesson) }
        } label: {
            HStack(spacing: Theme.Space.regular) {
                VStack(alignment: .leading, spacing: Theme.Space.tight) {
                    Text(settings.localized("Learn your first lesson"))
                        .font(Theme.strong(22))
                        .foregroundStyle(Theme.black)
                    if let next = nextLesson {
                        Text(settings.localized(next.title))
                            .font(Theme.text(15))
                            .foregroundStyle(Theme.black.opacity(0.75))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(Theme.strong(18))
                    .foregroundStyle(Theme.black)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .background(Theme.white, in: RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .lessonSource(nextLesson?.id ?? 0)
    }

    private var reviewStepCard: some View {
        let count = reviewLoad.todayIDs.count
        let summary = currentPlan?.reviewSummary ?? TodayPlan.ReviewSummary(notPlayed: count)
        let isCurrent = effectiveCurrentKind == .review
        let isDone = count > 0 && summary.played == count && !isCurrent

        let visualState: StepCardVisualState = {
            if isCurrent { return .current }
            if isDone { return .done(exclamation: summary.didNotCount > 0) }
            return .upcoming
        }()

        let title = count > 0
            ? settings.languagePreference.localizedLessonCount(count)
            : settings.localized("training.noReviews")

        let subtitle = reviewStatusDetail(count: count, summary: summary)

        return stepCardView(
            tag: settings.localized("1 · REVIEWS"),
            title: title,
            subtitle: subtitle,
            visualState: visualState
        )
    }

    private var newLessonStepCard: some View {
        let planLessonID = currentPlan?.steps.first(where: { $0.kind == .newLesson })?.lessonIDs.first
        let lesson = planLessonID.flatMap { lessonStore.lesson(for: $0) } ?? nextLesson
        let savedStep = currentPlan?.steps.first(where: { $0.kind == .newLesson })
        let isCurrent = effectiveCurrentKind == .newLesson
        let isDone = savedStep?.status == .passed || savedStep?.status == .played

        let visualState: StepCardVisualState = {
            if isCurrent { return .current }
            if isDone { return .done(exclamation: false) }
            return .upcoming
        }()

        let title = lesson.map { settings.localized($0.title) } ?? settings.localized("All lessons completed")
        let subtitle: String = {
            guard let lesson else { return "" }
            return lesson.bars > 1
                ? settings.localized("%lld bars · %lld BPM", lesson.bars, lesson.targetBpm)
                : settings.localized("1 bar · %lld BPM", lesson.targetBpm)
        }()

        return stepCardView(
            tag: settings.localized("2 · NEW LESSON"),
            title: title,
            subtitle: subtitle,
            visualState: visualState
        )
    }

    private var mixStepCard: some View {
        let savedStep = currentPlan?.steps.first(where: { $0.kind == .mix })
        let count = savedStep?.lessonIDs.count ?? mixLessons.count
        let hasMix = count >= LearningRules.minimumMixLessons
        let isCurrent = effectiveCurrentKind == .mix
        let isDone = savedStep?.status == .passed || savedStep?.status == .played

        let visualState: StepCardVisualState = {
            if isCurrent { return .current }
            if isDone { return .done(exclamation: false) }
            return .optional
        }()

        let title = hasMix
            ? settings.languagePreference.localizedLessonCount(count)
            : settings.localized("Mix")
        let subtitle = hasMix
            ? settings.localized("each once")
            : settings.localized("Mix needs two lessons with two stars.")

        return stepCardView(
            tag: settings.localized("3 · MIX · OPTIONAL"),
            title: title,
            subtitle: subtitle,
            visualState: visualState
        )
    }

    private func stepCardView(
        tag: String,
        title: String,
        subtitle: String,
        visualState: StepCardVisualState
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14)

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(tag)
                    .font(Theme.strong(12))
                    .tracking(0.4)
                    .foregroundStyle(Theme.black.opacity(0.65))
                    .lineLimit(1)

                Spacer(minLength: 4)

                switch visualState {
                case .current:
                    Text(settings.localized("training.now"))
                        .font(Theme.strong(12))
                        .foregroundStyle(Theme.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Theme.orange.opacity(0.24), in: Capsule())
                case .done(let exclamation):
                    Image(systemName: exclamation ? "exclamationmark.circle" : "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.black)
                case .upcoming, .optional:
                    EmptyView()
                }
            }

            Text(title)
                .font(Theme.boldDisplay(22))
                .foregroundStyle(Theme.black)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(Theme.text(13))
                    .foregroundStyle(Theme.black.opacity(0.68))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            if case .optional = visualState {
                shape.fill(Theme.white.opacity(0.35))
            } else {
                shape.fill(Theme.white)
            }
        }
        .overlay {
            switch visualState {
            case .current:
                shape.strokeBorder(Theme.black, lineWidth: 3)
            case .optional:
                shape.strokeBorder(Theme.black.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            case .done, .upcoming:
                EmptyView()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(tag), \(title), \(subtitle)")
    }

    private var continueButton: some View {
        let isFinished = isPlanFinished
        let canLaunch = isFinished || currentPlan != nil || nextLesson != nil || mixLessons.count >= LearningRules.minimumMixLessons

        return Button {
            startTodayTraining()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(settings.localized(isFinished ? "Summary" : "Continue"))
                    .font(Theme.boldDisplay(22))
                    .foregroundStyle(Theme.white)
                    .lineLimit(1)

                Text(continueSubtitle)
                    .font(Theme.text(13))
                    .foregroundStyle(Theme.white.opacity(0.68))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .buttonStyle(TrainingActionButtonStyle(variant: .dark))
        .disabled(!canLaunch)
    }

    private var continueSubtitle: String {
        if isPlanFinished {
            return settings.localized("training.doneForToday")
        }
        if let step = effectiveNextStep {
            if step.kind == .mix {
                return "\(settings.localized("Mix")) · \(settings.languagePreference.localizedLessonCount(step.lessonIDs.count))"
            }
            if let id = step.lessonIDs.first, let lesson = lessonStore.lesson(for: id) {
                return settings.localized(lesson.title)
            }
        }
        if let next = nextLesson {
            return settings.localized(next.title)
        }
        if mixLessons.count >= LearningRules.minimumMixLessons {
            return "\(settings.localized("Mix")) · \(settings.languagePreference.localizedLessonCount(mixLessons.count))"
        }
        return ""
    }

    private func reviewStatusDetail(count: Int, summary: TodayPlan.ReviewSummary) -> String {
        guard count > 0 else {
            return settings.localized("training.nothingDue")
        }
        if summary.played == 0 {
            return isPlanFinished
                ? settings.localized("Not played")
                : settings.localized("training.fromMemoryGoalTempo")
        }
        var parts: [String] = []
        if summary.passed > 0 {
            parts.append(localizedPlural(
                summary.passed,
                one: "training.reviewPassed.one",
                few: "training.reviewPassed.few",
                many: "training.reviewPassed.many"
            ))
        }
        if summary.didNotCount > 0 {
            parts.append(localizedPlural(
                summary.didNotCount,
                one: "training.reviewTomorrow.one",
                few: "training.reviewTomorrow.many",
                many: "training.reviewTomorrow.many"
            ))
        }
        if summary.notPlayed > 0 && !isPlanFinished {
            parts.append(localizedPlural(
                summary.notPlayed,
                one: "training.reviewLeft.one",
                few: "training.reviewLeft.few",
                many: "training.reviewLeft.many"
            ))
        }
        return parts.joined(separator: " · ")
    }

    private func localizedPlural(_ count: Int, one: String, few: String, many: String) -> String {
        if count == 1 {
            return settings.localized(one)
        }
        if settings.languagePreference == .czech && (2...4).contains(count) {
            return settings.localized(few, count)
        }
        return settings.localized(many, count)
    }

    private func preserveTodayPlan(for lessonID: Int) {
        guard TodayPlan.decode(savedTodayPlan, today: today) == nil,
              let plan = currentPlan,
              plan.steps.contains(where: { $0.kind == .review && $0.lessonIDs.first == lessonID }),
              let json = plan.encoded else { return }
        savedTodayPlan = json
    }

    private func startTodayTraining() {
        if let plan = currentPlan {
            activeTodayPlan = plan
            showingToday = true
            return
        }
        var steps: [TodayPlan.Step] = []
        if let next = nextLesson {
            steps.append(.init(kind: .newLesson, lessonIDs: [next.id]))
        }
        if mixLessons.count >= LearningRules.minimumMixLessons {
            steps.append(.init(kind: .mix, lessonIDs: mixLessons.map(\.id)))
        }
        if !steps.isEmpty {
            let plan = TodayPlan(day: today, steps: steps)
            if let json = plan.encoded {
                savedTodayPlan = json
            }
            activeTodayPlan = plan
            showingToday = true
        }
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
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
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
                    .background(isToday ? Theme.background : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isToday ? Theme.ink : Theme.hairline, lineWidth: isToday ? 2 : 1)
                    )
                    .overlay(alignment: .bottom) {
                        if isToday {
                            HardwareLightBar(active: true, breathes: false)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .contentShape(RoundedRectangle(cornerRadius: 10))

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
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
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

    private var currentStepFilter: DueStepFilter {
        DueStepFilter(rawValue: settings.trainingDueStepFilter) ?? .all
    }

    private var filteredDueLessons: [Lesson] {
        guard let targetIndex = currentStepFilter.stepIndex else {
            return queuedLessons
        }
        return queuedLessons.filter { lesson in
            let record = progress.progress(for: lesson.id)
            let step = record?.reviewStep ?? 0
            return step == targetIndex
        }
    }

    private var stepFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Space.small) {
                ForEach(DueStepFilter.allCases) { filter in
                    let count: Int = {
                        if let targetIndex = filter.stepIndex {
                            return queuedLessons.filter { (progress.progress(for: $0.id)?.reviewStep ?? 0) == targetIndex }.count
                        } else {
                            return queuedLessons.count
                        }
                    }()
                    let isSelected = (currentStepFilter == filter)
                    let isDisabled = (count == 0)

                    FilterChip(title: filter.title(settings: settings), selected: isSelected) {
                        if isSelected && filter != .all {
                            settings.trainingDueStepFilter = DueStepFilter.all.rawValue
                        } else {
                            settings.trainingDueStepFilter = filter.rawValue
                        }
                    }
                    .disabled(isDisabled)
                    .opacity(isDisabled ? 0.35 : 1.0)
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: Theme.Size.touch)
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
                    stepFilterChips
                        .padding(.bottom, Theme.Space.small)

                    let filtered = filteredDueLessons
                    if filtered.isEmpty {
                        emptyCardText(settings.localized("No lessons for this step."))
                    } else {
                        let displayed = isDueExpanded ? filtered : Array(filtered.prefix(5))
                        VStack(spacing: 0) {
                            ForEach(Array(displayed.enumerated()), id: \.element.id) { index, lesson in
                                if index > 0 {
                                    Rectangle()
                                        .fill(Theme.hairline)
                                        .frame(height: 1)
                                }
                                dueLessonRow(lesson)
                            }
                        }

                        if filtered.count > 5 {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isDueExpanded.toggle()
                                }
                            } label: {
                                Text(isDueExpanded
                                    ? settings.localized("Show fewer")
                                    : settings.localized("Show all (%lld)", filtered.count))
                                    .font(Theme.control)
                                    .padding(.horizontal, Theme.Space.regular)
                                    .frame(minHeight: Theme.Size.touch)
                            }
                            .buttonStyle(PadSecondaryButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, Theme.Space.small)
                        }
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

                Text(settings.localized("STEP %lld OF 4", step).uppercased(with: Locale(identifier: settings.languagePreference.rawValue)))
                    .font(Theme.strong(12).monospaced())
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .overlay(Rectangle().stroke(Theme.ink, lineWidth: 2))

                Text(settings.localized("Ready for review"))
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
        let subtext = waitingSubtext(for: record?.reviewDueDay)

        return Button {
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
                    .font(Theme.strong(12).monospaced())
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
                    .textCase(.uppercase)
                    .font(Theme.strong(13))
                    .tracking(0.6)
                    .foregroundStyle(Theme.secondary)
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
                .buttonStyle(TrainingActionButtonStyle(variant: .secondary))
                .disabled(mixLessons.count < LearningRules.minimumMixLessons)

                Button {
                    playingMix = mixLessons
                    showingMix = true
                } label: {
                    Text(settings.localized("Start mix"))
                        .font(Theme.strong(16))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(TrainingActionButtonStyle(variant: .primary))
                .disabled(mixLessons.count < LearningRules.minimumMixLessons)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
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
                .textCase(.uppercase)
                .font(Theme.strong(13))
                .tracking(0.6)
                .foregroundStyle(Theme.secondary)
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
                .buttonStyle(TrainingActionButtonStyle(variant: .secondary))
                .disabled(afterMeCandidates.count < 2)

                Button {
                    if let candidate {
                        selectedAfterMeLesson = candidate
                    }
                } label: {
                    Text(settings.localized("Start"))
                        .font(Theme.strong(16))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(TrainingActionButtonStyle(variant: .primary))
                .disabled(candidate == nil)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        }
    }

    // MARK: - 5. Compact Rows & Queue Screen

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
        let shape = RoundedRectangle(cornerRadius: 14)

        return Button(action: action) {
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
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(Theme.surface, in: shape)
            .overlay {
                shape.strokeBorder(Theme.hairline, lineWidth: 1)
            }
            .contentShape(shape)
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

        let source = NextLessonSource(rawValue: settings.nextLessonSource) ?? .path
        let next = progression.nextLesson(after: lessonStore.lesson(for: settings.lastLessonID), source: source)
            ?? progression.catalog.path.first
        let plan = TodayPlan.decode(savedTodayPlan, today: today) ?? TodayPlan.make(
            day: today, dueLessonIDs: due.map(\.id), nextLessonID: next?.id, mixLessonIDs: mix.map(\.id))
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
            nextLesson: next,
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
                              nextLessonID: snapshot.nextLesson?.id, mixLessonIDs: ids)
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
