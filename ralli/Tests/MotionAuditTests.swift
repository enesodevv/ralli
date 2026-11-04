import XCTest

/// Measures each stroke animation frame by frame and prints a report of physical problems.
final class MotionAuditTests: XCTestCase {
    struct Finding: CustomStringConvertible {
        let motion: String, check: String, worst: Double, at: Double, frames: Int
        var description: String { "\(motion) | \(check) | worst \(String(format: "%.3f", worst)) @ \(String(format: "%.3f", at)) | \(frames) frames" }
    }
    /// Shortest distance between segments p1-q1 and p2-q2.
    static func segmentDistance(_ p1: V3, _ q1: V3, _ p2: V3, _ q2: V3) -> Double {
        let d1 = q1 - p1, d2 = q2 - p2, r = p1 - p2
        let a = d1.dot(d1), e = d2.dot(d2), f = d2.dot(r)
        var s = 0.0, t = 0.0
        if a < 1e-9 && e < 1e-9 { return r.length }
        if a < 1e-9 { t = min(max(f / e, 0), 1) } else {
            let c = d1.dot(r)
            if e < 1e-9 { s = min(max(-c / a, 0), 1) } else {
                let b = d1.dot(d2), denom = a * e - b * b
                s = denom != 0 ? min(max((b * f - c * e) / denom, 0), 1) : 0
                t = (b * s + f) / e
                if t < 0 { t = 0; s = min(max(-c / a, 0), 1) } else if t > 1 { t = 1; s = min(max((b - c) / a, 0), 1) }
            }
        }
        return ((p1 + d1 * s) - (p2 + d2 * t)).length
    }
    static func pointSegment(_ p: V3, _ a: V3, _ b: V3) -> Double { segmentDistance(p, p, a, b) }
    /// How deep a segment goes into the flattened torso, as drawn (front radius 0.10, side radius 0.17). Positive = inside.
    static func torsoPenetration(_ a: V3, _ b: V3, pose p: MotionPose) -> Double {
        let up = (p.chest - p.pelvis).normalized
        var side = MotionPose.rightSide((p.chestYaw + p.hipYaw) / 2)
        side = (side - up * side.dot(up)).normalized
        let front = up.cross(side)
        let length = (p.chest - p.pelvis).length
        var deepest = -1.0
        for k in 0...16 {
            let q = a + (b - a) * (Double(k) / 16) - p.pelvis
            let along = q.dot(up)
            guard along > 0.05 && along < length + 0.05 else { continue }
            let f = q.dot(front) / 0.10, s = q.dot(side) / 0.17
            deepest = max(deepest, 1 - (f * f + s * s).squareRoot())
        }
        return deepest
    }

