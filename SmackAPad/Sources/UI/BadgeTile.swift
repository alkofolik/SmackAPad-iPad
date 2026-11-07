import SwiftUI

/// Pad-style tile displaying an achievement badge (Ticket 146, Variant B).
/// Earned tiles glow like a lit pad, unearned tiles are tactile and dim with a progress bar.
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
            tileContent
        }
        .buttonStyle(BadgeTileButtonStyle())
        .popover(isPresented: $showingDetail) {
            BadgeDetailPopover(
                badge: badge,
                stats: stats,
                earnedDate: earnedDate,
                formattedDate: formattedDate,
                done: done,
                goal: goal,
                isEarned: isEarned
            )
            .presentationCompactAdaptation(.popover)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(settings.localized(badge.name)), \(settings.localized(badge.condition))")
        .accessibilityValue(isEarned ? settings.localized("Earned: %@", formattedDate) : settings.localized("Progress: %lld / %lld", done, goal))
        .accessibilityAddTraits(.isButton)
    }

    private var tileContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top-left: tier LED dots (6–7 pt)
            HStack(spacing: compact ? 3 : 4) {
                ForEach(0..<badge.tier, id: \.self) { _ in
                    Circle()
                        .fill(isEarned ? Theme.orange : Theme.hairline)
                        .frame(width: compact ? 6 : 6.5, height: compact ? 6 : 6.5)
                        .shadow(color: isEarned ? Theme.orange.opacity(0.8) : .clear, radius: 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 2)

            // Centre: icon about 52 pt (or ~40 pt in compact)
            Image(badge.iconAssetName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: compact ? 40 : 52, height: compact ? 40 : 52)
                .foregroundStyle(isEarned ? Theme.orange : Theme.secondary.opacity(0.38))
                .shadow(color: isEarned ? Theme.orange.opacity(0.6) : .clear, radius: 3)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 2)

            // Bottom: name (max 2 lines) + foot (progress or earned date)
            VStack(alignment: .leading, spacing: 4) {
                Text(settings.localized(badge.name))
                    .font(Theme.strong(compact ? 13 : 14.5))
                    .foregroundStyle(isEarned ? Theme.white : Theme.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isEarned {
                    Text(formattedDate)
                        .font(Theme.text(compact ? 10 : 11).monospacedDigit())
                        .foregroundStyle(Theme.white.opacity(0.6))
                        .lineLimit(1)
                } else {
                    GeometryReader { geo in
                        let w = geo.size.width
                        let fraction = goal > 0 ? min(1.0, max(0.0, Double(done) / Double(goal))) : 0.0
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Theme.hairline)
                                .frame(width: w, height: compact ? 2.5 : 3)
                            Capsule()
                                .fill(Theme.orange)
                                .frame(width: w * fraction, height: compact ? 2.5 : 3)
                        }
                    }
                    .frame(height: compact ? 2.5 : 3)
                    .padding(.top, 2)
                }
            }
        }
        .padding(compact ? 10 : 12)
        .frame(maxWidth: .infinity)
        .aspectRatio(1.0 / 1.08, contentMode: .fit)
        .background {
            if isEarned {
                RoundedRectangle(cornerRadius: Theme.Radius.pad)
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 42/255, green: 22/255, blue: 8/255), Theme.cavity],
                            center: UnitPoint(x: 0.5, y: 0.4),
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .shadow(color: Theme.orange.opacity(0.35), radius: 8, x: 0, y: 0)
            } else {
                RoundedRectangle(cornerRadius: Theme.Radius.pad)
                    .fill(Theme.surface)
                    .shadow(color: Theme.black.opacity(0.08), radius: 2, x: 0, y: 1)
            }
        }
        .overlay {
            if isEarned {
                RoundedRectangle(cornerRadius: Theme.Radius.pad)
                    .strokeBorder(Theme.orange, lineWidth: 2)
                    .allowsHitTesting(false)
            } else {
                VStack(spacing: 0) {
                    Theme.padBevelTop
                        .frame(height: 1.5)
                    Spacer(minLength: 0)
                    Theme.padBevelBottom
                        .frame(height: 2.0)
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pad))
                .allowsHitTesting(false)
            }
        }
        .overlay {
            if !isEarned {
                RoundedRectangle(cornerRadius: Theme.Radius.pad)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.pad))
    }
}

/// Tactile pad press animation for badge tiles.
struct BadgeTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Small detail popover displaying full badge condition, large icon, and progress/earned status.
struct BadgeDetailPopover: View {
    @Environment(SettingsManager.self) private var settings
    let badge: BadgeDefinition
    let stats: BadgeProgressStats
    let earnedDate: Date?
    let formattedDate: String
    let done: Int
    let goal: Int
    let isEarned: Bool

    var body: some View {
        VStack(spacing: Theme.Space.regular) {
            // Icon + Tier well
            VStack(spacing: Theme.Space.small) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.pad)
                        .fill(isEarned ? Theme.cavity : Theme.surface)
                        .frame(width: 80, height: 80)
                        .overlay {
                            if isEarned {
                                RoundedRectangle(cornerRadius: Theme.Radius.pad)
                                    .strokeBorder(Theme.orange, lineWidth: 2)
                                    .shadow(color: Theme.orange.opacity(0.4), radius: 6)
                            } else {
                                RoundedRectangle(cornerRadius: Theme.Radius.pad)
                                    .strokeBorder(Theme.hairline, lineWidth: 1)
                            }
                        }

                    Image(badge.iconAssetName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .foregroundStyle(isEarned ? Theme.orange : Theme.secondary.opacity(0.45))
                        .shadow(color: isEarned ? Theme.orange.opacity(0.6) : .clear, radius: 4)
                }

                HStack(spacing: 4) {
                    ForEach(0..<badge.tier, id: \.self) { _ in
                        Circle()
                            .fill(isEarned ? Theme.orange : Theme.hairline)
                            .frame(width: 7, height: 7)
                            .shadow(color: isEarned ? Theme.orange.opacity(0.8) : .clear, radius: 2)
                    }
                }
            }

            // Name & Condition
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

            // Progress or Earned
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
                        let fraction = goal > 0 ? min(1.0, max(0.0, Double(done) / Double(goal))) : 0.0
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
