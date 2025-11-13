import SwiftUI

struct MainMenuView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: String = AppTheme.system.rawValue
    @EnvironmentObject var manager: StatsManager

    @State private var attemptsLeft = 8
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView {
            // Главная
            NavigationStack {
                VStack(spacing: 30) {
                    
                    Image(String(attemptsLeft))
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 20)
                        .onReceive(timer) { _ in
                            attemptsLeft = (attemptsLeft + 1) % 9
                        }
                    
                    NavigationLink(destination: GameView()) {
                        Text(NSLocalizedString("single_player", comment: ""))
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    NavigationLink(destination: MultiplayerMenuView()) {
                        Text(NSLocalizedString("multiplayer", comment: ""))
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(NSLocalizedString("main_menu_title", comment: ""))
                            .font(.system(size: 28, weight: .bold)) // размер и жирность
                            .multilineTextAlignment(.center)         // центрирование
                    }
                }
            }
            
            .tabItem {
                Label(NSLocalizedString("home_tab", comment: ""), systemImage: "house")
            }
            
            // Статистика
            NavigationStack {
                StatisticsView()
                    .navigationTitle(NSLocalizedString("statistics_tab", comment: ""))
            }
            .tabItem {
                Label(NSLocalizedString("statistics_tab", comment: ""), systemImage: "chart.bar")
            }
            
            // Настройки
            NavigationStack {
                SettingsView()
                    .navigationTitle(NSLocalizedString("settings_tab", comment: ""))
            }
            .tabItem {
                Label(NSLocalizedString("settings_tab", comment: ""), systemImage: "gear")
            }
        }
    }
}

#Preview {
    MainMenuView()
}
