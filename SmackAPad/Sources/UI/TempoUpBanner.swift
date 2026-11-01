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

    var body: some View {
        Text(label)
            .font(Theme.display(Theme.Size.body))
            .foregroundStyle(Theme.black)
            .padding(.horizontal, Theme.Space.regular)
            .padding(.vertical, Theme.Space.small)
            .background(Theme.orange, in: RoundedRectangle(cornerRadius: Theme.Size.blockRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Size.blockRadius)
                    .strokeBorder(Theme.black, lineWidth: Theme.Size.border)
            }
            .scaleEffect(pulse && !reduceMotion ? 1.08 : 1)
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(announcement)
            .accessibilityHidden(!visible)
            .task {
                withAnimation(.easeOut(duration: 0.15)) { visible = true }
                if !reduceMotion {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { pulse = true }
                    do {
                        try await Task.sleep(for: .milliseconds(300))
                    } catch { return }
                    withAnimation(.easeOut(duration: 0.2)) { pulse = false }
                }
                UIAccessibility.post(notification: .announcement, argument: announcement)
                do {
                    try await Task.sleep(for: .milliseconds(900))
                } catch { return }
                withAnimation(.easeOut(duration: 0.3)) { visible = false }
            }
    }
}
