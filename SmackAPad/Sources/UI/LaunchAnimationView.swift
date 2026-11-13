import SwiftUI

/// Cold-start launch view and Home screen.
/// Powers on the Home display, then reveals its plate in 0.75 seconds.
/// Reduced motion uses a simple fade; the final frame is the live Home screen.
@MainActor
public struct LaunchAnimationView: View {
    let onFinished: () -> Void

    public init(onFinished: @escaping () -> Void = {}) {
        self.onFinished = onFinished
    }

    public var body: some View {
        HomeScreen(
            isColdStart: true,
            onColdStartFinished: onFinished
        )
    }
}
