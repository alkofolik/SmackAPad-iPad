import SwiftUI
import UIKit
import XCTest
@testable import SmackAPad

final class FirstRunAndLegibilityTests: XCTestCase {
    func testAnyLessonProgressRequiresAnAttemptOrStar() {
        XCTAssertFalse(hasAnyLessonProgress([:]))
        XCTAssertFalse(hasAnyLessonProgress([1: LessonProgress(currentBpm: 80)]))
        XCTAssertTrue(hasAnyLessonProgress([1: LessonProgress(hasPlayed: true)]))
        XCTAssertTrue(hasAnyLessonProgress([1: LessonProgress(memory: true)]))
    }

    func testMIDILearnDisplaysRowsFromBottomWithoutReversingSlotsWithinARow() {
        XCTAssertEqual(PhysicalPadGrid.displaySlots(padCount: 8), [4, 5, 6, 7, 0, 1, 2, 3])
        XCTAssertEqual(PhysicalPadGrid.displaySlots(padCount: 16), [
            12, 13, 14, 15,
            8, 9, 10, 11,
            4, 5, 6, 7,
            0, 1, 2, 3
        ])
    }

    @MainActor
    func testGhostOutlineContrastAgainstTheDarkestMemoryBandInBothAppearances() {
        // The memory band is darkest at target tempo. Its top is shaded with 10% Theme.black.
        let band = BandTone.color(listen: false, memory: true, bpm: 100, startBpm: 75, targetBpm: 100)
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let outline = components(of: PatternField.ghostOutline, traits: traits)
            let shade = components(of: Theme.black, traits: traits)
            let orange = components(of: band, traits: traits)
            let shadedBand = zip(orange, shade).map { $0 * 0.9 + $1 * 0.1 }
            let contrast = (luminance(shadedBand) + 0.05) / (luminance(outline) + 0.05)
            XCTAssertGreaterThanOrEqual(contrast, 3, "\(style): \(contrast):1")
        }
    }

    private func components(of color: Color, traits: UITraitCollection) -> [CGFloat] {
        let resolved = UIColor(color).resolvedColor(with: traits)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        XCTAssertTrue(resolved.getRed(&red, green: &green, blue: &blue, alpha: nil))
        return [red, green, blue]
    }

    private func luminance(_ rgb: [CGFloat]) -> CGFloat {
        zip(rgb, [0.2126, 0.7152, 0.0722]).reduce(0) { luminance, channel in
            let (value, weight) = channel
            let linear = value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
            return luminance + linear * weight
        }
    }
}
