import SwiftUI

struct WeatherAppView: View {
    @EnvironmentObject private var ai: AIService
    @EnvironmentObject private var connection: ConnectionStore
    @EnvironmentObject private var router: NOCOOSRouter
    @State private var summary = "Lade Wetter …"
    @State private var loading = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 72))
                .foregroundStyle(NOCOOSTheme.accentGlow)
                .symbolEffect(.pulse, options: loading ? .repeating : .nonRepeating)

            Text(summary)
                .font(.title3)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding()

            Button("Mit NOCO AI aktualisieren") {
                Task { await refresh() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(loading || !connection.isPaired)

            if !connection.isPaired {
                Text("Verbinde den NOCO AI Server für Wetter-KI.")
                    .font(.caption)
                    .foregroundStyle(NOCOOSTheme.textSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.07, green: 0.08, blue: 0.14))
        .task { await refresh() }
    }

    private func refresh() async {
        guard connection.isPaired else {
            summary = "22° · Leicht bewölkt\n(Offline-Demo — verbinde NOCO AI für echte Daten.)"
            return
        }
        loading = true
        defer { loading = false }
        if let reply = await ai.processSpotlightQuery("Gib eine kurze Wetter-Zusammenfassung für heute in Deutschland.", router: router) {
            summary = reply
        }
    }
}
