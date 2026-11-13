//
//  FaderValueMappingTests.swift
//  SmackAPadTests
//

import CoreGraphics
import XCTest
@testable import SmackAPad

final class FaderValueMappingTests: XCTestCase {
    func testBoundariesZeroAndOneHundred() {
        XCTAssertEqual(FaderValueMapping.volumePercent(fromNormalizedPosition: 0.0), 0)
        XCTAssertEqual(FaderValueMapping.volumePercent(fromNormalizedPosition: 1.0), 100)

        XCTAssertEqual(FaderValueMapping.normalizedPosition(fromVolumePercent: 0), 0.0)
        XCTAssertEqual(FaderValueMapping.normalizedPosition(fromVolumePercent: 100), 1.0)
    }

    func testClampingAtBothEnds() {
        // Below bottom clamps to 0
        XCTAssertEqual(FaderValueMapping.volumePercent(fromNormalizedPosition: -0.01), 0)
        XCTAssertEqual(FaderValueMapping.volumePercent(fromNormalizedPosition: -1.0), 0)
        XCTAssertEqual(FaderValueMapping.volumePercent(fromNormalizedPosition: -100.0), 0)

        // Above top clamps to 100
        XCTAssertEqual(FaderValueMapping.volumePercent(fromNormalizedPosition: 1.01), 100)
        XCTAssertEqual(FaderValueMapping.volumePercent(fromNormalizedPosition: 2.0), 100)
        XCTAssertEqual(FaderValueMapping.volumePercent(fromNormalizedPosition: 100.0), 100)

        // Clamping on volume inputs
        XCTAssertEqual(FaderValueMapping.normalizedPosition(fromVolumePercent: -20), 0.0)
        XCTAssertEqual(FaderValueMapping.normalizedPosition(fromVolumePercent: 150), 1.0)
    }

    func testAllFivePercentStepsRoundTrip() {
        for step in stride(from: 0, through: 100, by: 5) {
            let normalized = FaderValueMapping.normalizedPosition(fromVolumePercent: step)
            let expectedNormalized = CGFloat(step) / 100.0
            XCTAssertEqual(normalized, expectedNormalized, accuracy: 0.0001, "Step \(step) normalized mismatch")

            let recovered = FaderValueMapping.volumePercent(fromNormalizedPosition: normalized)
            XCTAssertEqual(recovered, step, "Step \(step) round-trip mismatch")
        }
    }

    func testYCoordinateMappingAndClamping() {
        let minY: CGFloat = 50.0
        let maxY: CGFloat = 250.0

        // 100% volume sits at top (minY)
        XCTAssertEqual(FaderValueMapping.yPosition(fromVolumePercent: 100, minY: minY, maxY: maxY), minY)
        // 0% volume sits at bottom (maxY)
        XCTAssertEqual(FaderValueMapping.yPosition(fromVolumePercent: 0, minY: minY, maxY: maxY), maxY)
        // 50% volume sits at midpoint
        XCTAssertEqual(FaderValueMapping.yPosition(fromVolumePercent: 50, minY: minY, maxY: maxY), 150.0)

        // Mapping from Y back to percent
        XCTAssertEqual(FaderValueMapping.volumePercent(fromY: minY, minY: minY, maxY: maxY), 100)
        XCTAssertEqual(FaderValueMapping.volumePercent(fromY: maxY, minY: minY, maxY: maxY), 0)
        XCTAssertEqual(FaderValueMapping.volumePercent(fromY: 150.0, minY: minY, maxY: maxY), 50)

        // Clamping above top (y < minY)
        XCTAssertEqual(FaderValueMapping.volumePercent(fromY: 0.0, minY: minY, maxY: maxY), 100)
        XCTAssertEqual(FaderValueMapping.volumePercent(fromY: -100.0, minY: minY, maxY: maxY), 100)

        // Clamping below bottom (y > maxY)
        XCTAssertEqual(FaderValueMapping.volumePercent(fromY: 300.0, minY: minY, maxY: maxY), 0)
        XCTAssertEqual(FaderValueMapping.volumePercent(fromY: 1000.0, minY: minY, maxY: maxY), 0)
    }
}
