import Darwin

/// Resolves unreliable MIDI timestamps without leaving the native mach clock domain.
public enum MIDITimestamp {
    private static let limits: (stale: UInt64, future: UInt64) = {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        // Integer division gives the last allowed tick, even for a fractional-tick limit.
        let numerator = UInt64(timebase.numer)
        let denominator = UInt64(timebase.denom)
        return (250_000_000 * denominator / numerator, 50_000_000 * denominator / numerator)
    }()

    public static func resolve(_ timestamp: UInt64, receivedAt receipt: UInt64) -> UInt64 {
        guard timestamp != 0 else { return receipt }
        // Subtract in timestamp order so zero and UInt64.max cannot underflow or overflow.
        if timestamp <= receipt {
            return receipt - timestamp > limits.stale ? receipt : timestamp
        }
        return timestamp - receipt > limits.future ? receipt : timestamp
    }
}
