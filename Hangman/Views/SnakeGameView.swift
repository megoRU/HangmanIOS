import SwiftUI
import Combine

class SnakeGame: ObservableObject {
    enum Direction {
        case up, down, left, right
    }
    
    let gridSize: Int = 20
    let cellSize: CGFloat = 20
    
    @Published var snake: [CGPoint] = [CGPoint(x: 5, y: 5)]
    @Published var food: CGPoint = CGPoint(x: 10, y: 10)
    @Published var isGameOver = false
    
    private(set) var direction: Direction = .right

    func changeDirection(_ newDirection: Direction) {
        switch newDirection {
        case .up:
            if direction != .down { direction = .up }
        case .down:
            if direction != .up { direction = .down }
        case .left:
            if direction != .right { direction = .left }
        case .right:
            if direction != .left { direction = .right }
        }
    }
    
    func updateGame() {
        guard !isGameOver else { return }
        
        var newHead = snake[0]
        
        switch direction {
        case .up: newHead.y -= 1
        case .down: newHead.y += 1
        case .left: newHead.x -= 1
        case .right: newHead.x += 1
        }
        
        if newHead.x < 0 || newHead.x >= CGFloat(gridSize) ||
            newHead.y < 0 || newHead.y >= CGFloat(gridSize) ||
            snake.contains(newHead) {
            isGameOver = true
            return
        }
        
        snake.insert(newHead, at: 0)
        
        if newHead == food {
            spawnFood()
        } else {
            snake.removeLast()
        }
    }
    
    func position(for point: CGPoint) -> CGPoint {
        CGPoint(x: (point.x + 0.5) * cellSize,
                y: (point.y + 0.5) * cellSize)
    }

    private func spawnFood() {
        var newFood: CGPoint
        repeat {
            newFood = CGPoint(x: CGFloat(Int.random(in: 0..<gridSize)),
                              y: CGFloat(Int.random(in: 0..<gridSize)))
        } while snake.contains(newFood)
        food = newFood
    }
    
    func restartGame() {
        snake = [CGPoint(x: 5, y: 5)]
        food = CGPoint(x: 10, y: 10)
        direction = .right
        isGameOver = false
    }
}

struct SnakeGameView: View {
    @StateObject private var game = SnakeGame()
    private let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .stroke(Color.gray, lineWidth: 2)
                    .frame(width: game.cellSize * CGFloat(game.gridSize), height: game.cellSize * CGFloat(game.gridSize))

                Rectangle()
                    .fill(Color.red)
                    .frame(width: game.cellSize, height: game.cellSize)
                    .position(game.position(for: game.food))

                ForEach(0..<game.snake.count, id: \.self) { i in
                    Rectangle()
                        .fill(i == 0 ? Color.green : Color.green.opacity(0.7))
                        .frame(width: game.cellSize, height: game.cellSize)
                        .position(game.position(for: game.snake[i]))
                }

                if game.isGameOver {
                    Text("Game Over")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                }
            }

            // Кнопки управления
            VStack(spacing: 10) {
                Button("⬆️") { game.changeDirection(.up) }
                HStack(spacing: 40) {
                    Button("⬅️") { game.changeDirection(.left) }
                    Button("➡️") { game.changeDirection(.right) }
                }
                Button("⬇️") { game.changeDirection(.down) }
            }
            .font(.largeTitle)
            .padding(.top)
        }
        .onReceive(timer) { _ in
            game.updateGame()
        }
        .onTapGesture {
            if game.isGameOver { game.restartGame() }
        }
    }
}

struct ContentView: View {
    var body: some View {
        SnakeGameView()
    }
}

#Preview {
    ContentView()
}
