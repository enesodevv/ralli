import Foundation
import SwiftData

/// One atomic snapshot keeps the two histories and the legacy session count consistent.
@Model final class PlayerArchive {
    @Attribute(.unique) var key: String
    var notes: Data
    var records: Data
    var preferences: Data? = nil
    var sessionDraft: Data? = nil
    var completedSessions: Int
    init(notes: Data, records: Data, completedSessions: Int) {
        key = "player"
        self.notes = notes
        self.records = records
        self.completedSessions = completedSessions
    }
}
