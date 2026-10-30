import SwiftUI

@main
@MainActor
struct SmackAPadApp: App {
    @State private var settings = SettingsManager.shared
    @State private var progress = ProgressStore.shared
    @State private var midi = MIDIInput(settings: .shared)
    @AppStorage("smackapad.practice.appearance") private var appearance = "dark"
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearance == "light" ? .light : .dark)
                .tint(Theme.ink)
                .environment(settings)
                .environment(progress)
                .environment(midi)
                .environment(\.locale, Locale(identifier: settings.languagePreference.rawValue))
                .task { midi.start() }
                .onChange(of: settings.activeProfileName) { _, _ in midi.profileDidChange() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background { midi.stop() }
                    else if phase == .active { midi.start() }
                }
        }
    }
}
