import SwiftUI

/// Three projections of the same catalogue, sharing stage access and saved progress.
@MainActor
struct LibraryScreen: View {
    @Environment(StoreManager.self) private var store
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
    @Namespace private var lessonNamespace
    @State private var starsBefore: [Bool] = []
    @State private var practicedID: Int?
    @State private var consumedStarLessons: Set<Int> = []
    @State private var returnedStars: [Int: Set<Int>] = [:]
    @Environment(\.accessibilityReduceMotion) private var reduced
    private var motion: Theme.Motion.Policy { .init(reduced: reduced) }
    @State private var showingSettings = false
    @State private var purchaseAccess: String?
    @State private var bannerPulse = 0
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
                if showingIntro { IntroScreen { open($0) }.id("intro").transition(motion.transition) }
                else if let group { detail(group).id(mode.id + group.id).transition(motion.transition) }
                else { Text(settings.localized("No matching lessons")) }
            }
            .motion(Theme.Motion.standard, value: showingIntro ? "intro" : mode.id + (group?.id ?? ""))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(settings.localized("Settings")) { showingSettings = true }
                        .font(Theme.control).frame(minHeight: Theme.Size.touch)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .font(Theme.control)
        .background(Theme.background).foregroundStyle(Theme.ink).tint(Theme.orange)
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: Binding(get: { purchaseAccess != nil }, set: { if !$0 { purchaseAccess = nil } })) {
            PurchaseSheet(access: purchaseAccess ?? "full")
        }
        .environment(\.lessonNamespace, lessonNamespace)
        .environment(\.returnedStars, returnedStars)
        .environment(\.consumeReturnedStars, { id in
            guard !consumedStarLessons.contains(id), let fresh = returnedStars[id], !fresh.isEmpty else { return [] }
            consumedStarLessons.insert(id)
            return fresh
        })
        .lessonPresentation(lesson: $selectedLesson, namespace: lessonNamespace) { lesson in
            PracticeScreen(lesson: lesson, settings: settings, progress: progress, midi: midi)
        }
        .onChange(of: selectedLesson?.id) { _, id in
            if let id {
                practicedID = id
                starsBefore = starSet(id)
                returnedStars = [:]
                consumedStarLessons = []
            } else if let practicedID {
                returnedStars = [practicedID: Theme.Motion.newStars(before: starsBefore, after: starSet(practicedID))]
            }
        }
        .onChange(of: settings.libraryView) { _, _ in
            query = ""; cross = ""; showingIntro = false; progression.cancelStageAccessChange()
        }
        .onChange(of: group?.id) { _, _ in progression.cancelStageAccessChange() }
        .onChange(of: showingIntro) { _, _ in progression.cancelStageAccessChange() }
    }

    private func starSet(_ id: Int) -> [Bool] {
        let record = progress.progress(for: id)
        return [record?.passed ?? false, record?.mastery ?? false, record?.memory ?? false]
    }

    private var introLessons: [Lesson] { catalog.introLessons }

    private var overallCourseProgress: some View {
        let allLessons = catalog.path
        let three = allLessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 3 }.count
        let two = allLessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 2 }.count
        let one = allLessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 1 }.count
        let earnedStars = three * 3 + two * 2 + one
        let maxStars = allLessons.count * 3

        return VStack(alignment: .leading, spacing: Theme.Space.tight) {
            HStack(spacing: Theme.Space.small) {
                Text(settings.localized("Overall progress")).font(Theme.meta).foregroundStyle(Theme.secondary)
                Spacer(minLength: 0)
                HStack(spacing: 2) {
                    Image(systemName: "star.fill").font(Theme.meta).foregroundStyle(Theme.orange)
                    Text("\(earnedStars)/\(maxStars)").font(Theme.meta).bold()
                }
            }
            HStack(spacing: Theme.Space.small) {
                ProgressLine(threeStars: three, twoStars: two, oneStar: one, total: allLessons.count)
                Text(settings.localized("%lld lessons", allLessons.count))
                    .font(Theme.meta).foregroundStyle(Theme.secondary).fixedSize()
            }
        }
        .padding(.vertical, Theme.Space.tight)
    }

    private var sidebar: some View {
        List {
            Section {
                overallCourseProgress
            }
            Section {
                Button { showingIntro = true } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        sidebarLabel(settings.localized("Intro exercises"), lessons: introLessons, isCategory: true)
                        Text(settings.localized("%lld exercises · always open", introLessons.count))
                            .font(Theme.meta).foregroundStyle(Theme.secondary).lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
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
                        Button {
                            if expandedLevels.contains(level) { expandedLevels.remove(level) }
                            else { expandedLevels.insert(level) }
                        } label: {
                            HStack(spacing: Theme.Space.small) {
                                Image(systemName: "chevron.right")
                                    .rotationEffect(motion.angle(expandedLevels.contains(level) ? 90 : 0))
                                    .font(Theme.meta).frame(width: 16)
                                sidebarLabel(settings.localized("Level %lld", level),
                                             lessons: catalog.path.filter { $0.level == level },
                                             isCategory: true)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityValue(settings.localized(expandedLevels.contains(level) ? "Expanded" : "Collapsed"))
                        .listRowBackground(Theme.background)
                        if expandedLevels.contains(level) {
                            ForEach(groups.filter { $0.stage?.level == level }) { item in
                                HStack(spacing: 0) {
                                    Rectangle()
                                        .fill(Theme.secondary.opacity(0.35))
                                        .frame(width: 2)
                                        .padding(.leading, 7)
                                        .padding(.trailing, Theme.Space.small)
                                    sidebarRow(item)
                                }
                                .padding(.leading, Theme.Space.small)
                            }
                        }
                    }
                } else {
                    ForEach(groups.filter { !$0.isExtension }) { sidebarRow($0) }
                }
            } header: { SectionHeader(title: settings.localized("Organise by")) }
            if groups.contains(where: \.isExtension) {
                Section {
                    ForEach(groups.filter(\.isExtension)) { sidebarRow($0) }
                } header: { SectionHeader(title: settings.localized("Extensions · outside the Path")) }
            }
        }
        .motion(Theme.Motion.standard, value: expandedLevels)
        .font(Theme.control)
        .environment(\.defaultMinListRowHeight, Theme.Size.touch)
        .listRowInsets(EdgeInsets(top: 0, leading: Theme.Space.regular, bottom: 0, trailing: Theme.Space.regular))
        .listStyle(.sidebar).scrollContentBackground(.hidden).background(Theme.background)
        .toolbar {
            ToolbarItem(placement: .principal) { ScreenHeader(title: settings.localized("Library")) }
        }
    }

    private func sidebarRow(_ item: LibraryGroup) -> some View {
        let selected = !showingIntro && group?.id == item.id
        let locked = item.stage.map { !progression.isStageOpen($0) } ?? false
        return Button {
            showingIntro = false
            selections[mode.id] = item.id
            query = ""; cross = ""
        } label: {
            HStack(spacing: Theme.Space.small) {
                AnimatedLock(locked: locked).font(Theme.meta)
                sidebarLabel(settings.localized(item.title), lessons: item.lessons, isCategory: false)
            }
            .foregroundStyle(selected ? Theme.orange : Theme.ink)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain).listRowBackground(selected ? Theme.surface : Theme.background)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func sidebarLabel(_ title: String, lessons: [Lesson], isCategory: Bool = false) -> some View {
        let three = lessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 3 }.count
        let two = lessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 2 }.count
        let one = lessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 1 }.count
        let earnedStars = three * 3 + two * 2 + one
        let maxStars = lessons.count * 3

        return VStack(alignment: .leading, spacing: Theme.Space.tight) {
            HStack(spacing: Theme.Space.small) {
                Text(title)
                    .font(isCategory ? Theme.rowTitle : Theme.control)
                    .fontWeight(isCategory ? .heavy : .regular)
                    .lineLimit(1)
                Spacer(minLength: 0)
                HStack(spacing: 2) {
                    Image(systemName: "star.fill").font(Theme.meta)
                        .foregroundStyle(earnedStars > 0 ? Theme.orange : Theme.secondary)
                    Text("\(earnedStars)/\(maxStars)")
                        .font(Theme.meta).fixedSize()
                }
                .accessibilityLabel(settings.localized("%lld of %lld stars", earnedStars, maxStars))
            }
            progressLine(lessons)
        }
        .frame(minHeight: isCategory ? Theme.Size.touch : 40)
    }

    private func progressLine(_ lessons: [Lesson]) -> some View {
        let three = lessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 3 }.count
        let two = lessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 2 }.count
        let one = lessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 1 }.count
        return ProgressLine(threeStars: three, twoStars: two, oneStar: one, total: lessons.count)
    }

    private func detail(_ group: LibraryGroup) -> some View {
        let matching = catalog.matching(group.lessons, view: mode, query: query, cross: cross, language: settings.languagePreference)
        let filtered = matching.filter { settings.libraryStarFilters.contains(LibraryStarFilter.classify(progress.progress(for: $0.id)).id) }
        let nextID = next?.id
        return VStack(alignment: .leading, spacing: Theme.Space.small) {
            if let error = lessonStore.lastLoadError {
                InfoBanner(text: error.localizedDescription, actionTitle: settings.localized("Reload")) {
                    try? lessonStore.reload()
                }
            }
            filters(matching: matching)
            ScreenHeader(title: group.stage.map {
                settings.localized("Level %lld · %@", $0.level, settings.localized(group.title))
            } ?? settings.localized(group.title)) {
                courseProgressIndicator(group: group, shown: filtered.count, total: group.lessons.count)
                Button(settings.localized("Play next")) { if let next { open(next) } }
                    .font(Theme.control).padding(.horizontal, Theme.Space.small)
                    .frame(minHeight: Theme.Size.touch)
                    .foregroundStyle(Theme.black).background(Theme.orange).disabled(next == nil)
            }
            if let stage = group.stage, !progression.isStageOpen(stage) || progression.canRelockStage(stage) {
                stageBanner(stage).id("stage-lock").transition(motion.transition)
            }
            List {
                if filtered.isEmpty {
                    Text(settings.localized("No matching lessons")).font(Theme.control)
                        .listRowBackground(Theme.background)
                }
                ForEach(filtered) { lesson in
                    LibraryLessonRow(lesson: lesson, settings: settings, progress: progress,
                                     number: (group.lessons.firstIndex { $0.id == lesson.id } ?? 0) + 1,
                                     showTechnique: mode == .genre,
                                     locked: !progression.isLessonOpen(lesson), purchaseLocked: !store.isUnlocked(lesson), isNext: lesson.id == nextID) {
                        open(lesson)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Theme.background)
                }
            }
            .environment(\.defaultMinListRowHeight, 60)
            .listStyle(.plain).scrollContentBackground(.hidden)
            .contentMargins(.vertical, 0, for: .scrollContent)
        }
        .padding(.horizontal, Theme.Space.page).padding(.top, Theme.Space.small)
        .background(Theme.background)
        .motion(Theme.Motion.standard, value: group.stage.map { progression.isStageOpen($0) })
    }

    private func courseProgressIndicator(group: LibraryGroup, shown: Int, total: Int) -> some View {
        let three = group.lessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 3 }.count
        let two = group.lessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 2 }.count
        let one = group.lessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 1 }.count
        let earnedStars = three * 3 + two * 2 + one
        let maxStars = total * 3

        return VStack(alignment: .leading, spacing: Theme.Space.tight) {
            HStack(spacing: Theme.Space.small) {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill").font(Theme.meta).foregroundStyle(Theme.orange)
                    Text("\(earnedStars)/\(maxStars)").font(Theme.meta).bold()
                }
                Spacer(minLength: 4)
                Text(shown == total ? settings.localized("%lld lessons", total) : settings.localized("%lld of %lld lessons", shown, total))
                    .font(Theme.meta).foregroundStyle(Theme.secondary).lineLimit(1)
                    .contentTransition(motion.numeric).motion(value: shown)
            }
            progressLine(group.lessons)
        }
        .frame(minWidth: 140, idealWidth: 170, maxWidth: 200)
    }

    private func filters(matching: [Lesson]) -> some View {
        HStack(spacing: Theme.Space.small) {
            HStack(spacing: Theme.Space.tight) {
                Image(systemName: "magnifyingglass").font(Theme.meta).foregroundStyle(Theme.secondary)
                TextField(settings.localized("Title, genre…"), text: $query)
                    .textFieldStyle(.plain).font(Theme.meta)
            }
            .padding(.horizontal, Theme.Space.small)
            .frame(minWidth: 100, idealWidth: 140, maxWidth: 170, minHeight: 28)
            .background(Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Size.blockRadius)
                    .stroke(Theme.secondary.opacity(0.35), lineWidth: 1)
            )
            .accessibilityLabel(settings.localized("Search lessons..."))

            Menu {
                Picker(settings.localized(mode == .genre ? "Technique" : "Genre"), selection: $cross) {
                    Text(settings.localized("All")).tag("")
                    if mode == .genre {
                        ForEach(LessonTechnique.allCases) { Text(settings.localized($0.title)).tag($0.id) }
                    } else {
                        ForEach(LessonGenre.allCases) { Text(settings.localized($0.title)).tag($0.id) }
                    }
                }
            } label: {
                HStack(spacing: Theme.Space.tight) {
                    Image(systemName: cross.isEmpty ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
                    Text(crossTitle)
                }
                .font(Theme.meta).lineLimit(1)
                .padding(.horizontal, Theme.Space.small)
                .frame(minHeight: 28)
                .background(cross.isEmpty ? Theme.background : Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Size.blockRadius)
                        .stroke(cross.isEmpty ? Theme.secondary.opacity(0.35) : Theme.orange, lineWidth: 1)
                )
            }
            .accessibilityValue(crossTitle)

            ForEach(LibraryStarFilter.allCases) { filter in
                let count = matching.filter { LibraryStarFilter.classify(progress.progress(for: $0.id)) == filter }.count
                let selected = settings.libraryStarFilters.contains(filter.id)
                FilterChip(title: "\(settings.localized(filter.title)) (\(count))", selected: selected) {
                    if selected { settings.libraryStarFilters.removeAll { $0 == filter.id } }
                    else { settings.libraryStarFilters.append(filter.id) }
                }
            }

            Spacer(minLength: 0)

            Button {
                query = ""; cross = ""
                settings.libraryStarFilters = LibraryStarFilter.allCases.map(\.id)
            } label: {
                HStack(spacing: Theme.Space.tight) {
                    Image(systemName: "xmark").font(Theme.meta)
                    Text(settings.localized("Clear filters")).font(Theme.meta).fixedSize()
                }
                .padding(.horizontal, Theme.Space.small)
                .frame(minHeight: 28)
                .background(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Size.blockRadius)
                        .stroke(Theme.secondary.opacity(0.4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(settings.localized("Clear filters"))
        }
        .frame(minHeight: 32)
    }

    private var crossTitle: String {
        let title = mode == .genre
            ? LessonTechnique(rawValue: cross)?.title
            : LessonGenre(rawValue: cross)?.title
        return settings.localized(title ?? "All")
    }

    private func stageBanner(_ stage: LibraryStage) -> some View {
        let requirement = progression.unlockProgress(for: stage)
        let message = settings.localized("Earn 2 stars in %lld lessons in %@ to open this", requirement.needed,
                                        requirement.previous.map { progression.title(for: $0.id) } ?? "")
        let confirmation = progression.stageAccessConfirmation
        let pending = confirmation?.stageID == stage.id
        let relock = progression.canRelockStage(stage)
        let text = pending
            ? settings.localized(confirmation?.action == .relock ? "Really lock %@ again?" : "Really unlock %@?",
                                 progression.title(for: stage.id))
            : relock ? settings.localized("Manually unlocked · no stars yet")
            : "\(message) · \(requirement.completed)/\(requirement.needed)"
        return InfoBanner(text: text, symbol: relock ? "lock.open" : "lock",
                          actionTitle: settings.localized(pending
                              ? (confirmation?.action == .relock ? "Yes, lock again" : "Yes, unlock")
                              : (relock ? "Lock again" : "Unlock")),
                          action: {
            if pending { progression.confirmStageAccessChange() }
            else { progression.requestStageAccessChange(for: stage.id, action: relock ? .relock : .unlock) }
        }, secondaryActionTitle: pending ? settings.localized("Cancel") : nil,
                          secondaryAction: { progression.cancelStageAccessChange() })
        .overlay(Rectangle().stroke(Theme.orange.opacity(bannerPulse > 0 ? 1 : 0), lineWidth: Theme.Size.border))
        .motion(value: bannerPulse)
        .task(id: bannerPulse) {
            guard bannerPulse > 0 else { return }
            try? await Task.sleep(for: .milliseconds(400))
            bannerPulse = 0
        }
    }

    private func open(_ lesson: Lesson) {
        guard store.isUnlocked(lesson) else {
            purchaseAccess = lesson.access ?? "full"
            return
        }
        if progression.isLessonOpen(lesson) { selectedLesson = lesson; return }
        guard let stage = catalog.stage(for: lesson) else { return }
        settings.libraryView = LibraryViewMode.path.id
        selections[LibraryViewMode.path.id] = stage.id
        expandedLevels.insert(stage.level)
        bannerPulse += 1
    }
}

struct LibraryLessonRow: View {
    let lesson: Lesson
    let settings: SettingsManager
    let progress: ProgressStore
    var number = 0
    var showTechnique = false
    var locked = false
    var purchaseLocked = false
    var isNext = false
    var introGoal: String? = nil
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
        if purchaseLocked { return "Purchase required" }
        if locked { return "Locked" }
        if isNext { return "Up next" }
        return LibraryStarFilter.classify(record).title
    }

    var body: some View {
        ListRow(symbol: symbol, symbolTint: stars > 0 ? Theme.starColor(for: stars) : nil,
                stateTitle: settings.localized(stateTitle),
                number: number > 0 ? number : nil, title: settings.localized(lesson.title),
                dimmed: locked, action: onSelect) {
            if let introGoal {
                Text(introGoal)
            } else {
                HStack(spacing: Theme.Space.small) {
                    Text(settings.localized(showTechnique ? LessonTechnique.classify(lesson).title : lesson.genre))
                        .lineLimit(1).layoutPriority(-1)
                    Text("·")
                    difficulty
                    Text("·")
                    tempo
                    if settings.activeProfile().isEightPad && EightPadLayout.slots(for: lesson) == nil {
                        Image(systemName: "square.grid.4x3.fill")
                            .accessibilityLabel(settings.localized("REQUIRES 16 PADS"))
                    }
                }
            }
        } trailing: {
            if purchaseLocked {
                Button(action: onSelect) {
                    Image(systemName: "lock.fill").font(Theme.meta).foregroundStyle(Theme.orange)
                        .frame(minWidth: Theme.Size.touch, minHeight: Theme.Size.touch)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.localized("Purchase required"))
            }
            StarsView(record: record, lesson: lesson)
        }
        .lessonSource(lesson.id)
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
        return Text("\(settings.localized(lesson.bars == 1 ? "%lld bar" : "%lld bars", lesson.bars)) · \(bpm) → \(lesson.targetBpm) BPM")
            .font(Theme.meta).lineLimit(1).fixedSize()
    }
}
