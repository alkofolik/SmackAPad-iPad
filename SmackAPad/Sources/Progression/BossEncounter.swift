import Foundation

struct BossEncounter: Equatable, Sendable {
    let stageID: String
    let level: Int
    let lesson: Lesson

    var repeats: Int { (8 + lesson.bars - 1) / lesson.bars }
    var bars: Int { repeats * lesson.bars }
    var bpm: Int { lesson.targetBpm * [85, 88, 90, 92, 95][level - 1] / 100 }
    var stamina: Int { (3 * bars + 3) / 4 }

    var veilBars: Set<Int> {
        let count = min(2, level - 1)
        // A bar can only be veiled after the first play of its pattern.
        let first = max(lesson.bars, 2)
        guard count > 0, first < bars else { return [] }
        guard count == 2, first + 2 < bars else { return [first] }
        return [first, max(first + 2, bars - 2)]
    }

    static func pattern(in lessons: [Lesson], stageID: String, progress: [Int: LessonProgress],
                        storyMap: StoryMap = .bundled, eligible: (Lesson) -> Bool = { _ in true }) -> Lesson? {
        let mastered = lessons.filter { LibraryStarFilter.stars(progress[$0.id]) >= 2 && eligible($0) }
        for node in storyMap.nodes(for: stageID).reversed() {
            if case .keystone(let id) = node, let lesson = mastered.first(where: { $0.id == id }) {
                return lesson
            }
        }
        return mastered.first
    }

    static func emblem(for stageID: String) -> String {
        switch stageID.split(separator: "-").last {
        case "groove": return "clock"
        case "sixteenths": return "person.2.fill"
        case "ghost": return "waveform"
        case "swing": return "scalemass.fill"
        default: return "flame.fill"
        }
    }

    static func nameKey(for stageID: String) -> String { "story.boss.\(stageID).name" }
    var nameKey: String { Self.nameKey(for: stageID) }
    var introKey: String { "story.boss.\(stageID).intro" }
    var victoryKey: String { "story.boss.\(stageID).victory" }
}
