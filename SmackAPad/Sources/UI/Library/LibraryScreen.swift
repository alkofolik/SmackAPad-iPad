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
    let onHome: () -> Void
    let onReviewOpen: (Int) -> Void

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
    @State private var showingFilters = false
    @State private var isSearchOpen = false
    @FocusState private var isSearchFocused: Bool
    @State private var selectedLesson: LessonLaunch?
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

    private var isSearchVisible: Bool {
        isSearchOpen || !query.isEmpty
    }

    private var activeFilterGroupCount: Int {
        var count = 0
        if Set(settings.libraryStarFilters) != Set(LibraryStarFilter.allCases.map(\.id)) {
            count += 1
        }
        if !cross.isEmpty {
            count += 1
        }
        return count
    }

    private var filtersButtonTitle: String {
        let base = settings.localized("Filters")
        if activeFilterGroupCount > 0 {
            return "\(base) (\(activeFilterGroupCount))"
        }
        return base
    }

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

    init(launchTarget: LibraryLaunchTarget = .none, initialProgress: LessonProgress? = nil,
         onReviewOpen: @escaping (Int) -> Void = { _ in }, onHome: @escaping () -> Void = {}) {
        self.onHome = onHome
        self.onReviewOpen = onReviewOpen
        _showingIntro = State(initialValue: launchTarget == .intro)
        if case .lesson(let lesson) = launchTarget {
            _selectedLesson = State(initialValue: .library(lesson, progress: initialProgress, today: AppCalendar.today()))
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .calmChassisBackground()
            .motion(Theme.Motion.standard, value: showingIntro ? "intro" : mode.id + (group?.id ?? ""))
            .toolbar {
                PadToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: {
                        Text(settings.localized("Settings"))
                            .font(Theme.control)
                            .frame(minHeight: Theme.Size.touch)
                    }
                    .buttonStyle(PadSecondaryButtonStyle())
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .font(Theme.control)
        .calmChassisBackground()
        .foregroundStyle(Theme.ink).tint(Theme.orange)
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
        .practiceLessonPresentation(launch: $selectedLesson, namespace: lessonNamespace)
        .onChange(of: selectedLesson?.id, initial: true) {
            if case .review(let lesson) = selectedLesson { onReviewOpen(lesson.id) }
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
            isSearchOpen = false
            showingFilters = false
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
            .listStyle(.sidebar).scrollContentBackground(.hidden)
        }
        .navigationTitle(settings.localized("Library"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            PadToolbarItem(placement: .topBarLeading) {
                BackButton(action: onHome)
            }
        }
    }

    private var introSectionRow: some View {
        let title = settings.localized("Intro exercises")
        let selected = showingIntro
        return Button { showingIntro = true } label: {
            VStack(alignment: .leading, spacing: 0) {
                sidebarLabel(title, lessons: introLessons, isCategory: true, selected: selected)
                Text(settings.localized("%lld exercises · always open", introLessons.count))
                    .font(Theme.meta).foregroundStyle(Theme.secondary).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Theme.Space.regular)
            .padding(.vertical, Theme.Space.tight)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.touch, alignment: .leading)
            .background { sidebarSelection(selected) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .listRowInsets(EdgeInsets(top: Theme.Space.tight, leading: Theme.Space.regular, bottom: Theme.Space.tight, trailing: Theme.Space.regular))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
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
        .overlay(alignment: .bottom) { sidebarRule.offset(y: Theme.Space.tight) }
    }
    private var organiseSection: some View {
        Section {
            PlexSegmentedPicker(title: settings.localized("Organise by"), selection: Binding(
                get: { settings.libraryView }, set: { settings.libraryView = $0 }
            ), options: LibraryViewMode.allCases.map { ($0.id, settings.localized($0.title)) }, fitsColumn: true)
                .listRowInsets(EdgeInsets(top: Theme.Space.small, leading: Theme.Space.regular, bottom: Theme.Space.small, trailing: Theme.Space.regular))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            if mode == .path {
                pathLevelsList
            } else {
                let nonPathGroups = groups.filter { !$0.isExtension && !settings.isCategoryHidden($0.id, in: mode.id) }
                if !nonPathGroups.isEmpty {
                    categoryRows(nonPathGroups)
                        .listRowInsets(EdgeInsets(top: Theme.Space.tight, leading: Theme.Space.regular, bottom: Theme.Space.tight, trailing: Theme.Space.regular))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
        } header: { SectionHeader(title: settings.localized("Organise by")) }
    }

    private var pathLevelsList: some View {
        let levels = (1...5).filter { !settings.isCategoryHidden("level-\($0)", in: mode.id) }
        return ForEach(levels, id: \.self) { level in
            levelView(level)
                .overlay(alignment: .top) {
                    if level != levels.first { sidebarRule }
                }
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
                    categoryRows(levelGroups)
                }
            }
            .padding(.vertical, Theme.Space.tight)
            .listRowInsets(EdgeInsets(top: Theme.Space.tight, leading: Theme.Space.regular, bottom: Theme.Space.small, trailing: Theme.Space.regular))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
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
                .frame(maxWidth: .infinity, minHeight: Theme.Size.touch, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
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
            .listRowBackground(Color.clear)
        }
    }

    private var sidebarRule: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(height: 1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func sidebarSelection(_ selected: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.button)
        return shape.fill(selected ? Theme.surface : Color.clear)
            .overlay(alignment: .leading) {
                if selected { Rectangle().fill(Theme.orange).frame(width: 3) }
            }
            .clipShape(shape)
            .allowsHitTesting(false)
    }

    private func categoryRows(_ items: [LibraryGroup]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    sidebarRule
                }
                sidebarRow(item)
            }
        }
    }

    @ViewBuilder
    private var extensionsSection: some View {
        let visibleExtensions = groups.filter { $0.isExtension && !settings.isCategoryHidden($0.id, in: mode.id) }
        if !visibleExtensions.isEmpty {
            Section {
                categoryRows(visibleExtensions)
                    .listRowInsets(EdgeInsets(top: Theme.Space.tight, leading: Theme.Space.regular, bottom: Theme.Space.tight, trailing: Theme.Space.regular))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } header: {
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    sidebarRule
                    SectionHeader(title: settings.localized("Extensions · outside the Path"))
                }
            }
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
                .listRowBackground(Color.clear)
                .overlay(alignment: .top) { sidebarRule }

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
            isSearchOpen = false
            showingFilters = false
        } label: {
            HStack(spacing: Theme.Space.small) {
                AnimatedLock(locked: locked).font(Theme.meta)
                sidebarLabel(title, lessons: item.lessons, selected: selected)
            }
            .padding(.horizontal, Theme.Space.regular)
            .padding(.vertical, Theme.Space.tight)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.touch, alignment: .leading)
            .background { sidebarSelection(selected) }
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
                    .frame(minHeight: Theme.Size.touch)
            }
            .buttonStyle(PadSecondaryButtonStyle())
            .accessibilityLabel(settings.localized("Show category"))
        }
        .foregroundStyle(Theme.secondary)
        .opacity(0.7)
        .listRowBackground(Color.clear)
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
        let nextLesson = next
        let playNextTitle = settings.localized("Play next")
        let filters = HStack(spacing: Theme.Space.small) {
            magnifierButton
            filtersButton(matching: matching)
        }
        return VStack(alignment: .leading, spacing: Theme.Space.small) {
            if let error = lessonStore.lastLoadError {
                InfoBanner(text: error.localizedDescription, actionTitle: settings.localized("Reload"),
                           action: {
                    try? lessonStore.reload()
                })
            }
            ViewThatFits(in: .horizontal) {
                if let nextLesson {
                    HStack(spacing: Theme.Space.regular) {
                        filters.fixedSize()
                        Spacer(minLength: 0)
                        playNextButton("\(playNextTitle) · \(settings.localized(nextLesson.title))", lesson: nextLesson)
                            .fixedSize()
                    }
                }
                HStack(spacing: Theme.Space.regular) {
                    filters.fixedSize()
                    Spacer(minLength: 0)
                    playNextButton(playNextTitle, lesson: nextLesson).fixedSize()
                }
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    filters
                    playNextButton(playNextTitle, lesson: nextLesson)
                }
            }

            let stageTitle = group.stage.map {
                settings.localized("Level %lld · %@", $0.level, settings.localized(group.title))
            } ?? settings.localized(group.title)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: Theme.Space.regular) {
                    Text(stageTitle)
                        .font(Theme.screenTitle)
                        .foregroundStyle(Theme.ink)
                        .fixedSize()
                    Spacer(minLength: 0)
                    courseProgressIndicator(group: group, shown: filtered.count, total: group.lessons.count)
                        .fixedSize(horizontal: true, vertical: false)
                }
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    Text(stageTitle)
                        .font(Theme.screenTitle)
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    courseProgressIndicator(group: group, shown: filtered.count, total: group.lessons.count)
                }
            }
            .padding(.bottom, Theme.Space.small)
            if let stage = group.stage, !progression.isStageOpen(stage) || progression.canRelockStage(stage) {
                stageBanner(stage).id("stage-lock").transition(motion.transition)
                    .padding(.bottom, Theme.Space.small)
            }
            if isSearchVisible {
                searchBar
                    .transition(motion.transition)
                    .padding(.bottom, Theme.Space.tight)
            }
            List {
                if isGroupAllCompleted && settings.hideCompletedLessons && !isSearching {
                    allCompletedRow
                } else if filtered.isEmpty {
                    Text(settings.localized("No matching lessons")).font(Theme.control)
                        .listRowBackground(Color.clear)
                } else {
                    LessonRowsPanel(lessons: filtered) { lesson in
                        LibraryLessonRow(lesson: lesson, settings: settings, progress: progress,
                                         number: (group.lessons.firstIndex { $0.id == lesson.id } ?? 0) + 1,
                                         showTechnique: mode == .genre,
                                         locked: !progression.isLessonOpen(lesson), purchaseLocked: !store.isUnlocked(lesson), isNext: lesson.id == nextLesson?.id) {
                            open(lesson)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                }
            }
            .environment(\.defaultMinListRowHeight, 60)
            .listStyle(.plain)
            .listSectionSeparator(.hidden)
            .scrollContentBackground(.hidden)
            .contentMargins(.vertical, 0, for: .scrollContent)
            .motion(Theme.Motion.standard, value: filtered.map(\.id))
        }
        .padding(.horizontal, Theme.Space.page).padding(.top, Theme.Space.small)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .calmChassisBackground()
        .motion(Theme.Motion.standard, value: group.stage.map { progression.isStageOpen($0) })
        .onChange(of: isSearchOpen) { _, isOpen in
            if isOpen {
                isSearchFocused = true
            }
        }
    }

    private func playNextButton(_ title: String, lesson: Lesson?) -> some View {
        Button { if let lesson { open(lesson) } } label: {
            Text(title)
                .font(Theme.control)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: Theme.Size.touch)
        }
        .buttonStyle(PadPrimaryButtonStyle())
        .disabled(lesson == nil)
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
                    .frame(minHeight: Theme.Size.touch)
            }
            .buttonStyle(PadSecondaryButtonStyle())
            .accessibilityLabel(settings.localized("Show completed"))
        }
        .padding(.vertical, Theme.Space.small)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
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

    private var magnifierButton: some View {
        Button {
            withAnimation(motion.animation(Theme.Motion.standard)) {
                if isSearchVisible && query.isEmpty {
                    isSearchOpen = false
                    isSearchFocused = false
                } else {
                    isSearchOpen = true
                    isSearchFocused = true
                }
            }
        } label: {
            Image(systemName: "magnifyingglass")
                .font(Theme.meta)
                .frame(width: Theme.Size.touch, height: Theme.Size.touch)
        }
        .buttonStyle(PadIconButtonStyle(selected: isSearchVisible))
        .accessibilityLabel(settings.localized("Search"))
    }

    private func filtersButton(matching: [Lesson]) -> some View {
        Button {
            showingFilters = true
        } label: {
            HStack(spacing: Theme.Space.tight) {
                Image(systemName: "line.3.horizontal.decrease")
                Text(filtersButtonTitle)
            }
            .font(Theme.meta).lineLimit(1)
            .padding(.horizontal, Theme.Space.small)
            .frame(height: Theme.Size.touch)
            .background {
                RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius)
                    .fill(activeFilterGroupCount > 0 ? Theme.activeFill : Theme.Skin.Pad.fill)
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius)
                            .strokeBorder(activeFilterGroupCount > 0 ? Theme.orange : Theme.hairline,
                                          lineWidth: activeFilterGroupCount > 0 ? 1.5 : 1)
                    }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(filtersButtonTitle)
        .popover(isPresented: $showingFilters, arrowEdge: .top) {
            filtersPopover(matching: matching)
        }
    }

    private var searchBar: some View {
        HStack(spacing: Theme.Space.tight) {
            Image(systemName: "magnifyingglass")
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
            TextField(settings.localized("Search"), text: $query)
                .textFieldStyle(.plain)
                .font(Theme.meta)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit { isSearchFocused = false }
            Button {
                withAnimation(motion.animation(Theme.Motion.standard)) {
                    query = ""
                    isSearchOpen = false
                    isSearchFocused = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
                    .frame(width: Theme.Size.touch, height: Theme.Size.touch)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(settings.localized("Close"))
        }
        .padding(.leading, Theme.Space.small)
        .padding(.trailing, 2)
        .frame(height: Theme.Size.touch)
        .background {
            RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius)
                .fill(Theme.Skin.Pad.fill)
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius)
                        .strokeBorder(Theme.hairline, lineWidth: 1)
                }
        }
        .onAppear {
            isSearchFocused = true
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(settings.localized("Search"))
    }

    private func filtersPopover(matching: [Lesson]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            FlowLayout(spacing: Theme.Space.small) {
                ForEach(LibraryStarFilter.allCases) { filter in
                    let count = matching.filter { LibraryStarFilter.classify(progress.progress(for: $0.id)) == filter }.count
                    let selected = settings.libraryStarFilters.contains(filter.id)
                    FilterChip(title: "\(settings.localized(filter.title)) (\(count))", selected: selected) {
                        if selected {
                            settings.libraryStarFilters.removeAll { $0 == filter.id }
                        } else {
                            settings.libraryStarFilters.append(filter.id)
                        }
                    }
                    .frame(height: Theme.Size.touch)
                }
            }

            HStack {
                Text(settings.localized(mode == .genre ? "Technique" : "Genre"))
                    .font(Theme.meta)
                    .foregroundStyle(Theme.secondary)
                Spacer()
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
                        Text(crossTitle)
                            .font(Theme.meta)
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(Theme.meta)
                    }
                    .padding(.horizontal, Theme.Space.small)
                    .frame(height: Theme.Size.touch)
                    .background {
                        RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius)
                            .fill(cross.isEmpty ? Theme.Skin.Pad.fill : Theme.activeFill)
                            .overlay {
                                RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius)
                                    .strokeBorder(cross.isEmpty ? Theme.hairline : Theme.orange, lineWidth: cross.isEmpty ? 1 : 1.5)
                            }
                    }
                }
                .accessibilityValue(crossTitle)
            }

            HStack(alignment: .center) {
                Button {
                    withAnimation(motion.animation(Theme.Motion.standard)) {
                        cross = ""
                        settings.libraryStarFilters = LibraryStarFilter.allCases.map(\.id)
                    }
                } label: {
                    Text(settings.localized("Clear filters"))
                        .font(Theme.meta)
                        .foregroundStyle(activeFilterGroupCount > 0 ? Theme.orange : Theme.secondary)
                        .frame(minHeight: Theme.Size.touch)
                }
                .buttonStyle(.plain)
                .disabled(activeFilterGroupCount == 0)

                Spacer()

                Button {
                    showingFilters = false
                } label: {
                    Text(settings.localized("Done"))
                        .font(Theme.control)
                        .frame(minHeight: Theme.Size.touch)
                        .padding(.horizontal, Theme.Space.regular)
                }
                .buttonStyle(PadPrimaryButtonStyle())
            }
        }
        .padding(Theme.Space.page)
        .frame(width: 360)
        .calmChassisBackground()
        .foregroundStyle(Theme.ink)
        .tint(Theme.orange)
        .presentationCompactAdaptation(.sheet)
    }

    private var crossTitle: String {
        let title = mode == .genre
            ? LessonTechnique(rawValue: cross)?.title
            : LessonGenre(rawValue: cross)?.title
        return settings.localized(title ?? "All")
    }

    private func stageBanner(_ stage: LibraryStage) -> some View {
        let requirement = progression.unlockProgress(for: stage)
        let format = settings.languagePreference == .czech
            ? "%lld / %lld lekcí se 2★ v předchozí etapě"
            : "%lld / %lld lessons with 2★ in the previous stage"
        let message = String(format: format, requirement.completed, requirement.needed)
        let confirmation = progression.stageAccessConfirmation
        let pending = confirmation?.stageID == stage.id
        let relock = progression.canRelockStage(stage)
        let text = pending
            ? settings.localized(confirmation?.action == .relock ? "Really lock %@ again?" : "Really unlock %@?",
                                 progression.title(for: stage.id))
            : relock ? settings.localized("Manually unlocked · no stars yet")
            : message
        let actionTitle = settings.localized(pending
            ? (confirmation?.action == .relock ? "Yes, lock again" : "Yes, unlock")
            : (relock ? "Lock again" : "Unlock"))
        let status = Label {
            Text(text).font(Theme.meta)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: relock ? "lock.open" : "lock").font(Theme.control)
        }
        let accessButton = Button(actionTitle) {
            if pending { progression.confirmStageAccessChange() }
            else { progression.requestStageAccessChange(for: stage.id, action: relock ? .relock : .unlock) }
        }
        let cancelButton = Button(settings.localized("Cancel")) {
            progression.cancelStageAccessChange()
        }
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: Theme.Space.small) {
                status.fixedSize()
                Spacer(minLength: 0)
                accessButton.fixedSize()
                if pending { cancelButton.fixedSize() }
            }
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                status
                accessButton
                if pending { cancelButton }
            }
        }
        .buttonStyle(PadSecondaryButtonStyle())
        .font(Theme.control)
        .foregroundStyle(Theme.ink)
        .padding(Theme.Space.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .instrumentPanel(border: bannerPulse > 0 ? Theme.orange : Theme.hairline)
        .motion(value: text)
        .motion(value: actionTitle)
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
        if progression.isLessonOpen(lesson) {
            selectedLesson = .library(lesson, progress: progress.progress(for: lesson.id), today: AppCalendar.today())
            return
        }
        guard let stage = catalog.stage(for: lesson) else { return }
        settings.libraryView = LibraryViewMode.path.id
        selections[LibraryViewMode.path.id] = stage.id
        expandedLevels.insert(stage.level)
        bannerPulse += 1
    }
}

