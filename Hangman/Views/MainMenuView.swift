import SwiftUI

struct MainMenuView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: String = AppTheme.system.rawValue
    
    @State private var attemptsLeft = 8
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Hangman")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                // Анимация смены изображений
                Image(String(attemptsLeft))
                    .resizable()
                    .scaledToFit()
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
                
                NavigationLink(destination: MultiplayerMenuView()) {
                    Text("👥 Мультиплеер")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                NavigationLink(destination: SettingsView()) {
                    Text("⚙️ Настройки")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colorScheme == .dark ? Color.gray.opacity(0.6) : Color.gray.opacity(0.3))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Главная")
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    MainMenuView()
}
