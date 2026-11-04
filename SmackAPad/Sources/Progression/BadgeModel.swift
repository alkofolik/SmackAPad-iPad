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

    init(
        id: String,
        name: String,
        condition: String,
        metric: String,
        goal: BadgeGoal,
        tier: Int,
        group: BadgeGroup
    ) {
        self.id = id
        self.name = name
        self.condition = condition
        self.metric = metric
        self.goal = goal
        self.tier = tier
        self.group = group
    }
}
