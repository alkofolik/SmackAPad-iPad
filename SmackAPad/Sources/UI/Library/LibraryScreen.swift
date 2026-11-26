import SwiftUI

/// Launch parameter determining how the Library screen is initially focused.
public enum LibraryLaunchTarget: Equatable, Sendable {
    case none
    case intro
    case lesson(Lesson)
    case kit(String)
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
    @Environment(\.scenePhase) private var scenePhase
    private var motion: Theme.Motion.Policy { .init(reduced: reduced) }
    @State private var showingSettings = false
    @State private var purchaseAccess: String?
    @State private var bannerPulse = 0
    @State private var isSidebarVisible = true
    @State private var pendingCategoryToHide: PendingHideTarget?
    @State private var isHiddenExpanded = false
    @State private var previewPlayer = LibraryPatternPreviewPlayer()
    @State private var pendingKitId: String?

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
        if case .kit(let kitId) = launchTarget {
            _pendingKitId = State(initialValue: kitId)
        } else {
            _pendingKitId = State(initialValue: nil)
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
        VStack(spacing: 0) {
            ScreenTopBar {
                HardwareBackButton {
                    previewPlayer.stop(releaseAudio: true)
                    onHome()
                }
                HardwareIconButton(
                    systemName: "sidebar.left",
                    accessibilityLabel: settings.localized(isSidebarVisible ? "Hide sidebar" : "Show sidebar"),
                    isActive: isSidebarVisible
                ) {
                    withAnimation(motion.animation(Theme.Motion.standard)) {
                        isSidebarVisible.toggle()
                    }
                }
            } center: {
                if settings.playMode == .story {
                    StudioHardwareTabSwitcher(activeTab: .library) { tab in
                        guard tab != .library else { return }
                        previewPlayer.stop(releaseAudio: true)
                        onHome()
                        AppNavigation.shared.openTraining(tab: tab.rawValue)
                    }
                }
            } trailing: {
                Button { showingSettings = true } label: {
                    Text(settings.localized("Settings"))
                        .font(Theme.control)
                        .frame(minHeight: Theme.Size.touch)
                }
                .buttonStyle(PadSecondaryButtonStyle())
            }
            .padding(.horizontal, Theme.Space.page)
            .padding(.vertical, Theme.Space.small)
            .background(Theme.chassis)

            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)

            HStack(spacing: 0) {
                if isSidebarVisible {
                    sidebar
                        .frame(width: 310)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(width: 1)
                }

                Group {
                    if showingIntro { IntroScreen { open($0) }.id("intro").transition(motion.transition) }
                    else if let group { detail(group).id(mode.id + group.id).transition(motion.transition) }
                    else {
                        Text(settings.localized("No matching lessons"))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.chassis)
                .motion(Theme.Motion.standard, value: showingIntro ? "intro" : mode.id + (group?.id ?? ""))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .font(Theme.control)
        .background(Theme.chassis.ignoresSafeArea())
        .foregroundStyle(Theme.ink).tint(Theme.orange)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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
        .onAppear {
            applyPendingKitSelectionIfNeeded()
        }
        .onChange(of: selectedLesson?.id) { _, id in
            if let id {
                previewPlayer.stop(releaseAudio: true)
                practicedID = id
                starsBefore = starSet(id)
                returnedStars = [:]
                consumedStarLessons = []
            } else if let practicedID {
                returnedStars = [practicedID: Theme.Motion.newStars(before: starsBefore, after: starSet(practicedID))]
            }
        }
        .onChange(of: settings.libraryView) { _, _ in
            previewPlayer.stop(releaseAudio: false)
            query = ""; cross = ""; showingIntro = false; progression.cancelStageAccessChange()
            isHiddenExpanded = false
            pendingCategoryToHide = nil
            isSearchOpen = false
            showingFilters = false
        }
        .onChange(of: group?.id) { _, _ in
            previewPlayer.stop(releaseAudio: false)
            progression.cancelStageAccessChange()
        }
        .onChange(of: showingIntro) { _, _ in
            previewPlayer.stop(releaseAudio: false)
            progression.cancelStageAccessChange()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                previewPlayer.stop(releaseAudio: true)
            }
        }
        .onDisappear {
            previewPlayer.stop(releaseAudio: true)
        }
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
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.regular) {
                    if !isIntroHidden {
                        introSectionRow
                    }
                    organiseSection
                    extensionsSection
                    hiddenCategoriesSection
                }
                .padding(.horizontal, Theme.Space.regular)
                .padding(.vertical, Theme.Space.small)
            }
            .scrollIndicators(.hidden)
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
        }
        .background(Theme.surface)
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
        .instrumentPanel(border: selected ? Theme.orange : Theme.hairline)
        .accessibilityAddTraits(selected ? .isSelected : [])
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
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            SectionHeader(title: settings.localized("Organise by"))
            PlexSegmentedPicker(
                title: settings.localized("Organise by"),
                selection: Binding(get: { settings.libraryView }, set: { settings.libraryView = $0 }),
                options: LibraryViewMode.allCases.map { ($0.id, settings.localized($0.title)) },
                fitsColumn: true,
                size: .compact
            )
            if mode == .path {
                pathLevelsList
            } else {
                let nonPathGroups = groups.filter { !$0.isExtension && !settings.isCategoryHidden($0.id, in: mode.id) }
                if !nonPathGroups.isEmpty {
                    categoryRows(nonPathGroups)
                        .instrumentPanel()
                }
            }
        }
    }

    private var pathLevelsList: some View {
        let levels = (1...5).filter { !settings.isCategoryHidden("level-\($0)", in: mode.id) }
        return ForEach(levels, id: \.self) { level in
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
        let hasSelectedChild = !showingIntro && levelGroups.contains { $0.id == group?.id }

        if isExpanded {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    expandedLevels.remove(level)
                } label: {
                    HStack(spacing: Theme.Space.small) {
                        Image(systemName: "chevron.right")
                            .rotationEffect(motion.angle(90))
                            .font(Theme.meta)
                            .foregroundStyle(hasSelectedChild ? Theme.orange : Theme.secondary)
                            .frame(width: 16)
                        sidebarLabel(levelTitle,
                                     lessons: levelLessons,
                                     isCategory: true,
                                     isStrong: true)
                    }
                    .padding(.horizontal, Theme.Space.regular)
                    .padding(.vertical, Theme.Space.tight)
                    .frame(maxWidth: .infinity, minHeight: Theme.Size.touch, alignment: .leading)
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
                    sidebarRule
                    categoryRows(levelGroups)
                }
            }
            .instrumentPanel()
        } else {
            Button {
                expandedLevels.insert(level)
            } label: {
                HStack(spacing: Theme.Space.small) {
                    Image(systemName: "chevron.right")
                        .rotationEffect(motion.angle(0))
                        .font(Theme.meta)
                        .foregroundStyle(hasSelectedChild ? Theme.orange : Theme.secondary)
                        .frame(width: 16)
                    sidebarLabel(levelTitle,
                                 lessons: levelLessons,
                                 isCategory: true,
                                 isStrong: false)
                }
                .padding(.horizontal, Theme.Space.regular)
                .padding(.vertical, Theme.Space.tight)
                .frame(maxWidth: .infinity, minHeight: Theme.Size.touch, alignment: .leading)
                .background {
                    if hasSelectedChild {
                        Rectangle().fill(Theme.orange).frame(width: 3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .instrumentPanel(border: hasSelectedChild ? Theme.orange.opacity(0.6) : Theme.hairline)
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
        Rectangle()
            .fill(selected ? Theme.activeFill : Color.clear)
            .overlay(alignment: .leading) {
                if selected { Rectangle().fill(Theme.orange).frame(width: 3) }
            }
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
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                SectionHeader(title: settings.localized("Extensions · outside the Path"))
                categoryRows(visibleExtensions)
                    .instrumentPanel()
            }
        }
    }

    @ViewBuilder
    private var hiddenCategoriesSection: some View {
        if !hiddenItems.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                sidebarRule
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
                    .frame(maxWidth: .infinity, minHeight: Theme.Size.touch, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(settings.localized(isHiddenExpanded ? "Expanded" : "Collapsed"))

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
            if settings.playMode == .free, let stage = group.stage {
                bossStageAction(stage)
            }
            if isSearchVisible {
                searchBar
                    .transition(motion.transition)
                    .padding(.bottom, Theme.Space.tight)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.small) {
                    if isGroupAllCompleted && settings.hideCompletedLessons && !isSearching {
                        allCompletedRow
                    } else if filtered.isEmpty {
                        Text(settings.localized("No matching lessons"))
                            .font(Theme.control)
                            .foregroundStyle(Theme.secondary)
                            .padding(.vertical, Theme.Space.regular)
                    } else {
                        LessonRowsPanel(lessons: filtered) { lesson in
                            LessonRow(
                                lesson: lesson,
                                settings: settings,
                                progress: progress,
                                number: (group.lessons.firstIndex { $0.id == lesson.id } ?? 0) + 1,
                                showTechnique: mode == .genre,
                                locked: !progression.isLessonOpen(lesson),
                                purchaseLocked: !store.isUnlocked(lesson),
                                isNext: lesson.id == nextLesson?.id,
                                isPreviewPlaying: previewPlayer.playingLessonID == lesson.id,
                                previewAnchorHostTime: previewPlayer.anchorHostTime,
                                previewSecondsPerStep: previewPlayer.secondsPerStep,
                                onTogglePreview: { previewPlayer.toggle(lesson: lesson, settings: settings, pathState: progress.drummerPath) }
                            ) {
                                open(lesson)
                            }
                        }
                    }
                }
                .padding(.bottom, Theme.Space.page)
            }
            .scrollIndicators(.hidden)
            .motion(Theme.Motion.standard, value: filtered.map(\.id))
        }
        .padding(.horizontal, Theme.Space.page).padding(.top, Theme.Space.small)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.chassis)
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

        let countText = shown < total
            ? settings.localized("Shown %lld of %lld", shown, total)
            : settings.localized("%lld lessons", total)

        return VStack(alignment: .leading, spacing: Theme.Space.tight) {
            HStack(spacing: Theme.Space.small) {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill").font(Theme.meta).foregroundStyle(Theme.orange)
                    Text("\(earnedStars)/\(maxStars)").font(Theme.meta).monospacedDigit()
                }
                Spacer(minLength: 4)
                Text(countText)
                    .font(Theme.meta).foregroundStyle(Theme.secondary).fixedSize(horizontal: false, vertical: true)
                    .monospacedDigit()
                    .contentTransition(motion.numeric).motion(value: shown)
            }
            progressLine(group.lessons)
        }
        .frame(minWidth: 180, idealWidth: 240)
    }

    private var magnifierButton: some View {
        HardwareIconButton(
            systemName: "magnifyingglass",
            accessibilityLabel: settings.localized("Search"),
            isActive: isSearchVisible
        ) {
            withAnimation(motion.animation(Theme.Motion.standard)) {
                if isSearchVisible && query.isEmpty {
                    isSearchOpen = false
                    isSearchFocused = false
                } else {
                    isSearchOpen = true
                    isSearchFocused = true
                }
            }
        }
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
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, Theme.Space.small)
            .frame(height: 40)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.control)
                    .fill(activeFilterGroupCount > 0 ? Theme.activeFill : Theme.surfaceElevated)
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.control)
                            .strokeBorder(activeFilterGroupCount > 0 ? Theme.accent : Theme.hairline,
                                          lineWidth: activeFilterGroupCount > 0 ? 1.5 : 1)
                    }
            }
        }
        .buttonStyle(.plain)
        .frame(minHeight: Theme.Size.minimumTouch)
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

    @ViewBuilder
    private func bossStageAction(_ stage: LibraryStage) -> some View {
        let mastered = stage.lessons.count { LibraryStarFilter.stars(progress.progress(for: $0.id)) >= 2 }
        let needed = ProgressionConstant.requiredStageCompletions(lessonCount: stage.lessons.count)
        let defeated = progress.drummerPath.completedExamStageIDs.contains(stage.id)
        let lesson = BossEncounter.pattern(in: stage.lessons, stageID: stage.id, progress: progress.records,
                                          eligible: store.isUnlocked)
        if defeated || mastered >= needed, let lesson {
            Button {
                previewPlayer.stop(releaseAudio: true)
                selectedLesson = .boss(BossEncounter(stageID: stage.id, level: stage.level, lesson: lesson))
            } label: {
                Label(settings.localized(defeated ? "Replay the boss" : "Face the boss"),
                      systemImage: BossEncounter.emblem(for: stage.id))
            }
            .buttonStyle(PadSecondaryButtonStyle())
        } else if mastered < needed && !defeated && stage.lessons.contains(where: store.isUnlocked) {
            Text(settings.localized("Earn ★2 on %lld more lessons in this stage to unlock the boss.", needed - mastered))
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
        }
    }

    private func open(_ lesson: Lesson) {
        previewPlayer.stop(releaseAudio: true)
        guard store.isUnlocked(lesson) else {
            purchaseAccess = lesson.access ?? "full"
            return
        }
        if progression.isLessonOpen(lesson) {
            selectedLesson = .library(lesson, progress: progress.progress(for: lesson.id), today: AppCalendar.today())
            return
        }
    }

    private func applyPendingKitSelectionIfNeeded() {
        guard let kitId = pendingKitId else { return }
        pendingKitId = nil
        let genreGroups = catalog.groups(in: .genre)
        if let match = genreGroups.first(where: { group in
            group.lessons.contains { DrumKitCatalog.requiredKitId(for: $0) == kitId }
        }) {
            settings.libraryView = LibraryViewMode.genre.id
            selections[LibraryViewMode.genre.id] = match.id
            showingIntro = false
            return
        }
        let pathGroups = catalog.groups(in: .path)
        if let match = pathGroups.first(where: { group in
            group.lessons.contains { DrumKitCatalog.requiredKitId(for: $0) == kitId }
        }) {
            settings.libraryView = LibraryViewMode.path.id
            selections[LibraryViewMode.path.id] = match.id
            if let lvl = match.stage?.level { expandedLevels.insert(lvl) }
            showingIntro = false
        }
    }
}
