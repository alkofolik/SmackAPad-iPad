import SwiftUI

/// Round achievement medal displaying earned status or conic progress.
struct BadgeTile: View {
    @Environment(SettingsManager.self) private var settings
    let badge: BadgeDefinition
    let stats: BadgeProgressStats
    let earnedDate: Date?
    var compact: Bool = false

    @State private var showingDetail = false

    private var isEarned: Bool { earnedDate != nil }
    private var goal: Int { BadgeEvaluator.targetGoal(for: badge, in: stats) }
    private var done: Int { min(goal, BadgeEvaluator.currentProgress(for: badge, in: stats)) }

    private var progressFraction: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, max(0.0, Double(done) / Double(goal)))
    }

    private var progressPercent: Int {
        guard !isEarned else { return 100 }
        guard goal > 0 else { return 0 }
        let rounded = Int((progressFraction * 100).rounded())
        return done < goal ? min(99, rounded) : rounded
    }

    private var formattedDate: String {
        guard let earnedDate else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: settings.languagePreference.rawValue)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: earnedDate)
    }

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            medalContent
        }
        .buttonStyle(BadgeTileButtonStyle())
        .popover(isPresented: $showingDetail) {
            BadgeDetailPopover(
                badge: badge,
                formattedDate: formattedDate,
                done: done,
                goal: goal,
                fraction: progressFraction,
                isEarned: isEarned
            )
            .presentationCompactAdaptation(.popover)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(settings.localized(badge.name)), \(settings.localized(badge.condition))")
        .accessibilityValue(isEarned ? settings.localized("Earned: %@", formattedDate) : settings.localized("Progress: %lld / %lld", done, goal))
        .accessibilityAddTraits(.isButton)
    }

    private var medalContent: some View {
        VStack(spacing: 8) {
            BadgeMedalIcon(
                iconAssetName: badge.iconAssetName,
                isEarned: isEarned,
                fraction: progressFraction
            )

            Text(settings.localized(badge.name))
                .font(Theme.strong(14))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.85)
                .frame(height: 36, alignment: .top)

            Text(isEarned ? formattedDate : "\(progressPercent) %")
                .font(Theme.display(12).monospacedDigit())
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(height: 16)
        }
        .frame(width: compact ? nil : 128)
        .frame(maxWidth: compact ? .infinity : 128)
        .contentShape(Rectangle())
    }
}

/// 84 pt ring with 72 pt inner circle; solid black/orange when earned, conic progress arc when unearned.
struct BadgeMedalIcon: View {
    let iconAssetName: String
    let isEarned: Bool
    let fraction: Double

    var body: some View {
        ZStack {
            if isEarned {
                Circle()
                    .fill(Theme.ink)
                    .frame(width: 84, height: 84)
                Circle()
                    .fill(Theme.orange)
                    .frame(width: 72, height: 72)
                Image(iconAssetName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Theme.black)
            } else {
                Circle()
                    .fill(Theme.starColor(for: 0))
                    .frame(width: 84, height: 84)
                if fraction > 0 {
                    Circle()
                        .inset(by: 3)
                        .trim(from: 0, to: fraction)
                        .stroke(Theme.ink, style: StrokeStyle(lineWidth: 6, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 84, height: 84)
                }
                Circle()
                    .fill(Theme.surface)
                    .frame(width: 72, height: 72)
                Image(iconAssetName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Theme.secondary.opacity(0.65))
            }
        }
        .frame(width: 84, height: 84)
    }
}

/// Tactile press animation for badge medals.
struct BadgeTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Small detail popover displaying full badge condition, medal icon, and progress/earned status.
struct BadgeDetailPopover: View {
    @Environment(SettingsManager.self) private var settings
    let badge: BadgeDefinition
    let formattedDate: String
    let done: Int
    let goal: Int
    let fraction: Double
    let isEarned: Bool

    var body: some View {
        VStack(spacing: Theme.Space.regular) {
            BadgeMedalIcon(
                iconAssetName: badge.iconAssetName,
                isEarned: isEarned,
                fraction: fraction
            )

            VStack(spacing: Theme.Space.tight) {
                Text(settings.localized(badge.name))
                    .font(Theme.boldDisplay(22))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)

                Text(settings.localized(badge.condition))
                    .font(Theme.text(16))
                    .foregroundStyle(Theme.secondary)
                    .multilineTextAlignment(.center)
            }

            Divider()
                .overlay(Theme.hairline)

            if isEarned {
                Text(settings.localized("Earned: %@", formattedDate))
                    .font(Theme.strong(16).monospacedDigit())
                    .foregroundStyle(Theme.orange)
            } else {
                VStack(spacing: Theme.Space.small) {
                    Text(settings.localized("Progress: %lld / %lld", done, goal))
                        .font(Theme.strong(16).monospacedDigit())
                        .foregroundStyle(Theme.secondary)

                    GeometryReader { geo in
                        let w = geo.size.width
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Theme.hairline)
                                .frame(width: w, height: 4)
                            Capsule()
                                .fill(Theme.orange)
                                .frame(width: w * fraction, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }
        }
        .padding(Theme.Space.page)
        .frame(minWidth: 260, maxWidth: 320)
    }
}
