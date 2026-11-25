import Foundation

// MARK: - Drummer's Path Map Topologies & Nodes

/// Four alternating hardware signal-patch layouts for Drummer's Path stages.
public enum DrummerStageTopology: String, CaseIterable, Equatable, Sendable {
    case straightLine
    case splitFork
    case stepSequencer
    case loopWithSideQuest

    public static func forStageIndex(_ index: Int) -> DrummerStageTopology {
        let cases = Self.allCases
        return cases[abs(index) % cases.count]
    }

    public func title(language: AppLanguage = .english) -> String {
        switch (self, language) {
        case (.straightLine, .english): return "Signal Line"
        case (.straightLine, .czech): return "Signálová linka"
        case (.splitFork, .english): return "Split Fork"
        case (.splitFork, .czech): return "Rozbočení"
        case (.stepSequencer, .english): return "Step Matrix"
        case (.stepSequencer, .czech): return "Krokový sekvencer"
        case (.loopWithSideQuest, .english): return "Loop + Side Quest"
        case (.loopWithSideQuest, .czech): return "Smyčka + výzva"
        }
    }

    public var systemImage: String {
        switch self {
        case .straightLine: return "arrow.right"
        case .splitFork: return "arrow.triangle.branch"
        case .stepSequencer: return "square.grid.3x2"
        case .loopWithSideQuest: return "point.topleft.down.to.point.bottomright.curvepath"
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
    public var id: Int { lesson.id }
    public let lesson: Lesson
    public let orderIndex: Int
    public let isBoss: Bool
    public let isSideQuest: Bool
    /// `nil` = main trunk, `0` = upper/primary branch, `1` = lower/side branch.
    public let branchTrack: Int?
    public let stars: Int
    public let state: DrummerPathNodeState
    public let requiredKit: DrumKitDescriptor
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
}

/// Pure builder converting `LibraryCatalog`, `LessonProgress`, and `DrummerPathState` into stage maps.
public enum DrummerPathMapBuilder {
    static func buildStages(
        catalog: LibraryCatalog,
        progress: [Int: LessonProgress],
        pathState: DrummerPathState,
        language: AppLanguage = .english
    ) -> [DrummerPathStageModel] {
        var result: [DrummerPathStageModel] = []

        if !catalog.introLessons.isEmpty {
            let introTitle = language == .czech ? "Úvod" : "Intro"
            result.append(
                buildStage(
                    id: DrummerPathEvaluator.introExamStageId,
                    index: 0,
                    level: 1,
                    title: introTitle,
                    lessons: catalog.introLessons,
                    topology: .straightLine,
                    progress: progress,
                    pathState: pathState
                )
            )
        }

        for (offset, stage) in catalog.stages.enumerated() {
            let stageIndex = offset + 1
            let topology = DrummerStageTopology.forStageIndex(stageIndex)
            let stageTitle = language.localized(stage.technique.title)
            result.append(
                buildStage(
                    id: stage.id,
                    index: stageIndex,
                    level: stage.level,
                    title: stageTitle,
                    lessons: stage.lessons,
                    topology: topology,
                    progress: progress,
                    pathState: pathState
                )
            )
        }

        return result
    }

    static func buildStage(
        id: String,
        index: Int,
        level: Int,
        title: String,
        lessons: [Lesson],
        topology: DrummerStageTopology,
        progress: [Int: LessonProgress],
        pathState: DrummerPathState
    ) -> DrummerPathStageModel {
        let count = lessons.count
        let kits = lessons.map { DrumKitCatalog.requiredKit(for: $0) }
        let primaryKit = dominantKit(in: kits) ?? DrumKitCatalog.starterKit
        let lockedKit = kits.first { !pathState.isKitUnlocked($0.kitId) }

        let starsList = lessons.map { LibraryStarFilter.stars(progress[$0.id]) }
        let isCompletedList = starsList.map { $0 >= 1 }
        let isUnlockedKitList = kits.map { pathState.isKitUnlocked($0.kitId) }

        // Determine branch assignment and side quests per topology.
        let roles = assignRoles(count: count, topology: topology)
        let activeIndices = computeActiveIndices(
            count: count,
            topology: topology,
            roles: roles,
            isCompleted: isCompletedList,
            isKitUnlocked: isUnlockedKitList
        )

        var nodes: [DrummerPathNode] = []
        nodes.reserveCapacity(count)

        for i in 0..<count {
            let lesson = lessons[i]
            let stars = starsList[i]
            let isBoss = (i == count - 1)
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
                    isBoss: isBoss,
                    isSideQuest: role.isSideQuest,
                    branchTrack: role.branchTrack,
                    stars: stars,
                    state: state,
                    requiredKit: kits[i]
                )
            )
        }

        let examDone = pathState.completedExamStageIDs.contains(id) || (nodes.last?.state == .completed)

        return DrummerPathStageModel(
            id: id,
            index: index,
            level: level,
            title: title,
            topology: topology,
            primaryKit: primaryKit,
            lockedKit: lockedKit,
            nodes: nodes,
            isExamCompleted: examDone
        )
    }

