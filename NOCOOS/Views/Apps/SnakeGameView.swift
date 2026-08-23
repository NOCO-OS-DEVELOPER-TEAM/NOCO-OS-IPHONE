import SwiftUI

struct SnakeGameView: View {
    private let grid = 12
    @State private var snake: [CGPoint] = [CGPoint(x: 6, y: 6)]
    @State private var food = CGPoint(x: 3, y: 3)
    @State private var direction = CGPoint(x: 1, y: 0)
    @State private var score = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 16) {
            Text("Score: \(score)").font(.headline).foregroundStyle(.white)
            GeometryReader { geo in
                let cell = min(geo.size.width, geo.size.height) / CGFloat(grid)
                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06))
                    ForEach(snake.indices, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(i == 0 ? NOCOOSTheme.accent : Color.white.opacity(0.8))
                            .frame(width: cell - 2, height: cell - 2)
                            .position(x: snake[i].x * cell + cell / 2, y: snake[i].y * cell + cell / 2)
                    }
                    Circle().fill(Color.red)
                        .frame(width: cell - 4, height: cell - 4)
                        .position(x: food.x * cell + cell / 2, y: food.y * cell + cell / 2)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            controls
        }
        .padding()
        .background(Color(red: 0.07, green: 0.08, blue: 0.14))
        .onAppear { start() }
        .onDisappear { timer?.invalidate() }
        .navigationTitle("Snake")
    }

    private var controls: some View {
        VStack(spacing: 8) {
            Button("↑") { direction = CGPoint(x: 0, y: -1) }.controlButton()
            HStack {
                Button("←") { direction = CGPoint(x: -1, y: 0) }.controlButton()
                Button("→") { direction = CGPoint(x: 1, y: 0) }.controlButton()
            }
            Button("↓") { direction = CGPoint(x: 0, y: 1) }.controlButton()
        }
    }

    private func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.22, repeats: true) { _ in tick() }
    }

    private func tick() {
        guard let head = snake.first else { return }
        var newHead = CGPoint(x: head.x + direction.x, y: head.y + direction.y)
        if newHead.x < 0 { newHead.x = CGFloat(grid - 1) }
        if newHead.y < 0 { newHead.y = CGFloat(grid - 1) }
        if newHead.x >= CGFloat(grid) { newHead.x = 0 }
        if newHead.y >= CGFloat(grid) { newHead.y = 0 }
        if snake.contains(newHead) {
            snake = [CGPoint(x: 6, y: 6)]
            direction = CGPoint(x: 1, y: 0)
            score = 0
            spawnFood()
            return
        }
        snake.insert(newHead, at: 0)
        if newHead == food {
            score += 1
            NOCOOSTheme.lightHaptic()
            spawnFood()
        } else {
            snake.removeLast()
        }
    }

    private func spawnFood() {
        repeat { food = CGPoint(x: CGFloat(Int.random(in: 0..<grid)), y: CGFloat(Int.random(in: 0..<grid))) }
        while snake.contains(food)
    }
}

private extension View {
    func controlButton() -> some View {
        self.font(.title2.bold())
            .foregroundStyle(.white)
            .frame(width: 56, height: 44)
            .nocoGlass(cornerRadius: 12)
    }
}