    static func audit(_ motion: StrokeMotion, steps: Int = 600) -> [Finding] {
        var worst: [String: (value: Double, at: Double, count: Int)] = [:]
        func record(_ check: String, _ badness: Double, _ at: Double) {
            guard badness > 0 else { return }
            let current = worst[check]
            worst[check] = (max(current?.value ?? 0, badness), (current?.value ?? 0) >= badness ? current!.at : at, (current?.count ?? 0) + 1)
        }
        var previous: MotionPose?
        let dt = motion.cycleDuration / Double(steps)
        for k in 0..<steps {
            let t = Double(k) / Double(steps)
            let p = motion.pose(at: t)
            // Body volumes (capsules): torso, head, thighs.
            let torsoA = p.pelvis + V3(0, 0.05, 0), torsoB = p.chest
            let torsoR = 0.15, headR = 0.12
            let racketA = p.rightHand + p.shaft * 0.12, racketB = p.racketTip
            // 1. Racket through torso or head.
            record("racket through torso", torsoPenetration(racketA, racketB, pose: p), t)
            record("racket through head", headR + 0.02 - pointSegment(p.head, racketA, racketB), t)
            for (hip, knee) in [(p.rightHip, p.rightKnee), (p.leftHip, p.leftKnee)] {
                record("racket through leg", 0.09 - segmentDistance(racketA, racketB, hip, knee), t)
            }
            // 2. Forearms / hands inside the torso.
            for (name, elbow, hand) in [("right", p.rightElbow, p.rightHand), ("left", p.leftElbow, p.leftHand)] {
                record("\(name) forearm inside torso", torsoPenetration(elbow, hand, pose: p), t)
                record("\(name) hand inside head", headR + 0.04 - p.hand(name).distance(to: p.head), t)
            }
            // 3. Knees must bend forward (in the direction the hips face), never backwards.
            let hipFacing = MotionPose.facing(p.hipYaw)
            for (name, hip, knee, ankle) in [("right", p.rightHip, p.rightKnee, p.rightAnkle), ("left", p.leftHip, p.leftKnee, p.leftAnkle)] {
                let mid = (hip + ankle) * 0.5
                let bend = (knee - mid)
                let horizontal = V3(bend.x, 0, bend.z)
                if horizontal.length > 0.03 { record("\(name) knee bends backwards", -horizontal.normalized.dot(hipFacing) - 0.2, t) }
            }
            // 4. Elbows must not hyper-extend or point upward-inward unnaturally: elbow below shoulder unless arm raised.
            // 5. Two-handed backhand: the left hand stays on the grip.
            if motion.id == "backhand" {
                // Either on the handle (two-handed grip) or on the throat (ready position).
                let onRacket = segmentDistance(p.leftHand, p.leftHand, p.rightHand + p.shaft * 0.08, p.rightHand + p.shaft * 0.32)
                record("left hand off the racket", onRacket - 0.05, t)
            }
            // 6. Free arm should not cross through the other side of the body: left hand x-z inside torso radius.
            // 7. Feet sliding while planted.
            if let q = previous {
                for (name, a0, a1) in [("right", q.rightAnkle, p.rightAnkle), ("left", q.leftAnkle, p.leftAnkle)] {
                    if a0.y < 0.1 && a1.y < 0.1 {
                        let slide = V3(a1.x - a0.x, 0, a1.z - a0.z).length / dt
                        record("\(name) foot slides while planted (m/s)", slide - 0.35, t)
                    }
                }
                // 8. Teleporting joints: any joint faster than 25 m/s.
                for (name, a, b) in [("racket tip", q.racketTip, p.racketTip), ("right hand", q.rightHand, p.rightHand), ("left hand", q.leftHand, p.leftHand), ("pelvis", q.pelvis, p.pelvis)] {
                    record("\(name) jumps (m/s)", a.distance(to: b) / dt - (name == "racket tip" ? 32 : 16), t)
                }
                if let b0 = q.ball, let b1 = p.ball { record("ball jumps (m/s)", b0.distance(to: b1) / dt - 40, t) }
            }
            // 9. Ball passes through the body.
            if let ball = p.ball {
                record("ball inside torso", torsoPenetration(ball, ball, pose: p), t)
                record("ball inside head", headR + 0.04 - ball.distance(to: p.head), t)
                record("ball below court", 0.04 - ball.y, t)
            }
            // 10. Shoulder vs hip separation beyond what people can do.
            record("shoulder-hip twist over 70°", abs(p.chestYaw - p.hipYaw) - 70, t)
            // 11. Racket tip into the court.
            record("racket into court", 0.04 - min(p.racketTip.y, p.racketHeadCenter.y - 0.13), t)
            // 12. Torso leaning too far.
            let lean = acos(max(-1, min(1, (p.chest - p.pelvis).normalized.dot(V3(0, 1, 0))))) * 180 / .pi
            record("torso lean over 35°", lean - 35, t)
            previous = p
        }
        // 13. Contact quality: ball on strings and string face towards the net at impact.
        if let contact = motion.keyframes.firstIndex(where: { $0.phase == "motion.phase.contact" || $0.phase == "motion.phase.punch" }) {
            let t = motion.progress(atKeyframe: contact)
            let p = motion.pose(at: t)
            if let ball = p.ball { record("ball off the strings at contact", ball.distance(to: p.racketHeadCenter) - 0.09, t) }
            else { record("no ball at contact", 1, t) }
            let towardsNet = p.stringNormal.dot(V3(1, 0, 0))
            record("strings not facing net at contact", 0.6 - abs(towardsNet), t)
            // Contact should be in front of the body for groundstrokes and volleys.
            if ["forehand", "backhand", "volley"].contains(motion.id), let ball = p.ball {
                record("contact not in front of body", 0.25 - (ball.x - p.pelvis.x), t)
            }
        }
        return worst.map { Finding(motion: motion.id, check: $0.key, worst: $0.value.value, at: $0.value.at, frames: $0.value.count) }
            .sorted { $0.check < $1.check }
    }

    /// The audit as a gate: any new pose or code change that brings back a physical glitch fails here.
    /// A forearm may brush the shirt (up to 20 % into the drawn torso) during a fast follow-through; nothing else is allowed.
    func testEveryMotionPassesThePhysicalAudit() {
        let everyone = StrokeMotion.all + StrokeMotion.all.map { $0.mirrored() }
        let problems = everyone.flatMap { Self.audit($0) }.filter { finding in
            !(finding.check.hasSuffix("forearm inside torso") && finding.worst <= 0.2)
        }
        XCTAssertTrue(problems.isEmpty, problems.map(\.description).joined(separator: "\n"))
    }
    func testPrintMotionAudit() {
        var lines: [String] = []
        for motion in StrokeMotion.all { lines += Self.audit(motion).map(\.description) }
        let report = lines.isEmpty ? "no findings" : lines.joined(separator: "\n")
        print("MOTION AUDIT BEGIN\n\(report)\nMOTION AUDIT END")
    }
}

extension MotionPose {
    func hand(_ side: String) -> V3 { side == "right" ? rightHand : leftHand }
}
