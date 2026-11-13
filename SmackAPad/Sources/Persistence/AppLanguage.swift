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

    /// Short physical detent labels; adding a language automatically adds a Home knob detent.
    var homeDetentLabel: String {
        self == .czech ? "CZ" : rawValue.uppercased()
    }

    /// Bundle containing localized strings for this language.
    public var bundle: Bundle {
        if let path = Bundle.main.path(forResource: rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        for candidate in Bundle.allBundles {
            if let path = candidate.path(forResource: rawValue, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }
        }
        return .main
    }

    /// Localize a key using this language bundle.
    public func localized(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    /// Localize a key if defined in this language bundle, or return nil if missing.
    public func localizedOptional(_ key: String) -> String? {
        let sentinel = "\u{0000}__MISSING__\u{0000}"
        let result = bundle.localizedString(forKey: key, value: sentinel, table: nil)
        return result == sentinel ? nil : result
    }

    /// Localize a format key using this language bundle and locale.
    public func localized(_ key: String, _ arguments: CVarArg...) -> String {
        let format = localized(key)
        return String(format: format, locale: Locale(identifier: rawValue), arguments: arguments)
    }

    /// Formats a lesson count with English and Czech singular/plural forms.
    public func localizedLessonCount(_ count: Int) -> String {
        switch self {
        case .czech:
            if count == 1 { return "1 lekce" }
            if count >= 2 && count <= 4 { return "\(count) lekce" }
            return "\(count) lekcí"
        case .english:
            return count == 1 ? localized("1 lesson") : localized("%lld lessons", count)
        }
    }
}

