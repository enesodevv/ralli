import SwiftUI
import UIKit

import SwiftData

@main struct RalliApp: App {
    @StateObject private var store = RalliApp.makeStore()
    /// UI tests run against their own store file so they never touch real data.
    /// `-ralli-ui-testing` uses that store; adding `-ralli-reset` wipes it and all settings first.
    private static func makeStore() -> PlayerStore {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-ralli-ui-testing") {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("ralli-ui-tests.store")
            if arguments.contains("-ralli-reset") {
                for suffix in ["", "-shm", "-wal"] { try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix)) }
                if let id = Bundle.main.bundleIdentifier { UserDefaults.standard.removePersistentDomain(forName: id) }
            }
            if arguments.contains("-ralli-skip-intro") { UserDefaults.standard.set(true, forKey: "hasSeenIntro") }
            if let container = try? ModelContainer(for: PlayerArchive.self, configurations: ModelConfiguration(url: url)) {
                return PlayerStore(container: container)
            }
        }
        #endif
        return PlayerStore()
    }
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-ralli-accessibility-qa") {
                RootView().environmentObject(store).preferredColorScheme(.light)
                    .environment(\.dynamicTypeSize, .accessibility5)
                    .environment(\.ralliReducedMotion, true)
            } else { RootView().environmentObject(store).preferredColorScheme(.light) }
            #else
            RootView().environmentObject(store).preferredColorScheme(.light)
            #endif
        }
    }
}
struct RootView: View {
    @EnvironmentObject private var store: PlayerStore
    @State private var selection = 0
    @State private var savedToast: UUID?
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    @State private var showIntro = false
    @State private var setupAfterIntro = false
    @State private var showSetup = false
    @State private var debugDemo: PracticePlan?
    @State private var contactSheet: (StrokeMotion, MotionCamera)?
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.ralliReducedMotion) private var motionOverride
    private var reduceMotion: Bool { motionOverride ?? systemReduceMotion }
    var body: some View {
        TabView(selection: $selection) {
            HomeView(selection: $selection).tabItem { Label(L10n.text("Today"), systemImage: "tennisball") }.tag(0)
            PracticeView().tabItem { Label(L10n.text("Çalış"), systemImage: "figure.tennis") }.tag(1)
            JournalView(selection: $selection).tabItem { Label(L10n.text("Defter"), systemImage: "book.closed") }.tag(2)
            ProgressViewScreen().tabItem { Label(L10n.text("Gelişim"), systemImage: "chart.xyaxis.line") }.tag(3)
        }.tint(RalliTheme.ink)
        .sensoryFeedback(.success, trigger: store.completedSessions)
        .onChange(of: store.completedSessions) { previous, current in
            guard current > previous else { return }
            if reduceMotion { savedToast = UUID() }
            else { withAnimation(.easeOut(duration: 0.2)) { savedToast = UUID() } }
            if UIAccessibility.isVoiceOverRunning { UIAccessibility.post(notification: .announcement, argument: L10n.text("a11y.saved")) }
        }
        .overlay(alignment: .top) {
            if savedToast != nil {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(RalliTheme.ink)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.text("app.saved")).font(.headline)
                        Text(L10n.text("app.saved.detail")).font(.subheadline).foregroundStyle(RalliTheme.muted)
                    }
                }.padding(16).background(RalliTheme.paper, in: RoundedRectangle(cornerRadius: RalliTheme.radius))
                    .shadow(color: .black.opacity(0.1), radius: 12, y: 4).padding(.horizontal, 20).padding(.top, 8)
                    .allowsHitTesting(false).accessibilityHidden(true).transition(.opacity)
            }
        }
        .task(id: savedToast) {
            guard savedToast != nil else { return }
            do { try await Task.sleep(for: .seconds(4)) } catch { return }
            savedToast = nil
        }
        .alert(L10n.text("Kayıt sorunu"), isPresented: Binding(get: { store.persistenceError != nil }, set: { if !$0 { store.persistenceError = nil } })) {
            Button(L10n.text("Tamam"), role: .cancel) { store.persistenceError = nil }
        } message: { Text(store.persistenceError ?? "") }
        .onAppear { decideIntro() }
        .task { Analytics.track(.appOpened); DiagnosticsReceiver.shared.start() }
        .fullScreenCover(isPresented: $showIntro, onDismiss: {
            if setupAfterIntro { setupAfterIntro = false; selection = 0; showSetup = true }
        }) {
            IntroView { openSetup in
                hasSeenIntro = true
                setupAfterIntro = openSetup
                Analytics.track(.introFinished(openedSetup: openSetup))
                showIntro = false
            }.ralliPresentationEnvironment()
        }
        .sheet(isPresented: $showSetup) { PlayerPreferencesView(preferences: store.preferences).ralliPresentationEnvironment() }
        .overlay {
            #if DEBUG
            if let (motion, camera) = contactSheet { MotionContactSheet(motion: motion, camera: camera) }
            #endif
        }
        .sheet(item: $debugDemo) { plan in
            ScrollView { DrillDemonstration(plan: plan).padding(24) }.background(RalliTheme.paper).ralliPresentationEnvironment()
        }
    }
    /// Only brand-new players see the intro; anyone with notes or sessions already knows the app.
    private func decideIntro() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ralli-show-intro") { showIntro = true; return }
        let arguments = ProcessInfo.processInfo.arguments
        // Review aid: `-ralli-contact-sheet <motion id> <camera>` shows 12 frames of one motion side by side.
        if let flag = arguments.firstIndex(of: "-ralli-contact-sheet"), arguments.indices.contains(flag + 2),
           let motion = StrokeMotion.all.first(where: { $0.id == arguments[flag + 1].replacingOccurrences(of: "-left", with: "") }),
           let camera = MotionCamera(rawValue: arguments[flag + 2]) {
            hasSeenIntro = true
            contactSheet = (arguments[flag + 1].hasSuffix("-left") ? motion.mirrored() : motion, camera)
            return
        }
        // Review aid: `-ralli-demo <plan id>` opens that drill's demonstration directly.
        if let flag = arguments.firstIndex(of: "-ralli-demo"), arguments.indices.contains(flag + 1) {
            hasSeenIntro = true
            debugDemo = PracticePlan.library.first { $0.id == arguments[flag + 1] }
            return
        }
        #endif
        guard !hasSeenIntro else { return }
        if store.notes.isEmpty && store.records.isEmpty && store.draft == nil { showIntro = true }
        else { hasSeenIntro = true }
    }
}

#if DEBUG
/// Debug-only review grid: the same motion frozen at 12 evenly spaced moments.
struct MotionContactSheet: View {
    let motion: StrokeMotion
    let camera: MotionCamera
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(motion.id) · \(camera.rawValue)").font(.caption.monospaced()).foregroundStyle(RalliTheme.paper)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                ForEach(0..<12, id: \.self) { index in
                    let progress = Double(index) / 12
                    StrokeSceneView(motion: motion, progress: progress, camera: camera, effects: true, animateCamera: false)
                        .frame(height: 150)
                        .overlay(alignment: .topLeading) {
                            Text("\(index) \(String(format: "%.2f", progress)) \(L10n.text(motion.keyframes[motion.phaseIndex(at: progress)].phase))")
                                .font(.system(size: 9, design: .monospaced)).foregroundStyle(.white).padding(3)
                        }
                }
            }
        }.padding(.horizontal, 4).padding(.top, 50).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).background(Color.black)
    }
}
#endif
