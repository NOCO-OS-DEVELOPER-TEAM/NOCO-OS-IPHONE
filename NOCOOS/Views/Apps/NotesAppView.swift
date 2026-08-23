import SwiftUI

struct NotesAppView: View {
    @EnvironmentObject private var notes: NotesService
    @EnvironmentObject private var router: NOCOOSRouter
    @EnvironmentObject private var bridge: SystemBridge

    @State private var searchText = ""
    @State private var editingNote: Note?

    private var filtered: [Note] {
        searchText.isEmpty ? notes.notes : notes.search(searchText)
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    ContentUnavailableView(
                        "Keine Notizen",
                        systemImage: "note.text",
                        description: Text("Tippe + um eine Notiz zu erstellen.")
                    )
                    .foregroundStyle(.white)
                } else {
                    List {
                        ForEach(filtered) { note in
                            Button {
                                editingNote = note
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(note.title.isEmpty ? "Ohne Titel" : note.title)
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        if note.isFavorite {
                                            Image(systemName: "star.fill")
                                                .font(.caption)
                                                .foregroundStyle(.yellow)
                                        }
                                    }
                                    Text(note.preview)
                                        .font(.subheadline)
                                        .foregroundStyle(NOCOOSTheme.textSecondary)
                                        .lineLimit(2)
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.white.opacity(0.06))
                            .swipeActions {
                                Button(role: .destructive) { notes.delete(note) } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                                Button { notes.toggleFavorite(note) } label: {
                                    Label("Favorit", systemImage: "star")
                                }
                                .tint(.yellow)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color(red: 0.07, green: 0.08, blue: 0.14))
            .searchable(text: $searchText, prompt: "Notizen durchsuchen")
            .navigationTitle("Notizen")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editingNote = notes.create()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(.white)
                    }
                }
            }
            .navigationDestination(item: $editingNote) { note in
                NoteEditorView(note: note)
            }
        }
        .tint(NOCOOSTheme.accent)
        .onAppear(perform: handleLaunchAction)
        .onChange(of: router.notesLaunchAction) { _, _ in handleLaunchAction() }
        .onChange(of: bridge.pendingNoteFromText) { _, text in
            if let text, !text.isEmpty {
                var note = notes.create(title: "NOCO AI", body: text)
                editingNote = note
                _ = bridge.consumeNoteFromText()
            }
        }
    }

    private func handleLaunchAction() {
        guard let action = router.notesLaunchAction else { return }
        switch action {
        case .createNew:
            editingNote = notes.create()
        case .createWithTitle(let title):
            editingNote = notes.create(title: title)
        case .openLast:
            if let last = notes.notes.first {
                editingNote = last
            }
        case .openNote(let id):
            if let note = notes.notes.first(where: { $0.id == id }) {
                editingNote = note
            }
        case .search(let q):
            searchText = q
        }
        router.notesLaunchAction = nil
    }
}
