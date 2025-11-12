import SwiftUI
import Charts

struct StatisticsView: View {
    @StateObject private var manager = StatsManager.shared
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
            // фон в зависимости от темы
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Picker("Режим игры", selection: $selectedMode) {
                    ForEach(GameMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if manager.stats.filter({ $0.mode == selectedMode }).isEmpty {
                    VStack {
                        Spacer()
                        Text("Нет данных для отображения")
                            .font(.headline)
                            .foregroundColor(.secondary)
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
                            LineMark(
                                x: .value("Дата", item.date, unit: .day),
                                y: .value("Количество", item.wins)
                            )
                            .foregroundStyle(by: .value("Результат", "Победы"))

                            PointMark(
                                x: .value("Дата", item.date, unit: .day),
                                y: .value("Количество", item.wins)
                            )
                            .foregroundStyle(by: .value("Результат", "Победы"))

                            LineMark(
                                x: .value("Дата", item.date, unit: .day),
                                y: .value("Количество", item.losses)
                            )
                            .foregroundStyle(by: .value("Результат", "Поражения"))

                            PointMark(
                                x: .value("Дата", item.date, unit: .day),
                                y: .value("Количество", item.losses)
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
                            AxisValueLabel(format: russianDateFormat)
                        }
                    }
                    .frame(height: 400)
                    .padding()
                    .background(Color(.secondarySystemBackground)) // под тему
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

var russianDateFormat: Date.FormatStyle {
    var style = Date.FormatStyle.dateTime.day().month()
    style.locale = Locale(identifier: "ru_RU")
    return style
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium)) // чуть меньше
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil) // перенос разрешён

            Text(value)
                .font(.system(size: 22, weight: .bold)) // чуть меньше чем 24
                .foregroundColor(color)
                .minimumScaleFactor(0.8) // если число длинное — уменьшит
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    MainMenuView()
}
