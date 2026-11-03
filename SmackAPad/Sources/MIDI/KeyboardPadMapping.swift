import Foundation
import GameController

/// Physical keyboard mapping for 16 pads arranged in 4 rows of 4 keys.
/// Uses GCKeyCode to map by physical key position, independent of keyboard layout (QWERTY, QWERTZ, etc.).
public enum KeyboardPadMapping {
    /// Physical key codes corresponding to pads 0..<16 in visual order of `PadLayoutGrid`.
    public static let physicalKeys: [GCKeyCode] = [
        .one, .two, .three, .four,       // Row 1 (top): pads 0, 1, 2, 3
        .keyQ, .keyW, .keyE, .keyR,       // Row 2:       pads 4, 5, 6, 7
        .keyA, .keyS, .keyD, .keyF,       // Row 3:       pads 8, 9, 10, 11
        .keyZ, .keyX, .keyC, .keyV        // Row 4 (bot): pads 12, 13, 14, 15
    ]

    /// Key display labels corresponding to pads 0..<16.
    public static let keyLabels: [String] = [
        "1", "2", "3", "4",
        "Q", "W", "E", "R",
        "A", "S", "D", "F",
        "Z", "X", "C", "V"
    ]

    /// Row definitions for display in Settings.
    public static let rows: [(rowNumber: Int, label: String, keys: [String])] = [
        (1, "Row 1 (top)", ["1", "2", "3", "4"]),
        (2, "Row 2", ["Q", "W", "E", "R"]),
        (3, "Row 3", ["A", "S", "D", "F"]),
        (4, "Row 4 (bottom)", ["Z", "X", "C", "V"])
    ]

    /// Returns the pad index (0..<16) for a physical key code, or nil if unmapped.
    public static func padIndex(for keyCode: GCKeyCode) -> Int? {
        physicalKeys.firstIndex(of: keyCode)
    }

    /// Returns the key display label for a pad index (0..<16), or nil if out of bounds.
    public static func label(for padIndex: Int) -> String? {
        guard keyLabels.indices.contains(padIndex) else { return nil }
        return keyLabels[padIndex]
    }

    /// Returns true if the key code represents a modifier key.
    public static func isModifier(keyCode: GCKeyCode) -> Bool {
        keyCode == .leftGUI || keyCode == .rightGUI ||
        keyCode == .leftControl || keyCode == .rightControl ||
        keyCode == .leftAlt || keyCode == .rightAlt ||
        keyCode == .leftShift || keyCode == .rightShift
    }
}
