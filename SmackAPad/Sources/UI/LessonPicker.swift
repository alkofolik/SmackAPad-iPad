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

    private var introLessons: [Lesson] {
        store.lessons.filter { $0.cat == "intro" }
            .sorted { ($0.intro?.number ?? $0.id) < ($1.intro?.number ?? $1.id) }
    }

    private var nonIntroLessons: [Lesson] {
        store.lessons.filter { $0.cat != "intro" }
            .sorted { $0.id < $1.id }
    }

    private var searchResults: [Lesson] {
        store.lessons.filter {
            $0.title.localizedCaseInsensitiveContains(search) || $0.cat.localizedCaseInsensitiveContains(search)
        }
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

                if search.isEmpty {
                    // Separate entry point for intro exercises, always accessible
                    Section {
                        NavigationLink {
                            IntroScreen()
                        } label: {
                            HStack(spacing: Theme.Space.regular) {
                                VStack(alignment: .leading, spacing: Theme.Space.tight) {
                                    HStack(spacing: Theme.Space.small) {
                                        Text(czech ? "ÚVODNÍ CVIČENÍ" : "INTRO EXERCISES")
                                            .font(Theme.display(Theme.Size.listTitle))
                                            .foregroundStyle(Theme.ink)

                                        Text(czech ? "24 lekcí" : "24 exercises")
                                            .font(Theme.text(Theme.Size.dense))
                                            .padding(.horizontal, Theme.Space.small)
                                            .padding(.vertical, Theme.Space.tight)
                                            .background(Theme.orange)
                                            .foregroundStyle(Theme.black)
                                    }

                                    Text(czech ? "Základy rytmu, pulsu a koordinace · Vždy přístupné" : "Fundamentals of rhythm, pulse & coordination · Always accessible")
                                        .font(Theme.text(Theme.Size.small))
                                        .foregroundStyle(Theme.secondary)

                                    Text(czech ? "Přísnější pravidla (≥80 % pro splnění, 0 chyb pro mistrovství)" : "Stricter rules (≥80% to pass, 0 errors for mastery)")
                                        .font(Theme.text(Theme.Size.dense))
                                        .foregroundStyle(Theme.secondary)
                                }

                                Spacer()

                                let passedCount = introLessons.filter { progress.isPassed(lessonId: $0.id) }.count
                                VStack(alignment: .trailing, spacing: Theme.Space.tight) {
                                    Text("\(passedCount)/\(introLessons.count)")
                                        .font(Theme.display(Theme.Size.body))
                                        .foregroundStyle(Theme.ink)
                                    Text(czech ? "splněno" : "passed")
                                        .font(Theme.text(Theme.Size.dense))
                                        .foregroundStyle(Theme.secondary)
                                }
                            }
                            .padding(.vertical, Theme.Space.small)
                        }
                        .listRowBackground(Theme.surface)
                    } header: {
                        Text(czech ? "Úvodní sekce" : "Intro Section")
                            .font(Theme.text(Theme.Size.small))
                            .foregroundStyle(Theme.secondary)
                    }

                    // Main lesson library
                    Section {
                        ForEach(nonIntroLessons) { lesson in
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
                    } header: {
                        Text(czech ? "Knihovna lekcí" : "Lesson Library")
                            .font(Theme.text(Theme.Size.small))
                            .foregroundStyle(Theme.secondary)
                    }
                } else {
                    // Search results across all lessons
                    ForEach(searchResults) { lesson in
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
