import Foundation

/// Small 3D vector in metres. y is up; the player faces +x (towards the net); +z is the player's right.
struct V3: Equatable {
    var x, y, z: Double
    init(_ x: Double, _ y: Double, _ z: Double) { self.x = x; self.y = y; self.z = z }
    static let zero = V3(0, 0, 0)
    static func + (a: V3, b: V3) -> V3 { V3(a.x + b.x, a.y + b.y, a.z + b.z) }
    static func - (a: V3, b: V3) -> V3 { V3(a.x - b.x, a.y - b.y, a.z - b.z) }
    static func * (a: V3, s: Double) -> V3 { V3(a.x * s, a.y * s, a.z * s) }
    func dot(_ b: V3) -> Double { x * b.x + y * b.y + z * b.z }
    func cross(_ b: V3) -> V3 { V3(y * b.z - z * b.y, z * b.x - x * b.z, x * b.y - y * b.x) }
    var length: Double { dot(self).squareRoot() }
    var normalized: V3 { let l = length; return l > 1e-9 ? self * (1 / l) : V3(0, 1, 0) }
    var horizontal: V3 { V3(x, 0, z) }
    func distance(to b: V3) -> Double { (self - b).length }
    func mix(_ b: V3, _ t: Double) -> V3 { self + (b - self) * t }
    var isFinite: Bool { x.isFinite && y.isFinite && z.isFinite }
}

/// One pose of the 3D player. Only hands, feet, pelvis, chest, rotations and the racket are authored.
/// `solved()` turns that into a body that obeys a few physical rules:
/// limbs keep their length, knees bend forward, hands and racket stay outside head and torso,
/// and a supporting left hand stays on the racket.
struct MotionPose: Equatable {
    var pelvis, chest: V3
    /// Shoulder and hip rotation in degrees. 0 = square to the net, negative = turned to the right (forehand side).
    var chestYaw, hipYaw: Double
    /// Authored elbow points only say which way each elbow points; IK places the real elbow.
    var rightElbow, rightHand, leftElbow, leftHand: V3
    var rightAnkle, leftAnkle: V3
    /// Racket shaft direction from the hitting hand, and roughly where the strings face.
    var racketDir, racketFace: V3
    var ball: V3? = nil
    /// When set, the left hand holds the racket this far along the shaft (0.11 = two-handed grip, 0.3 = throat).
    var leftGrip: Double? = nil
    /// At contact the ball is placed on the strings after the arm is solved.
    var ballOnStrings = false
    /// Before the toss the ball rests in the left hand.
    var ballInLeftHand = false
    /// Knees are always computed (bending forward over the toes).
    var rightKnee = V3.zero, leftKnee = V3.zero
    /// Left-handed player: the whole pose is a mirror image across the court's centre line.
    /// "right" fields then mean the hitting side, which is on the player's left.
    var mirrored = false

    static let shoulderHalfWidth = 0.2, hipHalfWidth = 0.11
    static let racketLength = 0.68, racketHeadOffset = 0.47
    static let upperArm = 0.3, forearm = 0.27, thigh = 0.45, shin = 0.43
    static let headRadius = 0.115
    /// Drawn torso: an elliptic cylinder, thinner front to back than across the shoulders.
    static let torsoFront = 0.10, torsoSide = 0.17

    static func facing(_ yaw: Double) -> V3 { let r = yaw * .pi / 180; return V3(cos(r), 0, -sin(r)) }
    static func rightSide(_ yaw: Double) -> V3 { let r = yaw * .pi / 180; return V3(sin(r), 0, cos(r)) }

    /// Points to the hitting-arm side of the body (the player's right, or left when mirrored).
    func hittingSide(_ yaw: Double) -> V3 { Self.rightSide(yaw) * (mirrored ? -1 : 1) }
    var rightShoulder: V3 { chest + hittingSide(chestYaw) * Self.shoulderHalfWidth }
    var leftShoulder: V3 { chest - hittingSide(chestYaw) * Self.shoulderHalfWidth }
    var rightHip: V3 { pelvis + hittingSide(hipYaw) * Self.hipHalfWidth }
    var leftHip: V3 { pelvis - hittingSide(hipYaw) * Self.hipHalfWidth }
    var neck: V3 { chest + V3(0, 0.08, 0) }
    var head: V3 { chest + V3(0, 0.25, 0) + Self.facing(chestYaw) * 0.03 }
    var rightToe: V3 { toe(from: rightAnkle) }
    var leftToe: V3 { toe(from: leftAnkle) }
    private func toe(from ankle: V3) -> V3 {
        let forward = Self.facing(hipYaw) * 0.17
        return V3(ankle.x + forward.x, max(0.03, ankle.y - 0.06), ankle.z + forward.z)
    }
    var shaft: V3 { racketDir.normalized }
    /// String-face normal, made exactly perpendicular to the shaft.
    var stringNormal: V3 {
        let d = shaft, f = racketFace - d * racketFace.dot(d)
        return f.length > 1e-6 ? f.normalized : d.cross(V3(0, 1, 0.01)).normalized
    }
    var racketHeadCenter: V3 { rightHand + shaft * Self.racketHeadOffset }
    var racketTip: V3 { rightHand + shaft * Self.racketLength }

