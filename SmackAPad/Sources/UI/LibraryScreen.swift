import SwiftUI

/// Launch parameter determining how the Library screen is initially focused.
public enum LibraryLaunchTarget: Equatable, Sendable {
    case none
    case intro
    case lesson(Lesson)
}

/// Three projections of the same catalogue, sharing stage access and saved progress.
@MainActor
struct LibraryScreen: View {
    let launchTarget: LibraryLaunchTarget
    let onHome: () -> Void

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
    @State private var pendingCategoryToHide: PendingHideTarget?
    @State private var isHiddenExpanded = false

    private struct PendingHideTarget: Identifiable {
        let id: String
        let title: String
    }

    private struct HiddenCategoryItem: Identifiable {
        let id: String
        let title: String
        let lessons: [Lesson]
        let isCategory: Bool
        let stage: LibraryStage?
    }

    init(launchTarget: LibraryLaunchTarget = .none, onHome: @escaping () -> Void = {}) {
        self.launchTarget = launchTarget
        self.onHome = onHome
        _showingIntro = State(initialValue: launchTarget == .intro)
        if case .lesson(let lesson) = launchTarget {
            _selectedLesson = State(initialValue: lesson)
        } else {
            _selectedLesson = State(initialValue: nil)
        }
    }

    private var mode: LibraryViewMode { LibraryViewMode(rawValue: settings.libraryView) ?? .path }
    private var catalog: LibraryCatalog { progression.catalog }
    private var groups: [LibraryGroup] { catalog.groups(in: mode) }

    private func isGroupHidden(_ item: LibraryGroup) -> Bool {
        if settings.isCategoryHidden(item.id, in: mode.id) {
            return true
        }
        if mode == .path, let lvl = item.stage?.level, settings.isCategoryHidden("level-\(lvl)", in: mode.id) {
            return true
        }
        return false
    }

    private var visibleGroups: [LibraryGroup] {
        groups.filter { !isGroupHidden($0) }
    }

    private var group: LibraryGroup? {
        if let selectedID = selections[mode.id],
           let match = visibleGroups.first(where: { $0.id == selectedID }) {
            return match
        }
        return visibleGroups.first
    }

    private var isIntroHidden: Bool {
        settings.isCategoryHidden("intro", in: mode.id)
    }

    private var hiddenItems: [HiddenCategoryItem] {
        let hiddenIDs = settings.hiddenCategories(for: mode.id)
        guard !hiddenIDs.isEmpty else { return [] }

        var items: [HiddenCategoryItem] = []
        if hiddenIDs.contains("intro") {
            items.append(HiddenCategoryItem(
                id: "intro",
                title: settings.localized("Intro exercises"),
                lessons: introLessons,
                isCategory: true,
                stage: nil
            ))
        }
        if mode == .path {
            for level in 1...5 {
                let levelID = "level-\(level)"
                if hiddenIDs.contains(levelID) {
                    items.append(HiddenCategoryItem(
                        id: levelID,
                        title: settings.localized("Level %lld", level),
                        lessons: catalog.path.filter { $0.level == level },
                        isCategory: true,
                        stage: nil
                    ))
                }
                for group in groups.filter({ $0.stage?.level == level }) {
                    if hiddenIDs.contains(group.id) {
                        let title = group.stage.map {
                            settings.localized("Level %lld · %@", $0.level, settings.localized(group.title))
                        } ?? settings.localized(group.title)
                        items.append(HiddenCategoryItem(
                            id: group.id,
                            title: title,
                            lessons: group.lessons,
                            isCategory: false,
                            stage: group.stage
                        ))
                    }
                }
            }
            for group in groups.filter(\.isExtension) {
                if hiddenIDs.contains(group.id) {
                    items.append(HiddenCategoryItem(
                        id: group.id,
                        title: settings.localized(group.title),
                        lessons: group.lessons,
                        isCategory: false,
                        stage: nil
                    ))
                }
            }
        } else {
            for group in groups {
                if hiddenIDs.contains(group.id) {
                    items.append(HiddenCategoryItem(
                        id: group.id,
                        title: settings.localized(group.title),
                        lessons: group.lessons,
                        isCategory: false,
                        stage: group.stage
                    ))
                }
            }
        }
        return items
    }

