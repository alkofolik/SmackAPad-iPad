import SwiftUI

@main
struct SmackAPadApp: App {
    @State private var settings = SettingsManager.shared
    @State private var progress = ProgressStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settings)
                .environment(progress)
        }
    }
}
