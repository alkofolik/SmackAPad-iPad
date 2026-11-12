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

    @MainActor
    func testEmptyProfileDoesNotPresentTutorialAndStartsIntroPulse() throws {
        XCTAssertEqual(TutorialCard.allCases.count, 5)

        XCTAssertTrue(shouldPulseIntroPad(loadSucceeded: true, records: [:], animationFinished: true))
        XCTAssertTrue(shouldPulseIntroPad(loadSucceeded: true, records: [1: LessonProgress(currentBpm: 80)], animationFinished: true))
        XCTAssertFalse(shouldPulseIntroPad(loadSucceeded: true, records: [1: LessonProgress(hasPlayed: true)], animationFinished: true))
        XCTAssertFalse(shouldPulseIntroPad(loadSucceeded: true, records: [1: LessonProgress(passed: true)], animationFinished: true))
        XCTAssertFalse(shouldPulseIntroPad(loadSucceeded: false, records: [:], animationFinished: true))
        XCTAssertFalse(shouldPulseIntroPad(loadSucceeded: true, records: [:], animationFinished: false))

        let suite = "FirstRunAndLegibilityTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("FirstRunTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let settings = SettingsManager(userDefaults: defaults)
        let progress = ProgressStore(fileURL: tempDir.appendingPathComponent("progress.json"))
        let lessons = LessonStore.shared
        let progression = ProgressionManager(
            lessonStore: lessons,
            progressStore: progress,
            settingsManager: settings,
            userDefaults: defaults
        )
        let store = StoreManager()
        let badges = BadgeStore(userDefaults: defaults)
        let midi = MIDIInput(settings: settings)

        let root = HomeScreen(isColdStart: false)
            .defaultAppStorage(defaults)
            .environment(store)
            .environment(settings)
            .environment(progress)
            .environment(progression)
            .environment(badges)
            .environment(midi)

        let host = UIHostingController(rootView: root)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        XCTAssertNil(host.presentedViewController)
    }

    func testHelpStringsArePresentInEachLanguageBundle() throws {
        var keys = [
            "help.title", "help.tutorial.reopen", "help.nav.back", "help.nav.topics", "help.nav.position",
            "help.lesson.padRow", "help.lesson.now", "help.lesson.countIn", "help.hit.correct", "help.hit.off",
            "help.hit.wrong", "help.signals.behind", "help.signals.ahead", "help.stars.label", "help.tempo.tap",
            "help.memory.shown", "help.memory.fading", "help.memory.hiddenFromThird", "help.memory.hidden",
            "help.reviews.timeline", "help.reviews.warmups", "help.reviews.twoPasses", "help.library.stage",
            "help.library.progress", "help.keyboard.mapping", "Close", "Skip", "Done", "Next", "Start", "Intro",
            "Today", "Training", "Home", "Starting tempo", "Tempo up: %lld → %lld BPM", "Path", "Genres",
            "Techniques", "MIDI controller", "Details", "Settled", "Did not count", "New lesson", "Mix",
            "Tempo knob", "Play pads with keyboard", "Sound kit", "Timing calibration", "Back up progress",
            "Fade notes in From memory", "Start of plan",
            "Review star: pass two reviews on different days · %lld of 2", "Run finished: star 3 earned, review",
            "Review passed", "Review not passed", "next in 1 day", "next in %lld days", "again tomorrow",
            "Mode", "Listen · Play · After me", "notes hide after 2 good passes in a row",
            "Scrolling / static view", "practice, no stars", "Help", "tap to change", "Start · Stop · Restart"
        ]
        keys += HelpTopic.allCases.flatMap { [$0.titleKey, $0.captionKey] }
        keys += TutorialCard.allCases.flatMap { [$0.titleKey, $0.captionKey] }
        keys += LessonPlaybackMode.allCases.map(\.rawValue)
        keys += PracticeMode.allCases.map(\.title)
        keys += MIDIPracticeAction.allCases.map(\.title)
        keys += StarRequirement.titleKeys
        let missing = "<missing translation>"
        for language in ["en", "cs"] {
            let url = try XCTUnwrap(Bundle.main.url(forResource: language, withExtension: "lproj"))
            let bundle = try XCTUnwrap(Bundle(url: url))
            for key in keys {
                let value = bundle.localizedString(forKey: key, value: missing, table: nil)
                XCTAssertFalse(value == missing || value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                               "\(language): \(key)")
            }

            let trainingTitle = bundle.localizedString(forKey: "help.training.title", value: missing, table: nil)
            XCTAssertEqual(trainingTitle, language == "en" ? "Training" : "Trénink")

            for key in ["help.training.caption", "help.tutorial.whereNext.caption"] {
                let value = bundle.localizedString(forKey: key, value: missing, table: nil)
                XCTAssertLessThanOrEqual(value.components(separatedBy: "\n").count, 4, "\(language): \(key)")
            }

            let fadeOption = bundle.localizedString(forKey: "Fade notes in From memory", value: missing, table: nil)
            let memoryFormat = bundle.localizedString(forKey: "help.memory.caption", value: missing, table: nil)
            let memoryCaption = String(format: memoryFormat, locale: Locale(identifier: language), fadeOption)
            XCTAssertLessThanOrEqual(memoryCaption.components(separatedBy: "\n").count, 4, "\(language): help.memory.caption")
            XCTAssertTrue(memoryCaption.contains("80 %"), "\(language): help.memory.caption")
        }
    }

    func testLocalizableStringsHaveNoDuplicateKeys() throws {
        // The compiled bundles can collapse duplicate assignments, so read the source files.
        let resources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("SmackAPad/Resources")
        let assignmentOrComment = try NSRegularExpression(
            pattern: #"(?s)/\*.*?\*/|//[^\r\n]*|"(?:\\.|[^"\\])*"\s*=\s*"(?:\\.|[^"\\])*"\s*;"#
        )
        for language in ["en", "cs"] {
            let url = resources.appendingPathComponent("\(language).lproj/Localizable.strings")
            let source = try String(contentsOf: url, encoding: .utf8)
            let data = Data(source.utf8)
            let parsed = try XCTUnwrap(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String])
            var keys: Set<String> = []
            for match in assignmentOrComment.matches(in: source, range: NSRange(source.startIndex..., in: source)) {
                let range = try XCTUnwrap(Range(match.range, in: source))
                let entry = source[range]
                guard entry.first == "\"" else { continue }
                let pair = try XCTUnwrap(PropertyListSerialization.propertyList(from: Data(entry.utf8), format: nil) as? [String: String])
                let key = try XCTUnwrap(pair.keys.first)
                XCTAssertTrue(keys.insert(key).inserted, "\(language): duplicate key \(key)")
            }
            XCTAssertEqual(keys, Set(parsed.keys), "\(language): parsed keys")
        }
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
