import Foundation

enum LibraryViewMode: String, CaseIterable, Identifiable {
    case path, genre, technique
    var id: String { rawValue }
    var title: String {
        switch self { case .path: return "Path"; case .genre: return "Genres"; case .technique: return "Techniques" }
    }
}

enum LessonTechnique: String, CaseIterable, Identifiable {
    case groove, sixteenths, ghost, swing, fills
    var id: String { rawValue }
    var title: String {
        switch self {
        case .groove: return "Basic groove"
        case .sixteenths: return "Sixteenths"
        case .ghost: return "Ghost notes"
        case .swing: return "Swing & shuffle"
        case .fills: return "Fills & toms"
        }
    }
    static func classify(_ lesson: Lesson) -> Self {
        if lesson.tags.contains("toms") || lesson.cat == "fills" { return .fills }
        if lesson.tags.contains("triplet feel") || lesson.division == 12 { return .swing }
        if lesson.tags.contains("ghost notes") { return .ghost }
        if lesson.tags.contains("16ths") { return .sixteenths }
        return .groove
    }
}

enum LessonGenre: String, CaseIterable, Identifiable {
    case rock, funk, jazz, hiphop, world, electronic, pop
    var id: String { rawValue }
    var title: String {
        switch self {
        case .rock: return "Rock & punk"
        case .funk: return "Funk, soul & blues"
        case .jazz: return "Jazz & New Orleans"
        case .hiphop: return "Hip hop & trap"
        case .world: return "Latin & world"
        case .electronic: return "Electronic"
        case .pop: return "Pop & country"
        }
    }
    static func classify(_ lesson: Lesson) -> Self {
        switch lesson.genre {
        case "Rock", "Punk": return .rock
        case "Funk", "Soul", "Gospel", "Blues": return .funk
        case "Jazz", "New Orleans": return .jazz
        case "Hip hop", "Trap", "Lo-fi", "Trip hop": return .hiphop
        case "Latin", "Afrobeat", "Afro-Cuban", "Highlife", "Reggae", "Reggaeton", "Middle Eastern", "Moombahton": return .world
        case "Pop", "Country": return .pop
        default: return .electronic
        }
    }
}

enum LibraryStarFilter: String, CaseIterable, Identifiable {
    case three, two, one, inProgress, notStarted
    var id: String { rawValue }
    var title: String {
        switch self {
        case .three: return "3★"
        case .two: return "2★"
        case .one: return "1★"
        case .inProgress: return "In progress"
        case .notStarted: return "Not started"
        }
    }
    static func stars(_ record: LessonProgress?) -> Int {
        guard let record else { return 0 }
        return [record.passed, record.mastery, record.memory].filter { $0 }.count
    }
    static func classify(_ record: LessonProgress?) -> Self {
        switch stars(record) {
        case 3: return .three
        case 2: return .two
        case 1: return .one
        default: return record?.hasPlayed == true ? .inProgress : .notStarted
        }
    }
}

enum NextLessonSource: String, CaseIterable, Identifiable {
    case path, genre, technique, all
    var id: String { rawValue }
    var title: String {
        switch self {
        case .path: return "Path"
        case .genre: return "Genre"
        case .technique: return "Technique"
        case .all: return "All (easiest first)"
        }
    }
}

struct LibraryStage: Identifiable {
    let level: Int
    let technique: LessonTechnique
    let lessons: [Lesson]
    var id: String { "L\(level)-\(technique.rawValue)" }
}

struct LibraryGroup: Identifiable {
    let id: String
    let title: String
    let lessons: [Lesson]
    var stage: LibraryStage? = nil
    var isExtension = false
}

/// Catalogue order is immutable and independent of saved progress and filters.
struct LibraryCatalog {
    let lessons: [Lesson]
    let introLessons: [Lesson]
    let stages: [LibraryStage]
    let path: [Lesson]
    private let ranks: [Int: Int]

    init(lessons: [Lesson]) {
        let projected = lessons.map(Self.project)
        self.lessons = projected
        var intro = projected.filter { $0.cat == "intro" && $0.id != 6 }
            .sorted { ($0.intro?.number ?? $0.id) < ($1.intro?.number ?? $1.id) }
        if let moved = projected.first(where: { $0.id == 6 && $0.cat == "intro" }) {
            let position = intro.lastIndex { $0.intro?.stage == moved.intro?.stage }.map { $0 + 1 } ?? intro.count
            intro.insert(moved, at: position)
        }
        introLessons = intro
        stages = (1...5).flatMap { level in
            LessonTechnique.allCases.compactMap { technique -> LibraryStage? in
                guard level < 4 || technique != .groove else { return nil }
                let members = projected.filter {
                    ($0.id != 6 || $0.cat != "intro") && !Self.isExtension($0) && $0.level == level && LessonTechnique.classify($0) == technique
                }
                return members.isEmpty ? nil : LibraryStage(level: level, technique: technique, lessons: Self.orderStage(members))
            }
        }
        path = stages.flatMap(\.lessons)
        var order = Dictionary(uniqueKeysWithValues: projected.enumerated().map { ($1.id, $0) })
        for (index, lesson) in path.enumerated() { order[lesson.id] = index }
        ranks = order
    }

