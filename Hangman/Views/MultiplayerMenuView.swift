import SwiftUI

struct MultiplayerMenuView: View {
    
    @EnvironmentObject var manager: StatsManager
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"

    var body: some View {
        VStack(spacing: 30) {
            Image(String(7))
                .resizable()
                .scaledToFit()
                .frame(height: 350) // или любое подходящее значение

            NavigationLink(destination: CompetitiveGameView()) {
                Text("⚔️ Играть 1 vs 1")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            NavigationLink(destination: CooperativeGameView(mode: .friends)) {
                Text("🎮 Создать игру")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            NavigationLink(destination: CooperativeGameView(mode: .code_friend)) {
                Text("🔗 Подключиться к игре")
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
                Text("Мультиплеер")
                    .font(.system(size: 28, weight: .bold)) // размер и жирность
                    .multilineTextAlignment(.center)         // центрирование
            }
        }
    }
}

#Preview {
    MainMenuView()
}
