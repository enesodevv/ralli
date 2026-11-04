import SwiftUI
import UIKit

/// Where a support e-mail is shown. Leave nil until a real, monitored address exists:
/// a dead contact is worse for App Review than none (the App Store page carries the support URL).
enum AppLinks {
    static let supportEmail: String? = nil
}

/// About Ralli: privacy policy (readable in the app, no network needed), safety, content sources,
/// permissions and version. Reachable from Today.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    private var version: String {
        let info = Bundle.main.infoDictionary
        return "\(info?["CFBundleShortVersionString"] as? String ?? "1.0") (\(info?["CFBundleVersion"] as? String ?? "1"))"
    }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ralli.").font(RalliTheme.title(30)).tracking(-1.2)
                        Text(L10n.text("about.tagline")).font(.subheadline).foregroundStyle(RalliTheme.muted)
                    }.padding(.vertical, 6)
                }
                Section {
                    NavigationLink { PrivacyPolicyView() } label: { Label(L10n.text("about.privacy"), systemImage: "hand.raised") }
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    } label: { Label(L10n.text("about.permissions"), systemImage: "gearshape") }
                    if let email = AppLinks.supportEmail, let url = URL(string: "mailto:\(email)") {
                        Link(destination: url) { Label(L10n.text("about.contact"), systemImage: "envelope") }
                    }
                }
                Section(L10n.text("about.safety.title")) {
                    Text(L10n.text("practice.before")).font(.callout)
                }
                Section(L10n.text("about.sources.title")) {
                    Text(L10n.text("about.sources.body")).font(.callout)
                }
                Section {
                    LabeledContent(L10n.text("about.version"), value: version)
                }
            }
            .scrollContentBackground(.hidden).background(RalliTheme.paper).tint(RalliTheme.ink)
            .navigationTitle(L10n.text("about.title")).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.text("Tamam")) { dismiss() } } }
        }
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
