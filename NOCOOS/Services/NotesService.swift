import Foundation
import Combine

@MainActor
final class NotesService: ObservableObject {
    @Published private(set) var notes: [Note] = []

    private let storageKey = "nocoos.notes.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? decoder.decode([Note].self, from: data) else {
            notes = Self.sampleNotes
            persist()
            return
        }
        notes = decoded.sorted { $0.updatedAt > $1.updatedAt }
    }

    func persist() {
        guard let data = try? encoder.encode(notes) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    @discardableResult
    func create(title: String = "", body: String = "", tags: [String] = []) -> Note {
        let note = Note(title: title, body: body, tags: tags)
        notes.insert(note, at: 0)
        persist()
        return note
    }

    func update(_ note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        var updated = note
        updated.updatedAt = Date()
        notes[index] = updated
        notes.sort { $0.updatedAt > $1.updatedAt }
        persist()
    }

    func delete(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        persist()
    }

    func toggleFavorite(_ note: Note) {
        guard var found = notes.first(where: { $0.id == note.id }) else { return }
        found.isFavorite.toggle()
        update(found)
    }

    func search(_ query: String) -> [Note] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return notes }
        return notes.filter { $0.searchableText.contains(q) }
    }

    func notesContextForAI(limit: Int = 12) -> String {
        let slice = notes.prefix(limit)
        guard !slice.isEmpty else { return "Keine Notizen vorhanden." }
        return slice.map { note in
            let title = note.title.isEmpty ? "Ohne Titel" : note.title
            return "- \(title): \(note.body.replacingOccurrences(of: "\n", with: " "))"
        }.joined(separator: "\n")
    }

    func answerFromNotes(question: String) -> String? {
        let q = question.lowercased()
        let hits = search(question)
        if !hits.isEmpty {
            let lines = hits.prefix(5).map { n in
                let title = n.title.isEmpty ? "Notiz" : n.title
                return "• \(title): \(n.body)"
            }
            return "In deinen Notizen:\n" + lines.joined(separator: "\n")
        }

        if q.contains("fahrschule") || q.contains("fahr") {
            let related = notes.filter {
                $0.searchableText.contains("fahr") || $0.searchableText.contains("fahrschule")
            }
            if !related.isEmpty {
                return related.map { "• \($0.body)" }.joined(separator: "\n")
            }
        }
        return nil
    }

    private static let sampleNotes: [Note] = [
        Note(
            title: "Fahrschule",
            body: "Fahrschule Dienstag 19 Uhr. Thema 7.",
            tags: ["fahrschule"],
            isFavorite: true
        ),
        Note(
            title: "NOCO OS Ideen",
            body: "Homescreen mit Liquid Glass, Spotlight, NOCO AI als System-Assistent.",
            tags: ["noco", "dev"]
        )
    ]
}
