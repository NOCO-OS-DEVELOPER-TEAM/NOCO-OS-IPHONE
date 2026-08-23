import Foundation

struct SearchResult: Identifiable, Hashable {
    enum Kind: String {
        case app
        case note
        case action
        case aiSuggestion
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

        for app in NOCOAppID.homeScreenApps {
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
        case .createNote:
            results.insert(SearchResult(
                kind: .action,
                title: "Neue Notiz",
                subtitle: "Notizen",
                app: .notes,
                noteID: nil,
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
        case .summarizeNotes, .askAI:
            results.insert(SearchResult(
                kind: .aiSuggestion,
                title: "NOCO AI fragen",
                subtitle: query,
                app: .nocoAI,
                noteID: nil,
                query: query
            ), at: 0)
        default:
            break
        }

        return results
    }

    func suggestions() -> [SearchResult] {
        NOCOAppID.homeScreenApps.map { app in
            SearchResult(
                kind: .app,
                title: app.displayName,
                subtitle: "App",
                app: app,
                noteID: nil,
                query: nil
            )
        }
    }
}
