import Foundation

// MARK: - Drummer Attributes & Rank

/// The four core musical attributes displayed on the Drummer Card (0...100).
public enum DrummerAttribute: String, CaseIterable, Identifiable, Codable, Sendable {
    case timing
    case speed
    case technique
    case memory

    public var id: String { rawValue }

    /// Canonical short label shown on the hardware drummer card.
    public var code: String {
        switch self {
        case .timing: return "TIMING"
        case .speed: return "SPEED"
        case .technique: return "TECHNIQUE"
        case .memory: return "MEMORY"
        }
    }

    public func title(language: AppLanguage = .english) -> String {
        switch (self, language) {
        case (.timing, .english): return "Timing"
        case (.timing, .czech): return "Přesnost"
        case (.speed, .english): return "Speed"
        case (.speed, .czech): return "Rychlost"
        case (.technique, .english): return "Technique"
        case (.technique, .czech): return "Technika"
        case (.memory, .english): return "Memory"
        case (.memory, .czech): return "Paměť"
        }
    }
}

/// Snapshot of the player's four musical attributes, each clamped to 0...100.
public struct DrummerAttributes: Equatable, Hashable, Codable, Sendable {
    public let timing: Int
    public let speed: Int
    public let technique: Int
    public let memory: Int

    public static let zero = DrummerAttributes(timing: 0, speed: 0, technique: 0, memory: 0)

    public init(timing: Int, speed: Int, technique: Int, memory: Int) {
        self.timing = min(100, max(0, timing))
        self.speed = min(100, max(0, speed))
        self.technique = min(100, max(0, technique))
        self.memory = min(100, max(0, memory))
    }

    public subscript(attribute: DrummerAttribute) -> Int {
        switch attribute {
        case .timing: return timing
        case .speed: return speed
        case .technique: return technique
        case .memory: return memory
        }
    }
}

/// Progressive drummer rank derived from current level.
public enum DrummerRank: String, CaseIterable, Identifiable, Codable, Comparable, Sendable {
    case padRookie = "pad-rookie"
    case beatKeeper = "beat-keeper"
    case pocketPlayer = "pocket-player"
    case sessionDrummer = "session-drummer"
    case grooveArchitect = "groove-architect"
    case masterPercussionist = "master-percussionist"

    public var id: String { rawValue }

    public var tier: Int {
        switch self {
        case .padRookie: return 1
        case .beatKeeper: return 2
        case .pocketPlayer: return 3
        case .sessionDrummer: return 4
        case .grooveArchitect: return 5
        case .masterPercussionist: return 6
        }
    }

    public var minimumLevel: Int {
        switch self {
        case .padRookie: return 1
        case .beatKeeper: return 3
        case .pocketPlayer: return 6
        case .sessionDrummer: return 10
        case .grooveArchitect: return 15
        case .masterPercussionist: return 21
        }
    }

    public var title: String {
        switch self {
        case .padRookie: return "Pad Rookie"
        case .beatKeeper: return "Beat Keeper"
        case .pocketPlayer: return "Pocket Player"
        case .sessionDrummer: return "Session Drummer"
        case .grooveArchitect: return "Groove Architect"
        case .masterPercussionist: return "Master Percussionist"
        }
    }

    public static func forLevel(_ level: Int) -> DrummerRank {
        let sorted = Self.allCases.sorted { $0.minimumLevel > $1.minimumLevel }
        return sorted.first { level >= $0.minimumLevel } ?? .padRookie
    }

    public static func < (lhs: DrummerRank, rhs: DrummerRank) -> Bool {
        lhs.tier < rhs.tier
    }
}

// MARK: - Drummer Card & Delta

/// Computed RPG profile summary for the Drummer Card.
public struct DrummerCardSnapshot: Equatable, Codable, Sendable {
    public let xp: Int
    public let level: Int
    public let rank: DrummerRank
    public let currentLevelXP: Int
    public let nextLevelXP: Int
    public let attributes: DrummerAttributes
    public let peakCleanBpm: Int
    public let totalStars: Int

