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

        guard isSafeArithmeticExpression(normalized) else { return nil }

        // Avoid NSExpression ObjC exceptions on malformed input.
        guard let value = safeEvaluateNSExpression(normalized) else { return nil }

        let double = value.doubleValue
        guard double.isFinite else { return nil }
        if double.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", double)
        }
        return String(format: "%.4g", double)
    }

    /// Strict validation so NSExpression never receives crash-prone strings.
    private static func isSafeArithmeticExpression(_ s: String) -> Bool {
        guard s.range(of: #"^[0-9+\-*/().]+$"#, options: .regularExpression) != nil else {
            return false
        }
        guard s.contains(where: { "+-*/".contains($0) }) else { return false }
        guard !s.contains("()") else { return false }

        var depth = 0
        var previous: Character = "("
        for ch in s {
            switch ch {
            case "(":
                depth += 1
                if previous.isNumber || previous == ")" { return false }
            case ")":
                depth -= 1
                if depth < 0 { return false }
                if "+-*/(".contains(previous) { return false }
            case "+", "*", "/":
                if "+-*/(".contains(previous) { return false }
            case "-":
                // Allow unary minus after operator or open paren / start.
                if previous == "-" { return false }
            case ".":
                if previous == "." { return false }
            default:
                break
            }
            previous = ch
        }
        guard depth == 0 else { return false }
        guard let last = s.last, !"+-*/.".contains(last) else { return false }
        guard let first = s.first, !"*/+".contains(first) else { return false }
        return true
    }

    private static func safeEvaluateNSExpression(_ format: String) -> NSNumber? {
        // Final structural reject for known NSExpression crash patterns.
        if format.hasPrefix("*") || format.hasPrefix("/") { return nil }
        if format.contains("**") || format.contains("//") || format.contains("*/") || format.contains("/*") {
            return nil
        }
        let expr = NSExpression(format: format)
        return expr.expressionValue(with: nil, context: nil) as? NSNumber
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
            guard result.isFinite else { continue }
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