    var bones: [(name: String, from: V3, to: V3, range: ClosedRange<Double>)] {
        [("right upper arm", rightShoulder, rightElbow, 0.24...0.38), ("right forearm", rightElbow, rightHand, 0.2...0.34),
         ("left upper arm", leftShoulder, leftElbow, 0.24...0.38), ("left forearm", leftElbow, leftHand, 0.2...0.34),
         ("right thigh", rightHip, rightKnee, 0.36...0.5), ("right shin", rightKnee, rightAnkle, 0.34...0.5),
         ("left thigh", leftHip, leftKnee, 0.36...0.5), ("left shin", leftKnee, leftAnkle, 0.34...0.5),
         ("torso", pelvis, chest, 0.42...0.56)]
    }
    func with(_ change: (inout MotionPose) -> Void) -> MotionPose { var copy = self; change(&copy); return copy }

    /// Mirror image across the court's centre line (z → −z): a right-hander becomes a left-hander.
    func mirroredImage() -> MotionPose {
        func m(_ v: V3) -> V3 { V3(v.x, v.y, -v.z) }
        var out = self
        out.pelvis = m(pelvis); out.chest = m(chest)
        out.chestYaw = -chestYaw; out.hipYaw = -hipYaw
        out.rightElbow = m(rightElbow); out.rightHand = m(rightHand); out.leftElbow = m(leftElbow); out.leftHand = m(leftHand)
        out.rightKnee = m(rightKnee); out.leftKnee = m(leftKnee); out.rightAnkle = m(rightAnkle); out.leftAnkle = m(leftAnkle)
        out.racketDir = m(racketDir); out.racketFace = m(racketFace)
        out.ball = ball.map(m)
        out.mirrored = !mirrored
        return out
    }

    // MARK: Torso geometry
    var torsoAxes: (up: V3, front: V3, side: V3) {
        let up = (chest - pelvis).normalized
        var side = Self.rightSide((chestYaw + hipYaw) / 2)
        side = (side - up * side.dot(up)).normalized
        return (up, up.cross(side), side)
    }
    /// > 0 when `point` is inside the torso grown by `margin` (1 = on the axis); also the outward direction.
    func torsoDepth(of point: V3, margin: Double) -> (depth: Double, outward: V3) {
        let axes = torsoAxes, q = point - pelvis
        let along = q.dot(axes.up), length = (chest - pelvis).length
        guard along > 0.02 && along < length + 0.06 else { return (-1, .zero) }
        let rf = Self.torsoFront + margin, rs = Self.torsoSide + margin
        let f = q.dot(axes.front), s = q.dot(axes.side)
        let r = ((f / rf) * (f / rf) + (s / rs) * (s / rs)).squareRoot()
        let outward = axes.front * (f / (rf * rf)) + axes.side * (s / (rs * rs))
        return (1 - r, outward.length > 1e-6 ? outward.normalized : axes.front)
    }

    // MARK: Solving
    func solved() -> MotionPose {
        var out = self
        // Hands never inside the head or torso.
        out.rightHand = out.clearOfBody(out.rightHand)
        (out.rightElbow, out.rightHand) = out.arm(from: out.rightShoulder, to: out.rightHand, hint: rightElbow)
        out.racketDir = out.racketClearOfBody()
        // Support hand: held on the racket, or kept clear of the body.
        if let grip = leftGrip { out.leftHand = out.rightHand + out.shaft * grip }
        else { out.leftHand = out.clearOfBody(out.leftHand) }
        (out.leftElbow, out.leftHand) = out.arm(from: out.leftShoulder, to: out.leftHand, hint: leftElbow)
        // Knees always bend forward, over the toes.
        let kneeForward = Self.facing(hipYaw) * 0.35
        (out.rightKnee, out.rightAnkle) = Self.limb(from: rightHip, to: rightAnkle, hint: (rightHip + rightAnkle) * 0.5 + kneeForward, upper: Self.thigh, lower: Self.shin)
        (out.leftKnee, out.leftAnkle) = Self.limb(from: leftHip, to: leftAnkle, hint: (leftHip + leftAnkle) * 0.5 + kneeForward, upper: Self.thigh, lower: Self.shin)
        if ballOnStrings { out.ball = out.racketHeadCenter + out.stringNormal * 0.05; out.ballOnStrings = false }
        if ballInLeftHand { out.ball = out.leftHand + V3(0, 0.07, 0); out.ballInLeftHand = false }
        return out
    }
    /// Arm IK that also keeps the elbow and the middle of the forearm out of the torso.
    private func arm(from shoulder: V3, to hand: V3, hint: V3) -> (V3, V3) {
        var (elbow, end) = Self.limb(from: shoulder, to: hand, hint: hint, upper: Self.upperArm, lower: Self.forearm)
        for _ in 0..<3 {
            let worst = [elbow, elbow.mix(end, 0.5)].map { torsoDepth(of: $0, margin: 0.035) }.max { $0.depth < $1.depth }!
            guard worst.depth > 0 else { break }
            (elbow, end) = Self.limb(from: shoulder, to: end, hint: elbow + worst.outward * 0.4, upper: Self.upperArm, lower: Self.forearm)
        }
        return (elbow, end)
    }
    private func clearOfBody(_ point: V3) -> V3 {
        var p = point
        let fromHead = p - head
        if fromHead.length < 0.17 { p = head + fromHead.normalized * 0.17 }
        let (depth, outward) = torsoDepth(of: p, margin: 0.05)
        if depth > 0 { p = p + outward * (depth * (Self.torsoSide + 0.05) + 0.01) }
        return p
    }
    /// Turns the racket around the hand until no part of it is inside the head or the torso.
    private func racketClearOfBody() -> V3 {
        var direction = shaft
        for _ in 0..<12 {
            var push = V3.zero
            for k in 0...12 {
                let along = 0.12 + (Self.racketLength - 0.12) * Double(k) / 12
                let point = rightHand + direction * along
                let fromHead = point - head
                let headGap = Self.headRadius + 0.05 - fromHead.length
                if headGap > 0 { push = push + fromHead.normalized * (headGap / along) }
                let (depth, outward) = torsoDepth(of: point, margin: 0.04)
                if depth > 0 { push = push + outward * (depth * 0.16 / along) }
            }
            if push.length < 1e-4 { break }
            direction = (direction + push * 1.3).normalized
        }
        return direction
    }
    /// Two-bone inverse kinematics. Returns the middle joint and the end point, pulled in if out of reach.
    static func limb(from root: V3, to target: V3, hint: V3, upper a: Double, lower b: Double) -> (V3, V3) {
        let offset = target - root
        let direction = offset.normalized
        let reach = min(max(offset.length, abs(a - b) + 0.02), a + b - 0.002)
        let end = root + direction * reach
        let cosA = (a * a + reach * reach - b * b) / (2 * a * reach)
        let sinA = max(0, 1 - cosA * cosA).squareRoot()
        var bend = (hint - root) - direction * (hint - root).dot(direction)
        if bend.length < 1e-4 { bend = direction.cross(V3(0, 1, 0)).length > 1e-4 ? direction.cross(V3(0, 1, 0)) : V3(1, 0, 0) }
        let middle = root + direction * (a * cosA) + bend.normalized * (a * sinA)
        return (middle, end)
    }

