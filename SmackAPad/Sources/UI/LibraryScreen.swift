import SwiftUI

/// Three projections of the same catalogue, sharing stage access and saved progress.
@MainActor
struct LibraryScreen: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(ProgressionManager.self) private var progression
    @Environment(MIDIInput.self) private var midi
    @State private var lessonStore = LessonStore.shared
    @State private var selections: [String: String] = [:]
    @State private var expandedLevels: Set<Int> = [1]
    @State private var showingIntro = false
    @State private var cross = ""
    @State private var query = ""
    @State private var selectedLesson: Lesson?
    @State private var showingSettings = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private var mode: LibraryViewMode { LibraryViewMode(rawValue: settings.libraryView) ?? .path }
    private var catalog: LibraryCatalog { progression.catalog }
    private var groups: [LibraryGroup] { catalog.groups(in: mode) }
    private var group: LibraryGroup? { groups.first { $0.id == selections[mode.id] } ?? groups.first }
    private var next: Lesson? {
        progression.nextLesson(after: lessonStore.lesson(for: settings.lastLessonID),
                               source: NextLessonSource(rawValue: settings.nextLessonSource) ?? .path)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar.navigationTitle(settings.localized("Library"))
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 380)
        } detail: {
            Group {
                if showingIntro { IntroScreen { selectedLesson = $0 } }
                else if let group { detail(group) }
                else { Text(settings.localized("No matching lessons")) }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(settings.localized("Settings")) { showingSettings = true }
                        .font(Theme.text()).frame(minHeight: Theme.Size.touch)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .background(Theme.background).foregroundStyle(Theme.ink).tint(Theme.orange)
        .softUnlockAlert(progression: progression) { stage in
            settings.libraryView = LibraryViewMode.path.id
            selections[LibraryViewMode.path.id] = stage
            showingIntro = false
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .fullScreenCover(item: $selectedLesson) { lesson in
            PracticeScreen(lesson: lesson, settings: settings, progress: progress, midi: midi)
        }
        .onChange(of: settings.libraryView) { _, _ in query = ""; cross = ""; showingIntro = false }
    }

    private var sidebar: some View {
        List {
            Section {
                Button {
                    showingIntro = true
                } label: {
                    VStack(alignment: .leading, spacing: Theme.Space.tight) {
                        Text(settings.localized("Intro exercises")).font(Theme.display(Theme.Size.body))
                        Text(settings.localized("24 exercises · always open")).font(Theme.text(Theme.Size.dense))
                        groupProgress(lessonStore.lessons.filter { $0.cat == "intro" })
                    }
                    .foregroundStyle(Theme.ink).frame(minHeight: Theme.Size.touch)
                }
                .listRowBackground(showingIntro ? Theme.surface : Theme.background)
            }
            Section {
                Picker(settings.localized("Organise by"), selection: Binding(
                    get: { settings.libraryView }, set: { settings.libraryView = $0 }
                )) {
                    ForEach(LibraryViewMode.allCases) { view in Text(settings.localized(view.title)).tag(view.id) }
                }
                .pickerStyle(.segmented).frame(minHeight: Theme.Size.touch)
                if mode == .path {
                    ForEach(1...5, id: \.self) { level in
                        DisclosureGroup(isExpanded: Binding(
                            get: { expandedLevels.contains(level) },
                            set: { if $0 { expandedLevels.insert(level) } else { expandedLevels.remove(level) } }
                        )) {
                            ForEach(groups.filter { $0.stage?.level == level }) { sidebarRow($0) }
                        } label: {
                            VStack(alignment: .leading, spacing: Theme.Space.tight) {
                                Text(settings.localized("Level %lld", level)).font(Theme.display(Theme.Size.body))
                                groupProgress(catalog.path.filter { $0.level == level })
                            }.frame(minHeight: Theme.Size.touch)
                        }
                    }
                } else {
                    ForEach(groups.filter { !$0.isExtension }) { sidebarRow($0) }
                }
            } header: { Text(settings.localized("Organise by")) }
            if groups.contains(where: \.isExtension) {
                Section {
                    ForEach(groups.filter(\.isExtension)) { sidebarRow($0) }
                } header: { Text(settings.localized("Extensions · outside the Path")) }
            }
        }
        .listStyle(.sidebar).scrollContentBackground(.hidden).background(Theme.background)
    }

    private func sidebarRow(_ item: LibraryGroup) -> some View {
        let selected = !showingIntro && group?.id == item.id
        let locked = item.stage.map { !progression.isStageOpen($0) } ?? false
        return Button {
            showingIntro = false
            selections[mode.id] = item.id
            query = ""; cross = ""
            if locked { progression.requestSoftUnlock(for: item.id) }
        } label: {
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                HStack {
                    Text(settings.localized(item.title)).font(Theme.display(Theme.Size.body))
                    Spacer(minLength: 0)
                    if locked { Image(systemName: "lock") }
                }
                groupProgress(item.lessons)
            }
            .foregroundStyle(selected ? Theme.orange : Theme.ink)
            .padding(.vertical, Theme.Space.small).frame(minHeight: Theme.Size.touch)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain).listRowBackground(selected ? Theme.surface : Theme.background)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func groupProgress(_ lessons: [Lesson]) -> some View {
        let passed = lessons.filter { progress.isPassed(lessonId: $0.id) }.count
        let full = lessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 3 }.count
        let partial = lessons.filter { (1...2).contains(LibraryStarFilter.stars(progress.progress(for: $0.id))) }.count
        return VStack(alignment: .leading, spacing: Theme.Space.tight) {
            Text(settings.localized("%lld/%lld passed", passed, lessons.count)).font(Theme.text(Theme.Size.dense))
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Rectangle().fill(Theme.ink).frame(width: geometry.size.width * CGFloat(full) / CGFloat(max(1, lessons.count)))
                    Rectangle().fill(Theme.ink.opacity(0.35)).frame(width: geometry.size.width * CGFloat(partial) / CGFloat(max(1, lessons.count)))
                    Spacer(minLength: 0)
                }
                .background(Theme.surface)
            }.frame(height: 4).accessibilityHidden(true)
        }
    }

    private func detail(_ group: LibraryGroup) -> some View {
        let matching = catalog.matching(group.lessons, view: mode, query: query, cross: cross, language: settings.languagePreference)
        let filtered = matching.filter { settings.libraryStarFilters.contains(LibraryStarFilter.classify(progress.progress(for: $0.id)).id) }
        let nextID = next?.id
        return VStack(alignment: .leading, spacing: Theme.Space.small) {
            if let error = lessonStore.lastLoadError {
                Text(error.localizedDescription).font(Theme.text(Theme.Size.small))
                Button(settings.localized("Reload")) { try? lessonStore.reload() }
            }
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Theme.Space.tight) {
                    if let stage = group.stage {
                        Text(settings.localized("Level %lld", stage.level)).font(Theme.text(Theme.Size.small))
                    }
                    Text(settings.localized(group.title)).font(Theme.display()).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Theme.Space.small)
                Button(settings.localized("Play next")) { if let next { selectedLesson = next } }
                    .buttonStyle(InstrumentButtonStyle(selected: true)).disabled(next == nil)
            }
            groupProgress(group.lessons)
            if let stage = group.stage, !progression.isStageOpen(stage) { lockedBanner(stage) }
            filters(matching: matching, shown: filtered.count, total: group.lessons.count)
            List {
                if filtered.isEmpty {
                    Text(settings.localized("No matching lessons")).font(Theme.text()).listRowBackground(Theme.background)
                }
                ForEach(filtered) { lesson in
                    LibraryLessonRow(lesson: lesson, settings: settings, progress: progress,
                                     number: (group.lessons.firstIndex { $0.id == lesson.id } ?? 0) + 1,
                                     showTechnique: mode == .genre,
                                     locked: !progression.isLessonOpen(lesson), isNext: lesson.id == nextID) {
                        open(lesson)
                    }
                    .listRowBackground(Theme.background)
                }
            }
            .listStyle(.plain).scrollContentBackground(.hidden)
        }
        .padding(.horizontal, Theme.Space.page).padding(.top, Theme.Space.regular)
        .background(Theme.background)
    }

    private func filters(matching: [Lesson], shown: Int, total: Int) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            TextField(settings.localized("Title, genre…"), text: $query)
                .textFieldStyle(.roundedBorder).font(Theme.text()).frame(minHeight: Theme.Size.touch)
                .accessibilityLabel(settings.localized("Search lessons..."))
            Picker(settings.localized(mode == .genre ? "Technique" : "Genre"), selection: $cross) {
                Text(settings.localized("All")).tag("")
                if mode == .genre {
                    ForEach(LessonTechnique.allCases) { Text(settings.localized($0.title)).tag($0.id) }
                } else {
                    ForEach(LessonGenre.allCases) { Text(settings.localized($0.title)).tag($0.id) }
                }
            }
            .font(Theme.text(Theme.Size.small)).frame(minHeight: Theme.Size.touch)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Space.small) {
                    ForEach(LibraryStarFilter.allCases) { filter in
                        let count = matching.filter { LibraryStarFilter.classify(progress.progress(for: $0.id)) == filter }.count
                        let selected = settings.libraryStarFilters.contains(filter.id)
                        Button {
                            if selected { settings.libraryStarFilters.removeAll { $0 == filter.id } }
                            else { settings.libraryStarFilters.append(filter.id) }
                        } label: {
                            Text("\(settings.localized(filter.title)) (\(count))")
                                .font(Theme.text(Theme.Size.small))
                        }
                        .buttonStyle(InstrumentButtonStyle(selected: selected))
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }
            HStack {
                Text(settings.localized("%lld of %lld lessons", shown, total)).font(Theme.text(Theme.Size.small))
                Spacer(minLength: 0)
                Button(settings.localized("Clear filters")) {
                    query = ""; cross = ""
                    settings.libraryStarFilters = LibraryStarFilter.allCases.map(\.id)
                }.font(Theme.text(Theme.Size.small)).frame(minHeight: Theme.Size.touch)
            }
        }
    }

    private func lockedBanner(_ stage: LibraryStage) -> some View {
        let requirement = progression.unlockProgress(for: stage)
        return VStack(alignment: .leading, spacing: Theme.Space.small) {
            Label(settings.localized("Earn 2 stars in %lld lessons in %@ to open this", requirement.needed,
                                     requirement.previous.map { progression.title(for: $0.id) } ?? ""), systemImage: "lock")
                .font(Theme.text(Theme.Size.small))
            Text(settings.localized("%lld/%lld with 2 stars", requirement.completed, requirement.needed)).font(Theme.text(Theme.Size.small))
            Button(settings.localized("Unlock")) { progression.requestSoftUnlock(for: stage.id) }
                .buttonStyle(InstrumentButtonStyle())
        }
        .padding(Theme.Space.small).frame(maxWidth: .infinity, alignment: .leading).background(Theme.surface)
    }

    private func open(_ lesson: Lesson) {
        if progression.isLessonOpen(lesson) { selectedLesson = lesson; return }
        guard let stage = catalog.stage(for: lesson) else { return }
        settings.libraryView = LibraryViewMode.path.id
        selections[LibraryViewMode.path.id] = stage.id
        expandedLevels.insert(stage.level)
        progression.requestSoftUnlock(for: stage.id)
    }
}

