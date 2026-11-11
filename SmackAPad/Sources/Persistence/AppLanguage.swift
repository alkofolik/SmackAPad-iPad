//
//  AppLanguage.swift
//  SmackAPad
//

import Foundation

/// Supported app localization preferences.
public enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case english = "en"
    case czech = "cs"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .czech: return "Čeština"
        }
    }

    /// Bundle containing localized strings for this language.
    public var bundle: Bundle {
        if let path = Bundle.main.path(forResource: rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }

    /// Localize a key using this language bundle.
    public func localized(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    /// Localize a format key using this language bundle and locale.
    public func localized(_ key: String, _ arguments: CVarArg...) -> String {
        let format = localized(key)
        return String(format: format, locale: Locale(identifier: rawValue), arguments: arguments)
    }
}