    // MARK: Interpolation
    private static let bodyPoints: [WritableKeyPath<MotionPose, V3>] = [\.pelvis, \.chest]
    /// Interpolated in the chest's own frame, so arms turn with the body instead of cutting through it.
    private static let armPoints: [WritableKeyPath<MotionPose, V3>] = [\.rightElbow, \.rightHand, \.leftElbow, \.leftHand]
    private static let armDirections: [WritableKeyPath<MotionPose, V3>] = [\.racketDir, \.racketFace]
    private func toChest(_ v: V3, isPoint: Bool) -> V3 {
        let q = isPoint ? v - chest : v
        return V3(q.dot(Self.facing(chestYaw)), q.y, q.dot(hittingSide(chestYaw)))
    }
    private func fromChest(_ v: V3, isPoint: Bool) -> V3 {
        let w = Self.facing(chestYaw) * v.x + V3(0, v.y, 0) + hittingSide(chestYaw) * v.z
        return isPoint ? chest + w : w
    }
    private static let angles: [WritableKeyPath<MotionPose, Double>] = [\.chestYaw, \.hipYaw]

    /// Catmull-Rom between `b` and `c` (neighbours `a`, `d`), so joints travel on smooth arcs.
    /// Feet are handled separately: a planted foot stays put, or lifts and steps.
    static func spline(_ a: MotionPose, _ b: MotionPose, _ c: MotionPose, _ d: MotionPose, _ t: Double) -> MotionPose {
        var out = b
        for key in bodyPoints { out[keyPath: key] = curve(a[keyPath: key], b[keyPath: key], c[keyPath: key], d[keyPath: key], t) }
        for key in angles { out[keyPath: key] = curve(a[keyPath: key], b[keyPath: key], c[keyPath: key], d[keyPath: key], t) }
        for key in armPoints {
            let local = curve(a.toChest(a[keyPath: key], isPoint: true), b.toChest(b[keyPath: key], isPoint: true),
                              c.toChest(c[keyPath: key], isPoint: true), d.toChest(d[keyPath: key], isPoint: true), t)
            out[keyPath: key] = out.fromChest(local, isPoint: true)
        }
        // Racket directions turn at an even angular speed, so a big rotation never collapses into a one-frame flip.
        for key in armDirections {
            let local = slerp(b.toChest(b[keyPath: key], isPoint: false), c.toChest(c[keyPath: key], isPoint: false), t)
            out[keyPath: key] = out.fromChest(local, isPoint: false)
        }
        out.rightAnkle = step(from: b.rightAnkle, to: c.rightAnkle, t)
        out.leftAnkle = step(from: b.leftAnkle, to: c.leftAnkle, t)
        // Left-hand grip blends between holding the racket and moving freely.
        switch (b.leftGrip, c.leftGrip) {
        case let (g0?, g1?): out.leftGrip = g0 + (g1 - g0) * t
        case let (g0?, nil):
            out.leftGrip = nil; out.leftHand = (out.rightHand + out.shaft * g0).mix(out.leftHand, smooth(t))
        case let (nil, g1?):
            out.leftGrip = nil; out.leftHand = out.leftHand.mix(out.rightHand + out.shaft * g1, smooth(t))
        default: break
        }
        out.ballOnStrings = false; out.ballInLeftHand = false
        switch (b.ball, c.ball) {
        case let (from?, to?): out.ball = curve(a.ball ?? from, from, to, d.ball ?? to, t)
        case let (from?, nil): out.ball = t < 0.3 ? from : nil
        case let (nil, to?): out.ball = t > 0.7 ? to : nil
        default: out.ball = nil
        }
        return out
    }
    static func slerp(_ from: V3, _ to: V3, _ t: Double) -> V3 {
        let a = from.normalized, b = to.normalized
        let cosine = min(1, max(-1, a.dot(b)))
        let angle = acos(cosine)
        guard angle > 1e-3 else { return a.mix(b, t).normalized }
        // Nearly opposite: turn around an axis perpendicular to both, through the "up" side.
        if angle > .pi - 1e-3 {
            let axis = a.cross(V3(0, 1, 0)).length > 1e-3 ? a.cross(V3(0, 1, 0)).normalized : V3(1, 0, 0)
            let ortho = axis.cross(a).normalized
            return (a * cos(angle * t) + ortho * sin(angle * t)).normalized
        }
        return (a * (sin((1 - t) * angle) / sin(angle)) + b * (sin(t * angle) / sin(angle))).normalized
    }
    static func smooth(_ t: Double) -> Double { let c = min(1, max(0, t)); return c * c * (3 - 2 * c) }
    /// A foot that changes place is lifted and set down again; it never skates along the court.
    static func step(from start: V3, to end: V3, _ t: Double) -> V3 {
        let planted = start.y < 0.1 && end.y < 0.1
        let distance = (end - start).horizontal.length
        if start.y < 0.1 && end.y >= 0.1 {
            // Take-off: leave the ground first, then travel.
            let lift = smooth(t / 0.5), travel = smooth((t - 0.25) / 0.75)
            return V3(start.x + (end.x - start.x) * travel, start.y + (end.y - start.y) * lift, start.z + (end.z - start.z) * travel)
        }
        if start.y >= 0.1 && end.y < 0.1 {
            // Landing: arrive above the spot, then touch down.
            let travel = smooth(t / 0.75), drop = smooth(t)
            return V3(start.x + (end.x - start.x) * travel, start.y + (end.y - start.y) * drop, start.z + (end.z - start.z) * travel)
        }
        guard planted, distance > 0.04 else { return start.mix(end, smooth(t)) }
        // Lift first, travel only while the foot is in the air, then set it down.
        let s = smooth((t - 0.1) / 0.8)
        var foot = start.mix(end, smooth((s - 0.12) / 0.76))
        foot.y = max(foot.y, 0.09) + min(0.14, 0.06 + distance * 0.18) * sin(.pi * s)
        return foot
    }
    private static func curve(_ p0: Double, _ p1: Double, _ p2: Double, _ p3: Double, _ t: Double) -> Double {
        let t2 = t * t, t3 = t2 * t
        return 0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
    }
    private static func curve(_ p0: V3, _ p1: V3, _ p2: V3, _ p3: V3, _ t: Double) -> V3 {
        V3(curve(p0.x, p1.x, p2.x, p3.x, t), curve(p0.y, p1.y, p2.y, p3.y, t), curve(p0.z, p1.z, p2.z, p3.z, t))
    }
}

