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
    @State private var navigation = AppNavigation.shared
    @State private var hasPlayedColdStartAnimation = false
    @Environment(\.accessibilityReduceMotion) private var reduced

    var body: some View {
        ZStack {
            switch navigation.route {
            case .home:
                HomeScreen(
                    isColdStart: !hasPlayedColdStartAnimation,
                    onColdStartFinished: {
                        hasPlayedColdStartAnimation = true
                    },
                    onNavigateToLibrary: { target in
                        withAnimation(Theme.Motion.Policy(reduced: reduced).animation(Theme.Motion.standard)) {
                            navigation.openLibrary(target)
                        }
                    },
                    onNavigateToTraining: {
                        withAnimation(Theme.Motion.Policy(reduced: reduced).animation(Theme.Motion.standard)) {
                            navigation.openTraining()
                        }
                    }
                )
                .transition(.opacity)

            case .library(let target):
                LibraryScreen(
                    launchTarget: target,
                    onHome: {
                        withAnimation(Theme.Motion.Policy(reduced: reduced).animation(Theme.Motion.standard)) {
                            navigation.openHome()
                        }
                    }
                )
                .transition(.opacity)

            case .training:
                TrainingScreen(
                    onHome: {
                        withAnimation(Theme.Motion.Policy(reduced: reduced).animation(Theme.Motion.standard)) {
                            navigation.openHome()
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(Theme.Motion.Policy(reduced: reduced).animation(Theme.Motion.standard), value: navigation.route)
    }
}
