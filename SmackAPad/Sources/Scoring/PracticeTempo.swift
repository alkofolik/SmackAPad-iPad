/// Value-only tempo policy for the boundary between continuous passes.
struct PracticeTempo {
    private var pendingNextBpm: Int?

    mutating func completed(nextBpm: Int) {
        pendingNextBpm = nextBpm
    }

    mutating func reset() {
        pendingNextBpm = nil
    }

    mutating func queue(after lastQueuedBpm: Int, targetBpm: Int, listenBpm: Int?) -> Int {
        // A result is an absolute request, never another step to add. Consume it
        // once, including when it cannot raise the last queued tempo.
        defer { pendingNextBpm = nil }
        if let listenBpm { return listenBpm }
        return min(targetBpm, max(lastQueuedBpm, pendingNextBpm ?? lastQueuedBpm))
    }
}
