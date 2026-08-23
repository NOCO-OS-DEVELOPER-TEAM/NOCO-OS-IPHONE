import Foundation

enum NOCOIntent: Equatable {
    case openApp(NOCOAppID)
    case createNote
    case createNoteWithTitle(String)
    case openLastNote
    case searchNotes(String)
    case summarizeNotes
    case summarizeText(String)
    case calculate(String, result: String)
    case askAI(String)
    case unknown(String)

    var isInlineSpotlightAction: Bool {
        switch self {
        case .openApp, .createNote, .createNoteWithTitle, .openLastNote, .searchNotes:
            return false
        case .calculate, .summarizeText, .summarizeNotes, .askAI, .unknown:
            return true
        }
    }
}

struct IntentService {
    private let appAliases: [(NOCOAppID, [String])] = [
        (.nocoAI, ["noco ai", "nocoai", "ki", "ai"]),
        (.notes, ["notizen", "notes", "notiz"]),
        (.camera, ["kamera", "camera"]),
        (.video, ["video", "aufnahme"]),
        (.photos, ["fotos", "photos", "galerie", "bilder"]),
        (.settings, ["einstellungen", "settings"]),
        (.appStore, ["app store", "appstore", "store", "apps"]),
        (.games, ["spiele", "games", "game"]),
        (.calculator, ["rechner", "calculator", "taschenrechner"]),
        (.calendar, ["kalender", "calendar"]),
        (.timer, ["timer", "uhr", "countdown"]),
        (.weather, ["wetter", "weather"]),
        (.music, ["musik", "music"])
    ]

    func parse(_ input: String) -> NOCOIntent {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = text.lowercased()
        guard !text.isEmpty else { return .unknown(input) }

        if let math = MathEvaluator.evaluate(text) {
            return .calculate(text, result: math)
        }

        if matches(lower, any: ["öffne noco ai", "starte noco ai", "noco ai öffnen"]) {
            return .openApp(.nocoAI)
        }

        if let app = matchOpenApp(lower) {
            return .openApp(app)
        }

        if let title = extractNoteTitle(from: lower) {
            return .createNoteWithTitle(title)
        }

        if matches(lower, any: ["letzte notiz", "meine letzte notiz", "öffne letzte notiz"]) {
            return .openLastNote
        }

        if matches(lower, any: ["neue notiz", "erstelle notiz", "notiz erstellen", "mach eine notiz"]) {
            return .createNote
        }

        if lower.contains("notizen") && (lower.contains("suche") || lower.contains("über") || lower.contains("nach")) {
            let query = extractAfterKeywords(lower, keywords: ["über", "nach", "suche", "notizen"])
            if !query.isEmpty { return .searchNotes(query) }
        }

        if matches(lower, any: ["fasse meine notizen zusammen", "notizen zusammenfassen"]) {
            return .summarizeNotes
        }

        if lower.hasPrefix("fasse zusammen") || lower.hasPrefix("zusammenfassen") {
            let body = lower
                .replacingOccurrences(of: "fasse zusammen", with: "")
                .replacingOccurrences(of: "zusammenfassen", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !body.isEmpty { return .summarizeText(body) }
        }

        if lower.hasPrefix("schreib") || lower.hasPrefix("erkläre") || lower.hasPrefix("erklare") ||
            lower.contains("?") || lower.contains("was ") || lower.contains("wie ") || lower.contains("wann ") {
            return .askAI(text)
        }

        if MathEvaluator.looksLikeMath(text) {
            if let result = MathEvaluator.evaluate(text) {
                return .calculate(text, result: result)
            }
        }

        return .askAI(text)
    }

    private func matchOpenApp(_ lower: String) -> NOCOAppID? {
        guard lower.contains("öffne") || lower.contains("open") || lower.contains("starte") || lower.contains("zeig") else {
            return nil
        }
        for (app, aliases) in appAliases {
            if aliases.contains(where: { lower.contains($0) }) {
                return app
            }
        }
        return nil
    }

    private func extractNoteTitle(from lower: String) -> String? {
        let patterns = [
            #"notiz mit dem titel\s+(.+)"#,
            #"notiz mit titel\s+(.+)"#,
            #"notiz erstellen\s+(.+)"#,
            #"erstelle eine notiz\s+(.+)"#
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)),
                  match.numberOfRanges >= 2,
                  let range = Range(match.range(at: 1), in: lower) else { continue }
            let title = String(lower[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty { return title.capitalized }
        }
        return nil
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
