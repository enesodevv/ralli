import SwiftUI

struct HomeView: View {
    @Binding var selection: Int
    @EnvironmentObject private var store: PlayerStore
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var setup = false
    @State private var composing = false
    @State private var selected: PracticePlan?
    @State private var about = false
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    if isFirstVisit {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.text("personal.title")).font(RalliTheme.title(36)).tracking(-1).accessibilityAddTraits(.isHeader)
                            Text(L10n.text("personal.intro")).ralliFont(size: 15).foregroundStyle(RalliTheme.muted).lineSpacing(4)
                        }
                    }
                    if let draft = store.draft, let plan = PracticePlan.library.first(where: { $0.id == draft.planID }) {
                        VStack(alignment: .leading, spacing: 16) {
                            Eyebrow(text: L10n.text("practice.continue.title"))
                            Text(plan.title).font(RalliTheme.title(29))
                            Text(L10n.step(draft.step + 1, total: plan.steps.count)).ralliFont(size: 13)
                            PrimaryButton(title: L10n.text("practice.resume"), icon: "play.fill") { selected = plan }
                        }.padding(22).background(RalliTheme.lime.opacity(0.4), in: RoundedRectangle(cornerRadius: RalliTheme.radius))
                    } else if let recommendation = store.recommendation {
                        recommendationCard(recommendation)
                    } else {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(L10n.text("personal.empty")).font(RalliTheme.title(28))
                            Text(L10n.text("personal.empty.body")).ralliFont(size: 14).foregroundStyle(RalliTheme.muted)
                            PrimaryButton(title: L10n.text("personal.change")) { setup = true }
                        }.padding(22).background(RalliTheme.surface, in: RoundedRectangle(cornerRadius: RalliTheme.radius))
                    }
                    focusLayout {
                        VStack(alignment: .leading, spacing: 6) {
                            Eyebrow(text: L10n.text("personal.focus"))
                            Text(L10n.text(store.preferences.focus)).font(RalliTheme.title(24))
                            Text("\(L10n.minutes(store.preferences.minutes)) · \(L10n.text("practice." + store.preferences.mode))")
                                .ralliFont(size: 12).foregroundStyle(RalliTheme.muted)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        Button { setup = true } label: {
                            Label(L10n.text(store.preferences.configured ? "personal.change" : "personal.setup"), systemImage: "slider.horizontal.3")
                                .ralliFont(size: 13, weight: .medium).padding(.horizontal, 14).frame(minHeight: 44)
                                .background(RalliTheme.surface, in: Capsule())
                        }.buttonStyle(.plain)
                    }
                    Button { composing = true } label: {
                        HStack(alignment: .center, spacing: 15) {
                            Image(systemName: "mic.fill").ralliFont(size: 20).foregroundStyle(RalliTheme.paper)
                                .frame(width: 48, height: 48).background(RalliTheme.clay, in: Circle()).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(L10n.text("personal.journal")).font(RalliTheme.title(22))
                                Text(L10n.text("personal.journal.body")).ralliFont(size: 13).foregroundStyle(RalliTheme.muted)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "plus").accessibilityHidden(true)
                        }.padding(18).background(RalliTheme.surface, in: RoundedRectangle(cornerRadius: RalliTheme.radius)).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    if let note = store.activeNote {
                        VStack(alignment: .leading, spacing: 12) {
                            Eyebrow(text: L10n.text("personal.cue"))
                            Text(note.title).font(RalliTheme.title(24))
                            Text(note.text).ralliFont(size: 15).lineSpacing(5)
                            Button { selection = 2 } label: {
                                HStack { Text(L10n.text("personal.open.journal")); Image(systemName: "arrow.right") }.ralliFont(size: 13, weight: .medium).frame(minHeight: 44)
                            }.buttonStyle(.plain)
                        }.padding(22).frame(maxWidth: .infinity, alignment: .leading)
                            .overlay(RoundedRectangle(cornerRadius: RalliTheme.radius).stroke(RalliTheme.line, lineWidth: 1))
                    } else if let reflection = store.records.first?.reflection, !reflection.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Eyebrow(text: L10n.text("personal.last"))
                            Text(reflection).font(RalliTheme.title(22))
                        }
                    }
                    Button { selection = 1 } label: {
                        HStack { Text(L10n.text("personal.explore")); Spacer(); Image(systemName: "arrow.right") }.ralliFont(size: 14, weight: .medium).frame(minHeight: 44)
                    }.buttonStyle(.plain)
                }.padding(24)
            }.foregroundStyle(RalliTheme.ink).background(RalliTheme.paper).toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $setup) { PlayerPreferencesView(preferences: store.preferences).ralliPresentationEnvironment() }
                .sheet(isPresented: $composing) { NoteEditor().ralliPresentationEnvironment() }
                .fullScreenCover(item: $selected) { PracticeSessionView(plan: $0).ralliPresentationEnvironment() }
        }
    }
    /// The big editorial headline only greets new players; returning players see their next action first.
    private var isFirstVisit: Bool { store.records.isEmpty && store.notes.isEmpty && store.draft == nil }
    private var focusLayout: AnyLayout {
        textSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(alignment: .top))
    }
    @ViewBuilder private var header: some View {
        if textSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                Text("ralli.").font(RalliTheme.title(33)).tracking(-1.5)
                Text(Date.now, format: .dateTime.weekday(.wide).day().month(.abbreviated)).font(.caption).foregroundStyle(RalliTheme.muted)
                aboutButton
            }
        } else {
            HStack {
                Text("ralli.").font(RalliTheme.title(33)).tracking(-1.5)
                Spacer()
                Text(Date.now, format: .dateTime.weekday(.wide).day().month(.abbreviated)).ralliFont(size: 11, design: .monospaced).foregroundStyle(RalliTheme.muted)
                aboutButton
            }
        }
    }
    private var aboutButton: some View {
        Button { about = true } label: {
            Image(systemName: "info.circle").ralliFont(size: 18).frame(minWidth: 44, minHeight: 44)
        }.buttonStyle(.plain).accessibilityLabel(L10n.text("about.title"))
            .sheet(isPresented: $about) { AboutView().ralliPresentationEnvironment() }
    }
    private func recommendationCard(_ recommendation: PracticeRecommendation) -> some View {
        let plan = recommendation.plan
        return VStack(alignment: .leading, spacing: 17) {
            Eyebrow(text: L10n.text("personal.next"), color: RalliTheme.paper)
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(plan.title).font(RalliTheme.title(31))
                    Text("\(L10n.minutes(plan.minutes)) · \(plan.modeTitle)").ralliFont(size: 12)
                }.frame(maxWidth: .infinity, alignment: .leading)
                if !textSize.isAccessibilitySize { DrillCourtDiagram(pattern: plan.visual).frame(width: 70, height: 105).accessibilityHidden(true) }
            }
            Text(L10n.text(recommendation.matchesFocus ? "personal.reason.exact" : "personal.reason.other"))
                .ralliFont(size: 13).lineSpacing(4)
            Button { selected = plan } label: {
                HStack { Text(L10n.text("practice.start")); Spacer(); Image(systemName: "arrow.up.right") }
                    .ralliFont(size: 15, weight: .semibold).padding(17).foregroundStyle(RalliTheme.ink)
                    .background(RalliTheme.paper, in: RoundedRectangle(cornerRadius: RalliTheme.smallRadius))
            }.buttonStyle(.plain)
        }.padding(23).foregroundStyle(RalliTheme.paper).background(RalliTheme.clay, in: RoundedRectangle(cornerRadius: RalliTheme.radius))
    }
}
