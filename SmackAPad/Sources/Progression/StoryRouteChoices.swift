import Foundation

enum StoryRouteActionKind: Equatable, Sendable {
    case forkOption(lesson: Lesson, stageId: String, nodeIndex: Int, optionIndex: Int, title: String)
    case continueTrail(lesson: Lesson)
    case rejoinTrail(lesson: Lesson)
    case otherBranch(lesson: Lesson, stageId: String, nodeIndex: Int, optionIndex: Int)
    case reachGoalTempo
    case faceBoss(lesson: Lesson)
    case exploreSideTrail(lesson: Lesson)
}

struct StoryRouteAction: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let kind: StoryRouteActionKind
}

enum StoryRouteChoiceResolver {
    static func resolve(
        lesson: Lesson,
        catalog: LibraryCatalog,
        progress: [Int: LessonProgress],
        pathState: DrummerPathState,
        storyMap: StoryMap = .bundled,
        openStageIDs: Set<String> = [],
        language: AppLanguage = .english
    ) -> [StoryRouteAction] {
        let stars = LibraryStarFilter.stars(progress[lesson.id])
        guard stars >= 1 else { return [] }
        let lacksStar2 = stars < 2

        if lesson.cat == ProgressionConstant.introCategoryId {
            var actions: [StoryRouteAction] = []
            if let nextIntro = catalog.introLessons.first(where: {
                $0.id != lesson.id && LibraryStarFilter.stars(progress[$0.id]) < 1
            }) {
                actions.append(StoryRouteAction(
                    id: "continue-\(nextIntro.id)",
                    title: language.localized("Continue the trail"),
                    kind: .continueTrail(lesson: nextIntro)
                ))
            } else if let firstStage = catalog.stages.first,
                      let firstNode = storyMap.nodes(for: firstStage.id).first,
                      let firstId = firstNode.lessonIds.first,
                      let firstPathLesson = firstStage.lessons.first(where: { $0.id == firstId }) {
                actions.append(StoryRouteAction(
                    id: "continue-\(firstPathLesson.id)",
                    title: language.localized("Continue the trail"),
                    kind: .continueTrail(lesson: firstPathLesson)
                ))
            }
            if lacksStar2 && actions.count < 3 {
                actions.append(StoryRouteAction(
                    id: "goal-tempo",
                    title: language.localized("Reach goal tempo"),
                    kind: .reachGoalTempo
                ))
            }
            return Array(actions.prefix(3))
        }

        guard let stage = catalog.stages.first(where: { $0.lessons.contains(where: { $0.id == lesson.id }) }) else {
            return []
        }

        let mapNodes = storyMap.nodes(for: stage.id)
        guard let nodeIndex = mapNodes.firstIndex(where: { $0.lessonIds.contains(lesson.id) }) else {
            return []
        }

        let stageModel = DrummerPathMapBuilder.buildStages(
            catalog: catalog,
            progress: progress,
            pathState: pathState,
            language: language,
            storyMap: storyMap,
            openStageIDs: openStageIDs
        ).first(where: { $0.id == stage.id })

        let lessonsById = Dictionary(stage.lessons.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let bossAvailable = stageModel?.bossNode?.state == .active
        let bossLesson = stageModel?.bossNode?.lesson
        let nextNode = (nodeIndex + 1 < mapNodes.count) ? mapNodes[nodeIndex + 1] : nil
        let unfinishedSideTrail = stageModel?.nodes.first(where: {
            $0.isSideQuest && $0.state == .active && $0.lesson.id != lesson.id
        })?.lesson

        var actions: [StoryRouteAction] = []

        switch mapNodes[nodeIndex] {
        case .keystone:
            switch nextNode {
            case .fork(let forkIds):
                for (optIdx, fId) in forkIds.enumerated() {
                    guard actions.count < 3, let fLesson = lessonsById[fId] else { continue }
                    let key = StoryMap.forkStringKey(stageId: stage.id, nodeIndex: nodeIndex + 1, optionIndex: optIdx)
                    let label = language.localizedOptional(key) ?? language.localized(fLesson.title)
                    actions.append(StoryRouteAction(
                        id: "fork-\(stage.id)-\(nodeIndex + 1)-\(optIdx)",
                        title: label,
                        kind: .forkOption(
                            lesson: fLesson,
                            stageId: stage.id,
                            nodeIndex: nodeIndex + 1,
                            optionIndex: optIdx,
                            title: label
                        )
                    ))
                }
                if lacksStar2 && actions.count < 3 {
                    actions.append(StoryRouteAction(
                        id: "goal-tempo",
                        title: language.localized("Reach goal tempo"),
                        kind: .reachGoalTempo
                    ))
                }
                if bossAvailable, let bossLesson, actions.count < 3 {
                    actions.append(StoryRouteAction(
                        id: "face-boss-\(bossLesson.id)",
                        title: language.localized("Face the boss"),
                        kind: .faceBoss(lesson: bossLesson)
                    ))
                }

            case .keystone(let nextId):
                if let nextLesson = lessonsById[nextId] {
                    actions.append(StoryRouteAction(
                        id: "continue-\(nextLesson.id)",
                        title: language.localized("Continue the trail"),
                        kind: .continueTrail(lesson: nextLesson)
                    ))
                }
                if lacksStar2 && actions.count < 3 {
                    actions.append(StoryRouteAction(
                        id: "goal-tempo",
                        title: language.localized("Reach goal tempo"),
                        kind: .reachGoalTempo
                    ))
                }
                if bossAvailable, let bossLesson, actions.count < 3 {
                    actions.append(StoryRouteAction(
                        id: "face-boss-\(bossLesson.id)",
                        title: language.localized("Face the boss"),
                        kind: .faceBoss(lesson: bossLesson)
                    ))
                }

            case nil:
                if bossAvailable, let bossLesson {
                    actions.append(StoryRouteAction(
                        id: "face-boss-\(bossLesson.id)",
                        title: language.localized("Face the boss"),
                        kind: .faceBoss(lesson: bossLesson)
                    ))
                }
                if lacksStar2 && actions.count < 3 {
                    actions.append(StoryRouteAction(
                        id: "goal-tempo",
                        title: language.localized("Reach goal tempo"),
                        kind: .reachGoalTempo
                    ))
                }
                if let sideTrail = unfinishedSideTrail, actions.count < 3 {
                    actions.append(StoryRouteAction(
                        id: "side-trail-\(sideTrail.id)",
                        title: language.localized("Explore side trail"),
                        kind: .exploreSideTrail(lesson: sideTrail)
                    ))
                }
            }

        case .fork(let forkIds):
            if let nextNode, let rejoinId = nextNode.lessonIds.first, let rejoinLesson = lessonsById[rejoinId] {
                actions.append(StoryRouteAction(
                    id: "rejoin-\(rejoinLesson.id)",
                    title: language.localized("Rejoin the trail"),
                    kind: .rejoinTrail(lesson: rejoinLesson)
                ))
            }
            if let otherPair = forkIds.enumerated().first(where: {
                $0.element != lesson.id && LibraryStarFilter.stars(progress[$0.element]) == 0
            }), let otherLesson = lessonsById[otherPair.element], actions.count < 3 {
                actions.append(StoryRouteAction(
                    id: "other-branch-\(otherLesson.id)",
                    title: language.localized("Other branch"),
                    kind: .otherBranch(
                        lesson: otherLesson,
                        stageId: stage.id,
                        nodeIndex: nodeIndex,
                        optionIndex: otherPair.offset
                    )
                ))
            }
            if lacksStar2 && actions.count < 3 {
                actions.append(StoryRouteAction(
                    id: "goal-tempo",
                    title: language.localized("Reach goal tempo"),
                    kind: .reachGoalTempo
                ))
            }
            if bossAvailable, let bossLesson, actions.count < 3 {
                actions.append(StoryRouteAction(
                    id: "face-boss-\(bossLesson.id)",
                    title: language.localized("Face the boss"),
                    kind: .faceBoss(lesson: bossLesson)
                ))
            }
        }

        return Array(actions.prefix(3))
    }

    static func forkLocation(
        for lessonId: Int,
        in catalog: LibraryCatalog,
        storyMap: StoryMap = .bundled
    ) -> (stageId: String, nodeIndex: Int)? {
        for stage in catalog.stages {
            let nodes = storyMap.nodes(for: stage.id)
            for (nodeIndex, node) in nodes.enumerated() {
                if case .fork(let ids) = node, ids.contains(lessonId) {
                    return (stage.id, nodeIndex)
                }
            }
        }
        return nil
    }
}
