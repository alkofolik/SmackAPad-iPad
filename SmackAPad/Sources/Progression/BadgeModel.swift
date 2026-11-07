import Foundation

/// Goal requirement for a badge: an exact count, all catalogue lessons, or all group lessons.
enum BadgeGoal: Codable, Equatable, Hashable, Sendable {
    case count(Int)
    case catalogue
    case group

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            self = .count(intVal)
        } else if let strVal = try? container.decode(String.self) {
            switch strVal {
            case "catalogue": self = .catalogue
            case "group": self = .group
            default:
                if let intVal = Int(strVal) {
                    self = .count(intVal)
                } else {
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown goal: \(strVal)")
                }
            }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid goal")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .count(let val): try container.encode(val)
        case .catalogue: try container.encode("catalogue")
        case .group: try container.encode("group")
        }
    }
}

/// Badge display and grouping category matching legacy sections.
enum BadgeGroup: String, CaseIterable, Identifiable, Codable, Sendable {
    case passed = "passed"
    case mastered = "mastered"
    case memory = "memory"
    case courses = "courses"
    case levels = "levels"
    case genres = "genres"
    case techniques = "techniques"
    case training = "training"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .passed: return "Passed lessons"
        case .mastered: return "Goal tempo"
        case .memory: return "Memory practice"
        case .courses: return "Completed stages"
        case .levels: return "Levels"
        case .genres: return "Genres"
        case .techniques: return "Techniques"
        case .training: return "Training"
        }
    }

    var defaultIcon: String {
        switch self {
        case .passed: return "pad"
        case .mastered: return "metronome"
        case .memory: return "eye"
        case .courses: return "flag"
        case .levels: return "stairs"
        case .genres: return "note"
        case .techniques: return "four"
        case .training: return "review"
        }
    }
}

/// Static definition of an achievement badge loaded from bundled JSON.
struct BadgeDefinition: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
    let condition: String
    let metric: String
    let goal: BadgeGoal
    let tier: Int
    let group: BadgeGroup
    let icon: String?

    var resolvedIcon: String {
        icon ?? group.defaultIcon
    }

    var iconAssetName: String {
        let name = resolvedIcon
        return name.hasPrefix("badge-") ? name : "badge-\(name)"
    }

    init(
        id: String,
        name: String,
        condition: String,
        metric: String,
        goal: BadgeGoal,
        tier: Int,
        group: BadgeGroup,
        icon: String? = nil
    ) {
        self.id = id
        self.name = name
        self.condition = condition
        self.metric = metric
        self.goal = goal
        self.tier = tier
        self.group = group
        self.icon = icon
    }

    enum CodingKeys: String, CodingKey {
        case id, name, condition, metric, goal, tier, group, icon
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.condition = try container.decode(String.self, forKey: .condition)
        self.metric = try container.decode(String.self, forKey: .metric)
        self.goal = try container.decode(BadgeGoal.self, forKey: .goal)
        self.tier = try container.decode(Int.self, forKey: .tier)
        self.group = try container.decode(BadgeGroup.self, forKey: .group)
        self.icon = try container.decodeIfPresent(String.self, forKey: .icon)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(condition, forKey: .condition)
        try container.encode(metric, forKey: .metric)
        try container.encode(goal, forKey: .goal)
        try container.encode(tier, forKey: .tier)
        try container.encode(group, forKey: .group)
        try container.encodeIfPresent(icon, forKey: .icon)
    }
}
