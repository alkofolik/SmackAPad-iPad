import SwiftUI

/// Minimal entry point for the play screen; the full Home/Library flow has its own ticket.
@MainActor
struct ContentView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(MIDIInput.self) private var midi
    @State private var store = LessonStore.shared
    @State private var search = ""
    @State private var showingMIDI = false

    private var czech: Bool { settings.languagePreference == .czech }
    private var lessons: [Lesson] {
        store.lessons.filter { search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) || $0.cat.localizedCaseInsensitiveContains(search) }
            .sorted { lhs, rhs in
                if (lhs.cat == "intro") != (rhs.cat == "intro") { return lhs.cat == "intro" }
                return lhs.id < rhs.id
            }
    }

    var body: some View {
        NavigationStack {
            List {
                if let error = store.lastLoadError {
                    Text(error.localizedDescription)
                    Button(czech ? "Načíst znovu" : "Reload") { try? store.reload() }
                }
                ForEach(lessons) { lesson in
                    NavigationLink {
                        PracticeScreen(lesson: lesson, settings: settings, progress: progress, midi: midi)
                    } label: {
                        VStack(alignment: .leading, spacing: Theme.Space.small) {
                            Text(lesson.title).font(Theme.display(Theme.Size.listTitle))
                            Text("\(lesson.cat) · \(lesson.startBpm) → \(lesson.targetBpm) BPM")
                                .font(Theme.text(Theme.Size.small)).foregroundStyle(Theme.secondary)
                        }
                        .padding(.vertical, Theme.Space.small)
                    }
                    .listRowBackground(Theme.background)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .foregroundStyle(Theme.ink)
            .searchable(text: $search, prompt: czech ? "Najít lekci" : "Find a lesson")
            .navigationTitle("Smack-a-Pad")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("MIDI") { showingMIDI = true }.font(Theme.text()).frame(minHeight: Theme.Size.touch)
                }
            }
            .sheet(isPresented: $showingMIDI) { MIDISettingsView().presentationDragIndicator(.visible) }
        }
    }
}
