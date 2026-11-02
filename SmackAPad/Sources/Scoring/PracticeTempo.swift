/// Value-only tempo policy for the boundary between continuous passes.
struct PracticeTempo {
    static let minimumBpm = 30
    static let maximumBpm = 400
    static func clamp(_ bpm: Int) -> Int { min(maximumBpm, max(minimumBpm, bpm)) }

    private var pendingNextBpm: Int?
    /// The BPM of the pass that was on-screen before the current one started.
    /// `nil` for the very first pass of a run.
    private(set) var previousPassBpm: Int?

    /// Returns a `TempoUpEvent` when the new pass's BPM is higher than the
    /// previous pass's BPM. Returns `nil` on the first pass of a run, when the
    /// tempo stays the same, or after a reset.
    func tempoUpEvent(newBpm: Int) -> TempoUpEvent? {
        guard let prev = previousPassBpm, newBpm > prev else { return nil }
        return TempoUpEvent(from: prev, to: newBpm)
    }

    /// Record the current pass's BPM so the next pass can compare against it.
    mutating func recordPassStart(bpm: Int) {
        previousPassBpm = bpm
    }

    mutating func completed(nextBpm: Int) {
        pendingNextBpm = nextBpm
    }

    mutating func reset() {
        pendingNextBpm = nil
        previousPassBpm = nil
    }

    mutating func queue(after lastQueuedBpm: Int, targetBpm: Int, listenBpm: Int?) -> Int {
        // A result is an absolute request, never another step to add. Consume it
        // once, including when it cannot raise the last queued tempo.
        defer { pendingNextBpm = nil }
        if let listenBpm { return listenBpm }
        return min(targetBpm, max(lastQueuedBpm, pendingNextBpm ?? lastQueuedBpm))
    }
}