    public var levelProgress: Double {
        let span = nextLevelXP - currentLevelXP
        guard span > 0 else { return 1.0 }
        return min(1.0, max(0.0, Double(xp - currentLevelXP) / Double(span)))
    }

    public static let empty = DrummerCardSnapshot(
        xp: 0,
        level: 1,
        rank: .padRookie,
        currentLevelXP: 0,
        nextLevelXP: 120,
        attributes: .zero,
        peakCleanBpm: 0,
        totalStars: 0
    )

    public init(
        xp: Int,
        level: Int,
        rank: DrummerRank,
        currentLevelXP: Int,
        nextLevelXP: Int,
        attributes: DrummerAttributes,
        peakCleanBpm: Int,
        totalStars: Int
    ) {
        self.xp = max(0, xp)
        self.level = max(1, level)
        self.rank = rank
        self.currentLevelXP = max(0, currentLevelXP)
        self.nextLevelXP = max(currentLevelXP, nextLevelXP)
        self.attributes = attributes
        self.peakCleanBpm = max(0, peakCleanBpm)
        self.totalStars = max(0, totalStars)
    }
}

/// Post-lesson progression gain displayed on the practice summary.
public struct DrummerProgressDelta: Equatable, Sendable {
    public let xpGained: Int
    public let previousLevel: Int
    public let newLevel: Int
    public let previousRank: DrummerRank
    public let newRank: DrummerRank
    public let timingDelta: Int
    public let speedDelta: Int
    public let techniqueDelta: Int
    public let memoryDelta: Int

    public var didLevelUp: Bool { newLevel > previousLevel }
    public var didRankUp: Bool { newRank > previousRank }

    public var nonZeroAttributeDeltas: [(attribute: DrummerAttribute, delta: Int)] {
        let raw: [(DrummerAttribute, Int)] = [
            (.speed, speedDelta),
            (.timing, timingDelta),
            (.technique, techniqueDelta),
            (.memory, memoryDelta)
        ]
        return raw.filter { $0.1 > 0 }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.rawValue < rhs.0.rawValue
            }
    }

    /// Compact summary suitable for lesson result badges, e.g. `"+2 SPEED · +1 TIMING"`.
    public var formattedAttributeDeltas: String {
        nonZeroAttributeDeltas
            .map { "+\($0.delta) \($0.attribute.code)" }
            .joined(separator: " · ")
    }

    public var isEmpty: Bool {
        xpGained <= 0 && nonZeroAttributeDeltas.isEmpty && !didLevelUp && !didRankUp
    }

    public init(
        xpGained: Int,
        previousLevel: Int,
        newLevel: Int,
        previousRank: DrummerRank,
        newRank: DrummerRank,
        timingDelta: Int,
        speedDelta: Int,
        techniqueDelta: Int,
        memoryDelta: Int
    ) {
        self.xpGained = max(0, xpGained)
        self.previousLevel = previousLevel
        self.newLevel = newLevel
        self.previousRank = previousRank
        self.newRank = newRank
        self.timingDelta = max(0, timingDelta)
        self.speedDelta = max(0, speedDelta)
        self.techniqueDelta = max(0, techniqueDelta)
        self.memoryDelta = max(0, memoryDelta)
    }

    public static func between(previous: DrummerCardSnapshot, current: DrummerCardSnapshot) -> DrummerProgressDelta {
        DrummerProgressDelta(
            xpGained: max(0, current.xp - previous.xp),
            previousLevel: previous.level,
            newLevel: current.level,
            previousRank: previous.rank,
            newRank: current.rank,
            timingDelta: max(0, current.attributes.timing - previous.attributes.timing),
            speedDelta: max(0, current.attributes.speed - previous.attributes.speed),
            techniqueDelta: max(0, current.attributes.technique - previous.attributes.technique),
            memoryDelta: max(0, current.attributes.memory - previous.attributes.memory)
        )
    }
}

// MARK: - Persisted RPG State

