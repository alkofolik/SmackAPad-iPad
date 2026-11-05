import SwiftUI
import UIKit

/// Short announcement when the tempo rises between passes. Pulses the label
/// once, then fades out after about 1.2 s. Uses the same motion style as
/// `StarBurst`: spring when motion is allowed, simple fade otherwise.
struct TempoUpBanner: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let event: TempoUpEvent
    let label: String
    let announcement: String

    @State private var visible = false
    @State private var pulse = false
    private var motion: Theme.Motion.Policy { .init(reduced: reduceMotion) }

    var body: some View {
        Text(label)
            .font(Theme.strong(28))
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(Theme.black)
            .padding(.horizontal, Theme.Space.regular)
            .padding(.vertical, Theme.Space.small)
            .background(Theme.orange, in: Rectangle())
            .overlay {
                Rectangle()
                    .strokeBorder(Theme.black, lineWidth: Theme.Size.border)
            }
            .scaleEffect(motion.scale(pulse ? 1.08 : 1))
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(announcement)
            .accessibilityHidden(!visible)
            .task {
                withAnimation(motion.animation(Theme.Motion.fast)) { visible = true }
                withAnimation(motion.animation(Theme.Motion.emphasis)) { pulse = true }
                do { try await Task.sleep(for: .milliseconds(300)) } catch { return }
                withAnimation(motion.animation(Theme.Motion.fast)) { pulse = false }
                UIAccessibility.post(notification: .announcement, argument: announcement)
                do { try await Task.sleep(for: .milliseconds(600)) } catch { return }
                withAnimation(motion.animation(Theme.Motion.standard)) { visible = false }
            }
    }
}
