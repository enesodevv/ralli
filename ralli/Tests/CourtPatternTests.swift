import XCTest

final class CourtPatternTests: XCTestCase {
    func testEveryPracticePatternStaysInsideCourtDiagram() {
        for plan in PracticePlan.library {
            let route = CourtPattern.route(for: plan.visual)
            XCTAssertGreaterThan(route.count, 1)
            for value in stride(from: 0.0, through: 1.0, by: 0.01) {
                let point = CourtPattern.position(on: route, progress: value)
                XCTAssertTrue((0...1).contains(point.x), plan.id)
                XCTAssertTrue((0...1).contains(point.y), plan.id)
            }
            XCTAssertEqual(CourtPattern.position(on: route, progress: -1), route.first)
            XCTAssertEqual(CourtPattern.position(on: route, progress: 2), route.last)
        }
    }
    func testInvalidTimelineInputDoesNotCreateInvalidCoordinates() {
        let route = CourtPattern.route(for: "footwork")
        XCTAssertEqual(CourtPattern.position(on: route, progress: .nan), route.first)
        XCTAssertEqual(CourtPattern.position(on: [], progress: 0.5), CourtPosition(x: 0.5, y: 0.5))
        let point = CourtPosition(x: 0.3, y: 0.7)
        XCTAssertEqual(CourtPattern.position(on: [point, point], progress: 0.5), point)
        for plan in PracticePlan.library {
            XCTAssertEqual(plan.coachingURL?.scheme, "https")
            XCTAssertEqual(plan.coachingURL?.host, "www.lta.org.uk")
        }
    }
}
