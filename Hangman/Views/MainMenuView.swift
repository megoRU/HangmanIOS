import SwiftUI

struct MainMenuView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: String = AppTheme.system.rawValue
    @EnvironmentObject var manager: StatsManager

    @State private var attemptsLeft = 8
    @State private var isTabBarHidden = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView {
            // Главная
            NavigationStack {
                VStack(spacing: 30) {
                    Text("Hangman")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 40)
                    
                    Image(String(attemptsLeft))
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 20)
                        .onReceive(timer) { _ in
                            attemptsLeft = (attemptsLeft + 1) % 9
                        }
                    
                    NavigationLink(destination: GameView()) {
                        Text("🎮 Одиночная")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    NavigationLink(destination: MultiplayerMenuView(isTabBarHidden: $isTabBarHidden)) {
                        Text("👥 Мультиплеер")
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
                .navigationTitle("Главная")
                .toolbar(.hidden, for: .navigationBar)
            }
            .toolbar(isTabBarHidden ? .hidden : .visible, for: .tabBar)
            .tabItem {
                Label("Главная", systemImage: "house")
            }
            
            // Статистика
            NavigationStack {
                StatisticsView()
                    .navigationTitle("Статистика")
            }
            .tabItem {
                Label("Статистика", systemImage: "chart.bar")
            }
            
            // Настройки
            NavigationStack {
                SettingsView()
                    .navigationTitle("Настройки")
            }
            .tabItem {
                Label("Настройки", systemImage: "gear")
            }
        }
    }
}

#Preview {
    MainMenuView()
}
