import Foundation

/// A schematic, side-view figure (facing right, towards the net) described by key poses.
/// Coordinates are normalised to a 0...1 square, y grows downwards.
/// The app tweens between poses; this shows the order of a movement, not a full technique model.
struct MotionPoint: Equatable {
    var x: Double
    var y: Double
    init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
    func mix(_ other: MotionPoint, _ t: Double) -> MotionPoint { MotionPoint(x + (other.x - x) * t, y + (other.y - y) * t) }
    var isInsideFrame: Bool { (0...1).contains(x) && (0...1).contains(y) }
}

struct MotionPose: Equatable {
    var head, neck, hip: MotionPoint
    var frontKnee, frontFoot, backKnee, backFoot: MotionPoint
    var hittingElbow, hittingHand, freeElbow, freeHand: MotionPoint
    /// Racket direction from the hitting hand, in degrees (0 = right, 90 = down).
    var racketAngle: Double
    var ball: MotionPoint? = nil
    static let racketLength = 0.15

    var racketTip: MotionPoint {
        let radians = racketAngle * .pi / 180
        return MotionPoint(hittingHand.x + cos(radians) * Self.racketLength, hittingHand.y + sin(radians) * Self.racketLength)
    }
    var allPoints: [MotionPoint] {
        [head, neck, hip, frontKnee, frontFoot, backKnee, backFoot, hittingElbow, hittingHand, freeElbow, freeHand, racketTip] + (ball.map { [$0] } ?? [])
    }
    func mix(_ other: MotionPose, _ t: Double) -> MotionPose {
        // Turn the racket the short way round.
        var delta = (other.racketAngle - racketAngle).truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 } else if delta < -180 { delta += 360 }
        var ball: MotionPoint?
        switch (self.ball, other.ball) {
        case let (a?, b?): ball = a.mix(b, t)
        case let (a?, nil): ball = t < 0.35 ? a : nil
        case let (nil, b?): ball = t > 0.65 ? b : nil
        default: ball = nil
        }
        return MotionPose(head: head.mix(other.head, t), neck: neck.mix(other.neck, t), hip: hip.mix(other.hip, t),
                          frontKnee: frontKnee.mix(other.frontKnee, t), frontFoot: frontFoot.mix(other.frontFoot, t),
                          backKnee: backKnee.mix(other.backKnee, t), backFoot: backFoot.mix(other.backFoot, t),
                          hittingElbow: hittingElbow.mix(other.hittingElbow, t), hittingHand: hittingHand.mix(other.hittingHand, t),
                          freeElbow: freeElbow.mix(other.freeElbow, t), freeHand: freeHand.mix(other.freeHand, t),
                          racketAngle: racketAngle + delta * t, ball: ball)
    }
    /// Copy with only the named changes, so key poses stay short and readable.
    func with(_ change: (inout MotionPose) -> Void) -> MotionPose { var copy = self; change(&copy); return copy }
}

struct MotionKeyframe: Equatable {
    /// Localisation key of the phase name, e.g. "motion.phase.contact".
    let phase: String
    let pose: MotionPose
}

struct StrokeMotion: Identifiable, Equatable {
    let id: String
    /// Key frames of one cycle. The last frame equals the first so the loop is seamless.
    let keyframes: [MotionKeyframe]
    var titleKey: String { "motion.title." + id }
    var segmentCount: Int { max(1, keyframes.count - 1) }

    /// Pose at `progress` (0...1 over one cycle). Each segment holds briefly on its key pose, then eases into the next.
    func pose(at progress: Double) -> MotionPose {
        guard let first = keyframes.first else { return StrokeMotion.ready }
        guard keyframes.count > 1 else { return first.pose }
        let value = progress.isFinite ? progress - progress.rounded(.down) : 0
        let scaled = value * Double(segmentCount)
        let index = min(segmentCount - 1, Int(scaled))
        let local = scaled - Double(index)
        let moving = max(0, (local - 0.22) / 0.78)
        let eased = moving * moving * (3 - 2 * moving)
        return keyframes[index].pose.mix(keyframes[index + 1].pose, eased)
    }
    /// Index of the key frame the figure is at or moving away from.
    func phaseIndex(at progress: Double) -> Int {
        guard keyframes.count > 1 else { return 0 }
        let value = progress.isFinite ? progress - progress.rounded(.down) : 0
        let scaled = value * Double(segmentCount)
        let index = min(segmentCount - 1, Int(scaled))
        return scaled - Double(index) > 0.6 ? index + 1 : index
    }
}

