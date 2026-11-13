//
//  LessonData.swift
//  SmackAPad
//
//  Data models and JSON loaders for lessons, sample kits, and content packs.
//

import Foundation
import Observation

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
    /// `free`, `full`, or `pack:<id>`. Missing metadata defaults to Full access.
    public let access: String?

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
        intro: IntroMetadata? = nil,
        access: String? = "full"
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
        self.access = access
    }

    /// Returns the effective hits for the given controller pad count mode.
    /// In 8-pad mode, returns `hits8` if present and non-empty; otherwise `hits`.
    public func hits(forPadCount padCount: Int) -> [LessonHit] {
        if padCount == 8, let hits8 = hits8, !hits8.isEmpty {
            return hits8
        }
        return hits
    }

    /// Set of unique padIndex values used in the lesson pattern for the specified pad count.
    public func requiredPadIndices(forPadCount padCount: Int = 16) -> Set<Int> {
        Set(hits(forPadCount: padCount).map(\.padIndex))
    }
}

/// A category definition from `lessons-core.json`.
/// Serialized as a category identifier and display title.
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

/// A complete sample kit model with kit identifier, name, license, and voice definitions.
public struct SampleKit: Codable, Equatable, Identifiable, Sendable {
    public let kitId: String
    public let name: String
    public let license: String
    public let voices: [String: [SampleVoiceEntry]]

    public var id: String { kitId }

    public init(kitId: String, name: String, license: String, voices: [String: [SampleVoiceEntry]]) {
        self.kitId = kitId
        self.name = name
        self.license = license
        self.voices = voices
    }

    public init(kitId: String, definition: SampleKitDefinition) {
        self.init(kitId: kitId, name: definition.name, license: definition.license, voices: definition.voices)
    }
}

/// A MIDI controller mapping profile.
/// Maps incoming MIDI note numbers to padIndex (0–15 in 16-pad mode) or physical slot (0–7 in 8-pad mode).
public struct ControllerProfile: Codable, Equatable, Hashable, Sendable, Identifiable {
    public var id: String { profileName }
    public let profileName: String
    /// Map of MIDI note number to target padIndex (0–15) or physical slot (0–7).
    public let noteMap: [Int: Int]
    /// Controller physical pad count: 8 or 16.
    public let padCount: Int

    public var isEightPad: Bool { padCount == 8 }
    public var isSixteenPad: Bool { padCount == 16 }

    public init(profileName: String, noteMap: [Int: Int], padCount: Int) {
        self.profileName = profileName
        self.noteMap = noteMap
        self.padCount = padCount
    }

    /// Returns the target padIndex or slot for a given MIDI note number.
    public func target(forMidiNote note: Int) -> Int? {
        noteMap[note]
    }

    /// Returns the MIDI note mapped to a given target padIndex or slot.
    public func midiNote(forTarget target: Int) -> Int? {
        noteMap.first(where: { $0.value == target })?.key
    }
}

extension ControllerProfile {
    /// Standard chromatic 16-pad layout, notes 36..51 bottom-left to top-right.
    public static let standard16 = ControllerProfile(
        profileName: "Standard 16-Pad",
        noteMap: [
            36: 12, 37: 13, 38: 14, 39: 15,
            40: 8,  41: 9,  42: 10, 43: 11,
            44: 4,  45: 5,  46: 6,  47: 7,
            48: 0,  49: 1,  50: 2,  51: 3
        ],
        padCount: 16
    )

    public static let presets: [ControllerProfile] = [.standard16, .standard8]
    public static let builtInProfiles = presets

    public var isValid: Bool {
        (padCount == 8 || padCount == 16) &&
        !profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        noteMap.count == padCount && Set(noteMap.values) == Set(0..<padCount) &&
        noteMap.keys.allSatisfy { (0...127).contains($0) }
    }

    /// Standard 8-pad layout mapping notes 36..43 to physical slots 0..7.
    public static let standard8 = ControllerProfile(
        profileName: "Standard 8-Pad",
        noteMap: [
            36: 0, 37: 1, 38: 2, 39: 3,
            40: 4, 41: 5, 42: 6, 43: 7
        ],
        padCount: 8
    )
}

/// 8-pad layout engine as specified in SPEC §6.
/// Assigns 8 physical controller pads (slots 0–7) to the sounds required by each lesson.
public enum EightPadLayout {
    /// Standard base slots:
    /// [Clap(9), Rim(10), Crash(2), Ride(3), Kick L(12), Snare L(13), Hat R(11), Open hat(7)]
    public static let baseSlots: [Int] = [9, 10, 2, 3, 12, 13, 11, 7]

    /// The replacement order for walking slots when placing extra required pads:
    /// [0, 1, 3, 2, 7, 6, 5, 4]
    public static let fillOrder: [Int] = [0, 1, 3, 2, 7, 6, 5, 4]

