import GameController
import XCTest
@testable import SmackAPad

@MainActor
final class KeyboardInputTests: XCTestCase {
    func testMappingTable() {
        // Physical key mapping for 16 pads in visual order:
        // Row 1: 1 2 3 4 -> pads 0 1 2 3
        // Row 2: Q W E R -> pads 4 5 6 7
        // Row 3: A S D F -> pads 8 9 10 11
        // Row 4: Z X C V -> pads 12 13 14 15
        let expectedKeys: [GCKeyCode] = [
            .one, .two, .three, .four,
            .keyQ, .keyW, .keyE, .keyR,
            .keyA, .keyS, .keyD, .keyF,
            .keyZ, .keyX, .keyC, .keyV
        ]

        let expectedLabels = [
            "1", "2", "3", "4",
            "Q", "W", "E", "R",
            "A", "S", "D", "F",
            "Z", "X", "C", "V"
        ]

        XCTAssertEqual(KeyboardPadMapping.physicalKeys.count, 16)
        XCTAssertEqual(KeyboardPadMapping.keyLabels.count, 16)

        for (index, keyCode) in expectedKeys.enumerated() {
            XCTAssertEqual(KeyboardPadMapping.padIndex(for: keyCode), index, "Pad index for key \(keyCode)")
            XCTAssertEqual(KeyboardPadMapping.label(for: index), expectedLabels[index], "Label for pad index \(index)")
        }

        // Unmapped keys return nil
        XCTAssertNil(KeyboardPadMapping.padIndex(for: .spacebar))
        XCTAssertNil(KeyboardPadMapping.padIndex(for: .returnOrEnter))
        XCTAssertNil(KeyboardPadMapping.label(for: 16))
        XCTAssertNil(KeyboardPadMapping.label(for: -1))

        // Modifier checks
        XCTAssertTrue(KeyboardPadMapping.isModifier(keyCode: .leftGUI))
        XCTAssertTrue(KeyboardPadMapping.isModifier(keyCode: .rightGUI))
        XCTAssertTrue(KeyboardPadMapping.isModifier(keyCode: .leftControl))
        XCTAssertTrue(KeyboardPadMapping.isModifier(keyCode: .rightControl))
        XCTAssertTrue(KeyboardPadMapping.isModifier(keyCode: .leftAlt))
        XCTAssertTrue(KeyboardPadMapping.isModifier(keyCode: .rightAlt))
        XCTAssertTrue(KeyboardPadMapping.isModifier(keyCode: .leftShift))
        XCTAssertTrue(KeyboardPadMapping.isModifier(keyCode: .rightShift))
        XCTAssertFalse(KeyboardPadMapping.isModifier(keyCode: .keyA))
        XCTAssertFalse(KeyboardPadMapping.isModifier(keyCode: .one))
    }

    func testKeyUpReleasesRightPad() {
        let suiteName = "test.keyboard.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Could not create test UserDefaults")
            return
        }
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let settings = SettingsManager(userDefaults: userDefaults)
        let midi = MIDIInput(settings: settings)
        let lesson = Lesson(
            id: 9991, cat: "test", title: "Keyboard test", genre: "Rock", tags: [], text: "",
            division: 16, bars: 1, startBpm: 80, targetBpm: 120, level: 1, src: "test",
            hits: [LessonHit(step: 0, padIndex: 0, hand: "R", velocity: 100)]
        )
        midi.setLesson(lesson)

        var emitted: [PadInputEvent] = []
        midi.onPadEvent = { event in
            emitted.append(event)
        }

        // Press pad 4 (Q)
        midi.keyboard(padIndex: 4, isPressed: true, timestamp: 1000)
        XCTAssertEqual(emitted.count, 1)
        XCTAssertEqual(emitted.last?.padIndex, 4)
        XCTAssertEqual(emitted.last?.isNoteOn, true)
        XCTAssertEqual(emitted.last?.deviceID, "keyboard")
        XCTAssertEqual(emitted.last?.timestamp, 1000)
        XCTAssertEqual(midi.pressedPadIndices, [4])

        // Press pad 5 (W) while pad 4 is held
        midi.keyboard(padIndex: 5, isPressed: true, timestamp: 2000)
        XCTAssertEqual(emitted.count, 2)
        XCTAssertEqual(emitted.last?.padIndex, 5)
        XCTAssertEqual(emitted.last?.isNoteOn, true)
        XCTAssertEqual(emitted.last?.deviceID, "keyboard")
        XCTAssertEqual(midi.pressedPadIndices, [4, 5])

        // Auto-repeat of pad 4 should be ignored
        midi.keyboard(padIndex: 4, isPressed: true, timestamp: 2500)
        XCTAssertEqual(emitted.count, 2, "Duplicate key-down should not emit")

        // Release pad 4: only pad 4 is released, pad 5 remains held
        midi.keyboard(padIndex: 4, isPressed: false, timestamp: 3000)
        XCTAssertEqual(emitted.count, 3)
        XCTAssertEqual(emitted.last?.padIndex, 4)
        XCTAssertEqual(emitted.last?.isNoteOn, false)
        XCTAssertEqual(emitted.last?.deviceID, "keyboard")
        XCTAssertEqual(emitted.last?.timestamp, 3000)
        XCTAssertEqual(midi.pressedPadIndices, [5])

        // Release pad 5: pad 5 released, no pads held
        midi.keyboard(padIndex: 5, isPressed: false, timestamp: 4000)
        XCTAssertEqual(emitted.count, 4)
        XCTAssertEqual(emitted.last?.padIndex, 5)
        XCTAssertEqual(emitted.last?.isNoteOn, false)
        XCTAssertEqual(emitted.last?.deviceID, "keyboard")
        XCTAssertEqual(emitted.last?.timestamp, 4000)
        XCTAssertTrue(midi.pressedPadIndices.isEmpty)

        // Spurious key-up for unheld pad does not emit
        midi.keyboard(padIndex: 4, isPressed: false, timestamp: 5000)
        XCTAssertEqual(emitted.count, 4)
    }
}
