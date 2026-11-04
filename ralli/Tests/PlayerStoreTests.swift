import XCTest
import SwiftData

@MainActor final class PlayerStoreTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(for: PlayerArchive.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }
    private func defaults() -> UserDefaults {
        UserDefaults(suiteName: "RalliTests.\(UUID().uuidString)")!
    }
    func testLegacyMigrationAndNoDuplicateImport() throws {
        let defaults = defaults()
        let old = LessonNote(title: "Eski not", text: "Erken hazırlan")
        defaults.set(try JSONEncoder().encode([old]), forKey: "notes")
        defaults.set(7, forKey: "sessions")
        let legacyRecord = Data("[{\"id\":\"6AF5DA72-06DF-4EE5-9D70-A444364B4D61\",\"date\":0,\"focus\":\"Servis\",\"seconds\":60}]".utf8)
        defaults.set(legacyRecord, forKey: "practiceRecords")
        let container = try makeContainer()
        let first = PlayerStore(container: container, defaults: defaults)
        XCTAssertNil(first.persistenceError)
        XCTAssertEqual(first.notes.first?.id, old.id)
        XCTAssertNil(first.notes.first?.category)
        XCTAssertEqual(first.completedSessions, 7)
        XCTAssertEqual(first.records.count, 1)
        XCTAssertNil(first.records.first?.planID)
        XCTAssertNil(first.records.first?.result)
        XCTAssertTrue(first.addNote(title: "Yeni", text: "Denge", category: "Servis"))
        let reopened = PlayerStore(container: container, defaults: defaults)
        XCTAssertEqual(reopened.notes.count, 2)
        XCTAssertEqual(reopened.completedSessions, 7)
        XCTAssertNotNil(defaults.data(forKey: "notes"))
    }
    func testUpdateDeleteAndSessionSurviveStoreRecreation() throws {
        let container = try makeContainer()
        let defaults = defaults()
        let first = PlayerStore(container: container, defaults: defaults)
        XCTAssertTrue(first.addNote(title: "İlk", text: "Metin", category: "Genel"))
        let id = try XCTUnwrap(first.notes.first?.id)
        XCTAssertTrue(first.updateNote(id: id, title: "Düzeltildi", text: "Yeni metin", category: "Backhand"))
        XCTAssertTrue(first.completePractice(focus: "Backhand", seconds: 75, planID: "backhand", result: 12, reflection: "Rahat tempo"))
        let reopened = PlayerStore(container: container, defaults: defaults)
        XCTAssertEqual(reopened.notes.first?.title, "Düzeltildi")
        XCTAssertEqual(reopened.notes.first?.category, "Backhand")
        XCTAssertEqual(reopened.records.first?.seconds, 75)
        XCTAssertEqual(reopened.records.first?.planID, "backhand")
        XCTAssertEqual(reopened.records.first?.result, 12)
        XCTAssertEqual(reopened.records.first?.reflection, "Rahat tempo")
        XCTAssertEqual(reopened.completedSessions, 1)
        XCTAssertTrue(reopened.deleteNote(id: id))
        XCTAssertTrue(PlayerStore(container: container, defaults: defaults).notes.isEmpty)
    }
    func testCorruptLegacyDataIsNotSilentlyOverwritten() throws {
        let defaults = defaults()
        let corrupt = Data("invalid".utf8)
        defaults.set(corrupt, forKey: "notes")
        let store = PlayerStore(container: try makeContainer(), defaults: defaults)
        XCTAssertNotNil(store.persistenceError)
        XCTAssertFalse(store.addNote(title: "A", text: "B", category: "Genel"))
        XCTAssertEqual(defaults.data(forKey: "notes"), corrupt)
    }
    func testPreferencesAndLinkedCueSurviveReopening() throws {
        let container = try makeContainer()
        let defaults = defaults()
        let store = PlayerStore(container: container, defaults: defaults)
        XCTAssertTrue(store.addNote(title: "My cue", text: "Choose the target first", category: "Servis"))
        let note = try XCTUnwrap(store.notes.first)
        XCTAssertTrue(store.activateNote(note))
        var preferences = store.preferences
        preferences.mode = "solo"; preferences.minutes = 20; preferences.level = "foundation"
        XCTAssertTrue(store.savePreferences(preferences))
        let reopened = PlayerStore(container: container, defaults: defaults)
        XCTAssertEqual(reopened.activeNote?.id, note.id)
        XCTAssertEqual(reopened.preferences.focus, "Servis")
        XCTAssertEqual(reopened.recommendation?.plan.id, "serve")
    }
    func testRecommendationNeverRequiresUnavailableSetup() {
        var preferences = PlayerPreferences()
        preferences.mode = "solo"; preferences.hasWall = false; preferences.minutes = 15
        let candidates = PracticeSelector.eligible(for: preferences)
        XCTAssertTrue(candidates.allSatisfy { $0.mode == "solo" && $0.visual != "wall" && $0.minutes <= 15 })
        preferences.minutes = 5
        XCTAssertNil(PracticeSelector.recommendation(for: preferences))
        preferences.minutes = 20; preferences.mode = "partner"; preferences.level = "foundation"
        XCTAssertTrue(PracticeSelector.eligible(for: preferences).allSatisfy { $0.minimumLevel == "foundation" })
    }
    func testDraftRecoveryAndAtomicCompletionAreIdempotent() throws {
        let container = try makeContainer()
        let defaults = defaults()
        let store = PlayerStore(container: container, defaults: defaults)
        let draft = SessionDraft(planID: "serve", step: 1, remaining: 90, secondsSpent: 120,
            reviewing: false, includeResult: false, result: 0, reflection: "Remember", noteID: nil)
        XCTAssertTrue(store.saveDraft(draft))
        let reopened = PlayerStore(container: container, defaults: defaults)
        XCTAssertEqual(reopened.draft, draft)
        XCTAssertTrue(reopened.completePractice(focus: "Servis", seconds: 120, planID: "serve", result: 0, sessionID: draft.id, benchmarkVersion: 1))
        let completed = PlayerStore(container: container, defaults: defaults)
        XCTAssertNil(completed.draft)
        XCTAssertEqual(completed.records.first?.result, 0)
        XCTAssertTrue(completed.completePractice(focus: "Servis", seconds: 120, sessionID: draft.id))
        XCTAssertEqual(completed.records.count, 1)
        XCTAssertEqual(completed.completedSessions, 1)
    }
    func testComparisonRejectsDifferentTestsAndUnmeasuredRecords() {
        let first = PracticeRecord(focus: "Servis", seconds: 100, planID: "serve", result: 4, benchmarkVersion: 1)
        let second = PracticeRecord(focus: "Servis", seconds: 100, planID: "serve", result: 6, benchmarkVersion: 1)
        let different = PracticeRecord(focus: "Servis", seconds: 100, planID: "serve", result: 8, benchmarkVersion: 2)
        let missing = PracticeRecord(focus: "Servis", seconds: 100, planID: "serve", benchmarkVersion: 1)
        let legacy = PracticeRecord(focus: "Servis", seconds: 100, planID: "serve", result: 7)
        let groups = PracticeComparison.groups(from: [first, second, different, missing, legacy])
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.records.count, 2)
        XCTAssertTrue(first.isComparable(to: second))
        XCTAssertFalse(first.isComparable(to: different))
        XCTAssertFalse(first.isComparable(to: legacy))
    }

}
