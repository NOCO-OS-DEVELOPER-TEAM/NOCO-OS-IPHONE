import Foundation

@MainActor
final class AIService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing = false

    private let connection: ConnectionStore
    private let notes: NotesService
    private let settings: SettingsStore
    private let intentService = IntentService()
    private var requestGeneration = 0

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
        guard !isProcessing else { return nil }

        messages.append(ChatMessage(role: .user, text: prompt))
        let generation = beginProcessing()
        defer { endProcessing(generation) }

        return await handleIntent(prompt, router: router)
    }

    func processSpotlightQuery(_ raw: String, router: NOCOOSRouter) async -> String? {
        let prompt = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return nil }
        // Spotlight may run while chat is idle; allow one at a time globally.
        guard !isProcessing else { return "Bitte warte kurz — NOCO AI arbeitet noch." }

        messages.append(ChatMessage(role: .user, text: prompt))
        let generation = beginProcessing()
        defer { endProcessing(generation) }

        if let local = notes.answerFromNotes(question: prompt) {
            guard generation == requestGeneration else { return nil }
            appendAssistant(local)
            return local
        }

        return await askServer(prompt, extraContext: notes.notesContextForAI(), generation: generation)
    }

    func recordSpotlightExchange(user: String, assistant: String) async {
        if !messages.contains(where: { $0.role == .user && $0.text == user }) {
            messages.append(ChatMessage(role: .user, text: user))
        }
        appendAssistant(assistant)
    }

    func analyzeImageDescription(_ description: String) async -> String? {
        guard !isProcessing else { return "Bitte warte kurz — NOCO AI arbeitet noch." }
        messages.append(ChatMessage(role: .user, text: "Bild analysieren: \(description)"))
        let generation = beginProcessing()
        defer { endProcessing(generation) }
        return await askServer(
            "Analysiere dieses Bild und beschreibe, was du siehst. Kontext: \(description)",
            extraContext: nil,
            generation: generation
        )
    }

    func processSelectedText(_ action: String, text: String) async -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard !isProcessing else { return "Bitte warte kurz — NOCO AI arbeitet noch." }

        let prompt: String
        switch action {
        case "summarize": prompt = "Fasse folgenden Text kurz zusammen:\n\(trimmed)"
        case "explain": prompt = "Erkläre folgenden Text einfach:\n\(trimmed)"
        case "rewrite": prompt = "Formuliere folgenden Text freundlicher um:\n\(trimmed)"
        default: prompt = trimmed
        }
        messages.append(ChatMessage(role: .user, text: prompt))
        let generation = beginProcessing()
        defer { endProcessing(generation) }
        return await askServer(prompt, extraContext: nil, generation: generation)
    }

    private func beginProcessing() -> Int {
        requestGeneration += 1
        isProcessing = true
        return requestGeneration
    }

    private func endProcessing(_ generation: Int) {
        if generation == requestGeneration {
            isProcessing = false
        }
    }

    private func handleIntent(_ prompt: String, router: NOCOOSRouter) async -> String? {
        let generation = requestGeneration
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
        case .createNoteWithTitle(let title):
            router.openNotes(createWithTitle: title)
            let reply = "Notiz „\(title)“ wird erstellt."
            appendAssistant(reply)
            return reply
        case .openLastNote:
            if let last = notes.notes.first {
                router.openNotes(noteID: last.id)
                let reply = "Letzte Notiz geöffnet."
                appendAssistant(reply)
                return reply
            }
            let reply = "Keine Notizen vorhanden."
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
        case .calculate(_, let result):
            let reply = "= \(result)"
            appendAssistant(reply)
            return reply
        case .summarizeNotes:
            return await askServer("Fasse meine Notizen kurz zusammen.", extraContext: notes.notesContextForAI(), generation: generation)
        case .summarizeText(let text):
            return await askServer("Fasse folgenden Text zusammen:\n\(text)", generation: generation)
        case .askAI, .unknown:
            if let local = notes.answerFromNotes(question: prompt) {
                appendAssistant(local)
                return local
            }
            return await askServer(prompt, extraContext: notes.notesContextForAI(), generation: generation)
        }
    }

    private func askServer(_ prompt: String, extraContext: String? = nil, generation: Int) async -> String? {
        guard connection.isPaired, let api = connection.api else {
            let offline = "NOCO AI Server nicht verbunden. Bitte in den Einstellungen koppeln."
            appendAssistant(offline)
            return offline
        }

        let processing = ChatMessage(role: .assistant, text: "Denke nach …", isProcessing: true)
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
            guard generation == requestGeneration else {
                messages.removeAll { $0.id == processing.id }
                return nil
            }
            messages.removeAll { $0.id == processing.id }
            appendAssistant(reply)
            settings.log("AI reply (\(reply.count) chars)")
            return reply
        } catch is CancellationError {
            messages.removeAll { $0.id == processing.id }
            return nil
        } catch {
            guard generation == requestGeneration else {
                messages.removeAll { $0.id == processing.id }
                return nil
            }
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
