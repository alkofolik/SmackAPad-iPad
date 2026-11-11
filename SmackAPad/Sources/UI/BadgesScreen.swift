import SwiftUI

/// Badges sheet displaying long-term achievements grouped by category.
struct BadgesView: View {
    @Environment(BadgeStore.self) private var badgeStore
    @Environment(ProgressStore.self) private var progressStore
    @Environment(ProgressionManager.self) private var progression
    @Environment(SettingsManager.self) private var settings
    @Environment(\.dismiss) private var dismiss
    var onDismiss: (() -> Void)? = nil

    private var stats: BadgeProgressStats {
        BadgeEvaluator.evaluate(
            progress: progressStore.records,
            catalog: progression.catalog,
            definitions: badgeStore.definitions,
            currentlyEarned: Set(badgeStore.records.keys),
            trainingLog: progressStore.trainingLog
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
            .calmChassisBackground()
            .toolbar {
                PadToolbarItem(placement: .topBarLeading) {
                    BackButton {
                        if let onDismiss { onDismiss() } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .principal) {
                    ScreenHeader(title: settings.localized("Badges"))
                }
            }
        }
    }

    @ViewBuilder
    private func badgeGroupSection(group: BadgeGroup, badges: [BadgeDefinition]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            SectionHeader(title: settings.localized(group.title))

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 150), spacing: 14)],
                spacing: 14
            ) {
                ForEach(badges) { badge in
                    BadgeTile(
                        badge: badge,
                        stats: stats,
                        earnedDate: badgeStore.earnedDate(for: badge.id)
                    )
                }
            }
        }
    }
}
