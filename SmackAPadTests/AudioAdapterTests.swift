import XCTest
#if !AUDIO_ADAPTER_STANDALONE
@testable import SmackAPad
#endif

final class AudioAdapterTests: XCTestCase {
    func testCalibrationReleaseAndRepeatedCloseCannotDeactivatePractice() throws {
        var active = false
        let ownership = AudioSessionOwnership(activate: { active = true }, deactivate: { active = false })
        let practice = UUID()
        let calibration = UUID()
        try ownership.acquire(for: practice)
        try ownership.acquire(for: practice)
        try ownership.acquire(for: calibration)
        try ownership.release(for: calibration)
        try ownership.release(for: calibration) // View close after completion/cancellation/failure.
        XCTAssertTrue(active)
        try ownership.release(for: practice) // Background or leaving practice.
        XCTAssertFalse(active)
        try ownership.acquire(for: practice) // Return from background or dismiss settings.
        XCTAssertTrue(active)
        try ownership.release(for: calibration) // A late calibration cleanup is harmless.
        XCTAssertTrue(active)
        try ownership.release(for: practice)
        XCTAssertFalse(active)
    }

    func testPracticeSchedulingAndCalibrationObservationShareOneAudibleTimeline() throws {
        // A 12 ms engine presentation delay must not become a hypothetical
        // 20 ms session-plus-buffer delay in the opposite conversion.
        let timing = try XCTUnwrap(AudioOutputTiming(presentationLatency: 0.012))
        XCTAssertEqual(timing.renderTime(forAudibleTime: 10), 9.988, accuracy: 0.000000001)
        XCTAssertEqual(timing.audibleTime(forRenderTime: 20), 20.012, accuracy: 0.000000001)
        XCTAssertNil(AudioOutputTiming(presentationLatency: 0))
        XCTAssertNil(AudioOutputTiming(presentationLatency: -.infinity))
        XCTAssertNil(AudioOutputTiming(presentationLatency: .nan))
    }
}
