import Foundation

// MARK: - Drummer's Path Map Topologies & Nodes

/// Six distinct left-to-right hardware signal-patch layouts for Drummer's Path stages and pages.
public enum DrummerStageTopology: String, CaseIterable, Equatable, Sendable {
    case signalLine
    case serpentine
    case diagonalClimb
    case chevronWave
    case splitFork
    case steppedArc

    private static func stableHash(_ text: String) -> UInt64 {
        var hash: UInt64 = 14695981039346656037
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return hash
    }

    /// Selects a deterministic topology for a stage base identity, never matching the previous stage.
    public static func topology(
        forStageId stageId: String,
        previousStageTopology: DrummerStageTopology? = nil
    ) -> DrummerStageTopology {
        let cases = Self.allCases
        let startIdx = Int(stableHash(stageId) % UInt64(cases.count))
        let candidate = cases[startIdx]
        if candidate == previousStageTopology {
            return cases[(startIdx + 1) % cases.count]
        }
        return candidate
    }

    /// Resolves a deterministic topology for every page/block in a stage so adjacent blocks never repeat,
    /// blocks with fewer than 4 nodes only use `signalLine` or `diagonalClimb`,
    /// and multi-block Boss finale blocks (when >= 4 nodes) prefer `diagonalClimb` or `splitFork`.
    public static func topologiesForStage(
        stageId: String,
        pageCount: Int,
        bossPageIndex: Int?,
        stageBaseTopology: DrummerStageTopology,
        nodeCounts: [Int] = []
    ) -> [DrummerStageTopology] {
        guard pageCount > 0 else { return [] }
        let cases = Self.allCases
        var result: [DrummerStageTopology] = []
        result.reserveCapacity(pageCount)

        for pageIndex in 0..<pageCount {
            let pageNodeCount = nodeCounts.indices.contains(pageIndex) ? nodeCounts[pageIndex] : 6
            let prev = pageIndex > 0 ? result[pageIndex - 1] : nil
            let isMultiPageBoss = pageCount > 1 && bossPageIndex == pageIndex

            if pageNodeCount < 4 {
                let preferred: DrummerStageTopology = isMultiPageBoss ? .diagonalClimb : .signalLine
                if preferred == prev {
                    result.append(preferred == .diagonalClimb ? .signalLine : .diagonalClimb)
                } else {
                    result.append(preferred)
                }
                continue
            }

            if pageIndex == 0 {
                result.append(stageBaseTopology)
                continue
            }

            if isMultiPageBoss {
                let pickDiagonal = (stableHash("\(stageId)#\(pageIndex)#boss") & 1) == 0
                let preferred: DrummerStageTopology = pickDiagonal ? .diagonalClimb : .splitFork
                if preferred == prev {
                    result.append(preferred == .diagonalClimb ? .splitFork : .diagonalClimb)
                } else {
                    result.append(preferred)
                }
                continue
            }

            var idx = Int(stableHash("\(stageId)#page#\(pageIndex)") % UInt64(cases.count))
            for _ in 0..<cases.count {
                let candidate = cases[idx]
                if candidate != prev {
                    result.append(candidate)
                    break
                }
                idx = (idx + 1) % cases.count
            }
        }

        return result
    }

    public func title(language: AppLanguage = .english) -> String {
        switch (self, language) {
        case (.signalLine, .english): return "Signal Line"
        case (.signalLine, .czech): return "Signálová linka"
        case (.serpentine, .english): return "Serpentine"
        case (.serpentine, .czech): return "Hadí dráha"
        case (.diagonalClimb, .english): return "Diagonal Climb"
        case (.diagonalClimb, .czech): return "Diagonální výstup"
        case (.chevronWave, .english): return "Chevron Wave"
        case (.chevronWave, .czech): return "W-vlna"
        case (.splitFork, .english): return "Split Fork"
        case (.splitFork, .czech): return "Rozbočení"
        case (.steppedArc, .english): return "Stepped Arc"
        case (.steppedArc, .czech): return "Obloukový most"
        }
    }

    public var systemImage: String {
        switch self {
        case .signalLine: return "arrow.right"
        case .serpentine: return "point.topleft.down.to.point.bottomright.curvepath"
        case .diagonalClimb: return "arrow.up.right"
        case .chevronWave: return "waveform.path.ecg"
        case .splitFork: return "arrow.triangle.branch"
        case .steppedArc: return "chart.line.uptrend.xyaxis"
        }
    }
}

