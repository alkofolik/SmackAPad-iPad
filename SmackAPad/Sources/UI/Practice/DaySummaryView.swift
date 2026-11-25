import SwiftUI

// MARK: - Date Formatting

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

// MARK: - Day Summary View (End of Day)

struct DaySummaryView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(ProgressionManager.self) private var progression
    let plan: TodayPlan
    let isLandscape: Bool
    let canStartExtraMix: Bool
    let onBack: () -> Void
    let onExtraMix: () -> Void
    let onEndTraining: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            BackButton(action: onBack)

            ScrollView {
                if isLandscape {
                    HStack(alignment: .top, spacing: Theme.Space.regular) {
                        summaryContent
                        timelineList
                    }
                } else {
                    VStack(spacing: Theme.Space.regular) {
                        summaryContent
                        timelineList
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)

            bottomButtons(height: Theme.Size.rowLarge)
        }
        .padding(Theme.Space.page)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var summaryContent: some View {
        VStack(alignment: .leading, spacing: Theme.Space.controlGap) {
            VStack(alignment: .leading, spacing: Theme.Space.tight) {
                Text(settings.localized("daySummary.title"))
                    .font(Theme.screenTitle)
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(DayDateFormatter.format(plan.day, language: settings.languagePreference))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
            }

            HStack(spacing: 0) {
                statColumn(label: settings.localized("Reviews"), value: "\(plan.reviewSummary.passed) / \(plan.reviewCount)")
                Rectangle().fill(Theme.hairline).frame(width: 1)
                statColumn(label: settings.localized("New lesson"), value: percentStatText(for: .newLesson, allowDoneFallback: false))
                Rectangle().fill(Theme.hairline).frame(width: 1)
                statColumn(label: settings.localized("Mix"), value: percentStatText(for: .mix, allowDoneFallback: true))
            }
            .fixedSize(horizontal: false, vertical: true)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))

            WeeklyRhythmStrip(day: plan.day, practiceDays: progress.trainingLog.practiceDays)

            if let milestoneText {
                Text(milestoneText)
                    .font(Theme.control)
                    .foregroundStyle(Theme.ink)
                    .padding(Theme.Space.controlGap)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statColumn(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.tight) {
            Text(label)
                .font(Theme.caption)
                .foregroundStyle(Theme.secondary)
            Text(value)
                .font(Theme.sectionTitle.monospacedDigit())
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Space.controlGap)
        .accessibilityElement(children: .combine)
    }

    private var milestoneText: String? {
        let stages = progression.catalog.stages.dropFirst()
        let nextLocked = stages.first { !progression.isStageOpen($0) }
        let earnedToday = stages.last { stage in
            let current = progression.unlockProgress(for: stage)
            guard current.completed >= current.needed else { return false }
            let earlier = progression.unlockProgress(for: stage, excludingMasteriesOn: plan.day)
            return earlier.completed < current.needed
        }
        if let unlocked = earnedToday ?? (nextLocked == nil ? stages.last : nil) {
            return settings.localized("Milestone reached · %@ unlocked", progression.title(for: unlocked.id))
        }
        guard let nextLocked else { return nil }
        let requirement = progression.unlockProgress(for: nextLocked)
        return settings.localized("Next milestone: %@ · %lld / %lld 2★ lessons",
                                  progression.title(for: nextLocked.id), requirement.completed, requirement.needed)
    }

    private var timelineList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(plan.steps.indices, id: \.self) { index in
                if index > 0 {
                    Rectangle().fill(Theme.hairline).frame(height: 1)
                }
                timelineRow(step: plan.steps[index])
            }
        }
        .padding(.horizontal, Theme.Space.controlGap)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
    }

    private func timelineRow(step: TodayPlan.Step) -> some View {
        let failureReason = step.reviewFailureReason(language: settings.languagePreference)
        let marker = step.markerSymbol ?? (step.outcome?.played == true ? "checkmark" : "minus")
        let score = stepScoreText(for: step)

        return HStack(spacing: Theme.Space.controlGap) {
            Image(systemName: marker)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(step.status == .passed ? Theme.ink : Theme.secondary)
                .frame(width: 20)
                .accessibilityLabel(settings.localized(step.status?.titleKey ?? "Not played"))

            VStack(alignment: .leading, spacing: Theme.Space.tight) {
                Text(stepTag(for: step))
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondary)
                Text(stepTitle(for: step))
                    .font(Theme.rowTitle)
                    .foregroundStyle(Theme.ink)
                if let failureReason {
                    Text(failureReason)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !score.isEmpty {
                Text(score)
                    .font(Theme.sectionTitle.monospacedDigit())
                    .foregroundStyle(Theme.ink)
            }
        }
        .padding(.vertical, Theme.Space.controlGap)
        .accessibilityElement(children: .combine)
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
            .buttonStyle(PadSecondaryButtonStyle())
            .disabled(!canStartExtraMix)

            Button {
                onEndTraining()
            } label: {
                Text(settings.localized("End training"))
                    .font(Theme.strong(17))
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
            }
            .buttonStyle(PadPrimaryButtonStyle())
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
        if step.kind == .review, step.reviewFailureReason(language: settings.languagePreference) != nil {
            return ""
        }
        guard let outcome = step.outcome, outcome.played else { return "—" }
        if let score = outcome.bestScore {
            return "\(Int((score * 100).rounded())) %"
        }
        return settings.localized("Done")
    }
}

// MARK: - Weekly Rhythm Strip

struct WeeklyRhythmStrip: View {
    @Environment(SettingsManager.self) private var settings
    let day: String
    let practiceDays: Set<String>

    var body: some View {
        let language = settings.languagePreference
        let locale = Locale(identifier: language.rawValue)
        let rhythm = WeeklyRhythm(today: day, practiceDays: practiceDays, locale: locale)
        let cell = RoundedRectangle(cornerRadius: Theme.Radius.button)

        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HStack(spacing: Theme.Space.tight) {
                ForEach(rhythm.days) { day in
                    VStack(spacing: Theme.Space.tight) {
                        Text(day.shortWeekday.capitalized(with: locale))
                            .font(day.isToday ? Theme.strong(13) : Theme.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(Theme.ink)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(day.practiced ? Theme.orange : Color.clear)
                            .frame(width: 14, height: 3)
                    }
                    .padding(.vertical, Theme.Space.small)
                    .frame(maxWidth: .infinity)
                    .background(Theme.surface, in: cell)
                    .overlay {
                        if day.isToday {
                            cell.strokeBorder(Theme.secondary, lineWidth: 1)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel([
                        DayDateFormatter.format(day.dayString, language: language),
                        day.isToday ? settings.localized("Today") : "",
                        day.practiced ? settings.localized("Practiced") : ""
                    ].filter { !$0.isEmpty }.joined(separator: ", "))
                }
            }

            Text(settings.localized("This week: %lld× · %lld days total", rhythm.practicedThisWeek, rhythm.totalPracticedDays))
                .font(Theme.caption.monospacedDigit())
                .foregroundStyle(Theme.secondary)
        }
        .padding(Theme.Space.controlGap)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.panel).strokeBorder(Theme.hairline, lineWidth: 1)
        }
    }
}
