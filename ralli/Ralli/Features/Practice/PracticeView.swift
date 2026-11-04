import SwiftUI

struct PracticeView: View {
    @EnvironmentObject private var store: PlayerStore
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var setup = false
    @State private var blocked = false
    @State private var focus = "Tümü"
    @State private var mode = "all"
    @State private var query = ""
    @State private var savedOnly = false
    @State private var selected: PracticePlan?
    @AppStorage("savedPracticeIDs") private var savedIDs = ""
    private let focuses = ["Tümü", "Forehand", "Backhand", "Servis", "Karşılama", "Vole", "Ayak çalışması", "Genel"]
    private var favorites: Set<String> { Set(savedIDs.split(separator: ",").map(String.init)) }
    private var filtered: [PracticePlan] {
        PracticePlan.library.filter {
            (focus == "Tümü" || $0.focus == focus) && (mode == "all" || $0.mode == mode) &&
            (!savedOnly || favorites.contains($0.id)) &&
            (query.isEmpty || "\($0.title) \($0.subtitle) \(L10n.text($0.focus))".localizedStandardContains(query))
        }
    }
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Eyebrow(text: L10n.text("Oyun atölyesi"))
                        Spacer()
                        Text(String(format: L10n.text("practice.total"), PracticePlan.library.count))
                            .ralliFont(size: 11, design: .monospaced).foregroundStyle(RalliTheme.muted)
                    }
                    Text(L10n.text("practice.browse")).font(RalliTheme.title(36)).tracking(-1).accessibilityAddTraits(.isHeader)
                    if let draft = store.draft, let plan = PracticePlan.library.first(where: { $0.id == draft.planID }) {
                        Button { selected = plan } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "play.circle.fill").ralliFont(size: 26).accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L10n.text("practice.continue.title")).ralliFont(size: 12, weight: .medium).foregroundStyle(RalliTheme.muted)
                                    Text(plan.title).font(RalliTheme.title(21))
                                    Text(L10n.step(draft.step + 1, total: plan.steps.count)).ralliFont(size: 12)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "arrow.right").accessibilityHidden(true)
                            }.padding(18).background(RalliTheme.lime.opacity(0.45), in: RoundedRectangle(cornerRadius: RalliTheme.radius))
                        }.buttonStyle(.plain)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundStyle(RalliTheme.muted)
                        TextField(L10n.text("practice.search"), text: $query).ralliFont(size: 14).autocorrectionDisabled()
                        if !query.isEmpty { Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel(L10n.text("practice.clear")) }
                    }.padding(15).background(RalliTheme.surface, in: RoundedRectangle(cornerRadius: RalliTheme.smallRadius))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(focuses, id: \.self) { value in
                                Button { focus = value } label: {
                                    Text(L10n.text(value)).ralliFont(size: 12, weight: .medium).padding(.horizontal, 16).padding(.vertical, 11).frame(minHeight: 44)
                                        .foregroundStyle(focus == value ? RalliTheme.paper : RalliTheme.ink)
                                        .background(focus == value ? RalliTheme.ink : RalliTheme.surface, in: Capsule())
                                }.buttonStyle(.plain).accessibilityAddTraits(focus == value ? [.isSelected] : [])
                            }
                        }
                    }
                    HStack(spacing: 14) {
                        Picker(L10n.text("practice.any"), selection: $mode) {
                            Text(L10n.text("practice.any")).tag("all")
                            Text(L10n.text("practice.solo")).tag("solo")
                            Text(L10n.text("practice.partner")).tag("partner")
                        }.tint(RalliTheme.ink).fixedSize()
                        Spacer()
                        Button { savedOnly.toggle() } label: {
                            Label(L10n.text("practice.saved"), systemImage: savedOnly ? "bookmark.fill" : "bookmark")
                                .ralliFont(size: 12, weight: .medium).frame(minHeight: 44)
                        }.tint(savedOnly ? RalliTheme.clay : RalliTheme.ink)
                        Button { setup = true } label: {
                            Image(systemName: "slider.horizontal.3").ralliFont(size: 15).frame(minWidth: 44, minHeight: 44)
                        }.tint(RalliTheme.ink).accessibilityLabel(L10n.text("practice.preferences"))
                    }
                    if query.isEmpty && focus == "Tümü" && mode == "all" && !savedOnly && store.draft == nil,
                       store.preferences.configured, let recommendation = store.recommendation {
                        Eyebrow(text: L10n.text("personal.next"))
                        sessionRow(recommendation.plan)
                        SectionHeading(title: L10n.text("practice.all.library")).padding(.top, 8)
                    }
                    LazyVStack(spacing: 12) {
                        ForEach(filtered) { plan in sessionRow(plan) }
                        if filtered.isEmpty {
                            VStack(spacing: 14) {
                                Image(systemName: "tennisball").ralliFont(size: 30, weight: .ultraLight)
                                Text(L10n.text("practice.empty")).font(RalliTheme.title(23)).multilineTextAlignment(.center)
                                Button(L10n.text("practice.clear")) { query = ""; focus = "Tümü"; mode = "all"; savedOnly = false }
                            }.padding(30).frame(maxWidth: .infinity)
                        }
                    }
                }.padding(24)
            }.background(RalliTheme.paper).foregroundStyle(RalliTheme.ink).toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $setup) { PlayerPreferencesView(preferences: store.preferences).ralliPresentationEnvironment() }
                .alert(L10n.text("practice.existing"), isPresented: $blocked) {
                    Button(L10n.text("practice.resume")) {
                        if let draft = store.draft { selected = PracticePlan.library.first { $0.id == draft.planID } }
                    }
                    Button(L10n.text("Vazgeç"), role: .cancel) {}
                } message: { Text(L10n.text("practice.existing.body")) }
                .fullScreenCover(item: $selected) { PracticeSessionView(plan: $0).ralliPresentationEnvironment() }
        }
    }
    private func sessionRow(_ plan: PracticePlan) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Button { open(plan) } label: {
                HStack(alignment: .top, spacing: 15) {
                    if !textSize.isAccessibilitySize { Image(systemName: plan.symbol).ralliFont(size: 21, weight: .light).frame(width: 44, height: 50)
                        .foregroundStyle(RalliTheme.clay).background(RalliTheme.paper, in: RoundedRectangle(cornerRadius: RalliTheme.smallRadius)).accessibilityHidden(true) }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(plan.title).font(RalliTheme.title(25)).fixedSize(horizontal: false, vertical: true)
                        Text(plan.subtitle).ralliFont(size: 13).foregroundStyle(RalliTheme.muted).lineSpacing(3)
                        HStack(spacing: 8) {
                            Text(L10n.minutes(plan.minutes))
                            Text("·")
                            Text(plan.modeTitle)
                        }.ralliFont(size: 10, weight: .medium, design: .monospaced).foregroundStyle(RalliTheme.muted).padding(.top, 3)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
            Button { toggleSaved(plan.id) } label: {
                Image(systemName: favorites.contains(plan.id) ? "bookmark.fill" : "bookmark").ralliFont(size: 16).frame(minWidth: 44, minHeight: 44)
            }.buttonStyle(.plain).foregroundStyle(favorites.contains(plan.id) ? RalliTheme.clay : RalliTheme.muted)
                .accessibilityLabel(L10n.text(favorites.contains(plan.id) ? "practice.unsave" : "practice.save"))
        }.padding(18).background(RalliTheme.surface, in: RoundedRectangle(cornerRadius: RalliTheme.radius))
    }
    private func open(_ plan: PracticePlan) {
        if let draft = store.draft, draft.planID != plan.id { blocked = true }
        else { selected = plan }
    }
    private func toggleSaved(_ id: String) {
        var saved = favorites
        if saved.contains(id) { saved.remove(id) } else { saved.insert(id) }
        savedIDs = saved.sorted().joined(separator: ",")
    }
}