/// Visual and playable state of a node on the Drummer's Path map.
public enum DrummerPathNodeState: Equatable, Sendable {
    case completed
    case active
    case locked
}

/// Single lesson node in a Drummer's Path stage.
public struct DrummerPathNode: Identifiable, Equatable, Sendable {
    public var id: Int { isBoss ? -(1_000_000 + lesson.id) : lesson.id }
    public let lesson: Lesson
    public let orderIndex: Int
    public let isBoss: Bool
    public let isSideQuest: Bool
    /// `nil` = main trunk, `0` = upper/primary branch, `1` / `2` = lower/side branches.
    public let branchTrack: Int?
    public let storyNodeIndex: Int?
    public let forkOptionIndex: Int?
    public let isChosenRoute: Bool
    public let stars: Int
    public let state: DrummerPathNodeState
    public let requiredKit: DrumKitDescriptor

    public init(
        lesson: Lesson,
        orderIndex: Int,
        isBoss: Bool,
        isSideQuest: Bool,
        branchTrack: Int?,
        storyNodeIndex: Int? = nil,
        forkOptionIndex: Int? = nil,
        isChosenRoute: Bool = true,
        stars: Int,
        state: DrummerPathNodeState,
        requiredKit: DrumKitDescriptor
    ) {
        self.lesson = lesson
        self.orderIndex = orderIndex
        self.isBoss = isBoss
        self.isSideQuest = isSideQuest
        self.branchTrack = branchTrack
        self.storyNodeIndex = storyNodeIndex
        self.forkOptionIndex = forkOptionIndex
        self.isChosenRoute = isChosenRoute
        self.stars = stars
        self.state = state
        self.requiredKit = requiredKit
    }
}

/// Complete stage representation for the Drummer's Path signal map.
public struct DrummerPathStageModel: Identifiable, Equatable, Sendable {
    public let id: String
    public let index: Int
    public let level: Int
    public let title: String
    public let topology: DrummerStageTopology
    public let primaryKit: DrumKitDescriptor
    public let lockedKit: DrumKitDescriptor?
    public let nodes: [DrummerPathNode]
    public let isExamCompleted: Bool
    public let isStageOpen: Bool
    public let requiredMasteriesForBoss: Int
    public let masteredLessonCount: Int

    public var missingMasteriesForBoss: Int {
        max(0, requiredMasteriesForBoss - masteredLessonCount)
    }

    public var completedCount: Int {
        nodes.filter { $0.state == .completed }.count
    }

    public var totalCount: Int {
        nodes.count
    }

    public var activeNode: DrummerPathNode? {
        nodes.first { $0.state == .active }
    }

    public var bossNode: DrummerPathNode? {
        nodes.last { $0.isBoss }
    }

    var bossEncounter: BossEncounter? {
        guard index > 0, let bossNode, bossNode.state != .locked, bossNode.stars >= 2 else { return nil }
        return BossEncounter(stageID: id, level: level, lesson: bossNode.lesson)
    }
}

/// Pure builder converting `LibraryCatalog`, `LessonProgress`, and `DrummerPathState` into stage maps.
public enum DrummerPathMapBuilder {
    private static let buildStagesCountLock = NSLock()
    nonisolated(unsafe) private static var _buildStagesCountForTesting = 0

    static var buildStagesCountForTesting: Int {
        buildStagesCountLock.lock()
        defer { buildStagesCountLock.unlock() }
        return _buildStagesCountForTesting
    }

    static func resetBuildStagesCountForTesting() {
        buildStagesCountLock.lock()
        _buildStagesCountForTesting = 0
        buildStagesCountLock.unlock()
    }

    private static func recordBuildStagesCall() {
        buildStagesCountLock.lock()
        _buildStagesCountForTesting += 1
        buildStagesCountLock.unlock()
    }

