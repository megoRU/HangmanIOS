import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var manager: StatsManager
    @State private var selectedMode: GameMode = .single
    
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
    
    var totalWins: Int {
        manager.stats.filter { $0.mode == selectedMode && $0.result == .win }.count
    }

    var totalLosses: Int {
        manager.stats.filter { $0.mode == selectedMode && $0.result == .lose }.count
    }

    var winRate: Double {
        let totalGames = totalWins + totalLosses
        return totalGames == 0 ? 0 : Double(totalWins) / Double(totalGames)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Picker("Режим игры", selection: $selectedMode) {
                    ForEach(GameMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                if manager.stats.filter({ $0.mode == selectedMode }).isEmpty {
                    VStack {
                        Spacer()
                        Text("Нет данных для отображения")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    HStack(spacing: 20) {
                        StatCard(title: "Побед", value: "\(totalWins)", color: .green)
                        StatCard(title: "Поражений", value: "\(totalLosses)", color: .red)
                        StatCard(title: "Процент побед", value: String(format: "%.0f%%", winRate * 100), color: .blue)
                    }
                    .padding(.horizontal)
                    
                    Chart {
                        ForEach(chartData, id: \.date) { item in
                            BarMark(
                                x: .value("Дата", item.date, unit: .day),
                                y: .value("Количество", item.wins),
                                width: .ratio(0.6)
                            )
                            .foregroundStyle(by: .value("Результат", "Победы"))

                            BarMark(
                                x: .value("Дата", item.date, unit: .day),
                                y: .value("Количество", item.losses),
                                width: .ratio(0.6)
                            )
                            .foregroundStyle(by: .value("Результат", "Поражения"))
                        }
                    }
                    .chartForegroundStyleScale([
                        "Победы": .green,
                        "Поражения": .red
                    ])
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.day().month())
                        }
                    }
                    .frame(height: 300)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle("Статистика")
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        StatisticsView()
            .environmentObject(StatsManager.shared)
    }
}
