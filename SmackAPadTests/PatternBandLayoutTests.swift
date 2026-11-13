import CoreGraphics
import XCTest
@testable import SmackAPad

final class PatternBandLayoutTests: XCTestCase {
    func testRowFramesStayInsideBandAndBelowRulerForOneToEightRows() {
        let availableHeights: [CGFloat] = [538, 380, 320, 220]
        let widths: [CGFloat] = [1146, 720, 340]

        for rows in 1...8 {
            for availableHeight in availableHeights {
                let bandHeight = PracticeBandStyle.bandHeight(rows: rows, availableHeight: availableHeight)
                XCTAssertLessThanOrEqual(bandHeight, availableHeight, "Band grew past availableHeight for \(rows) rows")
                XCTAssertGreaterThan(bandHeight, 0)

                for width in widths {
                    let geometry = BandGeometry(size: CGSize(width: width, height: bandHeight), rows: rows)
                    XCTAssertEqual(geometry.rowRects.count, rows)
                    XCTAssertGreaterThanOrEqual(
                        geometry.countY - geometry.beatFontSize * 0.5,
                        geometry.spineRulerRect.maxY - 2,
                        "Beat digits collide with top progress strip for \(rows) rows at height \(availableHeight)"
                    )
                    XCTAssertLessThanOrEqual(
                        geometry.tickY + geometry.tickHeight,
                        geometry.rulerRect.maxY,
                        "Ruler ticks extend past rulerRect for \(rows) rows at height \(availableHeight)"
                    )

                    for (index, rect) in geometry.rowRects.enumerated() {
                        XCTAssertGreaterThanOrEqual(rect.minY, geometry.contentRect.minY)
                        XCTAssertLessThanOrEqual(
                            rect.maxY,
                            geometry.contentRect.maxY,
                            "Row \(index) overflows band bottom for \(rows) rows at height \(availableHeight)"
                        )
                        XCTAssertFalse(
                            rect.intersects(geometry.rulerRect),
                            "Row \(index) intersects rulerRect for \(rows) rows at height \(availableHeight)"
                        )
                        XCTAssertFalse(
                            rect.intersects(geometry.spineRulerRect),
                            "Row \(index) intersects spineRulerRect for \(rows) rows at height \(availableHeight)"
                        )
                        if index + 1 < geometry.rowRects.count {
                            XCTAssertLessThanOrEqual(rect.maxY, geometry.rowRects[index + 1].minY)
                        }
                    }
                }
            }
        }
    }

    func testOneToThreePadsKeepUnchangedDimensionsAtRoomyHeight() {
        for rows in 1...3 {
            let bandHeight = PracticeBandStyle.bandHeight(rows: rows, availableHeight: 538)
            let geometry = BandGeometry(size: CGSize(width: 1146, height: bandHeight), rows: rows)
            XCTAssertEqual(geometry.rowHeight, PracticeBandStyle.maxRowHeight, accuracy: 0.01)
            XCTAssertEqual(geometry.headerTintHeight, 76, accuracy: 0.01)
        }
    }

    func testFiveAndEightRowLabelsStayInsideRowHeightAndTruncateInMiddleWhenNarrow() {
        let fivePads = [8, 11, 7, 13, 12]
        let bandHeight = PracticeBandStyle.bandHeight(rows: fivePads.count, availableHeight: 220)
        let geometry = BandGeometry(size: CGSize(width: 340, height: bandHeight), rows: fivePads.count)
        let narrowLabels = PracticeBandStyle.bandLabelLayout(
            rows: fivePads,
            availableWidth: 340,
            rowHeight: geometry.rowHeight,
            barCount: 4
        )
        XCTAssertLessThanOrEqual(narrowLabels.fontSize, geometry.rowHeight * 0.72)
        XCTAssertEqual(Set(narrowLabels.labels.values).count, fivePads.count, "Duplicate pad numbers must stay distinct")
        if let pad9 = narrowLabels.labels[8], let pad12 = narrowLabels.labels[11], pad9.contains("…") || pad12.contains("…") {
            XCTAssertTrue(pad9.hasSuffix("9"))
            XCTAssertTrue(pad12.hasSuffix("12"))
        }

        let eightPads = [8, 11, 7, 2, 3, 4, 13, 12]
        let eightBandHeight = PracticeBandStyle.bandHeight(rows: eightPads.count, availableHeight: 220)
        let eightGeometry = BandGeometry(size: CGSize(width: 340, height: eightBandHeight), rows: eightPads.count)
        let eightLabels = PracticeBandStyle.bandLabelLayout(
            rows: eightPads,
            availableWidth: 340,
            rowHeight: eightGeometry.rowHeight,
            barCount: 4
        )
        XCTAssertLessThanOrEqual(eightLabels.fontSize, eightGeometry.rowHeight * 0.72)
    }

    func testRowOrderForKickSnareHiHatAndOpenHiHat() {
        let kick = 12
        let snare = 13
        let hiHat = 8
        let openHiHat = 7
        let used = Set([kick, snare, hiHat, openHiHat])
        let orderedRows = PadVoice.rowOrder.filter { used.contains($0) }
        XCTAssertEqual(orderedRows, [openHiHat, hiHat, snare, kick])
        XCTAssertEqual(orderedRows.map(PadVoice.displayName), ["Open hi-hat", "Hi-hat", "Snare", "Kick"])
    }
}
