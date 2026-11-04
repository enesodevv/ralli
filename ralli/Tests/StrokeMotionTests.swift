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
        let contact = try! XCTUnwrap(StrokeMotion.forehand.keyframes.firstIndex { $0.phase == "motion.phase.contact" })
        XCTAssertNotNil(StrokeMotion.forehand.impact(at: StrokeMotion.forehand.progress(atKeyframe: contact) + 0.005))
        XCTAssertNil(StrokeMotion.forehand.impact(at: 0.1))
    }
    func testEveryDrillHasAMotionWithLocalisedText() throws {
        for plan in PracticePlan.library { XCTAssertTrue(StrokeMotion.all.contains(plan.strokeMotion), plan.id) }
        let testFile = URL(fileURLWithPath: #filePath)
        for language in ["en", "tr", "es", "de", "fr", "it"] {
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

    /// A left-hander is an exact mirror image of the right-hander at every moment.
    func testLeftHandedMotionsMirrorEveryFrame() {
        for motion in StrokeMotion.all {
            let lefty = motion.mirrored()
            XCTAssertTrue(lefty.isLeftHanded, motion.id)
            for value in stride(from: 0.0, to: 1.0, by: 0.01) {
                let right = motion.pose(at: value), left = lefty.pose(at: value)
                for (a, b, name) in [(right.rightHand, left.rightHand, "hitting hand"), (right.racketTip, left.racketTip, "racket tip"),
                                     (right.rightShoulder, left.rightShoulder, "hitting shoulder"), (right.leftAnkle, left.leftAnkle, "front foot")] {
                    XCTAssertEqual(a.x, b.x, accuracy: 0.002, "\(motion.id) \(name) @\(value)")
                    XCTAssertEqual(a.y, b.y, accuracy: 0.002, "\(motion.id) \(name) @\(value)")
                    XCTAssertEqual(a.z, -b.z, accuracy: 0.002, "\(motion.id) \(name) @\(value)")
                }
            }
            XCTAssertFalse(lefty.mirrored().isLeftHanded, motion.id)
        }
    }
    func testOlderPreferencesWithoutHandednessStillDecode() throws {
        let old = #"{"focus":"Servis","mode":"solo","minutes":20,"hasWall":false,"level":"foundation","configured":true}"#
        let decoded = try JSONDecoder().decode(PlayerPreferences.self, from: Data(old.utf8))
        XCTAssertFalse(decoded.isLeftHanded)
        XCTAssertEqual(decoded.focus, "Servis")
    }

    /// Every language ships the same keys with the same format arguments as English, plus permission texts.
    func testEveryLanguageMatchesEnglish() throws {
        let resources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Ralli/Resources")
        func load(_ language: String, _ file: String) throws -> [String: String] {
            try XCTUnwrap(NSDictionary(contentsOf: resources.appendingPathComponent("\(language).lproj/\(file)")) as? [String: String], "\(language) \(file)")
        }
        let english = try load("en", "Localizable.strings")
        let format = try NSRegularExpression(pattern: "%[@d]")
        func formats(_ text: String) -> [String] {
            format.matches(in: text, range: NSRange(text.startIndex..., in: text)).map { (text as NSString).substring(with: $0.range) }.sorted()
        }
        for language in ["tr", "es", "de", "fr", "it"] {
            let strings = try load(language, "Localizable.strings")
            XCTAssertEqual(Set(strings.keys), Set(english.keys), language)
            for (key, value) in english { XCTAssertEqual(formats(strings[key] ?? ""), formats(value), "\(language) \(key)") }
            let plist = try load(language, "InfoPlist.strings")
            XCTAssertNotNil(plist["NSMicrophoneUsageDescription"], language)
            XCTAssertNotNil(plist["NSSpeechRecognitionUsageDescription"], language)
        }
    }
}
