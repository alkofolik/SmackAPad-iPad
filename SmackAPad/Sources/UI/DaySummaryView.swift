import SwiftUI

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

struct DaySummaryView: View {
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
        let failureReason = step.reviewFailureReason(language: settings.languagePreference)
        let isDidNotCount: Bool = {
            if step.kind == .review { return failureReason != nil }
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

                    if let failureReason {
                        Text(failureReason)
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

                let scoreText = stepScoreText(for: step)
                if !scoreText.isEmpty {
                    Text(scoreText)
                        .font(Theme.boldDisplay(24).monospacedDigit())
                        .foregroundStyle(isPassed ? Theme.ink : Theme.secondary)
                        .lineLimit(1)
                }
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
