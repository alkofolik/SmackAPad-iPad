import Foundation

/// Clockwise angle from twelve o'clock; the unoccupied lower arc is a hard stop.
enum LanguageKnobMapping {
    static let minimumAngle = -135.0
    static let maximumAngle = 135.0

    static func detent(fromAngle angle: Double) -> Int {
        let position = (min(max(angle, minimumAngle), maximumAngle) - minimumAngle)
            / (maximumAngle - minimumAngle)
        return Int((position * Double(AppLanguage.allCases.count - 1)).rounded())
    }

    static func angle(forDetent detent: Int) -> Double {
        let last = AppLanguage.allCases.count - 1
        guard last > 0 else { return 0 }
        return minimumAngle + Double(min(max(detent, 0), last)) / Double(last)
            * (maximumAngle - minimumAngle)
    }

    static func language(fromAngle angle: Double) -> AppLanguage {
        AppLanguage.allCases[detent(fromAngle: angle)]
    }

    static func angle(for language: AppLanguage) -> Double {
        angle(forDetent: AppLanguage.allCases.firstIndex(of: language) ?? 0)
    }
}

/// Physical switch order deliberately differs from the enum's declaration order.
enum AppearanceSwitchMapping {
    static let positions: [AppAppearance] = [.light, .system, .dark]

    static func appearance(fromPosition position: Double) -> AppAppearance {
        let index = Int((min(max(position, 0), 1) * Double(positions.count - 1)).rounded())
        return positions[index]
    }

    static func position(for appearance: AppAppearance) -> Double {
        Double(positions.firstIndex(of: appearance) ?? 1) / Double(positions.count - 1)
    }
}