struct MotionKeyframe: Equatable {
    /// Localisation key of the phase name, e.g. "motion.phase.contact".
    let phase: String
    /// The solved pose drawn at this key moment.
    let pose: MotionPose
    /// Seconds to travel to the next key pose: slow preparation, fast swing.
    var duration: Double = 0.7
    /// Grip as authored, kept so in-betweens can blend a hand onto or off the racket.
    let leftGrip: Double?
    init(phase: String, pose: MotionPose, duration: Double = 0.7) {
        self.phase = phase; self.pose = pose.solved(); self.duration = duration; self.leftGrip = pose.leftGrip
    }
}

enum MotionCamera: String, CaseIterable, Identifiable {
    case side, behind, front
    var id: String { rawValue }
    var titleKey: String { "motion.camera." + rawValue }
}

struct StrokeMotion: Identifiable, Equatable {
    let id: String
    /// One cycle of distinct poses; the cycle returns to the first pose.
    var keyframes: [MotionKeyframe] { keyframesStorage }
    private var keyframesStorage: [MotionKeyframe]
    /// Where the player stands: metres from the baseline towards the net.
    var courtX: Double = -0.4
    var defaultCamera: MotionCamera = .side
    /// Backhands read best from the player's left; everything else from the right.
    var sideCameraOnLeft = false
    /// Mirrored for a left-handed player; cameras mirror with the player.
    var isLeftHanded = false
    var titleKey: String { "motion.title." + id }
    init(id: String, keyframes: [MotionKeyframe], courtX: Double = -0.4, defaultCamera: MotionCamera = .side, sideCameraOnLeft: Bool = false) {
        self.id = id; self.keyframesStorage = keyframes; self.courtX = courtX
        self.defaultCamera = defaultCamera; self.sideCameraOnLeft = sideCameraOnLeft
    }
    var cycleDuration: Double { keyframes.reduce(0) { $0 + $1.duration } }

    private func timing(at progress: Double) -> (index: Int, local: Double) {
        guard keyframes.count > 1, cycleDuration > 0 else { return (0, 0) }
        let value = progress.isFinite ? progress - progress.rounded(.down) : 0
        var time = value * cycleDuration
        for (index, frame) in keyframes.enumerated() {
            if time < frame.duration || index == keyframes.count - 1 { return (index, min(1, max(0, time / frame.duration))) }
            time -= frame.duration
        }
        return (0, 0)
    }
    /// Pose at `progress` (0...1 over one cycle, wraps around).
    func pose(at progress: Double) -> MotionPose {
        guard let first = keyframes.first?.pose else { return StrokeMotion.ready.solved() }
        guard keyframes.count > 1 else { return first }
        let (i, local) = timing(at: progress)
        let n = keyframes.count
        func p(_ k: Int) -> MotionPose {
            let frame = keyframes[((k % n) + n) % n]
            return frame.pose.with { $0.leftGrip = frame.leftGrip }
        }
        return MotionPose.spline(p(i - 1), p(i), p(i + 1), p(i + 2), MotionPose.smooth(local)).solved()
    }
    /// The same stroke for a left-handed player.
    func mirrored() -> StrokeMotion {
        var copy = self
        copy.isLeftHanded = !isLeftHanded
        copy.keyframesStorage = keyframes.map { frame in
            MotionKeyframe(phase: frame.phase, pose: frame.pose.mirroredImage().with { $0.leftGrip = frame.leftGrip }, duration: frame.duration)
        }
        return copy
    }
    func forPlayer(leftHanded: Bool) -> StrokeMotion { leftHanded == isLeftHanded ? self : mirrored() }

