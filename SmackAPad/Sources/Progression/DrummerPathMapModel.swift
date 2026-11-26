import Foundation

// MARK: - Drummer's Path Map Topologies & Nodes

/// Six distinct hardware signal-patch layouts for Drummer's Path stages and pages.
public enum DrummerStageTopology: String, CaseIterable, Equatable, Sendable {
    case signalLine
    case serpentine
    case diagonalClimb
    case splitFork
    case chevronWave
    case circuitLoop

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

    /// Resolves a deterministic topology for every page/block in a stage so adjacent blocks never repeat
    /// and multi-block Boss finale blocks prefer `diagonalClimb` or `splitFork`.
    public static func topologiesForStage(
        stageId: String,
        pageCount: Int,
        bossPageIndex: Int?,
        stageBaseTopology: DrummerStageTopology
    ) -> [DrummerStageTopology] {
        guard pageCount > 0 else { return [] }
        let cases = Self.allCases
        var result: [DrummerStageTopology] = []
        result.reserveCapacity(pageCount)

        for pageIndex in 0..<pageCount {
            if pageIndex == 0 {
                result.append(stageBaseTopology)
                continue
            }

            let prev = result[pageIndex - 1]
            let isMultiPageBoss = pageCount > 1 && bossPageIndex == pageIndex
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
            // Keep opening blocks distinct from immediate neighbors.
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
        case (.splitFork, .english): return "Split Fork"
        case (.splitFork, .czech): return "Rozbočení"
        case (.chevronWave, .english): return "Chevron Wave"
        case (.chevronWave, .czech): return "W-vlna"
        case (.circuitLoop, .english): return "Circuit Loop"
        case (.circuitLoop, .czech): return "Obvodová smyčka"
        }
    }

    public var systemImage: String {
        switch self {
        case .signalLine: return "arrow.right"
        case .serpentine: return "square.grid.3x2"
        case .diagonalClimb: return "arrow.up.right"
        case .splitFork: return "arrow.triangle.branch"
        case .chevronWave: return "waveform.path.ecg"
        case .circuitLoop: return "point.topleft.down.to.point.bottomright.curvepath"
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
                    pathState: pathState
                )
            )
        }

        for (offset, stage) in catalog.stages.enumerated() {
            let stageIndex = offset + 1
            let topology = DrummerStageTopology.topology(
                forStageId: stage.id,
                previousStageTopology: previousTopology
            )
            previousTopology = topology
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
        case .signalLine, .serpentine, .diagonalClimb, .chevronWave:
            return Array(repeating: NodeRole(isSideQuest: false, branchTrack: nil), count: count)

        case .splitFork:
            // Nodes 0 & 1 on trunk; nodes 2 & 3 fork into parallel branches; node 4+ merges back to trunk before Boss.
            return (0..<count).map { i in
                if i < 2 || i == count - 1 || count < 5 {
                    return NodeRole(isSideQuest: false, branchTrack: nil)
                }
                if count == 6 && i == 4 {
                    return NodeRole(isSideQuest: false, branchTrack: nil)
                }
                let middleOffset = i - 2
                return NodeRole(isSideQuest: false, branchTrack: middleOffset % 2)
            }

        case .circuitLoop:
            // Penultimate node (when count >= 4) acts as an optional memory/bonus tap inside the perimeter circuit.
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
        case .signalLine, .serpentine, .diagonalClimb, .chevronWave:
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
            // Post-merge trunk & Boss unlock once both branches are completed.
            if !branchPending {
                let postMerge = (2..<count).filter { roles[$0].branchTrack == nil }
                if let nextTrunk = postMerge.first(where: { !isCompleted[$0] }), isKitUnlocked[nextTrunk] {
                    active.insert(nextTrunk)
                }
            }

        case .circuitLoop:
            // Main perimeter excludes the inner tap node; tap node unlocks after node 0 completes.
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
