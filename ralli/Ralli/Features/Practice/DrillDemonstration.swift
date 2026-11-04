import SwiftUI
import SafariServices

struct DrillDemonstration: View {
    let plan: PracticePlan
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.ralliReducedMotion) private var motionOverride
    private var reduceMotion: Bool { motionOverride ?? systemReduceMotion }
    @Environment(\.scenePhase) private var scenePhase
    @State private var playing = false
    @State private var accumulated: TimeInterval = 0
    @State private var startedAt = Date()
    @State private var position = 0
    @State private var guide = false
    @State private var showStroke = true
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Eyebrow(text: L10n.text("demo.title"))
            Picker(L10n.text("demo.title"), selection: $showStroke) {
                Text(L10n.text("motion.tab.stroke")).tag(true)
                Text(L10n.text("motion.tab.court")).tag(false)
            }.pickerStyle(.segmented)
            if showStroke {
                StrokeMotionPlayer(motion: plan.strokeMotion)
                Text(L10n.text("motion.description." + plan.strokeMotion.id)).font(.body).lineSpacing(4)
                Text(L10n.text("motion.caption")).font(.footnote).foregroundStyle(RalliTheme.muted)
            } else {
                courtPattern
            }
            if let url = plan.coachingURL {
                Button { pause(); guide = true } label: {
                    Label(L10n.text("demo.coach.guide"), systemImage: "safari").font(.callout).frame(minHeight: 44)
                }
                Text(L10n.text("demo.guide.caption")).font(.footnote).foregroundStyle(RalliTheme.muted)
                Color.clear.frame(height: 0).sheet(isPresented: $guide) { CoachingGuide(url: url).ignoresSafeArea() }
            }
        }.tint(RalliTheme.ink)
            .onChange(of: reduceMotion) { _, _ in pause() }
            .onChange(of: showStroke) { _, _ in pause() }
            .onChange(of: scenePhase) { _, phase in if phase != .active { pause() } }
            .onDisappear { pause() }
    }
    /// The original schematic: where the ball or player travels on court.
    @ViewBuilder private var courtPattern: some View {
        TimelineView(.animation(minimumInterval: 1.0/30, paused: !playing || reduceMotion)) { context in
            let elapsed = accumulated + (playing ? context.date.timeIntervalSince(startedAt) : 0)
            let phase = reduceMotion ? Double(position) / 4 : elapsed.truncatingRemainder(dividingBy: 6) / 6
            DrillCourtDiagram(pattern: plan.visual, progress: phase)
                .frame(height: 210).padding(22).background(RalliTheme.ink, in: RoundedRectangle(cornerRadius: RalliTheme.radius))
                .accessibilityHidden(true)
        }
        Text(L10n.text("demo.description." + plan.visual)).font(.body).lineSpacing(4)
        if reduceMotion {
            Button {
                position = (position + 1) % 5
            } label: { Label(L10n.text("demo.next.position"), systemImage: "forward.frame") }.frame(minHeight: 44)
            Text(String(format: L10n.text("demo.position"), position + 1)).font(.footnote).foregroundStyle(RalliTheme.muted)
        } else {
            Button {
                if playing { pause() }
                else { startedAt = Date(); playing = true }
            } label: { Label(L10n.text(playing ? "demo.pause" : "demo.play"), systemImage: playing ? "pause.fill" : "play.fill").frame(minHeight: 44) }
        }
        Text(L10n.text("demo.caption")).font(.footnote).foregroundStyle(RalliTheme.muted)
    }
    private func pause() {
        if playing { accumulated += Date().timeIntervalSince(startedAt) }
        playing = false
    }
}

struct CoachingGuide: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(RalliTheme.ink)
        return controller
    }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
