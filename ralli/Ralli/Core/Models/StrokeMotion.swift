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
    func distance(to b: V3) -> Double { (self - b).length }
    var isFinite: Bool { x.isFinite && y.isFinite && z.isFinite }
}

/// One key pose of the 3D player. Only the main joints are authored; shoulders, hips, head,
/// toes and the racket are derived so every pose stays anatomically consistent.
struct MotionPose: Equatable {
    var pelvis, chest: V3
    /// Shoulder and hip rotation in degrees. 0 = square to the net, negative = turned to the right (forehand side).
    var chestYaw, hipYaw: Double
    var rightElbow, rightHand, leftElbow, leftHand: V3
    var rightKnee, rightAnkle, leftKnee, leftAnkle: V3
    /// Racket shaft direction from the hitting hand, and the direction the strings face.
    var racketDir, racketFace: V3
    var ball: V3? = nil
    /// At contact the ball is placed on the strings after the arm is solved.
    var ballOnStrings = false

    static let shoulderHalfWidth = 0.2, hipHalfWidth = 0.11
    static let racketLength = 0.68, racketHeadOffset = 0.47

    static func facing(_ yaw: Double) -> V3 { let r = yaw * .pi / 180; return V3(cos(r), 0, -sin(r)) }
    static func rightSide(_ yaw: Double) -> V3 { let r = yaw * .pi / 180; return V3(sin(r), 0, cos(r)) }

    var rightShoulder: V3 { chest + Self.rightSide(chestYaw) * Self.shoulderHalfWidth }
    var leftShoulder: V3 { chest - Self.rightSide(chestYaw) * Self.shoulderHalfWidth }
    var rightHip: V3 { pelvis + Self.rightSide(hipYaw) * Self.hipHalfWidth }
    var leftHip: V3 { pelvis - Self.rightSide(hipYaw) * Self.hipHalfWidth }
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

    // MARK: Two-bone inverse kinematics
    static let upperArm = 0.3, forearm = 0.27, thigh = 0.45, shin = 0.43

    /// Places elbows and knees so every limb keeps its real length.
    /// Authored elbow and knee points only say which way the joint bends.
    func solved() -> MotionPose {
        var out = self
        (out.rightElbow, out.rightHand) = Self.limb(from: rightShoulder, to: rightHand, hint: rightElbow, upper: Self.upperArm, lower: Self.forearm)
        (out.leftElbow, out.leftHand) = Self.limb(from: leftShoulder, to: leftHand, hint: leftElbow, upper: Self.upperArm, lower: Self.forearm)
        (out.rightKnee, out.rightAnkle) = Self.limb(from: rightHip, to: rightAnkle, hint: rightKnee, upper: Self.thigh, lower: Self.shin)
        (out.leftKnee, out.leftAnkle) = Self.limb(from: leftHip, to: leftAnkle, hint: leftKnee, upper: Self.thigh, lower: Self.shin)
        if ballOnStrings { out.ball = out.racketHeadCenter + out.stringNormal * 0.05; out.ballOnStrings = false }
        return out
    }
    /// Returns the middle joint and the end point, pulled in if the target is out of reach.
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
    private static let points: [WritableKeyPath<MotionPose, V3>] = [\.pelvis, \.chest, \.rightElbow, \.rightHand, \.leftElbow, \.leftHand,
                                                                   \.rightKnee, \.rightAnkle, \.leftKnee, \.leftAnkle, \.racketDir, \.racketFace]
    private static let angles: [WritableKeyPath<MotionPose, Double>] = [\.chestYaw, \.hipYaw]

