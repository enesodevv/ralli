import SwiftUI

struct JournalView: View {
    @Binding var selection: Int
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var activated = false
    @EnvironmentObject private var store: PlayerStore
    @State private var composing = false
    @State private var editing: LessonNote?
    @State private var pendingDeletion: LessonNote?
    @State private var filter = "Tümü"
    private let categories = ["Tümü", "Genel", "Forehand", "Backhand", "Servis", "Karşılama", "Vole", "Ayak çalışması"]
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    Eyebrow(text: L10n.text("Kişisel kort defterin"))
                    HStack { Text(L10n.text("Aklında kalsın.")).font(RalliTheme.title(40)).tracking(-1).accessibilityAddTraits(.isHeader); Spacer() }
                    Text(L10n.text("Bir cümle bazen bütün oyunu değiştirir.")).ralliFont(size: 15).foregroundStyle(RalliTheme.muted)
                    PrimaryButton(title: L10n.text("Bir ders notu ekle"), icon: "plus") { composing = true }
                    if !store.notes.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { value in
                                    Button { filter = value } label: {
                                        Text(L10n.text(value)).ralliFont(size: 12, weight: .medium).padding(.horizontal, 16).padding(.vertical, 11).frame(minHeight: 44)
                                            .foregroundStyle(filter == value ? RalliTheme.paper : RalliTheme.ink)
                                            .background(filter == value ? RalliTheme.ink : RalliTheme.surface, in: Capsule())
                                    }.buttonStyle(.plain).accessibilityAddTraits(filter == value ? [.isSelected] : [])
                                }
                            }
                        }.accessibilityLabel(L10n.text("Not kategorisi"))
                    }
                    if store.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 22) {
                            Image(systemName: "pencil.and.outline").ralliFont(size: 34, weight: .ultraLight).foregroundStyle(RalliTheme.clay)
                            Text(L10n.text("Henüz yazılmamış\ngüzel bir sayfa.")).font(RalliTheme.title(32))
                            Text(L10n.text("Hocandan duyduğun bir ipucu, fark ettiğin bir his ya da tekrar denemek istediğin bir vuruş."))
                                .ralliFont(size: 15).foregroundStyle(RalliTheme.muted).lineSpacing(6)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(26)
                            .background(RalliTheme.surface, in: RoundedRectangle(cornerRadius: RalliTheme.radius))
                    }
                    if !store.notes.isEmpty && filter != "Tümü" && !store.notes.contains(where: { ($0.category ?? "Genel") == filter }) {
                        Text(L10n.text("Bu vuruş için henüz bir not yok.")).font(RalliTheme.title(24)).foregroundStyle(RalliTheme.muted).padding(.vertical, 20)
                    }
                    ForEach(store.notes.filter { filter == "Tümü" || ($0.category ?? "Genel") == filter }) { note in
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Eyebrow(text: note.category ?? "Genel")
                                Spacer()
                                Text(note.date, format: .dateTime.day().month(.abbreviated)).ralliFont(size: 10, design: .monospaced).foregroundStyle(RalliTheme.muted)
                            }
                            Text(note.title).font(RalliTheme.title(27))
                            Text(note.text).ralliFont(size: 15).lineSpacing(5).foregroundStyle(RalliTheme.muted)
                            let isActive = store.preferences.activeNoteID == note.id
                            if isActive {
                                Label(L10n.text("journal.active"), systemImage: "checkmark.circle.fill").font(.footnote.weight(.semibold)).foregroundStyle(RalliTheme.clay)
                            }
                            HStack(spacing: 10) {
                                Button {
                                    if store.activateNote(note) { Analytics.track(.noteActivated); selection = 0 }
                                } label: {
                                    Label(L10n.text("journal.practice"), systemImage: "figure.tennis").ralliFont(size: 13, weight: .semibold)
                                        .padding(.horizontal, 16).frame(minHeight: 44)
                                        .foregroundStyle(RalliTheme.paper).background(RalliTheme.ink, in: Capsule())
                                }.buttonStyle(.plain)
                                Spacer(minLength: 0)
                                Menu {
                                    if !isActive {
                                        Button { if store.activateNote(note) { Analytics.track(.noteActivated); activated = true } } label: { Label(L10n.text("journal.activate"), systemImage: "scope") }
                                    }
                                    ShareLink(item: "\(note.title)\n\n\(note.text)") { Label(L10n.text("Paylaş"), systemImage: "square.and.arrow.up") }
                                    Button { editing = note } label: { Label(L10n.text("Düzenle"), systemImage: "pencil") }
                                    Button(role: .destructive) { pendingDeletion = note } label: { Label(L10n.text("Sil"), systemImage: "trash") }
                                } label: {
                                    Image(systemName: "ellipsis").ralliFont(size: 16, weight: .semibold).frame(minWidth: 44, minHeight: 44)
                                        .background(RalliTheme.paper, in: Circle())
                                }.tint(RalliTheme.ink).accessibilityLabel(L10n.text("journal.more"))
                            }
                        }.padding(24).background(RalliTheme.surface, in: RoundedRectangle(cornerRadius: RalliTheme.radius))
                    }
                }.padding(24)
            }.background(RalliTheme.paper).foregroundStyle(RalliTheme.ink).toolbar(.hidden, for: .navigationBar)
                .alert(L10n.text("journal.cue.done"), isPresented: $activated) { Button(L10n.text("Tamam"), role: .cancel) {} } message: { Text(L10n.text("journal.activated")) }
                .sheet(isPresented: $composing) { NoteEditor().ralliPresentationEnvironment() }
                .sheet(item: $editing) { NoteEditor(note: $0).ralliPresentationEnvironment() }
                .alert(L10n.text("Bu not silinsin mi?"), isPresented: Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } })) {
                    Button(L10n.text("Sil"), role: .destructive) {
                        if let note = pendingDeletion { store.deleteNote(id: note.id) }
                        pendingDeletion = nil
                    }
                    Button(L10n.text("Vazgeç"), role: .cancel) { pendingDeletion = nil }
                } message: { Text(L10n.text("Bu işlem geri alınamaz.")) }
        }
    }

}
struct NoteEditor: View {
    @EnvironmentObject private var store: PlayerStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var speech = SpeechNoteRecorder()
    @State private var textBeforeRecording = ""
    @State private var restoredNoteDraft = false
    @State private var leave = false
    @State private var usedVoice = false
    @State private var skipDraftSave = false
    let note: LessonNote?
    @State private var title: String
    @State private var text: String
    @State private var category: String
    init(note: LessonNote? = nil) {
        self.note = note
        let data = UserDefaults.standard.data(forKey: NoteDraft.key(for: note?.id))
        let draft = data.flatMap { try? JSONDecoder().decode(NoteDraft.self, from: $0) }
        _title = State(initialValue: draft?.title ?? note?.title ?? "")
        _text = State(initialValue: draft?.text ?? note?.text ?? "")
        _category = State(initialValue: draft?.category ?? note?.category ?? "Genel")
        _restoredNoteDraft = State(initialValue: draft != nil)
    }
    var body: some View {
        NavigationStack {
            Form {
                if restoredNoteDraft { Section { Text(L10n.text("journal.draft")).font(.footnote).foregroundStyle(RalliTheme.muted) } }
                Section(L10n.text("Sesli not")) {
                    Button {
                        if speech.recording { speech.stop() }
                        else { textBeforeRecording = text; Task { await speech.start() } }
                    } label: {
                        Label(speech.requesting ? L10n.text("İzinler kontrol ediliyor…") : (speech.recording ? L10n.text("Dinlemeyi bitir") : L10n.text("Konuşarak ekle")), systemImage: speech.recording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.title3.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                            .foregroundStyle(speech.recording ? RalliTheme.clay : RalliTheme.ink)
                    }.disabled(speech.requesting)
                    Text(L10n.text("Yalnızca kendi ders özetini anlat. Konuşma Apple’ın tanıma hizmetiyle işlenebilir; ses dosyası uygulamada saklanmaz."))
                        .font(.footnote).foregroundStyle(RalliTheme.muted)
                    if let message = speech.message { Text(message).font(.footnote).foregroundStyle(RalliTheme.clay) }
                }
                Section(L10n.text("Aklında ne kaldı?")) { TextEditor(text: $text).frame(minHeight: 180).disabled(speech.recording) }
                Section { TextField(L10n.text("Örn. Backhand’de erken hazırlık"), text: $title) } header: { Text(L10n.text("Bugünün odağı")) } footer: { Text(L10n.text("journal.title.hint")) }
                Section(L10n.text("Vuruş")) { Picker(L10n.text("Kategori"), selection: $category) { ForEach(["Genel", "Forehand", "Backhand", "Servis", "Karşılama", "Vole", "Ayak çalışması"], id: \.self) { Text(L10n.text($0)).tag($0) } } }
                Section { Text(L10n.text("Kusursuz yazmana gerek yok. Kortta hatırlamak istediğin şeyi kaydet.")).foregroundStyle(RalliTheme.muted) }
            }.scrollContentBackground(.hidden).background(RalliTheme.paper)
                .navigationTitle(note == nil ? L10n.text("Yeni bir sayfa") : L10n.text("Notunu düzenle")).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button(L10n.text("Vazgeç")) { speech.stop(); if hasChanges { leave = true } else { dismiss() } } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.text("Kaydet")) { let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                            let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            speech.stop()
                            let saved: Bool
                            let finalTitle = cleanTitle.isEmpty ? Self.suggestedTitle(from: cleanText) : cleanTitle
                            if let note { saved = store.updateNote(id: note.id, title: finalTitle, text: cleanText, category: category) }
                            else { saved = store.addNote(title: finalTitle, text: cleanText, category: category) }
                            if saved { Analytics.track(.noteSaved(isNew: note == nil, usedVoice: usedVoice, category: category)) }
                            if saved { skipDraftSave = true; UserDefaults.standard.removeObject(forKey: NoteDraft.key(for: note?.id)); dismiss() } }
                            .disabled(speech.recording || speech.requesting || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }.tint(RalliTheme.ink)
                .onChange(of: speech.transcript) { _, transcript in
                    guard !transcript.isEmpty else { return }
                    usedVoice = true
                    text = textBeforeRecording + (textBeforeRecording.isEmpty ? "" : "\n") + transcript
                }
                .onChange(of: scenePhase) { _, phase in if phase == .background || (phase == .inactive && speech.recording) { speech.stop() } }
                .onChange(of: title) { _, _ in saveNoteDraft() }
                .onChange(of: text) { _, _ in saveNoteDraft() }
                .onChange(of: category) { _, _ in saveNoteDraft() }
                .onDisappear { speech.stop(); saveNoteDraft() }
                .confirmationDialog(L10n.text("journal.leave"), isPresented: $leave, titleVisibility: .visible) {
                    Button(L10n.text("journal.keep")) { saveNoteDraft(); dismiss() }
                    Button(L10n.text("journal.discard"), role: .destructive) {
                        skipDraftSave = true; UserDefaults.standard.removeObject(forKey: NoteDraft.key(for: note?.id)); dismiss()
                    }
                    Button(L10n.text("Devam et"), role: .cancel) {}
                }
                .interactiveDismissDisabled(speech.recording || speech.requesting || hasChanges)
                .alert(L10n.text("Not kaydedilemedi"), isPresented: Binding(get: { store.persistenceError != nil }, set: { if !$0 { store.persistenceError = nil } })) {
                    Button(L10n.text("Tamam"), role: .cancel) { store.persistenceError = nil }
                } message: { Text(store.persistenceError ?? "") }
        }
    }
    /// A title is optional: right after a lesson, speaking the note is the whole task.
    static func suggestedTitle(from text: String) -> String {
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? text
        return firstLine.count > 42 ? String(firstLine.prefix(40)).trimmingCharacters(in: .whitespaces) + "…" : firstLine
    }
    private var hasChanges: Bool {
        title != (note?.title ?? "") || text != (note?.text ?? "") || category != (note?.category ?? "Genel")
    }
    private func saveNoteDraft() {
        guard !skipDraftSave else { return }
        guard hasChanges else { UserDefaults.standard.removeObject(forKey: NoteDraft.key(for: note?.id)); return }
        if let data = try? JSONEncoder().encode(NoteDraft(title: title, text: text, category: category)) {
            UserDefaults.standard.set(data, forKey: NoteDraft.key(for: note?.id))
        }
    }

}
