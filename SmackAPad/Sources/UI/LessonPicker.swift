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

    var body: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-practice"),
           let lesson = LessonStore.shared.libraryCatalog.path.first {
            if ProcessInfo.processInfo.arguments.contains("-landscape") {
                PracticeScreen(lesson: lesson, settings: settings, progress: progress, midi: midi)
                    .frame(width: 1194, height: 834)
                    .rotationEffect(.degrees(90))
                    .frame(width: 834, height: 1194)
            } else {
                PracticeScreen(lesson: lesson, settings: settings, progress: progress, midi: midi)
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
