import SwiftUI

struct PlayerPreferencesView: View {
    @EnvironmentObject private var store: PlayerStore
    @Environment(\.dismiss) private var dismiss
    @State private var value: PlayerPreferences
    init(preferences: PlayerPreferences) { _value = State(initialValue: preferences) }
    private let focuses = ["Genel", "Forehand", "Backhand", "Servis", "Karşılama", "Vole", "Ayak çalışması"]
    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.text("setup.focus")) {
                    Picker(L10n.text("Vuruş odağı"), selection: $value.focus) {
                        ForEach(focuses, id: \.self) { Text(L10n.text($0)).tag($0) }
                    }
                }
                Section(L10n.text("setup.mode")) {
                    Picker(L10n.text("setup.mode"), selection: $value.mode) {
                        Text(L10n.text("practice.solo")).tag("solo")
                        Text(L10n.text("practice.partner")).tag("partner")
                    }.pickerStyle(.segmented)
                    if value.mode == "solo" { Toggle(L10n.text("setup.wall"), isOn: $value.hasWall) }
                    Picker(L10n.text("setup.time"), selection: $value.minutes) {
                        ForEach([10, 15, 20, 30], id: \.self) { Text(L10n.minutes($0)).tag($0) }
                    }
                }
                Section {
                    Picker(L10n.text("setup.level"), selection: $value.level) {
                        Text(L10n.text("setup.foundation")).tag("foundation")
                        Text(L10n.text("setup.developing")).tag("developing")
                    }.pickerStyle(.inline)
                } footer: { Text(L10n.text("setup.level.body")) }
                Section {
                    if let recommendation = PracticeSelector.recommendation(for: value) {
                        Text(recommendation.plan.title).font(RalliTheme.title(24))
                        Text(L10n.text(recommendation.matchesFocus ? "personal.reason.exact" : "personal.reason.other")).font(.footnote)
                    } else { Text(L10n.text("personal.empty.body")).font(.callout) }
                }
                Section {
                    PrimaryButton(title: L10n.text("setup.done")) {
                        value.configured = true
                        // Keep a linked cue only if its category still matches the chosen focus.
                        if value.focus != store.preferences.focus { value.activeNoteID = nil }
                        if store.savePreferences(value) { dismiss() }
                    }.listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                }
            }.scrollContentBackground(.hidden).background(RalliTheme.paper).tint(RalliTheme.ink)
                .navigationTitle(L10n.text("setup.title")).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button(L10n.text("Vazgeç")) { dismiss() } } }
                .alert(L10n.text("Kayıt sorunu"), isPresented: Binding(get: { store.persistenceError != nil }, set: { if !$0 { store.persistenceError = nil } })) {
                    Button(L10n.text("Tamam"), role: .cancel) { store.persistenceError = nil }
                } message: { Text(store.persistenceError ?? "") }
        }
    }
}
