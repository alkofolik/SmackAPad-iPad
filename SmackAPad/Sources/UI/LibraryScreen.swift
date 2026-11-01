import SwiftUI

/// Main lesson library screen for browsing categories, filtering by genre,
/// tracking pass/mastery progress, and managing category progression.
@MainActor
struct LibraryScreen: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(ProgressionManager.self) private var progression
    @Environment(MIDIInput.self) private var midi

    @State private var lessonStore = LessonStore.shared
    @State private var selectedCategoryId: String = CategoryOrder.initialUnlockedCategory
    @State private var selectedGenre: String? = nil
    @State private var searchQuery: String = ""
    @State private var selectedLesson: Lesson? = nil
    @State private var showingMIDI: Bool = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarView
                .navigationTitle(settings.localized("Library"))
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 380)
        } detail: {
            detailContent
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(settings.localized("Settings")) { showingMIDI = true }
                            .font(Theme.text())
                            .frame(minHeight: Theme.Size.touch)
                    }
                }
        }
        .navigationSplitViewStyle(.balanced)
        .background(Theme.background)
        .foregroundStyle(Theme.ink)
        .softUnlockAlert(progression: progression) { unlockedCategory in
            selectedCategoryId = unlockedCategory
            selectedGenre = nil
        }
        .sheet(isPresented: $showingMIDI) {
            MIDISettingsView().presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: $selectedLesson) { lesson in
            PracticeScreen(lesson: lesson, settings: settings, progress: progress, midi: midi)
        }
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        List {
            // Task 5: Intro section as a separate entry point (always accessible)
            Section {
                introCategoryRow
            } header: {
                Text(settings.localized("Intro"))
                    .font(Theme.display(Theme.Size.small))
                    .foregroundStyle(Theme.secondary)
            }

            // Task 1: Category list with lock/unlock state from ProgressionManager
            Section {
                ForEach(progression.categoryOrder, id: \.self) { categoryId in
                    categoryRow(for: categoryId)
                }
            } header: {
                Text(settings.localized("Progression categories"))
                    .font(Theme.display(Theme.Size.small))
                    .foregroundStyle(Theme.secondary)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
    }

    private var introCategoryRow: some View {
        let isSelected = selectedCategoryId == ProgressionConstant.introCategoryId
        let passed = progression.passedLessonCount(in: ProgressionConstant.introCategoryId)
        let total = progression.totalLessonCount(in: ProgressionConstant.introCategoryId)

        return Button {
            selectedCategoryId = ProgressionConstant.introCategoryId
            selectedGenre = nil
        } label: {
            HStack(spacing: Theme.Space.regular) {
                VStack(alignment: .leading, spacing: Theme.Space.tight) {
                    Text(progression.title(for: ProgressionConstant.introCategoryId))
                        .font(Theme.display(Theme.Size.body))
                        .foregroundStyle(isSelected ? Theme.orange : Theme.ink)
                    Text(settings.localized("24 exercises · always open"))
                        .font(Theme.text(Theme.Size.dense))
                        .foregroundStyle(Theme.secondary)
                }
                Spacer(minLength: Theme.Space.small)
                Text("\(passed)/\(total)")
                    .font(Theme.text(Theme.Size.small))
                    .foregroundStyle(passed >= total && total > 0 ? Theme.orange : Theme.secondary)
            }
            .padding(.vertical, Theme.Space.small)
            .frame(minHeight: Theme.Size.touch)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(isSelected ? Theme.surface : Theme.background)
    }

    private func categoryRow(for categoryId: String) -> some View {
        let status = progression.status(for: categoryId)
        let isSelected = selectedCategoryId == categoryId
        let isUnlocked = status.isUnlocked

        return Button {
            if isUnlocked {
                selectedCategoryId = categoryId
                selectedGenre = nil
            } else {
                // Task 3: Soft-unlock tap → confirmation → immediate unlock
                progression.requestSoftUnlock(for: categoryId)
            }
        } label: {
            HStack(spacing: Theme.Space.regular) {
                VStack(alignment: .leading, spacing: Theme.Space.tight) {
                    Text(status.title)
                        .font(Theme.display(Theme.Size.body))
                        .foregroundStyle(isSelected ? Theme.orange : (isUnlocked ? Theme.ink : Theme.secondary))

                    if isUnlocked {
                        if status.isSoftUnlocked {
                            Text(settings.localized("%lld/%lld · soft unlocked", status.passedCount, status.totalCount))
                                .font(Theme.text(Theme.Size.dense))
                                .foregroundStyle(Theme.secondary)
                        } else {
                            Text(settings.localized("%lld/%lld passed", status.passedCount, status.totalCount))
                                .font(Theme.text(Theme.Size.dense))
                                .foregroundStyle(Theme.secondary)
                        }
                    } else {
                        Text(settings.localized("Locked (5 to unlock)"))
                            .font(Theme.text(Theme.Size.dense))
                            .foregroundStyle(Theme.secondary)
                    }
                }

                Spacer(minLength: Theme.Space.small)

                // Task 3: Locked categories shown with lock icon
                if !isUnlocked {
                    PracticeGlyph(kind: .lock)
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Theme.orange)
                } else if status.passedCount >= status.totalCount && status.totalCount > 0 {
                    Text("✓")
                        .font(Theme.display(Theme.Size.small))
                        .foregroundStyle(Theme.orange)
                } else {
                    Text("\(status.passedCount)")
                        .font(Theme.text(Theme.Size.small))
                        .foregroundStyle(Theme.secondary)
                }
            }
            .padding(.vertical, Theme.Space.small)
            .frame(minHeight: Theme.Size.touch)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(isSelected ? Theme.surface : Theme.background)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailContent: some View {
        if selectedCategoryId == ProgressionConstant.introCategoryId {
            IntroScreen { selectedLesson = $0 }
        } else {
            detailView
        }
    }

    private var detailView: some View {
        let isUnlocked = progression.isCategoryUnlocked(selectedCategoryId)
        let lessons = categoryLessons(for: selectedCategoryId)
        let filteredLessons = filteredLessons(from: lessons)
        let genres = availableGenres(for: lessons)

        return VStack(spacing: 0) {
            if let error = lessonStore.lastLoadError {
                HStack {
                    Text(error.localizedDescription)
                        .font(Theme.text(Theme.Size.small))
                        .foregroundStyle(.red)
                    Spacer()
                    Button(settings.localized("Reload")) { try? lessonStore.reload() }
                        .font(Theme.text())
                }
                .padding(Theme.Space.small)
            }

            if !isUnlocked {
                lockedCategoryBanner(for: selectedCategoryId)
            }

            // Category Header
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                HStack(alignment: .firstTextBaseline) {
                    Text(progression.title(for: selectedCategoryId))
                        .font(Theme.display(Theme.Size.title))
                        .foregroundStyle(Theme.ink)

                    Spacer()

                    let passed = progression.passedLessonCount(in: selectedCategoryId)
                    let total = progression.totalLessonCount(in: selectedCategoryId)
                    Text(settings.localized("%lld / %lld PASSED", passed, total))
                        .font(Theme.text(Theme.Size.small))
                        .foregroundStyle(Theme.secondary)
                }

                // Task 1 & SPEC §3.8: Browse by category / genre
                if genres.count > 1 {
                    genreFilterBar(genres: genres)
                }
            }
            .padding(.horizontal, Theme.Space.page)
            .padding(.top, Theme.Space.regular)
            .padding(.bottom, Theme.Space.small)
            .background(Theme.background)

            Divider().overlay(Theme.surface)

            // Lesson List
            List {
                if filteredLessons.isEmpty {
                    VStack(alignment: .center, spacing: Theme.Space.regular) {
                        Text(settings.localized("No matching lessons"))
                            .font(Theme.display(Theme.Size.emphasis))
                            .foregroundStyle(Theme.secondary)
                        if !searchQuery.isEmpty || selectedGenre != nil {
                            Button(settings.localized("Clear filters")) {
                                searchQuery = ""
                                selectedGenre = nil
                            }
                            .font(Theme.text())
                            .foregroundStyle(Theme.orange)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Theme.Space.wide)
                    .listRowBackground(Theme.background)
                } else {
                    ForEach(filteredLessons) { lesson in
                        LibraryLessonRow(
                            lesson: lesson,
                            settings: settings,
                            progress: progress
                        ) {
                            if isUnlocked {
                                selectedLesson = lesson
                            } else {
                                progression.requestSoftUnlock(for: selectedCategoryId)
                            }
                        }
                        .listRowBackground(Theme.background)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .searchable(
                text: $searchQuery,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: Text(settings.localized("Search lessons..."))
            )
        }
        .background(Theme.background)
    }

    private func lockedCategoryBanner(for categoryId: String) -> some View {
        HStack(spacing: Theme.Space.regular) {
            PracticeGlyph(kind: .lock)
                .frame(width: 24, height: 24)
                .foregroundStyle(Theme.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(settings.localized("Category is locked"))
                    .font(Theme.display(Theme.Size.body))
                    .foregroundStyle(Theme.ink)
                Text(settings.localized("Tap to unlock immediately and practice."))
                    .font(Theme.text(Theme.Size.dense))
                    .foregroundStyle(Theme.secondary)
            }

            Spacer()

            Button(settings.localized("Unlock")) {
                progression.requestSoftUnlock(for: categoryId)
            }
            .font(Theme.display(Theme.Size.small))
            .foregroundStyle(Theme.background)
            .padding(.horizontal, Theme.Space.regular)
            .frame(minHeight: Theme.Size.touch)
            .background(Theme.orange)
        }
        .padding(.horizontal, Theme.Space.page)
        .padding(.vertical, Theme.Space.small)
        .background(Theme.surface)
        .overlay(Rectangle().stroke(Theme.orange, lineWidth: 1))
    }

    private func genreFilterBar(genres: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Space.small) {
                genreChip(
                    title: settings.localized("All"),
                    isSelected: selectedGenre == nil
                ) {
                    selectedGenre = nil
                }

                ForEach(genres, id: \.self) { genre in
                    genreChip(
                        title: genre,
                        isSelected: selectedGenre == genre
                    ) {
                        selectedGenre = (selectedGenre == genre ? nil : genre)
                    }
                }
            }
            .padding(.vertical, Theme.Space.tight)
        }
    }

    private func genreChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.text(Theme.Size.small))
                .foregroundStyle(isSelected ? Theme.background : Theme.ink)
                .padding(.horizontal, Theme.Space.regular)
                .frame(minHeight: 36)
                .background(isSelected ? Theme.ink : Theme.surface)
                .overlay(
                    Rectangle()
                        .stroke(isSelected ? Theme.ink : Theme.secondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Query Helpers

    private func categoryLessons(for categoryId: String) -> [Lesson] {
        progression.lessons(in: categoryId).sorted { $0.id < $1.id }
    }

    private func availableGenres(for lessons: [Lesson]) -> [String] {
        Array(Set(lessons.map(\.genre))).filter { !$0.isEmpty }.sorted()
    }

    private func filteredLessons(from lessons: [Lesson]) -> [Lesson] {
        lessons.filter { lesson in
            let matchesGenre = (selectedGenre == nil || lesson.genre == selectedGenre)
            let matchesSearch = searchQuery.isEmpty ||
                lesson.title.localizedCaseInsensitiveContains(searchQuery) ||
                lesson.genre.localizedCaseInsensitiveContains(searchQuery) ||
                lesson.tags.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            return matchesGenre && matchesSearch
        }
    }
}

// MARK: - LibraryLessonRow

struct LibraryLessonRow: View {
    let lesson: Lesson
    let settings: SettingsManager
    let progress: ProgressStore
    let onSelect: () -> Void

    private var progressRecord: LessonProgress? {
        progress.progress(for: lesson.id)
    }

    private var isPassed: Bool {
        progressRecord?.passed ?? false
    }

    private var isMastered: Bool {
        progressRecord?.mastery ?? false
    }

    private var isMemory: Bool {
        progressRecord?.memory ?? false
    }

    private var isEightPadMode: Bool {
        settings.activeProfile().isEightPad
    }

    private var hasEightPadLayout: Bool {
        EightPadLayout.slots(for: lesson) != nil
    }

    /// Task 4: Show greyed-out "requires 16 pads" label only for a lesson whose EightPadLayout is nil in 8-pad mode.
    private var showRequires16Pads: Bool {
        isEightPadMode && !hasEightPadLayout
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: Theme.Space.regular) {
                // Left column: Title and metadata (Task 2)
                VStack(alignment: .leading, spacing: Theme.Space.tight) {
                    HStack(spacing: Theme.Space.small) {
                        Text(lesson.title)
                            .font(Theme.display(Theme.Size.listTitle))
                            .foregroundStyle(showRequires16Pads ? Theme.secondary : Theme.ink)

                        if showRequires16Pads {
                            Text(settings.localized("REQUIRES 16 PADS"))
                                .font(Theme.text(Theme.Size.dense))
                                .foregroundStyle(Theme.orange)
                                .padding(.horizontal, Theme.Space.tight)
                                .padding(.vertical, 2)
                                .overlay(Rectangle().stroke(Theme.orange, lineWidth: 1))
                        }
                    }

                    HStack(spacing: Theme.Space.small) {
                        if !lesson.genre.isEmpty {
                            Text(lesson.genre)
                                .font(Theme.text(Theme.Size.small))
                                .foregroundStyle(Theme.ink)
                            Text("·")
                                .font(Theme.text(Theme.Size.small))
                                .foregroundStyle(Theme.secondary)
                        }

                        Text(settings.localized("Level %lld", lesson.level))
                            .font(Theme.text(Theme.Size.small))
                            .foregroundStyle(Theme.secondary)

                        Text("·")
                            .font(Theme.text(Theme.Size.small))
                            .foregroundStyle(Theme.secondary)

                        Text("\(lesson.startBpm) → \(lesson.targetBpm) BPM")
                            .font(Theme.text(Theme.Size.small))
                            .foregroundStyle(Theme.secondary)
                    }
                }

                Spacer(minLength: Theme.Space.regular)

                // Right column: Pass / Mastery status badge & stars (Task 2)
                HStack(spacing: Theme.Space.regular) {
                    if isMastered {
                        Text(settings.localized("MASTERY"))
                            .font(Theme.display(Theme.Size.dense))
                            .foregroundStyle(Theme.background)
                            .padding(.horizontal, Theme.Space.small)
                            .padding(.vertical, 4)
                            .background(Theme.orange)
                    } else if isPassed {
                        Text(settings.localized("PASSED"))
                            .font(Theme.display(Theme.Size.dense))
                            .foregroundStyle(Theme.background)
                            .padding(.horizontal, Theme.Space.small)
                            .padding(.vertical, 4)
                            .background(Theme.ink)
                    }

                    HStack(spacing: Theme.Space.tight) {
                        starView(earned: isPassed, label: settings.localized("Passed"))
                        starView(earned: isMastered, label: settings.localized("Mastery"))
                        starView(earned: isMemory, label: settings.localized("Memory"))
                    }
                }
            }
            .padding(.vertical, Theme.Space.small)
            .frame(minHeight: Theme.Size.touch)
            .contentShape(Rectangle())
            .opacity(showRequires16Pads ? 0.45 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private func starView(earned: Bool, label: String) -> some View {
        StarShape()
            .fill(earned ? Theme.orange : Theme.background)
            .overlay(StarShape().stroke(Theme.ink, lineWidth: Theme.Size.border))
            .frame(width: 18, height: 18)
            .accessibilityLabel(label)
            .accessibilityValue(settings.localized(earned ? "earned" : "not earned"))
    }
}
