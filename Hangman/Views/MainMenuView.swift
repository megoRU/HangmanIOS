import SwiftUI

struct MainMenuView: View {
    @AppStorage("appTheme") private var selectedTheme = "system"
    @Environment(\.colorScheme) var systemScheme

    var preferredScheme: ColorScheme? {
        switch selectedTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Text("Hangman")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 60)

                NavigationLink(destination: GameView()) {
                    Text("🎮 Начать игру")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                NavigationLink(destination: SettingsView()) {
                    Text("⚙️ Настройки")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            (preferredScheme == .dark || (preferredScheme == nil && systemScheme == .dark))
                                ? Color.gray.opacity(0.6)
                                : Color.gray.opacity(0.3)
                        )
                        .foregroundColor(
                            (preferredScheme == .dark || (preferredScheme == nil && systemScheme == .dark))
                                ? .white
                                : .black
                        )
                        .cornerRadius(12)
                        .padding(.horizontal)
                }


                Spacer()
            }
            .navigationTitle("Главное меню")
            .toolbarBackground(
                preferredScheme == .dark ? Color.black : Color.white,
                for: .navigationBar
            )
        }
        .preferredColorScheme(preferredScheme)
    }
}

#Preview {
    MainMenuView()
}
