import Foundation

enum MathEvaluator {
    static func evaluate(_ raw: String) -> String? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        if let percent = evaluatePercentage(text) {
            return percent
        }

        let normalized = text
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: ":", with: "/")
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")

        guard normalized.range(of: #"^[0-9+\-*/().]+$"#, options: .regularExpression) != nil else {
            return nil
        }
        guard normalized.contains(where: { "+-*/".contains($0) }) else { return nil }

        let expr = NSExpression(format: normalized)
        guard let value = expr.expressionValue(with: nil, context: nil) as? NSNumber else {
            return nil
        }

        let double = value.doubleValue
        if double.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", double)
        }
        return String(format: "%.4g", double)
    }

    private static func evaluatePercentage(_ text: String) -> String? {
        let lower = text.lowercased()
        let patterns = [
            #"(\d+(?:[.,]\d+)?)\s*%\s*(?:von|of)\s*(\d+(?:[.,]\d+)?)"#,
            #"(\d+(?:[.,]\d+)?)\s*prozent\s*(?:von)\s*(\d+(?:[.,]\d+)?)"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)),
                  match.numberOfRanges >= 3,
                  let pctRange = Range(match.range(at: 1), in: lower),
                  let baseRange = Range(match.range(at: 2), in: lower) else { continue }

            let pct = Double(lower[pctRange].replacingOccurrences(of: ",", with: ".")) ?? 0
            let base = Double(lower[baseRange].replacingOccurrences(of: ",", with: ".")) ?? 0
            let result = base * pct / 100
            if result.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0f", result)
            }
            return String(format: "%.2f", result)
        }
        return nil
    }

    static func looksLikeMath(_ text: String) -> Bool {
        evaluate(text) != nil
    }
}
