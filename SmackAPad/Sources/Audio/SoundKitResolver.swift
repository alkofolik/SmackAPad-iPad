//
//  SoundKitResolver.swift
//  SmackAPad
//
//  Resolves the active sound kit for a lesson based on per-lesson override,
//  global user settings, automatic genre mapping, and voice safety fallback.
//

import Foundation

/// Resolution result for a lesson sound kit.
public struct SoundKitResolution: Equatable, Sendable {
    /// The kit identifier to load into the audio engine (e.g. "rock", "808", "acoustic").
    public let kitId: String
    /// True when the resolved kit originated from the "Automatic" setting.
    public let isAutomatic: Bool
    /// Full display name of the kit.
    public let kitName: String
    /// Short name of the kit (e.g. "Rock", "808", "House").
    public let kitShortName: String

    public init(kitId: String, isAutomatic: Bool, kitName: String, kitShortName: String) {
        self.kitId = kitId
        self.isAutomatic = isAutomatic
        self.kitName = kitName
        self.kitShortName = kitShortName
    }
}

/// Resolves sound kits and provides the genre-to-kit automatic mapping table.
public struct SoundKitResolver: Sendable {
    public static let automaticKitId = "auto"
    public static let fallbackKitId = "acoustic"

    /// Automatic mapping table constant proposal from Ticket 26.
    /// Kept as a single table constant so it is easy to review and modify.
    public static let genreKitTable: [(kitId: String, genres: [String])] = [
        ("rock", ["Rock", "Punk", "Country", "Pop", "Blues", "Gospel"]),
        ("acoustic", ["Funk", "Soul", "Disco", "Lo-fi", "Trip hop"]),
        ("jazz", ["Jazz", "New Orleans"]),
        ("world", ["Latin", "Afrobeat", "Highlife", "Reggae", "Reggaeton", "Middle Eastern"]),
        ("worldperc", ["Afro-Cuban"]),
        ("808", ["Hip hop", "Trap", "Miami bass", "Electro"]),
        ("house", [
            "Dance", "House", "Deep house", "Tech house", "Techno",
            "Hard techno", "Trance", "UK garage", "Dubstep", "Drum and bass",
            "Jungle", "Breakbeat", "Moombahton", "Synthwave"
        ])
    ]

    private static let lock = NSLock()
    private static var _cachedBundledKits: [String: SampleKit]?

    /// Bundled sample kits loaded from `sample-kits.json`.
    public static var bundledKits: [String: SampleKit] {
        lock.lock()
        defer { lock.unlock() }
        if let cached = _cachedBundledKits { return cached }
        let loaded = (try? DataLoader.shared.loadSampleKits()) ?? [:]
        _cachedBundledKits = loaded
        return loaded
    }

    /// Returns the kit ID mapped to the given lesson genre (matched case-insensitively).
    /// Defaults to "acoustic" for unlisted, unknown, or empty genres.
    public static func kitId(forGenre genre: String?) -> String {
        guard let genre = genre?.trimmingCharacters(in: .whitespacesAndNewlines), !genre.isEmpty else {
            return fallbackKitId
        }
        let lower = genre.lowercased()
        for entry in genreKitTable {
            for g in entry.genres {
                if g.lowercased() == lower {
                    return entry.kitId
                }
            }
        }
        return fallbackKitId
    }

    /// Canonical short name for kit presentation (e.g. "Rock", "808", "House").
    public static func shortName(for kitId: String) -> String {
        switch kitId {
        case "rock": return "Rock"
        case "acoustic": return "Acoustic"
        case "808": return "808"
        case "jazz": return "Jazz"
        case "world": return "World"
        case "brush": return "Brush"
        case "worldperc": return "World percussion"
        case "house": return "House"
        default: return kitId.capitalized
        }
    }

    /// Collects the unique voice names needed by a lesson across its 16-pad and 8-pad hits.
    public static func requiredVoices(for lesson: Lesson) -> Set<String> {
        var pads = Set(lesson.hits.map(\.padIndex))
        if let hits8 = lesson.hits8 {
            for hit in hits8 {
                pads.insert(hit.padIndex)
            }
        }
        var voices = Set<String>()
        for pad in pads where pad >= 0 && pad < AudioEngine.defaultPadVoices.count {
            voices.insert(AudioEngine.defaultPadVoices[pad])
        }
        return voices
    }

    /// Checks if a kit definition contains sample data for all required voices.
    public static func kitHasVoices(
        kitId: String,
        neededVoices: Set<String>,
        kits: [String: SampleKit]
    ) -> Bool {
        guard let kit = kits[kitId] else { return false }
        for voice in neededVoices {
            guard let samples = kit.voices[voice], !samples.isEmpty else {
                return false
            }
        }
        return true
    }

    /// Resolves the sound kit for a lesson following the resolution order:
    /// 1. Per-lesson override (if specified and not "auto")
    /// 2. Global setting (`settings.selectedKitId`)
    /// 3. If the result is "auto", genre mapping table
    /// 4. Safety check: if the resolved kit lacks any voice required by the lesson, fall back to "acoustic".
    public static func resolve(
        for lesson: Lesson,
        settings: SettingsManager,
        kits: [String: SampleKit]? = nil
    ) -> SoundKitResolution {
        let override = settings.kitOverride(for: lesson.id)
        let candidateRaw: String
        let isAuto: Bool

        if let override = override, override != automaticKitId && !override.isEmpty {
            candidateRaw = override
            isAuto = false
        } else if settings.selectedKitId != automaticKitId {
            candidateRaw = settings.selectedKitId
            isAuto = false
        } else {
            candidateRaw = kitId(forGenre: lesson.genre)
            isAuto = true
        }

        let kitsDict = (kits != nil && !kits!.isEmpty) ? kits! : bundledKits
        let needed = requiredVoices(for: lesson)

        let finalKitId: String
        if kitHasVoices(kitId: candidateRaw, neededVoices: needed, kits: kitsDict) {
            finalKitId = candidateRaw
        } else {
            finalKitId = fallbackKitId
        }

        let fullName = kitsDict[finalKitId]?.name ?? shortName(for: finalKitId)
        let short = shortName(for: finalKitId)

        return SoundKitResolution(
            kitId: finalKitId,
            isAutomatic: isAuto,
            kitName: fullName,
            kitShortName: short
        )
    }

    /// Convenience helper returning just the kit ID to load.
    public static func resolveKitId(
        for lesson: Lesson,
        settings: SettingsManager,
        kits: [String: SampleKit]? = nil
    ) -> String {
        resolve(for: lesson, settings: settings, kits: kits).kitId
    }
}
