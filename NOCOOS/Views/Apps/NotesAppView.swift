import SwiftUI

struct NotesAppView: View {
    @EnvironmentObject private var notes: NotesService
    @EnvironmentObject private var router: NOCOOSRouter

    @State private var searchText = ""
    @State private var selectedNote: Note?
    @State private var showingEditor = false

    private var filtered: [Note] {
        searchText.isEmpty ? notes.notes : notes.search(searchText)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { note in
                    Button {
                        selectedNote = note
                        showingEditor = true
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
                            if !note.tags.isEmpty {
                                Text(note.tags.map { "#\($0)" }.joined(separator: " "))
                                    .font(.caption2)
                                    .foregroundStyle(NOCOOSTheme.accentGlow)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.white.opacity(0.06))
                    .swipeActions {
                        Button(role: .destructive) {
                            notes.delete(note)
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                        Button {
                            notes.toggleFavorite(note)
                        } label: {
                            Label("Favorit", systemImage: "star")
                        }
                        .tint(.yellow)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .searchable(text: $searchText, prompt: "Notizen durchsuchen")
            .navigationTitle("Notizen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectedNote = notes.create()
                        showingEditor = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                if let selectedNote {
                    NoteEditorView(note: selectedNote)
                }
            }
        }
        .onAppear(perform: handleLaunchAction)
        .onChange(of: router.notesLaunchAction) { _, _ in handleLaunchAction() }
    }

    private func handleLaunchAction() {
        guard let action = router.notesLaunchAction else { return }
        switch action {
        case .createNew:
            selectedNote = notes.create()
            showingEditor = true
        case .openNote(let id):
            if let note = notes.notes.first(where: { $0.id == id }) {
                selectedNote = note
                showingEditor = true
            }
        case .search(let q):
            searchText = q
        }
        router.notesLaunchAction = nil
    }
}
