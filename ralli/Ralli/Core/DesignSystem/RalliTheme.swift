import SwiftUI

enum RalliTheme {
    static let paper = Color(hex: 0xF5F1E8)
    static let ink = Color(hex: 0x24382D)
    static let muted = Color(hex: 0x5D675C)
    static let clay = Color(hex: 0x9C432F)
    static let lime = Color(hex: 0xD9E896)
    static let line = Color(hex: 0xDADDD0)
    /// Card surface on paper. One value keeps every card the same.
    static let surface = Color.white.opacity(0.8)
    static let radius: CGFloat = 20
    static let smallRadius: CGFloat = 14
    static func title(_ size: CGFloat) -> Font { .custom("Georgia", size: size, relativeTo: .largeTitle) }
}
extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
}
struct Eyebrow: View {
    let text: String
    var color: Color = RalliTheme.muted
    var body: some View {
        Text(L10n.text(text).uppercased(with: L10n.locale)).ralliFont(size: 10, weight: .semibold, design: .monospaced).tracking(2).foregroundStyle(color)
    }
}
struct SectionHeading: View {
    let title: String
    var detail: String = ""
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(L10n.text(title)).font(RalliTheme.title(27)).accessibilityAddTraits(.isHeader)
            Spacer()
            Text(L10n.text(detail)).ralliFont(size: 11, design: .monospaced).foregroundStyle(RalliTheme.muted)
        }.foregroundStyle(RalliTheme.ink)
    }
}
struct PrimaryButton: View {
    @Environment(\.dynamicTypeSize) private var textSize
    let title: String
    var icon = "arrow.up.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Text(L10n.text(title)); Spacer(minLength: 0); if !textSize.isAccessibilitySize { Image(systemName: icon).accessibilityHidden(true) } }
                .ralliFont(size: 15, weight: .semibold).padding(20)
                .foregroundStyle(RalliTheme.paper).background(RalliTheme.ink, in: RoundedRectangle(cornerRadius: RalliTheme.smallRadius))
        }.buttonStyle(.plain)
    }
}
struct CourtArt: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Path { p in
                let court = CGRect(x: w * 0.13, y: h * 0.08, width: w * 0.74, height: h * 0.84)
                p.addRect(court)
                p.move(to: CGPoint(x: w * 0.23, y: court.minY)); p.addLine(to: CGPoint(x: w * 0.23, y: court.maxY))
                p.move(to: CGPoint(x: w * 0.77, y: court.minY)); p.addLine(to: CGPoint(x: w * 0.77, y: court.maxY))
                p.move(to: CGPoint(x: court.minX, y: h * 0.5)); p.addLine(to: CGPoint(x: court.maxX, y: h * 0.5))
                p.addRect(CGRect(x: w * 0.23, y: h * 0.29, width: w * 0.54, height: h * 0.42))
                p.move(to: CGPoint(x: w * 0.5, y: h * 0.29)); p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.71))
            }.stroke(.white.opacity(0.55), lineWidth: 1)
            Path { p in
                p.move(to: CGPoint(x: w * 0.3, y: h * 0.8))
                p.addQuadCurve(to: CGPoint(x: w * 0.68, y: h * 0.23), control: CGPoint(x: w * 0.12, y: h * 0.25))
            }.stroke(RalliTheme.lime, style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
            Circle().fill(RalliTheme.lime).frame(width: 12, height: 12).position(x: w * 0.68, y: h * 0.23)
        }.accessibilityHidden(true)
    }
}

private struct ScaledRalliFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    init(size: CGFloat, weight: Font.Weight, design: Font.Design) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: .body)
        self.weight = weight; self.design = design
    }
    func body(content: Content) -> some View { content.font(.system(size: size, weight: weight, design: design)) }
}
extension View {
    func ralliFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(ScaledRalliFont(size: size, weight: weight, design: design))
    }
}

private struct RalliReducedMotionKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}
extension EnvironmentValues {
    /// Optional test override. Production falls back to the system accessibility preference.
    var ralliReducedMotion: Bool? {
        get { self[RalliReducedMotionKey.self] }
        set { self[RalliReducedMotionKey.self] = newValue }
    }
}

private struct RalliPresentationEnvironment: ViewModifier {
    @ViewBuilder func body(content: Content) -> some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ralli-accessibility-qa") {
            content.environment(\.dynamicTypeSize, .accessibility5).environment(\.ralliReducedMotion, true)
        } else { content }
        #else
        content
        #endif
    }
}
extension View {
    func ralliPresentationEnvironment() -> some View { modifier(RalliPresentationEnvironment()) }
}
