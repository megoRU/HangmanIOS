import SwiftUI
import Charts

struct StatisticsView: View {
    @ObservedObject var manager: StatsManager
    @State private var selectedMode: GameMode = .single
    
    // Группируем по дате и считаем победы и поражения
    var chartData: [(date: Date, wins: Int, losses: Int)] {
        let stats = manager.stats.filter { $0.mode == selectedMode }
        let grouped = Dictionary(grouping: stats) { stat in
            Calendar.current.startOfDay(for: stat.date)
        }
        return grouped.map { date, statsOnDate in
            let wins = statsOnDate.filter { $0.result == .win }.count
            let losses = statsOnDate.filter { $0.result == .lose }.count
            return (date, wins, losses)
        }
        .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack {
            Picker("Режим игры", selection: $selectedMode) {
                ForEach(GameMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Chart {
                ForEach(chartData, id: \.date) { item in
                    LineMark(
                        x: .value("Дата", item.date),
                        y: .value("Победы", item.wins)
                    )
                    .foregroundStyle(.green)
                    .symbol(Circle())
                    
                    LineMark(
                        x: .value("Дата", item.date),
                        y: .value("Поражения", item.losses)
                    )
                    .foregroundStyle(.red)
                    .symbol(Circle())
                }
            }
            .frame(height: 300)
            .padding()
            
            Spacer()
        }
    }
}

#Preview {
    MainMenuView()
}