/// Persisted progression state for Drummer's Path & Studio Rig.
/// Stored alongside lesson records in `progress.json` and portable backups.
public struct DrummerPathState: Codable, Equatable, Hashable, Sendable {
    public var unlockedKitIds: Set<String>
    public var unlockedSkinIds: Set<String>
    public var unlockedBonusTrackIds: Set<String>
    public var completedExamStageIDs: Set<String>
    public var earnedMilestoneIDs: Set<String>
    public var keysSpent: Int
    public var legacyKeysBonus: Int
    public var migratedFromLegacyProgress: Bool
    public var storyForkChoices: [String: Int]
    public var seenStoryCardStageIDs: Set<String>
    public var modifiedAt: Date?

    public init(
        unlockedKitIds: Set<String> = [DrumKitCatalog.starterKitId],
        unlockedSkinIds: Set<String> = [StudioRigCatalog.defaultSkinId],
        unlockedBonusTrackIds: Set<String> = [],
        completedExamStageIDs: Set<String> = [],
        earnedMilestoneIDs: Set<String> = [],
        keysSpent: Int = 0,
        legacyKeysBonus: Int = 0,
        migratedFromLegacyProgress: Bool = false,
        storyForkChoices: [String: Int] = [:],
        seenStoryCardStageIDs: Set<String> = [],
        modifiedAt: Date? = nil
    ) {
        var kits = unlockedKitIds
        kits.insert(DrumKitCatalog.starterKitId)
        self.unlockedKitIds = kits

        var skins = unlockedSkinIds
        skins.insert(StudioRigCatalog.defaultSkinId)
        self.unlockedSkinIds = skins

        self.unlockedBonusTrackIds = unlockedBonusTrackIds
        self.completedExamStageIDs = completedExamStageIDs
        self.earnedMilestoneIDs = earnedMilestoneIDs
        self.keysSpent = max(0, keysSpent)
        self.legacyKeysBonus = max(0, legacyKeysBonus)
        self.migratedFromLegacyProgress = migratedFromLegacyProgress
        self.storyForkChoices = storyForkChoices
        self.seenStoryCardStageIDs = seenStoryCardStageIDs
        self.modifiedAt = modifiedAt
    }

    /// Number of distinct stage bosses defeated (excluding the Intro exam).
    public var defeatedStageBossCount: Int {
        completedExamStageIDs.filter { $0 != DrummerPathEvaluator.introExamStageId }.count
    }

    /// Total keys awarded across the 7 finite key sources plus any preserved legacy keys.
    public var totalKeysEarned: Int {
        legacyKeysBonus + DrummerPathEvaluator.earnedKeyCount(
            exams: completedExamStageIDs,
            milestones: earnedMilestoneIDs
        )
    }

    /// Unspent keys available to unlock any locked drum kit (1 key = 1 kit).
    public var availableKeys: Int {
        max(0, totalKeysEarned - keysSpent)
    }

    public func isKitUnlocked(_ kitId: String) -> Bool {
        kitId == DrumKitCatalog.starterKitId || unlockedKitIds.contains(kitId)
    }

    public func isSkinUnlocked(_ skinId: String) -> Bool {
        skinId == StudioRigCatalog.defaultSkinId || unlockedSkinIds.contains(skinId)
    }

    public func isBonusTrackUnlocked(_ trackId: String) -> Bool {
        unlockedBonusTrackIds.contains(trackId)
    }

    private enum CodingKeys: String, CodingKey {
        case unlockedKitIds
        case unlockedSkinIds
        case unlockedBonusTrackIds
        case completedExamStageIDs
        case earnedMilestoneIDs
        case keysSpent
        case legacyKeysBonus
        case migratedFromLegacyProgress
        case storyForkChoices
        case seenStoryCardStageIDs
        case modifiedAt
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        var kits = try c.decodeIfPresent(Set<String>.self, forKey: .unlockedKitIds) ?? [DrumKitCatalog.starterKitId]
        kits.insert(DrumKitCatalog.starterKitId)
        self.unlockedKitIds = kits

        var skins = try c.decodeIfPresent(Set<String>.self, forKey: .unlockedSkinIds) ?? [StudioRigCatalog.defaultSkinId]
        skins.insert(StudioRigCatalog.defaultSkinId)
        self.unlockedSkinIds = skins

