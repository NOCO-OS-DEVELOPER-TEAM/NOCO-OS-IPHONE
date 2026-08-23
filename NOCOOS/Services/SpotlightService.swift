import Foundation
import SwiftUI

@MainActor
final class SpotlightService: ObservableObject {
    @Published var entries: [SpotlightEntry] = []
    @Published var isProcessing = false

    private let intentService = IntentService()

    func submit(
        _ raw: String,
        ai: AIService,
        router: NOCOOSRouter,
        notes: NotesService
    ) async {
        let query = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        entries.append(SpotlightEntry(role: .user, text: query))
        isProcessing = true
        defer { isProcessing = false }

        let intent = intentService.parse(query)

        switch intent {
        case .calculate(_, let result):
            appendAssistant("= \(result)")
            await ai.recordSpotlightExchange(user: query, assistant: result)

        case .openApp(let app):
            appendAction("\(app.displayName) wird geöffnet …")
            await ai.recordSpotlightExchange(user: query, assistant: "\(app.displayName) geöffnet.")
            router.closeSpotlight()
            router.open(app)

        case .createNote:
            appendAction("Neue Notiz wird erstellt …")
            await ai.recordSpotlightExchange(user: query, assistant: "Neue Notiz erstellt.")
            router.closeSpotlight()
            router.openNotes(createNew: true)

        case .createNoteWithTitle(let title):
            appendAction("Notiz „\(title)“ wird vorbereitet …")
            await ai.recordSpotlightExchange(user: query, assistant: "Notiz „\(title)“ erstellt.")
            router.closeSpotlight()
            router.openNotes(createWithTitle: title)

        case .openLastNote:
            if let last = notes.notes.first {
                appendAction("Letzte Notiz wird geöffnet …")
                await ai.recordSpotlightExchange(user: query, assistant: "Notiz geöffnet: \(last.title.isEmpty ? "Ohne Titel" : last.title)")
                router.closeSpotlight()
                router.openNotes(noteID: last.id)
            } else {
                let msg = "Keine Notizen vorhanden."
                appendAssistant(msg)
                await ai.recordSpotlightExchange(user: query, assistant: msg)
            }

        case .searchNotes(let q):
            let hits = notes.search(q)
            if hits.isEmpty {
                let msg = "Keine Notizen zu „\(q)“ gefunden."
                appendAssistant(msg)
                await ai.recordSpotlightExchange(user: query, assistant: msg)
            } else {
                let preview = hits.prefix(3).map { "• \($0.title.isEmpty ? $0.preview : $0.title)" }.joined(separator: "\n")
                appendAssistant(preview)
                await ai.recordSpotlightExchange(user: query, assistant: preview)
            }

        case .summarizeNotes, .summarizeText, .askAI, .unknown:
            var processing = SpotlightEntry(role: .assistant, text: "Denke nach …", isProcessing: true)
            entries.append(processing)
            let reply = await ai.processSpotlightQuery(query, router: router)
            entries.removeAll { $0.id == processing.id }
            appendAssistant(reply ?? "Keine Antwort erhalten.")
        }
    }

    func clear() {
        entries.removeAll()
    }

    private func appendAssistant(_ text: String) {
        withAnimation(NOCOOSTheme.spring(response: 0.38)) {
            entries.append(SpotlightEntry(role: .assistant, text: text))
        }
    }

    private func appendAction(_ text: String) {
        withAnimation(NOCOOSTheme.spring(response: 0.38)) {
            entries.append(SpotlightEntry(role: .action, text: text))
        }
    }
}