    static func buildStages(
        catalog: LibraryCatalog,
        progress: [Int: LessonProgress],
        pathState: DrummerPathState,
        language: AppLanguage = .english,
        storyMap: StoryMap = .bundled,
        openStageIDs: Set<String> = []
    ) -> [DrummerPathStageModel] {
        recordBuildStagesCall()
        var result: [DrummerPathStageModel] = []
        var previousTopology: DrummerStageTopology?

        if !catalog.introLessons.isEmpty {
            let introTitle = language == .czech ? "Úvod" : "Intro"
            let introTopology = DrummerStageTopology.topology(
                forStageId: DrummerPathEvaluator.introExamStageId,
                previousStageTopology: nil
            )
            previousTopology = introTopology
            result.append(
                buildStage(
                    id: DrummerPathEvaluator.introExamStageId,
                    index: 0,
                    level: 1,
                    title: introTitle,
                    lessons: catalog.introLessons,
                    topology: introTopology,
                    progress: progress,
                    pathState: pathState,
                    storyMap: storyMap
                )
            )
        }

        var previousPathStageCompleted = true
        for (offset, stage) in catalog.stages.enumerated() {
            let stageIndex = offset + 1
            let topology = DrummerStageTopology.topology(
                forStageId: stage.id,
                previousStageTopology: previousTopology
            )
            previousTopology = topology
            let stageTitle = language.localized(stage.technique.title)
            let hasPlayedInStage = stage.lessons.contains {
                progress[$0.id]?.passed == true || progress[$0.id]?.hasPlayed == true
            }
            let stageIsOpen = (stageIndex == 1)
                || previousPathStageCompleted
                || openStageIDs.contains(stage.id)
                || pathState.completedExamStageIDs.contains(stage.id)
                || hasPlayedInStage
            let built = buildStage(
                id: stage.id,
                index: stageIndex,
                level: stage.level,
                title: stageTitle,
                lessons: stage.lessons,
                topology: topology,
                progress: progress,
                pathState: pathState,
                allowActiveNodes: stageIsOpen,
                storyMap: storyMap
            )
            result.append(built)
            previousPathStageCompleted = built.isExamCompleted
        }

        return result
    }

    /// Single source of truth for Story mode lesson availability:
    /// Intro lessons are always open; otherwise a lesson is open when it is a reached
    /// node (keystone, fork alternative, or open boss) on the Story map.
    static func isOpenInStory(
        lesson: Lesson,
        catalog: LibraryCatalog,
        progress: [Int: LessonProgress],
        pathState: DrummerPathState,
        storyMap: StoryMap = .bundled,
        openStageIDs: Set<String> = []
    ) -> Bool {
        if lesson.cat == ProgressionConstant.introCategoryId {
            return true
        }
        let stages = buildStages(
            catalog: catalog,
            progress: progress,
            pathState: pathState,
            storyMap: storyMap,
            openStageIDs: openStageIDs
        )
        return stages.contains { stage in
            stage.nodes.contains { node in
                !node.isBoss && node.lesson.id == lesson.id && (node.state == .completed || node.state == .active)
            }
        }
    }

    /// Computes the full set of Story-open lesson IDs in a single `buildStages` pass.
    static func openStoryLessonIDs(
        catalog: LibraryCatalog,
        progress: [Int: LessonProgress],
        pathState: DrummerPathState,
        storyMap: StoryMap = .bundled,
        openStageIDs: Set<String> = []
    ) -> Set<Int> {
        var openIDs = Set(catalog.introLessons.map(\.id))
        let stages = buildStages(
            catalog: catalog,
            progress: progress,
            pathState: pathState,
            storyMap: storyMap,
            openStageIDs: openStageIDs
        )
        for stage in stages {
            for node in stage.nodes where !node.isBoss && (node.state == .completed || node.state == .active) {
                openIDs.insert(node.lesson.id)
            }
        }
        return openIDs
    }

