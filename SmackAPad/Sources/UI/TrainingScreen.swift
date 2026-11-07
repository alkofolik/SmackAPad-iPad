//
//  TrainingScreen.swift
//  SmackAPad
//
//  New Training screen following ticket 107 and mockup frame 1.
//  Dominant orange Today band, Memory meter, Next 7 days forecast,
//  Due now list with lateness, Mix & Play after me, and Training badges.
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
    @State private var loadedDailyMixes = ""
    @State private var calendarDay = AppCalendar.today()
    @Environment(\.scenePhase) private var scenePhase
    @State private var playingMix: [Lesson] = []
    @State private var showingMix = false
    @State private var mixFromMemory = false
    @State private var showingBadges = false
    @State private var showingToday = false
    @State private var activeTodayPlan: TodayPlan?

    @AppStorage(TodayPlan.storageKey) private var savedTodayPlan = ""
    @AppStorage("smackapad.training.dailyMixes") private var dailyMixes = "{}"
    @Namespace private var lessonNamespace

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
        let stats: BadgeProgressStats
        let badges: [BadgeDefinition]
        let hasMasteredLesson: Bool
        let nearestDueDay: String?
    }

    private var today: String { calendarDay }
    private var dueLessons: [Lesson] { data?.dueLessons ?? [] }
    private var nextLesson: Lesson? { data?.nextLesson }
    private var currentPlan: TodayPlan? { data?.currentPlan }
    private var isPlanFinished: Bool { currentPlan?.finished == true }

    public var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width >= 768 && geometry.size.width > geometry.size.height

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Space.page) {
                        if data == nil {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 160)
                                .accessibilityLabel(settings.localized("Training"))
                        } else {
                            todayBand

                            if isLandscape {
                                HStack(alignment: .top, spacing: Theme.Space.page) {
                                    memoryMeterPanel
                                        .frame(maxWidth: .infinity)
                                    next7DaysPanel
                                        .frame(maxWidth: .infinity)
                                }
                            } else {
                                memoryMeterPanel
                                next7DaysPanel
                            }

                            dueNowPanel

                            if isLandscape {
                                HStack(alignment: .top, spacing: Theme.Space.page) {
                                    mixPanel
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    afterMePanel
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            } else {
                                mixPanel
                                afterMePanel
                            }

                            trainingBadgesPanel(isLandscape: isLandscape)
                        }

                        Spacer(minLength: Theme.Space.page)
                    }
                    .padding(Theme.Space.page)
                    .frame(maxWidth: 1240, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
            }
            .calmChassisBackground()
            .navigationTitle(settings.localized("Training"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                PadToolbarItem(placement: .topBarLeading) {
                    Button(action: onHome) {
                        Text(settings.localized("Home"))
                            .font(Theme.control)
                            .frame(minHeight: Theme.Size.touch)
                    }
                    .buttonStyle(PadSecondaryButtonStyle())
                }
            }
            .task(id: refreshID) {
                // Let the lightweight shell and pad zoom reach the screen before loading data.
                do { try await Task.sleep(for: .milliseconds(50)) }
                catch { return }
                refreshTrainingData()
            }
            .onAppear {
                isVisible = true
                refreshID = UUID()
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
                if let first = playingMix.first {
                    PracticeLessonDestination(launch: .mix(first, lessons: playingMix, fromMemory: mixFromMemory))
                }
            }
            .fullScreenCover(isPresented: $showingToday) {
                if let plan = activeTodayPlan {
                    TodaySessionScreen(plan: plan) { showingToday = false }
                }
            }
            .sheet(isPresented: $showingBadges) {
                BadgesView()
            }
        }
        .environment(\.lessonNamespace, lessonNamespace)
        .practiceLessonPresentation(launch: $selectedLesson, namespace: lessonNamespace)
    }

    // MARK: - 1. Today Band

    @ViewBuilder
    private var todayBand: some View {
        let finished = isPlanFinished
        let isEmptyFirstRun = data?.hasMasteredLesson != true && dueLessons.isEmpty

        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            // Band Header
            HStack(alignment: .firstTextBaseline) {
                Text(settings.localized(finished ? "That's enough for today" : "Today").uppercased(with: Locale(identifier: settings.languagePreference.rawValue)))
                    .font(Theme.strong(32))
                    .foregroundStyle(Theme.black)

                Spacer(minLength: Theme.Space.small)

                Text(bandMetaText(finished: finished))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.black.opacity(0.8))
            }

            if isEmptyFirstRun {
                emptyFirstRunBlock
            } else {
                // Three step blocks stay in one row even in portrait
                HStack(spacing: 12) {
                    reviewStepBlock
                    newLessonStepBlock
                    mixStepBlock
                }
            }

            // Band Footer
            if !finished && !isEmptyFirstRun {
                HStack(alignment: .center, spacing: Theme.Space.regular) {
                    Text(settings.localized("Nothing is locked. You can skip any step."))
                        .font(Theme.text(15))
                        .foregroundStyle(Theme.black)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: Theme.Space.small)

                    HStack(spacing: 10) {
                        Button {
                            postponeTodayReviews()
                        } label: {
                            Text(settings.localized("Not today"))
                                .font(Theme.strong(18))
                                .frame(minHeight: Theme.Size.touch)
                        }
                        .buttonStyle(PadSecondaryButtonStyle())
                        .disabled(dueLessons.isEmpty)
                        .opacity(dueLessons.isEmpty ? 0.4 : 1.0)

                        Button {
                            startTodayTraining()
                        } label: {
                            Text(settings.localized("START TODAY'S TRAINING"))
                                .font(Theme.strong(18))
                                .frame(minHeight: Theme.Size.touch)
                        }
                        .buttonStyle(PadSecondaryButtonStyle())
                    }
                }
            } else if finished {
                finishedSummaryView
            }
        }
        .padding(20)
        .background(Theme.orange)
        .overlay(Rectangle().stroke(Theme.black, lineWidth: 2))
    }

    private func bandMetaText(finished: Bool) -> String {
        let dateStr = formattedTodayDate()
        let count = dueLessons.count
        let dueStr: String = {
            if count == 1 {
                return settings.localized("1 review due")
            } else {
                return settings.localized("%lld reviews due", count)
            }
        }()
        return "\(dateStr) · \(dueStr)"
    }

    private func formattedTodayDate() -> String {
        let parts = today.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return today }
        var comp = DateComponents()
        comp.year = parts[0]; comp.month = parts[1]; comp.day = parts[2]
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        guard let date = cal.date(from: comp) else { return today }

        let locale = Locale(identifier: settings.languagePreference.rawValue)
        let fmt = DateFormatter()
        fmt.locale = locale
        if settings.languagePreference == .czech {
            fmt.dateFormat = "EEEE d. M."
        } else {
            fmt.dateFormat = "EEEE d MMM"
        }
        let str = fmt.string(from: date)
        return str.prefix(1).uppercased(with: locale) + str.dropFirst()
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
                            .foregroundStyle(Theme.black.opacity(0.85))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(Theme.strong(18))
                    .foregroundStyle(Theme.black)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
            .background(Theme.white)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.black, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .lessonSource(nextLesson?.id ?? 0)
    }

    private var reviewStepBlock: some View {
        let count = dueLessons.count
        let state: StepLedState = {
            if let saved = currentPlan, saved.steps.contains(where: { $0.kind == .review && $0.outcome?.played == true }) {
                return .done
            }
            return count > 0 ? .todo : .off
        }()

        let detailText: String = {
            if count == 0 {
                return settings.localized("No reviews due")
            } else if settings.languagePreference == .czech {
                if count == 1 {
                    return "1 lekce zpaměti v cílovém tempu"
                } else if count >= 2 && count <= 4 {
                    return "\(count) lekce zpaměti v cílovém tempu"
                } else {
                    return "\(count) lekcí zpaměti v cílovém tempu"
                }
            } else {
                return count == 1
                    ? settings.localized("1 lesson from memory at goal tempo")
                    : settings.localized("%lld lessons from memory at goal tempo", count)
            }
        }()

        return stepBlockView(
            number: settings.localized("STEP 1"),
            title: settings.localized("Review"),
            detail: detailText,
            state: state
        )
    }

    private var newLessonStepBlock: some View {
        let hasLesson = nextLesson != nil
        let state: StepLedState = {
            if let saved = currentPlan, saved.steps.contains(where: { $0.kind == .newLesson && $0.outcome?.played == true }) {
                return .done
            }
            return hasLesson ? .todo : .off
        }()

        let detail = nextLesson.map { settings.localized($0.title) } ?? settings.localized("All lessons completed")

        return stepBlockView(
            number: settings.localized("STEP 2"),
            title: settings.localized("New lesson"),
            detail: detail,
            state: state
        )
    }

    private var mixStepBlock: some View {
        let count = mixLessons.count
        let hasMix = count >= 2
        let state: StepLedState = {
            if let saved = currentPlan, saved.steps.contains(where: { $0.kind == .mix && $0.outcome?.played == true }) {
                return .done
            }
            return hasMix ? .todo : .off
        }()

        let detailText: String = {
            if !hasMix {
                return settings.localized("Mix needs two lessons with two stars.")
            } else if settings.languagePreference == .czech {
                if count == 1 {
                    return "1 lekce, každá jednou"
                } else if count >= 2 && count <= 4 {
                    return "\(count) lekce, každá jednou"
                } else {
                    return "\(count) lekcí, každá jednou"
                }
            } else {
                return count == 1
                    ? settings.localized("1 lesson, once")
                    : settings.localized("%lld lessons, each once", count)
            }
        }()

        return stepBlockView(
            number: settings.localized("STEP 3 · OPTIONAL"),
            title: settings.localized("Mix"),
            detail: detailText,
            state: state
        )
    }

    private enum StepLedState {
        case todo, done, off

        var accessibilityText: String {
            switch self {
            case .todo: return "To do"
            case .done: return "Done"
            case .off: return "Nothing to do"
            }
        }
    }

    private func stepBlockView(number: String, title: String, detail: String, state: StepLedState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(number)
                    .font(Theme.strong(12).monospaced())
                    .foregroundStyle(Theme.black.opacity(0.8))
                Spacer()
                ledView(state: state)
            }

            Text(title)
                .font(Theme.strong(22))
                .foregroundStyle(Theme.black)
                .lineLimit(1)

            Text(detail)
                .font(Theme.text(14))
                .foregroundStyle(Theme.black.opacity(0.85))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .background(state == .done ? Color.clear : Theme.white)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Theme.black, style: StrokeStyle(lineWidth: 2, dash: state == .done ? [6, 4] : []))
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(number), \(title), \(settings.localized(state.accessibilityText)), \(detail)")
    }

    private func ledView(state: StepLedState) -> some View {
        ZStack {
            switch state {
            case .todo:
                Circle()
                    .fill(Theme.orange)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Theme.black, lineWidth: 2))
                    .shadow(color: Theme.orange.opacity(0.55), radius: 3)
            case .done:
                Circle()
                    .fill(Theme.black)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Theme.black, lineWidth: 2))
            case .off:
                Circle()
                    .fill(Theme.ledOff)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Theme.black, lineWidth: 2))
            }
        }
    }

    private var finishedSummaryView: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            if let saved = currentPlan {
                let passed = saved.steps.filter { step in
                    guard step.kind == .review, let feedback = step.outcome?.reviewFeedback else { return false }
                    switch feedback { case .passed, .settled: return true; default: return false }
                }.count
                Text(settings.localized("Reviews passed: %lld of %lld", passed, saved.reviewCount))
                    .font(Theme.strong(18))
                    .foregroundStyle(Theme.black)
            }
        }
    }

    private func postponeTodayReviews() {
        for lesson in dueLessons {
            progress.postponeReview(for: lesson.id, today: today)
        }
        if var plan = TodayPlan.decode(savedTodayPlan, today: today), !plan.finished {
            for step in plan.steps where step.kind == .review && step.outcome?.played != true {
                if let id = step.lessonIDs.first {
                    progress.postponeReview(for: id, today: today)
                }
            }
            plan.finished = true
            if let data = try? JSONEncoder().encode(plan), let json = String(data: data, encoding: .utf8) {
                savedTodayPlan = json
            }
        }
    }

    private func startTodayTraining() {
        if let plan = currentPlan, !plan.finished {
            activeTodayPlan = plan
            showingToday = true
            return
        }
        // Construct fallback plan with available new lesson or mix
        var steps: [TodayPlan.Step] = []
        if let next = nextLesson {
            steps.append(.init(kind: .newLesson, lessonIDs: [next.id]))
        }
        if mixLessons.count >= 2 {
            steps.append(.init(kind: .mix, lessonIDs: mixLessons.map(\.id)))
        }
        if !steps.isEmpty {
            let plan = TodayPlan(day: today, steps: steps)
            if let data = try? JSONEncoder().encode(plan), let json = String(data: data, encoding: .utf8) {
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
        .satinPlate()
    }

    private func meterColumn(label: String, count: Int, largest: Int, isSettled: Bool, accessibilityPrefix: String) -> some View {
        let litCount: Int = {
            guard count > 0 else { return 0 }
            let raw = Int((Double(count) / Double(largest) * 8.0).rounded())
            return min(8, max(1, raw))
        }()

        let offColor = Theme.ledOff
        let litColor = isSettled ? Theme.orange : Theme.ink

        let lessonCountPlural: String = {
            if settings.languagePreference == .czech {
                if count == 1 { return "1 lekce" }
                if count >= 2 && count <= 4 { return "\(count) lekce" }
                return "\(count) lekcí"
            }
            return count == 1 ? settings.localized("1 lesson") : settings.localized("%lld lessons", count)
        }()

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

            HStack(spacing: 6) {
                ForEach(forecast, id: \.day) { entry in
                    let isToday = (entry.day == today)
                    let (shortName, fullName) = weekdayNames(from: entry.day)
                    let countPlural: String = {
                        if settings.languagePreference == .czech {
                            if entry.count == 1 { return "1 lekce" }
                            if entry.count >= 2 && entry.count <= 4 { return "\(entry.count) lekce" }
                            return "\(entry.count) lekcí"
                        }
                        return entry.count == 1 ? settings.localized("1 lesson") : settings.localized("%lld lessons", entry.count)
                    }()

                    VStack(spacing: 4) {
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
                    .background(isToday ? Theme.surface : Color.clear)
                    .overlay(Rectangle().stroke(isToday ? Theme.ink : Theme.hairline, lineWidth: 2))
                    .overlay(alignment: .bottom) {
                        if isToday {
                            HardwareLightBar(active: true, breathes: false)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(fullName), \(countPlural)")
                }
            }

            Text(settings.localized("Lessons coming back for a review that day."))
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
        }
        .padding(Theme.Space.regular)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .satinPlate()
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

    private var dueNowPanel: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            panelHeader(settings.localized("Due now"))

            VStack(spacing: 0) {
                if data?.hasMasteredLesson != true {
                    emptyCardText(settings.localized("Reviews start once a lesson has two stars."))
                } else if dueLessons.isEmpty {
                    let nextDateFormatted: String = {
                        if let nearest = data?.nearestDueDay {
                            return formattedDate(from: nearest)
                        } else {
                            return "—"
                        }
                    }()
                    emptyCardText(settings.localized("Nothing to review today. Next: %@", nextDateFormatted))
                } else {
                    ForEach(Array(dueLessons.enumerated()), id: \.element.id) { index, lesson in
                        if index > 0 {
                            Rectangle()
                                .fill(Theme.hairline)
                                .frame(height: 1)
                        }
                        dueLessonRow(lesson)
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
        let lateness = latenessText(for: record?.reviewDueDay)

        return Button {
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

                Text(lateness)
                    .font(Theme.text(14))
                    .foregroundStyle(Theme.secondary)
                    .fixedSize()
            }
            .padding(.vertical, 8)
            .frame(minHeight: 52)
            .overlay(alignment: .bottom) {
                if record?.reviewDueDay != nil {
                    HardwareLightBar(active: true, breathes: false)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .lessonSource(lesson.id)
    }

    private func latenessText(for dueDay: String?) -> String {
        guard let dueDay, dueDay < today else {
            return settings.localized("today")
        }
        let diff = AppCalendar.daysBetween(dueDay, today) ?? 0
        if diff <= 0 { return settings.localized("today") }
        if diff == 1 { return settings.localized("1 day late") }

        if settings.languagePreference == .czech {
            if diff >= 2 && diff <= 4 {
                return "o \(diff) dny později"
            } else {
                return "o \(diff) dní později"
            }
        } else {
            return settings.localized("%lld days late", diff)
        }
    }

    // MARK: - 4. Mix & Play after me

    private var mixCandidates: [Lesson] { data?.mixCandidates ?? [] }
    private var openMixLessonIDs: Set<Int> { data?.openLessonIDs ?? [] }
    private var mixLessons: [Lesson] { data?.mixLessons ?? [] }

    private var mixPanel: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            panelHeader(settings.localized("Mix"))

            VStack(alignment: .leading, spacing: Theme.Space.small) {
                ForEach(Array(mixLessons.enumerated()), id: \.element.id) { index, lesson in
                    Text("\(index + 1). \(settings.localized(lesson.title))")
                        .font(Theme.rowTitle)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                }
                if mixLessons.count < 2 {
                    Text(settings.localized("Mix needs two lessons with two stars."))
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary)
                }
            }

            Toggle(settings.localized("From memory"), isOn: $mixFromMemory)
                .font(Theme.control)
                .tint(Theme.ink)
                .frame(minHeight: Theme.Size.touch)
                .disabled(mixLessons.count < 2)

            HStack(spacing: Theme.Space.regular) {
                Button {
                    playingMix = mixLessons
                    showingMix = true
                } label: {
                    Text(settings.localized("Start"))
                        .font(Theme.action)
                        .frame(minHeight: Theme.Size.control)
                }
                .buttonStyle(PadPrimaryButtonStyle())
                .disabled(mixLessons.count < 2)

                Button {
                    refreshMix(newDraw: true)
                } label: {
                    Text(settings.localized("New mix"))
                        .font(Theme.control)
                        .frame(minHeight: Theme.Size.touch)
                }
                .buttonStyle(PadSecondaryButtonStyle())
                .disabled(mixLessons.count < 2)
            }
        }
        .padding(Theme.Space.regular)
        .frame(maxWidth: .infinity, alignment: .leading)
        .satinPlate()
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

    private var afterMePanel: some View {
        let candidate = afterMeCandidates.first(where: { $0.id == afterMeLessonID })

        return VStack(alignment: .leading, spacing: Theme.Space.regular) {
            panelHeader(settings.localized("Play after me"))

            if let lesson = candidate {
                HStack(spacing: Theme.Space.regular) {
                    Text(settings.localized(lesson.title))
                        .font(Theme.rowTitle)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Spacer(minLength: Theme.Space.small)
                    StarsView(record: progress.progress(for: lesson.id), lesson: lesson)
                }

                Text(settings.localized("App plays, you repeat. Without sheet music."))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)

                HStack(spacing: Theme.Space.regular) {
                    Button {
                        selectedAfterMeLesson = lesson
                    } label: {
                        Text(settings.localized("Start"))
                            .font(Theme.action)
                            .frame(minHeight: Theme.Size.control)
                    }
                    .buttonStyle(PadPrimaryButtonStyle())

                    Button {
                        chooseAfterMeLesson(another: true)
                    } label: {
                        Text(settings.localized("Another lesson"))
                            .font(Theme.control)
                            .frame(minHeight: Theme.Size.touch)
                    }
                    .buttonStyle(PadSecondaryButtonStyle())
                    .disabled(afterMeCandidates.count < 2)
                }
            } else {
                Text(settings.localized("Learn a lesson to play after me."))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
            }
        }
        .padding(Theme.Space.regular)
        .frame(maxWidth: .infinity, alignment: .leading)
        .satinPlate()
    }

    // MARK: - 5. Training Badges

    private var availableTrainingBadges: [BadgeDefinition] {
        let allTraining = badgeStore.definitions.filter { $0.group == .training }
        let unearned = allTraining.filter { !badgeStore.isEarned(badgeId: $0.id) }
        if !unearned.isEmpty {
            return Array(unearned.prefix(3))
        }
        // If all are earned, show the three most recent
        let sortedEarned = allTraining.sorted { a, b in
            let dateA = badgeStore.earnedDate(for: a.id) ?? .distantPast
            let dateB = badgeStore.earnedDate(for: b.id) ?? .distantPast
            return dateA > dateB
        }
        return Array(sortedEarned.prefix(3))
    }

    private func trainingBadgesPanel(isLandscape: Bool) -> some View {
        let badges = data?.badges ?? []

        return VStack(alignment: .leading, spacing: Theme.Space.regular) {
            HStack(alignment: .firstTextBaseline) {
                panelHeader(settings.localized("Training badges"))
                Spacer()
                Button {
                    showingBadges = true
                } label: {
                    Text(settings.localized("All badges ›"))
                        .font(Theme.strong(16))
                        .foregroundStyle(Theme.ink)
                        .underline()
                }
                .buttonStyle(.plain)
            }

            if isLandscape {
                HStack(alignment: .top, spacing: Theme.Space.regular) {
                    ForEach(badges) { badge in
                        if let stats = data?.stats {
                            badgeCell(badge: badge, stats: stats)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: Theme.Space.regular) {
                    ForEach(badges) { badge in
                        if let stats = data?.stats {
                            badgeCell(badge: badge, stats: stats)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .padding(Theme.Space.regular)
        .frame(maxWidth: .infinity, alignment: .leading)
        .satinPlate()
    }

    private func badgeCell(badge: BadgeDefinition, stats: BadgeProgressStats) -> some View {
        let isEarned = badgeStore.isEarned(badgeId: badge.id)
        let goal = BadgeEvaluator.targetGoal(for: badge, in: stats)
        let current = BadgeEvaluator.currentProgress(for: badge, in: stats)
        let done = min(goal, current)
        let offColor = Theme.ledOff

        return HStack(alignment: .center, spacing: 12) {
            // Medal circle (44x44)
            ZStack {
                Circle()
                    .stroke(Theme.ink, lineWidth: 2)
                    .frame(width: 44, height: 44)

                if isEarned {
                    Image(systemName: "checkmark")
                        .font(Theme.strong(16))
                        .foregroundStyle(Theme.orange)
                } else {
                    Text("\(done)")
                        .font(Theme.strong(15).monospacedDigit())
                        .foregroundStyle(Theme.ink)
                }
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(settings.localized(badge.name))
                    .font(Theme.strong(17))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                Text(isEarned ? "\(settings.localized(badge.condition)) · \(settings.localized("Earned"))"
                              : "\(settings.localized(badge.condition)) · \(done) / \(goal)")
                    .font(Theme.text(13))
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)

                // 8pt progress bar
                GeometryReader { barGeom in
                    let w = barGeom.size.width
                    let fraction = goal > 0 ? min(1.0, max(0.0, Double(done) / Double(goal))) : 0.0
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(offColor)
                            .frame(width: w, height: 8)
                        Rectangle()
                            .fill(isEarned ? Theme.orange : Theme.ink)
                            .frame(width: w * fraction, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Refresh

    private func refreshCalendarDay() {
        calendarDay = AppCalendar.today()
        refreshID = UUID()
    }

    private func refreshTrainingData() {
        guard isVisible else { return }
        let generation = refreshID
        let started = Date.timeIntervalSinceReferenceDate
        // Observation invalidates this snapshot once when an actual input changes.
        // It does not enumerate candidates to manufacture a task identifier on each render.
        let snapshot = withObservationTracking {
            makeTrainingData()
        } onChange: {
            Task { @MainActor in
                guard isVisible, refreshID == generation else { return }
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
        let candidates = TrainingMix.candidates(lessons: lessons, progress: records,
            padCount: padCount, openLessonIDs: openIDs)
        let mix = TrainingMix.dailySelection(lessons: lessons, progress: records,
            padCount: padCount, openLessonIDs: openIDs, day: today, savedJSON: dailyMixes)
        let due = progress.dueLessonIds(today: today).compactMap { lessonStore.lesson(for: $0) }
        let source = NextLessonSource(rawValue: settings.nextLessonSource) ?? .path
        let next = progression.nextLesson(after: lessonStore.lesson(for: settings.lastLessonID), source: source)
            ?? progression.catalog.path.first
        let plan = TodayPlan.decode(savedTodayPlan, today: today) ?? TodayPlan.make(
            day: today, dueLessonIDs: due.map(\.id), nextLessonID: next?.id, mixLessonIDs: mix.map(\.id))
        let afterMe = lessons.filter { lesson in
            guard let record = records[lesson.id], record.passed || record.mastery || record.memory,
                  openIDs.contains(lesson.id) else { return false }
            return padCount == 16 || EightPadLayout.slots(for: lesson) != nil
        }.sorted {
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
        return TrainingData(dueLessons: due, nextLesson: next, currentPlan: plan,
            mixCandidates: candidates, openLessonIDs: openIDs, mixLessons: mix,
            afterMeCandidates: afterMe, memoryCounts: counts,
            forecast: ReviewForecast.dueCounts(records, from: today, days: 7).map { ($0.day, $0.count) },
            stats: BadgeEvaluator.evaluate(progress: records, catalog: progression.catalog,
                definitions: badgeStore.definitions, currentlyEarned: Set(badgeStore.records.keys),
                trainingLog: progress.trainingLog).stats,
            badges: availableTrainingBadges, hasMasteredLesson: progress.hasAnyMasteredLesson,
            nearestDueDay: progress.nearestDueDay(today: today))
    }

    private func updateMix(_ ids: [Int]) {
        guard var snapshot = data else { return }
        let byID = Dictionary(uniqueKeysWithValues: snapshot.mixCandidates.map { ($0.id, $0) })
        snapshot.mixLessons = ids.compactMap { byID[$0] }
        snapshot.currentPlan = TodayPlan.decode(savedTodayPlan, today: today) ?? TodayPlan.make(
            day: today, dueLessonIDs: snapshot.dueLessons.map(\.id),
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
