import SwiftUI

/// Badges sheet displaying long-term achievements grouped by category.
struct BadgesView: View {
    @Environment(BadgeStore.self) private var badgeStore
    @Environment(ProgressStore.self) private var progressStore
    @Environment(ProgressionManager.self) private var progression
    @Environment(SettingsManager.self) private var settings
    @Environment(\.dismiss) private var dismiss

    private var stats: BadgeProgressStats {
        BadgeEvaluator.evaluate(
            progress: progressStore.records,
            catalog: progression.catalog,
            definitions: badgeStore.definitions,
            currentlyEarned: Set(badgeStore.records.keys)
        ).stats
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.wide) {
                    Text(settings.localized("Badges %lld / %lld", badgeStore.earnedCount, badgeStore.totalCount))
                        .font(Theme.display(24))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, Theme.Space.small)

                    ForEach(BadgeGroup.allCases) { group in
                        let groupBadges = badgeStore.definitions.filter { $0.group == group }
                        if !groupBadges.isEmpty {
                            badgeGroupSection(group: group, badges: groupBadges)
                        }
                    }
                }
                .padding(.horizontal, Theme.Space.page)
                .padding(.vertical, Theme.Space.regular)
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ScreenHeader(title: settings.localized("Badges"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.localized("Done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func badgeGroupSection(group: BadgeGroup, badges: [BadgeDefinition]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            SectionHeader(title: settings.localized(group.title))

            VStack(spacing: 0) {
                ForEach(Array(badges.enumerated()), id: \.element.id) { index, badge in
                    BadgeRowView(
                        badge: badge,
                        stats: stats,
                        earnedDate: badgeStore.earnedDate(for: badge.id)
                    )
                    if index < badges.count - 1 {
                        Divider()
                            .overlay(Theme.hairline)
                    }
                }
            }
        }
    }
}

/// A single row representing a badge in the Badges screen.
struct BadgeRowView: View {
    @Environment(SettingsManager.self) private var settings
    let badge: BadgeDefinition
    let stats: BadgeProgressStats
    let earnedDate: Date?

    private var isEarned: Bool { earnedDate != nil }
    private var goal: Int { BadgeEvaluator.targetGoal(for: badge, in: stats) }
    private var done: Int { min(goal, BadgeEvaluator.currentProgress(for: badge, in: stats)) }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Space.regular) {
            // Left: tier marks + badge name & condition
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.small) {
                tierMarks
                    .alignmentGuide(.firstTextBaseline) { d in d[VerticalAlignment.center] }

                VStack(alignment: .leading, spacing: Theme.Space.tight) {
                    Text(settings.localized(badge.name))
                        .font(Theme.rowTitle)
                        .foregroundStyle(isEarned ? Theme.ink : Theme.secondary)

                    Text(settings.localized(badge.condition))
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: Theme.Space.regular)

            // Right: earned date OR progress done / goal with thin progress line
            if let earnedDate {
                Text(settings.localized("Earned: %@", formattedDate(earnedDate)))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
            } else {
                VStack(alignment: .trailing, spacing: Theme.Space.tight) {
                    Text(settings.localized("Progress: %lld / %lld", done, goal))
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary)
                        .monospacedDigit()
                        .lineLimit(1)

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.hairline)
                            .frame(width: 72, height: 2)

                        Capsule()
                            .fill(Theme.orange)
                            .frame(
                                width: goal > 0 ? max(0, min(72, 72.0 * Double(done) / Double(goal))) : 0,
                                height: 2
                            )
                    }
                }
            }
        }
        .padding(.vertical, Theme.Space.small)
        .frame(minHeight: Theme.Size.listRow)
        .accessibilityElement(children: .combine)
    }

    private var tierMarks: some View {
        HStack(spacing: 3) {
            ForEach(0..<badge.tier, id: \.self) { _ in
                Circle()
                    .fill(isEarned ? Theme.orange : Theme.hairline)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(width: 24, alignment: .leading)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: settings.languagePreference.rawValue)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
