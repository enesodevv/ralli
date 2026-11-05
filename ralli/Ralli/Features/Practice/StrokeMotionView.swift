import SwiftUI

/// 3D stroke animation with phase labels, camera angles, play/pause and slow motion.
/// With Reduce Motion it never moves on its own: the player steps through the phases.
struct StrokeMotionPlayer: View {
    let motion: StrokeMotion
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.ralliReducedMotion) private var motionOverride
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var renderQuality = RenderQualityMonitor.shared
    @EnvironmentObject private var store: PlayerStore
    @State private var playing = true
    @State private var slow = false
    @State private var accumulated: Double = 0
    @State private var startedAt = Date()
    @State private var stepIndex = 0
    @State private var camera: MotionCamera?
    private var reduceMotion: Bool { motionOverride ?? systemReduceMotion }
    private var speed: Double { slow ? 0.35 : 1 }
    private var activeCamera: MotionCamera { camera ?? motion.defaultCamera }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TimelineView(.animation(minimumInterval: 1.0 / Double(renderQuality.quality.framesPerSecond), paused: !playing || reduceMotion)) { context in
                let progress = currentProgress(at: context.date)
                let index = motion.phaseIndex(at: progress)
                VStack(alignment: .leading, spacing: 14) {
                    StrokeSceneView(motion: motion, progress: progress, camera: activeCamera, effects: !reduceMotion, animateCamera: !reduceMotion,
                                    quality: renderQuality.quality)
                        .frame(height: 330)
                        .clipShape(RoundedRectangle(cornerRadius: RalliTheme.radius))
                        .overlay(alignment: .topLeading) {
                            Text(L10n.text(motion.titleKey).uppercased(with: L10n.locale))
                                .ralliFont(size: 10, weight: .semibold, design: .monospaced).tracking(1.5)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .foregroundStyle(RalliTheme.ink).background(RalliTheme.lime, in: Capsule()).padding(12)
                        }
                        .accessibilityHidden(true)
                    phaseStrip(current: index)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(format: L10n.text("motion.a11y"), L10n.text(motion.titleKey)))
                .accessibilityValue(L10n.text(motion.keyframes[index].phase))
            }
            Picker(L10n.text("motion.camera.label"), selection: Binding(get: { activeCamera }, set: { camera = $0; Analytics.track(.motionCameraChanged(camera: $0.rawValue)) })) {
                ForEach(MotionCamera.allCases) { Text(L10n.text($0.titleKey)).tag($0) }
            }.pickerStyle(.segmented)
            controls
        }
        .onChange(of: scenePhase) { _, phase in if phase != .active { pause() } }
        .onChange(of: motion.id) { _, _ in accumulated = 0; startedAt = Date(); stepIndex = 0; camera = nil }
        .onAppear { Analytics.track(.motionViewed(motionID: motion.id)) }
        .onDisappear { pause() }
    }

    private func currentProgress(at date: Date) -> Double {
        if reduceMotion { return motion.progress(atKeyframe: stepIndex) }
        let elapsed = accumulated + (playing ? date.timeIntervalSince(startedAt) * speed : 0)
        return (elapsed / motion.cycleDuration).truncatingRemainder(dividingBy: 1)
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
        HStack { handednessToggle; Spacer() }.ralliFont(size: 14, weight: .medium).tint(RalliTheme.ink)
        HStack(spacing: 12) {
            if reduceMotion {
                Button { stepIndex = max(0, stepIndex - 1) } label: { Label(L10n.text("motion.prev"), systemImage: "backward.frame").frame(minHeight: 44) }
                    .disabled(stepIndex == 0)
                Spacer()
                Button { stepIndex = min(motion.keyframes.count - 1, stepIndex + 1) } label: { Label(L10n.text("motion.next"), systemImage: "forward.frame").frame(minHeight: 44) }
                    .disabled(stepIndex == motion.keyframes.count - 1)
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
    /// Quick switch between right- and left-handed views; saved as the player's preference.
    /// Quick switch between right- and left-handed views; saved as the player's preference.
    /// Drawn as a clear on/off pill so it reads as a control, not a label.
    private var handednessToggle: some View {
        let left = store.preferences.isLeftHanded
        return Button {
            var value = store.preferences
            value.handedness = left ? "right" : "left"
            _ = store.savePreferences(value)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: left ? "checkmark.circle.fill" : "circle").accessibilityHidden(true)
                Text(L10n.text("motion.lefty"))
            }
            .padding(.horizontal, 14).frame(minHeight: 44)
            .foregroundStyle(left ? RalliTheme.paper : RalliTheme.ink)
            .background(left ? RalliTheme.ink : Color.clear, in: Capsule())
            .overlay(Capsule().stroke(RalliTheme.ink.opacity(left ? 0 : 0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(left ? [.isSelected] : [])
        .accessibilityHint(L10n.text("motion.lefty.hint"))
    }
    private func play() { startedAt = Date(); playing = true }
    private func pause() {
        if playing { accumulated += Date().timeIntervalSince(startedAt) * speed }
        playing = false
    }
    /// Keep the player where it is when the speed changes.
    private func setSlow(_ value: Bool) {
        if playing { accumulated += Date().timeIntervalSince(startedAt) * speed; startedAt = Date() }
        slow = value
        Analytics.track(.motionSlowToggled(on: value))
    }
}
