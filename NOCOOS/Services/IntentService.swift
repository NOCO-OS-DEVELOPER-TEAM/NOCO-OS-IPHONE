import Foundation

enum NOCOIntent: Equatable {
    case openApp(NOCOAppID)
    case createNote
    case searchNotes(String)
    case summarizeNotes
    case summarizeText(String)
    case askAI(String)
    case unknown(String)
}

struct IntentService {
    func parse(_ input: String) -> NOCOIntent {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !text.isEmpty else { return .unknown(input) }

        if matches(text, any: ["öffne noco ai", "starte noco ai", "noco ai öffnen", "open noco ai"]) {
            return .openApp(.nocoAI)
        }
        if matches(text, any: ["öffne notizen", "notizen öffnen", "open notes", "notizen app"]) {
            return .openApp(.notes)
        }
        if matches(text, any: ["öffne kamera", "kamera öffnen", "open camera"]) {
            return .openApp(.camera)
        }
        if matches(text, any: ["öffne einstellungen", "einstellungen öffnen", "open settings"]) {
            return .openApp(.settings)
        }
        if matches(text, any: ["neue notiz", "erstelle notiz", "notiz erstellen", "mach eine notiz"]) {
            return .createNote
        }
        if text.contains("notizen") && (text.contains("suche") || text.contains("über") || text.contains("nach")) {
            let query = extractAfterKeywords(text, keywords: ["über", "nach", "suche", "notizen"])
            if !query.isEmpty { return .searchNotes(query) }
        }
        if matches(text, any: ["fasse meine notizen zusammen", "notizen zusammenfassen", "zusammenfassung notizen"]) {
            return .summarizeNotes
        }
        if text.hasPrefix("fasse zusammen") || text.hasPrefix("zusammenfassen") {
            let body = text.replacingOccurrences(of: "fasse zusammen", with: "")
                .replacingOccurrences(of: "zusammenfassen", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !body.isEmpty { return .summarizeText(body) }
        }
        if text.contains("?") || text.contains("wann") || text.contains("was") || text.contains("wie") {
            return .askAI(input)
        }
        return .askAI(input)
    }

    private func matches(_ text: String, any phrases: [String]) -> Bool {
        phrases.contains { text.contains($0) }
    }

    private func extractAfterKeywords(_ text: String, keywords: [String]) -> String {
        for keyword in keywords {
            if let range = text.range(of: keyword) {
                return String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return text.replacingOccurrences(of: "notizen", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