    /// Computes the 8 physical slots for a given lesson according to SPEC §6.
    /// In 8-pad mode, if `lesson.hits8` exists and is non-empty, it is used instead of `lesson.hits`.
    /// Returns nil if more than 8 distinct pads are required or replacement cannot satisfy requirements.
    public static func slots(for lesson: Lesson) -> [Int]? {
        let hits = (lesson.hits8 != nil && !(lesson.hits8?.isEmpty ?? true))
            ? (lesson.hits8 ?? lesson.hits)
            : lesson.hits
        return slots(forHits: hits)
    }

    /// Computes the 8 physical slots for a given list of hits.
    public static func slots(forHits hits: [LessonHit]) -> [Int]? {
        let required = Set(hits.map(\.padIndex))
        guard required.count <= 8 else {
            return nil
        }

        var slots = baseSlots
        let baseSet = Set(baseSlots)
        var waitingList = required.subtracting(baseSet).sorted()

        for slotIndex in fillOrder {
            guard !waitingList.isEmpty else { break }
            let padInSlot = slots[slotIndex]
            if !required.contains(padInSlot) {
                slots[slotIndex] = waitingList.removeFirst()
            }
        }

        guard waitingList.isEmpty else {
            return nil
        }

        return slots
    }

    /// Returns the pad index assigned to a physical slot (0–7) in a computed layout.
    public static func padIndex(forSlot slot: Int, in layout: [Int]) -> Int? {
        guard layout.indices.contains(slot) else { return nil }
        return layout[slot]
    }

    /// Returns the physical slot (0–7) assigned to a pad index in a computed layout.
    public static func slotIndex(forPad padIndex: Int, in layout: [Int]) -> Int? {
        layout.firstIndex(of: padIndex)
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
    func loadCategories() throws -> [LessonCategory]
}

extension LessonContentSource {
    public func loadCategories() throws -> [LessonCategory] {
        return []
    }
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
            "Resources"
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

        // Check other loaded bundles if not found in primary bundle
        let storeBundle = Bundle(for: LessonStore.self)
        if bundle != storeBundle {
            if let storeURL = try? findResourceURL(named: name, withExtension: ext, in: storeBundle) {
                return storeURL
            }
        }
        for altBundle in Bundle.allBundles where altBundle != bundle && altBundle != storeBundle {
            if let altURL = try? findResourceURL(named: name, withExtension: ext, in: altBundle) {
                return altURL
            }
        }

        let target = ext != nil ? "\(name).\(ext!)" : name
        throw DataLoaderError.fileNotFound(target)
    }

    // MARK: Bundled Resources

    /// Loads the core 539 lessons and categories from `lessons-core.json`.
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
    public func loadSampleKits(bundle: Bundle = .main) throws -> [String: SampleKit] {
        let url = try findResourceURL(named: "sample-kits", withExtension: "json", in: bundle)
        let rawDict: [String: SampleKitDefinition] = try loadJSON(from: url)
        return rawDict.reduce(into: [String: SampleKit]()) { result, element in
            result[element.key] = SampleKit(kitId: element.key, definition: element.value)
        }
    }

    /// Loads all sample kits as an array sorted by kit identifier.
    public func loadSampleKitList(bundle: Bundle = .main) throws -> [SampleKit] {
        let dict = try loadSampleKits(bundle: bundle)
        return dict.values.sorted { $0.kitId < $1.kitId }
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
    public let resourceName: String
    public let bundle: Bundle

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

    public func loadCategories() throws -> [LessonCategory] {
        let url = try DataLoader.shared.findResourceURL(named: resourceName, withExtension: "json", in: bundle)
        if let core: CoreLessonsPayload = try? DataLoader.shared.loadJSON(from: url) {
            return core.cats
        }
        return []
    }
}

extension BundledLessonContentSource {
    public static func core(bundle: Bundle = .main) -> BundledLessonContentSource {
        BundledLessonContentSource(sourceIdentifier: "lessons-core", resourceName: "lessons-core", bundle: bundle)
    }

    public static func intro(bundle: Bundle = .main) -> BundledLessonContentSource {
        BundledLessonContentSource(sourceIdentifier: "intro", resourceName: "intro", bundle: bundle)
    }

    public static func electronicPath(bundle: Bundle = .main) -> BundledLessonContentSource {
        BundledLessonContentSource(sourceIdentifier: "electronic-path", resourceName: "electronic-path", bundle: bundle)
    }

    public static func genreExtensions(bundle: Bundle = .main) -> BundledLessonContentSource {
        BundledLessonContentSource(sourceIdentifier: "genre-extensions", resourceName: "genre-extensions", bundle: bundle)
    }

