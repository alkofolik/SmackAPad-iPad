import AVFoundation
import XCTest
@testable import SmackAPad

final class SampleGainTests: XCTestCase {
    private let bundle = Bundle(for: AudioEngine.self)

    private struct Manifest: Decodable {
        struct Layer: Decodable { let url: String }
        struct Kit: Decodable { let voices: [String: [Layer]] }
    }

    private func manifest() throws -> [String: Manifest.Kit] {
        let url = try XCTUnwrap(bundle.url(forResource: "sample-kits", withExtension: "json", subdirectory: "Data")
            ?? bundle.url(forResource: "sample-kits", withExtension: "json"))
        return try JSONDecoder().decode([String: Manifest.Kit].self, from: Data(contentsOf: url))
    }

    private func samplePeak(_ url: URL) throws -> Float {
        let file = try AVAudioFile(forReading: url)
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                                   frameCapacity: AVAudioFrameCount(file.length)))
        try file.read(into: buffer)
        var peak: Float = 0
        for channel in 0..<Int(buffer.format.channelCount) {
            let data = try XCTUnwrap(buffer.floatChannelData?[channel])
            for frame in 0..<Int(buffer.frameLength) { peak = max(peak, abs(data[frame])) }
        }
        return peak
    }

    func testGainTableCoversEveryVoiceAndKeepsPeaksBelowMinusOneDB() throws {
        let table = SampleGain.Table.load(from: bundle)
        let root = try XCTUnwrap(bundle.url(forResource: "samples", withExtension: "bundle"))
        for (kitId, kit) in try manifest() {
            for (voice, layers) in kit.voices {
                let gain = try XCTUnwrap(table.kits[kitId]?[voice], "No gain for \(kitId)/\(voice)")
                XCTAssertLessThanOrEqual(gain, 0, "\(kitId)/\(voice) must not boost")
                for layer in layers {
                    let relative = String(layer.url.dropFirst("samples/".count))
                    let peak = try samplePeak(root.appendingPathComponent(relative))
                    let peakDB = 20 * log10(max(peak, 1e-9)) + gain
                    XCTAssertLessThanOrEqual(peakDB, -1.0 + 0.05, "\(layer.url) peaks at \(peakDB) dBFS")
                }
            }
        }
    }

    func testCombinedGainIsClampedAndUsesTheRightRole() {
        // Velocity alone, as before this ticket.
        XCTAssertEqual(SampleGain.playerVolume(velocity: 127, normalisationDB: 0, trimDB: 0), 1, accuracy: 1e-6)
        XCTAssertEqual(SampleGain.playerVolume(velocity: 64, normalisationDB: 0, trimDB: 0), 64 / 127, accuracy: 1e-6)
        // Normalisation -6 dB and trim -6 dB multiply.
        XCTAssertEqual(SampleGain.playerVolume(velocity: 127, normalisationDB: -6, trimDB: -6), 0.2512, accuracy: 1e-3)
        // A boost on a hard hit cannot pass unity.
        XCTAssertEqual(SampleGain.playerVolume(velocity: 127, normalisationDB: 0, trimDB: 6), 1)
        // Extreme cut stays above zero and never negative.
        XCTAssertGreaterThanOrEqual(SampleGain.playerVolume(velocity: 1, normalisationDB: -30, trimDB: -12), 0)
        // The role is looked up per voice and kit.
        let table = SampleGain.Table(kits: ["a": ["crash": -9, "kick": -1], "b": ["crash": -3]])
        XCTAssertEqual(table.gainDB(kit: "a", voice: "crash"), -9)
        XCTAssertEqual(table.gainDB(kit: "b", voice: "crash"), -3)
        XCTAssertEqual(table.gainDB(kit: "a", voice: "ride"), 0)
        XCTAssertEqual(SampleGain.roles(usedPads: [12, 2]), ["kick", "crash"])
    }

    func testTrimsPersistClampAndResetReturnsToZero() {
        let name = "SampleGainTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }

        let first = SettingsManager(userDefaults: defaults)
        XCTAssertTrue(first.instrumentTrims.isEmpty)
        first.instrumentTrims = ["crash": -6, "kick": 20, "snare": 0]
        XCTAssertEqual(first.instrumentTrims, ["crash": -6, "kick": 6])

        let relaunched = SettingsManager(userDefaults: defaults)
        XCTAssertEqual(relaunched.instrumentTrims, ["crash": -6, "kick": 6])

        relaunched.resetInstrumentTrims()
        XCTAssertTrue(relaunched.instrumentTrims.isEmpty)
        XCTAssertTrue(SettingsManager(userDefaults: defaults).instrumentTrims.isEmpty)
    }
}
