import Foundation
import XCTest
@testable import SmackAPad

final class LocalizationTests: XCTestCase {
    func testCataloguesHaveMatchingKeysFormatsAndNonemptyUniqueValues() throws {
        // Compiled strings files collapse duplicate assignments, so inspect the sources.
        let resources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("SmackAPad/Resources")
        let assignmentOrComment = try NSRegularExpression(
            pattern: #"(?s)/\*.*?\*/|//[^\r\n]*|"(?:\\.|[^"\\])*"\s*=\s*"(?:\\.|[^"\\])*"\s*;"#
        )
        // Space after a bare percent belongs to prose (e.g. "80 % in Play after me"),
        // not a printf space flag. Catalogue placeholders use adjacent conversion tokens.
        let formatSpecifier = try NSRegularExpression(
            pattern: #"%%|%(?:\d+\$)?[-+#0']*(?:\d+|\*(?:\d+\$)?)?(?:\.(?:\d+|\*(?:\d+\$)?))?(?:hh|ll|[hlLqjzt])?[@diuoxXfFeEgGaAcCsSpn]"#
        )
        func specifiers(in value: String) -> [String] {
            formatSpecifier.matches(in: value, range: NSRange(value.startIndex..., in: value))
                .compactMap { Range($0.range, in: value).map { String(value[$0]) } }
                .sorted()
        }

        var catalogues: [String: [String: String]] = [:]
        for language in ["en", "cs"] {
            let url = resources.appendingPathComponent("\(language).lproj/Localizable.strings")
            let source = try String(contentsOf: url, encoding: .utf8)
            let parsed = try XCTUnwrap(PropertyListSerialization.propertyList(
                from: Data(source.utf8), format: nil) as? [String: String])
            var keys: Set<String> = []
            for match in assignmentOrComment.matches(in: source, range: NSRange(source.startIndex..., in: source)) {
                let range = try XCTUnwrap(Range(match.range, in: source))
                let entry = source[range]
                guard entry.first == "\"" else { continue }
                let pair = try XCTUnwrap(PropertyListSerialization.propertyList(
                    from: Data(entry.utf8), format: nil) as? [String: String])
                let key = try XCTUnwrap(pair.keys.first)
                let value = try XCTUnwrap(pair[key])
                XCTAssertTrue(keys.insert(key).inserted, "\(language): duplicate key \(key)")
                XCTAssertFalse(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                               "\(language): empty value for \(key)")
            }
            XCTAssertFalse(keys.isEmpty, "\(language): empty catalogue")
            XCTAssertEqual(keys, Set(parsed.keys), "\(language): parsed keys")
            catalogues[language] = parsed
        }

        let english = try XCTUnwrap(catalogues["en"])
        let czech = try XCTUnwrap(catalogues["cs"])
        // Czech reminders select 1 / 2–4 / other counts using Czech-only keys.
        // English selects its own singular/plural keys. Require the exact exceptions
        // to remain in Czech rather than silently excluding them from validation.
        let czechReminderPluralKeys: Set<String> = [
            "1 lekce čeká na opakování",
            "%lld lekce čekají na opakování",
            "%lld lekcí čeká na opakování"
        ]
        XCTAssertEqual(Set(czech.keys).subtracting(english.keys), czechReminderPluralKeys,
                       "Only the documented Czech reminder plural keys may be absent from English")
        XCTAssertEqual(Set(english.keys).subtracting(czech.keys), [], "Keys missing from Czech")
        for (key, englishValue) in english.sorted(by: { $0.key < $1.key }) {
            let czechValue = try XCTUnwrap(czech[key], "cs: missing key \(key)")
            XCTAssertEqual(specifiers(in: englishValue), specifiers(in: czechValue),
                           "Format specifiers differ for \(key)")
        }
        for key in czechReminderPluralKeys.sorted() {
            let value = try XCTUnwrap(czech[key], "cs: missing plural key \(key)")
            XCTAssertEqual(specifiers(in: key), specifiers(in: value), "Czech plural format: \(key)")
        }
    }

    func testPadDisplayNamesMatchAcrossEnglishAndCzech() throws {
        let suite = "LocalizationTests.PadDisplayNames.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let settings = SettingsManager(userDefaults: defaults)
        for pad in PadVoice.names.indices {
            let canonical = PadVoice.displayName(pad)
            settings.languagePreference = .english
            let english = PadVoice.name(pad, settings: settings)
            settings.languagePreference = .czech
            let czech = PadVoice.name(pad, settings: settings)

            XCTAssertEqual(english, canonical, "English name drifted for pad \(pad)")
            XCTAssertEqual(czech, canonical, "Czech name must stay English for pad \(pad)")
            XCTAssertEqual(settings.localized(canonical), canonical,
                           "Localizable.strings must keep English drum name '\(canonical)' in Czech")
        }
    }
}
