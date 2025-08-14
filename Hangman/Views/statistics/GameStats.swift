import Foundation

enum GameMode: String, CaseIterable, Identifiable, Codable {
    case single = "Single"
    case multiplayer = "Multiplayer"
    case cooperative = "Cooperative"
    
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
