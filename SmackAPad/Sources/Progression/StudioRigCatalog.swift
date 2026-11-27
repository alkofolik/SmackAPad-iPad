import Foundation

// MARK: - Drum Kit Catalog & Lesson Binding

/// Metadata and lesson-unlock mapping for one of the 8 bundled drum kits.
public struct DrumKitDescriptor: Identifiable, Equatable, Hashable, Sendable {
    public var id: String { kitId }
    public let kitId: String
    public let name: String
    public let studioTitle: String
    public let clanEpithet: String
    public let clanEpithetCzech: String
    public let isStarter: Bool
    public let unlockCost: Int
    public let boundGenres: [String]

    public init(
        kitId: String,
        name: String,
        studioTitle: String,
        clanEpithet: String = "",
        clanEpithetCzech: String = "",
        isStarter: Bool,
        unlockCost: Int,
        boundGenres: [String]
    ) {
        self.kitId = kitId
        self.name = name
        self.studioTitle = studioTitle
        self.clanEpithet = clanEpithet
        self.clanEpithetCzech = clanEpithetCzech
        self.isStarter = isStarter
        self.unlockCost = unlockCost
        self.boundGenres = boundGenres
    }

    public func localizedClanEpithet(language: AppLanguage) -> String {
        switch language {
        case .english: return clanEpithet
        case .czech: return clanEpithetCzech.isEmpty ? clanEpithet : clanEpithetCzech
        }
    }
}

/// Lesson availability with respect to the player's unlocked drum kits.
public enum LessonKitAccessStatus: Equatable, Sendable {
    case unlocked(kit: DrumKitDescriptor)
    case requiresKit(kit: DrumKitDescriptor, unlockCost: Int, keysAvailable: Int, message: String)

    public var isUnlocked: Bool {
        if case .unlocked = self { return true }
        return false
    }

    public var requiredKit: DrumKitDescriptor {
        switch self {
        case .unlocked(let kit): return kit
        case .requiresKit(let kit, _, _, _): return kit
        }
    }

    public var canUnlockNow: Bool {
        switch self {
        case .unlocked: return false
        case .requiresKit(_, let cost, let available, _): return available >= cost
        }
    }

    public var statusMessage: String? {
        switch self {
        case .unlocked: return nil
        case .requiresKit(_, _, _, let message): return message
        }
    }
}

/// Catalog of all 8 bundled drum kits (1 Starter unlocked from the start, 7 unlockable for 1 key each).
public enum DrumKitCatalog {
    public static let starterKitId = "acoustic"
    public static let kitUnlockCost = 1