    static func buildStage(
        id: String,
        index: Int,
        level: Int,
        title: String,
        lessons: [Lesson],
        topology: DrummerStageTopology,
        progress: [Int: LessonProgress],
        pathState: DrummerPathState,
        allowActiveNodes: Bool = true,
        storyMap: StoryMap = .bundled
    ) -> DrummerPathStageModel {
        let count = lessons.count
        let kits = lessons.map { DrumKitCatalog.requiredKit(for: $0) }
        let primaryKit = dominantKit(in: kits) ?? DrumKitCatalog.starterKit

        let starsList = lessons.map { LibraryStarFilter.stars(progress[$0.id]) }
        let isCompletedList = starsList.map { $0 >= 1 }
        let masteredLessonCount = starsList.filter { $0 >= 2 }.count
        let isIntro = (id == DrummerPathEvaluator.introExamStageId)
        let requiredMasteriesForBoss = isIntro ? 0 : ProgressionConstant.requiredStageCompletions(lessonCount: count)

        let mapNodes = storyMap.nodes(for: id)
        let pathLessons = lessons.filter { $0.cat != ProgressionConstant.introCategoryId }
        let useStoryMap = !isIntro
            && !mapNodes.isEmpty
            && Set(mapNodes.flatMap(\.lessonIds)) == Set(pathLessons.map(\.id))

        var nodes: [DrummerPathNode] = []
        nodes.reserveCapacity(count + 1)

        if useStoryMap {
            let lessonsById = Dictionary(lessons.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            var isReached = Array(repeating: false, count: mapNodes.count)
            if allowActiveNodes && !mapNodes.isEmpty {
                isReached[0] = true
                for k in 1..<mapNodes.count {
                    let prevPassed = mapNodes[k - 1].lessonIds.contains {
                        LibraryStarFilter.stars(progress[$0]) >= 1
                    }
                    isReached[k] = isReached[k - 1] && prevPassed
                }
            }

            var orderIndex = 0
            for (nodeIdx, mapNode) in mapNodes.enumerated() {
                switch mapNode {
                case .keystone(let lessonId):
                    guard let lesson = lessonsById[lessonId] else { continue }
                    let stars = LibraryStarFilter.stars(progress[lessonId])
                    let state: DrummerPathNodeState = if stars >= 1 {
                        .completed
                    } else if isReached[nodeIdx] {
                        .active
                    } else {
                        .locked
                    }
                    nodes.append(
                        DrummerPathNode(
                            lesson: lesson,
                            orderIndex: orderIndex,
                            isBoss: false,
                            isSideQuest: false,
                            branchTrack: nil,
                            storyNodeIndex: nodeIdx,
                            forkOptionIndex: nil,
                            isChosenRoute: true,
                            stars: stars,
                            state: state,
                            requiredKit: DrumKitCatalog.requiredKit(for: lesson)
                        )
                    )
                    orderIndex += 1

                case .fork(let ids):
                    let key = StoryMap.forkChoiceKey(stageId: id, nodeIndex: nodeIdx)
                    let chosenId: Int? = {
                        if let saved = pathState.storyForkChoices[key], ids.contains(saved) {
                            return saved
                        }
                        var bestId: Int?
                        var bestStars = 0
                        for candidateId in ids {
                            let s = LibraryStarFilter.stars(progress[candidateId])
                            if s > bestStars {
                                bestStars = s
                                bestId = candidateId
                            }
                        }
                        return bestStars > 0 ? bestId : nil
                    }()

                    for (optIdx, lessonId) in ids.enumerated() {
                        guard let lesson = lessonsById[lessonId] else { continue }
                        let stars = LibraryStarFilter.stars(progress[lessonId])
                        let state: DrummerPathNodeState = if stars >= 1 {
                            .completed
                        } else if isReached[nodeIdx] {
                            .active
                        } else {
                            .locked
                        }
                        let isChosen = (chosenId == nil) ? (optIdx == 0) : (lessonId == chosenId)
                        let isSideTrail = (chosenId != nil && lessonId != chosenId)
                        nodes.append(
                            DrummerPathNode(
                                lesson: lesson,
                                orderIndex: orderIndex,
                                isBoss: false,
                                isSideQuest: isSideTrail,
                                branchTrack: optIdx,
                                storyNodeIndex: nodeIdx,
                                forkOptionIndex: optIdx,
                                isChosenRoute: isChosen,
                                stars: stars,
                                state: state,
                                requiredKit: DrumKitCatalog.requiredKit(for: lesson)
                            )
                        )
                        orderIndex += 1
                    }
                }
            }
        } else {
            // Fallback for Intro or synthetic test catalogs without StoryMap entries.
            let roles = assignRoles(count: count, topology: topology)
            let activeIndices = allowActiveNodes
                ? computeActiveIndices(
                    count: count,
                    topology: topology,
                    roles: roles,
                    isCompleted: isCompletedList
                )
                : []

            for i in 0..<count {
                let lesson = lessons[i]
                let stars = starsList[i]
                let role = roles[i]

                let state: DrummerPathNodeState
                if isCompletedList[i] {
                    state = .completed
                } else if activeIndices.contains(i) {
                    state = .active
                } else {
                    state = .locked
                }

                nodes.append(
                    DrummerPathNode(
                        lesson: lesson,
                        orderIndex: i,
                        isBoss: false,
                        isSideQuest: role.isSideQuest,
                        branchTrack: role.branchTrack,
                        stars: stars,
                        state: state,
                        requiredKit: kits[i]
                    )
                )
            }
        }

        let examDone = pathState.completedExamStageIDs.contains(id) || (isIntro && count > 0 && isCompletedList.allSatisfy { $0 })
        let bossPattern = isIntro ? nil : BossEncounter.pattern(in: lessons, stageID: id, progress: progress, storyMap: storyMap)
        if let examLesson = bossPattern ?? lessons.last {
            let prereqsComplete: Bool = if isIntro {
                count <= 1 || isCompletedList.dropLast().allSatisfy { $0 }
            } else {
                masteredLessonCount >= requiredMasteriesForBoss
            }
            let bossState: DrummerPathNodeState = if examDone {
                .completed
            } else if allowActiveNodes && prereqsComplete {
                .active
            } else {
                .locked
            }
            nodes.append(
                DrummerPathNode(
                    lesson: examLesson,
                    orderIndex: nodes.count,
                    isBoss: true,
                    isSideQuest: false,
                    branchTrack: nil,
                    stars: LibraryStarFilter.stars(progress[examLesson.id]),
                    state: bossState,
                    requiredKit: DrumKitCatalog.requiredKit(for: examLesson)
                )
            )
        }

        return DrummerPathStageModel(
            id: id,
            index: index,
            level: level,
            title: title,
            topology: topology,
            primaryKit: primaryKit,
            lockedKit: nil,
            nodes: nodes,
            isExamCompleted: examDone,
            isStageOpen: allowActiveNodes,
            requiredMasteriesForBoss: requiredMasteriesForBoss,
            masteredLessonCount: masteredLessonCount
        )
    }

    private struct NodeRole {
        let isSideQuest: Bool
        let branchTrack: Int?
    }

    private static func assignRoles(count: Int, topology: DrummerStageTopology) -> [NodeRole] {
        guard count > 0 else { return [] }
        switch topology {
        case .signalLine, .serpentine, .diagonalClimb, .chevronWave, .steppedArc:
            return Array(repeating: NodeRole(isSideQuest: false, branchTrack: nil), count: count)

        case .splitFork:
            // Nodes 0 & 1 on trunk; nodes 2 & 3 fork into parallel branches; node 4+ merges back to trunk.
            return (0..<count).map { i in
                if i < 2 || count < 5 {
                    return NodeRole(isSideQuest: false, branchTrack: nil)
                }
                if count == 5 && i == 4 {
                    return NodeRole(isSideQuest: false, branchTrack: nil)
                }
                if count == 6 && i >= 4 {
                    return NodeRole(isSideQuest: false, branchTrack: nil)
                }
                let middleOffset = i - 2
                return NodeRole(isSideQuest: false, branchTrack: middleOffset % 2)
            }
        }
    }

    private static func computeActiveIndices(
        count: Int,
        topology: DrummerStageTopology,
        roles: [NodeRole],
        isCompleted: [Bool]
    ) -> Set<Int> {
        guard count > 0 else { return [] }
        var active: Set<Int> = []

        switch topology {
        case .signalLine, .serpentine, .diagonalClimb, .chevronWave, .steppedArc:
            if let firstPending = (0..<count).first(where: { !isCompleted[$0] }) {
                active.insert(firstPending)
            }

        case .splitFork:
            let preFork = (0..<min(2, count)).filter { roles[$0].branchTrack == nil }
            if let firstTrunk = preFork.first(where: { !isCompleted[$0] }) {
                active.insert(firstTrunk)
                return active
            }
            let branch0 = (0..<count).filter { roles[$0].branchTrack == 0 }
            let branch1 = (0..<count).filter { roles[$0].branchTrack == 1 }
            var branchPending = false
            if let next0 = branch0.first(where: { !isCompleted[$0] }) {
                branchPending = true
                active.insert(next0)
            }
            if let next1 = branch1.first(where: { !isCompleted[$0] }) {
                branchPending = true
                active.insert(next1)
            }
            if !branchPending {
                let postMerge = (2..<count).filter { roles[$0].branchTrack == nil }
                if let nextTrunk = postMerge.first(where: { !isCompleted[$0] }) {
                    active.insert(nextTrunk)
                }
            }
        }

        return active
    }

    private static func dominantKit(in kits: [DrumKitDescriptor]) -> DrumKitDescriptor? {
        var counts: [String: Int] = [:]
        var nonStarterFirst: DrumKitDescriptor?
        for kit in kits {
            counts[kit.kitId, default: 0] += 1
            if !kit.isStarter && nonStarterFirst == nil {
                nonStarterFirst = kit
            }
        }
        if let nonStarterFirst {
            return nonStarterFirst
        }
        guard let bestId = counts.max(by: { $0.value < $1.value })?.key else {
            return kits.first
        }
        return kits.first { $0.kitId == bestId }
    }
}
