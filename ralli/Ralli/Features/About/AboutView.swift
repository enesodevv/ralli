import SwiftUI
import UIKit

/// Where a support e-mail is shown. Leave nil until a real, monitored address exists:
/// a dead contact is worse for App Review than none (the App Store page carries the support URL).
enum AppLinks {
    static let supportEmail: String? = nil
}

/// Settings: everything a player can change in one place, plus privacy, safety, sources and version.
/// Reachable from the gear on Today.
struct SettingsView: View {
    @EnvironmentObject private var store: PlayerStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage("spokenPracticeCues") private var spokenCues = false
    @State private var editingPreferences = false
    private var version: String {
        let info = Bundle.main.infoDictionary
        return "\(info?["CFBundleShortVersionString"] as? String ?? "1.0") (\(info?["CFBundleVersion"] as? String ?? "1"))"
    }
    private var hand: Binding<String> {
        Binding(get: { store.preferences.handedness ?? "right" }, set: { value in
            var preferences = store.preferences
            preferences.handedness = value
            _ = store.savePreferences(preferences)
        })
    }
    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
    }
    var body: some View {
        NavigationStack {
            List {
                Section(L10n.text("settings.player")) {
                    Button { editingPreferences = true } label: {
                        LabeledContent {
                            Text("\(L10n.text(store.preferences.focus)) · \(L10n.minutes(store.preferences.minutes))")
                        } label: { Label(L10n.text("settings.preferences"), systemImage: "slider.horizontal.3") }
                    }.foregroundStyle(RalliTheme.ink)
                    Picker(selection: hand) {
                        Text(L10n.text("setup.hand.right")).tag("right")
                        Text(L10n.text("setup.hand.left")).tag("left")
                    } label: { Label(L10n.text("setup.hand"), systemImage: "hand.raised") }
                }
                Section {
                    Toggle(isOn: $spokenCues) { Label(L10n.text("practice.sound"), systemImage: "speaker.wave.2") }.tint(RalliTheme.clay)
                } footer: { Text(L10n.text("practice.sound.hint")) }
                Section {
                    Button(action: openSystemSettings) { Label(L10n.text("settings.language"), systemImage: "globe") }
                    Button(action: openSystemSettings) { Label(L10n.text("about.permissions"), systemImage: "mic") }
                } header: { Text(L10n.text("settings.app")) } footer: { Text(L10n.text("settings.language.hint")) }
                Section(L10n.text("settings.about")) {
                    NavigationLink { PrivacyPolicyView() } label: { Label(L10n.text("about.privacy"), systemImage: "lock.shield") }
                    NavigationLink { SafetyAndSourcesView() } label: { Label(L10n.text("settings.safety"), systemImage: "heart.text.square") }
                    if let email = AppLinks.supportEmail, let url = URL(string: "mailto:\(email)") {
                        Link(destination: url) { Label(L10n.text("about.contact"), systemImage: "envelope") }
                    }
                    LabeledContent(L10n.text("about.version"), value: version)
                }
            }
            .scrollContentBackground(.hidden).background(RalliTheme.paper).tint(RalliTheme.ink)
            .navigationTitle(L10n.text("settings.title")).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.text("Tamam")) { dismiss() } } }
            .sheet(isPresented: $editingPreferences) { PlayerPreferencesView(preferences: store.preferences).ralliPresentationEnvironment() }
        }
    }
}

struct SafetyAndSourcesView: View {
    var body: some View {
        List {
            Section(L10n.text("about.safety.title")) { Text(L10n.text("practice.before")).font(.callout) }
            Section(L10n.text("about.sources.title")) { Text(L10n.text("about.sources.body")).font(.callout) }
        }
        .scrollContentBackground(.hidden).background(RalliTheme.paper)
        .navigationTitle(L10n.text("settings.safety")).navigationBarTitleDisplayMode(.inline)
    }
}

/// The privacy policy as plain, localised text inside the app, so it is always reachable (App Review 5.1.1).
struct PrivacyPolicyView: View {
    private let sections = ["summary", "device", "speech", "notifications", "diagnostics", "links", "children", "rights"]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(L10n.text("privacy.title")).font(RalliTheme.title(32)).accessibilityAddTraits(.isHeader)
                ForEach(sections, id: \.self) { key in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.text("privacy.\(key).title")).font(.headline).accessibilityAddTraits(.isHeader)
                        Text(L10n.text("privacy.\(key).body")).font(.body).lineSpacing(4).foregroundStyle(RalliTheme.ink)
                    }
                }
                Text(L10n.text("privacy.updated")).font(.footnote).foregroundStyle(RalliTheme.muted)
            }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
        }.background(RalliTheme.paper).foregroundStyle(RalliTheme.ink)
            .navigationTitle(L10n.text("about.privacy")).navigationBarTitleDisplayMode(.inline)
    }
}
