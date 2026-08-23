import SwiftUI

struct ReactionGameView: View {
    @State private var gameState: GameState = .waiting
    @State private var startTime = Date()
    @State private var best: Double?
    @State private var message = "Warte auf Grün …"

    enum GameState { case waiting, ready, tapped, tooEarly }

    var body: some View {
        VStack(spacing: 20) {
            Text(message)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            if let best {
                Text(String(format: "Bestzeit: %.3f s", best))
                    .foregroundStyle(NOCOOSTheme.textSecondary)
            }
            Button(action: tap) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(color)
                    .frame(height: 220)
                    .overlay(Text(buttonLabel).font(.headline).foregroundStyle(.white))
            }
            .buttonStyle(.plain)
            .disabled(gameState == .waiting)
        }
        .padding()
        .background(Color(red: 0.07, green: 0.08, blue: 0.14))
        .onAppear { scheduleRound() }
        .navigationTitle("Reaktion")
    }

    private var color: Color {
        switch gameState {
        case .waiting: return .red.opacity(0.8)
        case .ready: return .green
        case .tapped: return NOCOOSTheme.accent
        case .tooEarly: return .orange
        }
    }

    private var buttonLabel: String {
        switch gameState {
        case .waiting: return "Nicht tippen!"
        case .ready: return "JETZT!"
        case .tapped: return "Nochmal"
        case .tooEarly: return "Zu früh!"
        }
    }

    private func scheduleRound() {
        gameState = .waiting
        message = "Warte auf Grün …"
        let delay = Double.random(in: 1.2...3.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if gameState == .waiting {
                gameState = .ready
                startTime = Date()
                message = "Tippe jetzt!"
                NOCOOSTheme.mediumHaptic()
            }
        }
    }

    private func tap() {
        switch gameState {
        case .waiting:
            gameState = .tooEarly
            message = "Zu früh! Warte auf Grün."
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { scheduleRound() }
        case .ready:
            let elapsed = Date().timeIntervalSince(startTime)
            gameState = .tapped
            message = String(format: "%.3f Sekunden!", elapsed)
            if best == nil || elapsed < best! { best = elapsed }
            NOCOOSTheme.mediumHaptic()
        case .tapped, .tooEarly:
            scheduleRound()
        }
    }
}