    private var next: Lesson? {
        progression.nextLesson(after: lessonStore.lesson(for: settings.lastLessonID),
                               source: NextLessonSource(rawValue: settings.nextLessonSource) ?? .path)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
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
            isHiddenExpanded = false
            pendingCategoryToHide = nil
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
                    Text("\(earnedStars)/\(maxStars)").font(Theme.meta).monospacedDigit()
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
        VStack(spacing: 0) {
            overallCourseProgress
                .padding(.horizontal, Theme.Space.regular)
                .padding(.vertical, Theme.Space.small)
                .background(Theme.background)
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
            List {
                if !isIntroHidden {
                    introSectionRow
                }
                organiseSection
                extensionsSection
                hiddenCategoriesSection
            }
            .motion(Theme.Motion.standard, value: (settings.hiddenCategoryIDsByMode[mode.id] ?? []).hashValue ^ expandedLevels.hashValue ^ (isHiddenExpanded ? 1 : 0))
            .confirmationDialog(
                pendingCategoryToHide.map {
                    settings.localized("Hide “%@”? You can show it again at the bottom of the list.", $0.title)
                } ?? "",
                isPresented: Binding(
                    get: { pendingCategoryToHide != nil },
                    set: { if !$0 { pendingCategoryToHide = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button(settings.localized("Hide"), role: .destructive) {
                    if let target = pendingCategoryToHide {
                        hide(target: target)
                        pendingCategoryToHide = nil
                    }
                }
                Button(settings.localized("Cancel"), role: .cancel) {
                    pendingCategoryToHide = nil
                }
            }
            .font(Theme.control)
            .environment(\.defaultMinListRowHeight, Theme.Size.touch)
            .listRowInsets(EdgeInsets(top: 0, leading: Theme.Space.regular, bottom: 0, trailing: Theme.Space.regular))
            .listStyle(.sidebar).scrollContentBackground(.hidden).background(Theme.background)
        }
        .navigationTitle(settings.localized("Library"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onHome) {
                    Text(settings.localized("Home"))
                        .font(Theme.control)
                        .frame(minHeight: Theme.Size.touch)
                }
            }
        }
    }

    private var introSectionRow: some View {
        let title = settings.localized("Intro exercises")
        return Button { showingIntro = true } label: {
            VStack(alignment: .leading, spacing: 0) {
                sidebarLabel(title, lessons: introLessons, isCategory: true)
                Text(settings.localized("%lld exercises · always open", introLessons.count))
                    .font(Theme.meta).foregroundStyle(Theme.secondary).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Theme.Space.regular)
            .padding(.vertical, Theme.Space.tight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(showingIntro ? Theme.surface : Theme.background)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .clipShape(Rectangle())
        .overlay(
            Rectangle()
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .listRowInsets(EdgeInsets(top: Theme.Space.tight, leading: Theme.Space.regular, bottom: Theme.Space.tight, trailing: Theme.Space.regular))
        .listRowSeparator(.hidden)
        .listRowBackground(Theme.background)
        .contextMenu {
            Button {
                pendingCategoryToHide = PendingHideTarget(id: "intro", title: title)
            } label: {
                Label(settings.localized("Hide category"), systemImage: "eye.slash")
            }
        }
        .accessibilityAction(named: settings.localized("Hide category")) {
            pendingCategoryToHide = PendingHideTarget(id: "intro", title: title)
        }
    }
    private var organiseSection: some View {
        Section {
            PlexSegmentedPicker(title: settings.localized("Organise by"), selection: Binding(
                get: { settings.libraryView }, set: { settings.libraryView = $0 }
            ), options: LibraryViewMode.allCases.map { ($0.id, settings.localized($0.title)) }, fitsColumn: true)
                .listRowInsets(EdgeInsets(top: Theme.Space.small, leading: Theme.Space.regular, bottom: Theme.Space.small, trailing: Theme.Space.regular))
                .listRowSeparator(.hidden)
                .listRowBackground(Theme.background)
            if mode == .path {
                pathLevelsList
            } else {
                let nonPathGroups = groups.filter { !$0.isExtension && !settings.isCategoryHidden($0.id, in: mode.id) }
                if !nonPathGroups.isEmpty {
                    categoriesFramedBox(items: nonPathGroups)
                        .listRowInsets(EdgeInsets(top: Theme.Space.tight, leading: Theme.Space.regular, bottom: Theme.Space.tight, trailing: Theme.Space.regular))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Theme.background)
                }
            }
        } header: { SectionHeader(title: settings.localized("Organise by")) }
    }

    private var pathLevelsList: some View {
        ForEach((1...5).filter { !settings.isCategoryHidden("level-\($0)", in: mode.id) }, id: \.self) { level in
            levelView(level)
        }
    }

    @ViewBuilder
    private func levelView(_ level: Int) -> some View {
        let isExpanded = expandedLevels.contains(level)
        let levelID = "level-\(level)"
        let levelTitle = settings.localized("Level %lld", level)
        let levelLessons = catalog.path.filter { $0.level == level }
        let levelGroups = groups.filter { $0.stage?.level == level && !settings.isCategoryHidden($0.id, in: mode.id) }

        if isExpanded {
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                Button {
                    expandedLevels.remove(level)
                } label: {
                    HStack(spacing: Theme.Space.small) {
                        Image(systemName: "chevron.right")
                            .rotationEffect(motion.angle(90))
                            .font(Theme.meta).frame(width: 16)
                        sidebarLabel(levelTitle,
                                     lessons: levelLessons,
                                     isCategory: true,
                                     isStrong: true)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(settings.localized("Expanded"))
                .contextMenu {
                    Button {
                        pendingCategoryToHide = PendingHideTarget(id: levelID, title: levelTitle)
                    } label: {
                        Label(settings.localized("Hide category"), systemImage: "eye.slash")
                    }
                }
                .accessibilityAction(named: settings.localized("Hide category")) {
                    pendingCategoryToHide = PendingHideTarget(id: levelID, title: levelTitle)
                }

                if !levelGroups.isEmpty {
                    categoriesFramedBox(items: levelGroups)
                }
            }
            .padding(.vertical, Theme.Space.tight)
            .listRowInsets(EdgeInsets(top: Theme.Space.tight, leading: Theme.Space.regular, bottom: Theme.Space.small, trailing: Theme.Space.regular))
            .listRowSeparator(.hidden)
            .listRowBackground(Theme.background)
        } else {
            Button {
                expandedLevels.insert(level)
            } label: {
                HStack(spacing: Theme.Space.small) {
                    Image(systemName: "chevron.right")
                        .rotationEffect(motion.angle(0))
                        .font(Theme.meta).frame(width: 16)
                    sidebarLabel(levelTitle,
                                 lessons: levelLessons,
                                 isCategory: true,
                                 isStrong: false)
                }
                .padding(.horizontal, Theme.Space.regular)
                .padding(.vertical, Theme.Space.tight)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.background)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(Theme.hairline, lineWidth: 1)
            )
            .accessibilityValue(settings.localized("Collapsed"))
            .contextMenu {
                Button {
                    pendingCategoryToHide = PendingHideTarget(id: levelID, title: levelTitle)
                } label: {
                    Label(settings.localized("Hide category"), systemImage: "eye.slash")
                }
            }
            .accessibilityAction(named: settings.localized("Hide category")) {
                pendingCategoryToHide = PendingHideTarget(id: levelID, title: levelTitle)
            }
            .listRowInsets(EdgeInsets(top: Theme.Space.tight, leading: Theme.Space.regular, bottom: Theme.Space.tight, trailing: Theme.Space.regular))
            .listRowSeparator(.hidden)
            .listRowBackground(Theme.background)
        }
    }

    private func categoriesFramedBox(items: [LibraryGroup]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(height: 1)
                }
                sidebarRow(item)
            }
        }
        .background(Theme.background)
        .clipShape(Rectangle())
        .overlay(
            Rectangle()
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var extensionsSection: some View {
        let visibleExtensions = groups.filter { $0.isExtension && !settings.isCategoryHidden($0.id, in: mode.id) }
        if !visibleExtensions.isEmpty {
            Section {
                categoriesFramedBox(items: visibleExtensions)
                    .listRowInsets(EdgeInsets(top: Theme.Space.tight, leading: Theme.Space.regular, bottom: Theme.Space.tight, trailing: Theme.Space.regular))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Theme.background)
            } header: { SectionHeader(title: settings.localized("Extensions · outside the Path")) }
        }
    }

    @ViewBuilder
    private var hiddenCategoriesSection: some View {
        if !hiddenItems.isEmpty {
            Section {
                Button {
                    withAnimation(motion.animation(Theme.Motion.standard)) {
                        isHiddenExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: Theme.Space.small) {
                        Image(systemName: "chevron.right")
                            .rotationEffect(motion.angle(isHiddenExpanded ? 90 : 0))
                            .font(Theme.meta).frame(width: 16)
                        Text(settings.localized("Hidden categories (%lld)", hiddenItems.count))
                            .font(Theme.sectionTitle)
                            .foregroundStyle(Theme.secondary)
                    }
                    .frame(minHeight: Theme.Size.touch)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(settings.localized(isHiddenExpanded ? "Expanded" : "Collapsed"))
                .listRowBackground(Theme.background)

                if isHiddenExpanded {
                    ForEach(hiddenItems) { item in
                        hiddenCategoryRow(item)
                    }
                }
            }
        }
    }

    private func sidebarRow(_ item: LibraryGroup) -> some View {
        let selected = !showingIntro && group?.id == item.id
        let locked = item.stage.map { !progression.isStageOpen($0) } ?? false
        let title = settings.localized(item.title)
        return Button {
            showingIntro = false
            selections[mode.id] = item.id
            query = ""; cross = ""
        } label: {
            HStack(spacing: Theme.Space.small) {
                AnimatedLock(locked: locked).font(Theme.meta)
                sidebarLabel(title, lessons: item.lessons, selected: selected)
            }
            .padding(.horizontal, Theme.Space.regular)
            .padding(.vertical, Theme.Space.tight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Theme.surface : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .contextMenu {
            Button {
                pendingCategoryToHide = PendingHideTarget(id: item.id, title: title)
            } label: {
                Label(settings.localized("Hide category"), systemImage: "eye.slash")
            }
        }
        .accessibilityAction(named: settings.localized("Hide category")) {
            pendingCategoryToHide = PendingHideTarget(id: item.id, title: title)
        }
    }

    private func hide(target: PendingHideTarget) {
        withAnimation(motion.animation(Theme.Motion.standard)) {
            settings.hideCategory(target.id, in: mode.id)
            if target.id == "intro" && showingIntro {
                showingIntro = false
            }
            if let current = group, isGroupHidden(current) {
                if let first = visibleGroups.first {
                    selections[mode.id] = first.id
                    if let lvl = first.stage?.level {
                        expandedLevels.insert(lvl)
                    }
                }
            }
        }
    }

    private func unhideCategory(_ id: String) {
        withAnimation(motion.animation(Theme.Motion.standard)) {
            settings.unhideCategory(id, in: mode.id)
        }
    }

    private func hiddenCategoryRow(_ item: HiddenCategoryItem) -> some View {
        let locked = item.stage.map { !progression.isStageOpen($0) } ?? false
        return HStack(spacing: Theme.Space.small) {
            if item.isCategory {
                sidebarLabel(item.title, lessons: item.lessons, isCategory: true)
            } else {
                AnimatedLock(locked: locked).font(Theme.meta)
                sidebarLabel(item.title, lessons: item.lessons)
            }
            Spacer(minLength: Theme.Space.tight)
            Button {
                unhideCategory(item.id)
            } label: {
                Text(settings.localized("Show"))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, Theme.Space.small)
                    .frame(minHeight: Theme.Size.touch)
                    .background(Theme.surface)
                    .overlay(
                        Rectangle()
                            .stroke(Theme.hairline, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(settings.localized("Show category"))
        }
        .foregroundStyle(Theme.secondary)
        .opacity(0.7)
        .listRowBackground(Theme.background)
        .contextMenu {
            Button {
                unhideCategory(item.id)
            } label: {
                Label(settings.localized("Show category"), systemImage: "eye")
            }
        }
        .accessibilityAction(named: settings.localized("Show category")) {
            unhideCategory(item.id)
        }
    }

    private func sidebarLabel(_ title: String, lessons: [Lesson], isCategory: Bool = false, selected: Bool = false, isStrong: Bool = false) -> some View {
        let three = lessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 3 }.count
        let two = lessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 2 }.count
        let one = lessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 1 }.count
        let earnedStars = three * 3 + two * 2 + one
        let maxStars = lessons.count * 3

        let font: Font
        if isStrong {
            font = Theme.strong(22)
        } else if isCategory {
            font = Theme.sectionTitle
        } else {
            font = Theme.navigation
        }

        let titleLabel = Text(title)
            .font(font)
            .fixedSize(horizontal: false, vertical: true)
        let stars = HStack(spacing: 2) {
            Image(systemName: "star.fill").font(Theme.meta)
                .foregroundStyle(earnedStars > 0 ? Theme.orange : Theme.secondary)
            Text("\(earnedStars)/\(maxStars)").font(Theme.meta).monospacedDigit().fixedSize()
        }
        .accessibilityLabel(settings.localized("%lld of %lld stars", earnedStars, maxStars))
        return VStack(alignment: .leading, spacing: Theme.Space.tight) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Space.small) {
                    titleLabel.fixedSize()
                    Spacer(minLength: 0)
                    stars
                }
                VStack(alignment: .leading, spacing: Theme.Space.tight) { titleLabel; stars }
            }
            progressLine(lessons)
        }
        .padding(.vertical, Theme.Space.tight)
        .frame(minHeight: Theme.Size.touch)
    }

    private func progressLine(_ lessons: [Lesson]) -> some View {
        let three = lessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 3 }.count
        let two = lessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 2 }.count
        let one = lessons.filter { LibraryStarFilter.stars(progress.progress(for: $0.id)) == 1 }.count
        return ProgressLine(threeStars: three, twoStars: two, oneStar: one, total: lessons.count)
    }

    private func detail(_ group: LibraryGroup) -> some View {
        let isSearching = !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isGroupAllCompleted = !group.lessons.isEmpty && group.lessons.allSatisfy { progress.isCompleted(lessonId: $0.id) }
        let matching = catalog.matching(group.lessons, view: mode, query: query, cross: cross, language: settings.languagePreference)
        let filtered = matching.filter { lesson in
            if !isSearching && settings.hideCompletedLessons && progress.isCompleted(lessonId: lesson.id) {
                return false
            }
            return settings.libraryStarFilters.contains(LibraryStarFilter.classify(progress.progress(for: lesson.id)).id)
        }
        let nextID = next?.id
        return VStack(alignment: .leading, spacing: Theme.Space.small) {
            if let error = lessonStore.lastLoadError {
                InfoBanner(text: error.localizedDescription, actionTitle: settings.localized("Reload"),
                           action: {
                    try? lessonStore.reload()
                })
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
            .padding(.bottom, Theme.Space.small)
            if let stage = group.stage, !progression.isStageOpen(stage) || progression.canRelockStage(stage) {
                stageBanner(stage).id("stage-lock").transition(motion.transition)
                    .padding(.bottom, Theme.Space.small)
            }
            List {
                if isGroupAllCompleted && settings.hideCompletedLessons && !isSearching {
                    allCompletedRow
                } else if filtered.isEmpty {
                    Text(settings.localized("No matching lessons")).font(Theme.control)
                        .listRowBackground(Theme.background)
                } else {
                    ForEach(filtered) { lesson in
                        LibraryLessonRow(lesson: lesson, settings: settings, progress: progress,
                                         number: (group.lessons.firstIndex { $0.id == lesson.id } ?? 0) + 1,
                                         showTechnique: mode == .genre,
                                         locked: !progression.isLessonOpen(lesson), purchaseLocked: !store.isUnlocked(lesson), isNext: lesson.id == nextID) {
                            open(lesson)
                        }
                        .listRowInsets(EdgeInsets(top: Theme.Space.tight, leading: 0, bottom: Theme.Space.tight, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .environment(\.defaultMinListRowHeight, 60)
            .listStyle(.plain).scrollContentBackground(.hidden)
            .contentMargins(.vertical, 0, for: .scrollContent)
            .motion(Theme.Motion.standard, value: filtered.map(\.id))
        }
        .padding(.horizontal, Theme.Space.page).padding(.top, Theme.Space.small)
        .background(Theme.background)
        .motion(Theme.Motion.standard, value: group.stage.map { progression.isStageOpen($0) })
    }

    private var allCompletedRow: some View {
        HStack(spacing: Theme.Space.regular) {
            Text(settings.localized("All lessons completed"))
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
            Button {
                settings.hideCompletedLessons = false
            } label: {
                Text(settings.localized("Show completed"))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, Theme.Space.small)
                    .frame(minHeight: Theme.Size.touch)
                    .background(Theme.surface)
                    .overlay(
                        Rectangle()
                            .stroke(Theme.hairline, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(settings.localized("Show completed"))
        }
        .padding(.vertical, Theme.Space.small)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Theme.background)
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
                    Text("\(earnedStars)/\(maxStars)").font(Theme.meta).monospacedDigit()
                }
                Spacer(minLength: 4)
                Text(shown == total ? settings.localized("%lld lessons", total) : settings.localized("%lld of %lld lessons", shown, total))
                    .font(Theme.meta).foregroundStyle(Theme.secondary).fixedSize(horizontal: false, vertical: true)
                    .contentTransition(motion.numeric).motion(value: shown)
            }
            progressLine(group.lessons)
        }
        .frame(minWidth: 180, idealWidth: 240)
    }

    private func filters(matching: [Lesson]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Space.small) {
                HStack(spacing: Theme.Space.tight) {
                    Image(systemName: "magnifyingglass").font(Theme.meta).foregroundStyle(Theme.secondary)
                    TextField(settings.localized("Search"), text: $query)
                        .textFieldStyle(.plain).font(Theme.meta)
                }
                .padding(.horizontal, Theme.Space.small)
                .frame(minWidth: 100, idealWidth: 140, maxWidth: 170)
                .frame(height: Theme.Size.touch)
                .background(Theme.surface)
                .overlay(
                    Rectangle()
                        .stroke(Theme.hairline, lineWidth: 1)
                )
                .accessibilityLabel(settings.localized("Search"))

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
                        Image(systemName: "line.3.horizontal.decrease")
                        Text(crossTitle)
                    }
                    .font(Theme.meta).lineLimit(1)
                    .padding(.horizontal, Theme.Space.small)
                    .frame(height: Theme.Size.touch)
                    .background(cross.isEmpty ? Theme.background : Theme.surface)
                    .overlay(
                        Rectangle()
                            .stroke(cross.isEmpty ? Theme.hairline : Theme.ink, lineWidth: 1)
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
                    .frame(height: Theme.Size.touch)
                }

                Button {
                    query = ""; cross = ""
                    settings.libraryStarFilters = LibraryStarFilter.allCases.map(\.id)
                } label: {
                    HStack(spacing: Theme.Space.tight) {
                        Image(systemName: "xmark").font(Theme.meta)
                        Text(settings.localized("Clear filters")).font(Theme.meta).fixedSize()
                    }
                    .padding(.horizontal, Theme.Space.small)
                    .frame(height: Theme.Size.touch)
                    .background(Theme.surface)
                    .overlay(
                        Rectangle()
                            .stroke(Theme.hairline, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.localized("Clear filters"))
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: Theme.Size.touch)
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
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Space.small) {
                        genre
                        difficulty
                        tempo
                        padRequirement
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    VStack(alignment: .leading, spacing: Theme.Space.tight) {
                        HStack(spacing: Theme.Space.small) { genre; difficulty; padRequirement }
                        tempo
                    }
                }
            }
        } trailing: {
            if purchaseLocked {
                Button(action: onSelect) {
                    Image(systemName: "lock").font(Theme.meta).foregroundStyle(Theme.secondary)
                        .frame(minWidth: Theme.Size.touch, minHeight: Theme.Size.touch)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.localized("Purchase required"))
            }
            if introGoal == nil {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Space.regular) {
                        LessonPatternStrip(hits: lesson.hits, dimmed: locked)
                        StarsView(record: record, lesson: lesson)
                    }
                    StarsView(record: record, lesson: lesson)
                }
            } else {
                StarsView(record: record, lesson: lesson)
            }
        }
        .padding(.horizontal, Theme.Space.regular)
        .background(
            Rectangle()
                .fill(Theme.surface)
        )
        .overlay(
            Rectangle()
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .lessonSource(lesson.id)
    }

    private var genre: some View {
        Text(settings.localized(showTechnique ? LessonTechnique.classify(lesson).title : lesson.genre))
    }

    @ViewBuilder private var padRequirement: some View {
        if settings.activeProfile().isEightPad && EightPadLayout.slots(for: lesson) == nil {
            Text(settings.localized("16 pads"))
                .accessibilityLabel(settings.localized("Requires 16 pads"))
        }
    }

    private var difficulty: some View {
        HStack(spacing: Theme.Space.tight) {
            ForEach(1...5, id: \.self) { level in
                Circle().fill(level <= lesson.level ? Theme.ink : Theme.background)
                    .overlay(Circle().stroke(Theme.ink, lineWidth: 1)).frame(width: 8, height: 8)
            }
        }.accessibilityElement().accessibilityLabel(settings.localized("Level %lld", lesson.level))
    }

    private var tempo: some View {
        let bpm = (record?.currentBpm ?? 0) > 0 ? record!.currentBpm : lesson.startBpm
        return Text("\(settings.localized(lesson.bars == 1 ? "%lld bar" : "%lld bars", lesson.bars)) · \(bpm) → \(lesson.targetBpm) BPM")
            .font(Theme.meta).monospacedDigit().fixedSize(horizontal: false, vertical: true)
    }
}
