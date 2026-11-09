import AVFoundation
import XCTest
@testable import SmackAPad

final class AudioRouteAndLateSoundTests: XCTestCase {
    func testLateSoundsOnlyStopOnFourthSkipInSamePass() {
        var policy = LateSoundPolicy()
        var clock = 10.0
        XCTAssertFalse(policy.recordSkip(passStart: nil))
        XCTAssertFalse(policy.recordSkip(passStart: clock))
        XCTAssertFalse(policy.recordSkip(passStart: clock))
        XCTAssertFalse(policy.recordSkip(passStart: clock))

        clock += 2
        XCTAssertFalse(policy.recordSkip(passStart: clock))
        XCTAssertFalse(policy.recordSkip(passStart: clock))
        XCTAssertFalse(policy.recordSkip(passStart: clock))
        XCTAssertTrue(policy.recordSkip(passStart: clock))
        XCTAssertEqual(policy.totalSkipped, 8)
    }

    func testRouteChangeReasonsIgnoreCategorySetupAndInputOnlyDeviceChanges() {
        typealias Reason = AVAudioSession.RouteChangeReason
        for reason in [Reason.newDeviceAvailable, .oldDeviceUnavailable, .override,
                       .routeConfigurationChange, .wakeFromSleep, .noSuitableRouteForCategory, .unknown] {
            XCTAssertTrue(AudioEngine.isOutputRouteChange(reason: reason.rawValue, outputsChanged: true))
        }
        XCTAssertFalse(AudioEngine.isOutputRouteChange(reason: Reason.categoryChange.rawValue, outputsChanged: true))
        XCTAssertFalse(AudioEngine.isOutputRouteChange(reason: Reason.newDeviceAvailable.rawValue, outputsChanged: false))
        XCTAssertFalse(AudioEngine.isOutputRouteChange(reason: Reason.oldDeviceUnavailable.rawValue, outputsChanged: false))
        XCTAssertTrue(AudioEngine.isOutputRouteChange(reason: Reason.routeConfigurationChange.rawValue, outputsChanged: false))
    }

    func testCalibrationMigratesOnWriteAndKeepsLegacyFallbackForOtherRoutes() throws {
        let suite = "audio-route-calibration-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(["touch": 17.0], forKey: "smackapad.settings.calibrationOffsets")
        let settings = SettingsManager(userDefaults: defaults)
        let speaker = AudioOutputRoute(port: .builtInSpeaker)
        let wired = AudioOutputRoute(port: .usbAudio)
        let bluetooth = AudioOutputRoute(port: .bluetoothA2DP)

        XCTAssertEqual(settings.calibrationOffset(for: "touch", outputRoute: speaker), 17)
        settings.setCalibrationOffset(0, for: "touch", outputRoute: speaker)
        settings.setCalibrationOffset(-24, for: "touch", outputRoute: wired)

        let reloaded = SettingsManager(userDefaults: defaults)
        XCTAssertEqual(reloaded.calibrationOffsets, ["touch": 17, "touch|speaker": 0, "touch|wired": -24])
        XCTAssertEqual(reloaded.calibrationOffset(for: "touch", outputRoute: speaker), 0)
        XCTAssertEqual(reloaded.calibrationOffset(for: "touch", outputRoute: wired), -24)
        XCTAssertEqual(reloaded.calibrationOffset(for: "touch", outputRoute: bluetooth), 17)
        XCTAssertEqual(reloaded.calibrationOffset(for: "keyboard", outputRoute: wired), 0)
    }
}
