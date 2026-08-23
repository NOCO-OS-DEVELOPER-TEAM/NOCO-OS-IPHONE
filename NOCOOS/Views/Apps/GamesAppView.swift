import SwiftUI

struct GamesAppView: View {
    @State private var selected: GameID?

    enum GameID: String, Identifiable, CaseIterable {
        case snake, memory, reaction
        var id: String { rawValue }
        var title: String {
            switch self {
            case .snake: return "Snake"
            case .memory: return "Memory"
            case .reaction: return "Reaktion"
            }
        }
        var icon: String {
            switch self {
            case .snake: return "circle.grid.cross"
            case .memory: return "square.grid.3x3"
            case .reaction: return "bolt.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(GameID.allCases) { game in
                        Button { selected = game } label: {
                            VStack(spacing: 12) {
                                Image(systemName: game.icon)
                                    .font(.system(size: 32))
                                    .foregroundStyle(.white)
                                Text(game.title)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .nocoGlass(cornerRadius: 20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Color(red: 0.07, green: 0.08, blue: 0.14))
            .navigationTitle("Spiele")
            .navigationDestination(item: $selected) { game in
                switch game {
                case .snake: SnakeGameView()
                case .memory: MemoryGameView()
                case .reaction: ReactionGameView()
                }
            }
        }
        .tint(NOCOOSTheme.accent)
    }
}
