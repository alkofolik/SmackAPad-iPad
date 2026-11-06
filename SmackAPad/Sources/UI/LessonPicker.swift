import SwiftUI

/// Top-level app routes between Home, Library and Training.
public enum AppRoute: Equatable, Sendable {
    case home
    case library(LibraryLaunchTarget)
    case training
}

/// Main content entry point hosting Home, Library and Training routes.
@MainActor
struct ContentView: View {
    @State private var hasPlayedColdStartAnimation = false

    var body: some View {
        HomeScreen(
            isColdStart: !hasPlayedColdStartAnimation,
            onColdStartFinished: {
                hasPlayedColdStartAnimation = true
            }
        )
    }
}