extension StrokeMotion {
    // MARK: Base poses
    static let ready = MotionPose(
        head: .init(0.52, 0.32), neck: .init(0.51, 0.40), hip: .init(0.49, 0.64),
        frontKnee: .init(0.56, 0.79), frontFoot: .init(0.60, 0.95), backKnee: .init(0.43, 0.79), backFoot: .init(0.40, 0.95),
        hittingElbow: .init(0.55, 0.50), hittingHand: .init(0.59, 0.55), freeElbow: .init(0.54, 0.50), freeHand: .init(0.59, 0.54),
        racketAngle: -15)
    static let tall = ready.with {
        $0.head = .init(0.50, 0.30); $0.neck = .init(0.50, 0.38); $0.hip = .init(0.50, 0.62)
        $0.frontKnee = .init(0.55, 0.78); $0.backKnee = .init(0.45, 0.78); $0.frontFoot = .init(0.58, 0.95); $0.backFoot = .init(0.42, 0.95)
        $0.hittingElbow = .init(0.54, 0.48); $0.hittingHand = .init(0.57, 0.56); $0.freeElbow = .init(0.55, 0.49); $0.freeHand = .init(0.60, 0.56)
        $0.racketAngle = -20
    }
    private static let overheadContact = tall.with {
        $0.hip = .init(0.52, 0.60); $0.neck = .init(0.53, 0.37); $0.head = .init(0.54, 0.29)
        $0.frontKnee = .init(0.56, 0.77); $0.backKnee = .init(0.46, 0.77)
        $0.hittingElbow = .init(0.57, 0.25); $0.hittingHand = .init(0.60, 0.17); $0.racketAngle = -75
        $0.freeElbow = .init(0.53, 0.42); $0.freeHand = .init(0.55, 0.47)
        $0.ball = .init(0.65, 0.03)
    }
    private static let overheadFinish = tall.with {
        $0.hip = .init(0.54, 0.63); $0.neck = .init(0.57, 0.41); $0.head = .init(0.59, 0.34)
        $0.backFoot = .init(0.52, 0.95); $0.backKnee = .init(0.52, 0.79)
        $0.hittingElbow = .init(0.55, 0.52); $0.hittingHand = .init(0.48, 0.66); $0.racketAngle = 140
        $0.freeElbow = .init(0.58, 0.48); $0.freeHand = .init(0.56, 0.53)
    }

