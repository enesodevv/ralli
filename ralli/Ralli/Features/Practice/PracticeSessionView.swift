import SwiftUI
import UIKit
import AudioToolbox
import UserNotifications

struct PracticeSessionView: View {
    let plan: PracticePlan
    @EnvironmentObject private var store: PlayerStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.ralliReducedMotion) private var motionOverride
    @Environment(\.dynamicTypeSize) private var textSize
    private var reduceMotion: Bool { motionOverride ?? systemReduceMotion }
    @StateObject private var voice = PracticeVoiceGuide()
    @AppStorage("spokenPracticeCues") private var spokenCues = false
    @State private var sessionID = UUID()
    @State private var linkedNoteID: UUID?
    @State private var lastCheckpoint = Date.distantPast
    @State private var restored = false
    @State private var blocked = false
    @State private var showDemo = false
    @State private var active = false
    @State private var reviewing = false
    @State private var step = 0
    @State private var paused = false
    @State private var remaining: TimeInterval = 0
    @State private var deadline = Date()
    @State private var secondsSpent = 0
    @State private var segmentStarted = Date()
    @State private var stepEndSignalled = false
    @State private var confirmExit = false
    @State private var includeResult = false
    @State private var result = 0
    @State private var reflection = ""
    private static let stepNotificationID = "ralli.step.end"
    /// Court mode: a dark, high-contrast screen used while the session runs.
    private var courtMode: Bool { active && !reviewing }
    private var foreground: Color { courtMode ? RalliTheme.paper : RalliTheme.ink }
    private var secondary: Color { courtMode ? RalliTheme.paper.opacity(0.78) : RalliTheme.muted }
    private var isLastStep: Bool { step == plan.steps.count - 1 }
    private var applicableCue: LessonNote? {
        guard let note = store.activeNote else { return nil }
        return (note.category ?? "Genel") == "Genel" || note.category == plan.focus ? note : nil
    }
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var clock: String { let value = max(0, Int(remaining.rounded(.up))); return String(format: "%02d:%02d", value / 60, value % 60) }
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    topBar
                    if reviewing { review }
                    else if active {
                        VStack(alignment: .leading, spacing: 8) {
                            Eyebrow(text: L10n.text(plan.focus) + " / " + plan.modeTitle, color: secondary)
                            Text(plan.title).font(RalliTheme.title(26)).accessibilityAddTraits(.isHeader)
                        }
                        sessionPanel.id("session")
                    } else { details }
                }.padding(24)
            }.background(courtMode ? RalliTheme.ink : RalliTheme.paper).foregroundStyle(foreground)
                .preferredColorScheme(courtMode ? .dark : .light)
                // Solid band under the status bar so scrolled text never collides with the clock.
                .safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: 0).background(courtMode ? RalliTheme.ink : RalliTheme.paper) }
                .safeAreaInset(edge: .bottom) {
                    if !active {
                        PrimaryButton(title: L10n.text("practice.start"), icon: "play.fill") {
                            guard store.draft == nil || store.draft?.planID == plan.id else { blocked = true; return }
                            Task { _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) }
                            active = true; step = 0; secondsSpent = 0; linkedNoteID = applicableCue?.id; startStep()
                            Analytics.track(.sessionStarted(planID: plan.id, resumed: false))
                            if reduceMotion { proxy.scrollTo("session", anchor: .top) }
                            else { withAnimation { proxy.scrollTo("session", anchor: .top) } }
                        }.disabled(blocked).padding(.horizontal, 24).padding(.vertical, 12).background(RalliTheme.paper)
                    }
                }
                .onAppear { restoreDraft() }
                .onReceive(ticker) { _ in
                    refresh()
                    if active && Date().timeIntervalSince(lastCheckpoint) >= 10 { _ = checkpoint() }
                }
                .onChange(of: courtMode, initial: true) { _, on in UIApplication.shared.isIdleTimerDisabled = on }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { cancelStepNotification(); refresh() }
                    else { voice.stop(); refresh(); scheduleStepNotification(); _ = checkpoint() }
                }
                .onChange(of: includeResult) { _, _ in _ = checkpoint() }
                .onChange(of: result) { _, _ in _ = checkpoint() }
                .onChange(of: reflection) { _, _ in _ = checkpoint() }
                .onChange(of: spokenCues) { _, enabled in
                    if !enabled { voice.stop() }
                    else if active && !paused && !reviewing { voice.speak(plan.steps[step].instruction) }
                }
                .onDisappear {
                    voice.stop(); cancelStepNotification()
                    UIApplication.shared.isIdleTimerDisabled = false
                    if active { _ = checkpoint() }
                }
                .sheet(isPresented: $showDemo) {
                    NavigationStack {
                        ScrollView { DrillDemonstration(plan: plan).padding(24) }.background(RalliTheme.paper)
                            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.text("Tamam")) { showDemo = false } } }
                    }.preferredColorScheme(.light).ralliPresentationEnvironment()
                }
                .interactiveDismissDisabled(active)
                .confirmationDialog(L10n.text("Çalışmadan çıkılsın mı?"), isPresented: $confirmExit, titleVisibility: .visible) {
                    Button(L10n.text("practice.suspend")) {
                        if checkpoint() { Analytics.track(.sessionLeft(planID: plan.id, keptDraft: true)); active = false; dismiss() }
                    }
                    Button(L10n.text("practice.discard"), role: .destructive) {
                        if store.saveDraft(nil) { Analytics.track(.sessionLeft(planID: plan.id, keptDraft: false)); active = false; dismiss() }
                    }
                    Button(L10n.text("Devam et"), role: .cancel) {}
                }
                .alert(L10n.text("practice.existing"), isPresented: $blocked) {
                    Button(L10n.text("Tamam")) { dismiss() }
                } message: { Text(L10n.text("practice.existing.body")) }
                .alert(L10n.text("Kayıt sorunu"), isPresented: Binding(get: { store.persistenceError != nil }, set: { if !$0 { store.persistenceError = nil } })) {
                    Button(L10n.text("Tamam"), role: .cancel) { store.persistenceError = nil }
                } message: { Text(store.persistenceError ?? "") }
        }
    }

    // MARK: Top bar
    private var topBar: some View {
        Button {
            if reviewing { reviewing = false }
            else if active { confirmExit = true }
            else { dismiss() }
        } label: {
            Label(L10n.text(reviewing ? "practice.continue" : (active ? "Çalışmadan çık" : "practice.close")),
                  systemImage: reviewing ? "arrow.left" : "xmark")
                .ralliFont(size: 14, weight: .medium).frame(minHeight: 44)
        }.buttonStyle(.plain).padding(.top, 4)
    }

    // MARK: Drill details (before starting)
    private var details: some View {
        VStack(alignment: .leading, spacing: 26) {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: L10n.text(plan.focus) + " / " + plan.modeTitle)
                Text(plan.title).font(RalliTheme.title(40)).tracking(-1).accessibilityAddTraits(.isHeader)
                Text(plan.subtitle).ralliFont(size: 16).foregroundStyle(RalliTheme.muted).lineSpacing(4)
                HStack(spacing: 18) {
                    Label(L10n.minutes(plan.minutes), systemImage: "clock")
                    Label(plan.modeTitle, systemImage: plan.mode == "solo" ? "person" : "person.2")
                    Label(L10n.text(plan.minimumLevel == "developing" ? "level.developing.short" : "level.foundation.short"), systemImage: "chart.bar")
                }.ralliFont(size: 12, weight: .medium, design: .monospaced).foregroundStyle(RalliTheme.muted)
            }
            DrillDemonstration(plan: plan)
            VStack(alignment: .leading, spacing: 18) {
                SectionHeading(title: L10n.text("practice.structure"), detail: L10n.minutes(plan.minutes))
                ForEach(plan.steps.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 16) {
                        Text(String(format: "%02d", index + 1)).ralliFont(size: 12, design: .monospaced).foregroundStyle(RalliTheme.clay).padding(.top, 6)
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(plan.steps[index].title).font(RalliTheme.title(22))
                                Spacer()
                                Text(L10n.minutes(plan.steps[index].minutes)).ralliFont(size: 10, design: .monospaced).foregroundStyle(RalliTheme.muted)
                            }
                            Text(plan.steps[index].instruction).ralliFont(size: 14).foregroundStyle(RalliTheme.muted).lineSpacing(4)
                        }
                    }
                }
            }
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "sparkle").foregroundStyle(RalliTheme.clay).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: L10n.text("practice.cue"))
                    Text(plan.cue).font(RalliTheme.title(24))
                    Text(L10n.text("practice.mistake") + ": " + plan.mistake).ralliFont(size: 13).foregroundStyle(RalliTheme.muted).lineSpacing(4)
                }
            }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(RalliTheme.lime.opacity(0.35), in: RoundedRectangle(cornerRadius: RalliTheme.radius))
            if let cue = applicableCue { detail("personal.cue", body: cue.text) }
            detail("practice.goal", body: plan.goal)
            detail("practice.equipment", body: plan.equipment)
            detail("practice.preconditions", body: plan.prerequisite)
            // Safety stays visible, not tucked away: warm up, give others room, stop if it hurts.
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "heart.text.square").foregroundStyle(RalliTheme.clay).accessibilityHidden(true)
                Text(L10n.text("practice.before")).ralliFont(size: 13).lineSpacing(4)
            }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .overlay(RoundedRectangle(cornerRadius: RalliTheme.smallRadius).stroke(RalliTheme.clay.opacity(0.5), lineWidth: 1))
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: L10n.text("practice.metric.heading"))
                Text(plan.metricTitle).ralliFont(size: 15, weight: .medium)
            }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(RalliTheme.surface, in: RoundedRectangle(cornerRadius: RalliTheme.smallRadius))
            VStack(alignment: .leading, spacing: 6) {
                Toggle(L10n.text("practice.sound"), isOn: $spokenCues).tint(RalliTheme.clay)
                Text(L10n.text("practice.sound.hint")).font(.footnote).foregroundStyle(RalliTheme.muted)
            }
            DisclosureGroup(L10n.text("practice.sources")) {
                VStack(alignment: .leading, spacing: 12) {
                    if let url = URL(string: plan.source) { Link(L10n.text("practice.source"), destination: url).ralliFont(size: 13, weight: .medium) }
                    Text(L10n.text("practice.adapted")).ralliFont(size: 11).foregroundStyle(RalliTheme.muted).lineSpacing(3)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 10)
            }.tint(RalliTheme.ink)
        }
    }
    private func detail(_ key: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 9) { Eyebrow(text: L10n.text(key)); Text(body).ralliFont(size: 15).lineSpacing(5) }
    }

    // MARK: Court mode
    private var sessionPanel: some View {
        VStack(alignment: .leading, spacing: 22) {
            Eyebrow(text: L10n.step(step + 1, total: plan.steps.count), color: RalliTheme.lime)
            HStack(spacing: 5) {
                ForEach(plan.steps.indices, id: \.self) { index in
                    Capsule().fill(index <= step ? RalliTheme.lime : RalliTheme.paper.opacity(0.2)).frame(height: 5)
                }
            }.accessibilityHidden(true)
            if restored { Text(L10n.text("practice.resumed")).font(.footnote).foregroundStyle(secondary) }
            Text(plan.steps[step].title).font(RalliTheme.title(32)).accessibilityAddTraits(.isHeader)
            Text(plan.steps[step].instruction).ralliFont(size: 18).lineSpacing(6)
            Text(clock).ralliFont(size: 88, weight: .medium, design: .monospaced).monospacedDigit()
                .foregroundStyle(remaining <= 0 ? RalliTheme.paper : RalliTheme.lime)
                .minimumScaleFactor(0.25).lineLimit(1).frame(maxWidth: .infinity, alignment: .center)
                .accessibilityLabel(L10n.text("a11y.timer")).accessibilityValue(clock)
            if remaining <= 0 {
                Text(L10n.text("Bu adımın süresi doldu. Hazır olduğunda devam et.")).ralliFont(size: 15, weight: .medium).foregroundStyle(RalliTheme.lime)
                courtButton(L10n.text(isLastStep ? "practice.finish" : "practice.next"), icon: "arrow.right", filled: true) { advance() }
            } else {
                courtButton(L10n.text(paused ? "Sürdür" : "Duraklat"), icon: paused ? "play.fill" : "pause.fill", filled: true) { togglePause() }
                courtButton(L10n.text(isLastStep ? "practice.finish" : "practice.next"), icon: "forward.end", filled: false) { advance() }
            }
            VStack(alignment: .leading, spacing: 8) {
                if let cue = store.notes.first(where: { $0.id == linkedNoteID }) {
                    Eyebrow(text: L10n.text("personal.cue"), color: secondary)
                    Text(cue.text).font(RalliTheme.title(22)).lineSpacing(4)
                } else {
                    Eyebrow(text: L10n.text("practice.cue"), color: secondary)
                    Text(plan.cue).font(RalliTheme.title(22))
                }
            }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .background(RalliTheme.paper.opacity(0.08), in: RoundedRectangle(cornerRadius: RalliTheme.smallRadius))
            Button {
                if !paused && remaining > 0 { togglePause() }
                showDemo = true
            } label: { Label(L10n.text("demo.open"), systemImage: "rectangle.and.hand.point.up.left").frame(minHeight: 44) }
                .ralliFont(size: 15).foregroundStyle(RalliTheme.paper)
            Toggle(L10n.text("practice.sound"), isOn: $spokenCues).ralliFont(size: 15).tint(RalliTheme.clay)
        }
    }
    private func courtButton(_ title: String, icon: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if !textSize.isAccessibilitySize { Image(systemName: icon).accessibilityHidden(true) }
                Text(title)
            }.ralliFont(size: 18, weight: .semibold).frame(maxWidth: .infinity, minHeight: filled ? 68 : 56)
                .foregroundStyle(filled ? RalliTheme.ink : RalliTheme.paper)
                .background(filled ? RalliTheme.lime : Color.clear, in: RoundedRectangle(cornerRadius: RalliTheme.radius))
                .overlay { if !filled { RoundedRectangle(cornerRadius: RalliTheme.radius).stroke(RalliTheme.paper.opacity(0.45), lineWidth: 1) } }
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    // MARK: Review
    private var review: some View {
        VStack(alignment: .leading, spacing: 24) {
            Eyebrow(text: plan.title)
            Text(L10n.text("practice.check.title")).font(RalliTheme.title(42)).tracking(-1)
            Text(L10n.text("practice.check.subtitle")).ralliFont(size: 15).foregroundStyle(RalliTheme.muted).lineSpacing(4)
            Label(secondsSpent < 60 ? L10n.seconds(secondsSpent) : L10n.minutes(secondsSpent / 60), systemImage: "clock").ralliFont(size: 15, design: .monospaced)
            VStack(alignment: .leading, spacing: 18) {
                Toggle(L10n.text("practice.benchmark"), isOn: $includeResult).tint(RalliTheme.clay)
                if includeResult {
                    Text(plan.metricTitle).font(RalliTheme.title(24))
                    Stepper(value: $result, in: 0...plan.maximumScore) { Text("\(result)").ralliFont(size: 36, design: .serif).monospacedDigit() }
                } else { Text(L10n.text("practice.check.skip")).ralliFont(size: 12).foregroundStyle(RalliTheme.muted) }
            }.padding(22).background(RalliTheme.surface, in: RoundedRectangle(cornerRadius: RalliTheme.radius))
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: L10n.text("practice.reflection"))
                TextField(L10n.text("practice.reflection.placeholder"), text: $reflection, axis: .vertical).lineLimit(3...6)
                    .padding(18).background(RalliTheme.surface, in: RoundedRectangle(cornerRadius: RalliTheme.smallRadius))
            }
            PrimaryButton(title: L10n.text("practice.save.result"), icon: "checkmark") {
                let note = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
                if store.completePractice(focus: plan.focus, seconds: secondsSpent, planID: plan.id, result: includeResult ? result : nil, reflection: note.isEmpty ? nil : note, noteID: linkedNoteID, sessionID: sessionID, benchmarkVersion: plan.benchmarkVersion) {
                    Analytics.track(.sessionCompleted(planID: plan.id, minutes: secondsSpent / 60, loggedResult: includeResult))
                    active = false; dismiss()
                }
            }
        }
    }

    // MARK: Timing
    private func startStep() {
        remaining = TimeInterval(plan.steps[step].minutes * 60); deadline = Date().addingTimeInterval(remaining); segmentStarted = Date(); paused = false
        stepEndSignalled = false
        _ = checkpoint()
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: String(format: L10n.text("a11y.step"), step + 1, plan.steps.count, plan.steps[step].title))
        } else if spokenCues { voice.speak(plan.steps[step].title + ". " + plan.steps[step].instruction) }
    }
    private func advance() {
        accumulate()
        if step < plan.steps.count - 1 { step += 1; startStep() }
        else { paused = true; reviewing = true; voice.stop(); cancelStepNotification(); _ = checkpoint() }
    }
    /// The phone usually lies on the bench, so the end of a step must be heard and felt, not only seen.
    private func signalStepEnd() {
        stepEndSignalled = true
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        AudioServicesPlaySystemSound(1005)
        let message = L10n.text("Bu adımın süresi doldu. Hazır olduğunda devam et.")
        if UIAccessibility.isVoiceOverRunning { UIAccessibility.post(notification: .announcement, argument: message) }
        else if spokenCues { voice.speak(message) }
        _ = checkpoint()
    }
    private func scheduleStepNotification() {
        guard active, !paused, !reviewing, remaining > 1 else { return }
        let content = UNMutableNotificationContent()
        content.title = L10n.text("notify.step.title")
        content.body = String(format: L10n.text("notify.step.body"), plan.steps[step].title)
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: remaining, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: Self.stepNotificationID, content: content, trigger: trigger))
    }
    private func cancelStepNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.stepNotificationID])
    }
    @discardableResult private func checkpoint() -> Bool {
        guard active else { return true }
        lastCheckpoint = Date()
        let snapshot = SessionDraft(id: sessionID, planID: plan.id, step: step,
            remaining: paused ? remaining : max(0, deadline.timeIntervalSinceNow),
            secondsSpent: secondsSpent + (paused ? 0 : max(0, Int(Date().timeIntervalSince(segmentStarted)))),
            reviewing: reviewing, includeResult: includeResult, result: result, reflection: reflection, noteID: linkedNoteID)
        return store.saveDraft(snapshot)
    }
    private func restoreDraft() {
        guard let draft = store.draft else { return }
        guard draft.planID == plan.id, plan.steps.indices.contains(draft.step) else { blocked = true; return }
        sessionID = draft.id; step = draft.step; remaining = draft.remaining; secondsSpent = draft.secondsSpent
        reviewing = draft.reviewing; includeResult = draft.includeResult; result = draft.result; reflection = draft.reflection; linkedNoteID = draft.noteID
        active = true; paused = true; restored = true; stepEndSignalled = draft.remaining <= 0
        Analytics.track(.sessionStarted(planID: plan.id, resumed: true))
    }
    private func refresh() {
        guard active && !paused && !reviewing else { return }
        remaining = max(0, deadline.timeIntervalSinceNow)
        if remaining <= 0 && !stepEndSignalled { signalStepEnd() }
    }
    private func accumulate() {
        if !paused { secondsSpent += max(0, Int(Date().timeIntervalSince(segmentStarted))); segmentStarted = Date() }
    }
    private func togglePause() {
        if paused { deadline = Date().addingTimeInterval(remaining); segmentStarted = Date(); paused = false; restored = false
            if spokenCues { voice.speak(plan.steps[step].instruction) }
        }
        else { refresh(); accumulate(); paused = true; voice.stop() }
        _ = checkpoint()
    }
}
