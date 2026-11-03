import Darwin
import XCTest
@testable import SmackAPad

final class BluetoothTimingTests: XCTestCase {
    private let startHostTime: UInt64 = 1_000_000_000

    private func ticks(_ milliseconds: Double) -> UInt64 {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        let numerator = Double(timebase.numer)
        let denominator = Double(timebase.denom)
        return UInt64((milliseconds * 1_000_000 * denominator / numerator).rounded())
    }

    private func twoBarGrooveLesson() -> Lesson {
        // 2 bars of rock groove: Kick(12), Snare(13), Hat(11).
        // Bar 1: steps 0..15. Bar 2: steps 16..31.
        var hits: [LessonHit] = []
        for step in stride(from: 0, to: 32, by: 2) {
            hits.append(LessonHit(step: step, padIndex: 11, hand: "R", velocity: 80))
        }
        for step in [0, 8, 16, 24] {
            hits.append(LessonHit(step: step, padIndex: 12, hand: "L", velocity: 95))
        }
        for step in [4, 12, 20, 28] {
            hits.append(LessonHit(step: step, padIndex: 13, hand: "L", velocity: 95))
        }
        return Lesson(
            id: 9999, cat: "starter", title: "Two Bar Groove Test", genre: "Rock",
            tags: [], text: "", division: 16, bars: 2, startBpm: 120, targetBpm: 120,
            level: 3, src: "test", hits: hits.sorted { $0.step < $1.step }
        )
    }

    func testCableStyleInputScores100Percent() {
        let lesson = twoBarGrooveLesson()
        var engine = ScoringEngine(lesson: lesson, bpm: 120, startTimestamp: startHostTime)
        let stepDurationMs = 15_000.0 / 120.0 // 125ms per step

        MIDITimestamp.sharedTracker.reset(deviceID: "cable-device")

        for hit in lesson.hits {
            let hitTimeMs = Double(hit.step) * stepDurationMs
            let receipt = startHostTime + ticks(hitTimeMs)
            // Cable: raw timestamp is 0 (untimed)
            let resolved = MIDITimestamp.resolve(0, receivedAt: receipt, deviceID: "cable-device")
            let feedback = engine.receive(padIndex: hit.padIndex, at: resolved.timestamp)
            XCTAssertNotNil(feedback.expectedHitIndex, "Hit at step \(hit.step) pad \(hit.padIndex) should match")
            XCTAssertTrue(feedback.judgment == HitJudgment.perfect || feedback.judgment == HitJudgment.good)
        }

        let result = engine.finish()
        XCTAssertEqual(result.matchedHitCount, lesson.hits.count)
        XCTAssertEqual(result.extraHitCount, 0)
        XCTAssertEqual(result.score, 1.0, accuracy: 0.0001)
    }

    func testSimulatedBluetoothStreamWithJitterAndOffsetMatchesAllHits() {
        let lesson = twoBarGrooveLesson()
        var engine = ScoringEngine(lesson: lesson, bpm: 120, startTimestamp: startHostTime)
        let stepDurationMs = 15_000.0 / 120.0 // 125ms per step

        let deviceID = "ble-controller-test"
        MIDITimestamp.sharedTracker.reset(deviceID: deviceID)

        // Controller clock base is offset by -160ms relative to host mach time,
        // and drifts by +10ms over the 2-bar run (4 seconds).
        let baseOffsetMs = 160.0

        // Group hits by step to simulate BLE batching (chords in single transmission)
        let hitsByStep = Dictionary(grouping: lesson.hits, by: \.step)
        let sortedSteps = hitsByStep.keys.sorted()

        for (stepIndex, step) in sortedSteps.enumerated() {
            let hits = hitsByStep[step]!
            let hitTimeMs = Double(step) * stepDurationMs

            // Drift increases slightly over time
            let driftMs = (Double(stepIndex) / Double(sortedSteps.count)) * 10.0
            let effectiveOffsetMs = baseOffsetMs + driftMs

            // Controller raw timestamp is stamped at physical strike
            let rawTimestamp = startHostTime + ticks(hitTimeMs) - ticks(effectiveOffsetMs)

            // Transmission jitter: packets arrive 15-35ms after physical strike,
            // with a stale packet (50ms delay) on step 16
            let jitterMs = (step == 16) ? 50.0 : (15.0 + Double(step % 3) * 7.0)
            let receiptTime = startHostTime + ticks(hitTimeMs + jitterMs)

            // Feed all batched notes in this step
            for hit in hits {
                let resolved = MIDITimestamp.resolve(rawTimestamp, receivedAt: receiptTime, deviceID: deviceID)
                let feedback = engine.receive(padIndex: hit.padIndex, at: resolved.timestamp)
                XCTAssertNotNil(feedback.expectedHitIndex,
                               "Bluetooth hit at step \(hit.step) pad \(hit.padIndex) should match")
            }
        }

        let result = engine.finish()
        XCTAssertEqual(result.matchedHitCount, lesson.hits.count,
                       "All hits in simulated Bluetooth stream should match")
        XCTAssertEqual(result.extraHitCount, 0, "No extra hits expected")
        XCTAssertEqual(result.score, 1.0, accuracy: 0.0001)
    }

    func testTwoPadsStruckTogetherGetSameJudgment() {
        let lesson = twoBarGrooveLesson()
        var engine = ScoringEngine(lesson: lesson, bpm: 120, startTimestamp: startHostTime)

        let deviceID = "ble-chord-test"
        MIDITimestamp.sharedTracker.reset(deviceID: deviceID)

        // Step 0 has both Hat (pad 11) and Kick (pad 12)
        let rawTimestamp = startHostTime - ticks(140.0) // 140ms controller offset
        let receiptTime = startHostTime + ticks(20.0)   // 20ms BLE delay

        let resolved1 = MIDITimestamp.resolve(rawTimestamp, receivedAt: receiptTime, deviceID: deviceID)
        let feedback1 = engine.receive(padIndex: 11, at: resolved1.timestamp)

        let resolved2 = MIDITimestamp.resolve(rawTimestamp, receivedAt: receiptTime, deviceID: deviceID)
        let feedback2 = engine.receive(padIndex: 12, at: resolved2.timestamp)

        XCTAssertEqual(resolved1.timestamp, resolved2.timestamp, "Simultaneous hits must have identical resolved time")
        XCTAssertEqual(feedback1.judgment, feedback2.judgment, "Simultaneous hits in chord must get same judgment")
    }
}
