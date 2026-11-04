import SwiftUI

/// Draws one pose of the schematic player: body, racket, ball and a short racket trail.
struct StrokeFigure: View {
    let pose: MotionPose
    var trail: [MotionPoint] = []
    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
            func p(_ point: MotionPoint) -> CGPoint { CGPoint(x: origin.x + point.x * side, y: origin.y + point.y * side) }
            let paper = RalliTheme.paper, lime = RalliTheme.lime

            // Ground and net give the figure a direction.
            var ground = Path(); ground.move(to: p(.init(0.08, 0.955))); ground.addLine(to: p(.init(0.97, 0.955)))
            context.stroke(ground, with: .color(paper.opacity(0.3)), lineWidth: 1)
            var net = Path(); net.move(to: p(.init(0.95, 0.80))); net.addLine(to: p(.init(0.95, 0.955)))
            context.stroke(net, with: .color(paper.opacity(0.35)), style: StrokeStyle(lineWidth: 2, dash: [3, 3]))

            // Racket trail: where the racket head has just been.
            for (index, point) in trail.enumerated() {
                let alpha = Double(index + 1) / Double(trail.count + 1) * 0.35
                let r = side * 0.012
                context.fill(Path(ellipseIn: CGRect(x: p(point).x - r, y: p(point).y - r, width: r * 2, height: r * 2)), with: .color(lime.opacity(alpha)))
            }

            let limb = StrokeStyle(lineWidth: side * 0.034, lineCap: .round, lineJoin: .round)
            // Arms hang from a shoulder just below the neck, so a raised arm never runs through the head.
            let shoulder = MotionPoint(pose.neck.x, pose.neck.y + 0.035)
            func line(_ points: [MotionPoint], _ color: Color) {
                var path = Path(); path.move(to: p(points[0])); points.dropFirst().forEach { path.addLine(to: p($0)) }
                context.stroke(path, with: .color(color), style: limb)
            }
            // Back limbs slightly dimmer to read as depth.
            line([pose.hip, pose.backKnee, pose.backFoot], paper.opacity(0.55))
            line([shoulder, pose.freeElbow, pose.freeHand], paper.opacity(0.6))
            line([pose.neck, pose.hip], paper)
            line([pose.hip, pose.frontKnee, pose.frontFoot], paper)
            let headRadius = side * 0.05
            context.fill(Path(ellipseIn: CGRect(x: p(pose.head).x - headRadius, y: p(pose.head).y - headRadius, width: headRadius * 2, height: headRadius * 2)), with: .color(paper))

            // Racket: handle from the hand, an oval head at the far end.
            let hand = p(pose.hittingHand), tip = p(pose.racketTip)
            let neckPoint = CGPoint(x: hand.x + (tip.x - hand.x) * 0.45, y: hand.y + (tip.y - hand.y) * 0.45)
            var handle = Path(); handle.move(to: hand); handle.addLine(to: neckPoint)
            context.stroke(handle, with: .color(lime), style: StrokeStyle(lineWidth: side * 0.016, lineCap: .round))
            let headCenter = CGPoint(x: (neckPoint.x + tip.x) / 2, y: (neckPoint.y + tip.y) / 2)
            let headLength = hypot(tip.x - neckPoint.x, tip.y - neckPoint.y)
            var oval = context
            oval.translateBy(x: headCenter.x, y: headCenter.y)
            oval.rotate(by: .degrees(pose.racketAngle))
            let racketHead = Path(ellipseIn: CGRect(x: -headLength / 2, y: -headLength * 0.32, width: headLength, height: headLength * 0.64))
            oval.stroke(racketHead, with: .color(lime), lineWidth: side * 0.012)

            line([shoulder, pose.hittingElbow, pose.hittingHand], paper)

            if let ball = pose.ball {
                let r = side * 0.022
                context.fill(Path(ellipseIn: CGRect(x: p(ball).x - r, y: p(ball).y - r, width: r * 2, height: r * 2)), with: .color(lime))
            }
        }
    }
}

