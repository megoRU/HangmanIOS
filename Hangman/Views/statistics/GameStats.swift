import Foundation

enum GameMode: String, CaseIterable, Identifiable, Codable {
    case single = "Одиночная"
    case multiplayer = "1 vs 1"
    case cooperative = "Совместная"
    
    var id: String { self.rawValue }
}

enum GameResult: String, Codable {
    case win = "Win"
    case lose = "Lose"
}

struct GameStats: Identifiable, Codable {
    let id: UUID
    let mode: GameMode
    let date: Date
    let result: GameResult
}
