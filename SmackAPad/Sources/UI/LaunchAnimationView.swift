import SwiftUI

/// Cold-start launch view and Home screen.
/// Reworked in ticket 61 so its last frame IS the settled home screen.
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