    public static let allKits: [DrumKitDescriptor] = [
        DrumKitDescriptor(
            kitId: "acoustic",
            name: "Starter",
            studioTitle: "Starter · Acoustic AVL",
            clanEpithet: "The Common Drum",
            clanEpithetCzech: "Obyčejný buben",
            isStarter: true,
            unlockCost: 0,
            boundGenres: ["Funk", "Disco"]
        ),
        DrumKitDescriptor(
            kitId: "rock",
            name: "Rock",
            studioTitle: "Rock · Big Rusty + VCSL",
            clanEpithet: "The Iron Assembly",
            clanEpithetCzech: "Železný sbor",
            isStarter: false,
            unlockCost: kitUnlockCost,
            boundGenres: ["Rock", "Punk", "Gospel"]
        ),
        DrumKitDescriptor(
            kitId: "808",
            name: "808",
            studioTitle: "Electronic · Fischer 808",
            clanEpithet: "The Buried Engine",
            clanEpithetCzech: "Pohřbený stroj",
            isStarter: false,
            unlockCost: kitUnlockCost,
            boundGenres: ["Hip hop", "Trap", "Miami bass", "Electro"]
        ),
        DrumKitDescriptor(
            kitId: "house",
            name: "House",
            studioTitle: "House / Techno · Synthesized",
            clanEpithet: "The Endless Hall",
            clanEpithetCzech: "Nekonečná síň",
            isStarter: false,
            unlockCost: kitUnlockCost,
            boundGenres: [
                "Dance", "House", "Deep house", "Tech house", "Techno",
                "Hard techno", "Trance", "UK garage", "Dubstep", "Drum and bass",
                "Jungle", "Breakbeat", "Moombahton", "Synthwave",
                "Broken techno", "Hardgroove", "UK funky", "Jersey club",
                "Footwork / juke", "Speed garage"
            ]
        ),
        DrumKitDescriptor(
            kitId: "jazz",
            name: "Jazz",
            studioTitle: "Jazz · Virtuosity + AVL",
            clanEpithet: "The Crooked Brass",
            clanEpithetCzech: "Křivá dechovka",
            isStarter: false,
            unlockCost: kitUnlockCost,
            boundGenres: ["Jazz", "New Orleans"]
        ),
        DrumKitDescriptor(
            kitId: "brush",
            name: "Brush",
            studioTitle: "Brush · Swirly + VCSL",
            clanEpithet: "The Quiet Council",
            clanEpithetCzech: "Tichá rada",
            isStarter: false,
            unlockCost: kitUnlockCost,
            boundGenres: ["Soul", "Blues", "Lo-fi", "Trip hop", "Country", "Pop"]
        ),
        DrumKitDescriptor(
            kitId: "world",
            name: "World",
            studioTitle: "World · Acoustic Percussion",
            clanEpithet: "The Wandering Circle",
            clanEpithetCzech: "Putující kruh",
            isStarter: false,
            unlockCost: kitUnlockCost,
            boundGenres: ["Latin", "Afrobeat", "Highlife", "Reggae", "Reggaeton", "Middle Eastern"]
        ),
        DrumKitDescriptor(
            kitId: "worldperc",
            name: "World Percussion",
            studioTitle: "World Percussion · VCSL + Swirly",
            clanEpithet: "The Gathering of Hands",
            clanEpithetCzech: "Shromáždění rukou",
            isStarter: false,
            unlockCost: kitUnlockCost,
            boundGenres: ["Afro-Cuban"]
        )
    ]

    public static let kitsById: [String: DrumKitDescriptor] = Dictionary(
        uniqueKeysWithValues: allKits.map { ($0.kitId, $0) }
    )

    public static var starterKit: DrumKitDescriptor {
        kitsById[starterKitId]!
    }

    public static func kit(forId kitId: String) -> DrumKitDescriptor? {
        kitsById[kitId]
    }

    /// Maps a lesson to its required drum kit ID.
    /// Intro lessons (`cat == "intro"` or projected starter lesson `id == 6`) always run on the Starter kit.
    public static func requiredKitId(for lesson: Lesson) -> String {
        if lesson.cat == "intro" || (lesson.id == 6 && lesson.cat == "starter") {
            return starterKitId
        }
        let normalized = lesson.genre.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return starterKitId }
        for kit in allKits {
            if kit.boundGenres.contains(where: { $0.lowercased() == normalized }) {
                return kit.kitId
            }
        }
        return starterKitId
    }

    public static func requiredKit(for lesson: Lesson) -> DrumKitDescriptor {
        let id = requiredKitId(for: lesson)
        return kitsById[id] ?? starterKit
    }

    /// Ordered unique kits required across all lessons in a chapter/stage.
    static func requiredKits(for stage: LibraryStage) -> [DrumKitDescriptor] {
        var seen: Set<String> = []
        var result: [DrumKitDescriptor] = []
        for lesson in stage.lessons {
            let kit = requiredKit(for: lesson)
            if seen.insert(kit.kitId).inserted {
                result.append(kit)
            }
        }
        return result
    }

    /// Returns whether a lesson can be played with currently unlocked kits, or a clear unlock prompt.
    public static func accessStatus(
        for lesson: Lesson,
        state: DrummerPathState,
        language: AppLanguage = .english
    ) -> LessonKitAccessStatus {
        let kit = requiredKit(for: lesson)
        if state.isKitUnlocked(kit.kitId) {
            return .unlocked(kit: kit)
        }
        let cost = max(1, kit.unlockCost)
        let message = lockedKitMessage(kitName: kit.name, cost: cost, language: language)
        return .requiresKit(
            kit: kit,
            unlockCost: cost,
            keysAvailable: state.availableKeys,
            message: message
        )
    }

    public static func lockedKitMessage(kitName: String, cost: Int = 1, language: AppLanguage = .english) -> String {
        switch language {
        case .english:
            let unit = cost == 1 ? "key" : "keys"
            return "Requires \(kitName) kit (unlock for \(cost) \(unit))"
        case .czech:
            let unit: String
            if cost == 1 {
                unit = "klíč"
            } else if (2...4).contains(cost) {
                unit = "klíče"
            } else {
                unit = "klíčů"
            }
            return "Vyžaduje sadu \(kitName) (odemkni za \(cost) \(unit))"
        }
    }
}

