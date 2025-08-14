import SwiftUI

struct MultiplayerMenuView: View {
    
    @EnvironmentObject var manager: StatsManager
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"

    var body: some View {
        VStack(spacing: 30) {
            Text("Мультиплеер")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Image(String(7))
                .resizable()
                .scaledToFit()
            
            NavigationLink(destination: CompetitiveGameView(manager: manager)) {
                Text("⚔️ Играть 1 vs 1")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            NavigationLink(destination: CooperativeGameView(mode: .friends, manager: manager)) {
                Text("🎮 Создать игру")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            NavigationLink(destination: CooperativeGameView(mode: .code_friend, manager: manager)) {
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
        .navigationTitle("Назад")
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    MultiplayerMenuView()
        .environmentObject(StatsManager.shared)
}
