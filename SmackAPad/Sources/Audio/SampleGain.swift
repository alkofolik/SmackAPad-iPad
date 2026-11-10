import Foundation

/// Loudness evening (ticket 166). Gains come from `tools/measure-sample-loudness.py`.
///
/// Final player volume = velocity/127 x normalisation gain x user trim.
/// `AVAudioPlayerNode.volume` cannot go above 1, so the product is clamped.
/// The normalisation gains are never above 0 dB, so the clamp only matters
/// for a positive user trim on a loud, hard hit.
enum SampleGain {
    static let trimRange = -12...6
    static let fileName = "sample-gains"

    /// Normalisation gains in dB, by kit id then voice name.
    struct Table: Decodable, Equatable {
        let kits: [String: [String: Float]]

        func gainDB(kit: String, voice: String) -> Float {
            kits[kit]?[voice] ?? 0
        }

        static let empty = Table(kits: [:])

        static func load(from bundle: Bundle) -> Table {
            guard let url = bundle.url(forResource: fileName, withExtension: "json", subdirectory: "Data")
                ?? bundle.url(forResource: fileName, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let table = try? JSONDecoder().decode(Table.self, from: data) else { return .empty }
            return table
        }
    }

    /// Voices in the order they are listed in Settings.
    static let roleOrder = ["kick", "snare", "hat", "openHat", "crash", "ride",
                            "tomHi", "tomLo", "clap", "rim", "shaker", "wood", "cowbell"]

    /// Voices that at least one lesson uses, in `roleOrder`.
    static func roles(usedPads: Set<Int>, padVoices: [String] = AudioEngine.defaultPadVoices) -> [String] {
        let used = Set(usedPads.compactMap { padVoices.indices.contains($0) ? padVoices[$0] : nil })
        return roleOrder.filter(used.contains)
    }

    static func clampTrim(_ db: Int) -> Int { min(max(db, trimRange.lowerBound), trimRange.upperBound) }

    static func linear(_ db: Float) -> Float { powf(10, db / 20) }

    /// Value for `AVAudioPlayerNode.volume`.
    static func playerVolume(velocity: Int, normalisationDB: Float, trimDB: Float) -> Float {
        let combined = Float(velocity) / 127 * linear(normalisationDB + trimDB)
        return min(max(combined, 0), 1)
    }
}
