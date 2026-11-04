import Foundation

enum L10n {
    static func text(_ key: String) -> String { NSLocalizedString(key, comment: "") }
    static var speechLocale: Locale {
        Locale(identifier: Bundle.main.preferredLocalizations.first == "tr" ? "tr-TR" : "en-US")
    }
    static var locale: Locale {
        Locale(identifier: Bundle.main.preferredLocalizations.first == "tr" ? "tr_TR" : "en_US")
    }
    static func minutes(_ value: Int) -> String { String(format: text("duration.minutes"), value) }
    static func seconds(_ value: Int) -> String { String(format: text("duration.seconds"), value) }
    static func step(_ value: Int, total: Int) -> String { String(format: text("practice.step"), value, total) }
    static func remaining(_ clock: String) -> String { String(format: text("practice.remaining"), clock) }
}
