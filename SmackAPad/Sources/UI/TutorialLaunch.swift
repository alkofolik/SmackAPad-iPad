enum TutorialLaunch {
    static let seenKey = "smackapad.tutorial.seen"

    static func shouldPresent(
        loadSucceeded: Bool,
        records: [Int: LessonProgress],
        seen: Bool,
        homeIsIdle: Bool
    ) -> Bool {
        loadSucceeded && homeIsIdle && !seen && !hasAnyLessonProgress(records)
    }
}
