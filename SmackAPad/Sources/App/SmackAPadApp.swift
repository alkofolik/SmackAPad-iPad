import SwiftUI
import UserNotifications

@main
@MainActor
struct SmackAPadApp: App {
    @State private var store = StoreManager.shared
    @State private var settings = SettingsManager.shared
    @State private var progress = ProgressStore.shared
    @State private var progression = ProgressionManager.shared
    @State private var badges = BadgeStore.shared
    @State private var midi = MIDIInput(settings: .shared)
    @State private var showProgressLoadError = ProgressStore.shared.lastLoadError != nil
    @State private var showProgressBackupError = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        SettingsManager.shared.appearance.applyToWindows()
        UNUserNotificationCenter.current().delegate = ReviewReminderDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(settings.languagePreference)
                .tint(Theme.ink)
                .environment(store)
                .environment(settings)
                .environment(progress)
                .environment(progression)
                .environment(badges)
                .environment(midi)
                .environment(\.locale, Locale(identifier: settings.languagePreference.rawValue))
                .alert(settings.localized("Saved progress could not be read"), isPresented: $showProgressLoadError) {
                    Button(settings.localized("Start with empty progress"), role: .destructive) {
                        do {
                            try progress.startWithEmptyProgress()
                        } catch {
                            showProgressBackupError = true
                        }
                    }
                    Button(settings.localized("Not now"), role: .cancel) { }
                } message: {
                    if progress.hasUnreadableProgressBackup {
                        Text(settings.localized("Your saved progress could not be read. A copy of the file was kept. Progress will not be saved until you choose an option."))
                    } else {
                        Text(settings.localized("Your original progress file has not been changed. Progress will not be saved. Try again next time you open the app."))
                    }
                }
                .overlay {
                    Color.clear.frame(width: 0, height: 0)
                        .alert(settings.localized("Progress backup could not be kept"), isPresented: $showProgressBackupError) {
                            Button(settings.localized("OK"), role: .cancel) { }
                        } message: {
                            Text(settings.localized("Your original progress file has not been changed. Progress will not be saved. Try again next time you open the app."))
                        }
                }
                .onAppear {
                    settings.appearance.applyToWindows()
                }
                .task {
                    settings.appearance.applyToWindows()
                    store.start()
                    midi.start()
                    badges.awardSilently(progress: progress.records, catalog: progression.catalog, trainingLog: progress.trainingLog)
                    ReviewReminderScheduler.shared.reschedule()
                }
                .onChange(of: settings.appearance) { _, appearance in
                    appearance.applyToWindows()
                }
                .onChange(of: settings.activeProfileName) { _, _ in midi.profileDidChange() }
                .onChange(of: settings.languagePreference) { _, _ in
                    ReviewReminderScheduler.shared.reschedule()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background {
                        midi.stop()
                        ReviewReminderScheduler.shared.reschedule()
                    } else if phase == .active {
                        settings.appearance.applyToWindows()
                        midi.start()
                        Task { await store.refreshEntitlements() }
                    }
                }
        }
    }
}
