import XCTest
@testable import SmackAPad

final class StoryMapTests: XCTestCase {
    func testBundledStoryMapParsesAndCoversAllPathStagesAndLessons() throws {
        let map = try StoryMap.loadBundled()
        let catalog = LessonStore.shared.libraryCatalog

        XCTAssertEqual(map.stages.count, 23)
        XCTAssertEqual(Set(map.stages.keys), Set(catalog.stages.map(\.id)))

        try map.validate(against: catalog)

        let pathLessons = catalog.path.filter { $0.cat != "intro" }
        XCTAssertEqual(pathLessons.count, 550)

        var seenLessonIds: [Int] = []
        for stage in catalog.stages {
            let nodes = map.nodes(for: stage.id)
            XCTAssertFalse(nodes.isEmpty, "Stage \(stage.id) should not be empty")
            XCTAssertTrue(nodes.first?.isKeystone == true, "Stage \(stage.id) must start with a keystone")
            XCTAssertTrue(nodes.last?.isKeystone == true, "Stage \(stage.id) must end with a keystone")

            let stageExpectedIds = Set(stage.lessons.filter { $0.cat != "intro" }.map(\.id))
            var stageActualIds: [Int] = []
            for node in nodes {
                if case .fork(let ids) = node {
                    XCTAssertTrue((2...3).contains(ids.count), "Fork in \(stage.id) must have 2–3 lessons")
                }
                stageActualIds.append(contentsOf: node.lessonIds)
            }
            XCTAssertEqual(stageActualIds.count, stageExpectedIds.count, "Duplicate or missing lesson in \(stage.id)")
            XCTAssertEqual(Set(stageActualIds), stageExpectedIds, "Lessons in \(stage.id) must belong to that stage")
            seenLessonIds.append(contentsOf: stageActualIds)
        }

        XCTAssertEqual(seenLessonIds.count, pathLessons.count)
        XCTAssertEqual(Set(seenLessonIds), Set(pathLessons.map(\.id)))

        let introIds = Set(catalog.introLessons.map(\.id))
        let extensionIds = Set(catalog.lessons.filter(LibraryCatalog.isExtension).map(\.id))
        XCTAssertTrue(Set(seenLessonIds).isDisjoint(with: introIds))
        XCTAssertTrue(Set(seenLessonIds).isDisjoint(with: extensionIds))
    }
}
