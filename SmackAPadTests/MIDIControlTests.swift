import XCTest
@testable import SmackAPad

final class MIDIControlTests: XCTestCase {
    private let cc = MIDIControlSignal(kind: .cc, channel: 1, number: 20)

    private func message(_ value: Int, signal: MIDIControlSignal? = nil) -> MIDIControlMessage {
        MIDIControlMessage(signal: signal ?? cc, value: value, deviceID: "controller")
    }

    func testCCButtonEdgesForAllThreeBehaviors() {
        let cases: [(MIDICCButtonBehavior, [Int], [Bool])] = [
            (.rising64, [0, 63, 64, 80, 127, 63, 65, 0], [false, false, true, false, false, false, true, false]),
            (.nonzero, [0, 1, 64, 127, 0, 2, 2], [false, true, false, false, false, true, false]),
            (.everyChange, [0, 1, 1, 0, 0, 127], [false, true, false, true, false, true])
        ]
        for (behavior, values, expected) in cases {
            var config = MIDIControlConfiguration()
            config.buttons["startStop"] = MIDIButtonMapping(signal: cc, behavior: behavior)
            var router = MIDIControlRouter()
            let actual = values.map { router.route(message($0), configuration: config, stoppedTempo: nil) }
            XCTAssertEqual(actual, expected.map { $0 ? .action(.startStop) : .consumed }, behavior.rawValue)
        }
    }

    func testThreeRelativeFormatsDirectionAndLimits() {
        for (mode, positive, negative, neutral) in [
            (MIDIKnobMode.twosComplement, 1, 127, 0),
            (.binaryOffset, 65, 63, 64),
            (.signedBit, 1, 65, 64)
        ] {
            var config = MIDIControlConfiguration()
            config.knob.signal = cc
            config.knob.mode = mode
            var router = MIDIControlRouter()
            XCTAssertEqual(router.route(message(positive), configuration: config, stoppedTempo: 100), .tempo(101))
            XCTAssertEqual(router.route(message(negative), configuration: config, stoppedTempo: 100), .tempo(99))
            XCTAssertEqual(router.route(message(neutral), configuration: config, stoppedTempo: 100), .consumed)
            XCTAssertEqual(router.route(message(positive), configuration: config, stoppedTempo: 400), .tempo(400))
            XCTAssertEqual(router.route(message(negative), configuration: config, stoppedTempo: 30), .tempo(30))
            XCTAssertEqual(router.route(message(positive), configuration: config, stoppedTempo: nil), .consumed)
            config.knob.reversed = true
            XCTAssertEqual(router.route(message(positive), configuration: config, stoppedTempo: 100), .tempo(99))
            XCTAssertEqual(router.route(message(negative), configuration: config, stoppedTempo: 100), .tempo(101))
        }
    }

    func testAbsolutePickupCrossingRearmsAfterExternalTempoChangesAndRuns() {
        var config = MIDIControlConfiguration()
        config.knob.signal = cc
        config.knob.minimumBpm = 50
        config.knob.maximumBpm = 177
        var router = MIDIControlRouter()
        XCTAssertEqual(router.route(message(0), configuration: config, stoppedTempo: 100), .consumed)
        XCTAssertEqual(router.route(message(49), configuration: config, stoppedTempo: 100), .consumed)
        XCTAssertEqual(router.route(message(51), configuration: config, stoppedTempo: 100), .tempo(101))
        XCTAssertEqual(router.route(message(52), configuration: config, stoppedTempo: 101), .tempo(102))
        XCTAssertEqual(router.route(message(53), configuration: config, stoppedTempo: 120), .consumed)
        XCTAssertEqual(router.route(message(90), configuration: config, stoppedTempo: 120), .tempo(140))
        XCTAssertEqual(router.route(message(0), configuration: config, stoppedTempo: nil), .consumed)
        XCTAssertEqual(router.route(message(0), configuration: config, stoppedTempo: 100), .consumed)
        config.knob.reversed = true
        XCTAssertEqual(router.route(message(127), configuration: config, stoppedTempo: 100), .consumed)
        XCTAssertEqual(router.route(message(76), configuration: config, stoppedTempo: 100), .tempo(101))
        config.knob.pickup = false
        XCTAssertEqual(router.route(message(127), configuration: config, stoppedTempo: 100), .tempo(50))
    }

    func testMappedNoteNeverRoutesToPadsIncludingReleasesAndOutsidePractice() {
        let note = MIDIControlSignal(kind: .note, channel: 10, number: 36)
        var config = MIDIControlConfiguration()
        config.buttons["startStop"] = MIDIButtonMapping(signal: note)
        var router = MIDIControlRouter()
        // `.pad` is the only result allowed to reach pad mapping, sound and scoring.
        XCTAssertEqual(router.route(message(100, signal: note), configuration: config, stoppedTempo: 100), .action(.startStop))
        XCTAssertEqual(router.route(message(100, signal: note), configuration: config, stoppedTempo: 100), .consumed)
        XCTAssertEqual(router.route(message(0, signal: note), configuration: config, stoppedTempo: nil), .consumed)
        XCTAssertEqual(router.route(message(100, signal: note), configuration: config, stoppedTempo: nil), .action(.startStop))
        let otherChannel = MIDIControlSignal(kind: .note, channel: 1, number: 36)
        XCTAssertEqual(router.route(message(100, signal: otherChannel), configuration: config, stoppedTempo: 100), .pad)
    }
}
