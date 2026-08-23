import SwiftUI

struct CalculatorAppView: View {
    @State private var display = "0"
    @State private var stored: Double?
    @State private var pendingOp: String?

    private let rows: [[String]] = [
        ["C", "±", "%", "÷"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "−"],
        ["1", "2", "3", "+"],
        ["0", ".", "="]
    ]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Text(display)
                    .font(.system(size: 44, weight: .light, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding()

            ForEach(rows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { key in
                        Button { tap(key) } label: {
                            Text(key)
                                .font(.title2.weight(.medium))
                                .foregroundStyle(keyColor(key))
                                .frame(maxWidth: key == "0" ? .infinity : 72, minHeight: 64)
                                .background(keyBackground(key), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        if key == "0" { Spacer(minLength: 0) }
                    }
                }
            }
        }
        .padding()
        .background(Color(red: 0.07, green: 0.08, blue: 0.14))
    }

    private func keyBackground(_ key: String) -> Color {
        if ["÷", "×", "−", "+", "="].contains(key) { return NOCOOSTheme.accent.opacity(0.85) }
        if ["C", "±", "%"].contains(key) { return Color.white.opacity(0.18) }
        return Color.white.opacity(0.10)
    }

    private func keyColor(_ key: String) -> Color { .white }

    private func tap(_ key: String) {
        NOCOOSTheme.selectionHaptic()
        switch key {
        case "C": display = "0"; stored = nil; pendingOp = nil
        case "±": if let v = Double(display.replacingOccurrences(of: ",", with: ".")) { display = format(-v) }
        case "%": if let v = Double(display.replacingOccurrences(of: ",", with: ".")) { display = format(v / 100) }
        case "=": compute()
        case "+", "−", "×", "÷":
            stored = Double(display.replacingOccurrences(of: ",", with: "."))
            pendingOp = key
            display = "0"
        case ".":
            if !display.contains(".") { display += "." }
        default:
            display = display == "0" ? key : display + key
        }
    }

    private func compute() {
        guard let a = stored, let op = pendingOp, let b = Double(display.replacingOccurrences(of: ",", with: ".")) else { return }
        let result: Double
        switch op {
        case "+": result = a + b
        case "−": result = a - b
        case "×": result = a * b
        case "÷": result = b == 0 ? 0 : a / b
        default: return
        }
        display = format(result)
        stored = nil
        pendingOp = nil
    }

    private func format(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", v) : String(v)
    }
}