    private struct NodeRole {
        let isSideQuest: Bool
        let branchTrack: Int?
    }

    private static func assignRoles(count: Int, topology: DrummerStageTopology) -> [NodeRole] {
        guard count > 0 else { return [] }
        switch topology {
        case .straightLine, .stepSequencer:
            return Array(repeating: NodeRole(isSideQuest: false, branchTrack: nil), count: count)

        case .splitFork:
            // First 2 nodes on main trunk, last node (Boss) on main trunk; middle nodes split into two branches.
            return (0..<count).map { i in
                if i < 2 || i == count - 1 || count < 5 {
                    return NodeRole(isSideQuest: false, branchTrack: nil)
                }
                let middleOffset = i - 2
                return NodeRole(isSideQuest: false, branchTrack: middleOffset % 2)
            }

        case .loopWithSideQuest:
            // Penultimate node (when count >= 4) acts as an optional memory/bonus side quest off the main loop.
            return (0..<count).map { i in
                if count >= 4 && i == count - 2 {
                    return NodeRole(isSideQuest: true, branchTrack: 1)
                }
                return NodeRole(isSideQuest: false, branchTrack: nil)
            }
        }
    }

    private static func computeActiveIndices(
        count: Int,
        topology: DrummerStageTopology,
        roles: [NodeRole],
        isCompleted: [Bool],
        isKitUnlocked: [Bool]
    ) -> Set<Int> {
        guard count > 0 else { return [] }
        var active: Set<Int> = []

        switch topology {
        case .straightLine, .stepSequencer:
            if let firstPending = (0..<count).first(where: { !isCompleted[$0] }) {
                if isKitUnlocked[firstPending] {
                    active.insert(firstPending)
                }
            }

        case .splitFork:
            // Trunk before fork (0, 1)
            let preFork = (0..<min(2, count)).filter { roles[$0].branchTrack == nil }
            if let firstTrunk = preFork.first(where: { !isCompleted[$0] }) {
                if isKitUnlocked[firstTrunk] { active.insert(firstTrunk) }
                return active
            }
            // Parallel branches: first uncompleted node in branch 0 and branch 1 can both be active.
            let branch0 = (0..<count).filter { roles[$0].branchTrack == 0 }
            let branch1 = (0..<count).filter { roles[$0].branchTrack == 1 }
            var branchPending = false
            if let next0 = branch0.first(where: { !isCompleted[$0] }) {
                branchPending = true
                if isKitUnlocked[next0] { active.insert(next0) }
            }
            if let next1 = branch1.first(where: { !isCompleted[$0] }) {
                branchPending = true
                if isKitUnlocked[next1] { active.insert(next1) }
            }
            // Boss node unlocks once both branches are completed.
            let bossIndex = count - 1
            if !branchPending && !isCompleted[bossIndex] && isKitUnlocked[bossIndex] {
                active.insert(bossIndex)
            }

        case .loopWithSideQuest:
            // Main trunk excludes the optional side quest; side quest unlocks after node 1 (or 0).
            let mainIndices = (0..<count).filter { !roles[$0].isSideQuest }
            if let firstMain = mainIndices.first(where: { !isCompleted[$0] }) {
                if isKitUnlocked[firstMain] { active.insert(firstMain) }
            }
            let sideIndices = (0..<count).filter { roles[$0].isSideQuest }
            let prereqDone = count < 2 || isCompleted[0]
            if prereqDone {
                for sideIdx in sideIndices where !isCompleted[sideIdx] && isKitUnlocked[sideIdx] {
                    active.insert(sideIdx)
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
