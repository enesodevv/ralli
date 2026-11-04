import Foundation

struct CourtPosition: Equatable {
    let x: Double
    let y: Double
}

enum CourtPattern {
    static func route(for pattern: String) -> [CourtPosition] {
        let points: [(Double, Double)]
        switch pattern {
        case "serve": points = [(0.42,0.89),(0.70,0.39)]
        case "wall": points = [(0.30,0.82),(0.50,0.15),(0.65,0.82)]
        case "footwork":
            points = [(0.5,0.93),(0.23,0.93),(0.5,0.93),(0.23,0.71),(0.5,0.93),(0.5,0.71),(0.5,0.93),(0.77,0.71),(0.5,0.93),(0.77,0.93),(0.5,0.93)]
        case "volley": points = [(0.50,0.30),(0.50,0.59),(0.50,0.30)]
        case "return": points = [(0.70,0.10),(0.30,0.65),(0.30,0.89),(0.65,0.18)]
        case "shadow": points = [(0.50,0.90),(0.30,0.90),(0.50,0.90),(0.70,0.90),(0.50,0.90)]
        case "split": points = [(0.50,0.84),(0.30,0.84),(0.50,0.84),(0.70,0.84),(0.50,0.84)]
        case "approach": points = [(0.45,0.92),(0.45,0.66),(0.30,0.16),(0.50,0.58)]
        case "overhead": points = [(0.50,0.12),(0.48,0.66),(0.35,0.20)]
        case "depth": points = [(0.30,0.89),(0.65,0.18),(0.30,0.89)]
        default: points = [(0.30,0.89),(0.70,0.18),(0.30,0.89)]
        }
        return points.map { CourtPosition(x: $0.0, y: $0.1) }
    }
    static func position(on route: [CourtPosition], progress: Double) -> CourtPosition {
        guard let first = route.first else { return CourtPosition(x: 0.5, y: 0.5) }
        guard route.count > 1 else { return first }
        let phase = progress.isFinite ? min(1, max(0, progress)) : 0
        guard phase > 0 else { return first }
        guard phase < 1 else { return route.last ?? first }
        let lengths = zip(route, route.dropFirst()).map { hypot($1.x - $0.x, $1.y - $0.y) }
        let total = lengths.reduce(0, +)
        guard total > 0 else { return first }
        var distance = phase * total
        for index in lengths.indices {
            let length = lengths[index]
            if distance <= length && length > 0 {
                let fraction = distance / length
                return CourtPosition(x: route[index].x + (route[index+1].x - route[index].x) * fraction,
                                     y: route[index].y + (route[index+1].y - route[index].y) * fraction)
            }
            distance -= length
        }
        return route.last ?? first
    }
}

extension PracticePlan {
    var coachingURL: URL? {
        let root = "https://www.lta.org.uk/"
        let path: String
        switch id {
        case "backhand": path = "play/tennis-tips-and-techniques/how-to-hit-a-tennis-backhand/"
        case "forehand": path = "play/tennis-tips-and-techniques/how-to-play-a-tennis-forehand/"
        case "serve": path = "advantage-home/content/how-to-practice-your-serve-without-a-partner/"
        case "return": path = "play/tennis-tips-and-techniques/simple-steps-to-improve-your-return-of-serve/"
        case "volley": path = "play/tennis-tips-and-techniques/how-to-improve-your-tennis-volleys/"
        case "rally": path = "play/tennis-tips-and-techniques/how-to-play-better-tennis-rallies/"
        case "approach", "wall_volley": path = "play/tennis-tips-and-techniques/how-to-improve-your-tennis-volleys/"
        case "second_serve", "toss": path = "advantage-home/content/how-to-practice-your-serve-without-a-partner/"
        default: return URL(string: source)
        }
        return URL(string: root + path)
    }
}
