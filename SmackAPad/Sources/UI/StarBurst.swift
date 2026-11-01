import SwiftUI
import UIKit

struct StarBurst: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let event: StarEvent
    let announcement: String
    @State private var revealed: Set<Int> = []
    private var motion: Theme.Motion.Policy { .init(reduced: reduceMotion) }
    @State private var visible = false

    private var large: Bool { event.award.shouldStop }

    var body: some View {
        HStack(spacing: large ? Theme.Space.regular : Theme.Space.small) {
            ForEach(0..<3, id: \.self) { index in
                let fresh = event.award.fresh[index]
                StarShape()
                    .fill(Theme.black.opacity(event.award.earned[index] && (!fresh || revealed.contains(index)) ? 1 : 0))
                    .overlay(StarShape().stroke(Theme.black, lineWidth: Theme.Size.border))
                    .frame(width: large ? 56 : 28, height: large ? 56 : 28)
                    .scaleEffect(motion.scale(!fresh || revealed.contains(index) ? 1 : 0.35))
                    .motion(Theme.Motion.emphasis, value: revealed)
            }
        }
        .padding(large ? Theme.Space.page : 12)
        .background(Theme.orange, in: RoundedRectangle(cornerRadius: Theme.Size.panelRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Size.panelRadius)
                .strokeBorder(Theme.black, lineWidth: Theme.Size.border)
        }
        .opacity(visible ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(announcement)
        .accessibilityHidden(!visible)
        .task {
            withAnimation(motion.animation(Theme.Motion.fast)) { visible = true }
            do {
                try await Task.sleep(for: .milliseconds(100))
                for index in 0..<3 {
                    revealed.insert(index)
                    try await Task.sleep(for: Theme.Motion.starStagger)
                }
                UIAccessibility.post(notification: .announcement, argument: announcement)
                try await Task.sleep(for: .milliseconds(large ? 2_700 : 1_700))
                withAnimation(motion.animation(Theme.Motion.fast)) { visible = false }
            } catch {
                // A new event, restart or navigation cancels this panel's lifetime.
            }
        }
    }
}
