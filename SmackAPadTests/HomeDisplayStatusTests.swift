import XCTest
@testable import SmackAPad

final class HomeDisplayStatusTests: XCTestCase {
    func testMappedNoteStatusText() {
        let profile = ControllerProfile.standard16
        // Note 36 maps to target slot 12 (bottom-left), which is pad 12 ("Kick") in 16-pad layout
        let text = HomeDisplayStatusBuilder.statusText(for: 36, profile: profile)
        XCTAssertEqual(text, "Kick · 36")

        // Note 37 maps to target slot 13, which is pad 13 ("Snare")
        let snareText = HomeDisplayStatusBuilder.statusText(for: 37, profile: profile)
        XCTAssertEqual(snareText, "Snare · 37")
    }

    func testUnmappedNoteStatusText() {
        let profile = ControllerProfile.standard16
        // Note 61 is outside standard 16's mapped range (36...51)
        let text = HomeDisplayStatusBuilder.statusText(for: 61, profile: profile)
        XCTAssertEqual(text, "Note 61 · not mapped")
    }

    func testControllerButtonStatusText() {
        let profile = ControllerProfile.standard16
        var controls = MIDIControlConfiguration()

        // Map note 60 to start/stop
        controls.buttons[MIDIPracticeAction.startStop.rawValue] = MIDIButtonMapping(
            signal: MIDIControlSignal(kind: .note, channel: 1, number: 60)
        )
        // Map CC 20 to restart
        controls.buttons[MIDIPracticeAction.restart.rawValue] = MIDIButtonMapping(
            signal: MIDIControlSignal(kind: .cc, channel: 1, number: 20)
        )

        let startStopText = HomeDisplayStatusBuilder.statusText(for: 60, profile: profile, controls: controls)
        XCTAssertEqual(startStopText, "Start / stop")

        let restartSignal = MIDIControlSignal(kind: .cc, channel: 1, number: 20)
        let restartText = HomeDisplayStatusBuilder.statusText(for: restartSignal, profile: profile, controls: controls)
        XCTAssertEqual(restartText, "Restart")
    }
}
