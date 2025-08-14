import SwiftUI

class StatsManager: ObservableObject {
    static let shared = StatsManager()

    @Published var stats: [GameStats] = []
    
    private let statsKey = "hangman_stats"

    private init() {
        loadStats()
    }

    func addStat(mode: GameMode, result: GameResult) {
        let newStat = GameStats(id: UUID(), mode: mode, date: Date(), result: result)
        stats.append(newStat)
        saveStats()
    }

    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: statsKey)
        }
    }

    private func loadStats() {
        if let data = UserDefaults.standard.data(forKey: statsKey) {
            if let decoded = try? JSONDecoder().decode([GameStats].self, from: data) {
                stats = decoded
                return
            }
        }
        stats = []
    }
}
