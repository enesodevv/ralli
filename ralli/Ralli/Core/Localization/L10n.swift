import Foundation

enum L10n {
    static func text(_ key: String) -> String { NSLocalizedString(key, comment: "") }
    /// The app language iOS picked from the user's preferences (falls back to English).
    static var language: String { Bundle.main.preferredLocalizations.first ?? "en" }
    /// Speech recognition and spoken cues use the regional voice of the app language.
    static var speechLocale: Locale {
        let regions = ["tr": "tr-TR", "es": "es-ES", "de": "de-DE", "fr": "fr-FR", "it": "it-IT"]
        return Locale(identifier: regions[language] ?? "en-US")
    }
    /// Used for case changes (Turkish dotted i) and formatting.
    static var locale: Locale { Locale(identifier: language) }
    static func minutes(_ value: Int) -> String { String(format: text("duration.minutes"), value) }
    static func seconds(_ value: Int) -> String { String(format: text("duration.seconds"), value) }
    static func step(_ value: Int, total: Int) -> String { String(format: text("practice.step"), value, total) }
    static func remaining(_ clock: String) -> String { String(format: text("practice.remaining"), clock) }
}
