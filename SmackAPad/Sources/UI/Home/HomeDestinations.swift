import SwiftUI

/// Destinations opened from Home pads with pad-to-screen zoom navigation transition (ticket 113).
enum HomePadDestination: Identifiable, Equatable {
    case continueToLesson(Lesson)
    case continueToLibrary
    case library(LibraryLaunchTarget)
    case training
    case intro
    case controller
    case badges
    case purchases
    case settings
    case about

    var id: String {
        switch self {
        case .continueToLesson, .continueToLibrary: return "pad-continue"
        case .library: return "pad-library"
        case .training: return "pad-training"
        case .intro: return "pad-intro"
        case .controller: return "pad-controller"
        case .badges: return "pad-badges"
        case .purchases: return "pad-purchases"
        case .settings: return "pad-settings"
        case .about: return "pad-about"
        }
    }

    var libraryTarget: LibraryLaunchTarget? {
        switch self {
        case .continueToLesson(let lesson): return .lesson(lesson)
        case .continueToLibrary: return LibraryLaunchTarget.none
        case .library(let target): return target
        case .intro: return .intro
        default: return nil
        }
    }
}

/// Renders the destination screen for a tapped Home pad with shared environment objects.
struct HomeDestinationView: View {
    let destination: HomePadDestination
    let onReviewOpen: (Int) -> Void
    let onClearDestination: () -> Void

    @Environment(StoreManager.self) private var store
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(ProgressionManager.self) private var progression
    @Environment(BadgeStore.self) private var badgeStore
    @Environment(MIDIInput.self) private var midi

    var body: some View {
        Group {
            switch destination {
            case .continueToLesson, .continueToLibrary, .library, .intro:
                let target = destination.libraryTarget ?? .none
                let initialProgress = switch target {
                case .lesson(let lesson): progress.progress(for: lesson.id)
                default: nil as LessonProgress?
                }
                LibraryScreen(
                    launchTarget: target,
                    initialProgress: initialProgress,
                    onReviewOpen: onReviewOpen,
                    onHome: {
                        onClearDestination()
                        AppNavigation.shared.openHome()
                    }
                )

            case .training:
                TrainingScreen(
                    onHome: {
                        onClearDestination()
                        AppNavigation.shared.openHome()
                    }
                )

            case .controller:
                NavigationStack {
                    ControllerSetupView(onDismiss: onClearDestination)
                }

            case .badges:
                BadgesView(onDismiss: onClearDestination)

            case .purchases:
                PurchaseSheet(onDismiss: onClearDestination)

            case .settings:
                SettingsView(onDismiss: onClearDestination)

            case .about:
                NavigationStack {
                    AboutDetailView(onDismiss: onClearDestination)
                }
            }
        }
        .environment(store)
        .environment(settings)
        .environment(progress)
        .environment(progression)
        .environment(badgeStore)
        .environment(midi)
    }
}
