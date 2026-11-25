import SwiftUI

/// Badges sheet displaying long-term achievements grouped by category.
struct BadgesView: View {
    @Environment(BadgeStore.self) private var badgeStore
    @Environment(ProgressStore.self) private var progressStore
    @Environment(ProgressionManager.self) private var progression
    @Environment(SettingsManager.self) private var settings
    @Environment(\.dismiss) private var dismiss
    let initialGroup: BadgeGroup?
    var onDismiss: (() -> Void)? = nil
    @State private var selectedGroup: BadgeGroup?

    init(initialGroup: BadgeGroup? = nil, onDismiss: (() -> Void)? = nil) {
        self.initialGroup = initialGroup
        self.onDismiss = onDismiss
        _selectedGroup = State(initialValue: initialGroup)
    }

    private var stats: BadgeProgressStats {
        BadgeEvaluator.evaluate(
            progress: progressStore.records,
            catalog: progression.catalog,
            definitions: badgeStore.definitions,
            currentlyEarned: Set(badgeStore.records.keys),
            trainingLog: progressStore.trainingLog
        ).stats
    }

    private var visibleGroups: [BadgeGroup] {
        if let selectedGroup { return [selectedGroup] }
        return BadgeGroup.allCases
    }

    private var displayedBadges: [BadgeDefinition] {
        guard let selectedGroup else { return badgeStore.definitions }
        return badgeStore.definitions.filter { $0.group == selectedGroup }
    }

    private var displayedEarnedCount: Int {
        displayedBadges.filter { badgeStore.earnedDate(for: $0.id) != nil }.count
    }

    private var displayedTotalCount: Int {
        displayedBadges.count
    }

    private var overallFraction: Double {
        guard displayedTotalCount > 0 else { return 0 }
        return min(1.0, max(0.0, Double(displayedEarnedCount) / Double(displayedTotalCount)))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, Theme.Space.page)
                .padding(.top, Theme.Space.page)
                .padding(.bottom, initialGroup == nil ? 20 : 12)

            if let initialGroup {
                HStack(spacing: 8) {
                    FilterChip(
                        title: settings.localized(initialGroup.title),
                        selected: selectedGroup == initialGroup
                    ) {
                        selectedGroup = initialGroup
                    }
                    FilterChip(
                        title: settings.localized("All"),
                        selected: selectedGroup == nil
                    ) {
                        selectedGroup = nil
                    }
                    Spacer()
                }
                .padding(.horizontal, Theme.Space.page)
                .padding(.bottom, 16)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(visibleGroups) { group in
                        let groupBadges = badgeStore.definitions.filter { $0.group == group }
                        if !groupBadges.isEmpty {
                            badgeGroupPanel(group: group, badges: groupBadges)
                        }
                    }
                }
                .padding(.horizontal, Theme.Space.page)
                .padding(.bottom, Theme.Space.page)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(spacing: 20) {
            BackButton {
                if let onDismiss { onDismiss() } else { dismiss() }
            }

            Text(settings.localized("Badges"))
                .font(Theme.boldDisplay(28))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)

            Spacer(minLength: 16)

            HStack(spacing: 14) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.starColor(for: 0))
                        .frame(width: 220, height: 8)
                    Capsule()
                        .fill(Theme.orange)
                        .frame(width: 220 * overallFraction, height: 8)
                }
                .frame(width: 220, height: 8)
                .accessibilityHidden(true)

                (Text("\(displayedEarnedCount) ")
                    .font(Theme.boldDisplay(20))
                    .foregroundColor(Theme.ink)
                + Text("/ \(displayedTotalCount)")
                    .font(Theme.display(20))
                    .foregroundColor(Theme.secondary))
                .monospacedDigit()
                .fixedSize()
                .accessibilityLabel(settings.localized("Badges %lld / %lld", displayedEarnedCount, displayedTotalCount))
            }
        }
        .frame(height: 56)
    }

    @ViewBuilder
    private func badgeGroupPanel(group: BadgeGroup, badges: [BadgeDefinition]) -> some View {
        let earnedInGroup = badges.filter { badgeStore.earnedDate(for: $0.id) != nil }.count

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(settings.localized(group.title))
                    .font(Theme.strong(19))
                    .foregroundStyle(Theme.ink)

                Text("\(earnedInGroup) / \(badges.count)")
                    .font(Theme.display(15).monospacedDigit())
                    .foregroundStyle(Theme.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(badges) { badge in
                        BadgeTile(
                            badge: badge,
                            stats: stats,
                            earnedDate: badgeStore.earnedDate(for: badge.id)
                        )
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.top, 18)
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
    }
}
