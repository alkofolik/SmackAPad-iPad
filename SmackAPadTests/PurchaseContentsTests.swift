import XCTest
@testable import SmackAPad

@MainActor
final class PurchaseContentsTests: XCTestCase {
    func testFullUnlockCountsOnlyPaidCatalogueLessons() {
        let lessons = LessonStore.shared.lessons
        let contents = PurchaseContents(lessons: lessons, access: "full")

        XCTAssertFalse(lessons.isEmpty)
        XCTAssertEqual(contents.lessonCount, lessons.filter { $0.access == "full" }.count)
        XCTAssertLessThan(contents.lessonCount, lessons.count)
    }

    func testPackCountsOnlyLessonsWithItsAccessValue() {
        let lessons = LessonStore.shared.lessons
        let packAccessValues = Set(lessons.compactMap(\.access).filter { $0.hasPrefix("pack:") })

        for access in packAccessValues {
            let contents = PurchaseContents(lessons: lessons, access: access)
            XCTAssertEqual(contents.lessonCount, lessons.filter { $0.access == access }.count)
        }
        // The current catalogue can have no packs yet; still check pack isolation.
        let access = "pack:purchase-test"
        let packLesson = Lesson(
            id: -1, cat: "test", title: "Pack fixture", genre: "test", tags: [],
            text: "", division: 16, bars: 1, startBpm: 60, targetBpm: 120,
            level: 1, src: "test", hits: [], access: access
        )
        let catalogue = lessons + [packLesson]
        XCTAssertEqual(PurchaseContents(lessons: catalogue, access: access).lessonCount,
                       catalogue.filter { $0.access == access }.count)
    }
}