// MARK: - Studio Rewards: Instrument Skins & Bonus Jam Tracks

/// Unlock condition for studio skins and bonus jam tracks.
public enum StudioRewardRequirement: Equatable, Hashable, Sendable {
    case starter
    case milestone(id: String)
    case stageExam(stageId: String)
    case anyStageExamInLevel(level: Int)
    case bossesDefeated(count: Int)
    case rank(DrummerRank)

    public func isSatisfied(by state: DrummerPathState, card: DrummerCardSnapshot) -> Bool {
        switch self {
        case .starter:
            return true
        case .milestone(let id):
            return state.earnedMilestoneIDs.contains(id)
        case .stageExam(let stageId):
            return state.completedExamStageIDs.contains(stageId)
        case .anyStageExamInLevel(let level):
            return state.completedExamStageIDs.contains { $0.hasPrefix("L\(level)-") }
        case .bossesDefeated(let count):
            return state.defeatedStageBossCount >= count
        case .rank(let requiredRank):
            return card.rank >= requiredRank
        }
    }

    public func description(language: AppLanguage = .english) -> String {
        switch (self, language) {
        case (.starter, .english): return "Unlocked from start"
        case (.starter, .czech): return "Odemčeno od začátku"
        case (.milestone(let id), .english): return "Milestone: \(id)"
        case (.milestone(let id), .czech): return "Milník: \(id)"
        case (.stageExam(let stageId), .english): return "Stage exam: \(stageId)"
        case (.stageExam(let stageId), .czech): return "Zkouška etapy: \(stageId)"
        case (.anyStageExamInLevel(let level), .english): return "Complete any Level \(level) stage exam"
        case (.anyStageExamInLevel(let level), .czech): return "Splň zkoušku libovolné etapy úrovně \(level)"
        case (.bossesDefeated(let count), .english):
            return count == 1 ? "Defeat 1 stage boss" : "Defeat \(count) stage bosses"
        case (.bossesDefeated(let count), .czech):
            if count == 1 { return "Poraz 1 bosse etapy" }
            if (2...4).contains(count) { return "Poraz \(count) bossy etap" }
            return "Poraz \(count) bossů etap"
        case (.rank(let rank), .english): return "Reach rank \(rank.title)"
        case (.rank(let rank), .czech): return "Dosáhni hodnosti \(rank.title)"
        }
    }
}

/// Hardware appearance theme variant for the Studio Rig instrument chassis.
public struct InstrumentSkin: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let accentHex: UInt32
    public let chassisHex: UInt32
    public let padSurfaceHex: UInt32
    public let isDefault: Bool
    public let unlockRequirement: StudioRewardRequirement

    public init(
        id: String,
        name: String,
        subtitle: String,
        accentHex: UInt32,
        chassisHex: UInt32,
        padSurfaceHex: UInt32,
        isDefault: Bool = false,
        unlockRequirement: StudioRewardRequirement
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.accentHex = accentHex
        self.chassisHex = chassisHex
        self.padSurfaceHex = padSurfaceHex
        self.isDefault = isDefault
        self.unlockRequirement = unlockRequirement
    }
}