    /// Catmull-Rom between `b` and `c`, using neighbours `a` and `d`, so joints travel on smooth arcs.
    static func spline(_ a: MotionPose, _ b: MotionPose, _ c: MotionPose, _ d: MotionPose, _ t: Double) -> MotionPose {
        var out = b
        for key in points { out[keyPath: key] = curve(a[keyPath: key], b[keyPath: key], c[keyPath: key], d[keyPath: key], t) }
        for key in angles { out[keyPath: key] = curve(a[keyPath: key], b[keyPath: key], c[keyPath: key], d[keyPath: key], t) }
        // Feet never sink into the court.
        out.rightAnkle.y = max(0.08, out.rightAnkle.y); out.leftAnkle.y = max(0.08, out.leftAnkle.y)
        switch (b.ball, c.ball) {
        case let (from?, to?): out.ball = curve(a.ball ?? from, from, to, d.ball ?? to, t)
        case let (from?, nil): out.ball = t < 0.3 ? from : nil
        case let (nil, to?): out.ball = t > 0.7 ? to : nil
        default: out.ball = nil
        }
        return out
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
    let pose: MotionPose
    /// Seconds to travel to the next key pose: slow preparation, fast swing.
    var duration: Double = 0.7
    init(phase: String, pose: MotionPose, duration: Double = 0.7) {
        self.phase = phase; self.pose = pose.solved(); self.duration = duration
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
    let keyframes: [MotionKeyframe]
    /// Where the player stands: metres from the baseline towards the net.
    var courtX: Double = -0.4
    var defaultCamera: MotionCamera = .side
    var titleKey: String { "motion.title." + id }
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
        guard let first = keyframes.first?.pose else { return StrokeMotion.ready }
        guard keyframes.count > 1 else { return first }
        let (i, local) = timing(at: progress)
        let n = keyframes.count
        func p(_ k: Int) -> MotionPose { keyframes[((k % n) + n) % n].pose }
        // Gentle ease so the swing accelerates through each segment rather than moving at constant speed.
        let eased = local * local * (3 - 2 * local)
        return MotionPose.spline(p(i - 1), p(i), p(i + 1), p(i + 2), eased).solved()
    }
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
    /// True while the racket meets the ball, for the impact flash.
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
    static let ready = MotionPose(
        pelvis: V3(0, 0.88, 0), chest: V3(0.06, 1.38, 0), chestYaw: 0, hipYaw: 0,
        rightElbow: V3(0.2, 1.13, 0.24), rightHand: V3(0.4, 1.04, 0.1), leftElbow: V3(0.2, 1.14, -0.22), leftHand: V3(0.42, 1.08, -0.02),
        rightKnee: V3(0.12, 0.48, 0.27), rightAnkle: V3(0, 0.09, 0.32), leftKnee: V3(0.12, 0.48, -0.27), leftAnkle: V3(0, 0.09, -0.32),
        racketDir: V3(0.6, 0.55, -0.35), racketFace: V3(0, 0, 1))
    static let netReady = ready.with {
        $0.rightElbow = V3(0.2, 1.16, 0.25); $0.rightHand = V3(0.42, 1.2, 0.12)
        $0.leftElbow = V3(0.2, 1.16, -0.22); $0.leftHand = V3(0.42, 1.22, 0.0)
        $0.racketDir = V3(0.35, 0.9, -0.1); $0.racketFace = V3(1, 0, 0)
    }
    static let serveStance = MotionPose(
        pelvis: V3(0, 0.92, 0.02), chest: V3(0.01, 1.42, 0.03), chestYaw: -75, hipYaw: -60,
        rightElbow: V3(0.03, 1.17, 0.29), rightHand: V3(0.12, 1.05, 0.48), leftElbow: V3(0.16, 1.16, 0.16), leftHand: V3(0.16, 1.07, 0.42),
        rightKnee: V3(-0.12, 0.5, 0.2), rightAnkle: V3(-0.22, 0.09, 0.26), leftKnee: V3(0.2, 0.5, -0.06), leftAnkle: V3(0.26, 0.09, -0.08),
        racketDir: V3(0.75, 0.15, 0.45), racketFace: V3(0, 1, 0), ball: V3(0.18, 1.11, 0.44))

    // MARK: Strokes
    static let forehand = StrokeMotion(id: "forehand", keyframes: [
        .init(phase: "motion.phase.ready", pose: ready, duration: 0.9),
        .init(phase: "motion.phase.takeback", pose: ready.with {
            $0.pelvis = V3(0.02, 0.86, 0.02); $0.chest = V3(0.0, 1.36, 0.03); $0.chestYaw = -85; $0.hipYaw = -45
            $0.rightElbow = V3(-0.28, 1.2, 0.3); $0.rightHand = V3(-0.5, 1.22, 0.42); $0.racketDir = V3(-0.75, 0.5, 0.3); $0.racketFace = V3(0, 0, 1)
            $0.leftElbow = V3(0.3, 1.28, 0.04); $0.leftHand = V3(0.52, 1.28, 0.2)
            $0.leftKnee = V3(0.36, 0.48, -0.08); $0.leftAnkle = V3(0.46, 0.09, -0.06); $0.rightKnee = V3(0.08, 0.47, 0.32); $0.rightAnkle = V3(-0.05, 0.09, 0.36)
            $0.ball = V3(5.5, 1.5, 1.1)
        }, duration: 0.75),
        .init(phase: "motion.phase.drop", pose: ready.with {
            $0.pelvis = V3(0.08, 0.84, 0.02); $0.chest = V3(0.05, 1.34, 0.04); $0.chestYaw = -70; $0.hipYaw = -30
            $0.rightElbow = V3(-0.2, 1.06, 0.4); $0.rightHand = V3(-0.3, 0.84, 0.52); $0.racketDir = V3(-0.45, -0.75, 0.3); $0.racketFace = V3(0, 0.2, 1)
            $0.leftElbow = V3(0.3, 1.24, 0.02); $0.leftHand = V3(0.5, 1.16, 0.16)
            $0.leftKnee = V3(0.4, 0.47, -0.08); $0.leftAnkle = V3(0.48, 0.09, -0.06); $0.rightKnee = V3(0.12, 0.46, 0.3); $0.rightAnkle = V3(-0.04, 0.09, 0.36)
            $0.ball = V3(2.4, 1.15, 0.95)
        }, duration: 0.32),
        .init(phase: "motion.phase.contact", pose: ready.with {
            $0.pelvis = V3(0.16, 0.88, 0.0); $0.chest = V3(0.22, 1.38, 0.0); $0.chestYaw = -12; $0.hipYaw = -5
            $0.rightElbow = V3(0.26, 1.12, 0.42); $0.rightHand = V3(0.54, 1.0, 0.56); $0.racketDir = V3(0.28, 0.06, 0.96); $0.racketFace = V3(1, 0.1, 0)
            $0.leftElbow = V3(0.22, 1.18, -0.3); $0.leftHand = V3(0.18, 1.06, -0.4)
            $0.leftKnee = V3(0.42, 0.5, -0.07); $0.leftAnkle = V3(0.48, 0.09, -0.06); $0.rightKnee = V3(0.26, 0.5, 0.22); $0.rightAnkle = V3(0.05, 0.13, 0.32)
            $0.ballOnStrings = true
        }, duration: 0.22),
        .init(phase: "motion.phase.finish", pose: ready.with {
            $0.pelvis = V3(0.2, 0.9, -0.02); $0.chest = V3(0.28, 1.4, -0.02); $0.chestYaw = 35; $0.hipYaw = 15
            $0.rightElbow = V3(0.48, 1.46, -0.1); $0.rightHand = V3(0.26, 1.58, -0.32); $0.racketDir = V3(-0.62, 0.32, -0.55); $0.racketFace = V3(0, 1, 0)
            $0.leftElbow = V3(0.24, 1.2, -0.42); $0.leftHand = V3(0.3, 1.4, -0.34)
            $0.leftKnee = V3(0.44, 0.5, -0.06); $0.leftAnkle = V3(0.48, 0.09, -0.06); $0.rightKnee = V3(0.3, 0.48, 0.12); $0.rightAnkle = V3(0.16, 0.15, 0.24)
            $0.ball = V3(5.5, 1.5, -0.9)
        }, duration: 0.8),
    ])
    static let backhand = StrokeMotion(id: "backhand", keyframes: [
        .init(phase: "motion.phase.ready", pose: ready, duration: 0.9),
        .init(phase: "motion.phase.takeback", pose: ready.with {
            $0.pelvis = V3(0.02, 0.86, -0.02); $0.chest = V3(0.0, 1.36, -0.03); $0.chestYaw = 88; $0.hipYaw = 50
            $0.rightElbow = V3(0.02, 1.12, -0.24); $0.rightHand = V3(-0.25, 1.08, -0.42)
            $0.leftElbow = V3(-0.22, 1.18, -0.24); $0.leftHand = V3(-0.3, 1.1, -0.45)
            $0.racketDir = V3(-0.4, 0.75, -0.3); $0.racketFace = V3(0, 0, -1)
            $0.rightKnee = V3(0.36, 0.48, 0.08); $0.rightAnkle = V3(0.46, 0.09, 0.06); $0.leftKnee = V3(0.08, 0.47, -0.32); $0.leftAnkle = V3(-0.05, 0.09, -0.36)
            $0.ball = V3(5.5, 1.5, -1.1)
        }, duration: 0.75),
        .init(phase: "motion.phase.contact", pose: ready.with {
            $0.pelvis = V3(0.16, 0.88, 0.0); $0.chest = V3(0.22, 1.38, -0.02); $0.chestYaw = 15; $0.hipYaw = 8
            $0.rightElbow = V3(0.38, 1.12, -0.16); $0.rightHand = V3(0.5, 1.0, -0.4)
            $0.leftElbow = V3(0.18, 1.12, -0.38); $0.leftHand = V3(0.47, 1.03, -0.36)
            $0.racketDir = V3(0.25, 0.05, -0.97); $0.racketFace = V3(1, 0.1, 0)
            $0.rightKnee = V3(0.44, 0.5, 0.07); $0.rightAnkle = V3(0.48, 0.09, 0.06); $0.leftKnee = V3(0.26, 0.5, -0.22); $0.leftAnkle = V3(0.05, 0.13, -0.32)
            $0.ballOnStrings = true
        }, duration: 0.22),
        .init(phase: "motion.phase.finish", pose: ready.with {
            $0.pelvis = V3(0.2, 0.9, 0.02); $0.chest = V3(0.28, 1.4, 0.02); $0.chestYaw = -40; $0.hipYaw = -15
            $0.rightElbow = V3(0.5, 1.4, 0.2); $0.rightHand = V3(0.36, 1.58, 0.36)
            $0.leftElbow = V3(0.38, 1.3, 0.0); $0.leftHand = V3(0.34, 1.55, 0.3)
            $0.racketDir = V3(-0.6, 0.35, 0.6); $0.racketFace = V3(0, 1, 0)
            $0.rightKnee = V3(0.44, 0.5, 0.06); $0.rightAnkle = V3(0.48, 0.09, 0.06); $0.leftKnee = V3(0.3, 0.48, -0.12); $0.leftAnkle = V3(0.16, 0.15, -0.24)
            $0.ball = V3(5.5, 1.5, 0.9)
        }, duration: 0.8),
    ])
    static let serve = StrokeMotion(id: "serve", keyframes: [
        .init(phase: "motion.phase.stance", pose: serveStance, duration: 0.8),
        .init(phase: "motion.phase.trophy", pose: serveStance.with {
            $0.pelvis = V3(0.04, 0.8, 0.02); $0.chest = V3(-0.04, 1.3, 0.04); $0.chestYaw = -80
            $0.leftElbow = V3(0.1, 1.62, 0.0); $0.leftHand = V3(0.24, 1.9, 0.0)
            $0.rightElbow = V3(-0.24, 1.36, 0.34); $0.rightHand = V3(-0.26, 1.64, 0.3); $0.racketDir = V3(0.05, 0.95, 0.15); $0.racketFace = V3(0, 0, 1)
            $0.rightKnee = V3(-0.02, 0.47, 0.22); $0.leftKnee = V3(0.32, 0.46, -0.04)
            $0.ball = V3(0.36, 2.55, 0.02)
        }, duration: 0.6),
        .init(phase: "motion.phase.racketdrop", pose: serveStance.with {
            $0.pelvis = V3(0.1, 0.86, 0.02); $0.chest = V3(0.06, 1.36, 0.04); $0.chestYaw = -55
            $0.leftElbow = V3(0.24, 1.48, -0.1); $0.leftHand = V3(0.32, 1.6, -0.3)
            $0.rightElbow = V3(-0.02, 1.62, 0.28); $0.rightHand = V3(-0.18, 1.42, 0.2); $0.racketDir = V3(-0.15, -0.95, -0.1); $0.racketFace = V3(1, 0, 0)
            $0.rightKnee = V3(0.0, 0.5, 0.22); $0.leftKnee = V3(0.34, 0.48, -0.04)
            $0.ball = V3(0.46, 2.78, 0.04)
        }, duration: 0.3),
        .init(phase: "motion.phase.contact", pose: serveStance.with {
            $0.pelvis = V3(0.26, 0.98, 0.0); $0.chest = V3(0.36, 1.48, 0.02); $0.chestYaw = -20; $0.hipYaw = -25
            $0.rightElbow = V3(0.4, 1.83, 0.14); $0.rightHand = V3(0.47, 2.12, 0.1); $0.racketDir = V3(0.25, 0.97, -0.05); $0.racketFace = V3(1, -0.2, 0)
            $0.leftElbow = V3(0.32, 1.27, -0.18); $0.leftHand = V3(0.4, 1.12, -0.04)
            $0.rightKnee = V3(0.18, 0.62, 0.16); $0.rightAnkle = V3(0.0, 0.26, 0.2); $0.leftKnee = V3(0.4, 0.56, -0.06); $0.leftAnkle = V3(0.38, 0.17, -0.06)
            $0.ballOnStrings = true
        }, duration: 0.22),
        .init(phase: "motion.phase.finish", pose: serveStance.with {
            $0.pelvis = V3(0.62, 0.84, -0.04); $0.chest = V3(0.84, 1.29, -0.06); $0.chestYaw = 30; $0.hipYaw = 10
            $0.rightElbow = V3(0.84, 1.0, -0.28); $0.rightHand = V3(0.66, 0.84, -0.46); $0.racketDir = V3(-0.4, -0.5, -0.75); $0.racketFace = V3(0, 1, 0)
            $0.leftElbow = V3(0.7, 1.1, -0.36); $0.leftHand = V3(0.78, 0.96, -0.5)
            $0.leftKnee = V3(0.82, 0.47, -0.08); $0.leftAnkle = V3(0.8, 0.09, -0.06); $0.rightKnee = V3(0.38, 0.6, 0.16); $0.rightAnkle = V3(0.18, 0.34, 0.2)
            $0.ball = V3(6.5, 1.6, -1.2)
        }, duration: 0.9),
    ])
    static let volley = StrokeMotion(id: "volley", keyframes: [
        .init(phase: "motion.phase.ready", pose: netReady, duration: 0.8),
        .init(phase: "motion.phase.turn", pose: netReady.with {
            $0.chestYaw = -35; $0.hipYaw = -15
            $0.rightElbow = V3(0.04, 1.18, 0.4); $0.rightHand = V3(0.24, 1.3, 0.46); $0.racketDir = V3(0.1, 0.9, 0.4); $0.racketFace = V3(1, 0, 0)
            $0.leftElbow = V3(0.24, 1.18, -0.06); $0.leftHand = V3(0.42, 1.24, 0.14)
            $0.ball = V3(3.2, 1.35, 0.75)
        }, duration: 0.35),
        .init(phase: "motion.phase.punch", pose: netReady.with {
            $0.pelvis = V3(0.2, 0.84, 0.0); $0.chest = V3(0.3, 1.33, 0.0); $0.chestYaw = -20; $0.hipYaw = -10
            $0.rightElbow = V3(0.38, 1.12, 0.44); $0.rightHand = V3(0.6, 1.24, 0.5); $0.racketDir = V3(0.3, 0.75, 0.6); $0.racketFace = V3(1, -0.1, 0)
            $0.leftElbow = V3(0.36, 1.14, -0.2); $0.leftHand = V3(0.56, 1.12, -0.06)
            $0.leftKnee = V3(0.56, 0.48, -0.12); $0.leftAnkle = V3(0.62, 0.09, -0.1); $0.rightKnee = V3(0.24, 0.47, 0.28); $0.rightAnkle = V3(0.04, 0.12, 0.33)
            $0.ballOnStrings = true
        }, duration: 0.35),
        .init(phase: "motion.phase.recover", pose: netReady.with { $0.ball = V3(5.5, 1.0, -0.5) }, duration: 0.6),
    ], courtX: 8.6)
    static let overhead = StrokeMotion(id: "overhead", keyframes: [
        .init(phase: "motion.phase.ready", pose: netReady, duration: 0.7),
        .init(phase: "motion.phase.point", pose: serveStance.with {
            $0.pelvis = V3(-0.3, 0.88, 0.04); $0.chest = V3(-0.32, 1.38, 0.05); $0.chestYaw = -80; $0.hipYaw = -65
            $0.leftElbow = V3(-0.12, 1.6, 0.02); $0.leftHand = V3(0.04, 1.88, 0.02)
            $0.rightElbow = V3(-0.54, 1.38, 0.36); $0.rightHand = V3(-0.56, 1.66, 0.32); $0.racketDir = V3(0.05, 0.95, 0.15); $0.racketFace = V3(0, 0, 1)
            $0.rightKnee = V3(-0.42, 0.49, 0.25); $0.rightAnkle = V3(-0.56, 0.09, 0.28); $0.leftKnee = V3(-0.06, 0.49, -0.1); $0.leftAnkle = V3(0.0, 0.09, -0.12)
            $0.ball = V3(0.3, 3.4, 0.05)
        }, duration: 0.7),
        .init(phase: "motion.phase.contact", pose: serveStance.with {
            $0.pelvis = V3(0.0, 0.94, 0.02); $0.chest = V3(0.1, 1.44, 0.03); $0.chestYaw = -20; $0.hipYaw = -30
            $0.rightElbow = V3(0.14, 1.79, 0.15); $0.rightHand = V3(0.21, 2.08, 0.1); $0.racketDir = V3(0.25, 0.97, -0.05); $0.racketFace = V3(1, -0.2, 0)
            $0.leftElbow = V3(0.06, 1.23, -0.18); $0.leftHand = V3(0.14, 1.08, -0.04)
            $0.rightKnee = V3(-0.14, 0.5, 0.22); $0.rightAnkle = V3(-0.3, 0.1, 0.26); $0.leftKnee = V3(0.2, 0.49, -0.08); $0.leftAnkle = V3(0.24, 0.09, -0.1)
            $0.ballOnStrings = true
        }, duration: 0.22),
        .init(phase: "motion.phase.finish", pose: serveStance.with {
            $0.pelvis = V3(0.24, 0.86, -0.04); $0.chest = V3(0.4, 1.33, -0.06); $0.chestYaw = 30; $0.hipYaw = 5
            $0.rightElbow = V3(0.42, 1.05, -0.3); $0.rightHand = V3(0.3, 0.84, -0.48); $0.racketDir = V3(-0.4, -0.5, -0.75); $0.racketFace = V3(0, 1, 0)
            $0.leftElbow = V3(0.3, 1.12, -0.38); $0.leftHand = V3(0.4, 0.96, -0.5)
            $0.leftKnee = V3(0.42, 0.48, -0.1); $0.leftAnkle = V3(0.42, 0.09, -0.1); $0.rightKnee = V3(0.06, 0.5, 0.2); $0.rightAnkle = V3(-0.06, 0.13, 0.26)
            $0.ball = V3(6, 0.9, -1.2)
        }, duration: 0.8),
    ], courtX: 8.0)
    static let split = StrokeMotion(id: "split", keyframes: [
        .init(phase: "motion.phase.ready", pose: ready.with {
            $0.pelvis = V3(0, 0.92, 0); $0.chest = V3(0.05, 1.42, 0)
            $0.rightKnee = V3(0.08, 0.5, 0.2); $0.rightAnkle = V3(0, 0.09, 0.22); $0.leftKnee = V3(0.08, 0.5, -0.2); $0.leftAnkle = V3(0, 0.09, -0.22)
            $0.rightElbow = V3(0.2, 1.17, 0.24); $0.rightHand = V3(0.4, 1.08, 0.1); $0.leftElbow = V3(0.2, 1.18, -0.22); $0.leftHand = V3(0.42, 1.12, -0.02)
        }, duration: 0.6),
        .init(phase: "motion.phase.hop", pose: ready.with {
            $0.pelvis = V3(0, 1.04, 0); $0.chest = V3(0.05, 1.54, 0)
            $0.rightKnee = V3(0.1, 0.62, 0.18); $0.rightAnkle = V3(0, 0.22, 0.18); $0.leftKnee = V3(0.1, 0.62, -0.18); $0.leftAnkle = V3(0, 0.22, -0.18)
            $0.rightElbow = V3(0.2, 1.29, 0.24); $0.rightHand = V3(0.4, 1.2, 0.1); $0.leftElbow = V3(0.2, 1.3, -0.22); $0.leftHand = V3(0.42, 1.24, -0.02)
        }, duration: 0.3),
        .init(phase: "motion.phase.land", pose: ready.with {
            $0.pelvis = V3(-0.02, 0.8, 0); $0.chest = V3(0.06, 1.29, 0)
            $0.rightKnee = V3(0.14, 0.44, 0.36); $0.rightAnkle = V3(0, 0.09, 0.44); $0.leftKnee = V3(0.14, 0.44, -0.36); $0.leftAnkle = V3(0, 0.09, -0.44)
            $0.rightElbow = V3(0.2, 1.04, 0.24); $0.rightHand = V3(0.4, 0.96, 0.1); $0.leftElbow = V3(0.2, 1.05, -0.22); $0.leftHand = V3(0.42, 0.99, -0.02)
        }, duration: 0.35),
        .init(phase: "motion.phase.firststep", pose: ready.with {
            $0.pelvis = V3(0.0, 0.83, 0.38); $0.chest = V3(0.05, 1.31, 0.46); $0.chestYaw = -35; $0.hipYaw = -45
            $0.rightKnee = V3(0.16, 0.46, 0.88); $0.rightAnkle = V3(0.12, 0.09, 1.02); $0.leftKnee = V3(0.06, 0.46, 0.12); $0.leftAnkle = V3(-0.06, 0.12, 0.0)
            $0.rightElbow = V3(0.04, 1.08, 0.7); $0.rightHand = V3(0.24, 1.02, 0.78); $0.leftElbow = V3(0.18, 1.09, 0.2); $0.leftHand = V3(0.38, 1.04, 0.36)
            $0.racketDir = V3(0.55, 0.6, 0.2)
        }, duration: 0.7),
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
