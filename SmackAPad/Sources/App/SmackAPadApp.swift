import SwiftUI

@main
@MainActor
struct SmackAPadApp: App {
    @State private var store = StoreManager.shared
    @State private var settings = SettingsManager.shared
    @State private var progress = ProgressStore.shared
    @State private var progression = ProgressionManager.shared
    @State private var midi = MIDIInput(settings: .shared)
    @AppStorage("smackapad.practice.appearance") private var appearance = "dark"
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(settings.languagePreference)
                .preferredColorScheme(appearance == "light" ? .light : .dark)
                .tint(Theme.ink)
                .environment(store)
                .environment(settings)
                .environment(progress)
                .environment(progression)
                .environment(midi)
                .environment(\.locale, Locale(identifier: settings.languagePreference.rawValue))
                .task { store.start(); midi.start() }
                .onChange(of: settings.activeProfileName) { _, _ in midi.profileDidChange() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background { midi.stop() }
                    else if phase == .active {
                        midi.start()
                        Task { await store.refreshEntitlements() }
                    }
                }
        }
    }
}
