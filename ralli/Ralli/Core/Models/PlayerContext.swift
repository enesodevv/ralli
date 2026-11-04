import Foundation

struct PlayerPreferences: Codable, Equatable {
    var focus = "Genel"
    var mode = "solo"
    var minutes = 20
    var hasWall = false
    var level = "foundation"
    var activeNoteID: UUID?
    var configured = false
    /// "left" or "right". Optional so preferences saved by older versions still decode.
    var handedness: String?
    var isLeftHanded: Bool { handedness == "left" }
}

struct SessionDraft: Codable, Equatable {
    var id = UUID()
    var planID: String
    var step: Int
    var remaining: TimeInterval
    var secondsSpent: Int
    var reviewing: Bool
    var includeResult: Bool
    var result: Int
    var reflection: String
    var noteID: UUID?
    var updatedAt = Date()
}

struct PracticeRecommendation {
    let plan: PracticePlan
    let matchesFocus: Bool
}

enum PracticeSelector {
    static func eligible(for preferences: PlayerPreferences) -> [PracticePlan] {
        PracticePlan.library.filter { plan in
            plan.mode == preferences.mode && plan.minutes <= preferences.minutes &&
            (plan.visual != "wall" || preferences.hasWall) &&
            (plan.minimumLevel == "foundation" || preferences.level == "developing")
        }
    }
    static func recommendation(for preferences: PlayerPreferences) -> PracticeRecommendation? {
        let candidates = eligible(for: preferences)
        guard let plan = candidates.first(where: { $0.focus == preferences.focus }) ?? candidates.first else { return nil }
        return PracticeRecommendation(plan: plan, matchesFocus: preferences.focus == "Genel" || plan.focus == preferences.focus)
    }
}

extension PracticePlan {
    var minimumLevel: String { ["backhand", "forehand", "return", "rally", "second_serve", "approach", "overhead"].contains(id) ? "developing" : "foundation" }
    var prerequisite: String { L10n.text("prerequisite." + (minimumLevel == "developing" ? "rally" : "basic")) }
    var benchmarkVersion: Int { 1 }
}

extension PracticeRecord {
    func isComparable(to other: PracticeRecord) -> Bool {
        guard let planID, let benchmarkVersion, result != nil, other.result != nil else { return false }
        return other.planID == planID && other.benchmarkVersion == benchmarkVersion
    }
}

struct PracticeComparison: Identifiable {
    let id: String
    let planID: String
    let records: [PracticeRecord]
    static func groups(from records: [PracticeRecord]) -> [PracticeComparison] {
        let usable = records.filter { $0.planID != nil && $0.benchmarkVersion != nil && $0.result != nil }
        let groups = Dictionary(grouping: usable) { "\($0.planID!):\($0.benchmarkVersion!)" }
        return groups.compactMap { key, values in
            guard values.count >= 2, let planID = values.first?.planID else { return nil }
            return PracticeComparison(id: key, planID: planID, records: values.sorted { $0.date < $1.date })
        }.sorted { ($0.records.last?.date ?? .distantPast) > ($1.records.last?.date ?? .distantPast) }
    }
}