struct LibraryLessonRow: View {
    let lesson: Lesson
    let settings: SettingsManager
    let progress: ProgressStore
    var number = 0
    var showTechnique = false
    var locked = false
    var isNext = false
    let onSelect: () -> Void

    private var record: LessonProgress? { progress.progress(for: lesson.id) }
    private var stars: Int { LibraryStarFilter.stars(record) }
    private var symbol: String {
        if locked { return "lock" }
        if isNext { return "play.fill" }
        if stars == 3 { return "circle.fill" }
        if stars > 0 { return "circle.lefthalf.filled" }
        if record?.hasPlayed == true { return "circle.dotted" }
        return "circle"
    }
    private var stateTitle: String {
        if locked { return "Locked" }
        if isNext { return "Up next" }
        return LibraryStarFilter.classify(record).title
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: Theme.Space.small) {
                Image(systemName: symbol).frame(width: 24).accessibilityLabel(settings.localized(stateTitle))
                if number > 0 { Text(number.formatted()).font(Theme.text(Theme.Size.small)).frame(minWidth: 24) }
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    Text(settings.localized(lesson.title)).font(Theme.display(Theme.Size.body))
                        .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                    Text(settings.localized(showTechnique ? LessonTechnique.classify(lesson).title : lesson.genre))
                        .font(Theme.text(Theme.Size.small))
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: Theme.Space.small) { difficulty; tempo }
                        VStack(alignment: .leading, spacing: Theme.Space.small) { difficulty; tempo }
                    }
                    if settings.activeProfile().isEightPad && EightPadLayout.slots(for: lesson) == nil {
                        Text(settings.localized("REQUIRES 16 PADS")).font(Theme.text(Theme.Size.dense))
                    }
                }
                Spacer(minLength: 0)
                HStack(spacing: 2) {
                    ForEach(Array([record?.passed ?? false, record?.mastery ?? false, record?.memory ?? false].enumerated()), id: \.offset) { index, earned in
                        Image(systemName: earned ? "star.fill" : "star")
                            .font(.system(size: 14)).foregroundStyle(earned ? Theme.orange : Theme.ink)
                            .accessibilityLabel(settings.localized(["Passed", "Goal tempo", "From memory"][index]))
                            .accessibilityValue(settings.localized(earned ? "On" : "Off"))
                    }
                }
            }
            .foregroundStyle(Theme.ink).padding(.vertical, Theme.Space.small)
            .frame(minHeight: Theme.Size.touch).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private var difficulty: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { level in
                Circle().fill(level <= lesson.level ? Theme.ink : Theme.background)
                    .overlay(Circle().stroke(Theme.ink, lineWidth: 1)).frame(width: 7, height: 7)
            }
        }.accessibilityElement().accessibilityLabel(settings.localized("Level %lld", lesson.level))
    }

    private var tempo: some View {
        let bpm = (record?.currentBpm ?? 0) > 0 ? record!.currentBpm : lesson.startBpm
        return Text("\(settings.localized("%lld bars", lesson.bars)) · \(bpm) → \(lesson.targetBpm) BPM")
            .font(Theme.text(Theme.Size.dense)).fixedSize()
    }
}
