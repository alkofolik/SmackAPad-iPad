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
    @State private var route: AppRoute = .home
    @State private var hasPlayedColdStartAnimation = false
    @Environment(\.accessibilityReduceMotion) private var reduced

    var body: some View {
        ZStack {
            switch route {
            case .home:
                HomeScreen(
                    isColdStart: !hasPlayedColdStartAnimation,
                    onColdStartFinished: {
                        hasPlayedColdStartAnimation = true
                    },
                    onNavigateToLibrary: { target in
                        withAnimation(Theme.Motion.Policy(reduced: reduced).animation(Theme.Motion.standard)) {
                            route = .library(target)
                        }
                    },
                    onNavigateToTraining: {
                        withAnimation(Theme.Motion.Policy(reduced: reduced).animation(Theme.Motion.standard)) {
                            route = .training
                        }
                    }
                )
                .transition(.opacity)

            case .library(let target):
                LibraryScreen(
                    launchTarget: target,
                    onHome: {
                        withAnimation(Theme.Motion.Policy(reduced: reduced).animation(Theme.Motion.standard)) {
                            route = .home
                        }
                    }
                )
                .transition(.opacity)

            case .training:
                TrainingScreen(
                    onHome: {
                        withAnimation(Theme.Motion.Policy(reduced: reduced).animation(Theme.Motion.standard)) {
                            route = .home
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(Theme.Motion.Policy(reduced: reduced).animation(Theme.Motion.standard), value: route)
    }
}
