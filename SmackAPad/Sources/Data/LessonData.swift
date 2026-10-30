//
//  LessonData.swift
//  SmackAPad
//
//  Data models and JSON loaders for lessons, sample kits, and content packs.
//

import Foundation

// MARK: - Models

/// A single drum strike in a lesson pattern.
/// Serialized in JSON as `[step, padIndex, hand, velocity]`.
public struct LessonHit: Codable, Equatable, Hashable, Sendable {
    /// 0-based sixteenth note index (0 ..< 16 * bars)
    public let step: Int
    /// 0-15 target pad index
    public let padIndex: Int
    /// "L" or "R"
    public let hand: String
    /// MIDI velocity (0-127)
    public let velocity: Int

    public init(step: Int, padIndex: Int, hand: String, velocity: Int) {
        self.step = step
        self.padIndex = padIndex
        self.hand = hand
        self.velocity = velocity
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.step = try container.decode(Int.self)
        self.padIndex = try container.decode(Int.self)
        self.hand = try container.decode(String.self)
        self.velocity = try container.decode(Int.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(step)
        try container.encode(padIndex)
        try container.encode(hand)
        try container.encode(velocity)
    }
}

/// Educational reference material for introductory lessons.
public struct IntroResource: Codable, Equatable, Hashable, Sendable {
    public let name: String
    public let url: String

    public init(name: String, url: String) {
        self.name = name
        self.url = url
    }
}

/// Metadata specific to intro exercises and electronic path lessons.
public struct IntroMetadata: Codable, Equatable, Hashable, Sendable {
    public let number: Int
    public let total: Int?
    public let stage: String
    public let goal: String
    public let watch: String
    public let fingers16: [String: Int]?
    public let fingers8: [String: Int]?
    public let resources: [IntroResource]?

    public init(
        number: Int,
        total: Int? = nil,
        stage: String,
        goal: String,
        watch: String,
        fingers16: [String: Int]? = nil,
        fingers8: [String: Int]? = nil,
        resources: [IntroResource]? = nil
    ) {
        self.number = number
        self.total = total
        self.stage = stage
        self.goal = goal
        self.watch = watch
        self.fingers16 = fingers16
        self.fingers8 = fingers8
        self.resources = resources
    }
}

/// A lesson definition matching the legacy schema.
public struct Lesson: Codable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let cat: String
    public let title: String
    public let genre: String
    public let tags: [String]
    public let text: String
    public let division: Int
    public let bars: Int
    public let startBpm: Int
    public let targetBpm: Int
    public let level: Int
    public let score: Double?
    public let src: String
    public let hits: [LessonHit]
    public let hits8: [LessonHit]?
    public let eightNote: String?
    public let intro: IntroMetadata?

    public init(
        id: Int,
        cat: String,
        title: String,
        genre: String,
        tags: [String],
        text: String,
        division: Int,
        bars: Int,
        startBpm: Int,
        targetBpm: Int,
        level: Int,
        score: Double? = nil,
        src: String,
        hits: [LessonHit],
        hits8: [LessonHit]? = nil,
        eightNote: String? = nil,
        intro: IntroMetadata? = nil
    ) {
        self.id = id
        self.cat = cat
        self.title = title
        self.genre = genre
        self.tags = tags
        self.text = text
        self.division = division
        self.bars = bars
        self.startBpm = startBpm
        self.targetBpm = targetBpm
        self.level = level
        self.score = score
        self.src = src
        self.hits = hits
        self.hits8 = hits8
        self.eightNote = eightNote
        self.intro = intro
    }
}

/// A category definition from `lessons-core.json`.
/// Serialized as `["starter", "First steps"]`.
public struct LessonCategory: Codable, Equatable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.id = try container.decode(String.self)
        self.title = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(id)
        try container.encode(title)
    }
}

/// Root structure of `lessons-core.json`.
public struct CoreLessonsPayload: Codable, Sendable {
    public let cats: [LessonCategory]
    public let lessons: [Lesson]

    public init(cats: [LessonCategory], lessons: [Lesson]) {
        self.cats = cats
        self.lessons = lessons
    }
}

/// A single sample voice entry with velocity mapping and round-robin variants.
public struct SampleVoiceEntry: Codable, Equatable, Sendable {
    public let url: String
    public let maxVel: Int
    public let variants: [String]?
    public let sourceRange: [Int]?

