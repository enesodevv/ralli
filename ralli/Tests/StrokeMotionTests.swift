import XCTest

final class StrokeMotionTests: XCTestCase {
    func testEveryFrameStaysInsideTheFigureBox() {
        for motion in StrokeMotion.all {
            for value in stride(from: 0.0, through: 1.0, by: 0.005) {
                for point in motion.pose(at: value).allPoints {
                    XCTAssertTrue(point.isInsideFrame, "\(motion.id) at \(value): \(point)")
                }
            }
        }
    }
    func testCyclesLoopSeamlessly() {
        for motion in StrokeMotion.all {
            XCTAssertGreaterThanOrEqual(motion.keyframes.count, 4, motion.id)
            let first = motion.keyframes[0].pose, last = motion.keyframes[motion.keyframes.count - 1].pose
            XCTAssertEqual(first.head, last.head, motion.id)
            XCTAssertEqual(first.hittingHand, last.hittingHand, motion.id)
            XCTAssertEqual(motion.pose(at: 0), first, motion.id)
            XCTAssertTrue(motion.keyframes.contains { $0.pose.ball != nil } || motion.id == "split", motion.id)
        }
    }
    func testPhaseIndexAndBadInputStayInRange() {
        for motion in StrokeMotion.all {
            for value in [-0.3, 0, 0.5, 0.999, 1, 7.25, .nan, .infinity] {
                XCTAssertTrue(motion.keyframes.indices.contains(motion.phaseIndex(at: value)), "\(motion.id) \(value)")
                XCTAssertTrue(motion.pose(at: value).allPoints.allSatisfy(\.isInsideFrame), "\(motion.id) \(value)")
            }
        }
    }
    func testEveryDrillHasAMotionWithLocalisedPhases() throws {
        for plan in PracticePlan.library { XCTAssertTrue(StrokeMotion.all.contains(plan.strokeMotion), plan.id) }
        let testFile = URL(fileURLWithPath: #filePath)
        for language in ["en", "tr"] {
            let url = testFile.deletingLastPathComponent().deletingLastPathComponent()
                .appendingPathComponent("Ralli/Resources/\(language).lproj/Localizable.strings")
            let strings = try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String], language)
            for motion in StrokeMotion.all {
                XCTAssertNotNil(strings[motion.titleKey], "\(language) \(motion.titleKey)")
                XCTAssertNotNil(strings["motion.description." + motion.id], "\(language) \(motion.id)")
                for frame in motion.keyframes { XCTAssertNotNil(strings[frame.phase], "\(language) \(frame.phase)") }
            }
        }
    }
}