        self.unlockedBonusTrackIds = try c.decodeIfPresent(Set<String>.self, forKey: .unlockedBonusTrackIds) ?? []
        self.completedExamStageIDs = try c.decodeIfPresent(Set<String>.self, forKey: .completedExamStageIDs) ?? []
        self.earnedMilestoneIDs = try c.decodeIfPresent(Set<String>.self, forKey: .earnedMilestoneIDs) ?? []
        self.keysSpent = max(0, try c.decodeIfPresent(Int.self, forKey: .keysSpent) ?? 0)
        if let decodedLegacyBonus = try c.decodeIfPresent(Int.self, forKey: .legacyKeysBonus) {
            self.legacyKeysBonus = max(0, decodedLegacyBonus)
        } else {
            let oldEarned = self.completedExamStageIDs.count + self.earnedMilestoneIDs.count
            let newEarned = DrummerPathEvaluator.earnedKeyCount(
                exams: self.completedExamStageIDs,
                milestones: self.earnedMilestoneIDs
            )
            self.legacyKeysBonus = max(0, oldEarned - newEarned)
        }
        self.migratedFromLegacyProgress = try c.decodeIfPresent(Bool.self, forKey: .migratedFromLegacyProgress) ?? false
        self.storyForkChoices = try c.decodeIfPresent([String: Int].self, forKey: .storyForkChoices) ?? [:]
        self.seenStoryCardStageIDs = try c.decodeIfPresent(Set<String>.self, forKey: .seenStoryCardStageIDs) ?? []
        self.modifiedAt = try c.decodeIfPresent(Date.self, forKey: .modifiedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(Array(unlockedKitIds).sorted(), forKey: .unlockedKitIds)
        try c.encode(Array(unlockedSkinIds).sorted(), forKey: .unlockedSkinIds)
        try c.encode(Array(unlockedBonusTrackIds).sorted(), forKey: .unlockedBonusTrackIds)
        try c.encode(Array(completedExamStageIDs).sorted(), forKey: .completedExamStageIDs)
        try c.encode(Array(earnedMilestoneIDs).sorted(), forKey: .earnedMilestoneIDs)
        try c.encode(keysSpent, forKey: .keysSpent)
        try c.encode(legacyKeysBonus, forKey: .legacyKeysBonus)
        try c.encode(migratedFromLegacyProgress, forKey: .migratedFromLegacyProgress)
        try c.encode(storyForkChoices, forKey: .storyForkChoices)
        try c.encode(Array(seenStoryCardStageIDs).sorted(), forKey: .seenStoryCardStageIDs)
        try c.encodeIfPresent(modifiedAt, forKey: .modifiedAt)
    }

    public static func == (lhs: DrummerPathState, rhs: DrummerPathState) -> Bool {
        lhs.unlockedKitIds == rhs.unlockedKitIds &&
        lhs.unlockedSkinIds == rhs.unlockedSkinIds &&
        lhs.unlockedBonusTrackIds == rhs.unlockedBonusTrackIds &&
        lhs.completedExamStageIDs == rhs.completedExamStageIDs &&
        lhs.earnedMilestoneIDs == rhs.earnedMilestoneIDs &&
        lhs.keysSpent == rhs.keysSpent &&
        lhs.legacyKeysBonus == rhs.legacyKeysBonus &&
        lhs.migratedFromLegacyProgress == rhs.migratedFromLegacyProgress &&
        lhs.storyForkChoices == rhs.storyForkChoices &&
        lhs.seenStoryCardStageIDs == rhs.seenStoryCardStageIDs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(unlockedKitIds)
        hasher.combine(unlockedSkinIds)
        hasher.combine(unlockedBonusTrackIds)
        hasher.combine(completedExamStageIDs)
        hasher.combine(earnedMilestoneIDs)
        hasher.combine(keysSpent)
        hasher.combine(legacyKeysBonus)
        hasher.combine(migratedFromLegacyProgress)
        hasher.combine(storyForkChoices)
        hasher.combine(seenStoryCardStageIDs)
    }
}
