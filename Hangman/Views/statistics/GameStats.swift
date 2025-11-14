import Foundation

enum GameMode: String, CaseIterable, Identifiable, Codable {
    case single = "single_player"
    case multiplayer = "competitive"
    case cooperative = "cooperative"
    
    var id: String { self.rawValue }

    var localizedString: String {
        NSLocalizedString(self.rawValue, comment: "")
    }
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
