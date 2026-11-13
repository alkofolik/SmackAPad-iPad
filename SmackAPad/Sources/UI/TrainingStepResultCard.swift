import SwiftUI

/// A daily step's result and handoff, presented over Training without another menu.
struct TrainingStepResultCard: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @AccessibilityFocusState private var titleFocused: Bool

    let step: TodayPlan.Step
    let nextStep: TodayPlan.Step?
    let onContinue: () -> Void
    let onSkip: () -> Void
    let onDone: () -> Void
    let onClose: () -> Void

    private func title(for step: TodayPlan.Step) -> String {
        if step.kind == .mix { return settings.localized("Daily mix") }
        return step.lessonIDs.first.flatMap { LessonStore.shared.lesson(for: $0) }
            .map { settings.localized($0.title) } ?? settings.localized("Not played")
    }

    private var verdict: String {
        if let reason = step.reviewFailureReason(language: settings.languagePreference) { return reason }
        guard step.outcome?.played == true else { return settings.localized("Not played") }
        switch step.kind {
        case .review:
            return settings.localized("Passed")
        case .newLesson:
            return settings.localized(step.status == .passed
                ? "New lesson passed successfully!" : "Aim for 80% to pass the new lesson.")
        case .mix:
            return settings.localized(step.status == .passed
                ? "Daily mix completed successfully!" : "Mix completed · keep practicing to improve your groove.")
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { }
                    .accessibilityHidden(true)

                ScrollView {
                    card
                        .padding(Theme.Space.page)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geometry.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .task { titleFocused = true }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            HStack(alignment: .top, spacing: 16) {
                Text(title(for: step))
                    .font(Theme.screenTitle)
                    .foregroundStyle(Theme.white)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titleFocused)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.white)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.localized("Close"))
            }

            if step.reviewFailureReason(language: settings.languagePreference) == nil,
               let score = step.outcome?.bestScore {
                Text("\(Int((score * 100).rounded()))\u{00a0}%")
                    .font(Theme.boldDisplay(52).monospacedDigit())
                    .foregroundStyle(Theme.white)
            }

            ForEach(step.lessonIDs, id: \.self) { id in
                if let lesson = LessonStore.shared.lesson(for: id) {
                    HStack(spacing: 12) {
                        if step.kind == .mix {
                            Text(settings.localized(lesson.title))
                                .font(Theme.text(15))
                                .foregroundStyle(Theme.white)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        StarsView(record: progress.progress(for: id), lesson: lesson)
                    }
                    .frame(minHeight: 32)
                }
            }

            Text(verdict)
                .font(Theme.text(16))
                .foregroundStyle(Theme.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onContinue) {
                Text(nextStep.map { settings.localized("Continue to %@", title(for: $0)) }
                     ?? settings.localized("Summary"))
                    .font(Theme.action)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(PadPrimaryButtonStyle())

            if nextStep != nil {
                HStack(spacing: Theme.Space.controlGap) {
                    Button(action: onSkip) {
                        Text(settings.localized("Skip"))
                            .font(Theme.control)
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(PadSecondaryButtonStyle())

                    Button(action: onDone) {
                        Text(settings.localized("Done for today"))
                            .font(Theme.control)
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(PadSecondaryButtonStyle())
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .frame(maxWidth: 560)
        .background(Theme.black, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
