import Darwin
import XCTest
@testable import SmackAPad

final class MIDITimestampTests: XCTestCase {
    func testPreservesTrustedTimesAndFallsBackOnlyOutsideBLELimits() {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        // Use exact, representable mach ticks for the thresholds from SPEC §3.1.
        let ticksPerMillisecond = UInt64(1_000_000) * UInt64(timebase.denom) / UInt64(timebase.numer)
        let receipt = ticksPerMillisecond * 10_000
        let staleBoundary = receipt - ticksPerMillisecond * 250
        let futureBoundary = receipt + ticksPerMillisecond * 50
        let cases: [(UInt64, UInt64)] = [
            (receipt, receipt),
            (receipt - ticksPerMillisecond * 20, receipt - ticksPerMillisecond * 20),
            (staleBoundary, staleBoundary),
            (staleBoundary - 1, receipt),
            (futureBoundary, futureBoundary),
            (futureBoundary + 1, receipt),
            (0, receipt),
            (UInt64.max, receipt)
        ]
        for (timestamp, expected) in cases {
            XCTAssertEqual(MIDITimestamp.resolve(timestamp, receivedAt: receipt), expected,
                           "MIDI timestamp \(timestamp), receipt \(receipt)")
        }
    }
}
