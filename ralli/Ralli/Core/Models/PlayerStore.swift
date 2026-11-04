import SwiftUI
import SwiftData

struct LessonNote: Identifiable, Codable {
    var id = UUID()
    var title: String
    var text: String
    var date = Date()
    var category: String? = nil
}

@MainActor final class PlayerStore: ObservableObject {
    @Published private(set) var notes: [LessonNote] = []
    @Published private(set) var records: [PracticeRecord] = []
    @Published private(set) var completedSessions = 0
    @Published private(set) var preferences = PlayerPreferences()
    @Published private(set) var draft: SessionDraft?
    @Published var persistenceError: String?
    private var container: ModelContainer?
    private var archive: PlayerArchive?

    init(container: ModelContainer? = nil, defaults: UserDefaults = .standard) {
        do {
            let resolved: ModelContainer
            if let container { resolved = container }
            else { resolved = try ModelContainer(for: PlayerArchive.self) }
            self.container = resolved
            let context = resolved.mainContext
            if let existing = try context.fetch(FetchDescriptor<PlayerArchive>()).first {
                notes = try JSONDecoder().decode([LessonNote].self, from: existing.notes)
                records = try JSONDecoder().decode([PracticeRecord].self, from: existing.records)
                completedSessions = existing.completedSessions
                if let data = existing.preferences { preferences = try JSONDecoder().decode(PlayerPreferences.self, from: data) }
                if let data = existing.sessionDraft { draft = try JSONDecoder().decode(SessionDraft.self, from: data) }
                archive = existing
            } else {
                // Keep the source defaults untouched so a failed migration can be retried.
                if let data = defaults.data(forKey: "notes") { notes = try JSONDecoder().decode([LessonNote].self, from: data) }
                if let data = defaults.data(forKey: "practiceRecords") { records = try JSONDecoder().decode([PracticeRecord].self, from: data) }
                completedSessions = max(defaults.integer(forKey: "sessions"), records.count)
                let initial = PlayerArchive(notes: try JSONEncoder().encode(notes), records: try JSONEncoder().encode(records), completedSessions: completedSessions)
                context.insert(initial)
                try context.save()
                archive = initial
            }
        } catch {
            persistenceError = L10n.text("Kayıtlarına erişilemedi. Verilerini silmeden uygulamayı yeniden açmayı dene.")
        }
    }

    @discardableResult func addNote(title: String, text: String, category: String) -> Bool {
        var updated = notes
        updated.insert(LessonNote(title: title, text: text, category: category), at: 0)
        return persist(notes: updated, records: records, count: completedSessions)
    }
    @discardableResult func updateNote(id: UUID, title: String, text: String, category: String) -> Bool {
        var updated = notes
        guard let index = updated.firstIndex(where: { $0.id == id }) else { return false }
        updated[index].title = title; updated[index].text = text; updated[index].category = category
        return persist(notes: updated, records: records, count: completedSessions)
    }
    @discardableResult func deleteNote(id: UUID) -> Bool {
        let saved = persist(notes: notes.filter { $0.id != id }, records: records, count: completedSessions)
        if saved { UserDefaults.standard.removeObject(forKey: NoteDraft.key(for: id)) }
        return saved
    }
    @discardableResult func completePractice(focus: String, seconds: Int, planID: String? = nil, result: Int? = nil, reflection: String? = nil, noteID: UUID? = nil, sessionID: UUID? = nil, benchmarkVersion: Int? = nil) -> Bool {
        if let sessionID, records.contains(where: { $0.id == sessionID }) { return true }
        var updated = records
        updated.insert(PracticeRecord(id: sessionID ?? UUID(), focus: focus, seconds: max(0, seconds), planID: planID, result: result, reflection: reflection, noteID: noteID, benchmarkVersion: benchmarkVersion), at: 0)
        return persist(notes: notes, records: updated, count: completedSessions + 1, clearDraft: true)
    }
    var activeNote: LessonNote? { notes.first { $0.id == preferences.activeNoteID } }
    var recommendation: PracticeRecommendation? { PracticeSelector.recommendation(for: preferences) }

    @discardableResult func savePreferences(_ value: PlayerPreferences) -> Bool {
        guard let context = container?.mainContext, let archive else { persistenceError = L10n.text("save.unavailable"); return false }
        do {
            archive.preferences = try JSONEncoder().encode(value)
            try context.save()
            preferences = value
            return true
        } catch { context.rollback(); persistenceError = L10n.text("save.failed"); return false }
    }
    @discardableResult func activateNote(_ note: LessonNote) -> Bool {
        var value = preferences
        value.activeNoteID = note.id
        value.focus = note.category ?? "Genel"
        value.configured = true
        return savePreferences(value)
    }
    @discardableResult func saveDraft(_ value: SessionDraft?) -> Bool {
        guard let context = container?.mainContext, let archive else { persistenceError = L10n.text("save.unavailable"); return false }
        do {
            archive.sessionDraft = try value.map { try JSONEncoder().encode($0) }
            try context.save()
            draft = value
            return true
        } catch { context.rollback(); persistenceError = L10n.text("save.failed"); return false }
    }
    private func persist(notes: [LessonNote], records: [PracticeRecord], count: Int, clearDraft: Bool = false) -> Bool {
        guard let context = container?.mainContext, let archive else {
            persistenceError = L10n.text("Kayıt alanı hazır değil. Değişikliğin kaydedilmedi; uygulamayı yeniden açmayı dene.")
            return false
        }
        do {
            archive.notes = try JSONEncoder().encode(notes)
            archive.records = try JSONEncoder().encode(records)
            archive.completedSessions = count
            if clearDraft { archive.sessionDraft = nil }
            try context.save()
            self.notes = notes; self.records = records; completedSessions = count
            if clearDraft { draft = nil }
            return true
        } catch {
            context.rollback()
            persistenceError = L10n.text("Değişikliğin kaydedilemedi. Tekrar deneyebilirsin.")
            return false
        }
    }
}