    // MARK: Strokes
    static let forehand = StrokeMotion(id: "forehand", keyframes: [
        .init(phase: "motion.phase.ready", pose: ready),
        .init(phase: "motion.phase.takeback", pose: ready.with {
            $0.neck = .init(0.49, 0.40); $0.head = .init(0.50, 0.32)
            $0.hittingElbow = .init(0.42, 0.46); $0.hittingHand = .init(0.38, 0.52); $0.racketAngle = -140
            $0.freeElbow = .init(0.58, 0.44); $0.freeHand = .init(0.66, 0.46)
        }),
        .init(phase: "motion.phase.drop", pose: ready.with {
            $0.neck = .init(0.49, 0.40); $0.head = .init(0.50, 0.32)
            $0.hittingElbow = .init(0.43, 0.52); $0.hittingHand = .init(0.38, 0.60); $0.racketAngle = 170
            $0.freeElbow = .init(0.57, 0.45); $0.freeHand = .init(0.63, 0.48)
            $0.ball = .init(0.92, 0.50)
        }),
        .init(phase: "motion.phase.contact", pose: ready.with {
            $0.neck = .init(0.53, 0.40); $0.head = .init(0.54, 0.32); $0.hip = .init(0.51, 0.64)
            $0.hittingElbow = .init(0.56, 0.50); $0.hittingHand = .init(0.64, 0.58); $0.racketAngle = -5
            $0.freeElbow = .init(0.52, 0.48); $0.freeHand = .init(0.55, 0.54)
            $0.ball = .init(0.80, 0.56)
        }),
        .init(phase: "motion.phase.finish", pose: ready.with {
            $0.neck = .init(0.53, 0.40); $0.head = .init(0.54, 0.32); $0.hip = .init(0.51, 0.64)
            $0.hittingElbow = .init(0.56, 0.40); $0.hittingHand = .init(0.46, 0.34); $0.racketAngle = -150
            $0.freeElbow = .init(0.53, 0.46); $0.freeHand = .init(0.49, 0.42)
        }),
        .init(phase: "motion.phase.recover", pose: ready),
    ])
    static let backhand = StrokeMotion(id: "backhand", keyframes: [
        .init(phase: "motion.phase.ready", pose: ready),
        .init(phase: "motion.phase.takeback", pose: ready.with {
            $0.neck = .init(0.49, 0.40); $0.head = .init(0.50, 0.32)
            $0.hittingElbow = .init(0.44, 0.50); $0.hittingHand = .init(0.40, 0.56)
            $0.freeElbow = .init(0.45, 0.52); $0.freeHand = .init(0.41, 0.57); $0.racketAngle = -150
        }),
        .init(phase: "motion.phase.contact", pose: ready.with {
            $0.neck = .init(0.53, 0.40); $0.head = .init(0.54, 0.32); $0.hip = .init(0.51, 0.64)
            $0.hittingElbow = .init(0.56, 0.52); $0.hittingHand = .init(0.63, 0.60)
            $0.freeElbow = .init(0.57, 0.54); $0.freeHand = .init(0.64, 0.61); $0.racketAngle = 0
            $0.ball = .init(0.79, 0.60)
        }),
        .init(phase: "motion.phase.finish", pose: ready.with {
            $0.neck = .init(0.53, 0.40); $0.head = .init(0.54, 0.32); $0.hip = .init(0.51, 0.64)
            $0.hittingElbow = .init(0.58, 0.44); $0.hittingHand = .init(0.60, 0.36)
            $0.freeElbow = .init(0.59, 0.45); $0.freeHand = .init(0.61, 0.37); $0.racketAngle = -130
        }),
        .init(phase: "motion.phase.recover", pose: ready),
    ])
    static let serve = StrokeMotion(id: "serve", keyframes: [
        .init(phase: "motion.phase.stance", pose: tall.with { $0.ball = .init(0.61, 0.55) }),
        .init(phase: "motion.phase.trophy", pose: tall.with {
            $0.hip = .init(0.50, 0.65); $0.neck = .init(0.49, 0.41); $0.head = .init(0.49, 0.33)
            $0.frontKnee = .init(0.55, 0.80); $0.backKnee = .init(0.45, 0.80)
            $0.freeElbow = .init(0.56, 0.25); $0.freeHand = .init(0.60, 0.13)
            $0.hittingElbow = .init(0.40, 0.40); $0.hittingHand = .init(0.42, 0.30); $0.racketAngle = -95
            $0.ball = .init(0.63, 0.06)
        }),
        .init(phase: "motion.phase.racketdrop", pose: tall.with {
            $0.hip = .init(0.50, 0.65); $0.neck = .init(0.50, 0.41); $0.head = .init(0.50, 0.33)
            $0.frontKnee = .init(0.55, 0.80); $0.backKnee = .init(0.45, 0.80)
            $0.freeElbow = .init(0.56, 0.30); $0.freeHand = .init(0.58, 0.22)
            $0.hittingElbow = .init(0.42, 0.36); $0.hittingHand = .init(0.44, 0.44); $0.racketAngle = 95
            $0.ball = .init(0.64, 0.04)
        }),
        .init(phase: "motion.phase.contact", pose: overheadContact),
        .init(phase: "motion.phase.finish", pose: overheadFinish),
        .init(phase: "motion.phase.recover", pose: tall),
    ])
    static let volley = StrokeMotion(id: "volley", keyframes: [
        .init(phase: "motion.phase.ready", pose: ready.with {
            $0.hittingElbow = .init(0.56, 0.48); $0.hittingHand = .init(0.60, 0.50); $0.freeElbow = .init(0.55, 0.48); $0.freeHand = .init(0.60, 0.50)
            $0.racketAngle = -40
        }),
        .init(phase: "motion.phase.turn", pose: ready.with {
            $0.hittingElbow = .init(0.52, 0.46); $0.hittingHand = .init(0.53, 0.44); $0.racketAngle = -70
            $0.freeElbow = .init(0.57, 0.46); $0.freeHand = .init(0.62, 0.46)
            $0.ball = .init(0.92, 0.42)
        }),
        .init(phase: "motion.phase.punch", pose: ready.with {
            $0.neck = .init(0.54, 0.40); $0.head = .init(0.55, 0.32); $0.hip = .init(0.52, 0.64)
            $0.frontKnee = .init(0.61, 0.79); $0.frontFoot = .init(0.66, 0.95)
            $0.hittingElbow = .init(0.58, 0.46); $0.hittingHand = .init(0.65, 0.48); $0.racketAngle = -55
            $0.freeElbow = .init(0.56, 0.46); $0.freeHand = .init(0.60, 0.48)
            $0.ball = .init(0.73, 0.37)
        }),
        .init(phase: "motion.phase.recover", pose: ready.with {
            $0.hittingElbow = .init(0.56, 0.48); $0.hittingHand = .init(0.60, 0.50); $0.freeElbow = .init(0.55, 0.48); $0.freeHand = .init(0.60, 0.50)
            $0.racketAngle = -40
        }),
    ])
    static let overhead = StrokeMotion(id: "overhead", keyframes: [
        .init(phase: "motion.phase.ready", pose: ready),
        .init(phase: "motion.phase.point", pose: tall.with {
            $0.hip = .init(0.47, 0.63); $0.neck = .init(0.47, 0.40); $0.head = .init(0.47, 0.32)
            $0.frontFoot = .init(0.55, 0.95); $0.backFoot = .init(0.37, 0.95); $0.frontKnee = .init(0.52, 0.79); $0.backKnee = .init(0.41, 0.79)
            $0.freeElbow = .init(0.55, 0.30); $0.freeHand = .init(0.62, 0.22)
            $0.hittingElbow = .init(0.39, 0.40); $0.hittingHand = .init(0.41, 0.30); $0.racketAngle = -95
            $0.ball = .init(0.70, 0.08)
        }),
        .init(phase: "motion.phase.contact", pose: overheadContact),
        .init(phase: "motion.phase.finish", pose: overheadFinish.with { $0.backFoot = .init(0.42, 0.95); $0.backKnee = .init(0.46, 0.79) }),
        .init(phase: "motion.phase.recover", pose: ready),
    ])
    static let split = StrokeMotion(id: "split", keyframes: [
        .init(phase: "motion.phase.ready", pose: ready),
        .init(phase: "motion.phase.hop", pose: ready.with {
            $0.head = .init(0.52, 0.28); $0.neck = .init(0.51, 0.36); $0.hip = .init(0.50, 0.60)
            $0.frontKnee = .init(0.55, 0.75); $0.backKnee = .init(0.45, 0.75); $0.frontFoot = .init(0.57, 0.89); $0.backFoot = .init(0.43, 0.89)
            $0.hittingElbow = .init(0.55, 0.46); $0.hittingHand = .init(0.59, 0.51); $0.freeElbow = .init(0.54, 0.46); $0.freeHand = .init(0.59, 0.50)
        }),
        .init(phase: "motion.phase.land", pose: ready.with {
            $0.head = .init(0.51, 0.36); $0.neck = .init(0.50, 0.44); $0.hip = .init(0.50, 0.68)
            $0.frontKnee = .init(0.60, 0.80); $0.backKnee = .init(0.40, 0.80); $0.frontFoot = .init(0.65, 0.95); $0.backFoot = .init(0.35, 0.95)
            $0.hittingElbow = .init(0.55, 0.54); $0.hittingHand = .init(0.59, 0.59); $0.freeElbow = .init(0.54, 0.54); $0.freeHand = .init(0.59, 0.58)
        }),
        .init(phase: "motion.phase.firststep", pose: ready.with {
            $0.head = .init(0.60, 0.34); $0.neck = .init(0.58, 0.42); $0.hip = .init(0.56, 0.66)
            $0.frontKnee = .init(0.68, 0.80); $0.frontFoot = .init(0.76, 0.95); $0.backKnee = .init(0.49, 0.80); $0.backFoot = .init(0.45, 0.95)
            $0.hittingElbow = .init(0.63, 0.52); $0.hittingHand = .init(0.67, 0.57); $0.freeElbow = .init(0.62, 0.52); $0.freeHand = .init(0.67, 0.56)
        }),
        .init(phase: "motion.phase.recover", pose: ready),
    ])

    static let all: [StrokeMotion] = [forehand, backhand, serve, volley, overhead, split]
}

extension PracticePlan {
    /// The stroke figure that best illustrates this drill.
    var strokeMotion: StrokeMotion {
        if id == "overhead" { return .overhead }
        switch focus {
        case "Backhand": return .backhand
        case "Servis": return .serve
        case "Vole": return .volley
        case "Ayak çalışması": return .split
        default: return .forehand
        }
    }
}