/// Bonus jam or practice groove unlocked via milestones and stage exams.
public struct BonusJamTrack: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let genre: String
    public let bpm: Int
    public let bars: Int
    public let kitId: String
    public let hits: [LessonHit]
    public let unlockRequirement: StudioRewardRequirement

    public init(
        id: String,
        title: String,
        subtitle: String,
        genre: String,
        bpm: Int,
        bars: Int,
        kitId: String,
        hits: [LessonHit],
        unlockRequirement: StudioRewardRequirement
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.genre = genre
        self.bpm = bpm
        self.bars = bars
        self.kitId = kitId
        self.hits = hits
        self.unlockRequirement = unlockRequirement
    }

    /// Converts this bonus track into a playable Lesson model for practice or audio preview.
    public func asLesson(syntheticId: Int = -1) -> Lesson {
        Lesson(
            id: syntheticId,
            cat: "bonus",
            title: title,
            genre: genre,
            tags: ["bonus-jam"],
            text: subtitle,
            division: 16,
            bars: bars,
            startBpm: max(60, bpm - 15),
            targetBpm: bpm,
            level: 2,
            src: "studio-rig-bonus",
            hits: hits,
            access: "free"
        )
    }
}

/// Registry of unlockable studio instrument skins and bonus jam tracks.
public enum StudioRigCatalog {
    public static let defaultSkinId = "smack-orange"

    public static let skins: [InstrumentSkin] = [
        InstrumentSkin(
            id: "smack-orange",
            name: "Smack Orange",
            subtitle: "Signature cream & soft-black studio deck",
            accentHex: 0xFF6B00,
            chassisHex: 0x1F1D1A,
            padSurfaceHex: 0x2A2824,
            isDefault: true,
            unlockRequirement: .starter
        ),
        InstrumentSkin(
            id: "midnight-mpc",
            name: "Midnight Studio",
            subtitle: "Anodized slate chassis with cobalt LEDs",
            accentHex: 0x3B82F6,
            chassisHex: 0x12161F,
            padSurfaceHex: 0x1D2432,
            isDefault: false,
            unlockRequirement: .bossesDefeated(count: 1)
        ),
        InstrumentSkin(
            id: "cream-vintage",
            name: "Cream Vintage 80s",
            subtitle: "Warm retro sampler plate with amber LEDs",
            accentHex: 0xD97706,
            chassisHex: 0xEAE2D3,
            padSurfaceHex: 0xD8CFC0,
            isDefault: false,
            unlockRequirement: .bossesDefeated(count: 5)
        ),
        InstrumentSkin(
            id: "acid-rack",
            name: "Acid Synth Rack",
            subtitle: "Dark rackmount deck with acid-lime trim",
            accentHex: 0x84CC16,
            chassisHex: 0x141714,
            padSurfaceHex: 0x20261F,
            isDefault: false,
            unlockRequirement: .bossesDefeated(count: 15)
        )
    ]

