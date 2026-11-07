import SwiftUI
import UIKit

/// Short floating banner displayed at the top centre of the practice screen
/// when a run earns one or more badges. Shows for ~2.5 s then fades out.
/// Never blocks touch or MIDI input (`allowsHitTesting(false)`).
struct BadgeBanner: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(SettingsManager.self) private var settings
    let event: BadgeBannerEvent
    var onDismiss: (() -> Void)? = nil

    @State private var visible = false
    private var motion: Theme.Motion.Policy { .init(reduced: reduceMotion) }

    private var announcement: String {
        if event.badges.count == 1, let badge = event.badges.first {
            return settings.localized("New badge: %@", settings.localized(badge.name))
        } else {
            return settings.localized("Earned %lld new badges", event.badges.count)
        }
    }

    var body: some View {
        HStack(spacing: Theme.Space.small) {
            Image(systemName: "rosette")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Theme.orange)

            if event.badges.count == 1, let badge = event.badges.first {
                VStack(alignment: .leading, spacing: 1) {
                    Text(settings.localized("New badge"))
                        .font(Theme.text(12))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)
                    Text(settings.localized(badge.name))
                        .font(Theme.strong(18))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            } else {
                Text(settings.localized("Earned %lld new badges", event.badges.count))
                    .font(Theme.strong(18))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, Theme.Space.regular)
        .padding(.vertical, Theme.Space.small)
        .satinPlate()
        .offset(y: visible ? 0 : motion.offset(-16))
        .opacity(visible ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(announcement)
        .accessibilityHidden(!visible)
        .task {
            withAnimation(motion.animation(Theme.Motion.standard)) { visible = true }
            UIAccessibility.post(notification: .announcement, argument: announcement)
            do { try await Task.sleep(for: .milliseconds(2500)) } catch { return }
            withAnimation(motion.animation(Theme.Motion.standard)) { visible = false }
            do { try await Task.sleep(for: .milliseconds(300)) } catch { return }
            onDismiss?()
        }
    }
}