/// Animated stroke figure with phase labels, play/pause and slow motion.
/// With Reduce Motion it never moves on its own: the player steps through the phases.
struct StrokeMotionPlayer: View {
    let motion: StrokeMotion
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.ralliReducedMotion) private var motionOverride
    @Environment(\.scenePhase) private var scenePhase
    @State private var playing = true
    @State private var slow = false
    @State private var accumulated: Double = 0
    @State private var startedAt = Date()
    @State private var stepIndex = 0
    private var reduceMotion: Bool { motionOverride ?? systemReduceMotion }
    /// Seconds for one full cycle at normal speed.
    private var cycle: Double { Double(motion.segmentCount) * 0.95 * (slow ? 2.5 : 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !playing || reduceMotion)) { context in
                let progress = currentProgress(at: context.date)
                let index = motion.phaseIndex(at: progress)
                VStack(alignment: .leading, spacing: 14) {
                    StrokeFigure(pose: motion.pose(at: progress), trail: reduceMotion ? [] : trail(at: progress))
                        .frame(height: 300).frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RalliTheme.ink, in: RoundedRectangle(cornerRadius: RalliTheme.radius))
                        .accessibilityHidden(true)
                    phaseStrip(current: index)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(format: L10n.text("motion.a11y"), L10n.text(motion.titleKey)))
                .accessibilityValue(L10n.text(motion.keyframes[index].phase))
            }
            controls
        }
        .onChange(of: scenePhase) { _, phase in if phase != .active { pause() } }
        .onChange(of: motion.id) { _, _ in accumulated = 0; startedAt = Date(); stepIndex = 0 }
        .onDisappear { pause() }
    }

    private func currentProgress(at date: Date) -> Double {
        if reduceMotion { return Double(stepIndex) / Double(motion.segmentCount) }
        let elapsed = accumulated + (playing ? date.timeIntervalSince(startedAt) : 0)
        return (elapsed / cycle).truncatingRemainder(dividingBy: 1)
    }
    private func trail(at progress: Double) -> [MotionPoint] {
        (1...7).reversed().map { motion.pose(at: progress - Double($0) * 0.012).racketTip }
    }
    private func phaseStrip(current: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                ForEach(motion.keyframes.indices, id: \.self) { index in
                    Capsule().fill(index == current ? RalliTheme.clay : RalliTheme.line).frame(height: 4)
                }
            }
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.text(motion.keyframes[current].phase)).font(RalliTheme.title(22))
                Spacer()
                Text("\(current + 1)/\(motion.keyframes.count)").ralliFont(size: 11, design: .monospaced).foregroundStyle(RalliTheme.muted)
            }
        }
    }
    @ViewBuilder private var controls: some View {
        HStack(spacing: 12) {
            if reduceMotion {
                Button { stepIndex = max(0, stepIndex - 1) } label: { Label(L10n.text("motion.prev"), systemImage: "backward.frame").frame(minHeight: 44) }
                    .disabled(stepIndex == 0)
                Spacer()
                Button { stepIndex = min(motion.segmentCount, stepIndex + 1) } label: { Label(L10n.text("motion.next"), systemImage: "forward.frame").frame(minHeight: 44) }
                    .disabled(stepIndex == motion.segmentCount)
            } else {
                Button { playing ? pause() : play() } label: {
                    Label(L10n.text(playing ? "demo.pause" : "demo.play"), systemImage: playing ? "pause.fill" : "play.fill").frame(minHeight: 44)
                }
                Spacer()
                Toggle(isOn: Binding(get: { slow }, set: { setSlow($0) })) {
                    Label(L10n.text("motion.slow"), systemImage: "tortoise")
                }.toggleStyle(.button).frame(minHeight: 44)
            }
        }.ralliFont(size: 14, weight: .medium).tint(RalliTheme.ink)
    }
    private func play() { startedAt = Date(); playing = true }
    private func pause() {
        if playing { accumulated += Date().timeIntervalSince(startedAt) }
        playing = false
    }
    /// Keep the figure where it is when the speed changes.
    private func setSlow(_ value: Bool) {
        let now = Date()
        let progress = currentProgress(at: now)
        slow = value
        accumulated = progress * cycle
        startedAt = now
    }
}
