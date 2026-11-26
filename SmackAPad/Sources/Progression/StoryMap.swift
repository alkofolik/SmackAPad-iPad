import Foundation

/// A single node in a stage's story progression map.
enum StoryMapNode: Equatable, Hashable, Codable, Sendable {
    case keystone(Int)
    case fork([Int])

    var lessonIds: [Int] {
        switch self {
        case .keystone(let id): return [id]
        case .fork(let ids): return ids
        }
    }

    var isKeystone: Bool {
        if case .keystone = self { return true }
        return false
    }

    var isFork: Bool {
        if case .fork = self { return true }
        return false
    }

    private enum CodingKeys: String, CodingKey {
        case keystone
        case fork
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hasKeystone = container.contains(.keystone)
        let hasFork = container.contains(.fork)
        switch (hasKeystone, hasFork) {
        case (true, false):
            self = .keystone(try container.decode(Int.self, forKey: .keystone))
        case (false, true):
            self = .fork(try container.decode([Int].self, forKey: .fork))
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "StoryMapNode must contain exactly one of 'keystone' or 'fork'."
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .keystone(let id):
            try container.encode(id, forKey: .keystone)
        case .fork(let ids):
            try container.encode(ids, forKey: .fork)
        }
    }
}

enum StoryMapValidationError: Error, Equatable, CustomStringConvertible {
    case missingStages([String])
    case unknownStages([String])
    case emptyStage(String)
    case stageMustStartWithKeystone(String)
    case stageMustEndWithKeystone(String)
    case invalidForkSize(stageId: String, nodeIndex: Int, count: Int)
    case duplicateLesson(Int)
    case wrongStageLessons(stageId: String, missing: [Int], unexpected: [Int])
    case pathCoverageMismatch(missing: [Int], extra: [Int])

    var description: String {
        switch self {
        case .missingStages(let ids):
            return "Missing stages: \(ids.joined(separator: ", "))"
        case .unknownStages(let ids):
            return "Unknown stages: \(ids.joined(separator: ", "))"
        case .emptyStage(let id):
            return "Stage \(id) has no nodes"
        case .stageMustStartWithKeystone(let id):
            return "Stage \(id) must start with a keystone"
        case .stageMustEndWithKeystone(let id):
            return "Stage \(id) must end with a keystone"
        case .invalidForkSize(let stageId, let nodeIndex, let count):
            return "Fork at \(stageId)[\(nodeIndex)] has \(count) lessons (expected 2 or 3)"
        case .duplicateLesson(let id):
            return "Lesson \(id) appears more than once in the story map"
        case .wrongStageLessons(let stageId, let missing, let unexpected):
            return "Stage \(stageId) mismatch (missing: \(missing), unexpected: \(unexpected))"
        case .pathCoverageMismatch(let missing, let extra):
            return "Path coverage mismatch (missing: \(missing), extra: \(extra))"
        }
    }
}

/// Ordered keystones and forks for every Path stage, loaded from `story-map.json`.
struct StoryMap: Equatable, Codable, Sendable {
    let stages: [String: [StoryMapNode]]

    init(stages: [String: [StoryMapNode]]) {
        self.stages = stages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        stages = try container.decode([String: [StoryMapNode]].self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stages)
    }

    func nodes(for stageId: String) -> [StoryMapNode] {
        stages[stageId] ?? []
    }

    static func loadBundled(bundle: Bundle = .main) throws -> StoryMap {
        let url = try DataLoader.shared.findResourceURL(named: "story-map", withExtension: "json", in: bundle)
        return try load(from: url)
    }

    static func load(from url: URL) throws -> StoryMap {
        try DataLoader.shared.loadJSON(from: url)
    }

    /// Validates stage coverage, node structure, fork sizes, and Path lesson uniqueness.
    func validate(against catalog: LibraryCatalog) throws {
        let expectedStageIds = Set(catalog.stages.map(\.id))
        let actualStageIds = Set(stages.keys)

        let missingStages = expectedStageIds.subtracting(actualStageIds).sorted()
        if !missingStages.isEmpty {
            throw StoryMapValidationError.missingStages(missingStages)
        }
        let unknownStages = actualStageIds.subtracting(expectedStageIds).sorted()
        if !unknownStages.isEmpty {
            throw StoryMapValidationError.unknownStages(unknownStages)
        }

        var seenGlobal = Set<Int>()
        for stage in catalog.stages {
            let nodes = stages[stage.id] ?? []
            guard let first = nodes.first, let last = nodes.last else {
                throw StoryMapValidationError.emptyStage(stage.id)
            }
            if !first.isKeystone {
                throw StoryMapValidationError.stageMustStartWithKeystone(stage.id)
            }
            if !last.isKeystone {
                throw StoryMapValidationError.stageMustEndWithKeystone(stage.id)
            }

            var stageIds: [Int] = []
            for (index, node) in nodes.enumerated() {
                if case .fork(let ids) = node, !(2...3).contains(ids.count) {
                    throw StoryMapValidationError.invalidForkSize(stageId: stage.id, nodeIndex: index, count: ids.count)
                }
                for lessonId in node.lessonIds {
                    if !seenGlobal.insert(lessonId).inserted {
                        throw StoryMapValidationError.duplicateLesson(lessonId)
                    }
                    stageIds.append(lessonId)
                }
            }

            let expectedIds = Set(stage.lessons.filter { $0.cat != "intro" }.map(\.id))
            let actualIds = Set(stageIds)
            if actualIds != expectedIds {
                throw StoryMapValidationError.wrongStageLessons(
                    stageId: stage.id,
                    missing: expectedIds.subtracting(actualIds).sorted(),
                    unexpected: actualIds.subtracting(expectedIds).sorted()
                )
            }
        }

        let expectedPathIds = Set(catalog.path.filter { $0.cat != "intro" }.map(\.id))
        if seenGlobal != expectedPathIds {
            throw StoryMapValidationError.pathCoverageMismatch(
                missing: expectedPathIds.subtracting(seenGlobal).sorted(),
                extra: seenGlobal.subtracting(expectedPathIds).sorted()
            )
        }
    }
}