    /// Cycle progress at which key frame `index` is reached, for stepping through phases by hand.
    func progress(atKeyframe index: Int) -> Double {
        guard cycleDuration > 0, keyframes.indices.contains(index) else { return 0 }
        return keyframes.prefix(index).reduce(0) { $0 + $1.duration } / cycleDuration
    }
    /// The key pose the player is at or closest to.
    func phaseIndex(at progress: Double) -> Int {
        guard keyframes.count > 1 else { return 0 }
        let (i, local) = timing(at: progress)
        return local > 0.6 ? (i + 1) % keyframes.count : i
    }
    /// 0...1 while the racket meets the ball, for the impact flash.
    func impact(at progress: Double) -> Double? {
        guard keyframes.count > 1 else { return nil }
        let (i, local) = timing(at: progress)
        let contact = keyframes.firstIndex { $0.phase == "motion.phase.contact" || $0.phase == "motion.phase.punch" }
        guard let contact, i == contact, local < 0.45 else { return nil }
        return local / 0.45
    }
}

extension StrokeMotion {
    // MARK: Base poses (right-handed player)
    /// Athletic ready position: knees flexed, racket in front, left hand on the throat.
    static let ready = MotionPose(
        pelvis: V3(0, 0.88, 0), chest: V3(0.06, 1.38, 0), chestYaw: 0, hipYaw: 0,
        rightElbow: V3(0.18, 1.08, 0.32), rightHand: V3(0.36, 1.02, 0.12), leftElbow: V3(0.2, 1.08, -0.3), leftHand: V3(0.42, 1.08, -0.02),
        rightAnkle: V3(0, 0.09, 0.32), leftAnkle: V3(0, 0.09, -0.32),
        racketDir: V3(0.65, 0.6, -0.3), racketFace: V3(0, 0, 1), leftGrip: 0.28)
    static let netReady = ready.with {
        // Racket head up in front of the chest, below eye level, so the player can see past it.
        $0.rightHand = V3(0.4, 1.06, 0.14); $0.rightElbow = V3(0.2, 1.02, 0.34)
        $0.racketDir = V3(0.62, 0.62, -0.2); $0.racketFace = V3(1, 0, 0)
    }
    static let serveStance = MotionPose(
        pelvis: V3(0, 0.92, 0.02), chest: V3(0.01, 1.42, 0.03), chestYaw: -75, hipYaw: -60,
        rightElbow: V3(-0.05, 1.12, 0.32), rightHand: V3(0.08, 1.08, 0.36), leftElbow: V3(0.12, 1.12, 0.12), leftHand: V3(0.3, 1.12, 0.45),
        rightAnkle: V3(-0.22, 0.09, 0.26), leftAnkle: V3(0.26, 0.09, -0.08),
        racketDir: V3(0.75, 0.2, 0.4), racketFace: V3(0, 1, 0), leftGrip: 0.3, ballInLeftHand: true)
    /// "Trophy": hitting elbow at shoulder height out to the side, racket up behind the head.
    private static func trophyArm(_ pose: inout MotionPose, shoulderX: Double) {
        pose.rightElbow = V3(shoulderX - 0.2, 1.34, -0.04)
        pose.rightHand = V3(shoulderX - 0.1, 1.64, -0.1)
        pose.racketDir = V3(-0.2, 0.8, -0.45); pose.racketFace = V3(1, 0, 0)
    }

