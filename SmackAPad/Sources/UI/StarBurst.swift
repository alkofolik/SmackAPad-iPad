import SwiftUI
import UIKit

struct StarBurst: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let event: StarEvent
    let announcement: String
    @State private var revealed = false
    @State private var visible = false

    private var large: Bool { event.award.shouldStop }

    var body: some View {
        HStack(spacing: large ? Theme.Space.regular : Theme.Space.small) {
            ForEach(0..<3, id: \.self) { index in
                let fresh = event.award.fresh[index]
                StarShape()
                    .fill(Theme.black.opacity(event.award.earned[index] && (!fresh || revealed) ? 1 : 0))
                    .overlay(StarShape().stroke(Theme.black, lineWidth: Theme.Size.border))
                    .frame(width: large ? 56 : 28, height: large ? 56 : 28)
                    .scaleEffect(reduceMotion || !fresh || revealed ? 1 : 0.35)
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
            withAnimation(.easeOut(duration: 0.15)) { visible = true }
            do {
                try await Task.sleep(for: .milliseconds(100))
                withAnimation(reduceMotion ? .easeInOut(duration: 0.25) : .spring(response: 0.4, dampingFraction: 0.6)) {
                    revealed = true
                }
                UIAccessibility.post(notification: .announcement, argument: announcement)
                try await Task.sleep(for: .milliseconds(large ? 2_700 : 1_700))
                withAnimation(.easeOut(duration: 0.2)) { visible = false }
            } catch {
                // A new event, restart or navigation cancels this panel's lifetime.
            }
        }
    }
}
