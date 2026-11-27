import SwiftUI

/// Filter category for `BadgesView`.
private enum BadgeFilter: Hashable {
    case all
    case training
    case lessons
}

/// Badges sheet displaying long-term achievements grouped by category.
struct BadgesView: View {
    @Environment(BadgeStore.self) private var badgeStore
    @Environment(ProgressStore.self) private var progressStore
    @Environment(ProgressionManager.self) private var progression
    @Environment(SettingsManager.self) private var settings
    @Environment(\.dismiss) private var dismiss
    let initialGroup: BadgeGroup?
    var onDismiss: (() -> Void)? = nil
    @State private var selectedFilter: BadgeFilter

    init(initialGroup: BadgeGroup? = nil, onDismiss: (() -> Void)? = nil) {
        self.initialGroup = initialGroup
        self.onDismiss = onDismiss
        if initialGroup == .training {
            _selectedFilter = State(initialValue: .training)
        } else if initialGroup != nil {
            _selectedFilter = State(initialValue: .lessons)
        } else {
            _selectedFilter = State(initialValue: .all)
        }
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
        switch selectedFilter {
        case .all:
            return BadgeGroup.allCases
        case .training:
            return [.training]
        case .lessons:
            return BadgeGroup.allCases.filter { $0 != .training }
        }
    }

    private var displayedBadges: [BadgeDefinition] {
        let allowed = Set(visibleGroups)
        return badgeStore.definitions.filter { allowed.contains($0.group) }
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
            ScreenTopBar {
                HardwareBackButton {
                    if let onDismiss { onDismiss() } else { dismiss() }
                }

                Text(settings.localized("Badges"))
                    .font(Theme.boldDisplay(28))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
            } center: {
                EmptyView()
            } trailing: {
                overallProgress
            }
            .padding(.horizontal, Theme.Space.page)
            .padding(.top, Theme.Space.page)
            .padding(.bottom, Theme.Space.regular)

            HStack {
                PlexSegmentedPicker(
                    title: settings.localized("Badges"),
                    selection: $selectedFilter,
                    options: [
                        (.all, settings.localized("All")),
                        (.training, settings.localized("Training")),
                        (.lessons, settings.localized("Lessons"))
                    ],
                    size: .compact
                )
                Spacer()
            }
            .padding(.horizontal, Theme.Space.page)
            .padding(.bottom, Theme.Space.regular)

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
        .background(Theme.chassis.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var overallProgress: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.recessed)
                    .frame(width: 220, height: 8)
                    .overlay {
                        Capsule().strokeBorder(Theme.hairline, lineWidth: 1)
                    }
                Capsule()
                    .fill(Theme.accent)
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

    private func milestoneLabel(for badge: BadgeDefinition) -> String {
        switch badge.goal {
        case .count(let count):
            return "\(count)"
        case .catalogue, .group:
            return "100 %"
        }
    }

    @ViewBuilder
    private func badgeGroupPanel(group: BadgeGroup, badges: [BadgeDefinition]) -> some View {
        let earnedInGroup = badges.filter { badgeStore.earnedDate(for: $0.id) != nil }.count

        HardwareCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(settings.localized(group.title))
                        .font(Theme.strong(19))
                        .foregroundStyle(Theme.ink)

                    Text("\(earnedInGroup) / \(badges.count)")
                        .font(Theme.display(15).monospacedDigit())
                        .foregroundStyle(Theme.secondary)
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 124, maximum: 156), spacing: 16)],
                    alignment: .leading,
                    spacing: 18
                ) {
                    ForEach(badges) { badge in
                        BadgeTile(
                            badge: badge,
                            stats: stats,
                            earnedDate: badgeStore.earnedDate(for: badge.id),
                            compact: true,
                            badgeLabel: milestoneLabel(for: badge)
                        )
                    }
                }
            }
        }
    }
}
