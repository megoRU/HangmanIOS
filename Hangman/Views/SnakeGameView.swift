import SwiftUI
import Combine

struct SnakeGameView: View {
    private let gridSize: Int = 20
    private let cellSize: CGFloat = 20
    private let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    
    @State private var snake: [CGPoint] = [CGPoint(x: 5, y: 5)]
    @State private var food: CGPoint = CGPoint(x: 10, y: 10)
    @State private var direction: Direction = .right
    @State private var isGameOver = false
    
    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .stroke(Color.gray, lineWidth: 2)
                    .frame(width: CGFloat(gridSize) * cellSize, height: CGFloat(gridSize) * cellSize)
                
                // Еда
                Rectangle()
                    .fill(Color.red)
                    .frame(width: cellSize, height: cellSize)
                    .position(position(for: food))
                
                // Змейка
                ForEach(0..<snake.count, id: \.self) { i in
                    Rectangle()
                        .fill(i == 0 ? Color.green : Color.green.opacity(0.7))
                        .frame(width: cellSize, height: cellSize)
                        .position(position(for: snake[i]))
                }
                
                if isGameOver {
                    Text("Game Over")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                        .position(x: CGFloat(gridSize) * cellSize / 2,
                                  y: CGFloat(gridSize) * cellSize / 2)
                }
            }
            
            // Кнопки управления
            VStack(spacing: 10) {
                Button("⬆️") { if direction != .down { direction = .up } }
                HStack(spacing: 40) {
                    Button("⬅️") { if direction != .right { direction = .left } }
                    Button("➡️") { if direction != .left { direction = .right } }
                }
                Button("⬇️") { if direction != .up { direction = .down } }
            }
            .font(.largeTitle)
            .padding(.top)
        }
        .onReceive(timer) { _ in
            updateGame()
        }
        .onTapGesture {
            if isGameOver { restartGame() }
        }
    }
    
    private func position(for point: CGPoint) -> CGPoint {
        CGPoint(x: (point.x + 0.5) * cellSize,
                y: (point.y + 0.5) * cellSize)
    }
    
    private func updateGame() {
        guard !isGameOver else { return }
        
        var newHead = snake[0]
        
        switch direction {
        case .up: newHead.y -= 1
        case .down: newHead.y += 1
        case .left: newHead.x -= 1
        case .right: newHead.x += 1
        }
        
        // Проверка столкновений
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
    
    private func spawnFood() {
        var newFood: CGPoint
        repeat {
            newFood = CGPoint(x: CGFloat(Int.random(in: 0..<gridSize)),
                              y: CGFloat(Int.random(in: 0..<gridSize)))
        } while snake.contains(newFood)
        food = newFood
    }
    
    private func restartGame() {
        snake = [CGPoint(x: 5, y: 5)]
        food = CGPoint(x: 10, y: 10)
        direction = .right
        isGameOver = false
    }
}

enum Direction {
    case up, down, left, right
}

struct ContentView: View {
    var body: some View {
        SnakeGameView()
    }
}

#Preview {
    ContentView()
}
