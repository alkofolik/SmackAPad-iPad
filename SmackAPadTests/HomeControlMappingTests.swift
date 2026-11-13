import XCTest
@testable import SmackAPad

final class HomeControlMappingTests: XCTestCase {
    func testLanguageAnglesAndDetentsRoundTrip() {
        for (index, language) in AppLanguage.allCases.enumerated() {
            let angle = LanguageKnobMapping.angle(for: language)
            XCTAssertEqual(LanguageKnobMapping.angle(forDetent: index), angle)
            XCTAssertEqual(LanguageKnobMapping.detent(fromAngle: angle), index)
            XCTAssertEqual(LanguageKnobMapping.language(fromAngle: angle), language)
        }
    }

    func testLanguageSnapsToNearestAndClampsBothEnds() {
        let languages = AppLanguage.allCases
        for index in 0..<(languages.count - 1) {
            let midpoint = (LanguageKnobMapping.angle(forDetent: index)
                + LanguageKnobMapping.angle(forDetent: index + 1)) / 2
            XCTAssertEqual(LanguageKnobMapping.language(fromAngle: midpoint - 0.01), languages[index])
            XCTAssertEqual(LanguageKnobMapping.language(fromAngle: midpoint + 0.01), languages[index + 1])
        }
        XCTAssertEqual(LanguageKnobMapping.language(fromAngle: -360), languages.first)
        XCTAssertEqual(LanguageKnobMapping.language(fromAngle: 360), languages.last)
        XCTAssertEqual(LanguageKnobMapping.angle(forDetent: -1), LanguageKnobMapping.minimumAngle)
        XCTAssertEqual(LanguageKnobMapping.angle(forDetent: languages.count), LanguageKnobMapping.maximumAngle)
    }

    func testAppearancePositionsRoundTrip() {
        for (appearance, position) in [(AppAppearance.light, 0.0), (.system, 0.5), (.dark, 1.0)] {
            XCTAssertEqual(AppearanceSwitchMapping.position(for: appearance), position)
            XCTAssertEqual(AppearanceSwitchMapping.appearance(fromPosition: position), appearance)
        }
    }

    func testAppearanceSnapsAndClampsBothEnds() {
        XCTAssertEqual(AppearanceSwitchMapping.appearance(fromPosition: -1), .light)
        XCTAssertEqual(AppearanceSwitchMapping.appearance(fromPosition: 0.249), .light)
        XCTAssertEqual(AppearanceSwitchMapping.appearance(fromPosition: 0.251), .system)
        XCTAssertEqual(AppearanceSwitchMapping.appearance(fromPosition: 0.749), .system)
        XCTAssertEqual(AppearanceSwitchMapping.appearance(fromPosition: 0.751), .dark)
        XCTAssertEqual(AppearanceSwitchMapping.appearance(fromPosition: 2), .dark)
    }
}
