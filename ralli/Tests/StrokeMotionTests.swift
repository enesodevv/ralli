import XCTest

final class StrokeMotionTests: XCTestCase {
    /// Authored key poses must have human proportions: no stretched arms or folded legs.
    func testKeyPosesHaveHumanProportions() {
        var problems: [String] = []
        for motion in StrokeMotion.all {
            for frame in motion.keyframes {
                for bone in frame.pose.bones {
                    let length = bone.from.distance(to: bone.to)
                    if !bone.range.contains(length) { problems.append("\(motion.id) \(frame.phase) \(bone.name): \(String(format: "%.3f", length))") }
                }
            }
        }
        XCTAssertTrue(problems.isEmpty, problems.joined(separator: "\n"))
    }
    /// Between key poses the spline may bend lengths slightly, but never grotesquely.
    func testInBetweenFramesStayBelievable() {
        var problems: [String] = []
        for motion in StrokeMotion.all {
            for value in stride(from: 0.0, to: 1.0, by: 0.004) {
                let pose = motion.pose(at: value)
                for bone in pose.bones {
                    let length = bone.from.distance(to: bone.to)
                    if length < bone.range.lowerBound * 0.8 || length > bone.range.upperBound * 1.2 {
                        problems.append("\(motion.id) @\(String(format: "%.3f", value)) \(bone.name): \(String(format: "%.3f", length))")
                    }
                }
                if pose.rightAnkle.y < 0.079 || pose.leftAnkle.y < 0.079 { problems.append("\(motion.id) @\(value) foot below court") }
                if pose.head.y < pose.chest.y || pose.chest.y < pose.pelvis.y { problems.append("\(motion.id) @\(value) body upside down") }
                if pose.racketTip.y < 0.02 { problems.append("\(motion.id) @\(value) racket into the court") }
            }
        }
        XCTAssertTrue(problems.prefix(30).isEmpty, problems.prefix(30).joined(separator: "\n"))
    }
    func testTimingAndBadInputStayInRange() {
        for motion in StrokeMotion.all {
            XCTAssertGreaterThanOrEqual(motion.keyframes.count, 4, motion.id)
            XCTAssertGreaterThan(motion.cycleDuration, 1.5, motion.id)
            XCTAssertLessThan(motion.pose(at: 0).rightHand.distance(to: motion.keyframes[0].pose.rightHand), 0.001, motion.id)
            for value in [-0.3, 0, 0.5, 0.999, 1, 7.25, .nan, .infinity] {
                XCTAssertTrue(motion.keyframes.indices.contains(motion.phaseIndex(at: value)), "\(motion.id) \(value)")
                let pose = motion.pose(at: value)
                XCTAssertTrue(([pose.head, pose.racketTip, pose.leftToe] + (pose.ball.map { [$0] } ?? [])).allSatisfy(\.isFinite), "\(motion.id) \(value)")
            }
            XCTAssertTrue(motion.keyframes.contains { $0.pose.ball != nil } || motion.id == "split", motion.id)
        }
        XCTAssertNotNil(StrokeMotion.forehand.impact(at: 0.665))
        XCTAssertNil(StrokeMotion.forehand.impact(at: 0.1))
    }
    func testEveryDrillHasAMotionWithLocalisedText() throws {
        for plan in PracticePlan.library { XCTAssertTrue(StrokeMotion.all.contains(plan.strokeMotion), plan.id) }
        let testFile = URL(fileURLWithPath: #filePath)
        for language in ["en", "tr"] {
            let url = testFile.deletingLastPathComponent().deletingLastPathComponent()
                .appendingPathComponent("Ralli/Resources/\(language).lproj/Localizable.strings")
            let strings = try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String], language)
            for camera in MotionCamera.allCases { XCTAssertNotNil(strings[camera.titleKey], "\(language) \(camera.titleKey)") }
            for motion in StrokeMotion.all {
                XCTAssertNotNil(strings[motion.titleKey], "\(language) \(motion.titleKey)")
                XCTAssertNotNil(strings["motion.description." + motion.id], "\(language) \(motion.id)")
                for frame in motion.keyframes { XCTAssertNotNil(strings[frame.phase], "\(language) \(frame.phase)") }
            }
        }
    }
}
