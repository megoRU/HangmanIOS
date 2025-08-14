import Foundation

enum GameMode: String, CaseIterable, Identifiable {
    case single = "Single"
    case multiplayer = "Multiplayer"
    case cooperative = "Cooperative"
    
    var id: String { self.rawValue }
}

enum GameResult: String {
    case win = "Win"
    case lose = "Lose"
}

struct GameStats: Identifiable {
    let id = UUID()
    let mode: GameMode
    let date: Date
    let result: GameResult
}