    public init(url: String, maxVel: Int, variants: [String]? = nil, sourceRange: [Int]? = nil) {
        self.url = url
        self.maxVel = maxVel
        self.variants = variants
        self.sourceRange = sourceRange
    }
}

/// Kit definition within `sample-kits.json`.
public struct SampleKitDefinition: Codable, Equatable, Sendable {
    public let name: String
    public let license: String
    public let voices: [String: [SampleVoiceEntry]]

    public init(name: String, license: String, voices: [String: [SampleVoiceEntry]]) {
        self.name = name
        self.license = license
        self.voices = voices
    }
}

// MARK: - Loader Errors

public enum DataLoaderError: Error, LocalizedError, Equatable {
    case fileNotFound(String)
    case unreadableData(String, String)
    case decodingFailed(String, String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found at: \(path)"
        case .unreadableData(let path, let reason):
            return "Unable to read data at \(path): \(reason)"
        case .decodingFailed(let path, let details):
            return "Failed to decode JSON from \(path): \(details)"
        }
    }
}

// MARK: - Content Source Protocol

/// Architecture support for loading lessons from different sources
/// (bundled JSON, downloaded content packs, local test files).
public protocol LessonContentSource: Sendable {
    var sourceIdentifier: String { get }
    func loadLessons() throws -> [Lesson]
}

// MARK: - DataLoader

public final class DataLoader: Sendable {
    public static let shared = DataLoader()

    public init() {}

    // MARK: Generic JSON Loading