    public static let bonusTracks: [BonusJamTrack] = [
        BonusJamTrack(
            id: "jam-pocket-starter",
            title: "Pocket Warm-Up Jam",
            subtitle: "Crisp kick-snare pocket for freeform groove",
            genre: "Funk",
            bpm: 96,
            bars: 1,
            kitId: "acoustic",
            hits: [
                LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 112),
                LessonHit(step: 0, padIndex: 11, hand: "R", velocity: 96),
                LessonHit(step: 2, padIndex: 11, hand: "R", velocity: 78),
                LessonHit(step: 4, padIndex: 13, hand: "L", velocity: 110),
                LessonHit(step: 4, padIndex: 11, hand: "R", velocity: 96),
                LessonHit(step: 6, padIndex: 12, hand: "L", velocity: 94),
                LessonHit(step: 8, padIndex: 12, hand: "L", velocity: 108),
                LessonHit(step: 10, padIndex: 11, hand: "R", velocity: 82),
                LessonHit(step: 12, padIndex: 13, hand: "L", velocity: 114),
                LessonHit(step: 14, padIndex: 7, hand: "R", velocity: 92)
            ],
            unlockRequirement: .milestone(id: "intro-graduate")
        ),
        BonusJamTrack(
            id: "jam-rock-basement",
            title: "Basement Break",
            subtitle: "Driving eighth-note rock jam with open hat accents",
            genre: "Rock",
            bpm: 112,
            bars: 1,
            kitId: "rock",
            hits: [
                LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 118),
                LessonHit(step: 0, padIndex: 2, hand: "R", velocity: 105),
                LessonHit(step: 4, padIndex: 13, hand: "L", velocity: 115),
                LessonHit(step: 6, padIndex: 12, hand: "L", velocity: 100),
                LessonHit(step: 8, padIndex: 12, hand: "L", velocity: 115),
                LessonHit(step: 10, padIndex: 12, hand: "L", velocity: 102),
                LessonHit(step: 12, padIndex: 13, hand: "L", velocity: 118),
                LessonHit(step: 14, padIndex: 7, hand: "R", velocity: 98)
            ],
            unlockRequirement: .anyStageExamInLevel(level: 1)
        ),
        BonusJamTrack(
            id: "jam-broken-club",
            title: "Warehouse 808 Bounce",
            subtitle: "Syncopated 808 bounce & clap pocket",
            genre: "Hip hop",
            bpm: 124,
            bars: 1,
            kitId: "808",
            hits: [
                LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 120),
                LessonHit(step: 3, padIndex: 11, hand: "R", velocity: 88),
                LessonHit(step: 4, padIndex: 9, hand: "L", velocity: 112),
                LessonHit(step: 6, padIndex: 12, hand: "L", velocity: 106),
                LessonHit(step: 10, padIndex: 12, hand: "L", velocity: 108),
                LessonHit(step: 12, padIndex: 9, hand: "L", velocity: 116),
                LessonHit(step: 15, padIndex: 11, hand: "R", velocity: 84)
            ],
            unlockRequirement: .anyStageExamInLevel(level: 2)
        ),
        BonusJamTrack(
            id: "jam-memory-groove",
            title: "Midnight Ghost Pocket",
            subtitle: "Low-volume ghost snare flow for memory runs",
            genre: "Soul",
            bpm: 92,
            bars: 1,
            kitId: "brush",
            hits: [
                LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 105),
                LessonHit(step: 3, padIndex: 13, hand: "L", velocity: 48),
                LessonHit(step: 4, padIndex: 13, hand: "L", velocity: 108),
                LessonHit(step: 7, padIndex: 13, hand: "L", velocity: 45),
                LessonHit(step: 9, padIndex: 12, hand: "L", velocity: 96),
                LessonHit(step: 12, padIndex: 13, hand: "L", velocity: 110)
            ],
            unlockRequirement: .milestone(id: "review-habit")
        ),
        BonusJamTrack(
            id: "jam-jazz-lounge",
            title: "Blue Note Ride",
            subtitle: "Swing ride pulse with comping snare hits",
            genre: "Jazz",
            bpm: 132,
            bars: 1,
            kitId: "jazz",
            hits: [
                LessonHit(step: 0, padIndex: 3, hand: "R", velocity: 100),
                LessonHit(step: 4, padIndex: 3, hand: "R", velocity: 95),
                LessonHit(step: 6, padIndex: 13, hand: "L", velocity: 78),
                LessonHit(step: 8, padIndex: 3, hand: "R", velocity: 102),
                LessonHit(step: 12, padIndex: 3, hand: "R", velocity: 96),
                LessonHit(step: 14, padIndex: 12, hand: "L", velocity: 88)
            ],
            unlockRequirement: .anyStageExamInLevel(level: 3)
        ),
        BonusJamTrack(
            id: "jam-studio-session",
            title: "Architect Afro-Clave",
            subtitle: "Poly-rhythmic percussion & drum kit showcase",
            genre: "Afro-Cuban",
            bpm: 118,
            bars: 1,
            kitId: "worldperc",
            hits: [
                LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 112),
                LessonHit(step: 3, padIndex: 6, hand: "R", velocity: 104),
                LessonHit(step: 6, padIndex: 6, hand: "R", velocity: 100),
                LessonHit(step: 8, padIndex: 13, hand: "L", velocity: 108),
                LessonHit(step: 10, padIndex: 6, hand: "R", velocity: 98),
                LessonHit(step: 12, padIndex: 6, hand: "R", velocity: 104),
                LessonHit(step: 14, padIndex: 12, hand: "L", velocity: 106)
            ],
            unlockRequirement: .milestone(id: "twenty-five-mastered")
        )
    ]

    public static func skin(forId id: String) -> InstrumentSkin? {
        skins.first { $0.id == id }
    }

    public static func bonusTrack(forId id: String) -> BonusJamTrack? {
        bonusTracks.first { $0.id == id }
    }
}