    public static func allDefaultBundledSources(bundle: Bundle = .main) -> [LessonContentSource] {
        [
            core(bundle: bundle),
            intro(bundle: bundle),
            electronicPath(bundle: bundle),
            genreExtensions(bundle: bundle)
        ]
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

    public func loadCategories() throws -> [LessonCategory] {
        if let core: CoreLessonsPayload = try? DataLoader.shared.loadJSON(from: fileURL) {
            return core.cats
        }
        return []
    }
}

// MARK: - LessonStore

/// Unified store and manager for lessons across multiple sources (bundled resources and content packs).
@Observable
public final class LessonStore: @unchecked Sendable {
    public static let shared = LessonStore()

    public private(set) var sources: [LessonContentSource] = []
    /// Original source lessons remain available for historical category-access migration.
    public private(set) var lessons: [Lesson] = []
    public private(set) var categories: [LessonCategory] = []
    public private(set) var lessonsById: [Int: Lesson] = [:]
    public private(set) var lessonsByCategory: [String: [Lesson]] = [:]
    public private(set) var lastLoadError: Error?
    private(set) var libraryCatalog = LibraryCatalog(lessons: [])

    private let lock = NSLock()

    /// Initializes the store with specified sources, or defaults to all bundled content.
    public init(
        sources: [LessonContentSource]? = nil,
        autoLoad: Bool = true,
        bundle: Bundle = .main
    ) {
        let initialSources = sources ?? BundledLessonContentSource.allDefaultBundledSources(bundle: bundle)
        self.sources = initialSources
        if autoLoad {
            do {
                try reload()
            } catch {
                self.lastLoadError = error
            }
        }
    }

    /// Registers an additional content source (e.g. future content packs) and merges lessons.
    public func register(source: LessonContentSource, reloadImmediately: Bool = true) throws {
        lock.lock()
        sources.append(source)
        lock.unlock()

        if reloadImmediately {
            try reload()
        }
    }

    /// Registers multiple additional content sources and merges lessons.
    public func register(sources newSources: [LessonContentSource], reloadImmediately: Bool = true) throws {
        lock.lock()
        sources.append(contentsOf: newSources)
        lock.unlock()

        if reloadImmediately {
            try reload()
        }
    }

    /// Reloads and merges all lessons and categories from registered sources.
    public func reload() throws {
        lock.lock()
        defer { lock.unlock() }

        var mergedLessons: [Lesson] = []
        var mergedCategories: [LessonCategory] = []
        var seenLessonIds = Set<Int>()
        var seenCategoryIds = Set<String>()

        for source in sources {
            let loadedLessons = try source.loadLessons()
            for lesson in loadedLessons {
                if !seenLessonIds.contains(lesson.id) {
                    seenLessonIds.insert(lesson.id)
                    mergedLessons.append(lesson)
                } else {
                    // Update/override existing lesson definition with new source
                    if let index = mergedLessons.firstIndex(where: { $0.id == lesson.id }) {
                        mergedLessons[index] = lesson
                    }
                }
            }

            let loadedCategories = try source.loadCategories()
            for category in loadedCategories {
                if !seenCategoryIds.contains(category.id) {
                    seenCategoryIds.insert(category.id)
                    mergedCategories.append(category)
                }
            }
        }

        self.lessons = mergedLessons
        self.libraryCatalog = LibraryCatalog(lessons: mergedLessons)
        self.categories = mergedCategories.filter { $0.id != "starter" }
        self.lessonsById = Dictionary(libraryCatalog.lessons.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })

        var byCat: [String: [Lesson]] = [:]
        for lesson in libraryCatalog.lessons {
            byCat[lesson.cat, default: []].append(lesson)
        }
        self.lessonsByCategory = byCat
        self.lastLoadError = nil
    }

    /// Looks up a lesson by its numeric ID.
    public func lesson(for id: Int) -> Lesson? {
        lessonsById[id]
    }

    /// Returns all lessons belonging to the given category identifier.
    /// When `includeFolded` is true (default), electronic-path and extension lessons are folded into "electronic" (SPEC §3.7, DECISIONS §17).
    public func lessons(in category: String, includeFolded: Bool = true) -> [Lesson] {
        let direct = lessonsByCategory[category] ?? []
        guard includeFolded else { return direct }
        if category == "electronic" {
            let folded = lessons.filter {
                $0.cat != "electronic" &&
                ($0.cat == "hardgroove" || $0.cat == "broken-techno" || $0.cat == "uk-club" || $0.tags.contains("electronic path") || $0.cat == "jersey" || $0.cat == "footwork")
            }
            return direct + folded
        }
        return direct
    }

    /// Convenience access for 8-pad slot mapping for a lesson.
    public func layout(for lesson: Lesson) -> [Int]? {
        EightPadLayout.slots(for: lesson)
    }

    /// Returns all lessons that are playable in 8-pad mode.
    public func lessonsPlayableInEightPadMode() -> [Lesson] {
        lessons.filter { EightPadLayout.slots(for: $0) != nil }
    }
}
