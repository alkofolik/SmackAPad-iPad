import SwiftUI
import UIKit

/// The existing award event fills only its new stars, in place in the result row.
struct StarBurst: View {
    @Environment(\.accessibilityReduceMotion) private var reduced
    let earned: [Bool]
    let event: StarEvent?
    let announcement: String
    @State private var revealed = false
    @State private var scale: CGFloat = 0.86

    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<3, id: \.self) { index in
                let fresh = event?.award.fresh[index] == true
                ZStack {
                    Image(systemName: "star")
                        .foregroundStyle(earned[index] && (!fresh || revealed || reduced)
                                         ? PracticeBandStyle.orange : Theme.ink)
                    Image(systemName: "star.fill")
                        .foregroundStyle(PracticeBandStyle.orange)
                        .opacity(earned[index] && (!fresh || revealed || reduced) ? 1 : 0)
                }
                .font(.system(size: 40, weight: .regular))
                .frame(width: 40, height: 52)
                .scaleEffect(fresh && !reduced ? scale : 1)
            }
        }
        .padding(.horizontal, 7)
        .accessibilityHidden(true)
        .transaction { if reduced { $0.animation = nil } }
        .task(id: event?.id) {
            guard event != nil else { return }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { revealed = reduced; scale = reduced ? 1 : 0.86 }
            await Task.yield()
            guard !Task.isCancelled else { return }
            if !reduced {
                withAnimation(.easeOut(duration: 0.18)) { revealed = true; scale = 1.08 }
                do { try await Task.sleep(for: .milliseconds(180)) } catch { return }
                withAnimation(.easeInOut(duration: 0.30)) { scale = 1 }
            }
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }
}