    /// Move the retained core lesson into Intro without changing bundled data or progress IDs.
    private static func project(_ lesson: Lesson) -> Lesson {
        guard lesson.id == 6, lesson.cat == "starter" else { return lesson }
        return Lesson(id: lesson.id, cat: "intro", title: lesson.title, genre: lesson.genre,
                      tags: lesson.tags, text: lesson.text, division: lesson.division, bars: lesson.bars,
                      startBpm: lesson.startBpm, targetBpm: lesson.targetBpm, level: lesson.level,
                      score: lesson.score, src: lesson.src, hits: lesson.hits, hits8: lesson.hits8,
                      eightNote: lesson.eightNote,
                      intro: IntroMetadata(number: 21, stage: "Control and detail",
                                           goal: "Keep offbeat open hats steady over the kick.",
                                           watch: "Keep the kick pulse steady even when the hats feel stronger."))
    }

    static func isExtension(_ lesson: Lesson) -> Bool { ["jersey", "footwork"].contains(lesson.cat) }

    /// Intro lessons lead; genre queues retain their first-appearance and internal order.
    static func orderStage(_ lessons: [Lesson]) -> [Lesson] {
        var first: [Lesson] = []
        var genres: [LessonGenre] = []
        var queues: [LessonGenre: [Lesson]] = [:]
        for lesson in lessons {
            if lesson.cat == "intro" { first.append(lesson); continue }
            let genre = LessonGenre.classify(lesson)
            if queues[genre] == nil { genres.append(genre) }
            queues[genre, default: []].append(lesson)
        }
        for index in 0..<(queues.values.map(\.count).max() ?? 0) {
            for genre in genres {
                if let queue = queues[genre], index < queue.count { first.append(queue[index]) }
            }
        }
        return first
    }

    func stage(for lesson: Lesson) -> LibraryStage? { stages.first { $0.lessons.contains { $0.id == lesson.id } } }

    func groups(in view: LibraryViewMode) -> [LibraryGroup] {
        let extensions = lessons.filter(Self.isExtension)
        if view == .path {
            return stages.map { LibraryGroup(id: $0.id, title: $0.technique.title, lessons: $0.lessons, stage: $0) }
                + (extensions.isEmpty ? [] : [LibraryGroup(id: "extensions", title: "Jersey club and Footwork", lessons: sorted(extensions), isExtension: true)])
        }
        return [false, true].flatMap { extra -> [LibraryGroup] in
            let pool = extra ? extensions : path
            let prefix = extra ? "ext-" : ""
            let groups: [LibraryGroup]
            if view == .genre {
                groups = LessonGenre.allCases.map { genre in
                    LibraryGroup(id: prefix + genre.id, title: genre.title,
                                 lessons: sorted(pool.filter { LessonGenre.classify($0) == genre }), isExtension: extra)
                }
            } else {
                groups = LessonTechnique.allCases.map { technique in
                    LibraryGroup(id: prefix + technique.id, title: technique.title,
                                 lessons: sorted(pool.filter { LessonTechnique.classify($0) == technique }), isExtension: extra)
                }
            }
            return groups.filter { !$0.lessons.isEmpty }
        }
    }

    func matching(_ lessons: [Lesson], view: LibraryViewMode, query: String, cross: String,
                  language: AppLanguage) -> [Lesson] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return lessons.filter { lesson in
            let search = query.isEmpty || [lesson.title, lesson.genre, language.localized(lesson.title), language.localized(lesson.genre)]
                .contains { $0.localizedCaseInsensitiveContains(query) }
            return search && (cross.isEmpty || (view == .genre ? LessonTechnique.classify(lesson).id : LessonGenre.classify(lesson).id) == cross)
        }
    }

    func candidates(after anchor: Lesson?, source: NextLessonSource) -> [Lesson] {
        guard let anchor else { return path }
        if source == .path {
            if Self.isExtension(anchor) {
                let siblings = lessons.filter { $0.cat == anchor.cat }
                let index = siblings.firstIndex { $0.id == anchor.id } ?? siblings.count
                return Array(siblings.dropFirst(index + 1)) + path
            }
            return path
        }
        return lessons.filter { $0.id != 6 || $0.cat != "intro" }.filter {
            source == .all || (source == .genre ? LessonGenre.classify($0) == LessonGenre.classify(anchor) : LessonTechnique.classify($0) == LessonTechnique.classify(anchor))
        }.sorted { lhs, rhs in
            if source == .all, lhs.level != rhs.level { return lhs.level < rhs.level }
            if Self.isExtension(lhs) != Self.isExtension(rhs) { return !Self.isExtension(lhs) }
            if lhs.level != rhs.level { return lhs.level < rhs.level }
            return (ranks[lhs.id] ?? 0) < (ranks[rhs.id] ?? 0)
        }
    }

    private func sorted(_ lessons: [Lesson]) -> [Lesson] {
        lessons.sorted { $0.level != $1.level ? $0.level < $1.level : (ranks[$0.id] ?? 0) < (ranks[$1.id] ?? 0) }
    }
}
