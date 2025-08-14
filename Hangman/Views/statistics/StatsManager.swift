import SwiftUI

class StatsManager: ObservableObject {
    @Published var stats: [GameStats] = []
    
    func addStat(mode: GameMode, result: GameResult) {
        let newStat = GameStats(mode: mode, date: Date(), result: result)
        stats.append(newStat)
    }
}
