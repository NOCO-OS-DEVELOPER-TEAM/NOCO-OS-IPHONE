import SwiftUI

struct MemoryGameView: View {
    private let symbols = ["star.fill", "heart.fill", "bolt.fill", "moon.fill", "leaf.fill", "flame.fill"]
    @State private var cards: [MemoryCard] = []
    @State private var flipped: [UUID] = []
    @State private var matched: Set<UUID> = []
    @State private var moves = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("Züge: \(moves)").foregroundStyle(.white)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(cards) { card in
                    Button { tap(card) } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(cardColor(card))
                            if flipped.contains(card.id) || matched.contains(card.id) {
                                Image(systemName: card.symbol).foregroundStyle(.white).font(.title2)
                            }
                        }
                        .frame(height: 64)
                    }
                    .buttonStyle(.plain)
                    .disabled(matched.contains(card.id))
                }
            }
            Button("Neu starten") { setup() }
                .foregroundStyle(NOCOOSTheme.accent)
        }
        .padding()
        .background(Color(red: 0.07, green: 0.08, blue: 0.14))
        .onAppear { setup() }
        .navigationTitle("Memory")
    }

    private func cardColor(_ card: MemoryCard) -> Color {
        flipped.contains(card.id) || matched.contains(card.id)
            ? NOCOOSTheme.accent.opacity(0.7)
            : Color.white.opacity(0.12)
    }

    private func setup() {
        var deck: [MemoryCard] = []
        for symbol in symbols {
            deck.append(MemoryCard(symbol: symbol))
            deck.append(MemoryCard(symbol: symbol))
        }
        cards = deck.shuffled()
        flipped = []
        matched = []
        moves = 0
    }

    private func tap(_ card: MemoryCard) {
        guard !flipped.contains(card.id), flipped.count < 2 else { return }
        flipped.append(card.id)
        if flipped.count == 2 {
            moves += 1
            let a = cards.first { $0.id == flipped[0] }
            let b = cards.first { $0.id == flipped[1] }
            if a?.symbol == b?.symbol {
                matched.formInsert(a!.id)
                matched.formInsert(b!.id)
                flipped = []
                NOCOOSTheme.mediumHaptic()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { flipped = [] }
            }
        }
    }
}

private struct MemoryCard: Identifiable {
    let id = UUID()
    let symbol: String
}