    // MARK: Strokes
    static let forehand = StrokeMotion(id: "forehand", keyframes: [
        .init(phase: "motion.phase.ready", pose: ready, duration: 0.9),
        .init(phase: "motion.phase.takeback", pose: ready.with {
            $0.pelvis = V3(0.0, 0.86, 0.02); $0.chest = V3(-0.02, 1.36, 0.03); $0.chestYaw = -80; $0.hipYaw = -45
            $0.rightHand = V3(-0.3, 1.24, 0.36); $0.rightElbow = V3(-0.2, 1.02, 0.46); $0.racketDir = V3(-0.6, 0.65, 0.3); $0.racketFace = V3(0, 0, 1)
            $0.leftGrip = nil; $0.leftHand = V3(0.42, 1.32, 0.28); $0.leftElbow = V3(0.24, 1.18, 0.0)
            $0.rightAnkle = V3(-0.05, 0.09, 0.34); $0.leftAnkle = V3(0.42, 0.09, -0.05)
            $0.ball = V3(4.2, 1.45, 1.0)
        }, duration: 0.75),
        .init(phase: "motion.phase.drop", pose: ready.with {
            $0.pelvis = V3(0.08, 0.84, 0.03); $0.chest = V3(0.05, 1.34, 0.04); $0.chestYaw = -68; $0.hipYaw = -30
            $0.rightHand = V3(-0.28, 0.98, 0.48); $0.rightElbow = V3(-0.14, 1.0, 0.58); $0.racketDir = V3(-0.55, -0.5, 0.35); $0.racketFace = V3(0, 0.3, 1)
            $0.leftGrip = nil; $0.leftHand = V3(0.45, 1.2, 0.2); $0.leftElbow = V3(0.28, 1.12, -0.02)
            $0.rightAnkle = V3(-0.05, 0.09, 0.34); $0.leftAnkle = V3(0.42, 0.09, -0.05)
            $0.ball = V3(1.9, 1.12, 0.95)
        }, duration: 0.32),
        .init(phase: "motion.phase.contact", pose: ready.with {
            $0.pelvis = V3(0.16, 0.88, 0.0); $0.chest = V3(0.22, 1.38, 0.0); $0.chestYaw = -12; $0.hipYaw = -5
            $0.rightHand = V3(0.5, 1.0, 0.5); $0.rightElbow = V3(0.28, 1.02, 0.52); $0.racketDir = V3(0.28, 0.06, 0.96); $0.racketFace = V3(1, 0.1, 0)
            $0.leftGrip = nil; $0.leftHand = V3(0.26, 1.12, -0.4); $0.leftElbow = V3(0.14, 1.18, -0.36)
            $0.rightAnkle = V3(-0.03, 0.13, 0.33); $0.leftAnkle = V3(0.42, 0.09, -0.05)
            $0.ballOnStrings = true
        }, duration: 0.2),
        .init(phase: "motion.phase.follow", pose: ready.with {
            $0.pelvis = V3(0.19, 0.89, -0.01); $0.chest = V3(0.26, 1.39, -0.01); $0.chestYaw = 15; $0.hipYaw = 8
            $0.rightHand = V3(0.66, 1.36, -0.04); $0.rightElbow = V3(0.6, 1.18, 0.32); $0.racketDir = V3(0.2, 0.85, -0.5); $0.racketFace = V3(0.4, 0, 1)
            $0.leftGrip = nil; $0.leftHand = V3(0.3, 1.15, -0.42); $0.leftElbow = V3(0.18, 1.18, -0.38)
            $0.rightAnkle = V3(0.08, 0.15, 0.28); $0.leftAnkle = V3(0.42, 0.09, -0.05)
            $0.ball = V3(1.6, 1.25, 0.3)
        }, duration: 0.24),
        .init(phase: "motion.phase.finish", pose: ready.with {
            $0.pelvis = V3(0.2, 0.9, -0.02); $0.chest = V3(0.28, 1.4, -0.02); $0.chestYaw = 35; $0.hipYaw = 15
            $0.rightHand = V3(0.16, 1.44, -0.38); $0.rightElbow = V3(0.5, 1.42, -0.04); $0.racketDir = V3(-0.65, 0.3, -0.4); $0.racketFace = V3(0, 1, 0)
            $0.leftGrip = 0.3; $0.leftElbow = V3(0.3, 1.2, -0.42)
            $0.rightAnkle = V3(0.12, 0.15, 0.26); $0.leftAnkle = V3(0.42, 0.09, -0.05)
            $0.ball = V3(3.4, 1.4, -0.6)
        }, duration: 0.85),
    ])
    static let backhand = StrokeMotion(id: "backhand", keyframes: [
        .init(phase: "motion.phase.ready", pose: ready, duration: 0.9),
        .init(phase: "motion.phase.takeback", pose: ready.with {
            $0.pelvis = V3(0.02, 0.86, -0.02); $0.chest = V3(0.0, 1.36, -0.03); $0.chestYaw = 85; $0.hipYaw = 50
            $0.rightHand = V3(-0.12, 1.02, -0.3); $0.rightElbow = V3(0.12, 1.02, -0.22)
            $0.leftGrip = 0.11; $0.leftElbow = V3(-0.2, 1.06, -0.12)
            $0.racketDir = V3(-0.6, 0.6, -0.35); $0.racketFace = V3(0, 0, -1)
            $0.rightAnkle = V3(0.4, 0.09, 0.02); $0.leftAnkle = V3(-0.04, 0.09, -0.36)
            $0.ball = V3(4.2, 1.45, -1.0)
        }, duration: 0.75),
        .init(phase: "motion.phase.contact", pose: ready.with {
            $0.pelvis = V3(0.16, 0.88, 0.0); $0.chest = V3(0.22, 1.38, -0.02); $0.chestYaw = 30; $0.hipYaw = 15
            $0.rightHand = V3(0.45, 1.05, -0.25); $0.rightElbow = V3(0.36, 1.08, 0.0)
            $0.leftGrip = 0.11; $0.leftElbow = V3(0.1, 1.08, -0.4)
            $0.racketDir = V3(0.3, 0.05, -0.95); $0.racketFace = V3(1, 0.1, 0)
            $0.rightAnkle = V3(0.4, 0.09, 0.02); $0.leftAnkle = V3(0.0, 0.13, -0.34)
            $0.ballOnStrings = true
        }, duration: 0.2),
        .init(phase: "motion.phase.follow", pose: ready.with {
            $0.pelvis = V3(0.19, 0.89, 0.01); $0.chest = V3(0.26, 1.39, 0.0); $0.chestYaw = 5; $0.hipYaw = 2
            $0.rightHand = V3(0.58, 1.34, 0.06); $0.rightElbow = V3(0.5, 1.15, 0.28)
            $0.leftGrip = 0.11; $0.leftElbow = V3(0.38, 1.15, -0.3)
            $0.racketDir = V3(0.15, 0.85, 0.5); $0.racketFace = V3(0.4, 0, -1)
            $0.rightAnkle = V3(0.4, 0.09, 0.02); $0.leftAnkle = V3(0.08, 0.15, -0.3)
            $0.ball = V3(1.6, 1.25, -0.3)
        }, duration: 0.24),
        .init(phase: "motion.phase.finish", pose: ready.with {
            $0.pelvis = V3(0.2, 0.9, 0.02); $0.chest = V3(0.28, 1.4, 0.02); $0.chestYaw = -45; $0.hipYaw = -15
            $0.rightHand = V3(0.32, 1.44, 0.4); $0.rightElbow = V3(0.5, 1.3, 0.2)
            $0.leftGrip = 0.11; $0.leftElbow = V3(0.4, 1.25, -0.05)
            $0.racketDir = V3(-0.65, 0.35, 0.5); $0.racketFace = V3(0, 1, 0)
            $0.rightAnkle = V3(0.4, 0.09, 0.02); $0.leftAnkle = V3(0.14, 0.15, -0.26)
            $0.ball = V3(3.4, 1.4, 0.6)
        }, duration: 0.85),
    ], sideCameraOnLeft: true)
    static let serve = StrokeMotion(id: "serve", keyframes: [
        .init(phase: "motion.phase.stance", pose: serveStance, duration: 0.7),
        .init(phase: "motion.phase.toss", pose: serveStance.with {
            $0.pelvis = V3(0.0, 0.88, 0.02); $0.chest = V3(-0.03, 1.38, 0.03); $0.chestYaw = -85
            $0.rightHand = V3(-0.42, 0.96, 0.12); $0.rightElbow = V3(-0.3, 1.12, 0.2); $0.racketDir = V3(-0.55, -0.55, 0.15); $0.racketFace = V3(0, 0, 1)
            $0.leftGrip = nil; $0.leftHand = V3(0.22, 1.55, 0.02); $0.leftElbow = V3(0.12, 1.32, 0.1)
            $0.ballInLeftHand = true
        }, duration: 0.5),
        .init(phase: "motion.phase.trophy", pose: serveStance.with {
            $0.pelvis = V3(0.04, 0.8, 0.02); $0.chest = V3(-0.06, 1.3, 0.04); $0.chestYaw = -85
            trophyArm(&$0, shoulderX: -0.26)
            $0.leftGrip = nil; $0.leftHand = V3(0.2, 1.9, -0.02); $0.leftElbow = V3(0.14, 1.6, 0.08)
            $0.ballInLeftHand = false; $0.ball = V3(0.36, 2.55, 0.0)
        }, duration: 0.55),
        .init(phase: "motion.phase.racketdrop", pose: serveStance.with {
            $0.pelvis = V3(0.1, 0.86, 0.02); $0.chest = V3(0.06, 1.36, 0.04); $0.chestYaw = -55
            $0.rightHand = V3(-0.2, 1.42, -0.15); $0.rightElbow = V3(-0.04, 1.7, 0.1); $0.racketDir = V3(-0.05, -0.9, -0.4); $0.racketFace = V3(1, 0, 0)
            $0.leftGrip = nil; $0.leftHand = V3(0.32, 1.48, -0.22); $0.leftElbow = V3(0.2, 1.34, -0.08)
            $0.ballInLeftHand = false; $0.ball = V3(0.46, 2.78, 0.04)
        }, duration: 0.28),
        .init(phase: "motion.phase.contact", pose: serveStance.with {
            $0.pelvis = V3(0.26, 0.98, 0.0); $0.chest = V3(0.36, 1.48, 0.02); $0.chestYaw = -20; $0.hipYaw = -25
            $0.rightHand = V3(0.47, 2.1, 0.1); $0.rightElbow = V3(0.4, 1.85, 0.22); $0.racketDir = V3(0.25, 0.97, -0.05); $0.racketFace = V3(1, -0.2, 0)
            $0.leftGrip = nil; $0.leftHand = V3(0.42, 1.1, -0.06); $0.leftElbow = V3(0.3, 1.22, -0.16)
            $0.rightAnkle = V3(0.0, 0.26, 0.2); $0.leftAnkle = V3(0.38, 0.17, -0.06)
            $0.ballInLeftHand = false; $0.ballOnStrings = true
        }, duration: 0.22),
        .init(phase: "motion.phase.finish", pose: serveStance.with {
            $0.pelvis = V3(0.55, 0.84, -0.04); $0.chest = V3(0.74, 1.3, -0.06); $0.chestYaw = 30; $0.hipYaw = 10
            $0.rightHand = V3(0.62, 0.88, -0.42); $0.rightElbow = V3(0.8, 1.05, -0.2); $0.racketDir = V3(-0.4, -0.5, -0.75); $0.racketFace = V3(0, 1, 0)
            $0.leftGrip = nil; $0.leftHand = V3(0.74, 1.0, -0.46); $0.leftElbow = V3(0.66, 1.14, -0.36)
            $0.rightAnkle = V3(0.2, 0.32, 0.22); $0.leftAnkle = V3(0.75, 0.09, -0.06)
            $0.ballInLeftHand = false; $0.ball = V3(3.6, 1.7, -0.6)
        }, duration: 0.95),
    ])
    static let volley = StrokeMotion(id: "volley", keyframes: [
        .init(phase: "motion.phase.ready", pose: netReady, duration: 0.8),
        .init(phase: "motion.phase.turn", pose: netReady.with {
            $0.chestYaw = -35; $0.hipYaw = -15
            $0.rightHand = V3(0.3, 1.28, 0.44); $0.rightElbow = V3(0.08, 1.12, 0.46); $0.racketDir = V3(0.3, 0.8, 0.45); $0.racketFace = V3(0.95, 0, -0.3)
            $0.leftGrip = nil; $0.leftHand = V3(0.45, 1.25, 0.15); $0.leftElbow = V3(0.24, 1.12, -0.12)
            $0.ball = V3(3.2, 1.35, 0.75)
        }, duration: 0.38),
        .init(phase: "motion.phase.punch", pose: netReady.with {
            $0.pelvis = V3(0.22, 0.84, 0.0); $0.chest = V3(0.32, 1.33, 0.0); $0.chestYaw = -20; $0.hipYaw = -10
            $0.rightHand = V3(0.62, 1.26, 0.44); $0.rightElbow = V3(0.4, 1.08, 0.44); $0.racketDir = V3(0.35, 0.75, 0.5); $0.racketFace = V3(1, 0.1, -0.25)
            $0.leftGrip = nil; $0.leftHand = V3(0.55, 1.15, -0.05); $0.leftElbow = V3(0.38, 1.08, -0.24)
            $0.leftAnkle = V3(0.5, 0.09, -0.14); $0.rightAnkle = V3(0.04, 0.12, 0.33)
            $0.ballOnStrings = true
        }, duration: 0.32),
        .init(phase: "motion.phase.recover", pose: netReady.with { $0.ball = V3(5.5, 1.0, -0.5) }, duration: 0.7),
    ], courtX: 8.6, defaultCamera: .front)
    static let overhead = StrokeMotion(id: "overhead", keyframes: [
        .init(phase: "motion.phase.ready", pose: netReady, duration: 0.7),
        .init(phase: "motion.phase.point", pose: serveStance.with {
            $0.pelvis = V3(-0.3, 0.88, 0.04); $0.chest = V3(-0.32, 1.38, 0.05); $0.chestYaw = -80; $0.hipYaw = -65
            trophyArm(&$0, shoulderX: -0.52)
            $0.leftGrip = nil; $0.leftHand = V3(-0.05, 1.92, 0.02); $0.leftElbow = V3(-0.12, 1.62, 0.1)
            $0.rightAnkle = V3(-0.6, 0.09, 0.28); $0.leftAnkle = V3(-0.02, 0.09, -0.12)
            $0.ballInLeftHand = false; $0.ball = V3(0.3, 3.4, 0.05)
        }, duration: 0.75),
        .init(phase: "motion.phase.contact", pose: serveStance.with {
            $0.pelvis = V3(0.0, 0.94, 0.02); $0.chest = V3(0.1, 1.44, 0.03); $0.chestYaw = -20; $0.hipYaw = -30
            $0.rightHand = V3(0.21, 2.06, 0.1); $0.rightElbow = V3(0.14, 1.8, 0.22); $0.racketDir = V3(0.25, 0.97, -0.05); $0.racketFace = V3(1, -0.2, 0)
            $0.leftGrip = nil; $0.leftHand = V3(0.16, 1.06, -0.06); $0.leftElbow = V3(0.06, 1.18, -0.16)
            $0.rightAnkle = V3(-0.3, 0.09, 0.26); $0.leftAnkle = V3(0.24, 0.09, -0.1)
            $0.ballInLeftHand = false; $0.ballOnStrings = true
        }, duration: 0.22),
        .init(phase: "motion.phase.finish", pose: serveStance.with {
            $0.pelvis = V3(0.24, 0.86, -0.04); $0.chest = V3(0.4, 1.33, -0.06); $0.chestYaw = 30; $0.hipYaw = 5
            $0.rightHand = V3(0.32, 0.86, -0.45); $0.rightElbow = V3(0.44, 1.04, -0.22); $0.racketDir = V3(-0.4, -0.5, -0.75); $0.racketFace = V3(0, 1, 0)
            $0.leftGrip = nil; $0.leftHand = V3(0.4, 0.98, -0.48); $0.leftElbow = V3(0.3, 1.12, -0.38)
            $0.leftAnkle = V3(0.42, 0.09, -0.1); $0.rightAnkle = V3(-0.05, 0.13, 0.26)
            $0.ballInLeftHand = false; $0.ball = V3(3.4, 1.0, -0.6)
        }, duration: 0.85),
    ], courtX: 8.0)
    static let split = StrokeMotion(id: "split", keyframes: [
        .init(phase: "motion.phase.ready", pose: ready.with {
            $0.pelvis = V3(0, 0.92, 0); $0.chest = V3(0.05, 1.42, 0)
            $0.rightAnkle = V3(0, 0.09, 0.22); $0.leftAnkle = V3(0, 0.09, -0.22)
            $0.rightHand = V3(0.36, 1.06, 0.12)
        }, duration: 0.6),
        .init(phase: "motion.phase.hop", pose: ready.with {
            $0.pelvis = V3(0, 1.08, 0); $0.chest = V3(0.05, 1.58, 0)
            $0.rightAnkle = V3(0, 0.28, 0.2); $0.leftAnkle = V3(0, 0.28, -0.2)
            $0.rightHand = V3(0.36, 1.22, 0.12)
        }, duration: 0.3),
        .init(phase: "motion.phase.land", pose: ready.with {
            $0.pelvis = V3(-0.02, 0.8, 0); $0.chest = V3(0.06, 1.29, 0)
            $0.rightAnkle = V3(0, 0.09, 0.44); $0.leftAnkle = V3(0, 0.09, -0.44)
            $0.rightHand = V3(0.36, 0.94, 0.12)
        }, duration: 0.35),
        .init(phase: "motion.phase.firststep", pose: ready.with {
            $0.pelvis = V3(0.0, 0.83, 0.38); $0.chest = V3(0.05, 1.31, 0.46); $0.chestYaw = -35; $0.hipYaw = -45
            $0.rightAnkle = V3(0.12, 0.09, 1.02); $0.leftAnkle = V3(0.0, 0.09, 0.0)
            $0.rightHand = V3(0.26, 1.02, 0.7); $0.racketDir = V3(0.55, 0.6, 0.2)
        }, duration: 0.75),
    ], courtX: 0.6, defaultCamera: .front)

    static let all: [StrokeMotion] = [forehand, backhand, serve, volley, overhead, split]
}

extension PracticePlan {
    /// The stroke animation that best illustrates this drill.
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
