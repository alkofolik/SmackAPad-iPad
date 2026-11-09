struct LateSoundPolicy {
    private(set) var totalSkipped = 0
    private var currentPassStart: Double?
    private var skippedInPass = 0

    mutating func recordSkip(passStart: Double?) -> Bool {
        totalSkipped += 1
        // Count-in clicks have no pass and do not count toward its limit.
        guard let passStart else { return false }
        if currentPassStart != passStart {
            currentPassStart = passStart
            skippedInPass = 0
        }
        skippedInPass += 1
        return skippedInPass > 3
    }
}
