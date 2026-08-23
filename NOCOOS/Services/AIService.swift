import Foundation

@MainActor
final class AIService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing = false
    @Published var pendingPrompt: String?

    private let connection: ConnectionStore
    private let notes: NotesService
    private let settings: SettingsStore
    private let intentService = IntentService()

    init(connection: ConnectionStore, notes: NotesService, settings: SettingsStore) {
        self.connection = connection
        self.notes = notes
        self.settings = settings
        messages = [
            ChatMessage(
                role: .assistant,
                text: "Ich bin NOCO AI — das Gehirn von NOCO OS. Sag mir, welche App ich öffnen soll, oder stell mir Fragen zu deinen Notizen."
            )
        ]
    }

    func send(_ raw: String, router: NOCOOSRouter) async -> String? {
        let prompt = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return nil }

        messages.append(ChatMessage(role: .user, text: prompt))
        isProcessing = true
        defer { isProcessing = false }

        let intent = intentService.parse(prompt)
        switch intent {
        case .openApp(let app):
            router.open(app)
            let reply = "\(app.displayName) wird geöffnet."
            appendAssistant(reply)
            return reply
        case .createNote:
            router.openNotes(createNew: true)
            let reply = "Neue Notiz wird erstellt."
            appendAssistant(reply)
            return reply
        case .searchNotes(let query):
            router.openNotes(search: query)
            let hits = notes.search(query)
            let reply = hits.isEmpty
                ? "Keine Notizen zu „\(query)“ gefunden."
                : "Ich habe \(hits.count) Notiz(en) zu „\(query)“ gefunden."
            appendAssistant(reply)
            return reply
        case .summarizeNotes:
            return await askServer(
                "Fasse meine Notizen kurz zusammen.",
                extraContext: notes.notesContextForAI()
            )
        case .summarizeText(let text):
            return await askServer("Fasse folgenden Text zusammen:\n\(text)")
        case .askAI, .unknown:
            if let local = notes.answerFromNotes(question: prompt) {
                appendAssistant(local)
                return local
            }
            return await askServer(prompt, extraContext: notes.notesContextForAI())
        }
    }

    func analyzeImageDescription(_ description: String) async -> String? {
        await askServer("Analysiere dieses Bild: \(description)")
    }

    private func askServer(_ prompt: String, extraContext: String? = nil) async -> String? {
        guard connection.isPaired, let api = connection.api else {
            let offline = "NOCO AI Server nicht verbunden. Bitte in den Einstellungen koppeln."
            appendAssistant(offline)
            return offline
        }

        var processing = ChatMessage(role: .assistant, text: "Denke nach …", isProcessing: true)
        messages.append(processing)

        do {
            let systemContext = """
            Du bist NOCO AI, das intelligente Zentrum von NOCO OS auf dem iPhone.
            Antworte auf Deutsch, kurz und hilfreich.
            Wenn der Nutzer nach Notizen fragt, nutze den Kontext.
            """
            let context = [systemContext, extraContext].compactMap { $0 }.joined(separator: "\n\n")
            let reply = try await api.chat(
                prompt: prompt,
                model: settings.aiModelName == "default" ? nil : settings.aiModelName,
                notesContext: context
            )
            messages.removeAll { $0.id == processing.id }
            appendAssistant(reply)
            settings.log("AI reply (\(reply.count) chars)")
            return reply
        } catch {
            messages.removeAll { $0.id == processing.id }
            let msg = error.localizedDescription
            appendAssistant(msg)
            settings.log("AI error: \(msg)")
            return msg
        }
    }

    private func appendAssistant(_ text: String) {
        messages.append(ChatMessage(role: .assistant, text: text))
    }
}