    /// Loads and decodes JSON from any file URL.
    /// Throws descriptive `DataLoaderError` on failure rather than crashing.
    public func loadJSON<T: Decodable>(from url: URL) throws -> T {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw DataLoaderError.fileNotFound(url.path)
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw DataLoaderError.unreadableData(url.path, error.localizedDescription)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw DataLoaderError.decodingFailed(url.path, String(describing: error))
        }
    }

    // MARK: Bundle URL Discovery

    /// Locates a resource inside a bundle, checking both root level and known resource subdirectories.
    public func findResourceURL(named name: String, withExtension ext: String?, in bundle: Bundle = .main) throws -> URL {
        if let directURL = bundle.url(forResource: name, withExtension: ext) {
            return directURL
        }

        // Check inside Data or other common subdirectories if needed
        let candidates = [
            "Data",
            "Resources/Data",
            "Resources",
            "i18n",
            "Resources/i18n"
        ]

        for candidate in candidates {
            if let subURL = bundle.url(forResource: name, withExtension: ext, subdirectory: candidate) {
                return subURL
            }
        }

        // Direct path check inside bundleURL
        let extSuffix = ext.map { ".\($0)" } ?? ""
        let directPath = bundle.bundleURL.appendingPathComponent("\(name)\(extSuffix)")
        if FileManager.default.fileExists(atPath: directPath.path) {
            return directPath
        }

        for candidate in candidates {
            let candidatePath = bundle.bundleURL
                .appendingPathComponent(candidate)
                .appendingPathComponent("\(name)\(extSuffix)")
            if FileManager.default.fileExists(atPath: candidatePath.path) {
                return candidatePath
            }
        }

        let target = ext != nil ? "\(name).\(ext!)" : name
        throw DataLoaderError.fileNotFound(target)
    }

    // MARK: Bundled Resources

    /// Loads the core 547 lessons and categories from `lessons-core.json`.
    public func loadCoreLessons(bundle: Bundle = .main) throws -> CoreLessonsPayload {
        let url = try findResourceURL(named: "lessons-core", withExtension: "json", in: bundle)
        return try loadJSON(from: url)
    }

    /// Loads the 24 intro exercises from `intro.json`.
    public func loadIntroLessons(bundle: Bundle = .main) throws -> [Lesson] {
        let url = try findResourceURL(named: "intro", withExtension: "json", in: bundle)
        return try loadJSON(from: url)
    }

    /// Loads the 12 electronic path lessons from `electronic-path.json`.
    public func loadElectronicPathLessons(bundle: Bundle = .main) throws -> [Lesson] {
        let url = try findResourceURL(named: "electronic-path", withExtension: "json", in: bundle)
        return try loadJSON(from: url)
    }

    /// Loads the 12 genre extensions from `genre-extensions.json`.
    public func loadGenreExtensionLessons(bundle: Bundle = .main) throws -> [Lesson] {
        let url = try findResourceURL(named: "genre-extensions", withExtension: "json", in: bundle)
        return try loadJSON(from: url)
    }

    /// Loads the sample kit manifest (8 kits) from `sample-kits.json`.
    public func loadSampleKits(bundle: Bundle = .main) throws -> [String: SampleKitDefinition] {
        let url = try findResourceURL(named: "sample-kits", withExtension: "json", in: bundle)
        return try loadJSON(from: url)
    }

    /// Loads Czech localisation strings from `cs.tsv`.
    public func loadLocalizationTSV(bundle: Bundle = .main) throws -> String {
        let url = try findResourceURL(named: "cs", withExtension: "tsv", in: bundle)
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw DataLoaderError.unreadableData(url.path, error.localizedDescription)
        }
    }

    // MARK: Sample URL Resolver

    /// Resolves the filesystem URL of a WAV sample from its manifest relative URL.
    /// Example manifest URL: `"samples/acoustic/kick-1.wav"`.
    /// Handles bundle packaging in `samples.bundle`, `Samples`, or app root.
    public func resolveSampleURL(for relativePath: String, in bundle: Bundle = .main) -> URL? {
        let trimmedPath = relativePath.hasPrefix("samples/")
            ? String(relativePath.dropFirst("samples/".count))
            : (relativePath.hasPrefix("Samples/") ? String(relativePath.dropFirst("Samples/".count)) : relativePath)

        let candidateURLs: [URL] = [
            bundle.bundleURL.appendingPathComponent("samples.bundle").appendingPathComponent(trimmedPath),
            bundle.bundleURL.appendingPathComponent("Samples.bundle").appendingPathComponent(trimmedPath),
            bundle.bundleURL.appendingPathComponent("Samples").appendingPathComponent(trimmedPath),
            bundle.bundleURL.appendingPathComponent("samples").appendingPathComponent(trimmedPath),
            bundle.bundleURL.appendingPathComponent(relativePath)
        ]

        for url in candidateURLs {
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        // Also attempt standard Bundle resource lookups
        let filename = (trimmedPath as NSString).lastPathComponent
        let subfolder = (trimmedPath as NSString).deletingLastPathComponent
        let nameWithoutExt = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension

        let bundleContainers = ["samples.bundle", "Samples.bundle", "Samples", "samples"]
        for container in bundleContainers {
            let fullSubdir = subfolder.isEmpty ? container : "\(container)/\(subfolder)"
            if let url = bundle.url(forResource: nameWithoutExt, withExtension: ext, subdirectory: fullSubdir),
               FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        return nil
    }
}

// MARK: - Bundled & External Content Sources

/// Content source that loads lessons from a bundle file.
public struct BundledLessonContentSource: LessonContentSource {
    public let sourceIdentifier: String
    private let resourceName: String
    private let bundle: Bundle

    public init(sourceIdentifier: String, resourceName: String, bundle: Bundle = .main) {
        self.sourceIdentifier = sourceIdentifier
        self.resourceName = resourceName
        self.bundle = bundle
    }

    public func loadLessons() throws -> [Lesson] {
        let url = try DataLoader.shared.findResourceURL(named: resourceName, withExtension: "json", in: bundle)
        // If it's a core lessons file (wrapped in CoreLessonsPayload), extract lessons
        if let core: CoreLessonsPayload = try? DataLoader.shared.loadJSON(from: url) {
            return core.lessons
        }
        return try DataLoader.shared.loadJSON(from: url)
    }
}

/// Content source that loads lessons from an arbitrary external URL (for future content packs).
public struct ExternalJSONContentSource: LessonContentSource {
    public let sourceIdentifier: String
    public let fileURL: URL

    public init(sourceIdentifier: String, fileURL: URL) {
        self.sourceIdentifier = sourceIdentifier
        self.fileURL = fileURL
    }

    public func loadLessons() throws -> [Lesson] {
        if let core: CoreLessonsPayload = try? DataLoader.shared.loadJSON(from: fileURL) {
            return core.lessons
        }
        return try DataLoader.shared.loadJSON(from: fileURL)
    }
}
