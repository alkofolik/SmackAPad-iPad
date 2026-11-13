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
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(MIDIInput.self) private var midi
    @Environment(StoreManager.self) private var store
    @Environment(ProgressionManager.self) private var progression
    @Environment(BadgeStore.self) private var badgeStore

    var body: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-light") {
            let _ = {
                if settings.appearance != .light {
                    settings.appearance = .light
                    settings.appearance.applyToWindows()
                }
            }()
        } else if ProcessInfo.processInfo.arguments.contains("-dark") {
            let _ = {
                if settings.appearance != .dark {
                    settings.appearance = .dark
                    settings.appearance.applyToWindows()
                }
            }()
        }

        if ProcessInfo.processInfo.arguments.contains("-library") {
            let target = LibraryScreen(launchTarget: .none)
            if ProcessInfo.processInfo.arguments.contains("-landscape") {
                target
                    .frame(width: 1194, height: 834)
                    .rotationEffect(.degrees(90))
                    .frame(width: 834, height: 1194)
            } else {
                target
            }
        } else if ProcessInfo.processInfo.arguments.contains("-training") || ProcessInfo.processInfo.arguments.contains("-today") {
            let target = TrainingScreen()
            if ProcessInfo.processInfo.arguments.contains("-landscape") {
                target
                    .frame(width: 1194, height: 834)
                    .rotationEffect(.degrees(90))
                    .frame(width: 834, height: 1194)
            } else {
                target
            }
        } else if ProcessInfo.processInfo.arguments.contains("-practice"),
           let lesson = LessonStore.shared.libraryCatalog.path.first {
            if ProcessInfo.processInfo.arguments.contains("-landscape") {
                PracticeScreen(lesson: lesson, settings: settings, progress: progress, midi: midi)
                    .frame(width: 1194, height: 834)
                    .rotationEffect(.degrees(90))
                    .frame(width: 834, height: 1194)
            } else {
                PracticeScreen(lesson: lesson, settings: settings, progress: progress, midi: midi)
            }
        } else if ProcessInfo.processInfo.arguments.contains("-badges") {
            let target = BadgesView()
            if ProcessInfo.processInfo.arguments.contains("-landscape") {
                target
                    .frame(width: 1194, height: 834)
                    .rotationEffect(.degrees(90))
                    .frame(width: 834, height: 1194)
            } else {
                target
            }
        } else if ProcessInfo.processInfo.arguments.contains("-settings") {
            let target = SettingsView()
            if ProcessInfo.processInfo.arguments.contains("-landscape") {
                target
                    .frame(width: 1194, height: 834)
                    .rotationEffect(.degrees(90))
                    .frame(width: 834, height: 1194)
            } else {
                target
            }
        } else if ProcessInfo.processInfo.arguments.contains("-about") {
            let target = NavigationStack { AboutDetailView() }
            if ProcessInfo.processInfo.arguments.contains("-landscape") {
                target
                    .frame(width: 1194, height: 834)
                    .rotationEffect(.degrees(90))
                    .frame(width: 834, height: 1194)
            } else {
                target
            }
        } else if ProcessInfo.processInfo.arguments.contains("-purchases") {
            let target = PurchaseSheet()
            if ProcessInfo.processInfo.arguments.contains("-landscape") {
                target
                    .frame(width: 1194, height: 834)
                    .rotationEffect(.degrees(90))
                    .frame(width: 834, height: 1194)
            } else {
                target
            }
        } else if ProcessInfo.processInfo.arguments.contains("-controller") {
            let target = NavigationStack { ControllerSetupView() }
            if ProcessInfo.processInfo.arguments.contains("-landscape") {
                target
                    .frame(width: 1194, height: 834)
                    .rotationEffect(.degrees(90))
                    .frame(width: 834, height: 1194)
            } else {
                target
            }
        } else if ProcessInfo.processInfo.arguments.contains("-calibration") {
            let target = NavigationStack { CalibrationView(settings: settings, midi: midi) }
            if ProcessInfo.processInfo.arguments.contains("-landscape") {
                target
                    .frame(width: 1194, height: 834)
                    .rotationEffect(.degrees(90))
                    .frame(width: 834, height: 1194)
            } else {
                target
            }
        } else if ProcessInfo.processInfo.arguments.contains("-intro") {
            let target = NavigationStack { IntroScreen(onSelect: { _ in }) }
            if ProcessInfo.processInfo.arguments.contains("-landscape") {
                target
                    .frame(width: 1194, height: 834)
                    .rotationEffect(.degrees(90))
                    .frame(width: 834, height: 1194)
            } else {
                target
            }
        } else {
            homeView
        }
        #else
        homeView
        #endif
    }

    private var homeView: some View {
        HomeScreen(
            isColdStart: !hasPlayedColdStartAnimation,
            onColdStartFinished: {
                hasPlayedColdStartAnimation = true
            }
        )
    }
}
