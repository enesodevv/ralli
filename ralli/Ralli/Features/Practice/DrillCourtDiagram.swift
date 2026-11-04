import SwiftUI

struct DrillCourtDiagram: View {
    let pattern: String
    var progress: Double? = nil
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Path { p in
                p.addRect(CGRect(x: w * 0.12, y: h * 0.07, width: w * 0.76, height: h * 0.86))
                for x in [0.23, 0.77] { p.move(to: CGPoint(x: w*x, y: h*0.07)); p.addLine(to: CGPoint(x: w*x, y: h*0.93)) }
                for y in [0.29, 0.5, 0.71] { p.move(to: CGPoint(x: w*0.23, y: h*y)); p.addLine(to: CGPoint(x: w*0.77, y: h*y)) }
                p.move(to: CGPoint(x: w*0.5, y: h*0.29)); p.addLine(to: CGPoint(x: w*0.5, y: h*0.71))
            }.stroke(.white.opacity(0.4), lineWidth: 1)
            if pattern == "depth" || pattern == "return" || pattern == "approach" {
                Rectangle().fill(RalliTheme.lime.opacity(0.25)).frame(width: w*0.54, height: h*0.22).position(x: w*0.5, y: h*0.18)
            }
            if pattern == "serve" {
                Rectangle().fill(RalliTheme.lime.opacity(0.35)).frame(width: w*0.135, height: h*0.21).position(x: w*0.7025, y: h*0.395)
            }
            if pattern == "wall" {
                Path { p in p.move(to: CGPoint(x: w*0.12, y: h*0.15)); p.addLine(to: CGPoint(x: w*0.88, y: h*0.15)) }.stroke(RalliTheme.lime, lineWidth: 4)
            }
            if pattern == "footwork" {
                ForEach(0..<5) { index in
                    let points: [(Double,Double)] = [(0.23,0.93),(0.23,0.71),(0.5,0.71),(0.77,0.71),(0.77,0.93)]
                    Circle().fill(RalliTheme.lime).frame(width: 7,height: 7).position(x: w*points[index].0,y:h*points[index].1)
                }
            }
            let route = CourtPattern.route(for: pattern)
            Path { p in
                guard let first = route.first else { return }
                p.move(to: CGPoint(x: w * first.x, y: h * first.y))
                for point in route.dropFirst() { p.addLine(to: CGPoint(x: w * point.x, y: h * point.y)) }
            }.stroke(RalliTheme.lime, style: StrokeStyle(lineWidth: 2, dash: [5,5]))
            let marker = CourtPattern.position(on: route, progress: progress ?? 1)
            Circle().fill(RalliTheme.lime).frame(width: 12, height: 12).position(x: w * marker.x, y: h * marker.y)

        }.accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.text(pattern == "wall" ? "practice.diagram.wall" : (pattern == "footwork" ? "practice.diagram.footwork" : "practice.diagram")))
    }
}
