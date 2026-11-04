import Foundation

struct NoteDraft: Codable {
    var title: String
    var text: String
    var category: String
    static func key(for id: UUID?) -> String { "noteDraft." + (id?.uuidString ?? "new") }
}
