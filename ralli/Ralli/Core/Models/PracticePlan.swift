import Foundation

struct PracticePlan: Identifiable {
    struct Step {
        let title: String
        let instruction: String
        let minutes: Int
    }
    let id: String
    let focus: String
    let mode: String
    let visual: String
    let title: String
    let subtitle: String
    let goal: String
    let equipment: String
    let cue: String
    let mistake: String
    let metric: String
    let source: String
    let steps: [Step]
    var minutes: Int { steps.reduce(0) { $0 + $1.minutes } }
    var metricTitle: String { L10n.text("practice.metric." + metric) }
    var maximumScore: Int { metric == "hits" || metric == "toss" ? 10 : (metric == "rounds" ? 5 : 999) }
    var modeTitle: String { L10n.text("practice." + mode) }
    var symbol: String {
        switch visual {
        case "serve": return "scope"
        case "wall": return "rectangle.split.1x2"
        case "footwork": return "figure.walk"
        case "volley": return "hand.raised"
        case "return": return "arrow.uturn.backward"
        case "shadow": return "figure.tennis"
        case "split": return "arrow.left.and.right"
        case "approach": return "arrow.up.forward"
        case "overhead": return "arrow.up.circle"
        default: return "tennisball"
        }
    }
    static let library: [PracticePlan] = [
        PracticePlan(id: "backhand", focus: "Backhand", mode: "partner", visual: "crosscourt", title: L10n.text("backhand.title"), subtitle: L10n.text("backhand.subtitle"), goal: L10n.text("backhand.goal"), equipment: L10n.text("backhand.equipment"), cue: L10n.text("backhand.cue"), mistake: L10n.text("backhand.mistake"), metric: "rally", source: "https://www.usta.com/en/home/improve/tips-and-instruction.html", steps: [
            Step(title: L10n.text("bh.1.title"), instruction: L10n.text("bh.1.body"), minutes: 4),
            Step(title: L10n.text("bh.2.title"), instruction: L10n.text("bh.2.body"), minutes: 8),
            Step(title: L10n.text("bh.3.title"), instruction: L10n.text("bh.3.body"), minutes: 4)
        ]),
        PracticePlan(id: "forehand", focus: "Forehand", mode: "partner", visual: "depth", title: L10n.text("forehand.title"), subtitle: L10n.text("forehand.subtitle"), goal: L10n.text("forehand.goal"), equipment: L10n.text("forehand.equipment"), cue: L10n.text("forehand.cue"), mistake: L10n.text("forehand.mistake"), metric: "hits", source: "https://www.usta.com/en/home/improve/tips-and-instruction/national/improve-your-tennis-game--target-practice.html", steps: [
            Step(title: L10n.text("fh.1.title"), instruction: L10n.text("fh.1.body"), minutes: 4),
            Step(title: L10n.text("fh.2.title"), instruction: L10n.text("fh.2.body"), minutes: 10),
            Step(title: L10n.text("fh.3.title"), instruction: L10n.text("fh.3.body"), minutes: 4)
        ]),
        PracticePlan(id: "serve", focus: "Servis", mode: "solo", visual: "serve", title: L10n.text("serve.title"), subtitle: L10n.text("serve.subtitle"), goal: L10n.text("serve.goal"), equipment: L10n.text("serve.equipment"), cue: L10n.text("serve.cue"), mistake: L10n.text("serve.mistake"), metric: "hits", source: "https://www.lta.org.uk/advantage-home/content/how-to-train-and-practice-tennis-skills-by-yourself/", steps: [
            Step(title: L10n.text("sv.1.title"), instruction: L10n.text("sv.1.body"), minutes: 4),
            Step(title: L10n.text("sv.2.title"), instruction: L10n.text("sv.2.body"), minutes: 8),
            Step(title: L10n.text("sv.3.title"), instruction: L10n.text("sv.3.body"), minutes: 4)
        ]),
        PracticePlan(id: "wall", focus: "Genel", mode: "solo", visual: "wall", title: L10n.text("wall.title"), subtitle: L10n.text("wall.subtitle"), goal: L10n.text("wall.goal"), equipment: L10n.text("wall.equipment"), cue: L10n.text("wall.cue"), mistake: L10n.text("wall.mistake"), metric: "rally", source: "https://www.lta.org.uk/play/tennis-at-home/at-home-tennis-drills/", steps: [
            Step(title: L10n.text("wl.1.title"), instruction: L10n.text("wl.1.body"), minutes: 3),
            Step(title: L10n.text("wl.2.title"), instruction: L10n.text("wl.2.body"), minutes: 6),
            Step(title: L10n.text("wl.3.title"), instruction: L10n.text("wl.3.body"), minutes: 3)
        ]),
        PracticePlan(id: "return", focus: "Karşılama", mode: "partner", visual: "return", title: L10n.text("return.title"), subtitle: L10n.text("return.subtitle"), goal: L10n.text("return.goal"), equipment: L10n.text("return.equipment"), cue: L10n.text("return.cue"), mistake: L10n.text("return.mistake"), metric: "hits", source: "https://www4.lta.org.uk/play-compete/getting-started/tennis-coaching-tips/drills-to-improve-technique/", steps: [
            Step(title: L10n.text("rt.1.title"), instruction: L10n.text("rt.1.body"), minutes: 4),
            Step(title: L10n.text("rt.2.title"), instruction: L10n.text("rt.2.body"), minutes: 8),
            Step(title: L10n.text("rt.3.title"), instruction: L10n.text("rt.3.body"), minutes: 4)
        ]),
        PracticePlan(id: "volley", focus: "Vole", mode: "partner", visual: "volley", title: L10n.text("volley.title"), subtitle: L10n.text("volley.subtitle"), goal: L10n.text("volley.goal"), equipment: L10n.text("volley.equipment"), cue: L10n.text("volley.cue"), mistake: L10n.text("volley.mistake"), metric: "hits", source: "https://www.lta.org.uk/play/tennis-at-home/at-home-tennis-drills/", steps: [
            Step(title: L10n.text("vo.1.title"), instruction: L10n.text("vo.1.body"), minutes: 3),
            Step(title: L10n.text("vo.2.title"), instruction: L10n.text("vo.2.body"), minutes: 6),
            Step(title: L10n.text("vo.3.title"), instruction: L10n.text("vo.3.body"), minutes: 3)
        ]),
        PracticePlan(id: "rally", focus: "Genel", mode: "partner", visual: "crosscourt", title: L10n.text("rally.title"), subtitle: L10n.text("rally.subtitle"), goal: L10n.text("rally.goal"), equipment: L10n.text("rally.equipment"), cue: L10n.text("rally.cue"), mistake: L10n.text("rally.mistake"), metric: "rally", source: "https://www.lta.org.uk/play/tennis-tips-and-techniques/tennis-drills-to-help-build-consistency-in-your-game/", steps: [
            Step(title: L10n.text("ra.1.title"), instruction: L10n.text("ra.1.body"), minutes: 3),
            Step(title: L10n.text("ra.2.title"), instruction: L10n.text("ra.2.body"), minutes: 8),
            Step(title: L10n.text("ra.3.title"), instruction: L10n.text("ra.3.body"), minutes: 4)
        ]),
        PracticePlan(id: "footwork", focus: "Ayak çalışması", mode: "solo", visual: "footwork", title: L10n.text("footwork.title"), subtitle: L10n.text("footwork.subtitle"), goal: L10n.text("footwork.goal"), equipment: L10n.text("footwork.equipment"), cue: L10n.text("footwork.cue"), mistake: L10n.text("footwork.mistake"), metric: "rounds", source: "https://www.lta.org.uk/play/tennis-tips-and-techniques/improve-your-tennis-footwork-on-court-with-these-simple-tips/", steps: [
            Step(title: L10n.text("ft.1.title"), instruction: L10n.text("ft.1.body"), minutes: 2),
            Step(title: L10n.text("ft.2.title"), instruction: L10n.text("ft.2.body"), minutes: 5),
            Step(title: L10n.text("ft.3.title"), instruction: L10n.text("ft.3.body"), minutes: 3)
        ]),
        keyed("shadow", focus: "Genel", mode: "solo", visual: "shadow", metric: "rounds", source: "https://www.lta.org.uk/advantage-home/content/how-to-train-and-practice-tennis-skills-by-yourself/", minutes: [3, 6, 3]),
        keyed("dropfeed_fh", focus: "Forehand", mode: "solo", visual: "depth", metric: "hits", source: "https://www.lta.org.uk/advantage-home/content/how-to-train-and-practice-tennis-skills-by-yourself/", minutes: [3, 9, 3]),
        keyed("dropfeed_bh", focus: "Backhand", mode: "solo", visual: "crosscourt", metric: "hits", source: "https://www.lta.org.uk/advantage-home/content/how-to-train-and-practice-tennis-skills-by-yourself/", minutes: [3, 9, 3]),
        keyed("toss", focus: "Servis", mode: "solo", visual: "serve", metric: "toss", source: "https://www.lta.org.uk/advantage-home/content/how-to-train-and-practice-tennis-skills-by-yourself/", minutes: [2, 6, 2]),
        keyed("second_serve", focus: "Servis", mode: "solo", visual: "serve", metric: "hits", source: "https://www.lta.org.uk/advantage-home/content/how-to-train-and-practice-tennis-skills-by-yourself/", minutes: [3, 10, 3]),
        keyed("wall_volley", focus: "Vole", mode: "solo", visual: "wall", metric: "rally", source: "https://www.lta.org.uk/play/tennis-at-home/at-home-tennis-drills/", minutes: [2, 6, 2]),
        keyed("split", focus: "Ayak çalışması", mode: "solo", visual: "split", metric: "rounds", source: "https://www.lta.org.uk/play/tennis-tips-and-techniques/improve-your-tennis-footwork-on-court-with-these-simple-tips/", minutes: [2, 6, 2]),
        keyed("approach", focus: "Vole", mode: "partner", visual: "approach", metric: "hits", source: "https://www.lta.org.uk/play/tennis-tips-and-techniques/tennis-drills-to-help-build-consistency-in-your-game/", minutes: [3, 9, 4]),
        keyed("overhead", focus: "Vole", mode: "partner", visual: "overhead", metric: "hits", source: "https://www.lta.org.uk/play/tennis-tips-and-techniques/tennis-drills-to-help-build-consistency-in-your-game/", minutes: [3, 8, 4]),
    ]
    /// Newer drills keep every text under "<id>.<field>" and "<id>.<step>.title/body".
    private static func keyed(_ id: String, focus: String, mode: String, visual: String, metric: String, source: String, minutes: [Int]) -> PracticePlan {
        PracticePlan(id: id, focus: focus, mode: mode, visual: visual, title: L10n.text(id + ".title"), subtitle: L10n.text(id + ".subtitle"),
                     goal: L10n.text(id + ".goal"), equipment: L10n.text(id + ".equipment"), cue: L10n.text(id + ".cue"), mistake: L10n.text(id + ".mistake"),
                     metric: metric, source: source,
                     steps: minutes.enumerated().map { Step(title: L10n.text("\(id).\($0.offset + 1).title"), instruction: L10n.text("\(id).\($0.offset + 1).body"), minutes: $0.element) })
    }
}
struct PracticeRecord: Identifiable, Codable {
    var id = UUID()
    var date = Date()
    let focus: String
    let seconds: Int
    var planID: String? = nil
    var result: Int? = nil
    var reflection: String? = nil
    var noteID: UUID? = nil
    var benchmarkVersion: Int? = nil
}