struct LessonRowsPanel<Row: View>: View {
    let lessons: [Lesson]
    @ViewBuilder let row: (Lesson) -> Row

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                if index > 0 {
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(height: 1)
                        .accessibilityHidden(true)
                }
                row(lesson)
            }
        }
        .instrumentPanel()
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
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
        if record?.lastReviewFailDay == AppCalendar.today() {
            return "Tried today · not met yet"
        }
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
                .buttonStyle(PadIconButtonStyle())
                .accessibilityLabel(settings.localized("Purchase required"))
            }
            if introGoal == nil {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Space.regular) {
                        LessonPatternStrip(hits: lesson.hits, dimmed: locked)
                        settledMark
                        dueMark
                        StarsView(record: record, lesson: lesson)
                    }
                    HStack(spacing: Theme.Space.small) {
                        settledMark
                        dueMark
                        StarsView(record: record, lesson: lesson)
                    }
                }
            } else {
                HStack(spacing: Theme.Space.small) {
                    settledMark
                    dueMark
                    StarsView(record: record, lesson: lesson)
                }
            }
        }
        .padding(.horizontal, Theme.Space.regular)
        .background {
            // Keep the full row tappable without nesting its trailing controls.
            Button(action: onSelect) {
                Color.clear
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)
        }
        .background(isNext ? Theme.activeFill.opacity(0.45) : Color.clear)
        .overlay(alignment: .leading) {
            if isNext {
                Rectangle().fill(Theme.orange).frame(width: 3)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .lessonSource(lesson.id)
    }

    private var isDue: Bool {
        record?.reviewSchedule.isSettled != true && record?.reviewSchedule.isDue(on: AppCalendar.today()) == true
    }

    @ViewBuilder
    private var settledMark: some View {
        if record?.reviewSchedule.isSettled == true {
            Image(systemName: "checkmark")
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
                .accessibilityLabel(settings.localized("Settled"))
        }
    }

    @ViewBuilder
    private var dueMark: some View {
        if isDue {
            let isTried = record?.lastReviewFailDay == AppCalendar.today()
            Image(systemName: "clock")
                .font(Theme.meta)
                .foregroundStyle(isTried ? Theme.orange : Theme.ink)
                .accessibilityLabel(settings.localized(isTried ? "Tried today · not met yet" : "Due for review"))
        }
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
