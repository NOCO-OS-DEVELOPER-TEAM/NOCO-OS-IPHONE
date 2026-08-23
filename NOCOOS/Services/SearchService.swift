import Foundation

struct SearchResult: Identifiable, Hashable {
    enum Kind: String {
        case app
        case note
        case action
        case aiSuggestion
        case calculation
    }

    let id = UUID()
    let kind: Kind
    let title: String
    let subtitle: String
    let app: NOCOAppID?
    let noteID: UUID?
    let query: String?
}

@MainActor
struct SearchService {
    let notes: NotesService
    let intentService = IntentService()

    func search(_ raw: String) -> [SearchResult] {
        let query = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return suggestions() }

        var results: [SearchResult] = []

        if let math = MathEvaluator.evaluate(query) {
            results.append(SearchResult(
                kind: .calculation,
                title: "= \(math)",
                subtitle: query,
                app: nil,
                noteID: nil,
                query: query
            ))
        }

        for app in NOCOAppID.storeApps {
            if app.displayName.lowercased().contains(query.lowercased()) {
                results.append(SearchResult(
                    kind: .app,
                    title: app.displayName,
                    subtitle: "App öffnen",
                    app: app,
                    noteID: nil,
                    query: nil
                ))
            }
        }

        let noteHits = notes.search(query)
        for note in noteHits.prefix(8) {
            results.append(SearchResult(
                kind: .note,
                title: note.title.isEmpty ? "Notiz" : note.title,
                subtitle: note.preview,
                app: .notes,
                noteID: note.id,
                query: query
            ))
        }

        let intent = intentService.parse(query)
        switch intent {
        case .openApp(let app):
            results.insert(SearchResult(
                kind: .action,
                title: "\(app.displayName) öffnen",
                subtitle: "Aktion",
                app: app,
                noteID: nil,
                query: nil
            ), at: 0)
        case .createNote, .createNoteWithTitle:
            results.insert(SearchResult(
                kind: .action,
                title: "Neue Notiz",
                subtitle: "Notizen",
                app: .notes,
                noteID: nil,
                query: nil
            ), at: 0)
        case .openLastNote:
            results.insert(SearchResult(
                kind: .action,
                title: "Letzte Notiz öffnen",
                subtitle: "Notizen",
                app: .notes,
                noteID: notes.notes.first?.id,
                query: nil
            ), at: 0)
        case .searchNotes(let q):
            results.insert(SearchResult(
                kind: .action,
                title: "Notizen durchsuchen",
                subtitle: q,
                app: .notes,
                noteID: nil,
                query: q
            ), at: 0)
        case .calculate(_, let result):
            results.insert(SearchResult(
                kind: .calculation,
                title: "= \(result)",
                subtitle: "Enter für Ergebnis",
                app: nil,
                noteID: nil,
                query: query
            ), at: 0)
        case .summarizeNotes, .askAI, .summarizeText, .unknown:
            results.insert(SearchResult(
                kind: .aiSuggestion,
                title: "NOCO AI fragen",
                subtitle: query,
                app: .nocoAI,
                noteID: nil,
                query: query
            ), at: 0)
        }

        return results
    }

    func suggestions() -> [SearchResult] {
        [
            SearchResult(kind: .aiSuggestion, title: "Wie viel sind 25 % von 400?", subtitle: "Rechnen mit NOCO AI", app: .nocoAI, noteID: nil, query: "Wie viel sind 25 % von 400?"),
            SearchResult(kind: .action, title: "Öffne Kamera", subtitle: "Systemaktion", app: .camera, noteID: nil, query: nil),
            SearchResult(kind: .action, title: "Neue Notiz", subtitle: "Notizen", app: .notes, noteID: nil, query: nil)
        ] + NOCOAppID.homeScreenApps.prefix(6).map { app in
            SearchResult(kind: .app, title: app.displayName, subtitle: "App", app: app, noteID: nil, query: nil)
        }
    }
}
