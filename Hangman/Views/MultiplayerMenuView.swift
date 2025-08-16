import SwiftUI

struct MultiplayerMenuView: View {
    
    @EnvironmentObject var manager: StatsManager
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"

    @State private var isPresentingCompetitiveGame = false
    @State private var isPresentingCooperativeGameCreate = false
    @State private var isPresentingCooperativeGameJoin = false

    var body: some View {
        VStack(spacing: 30) {
            Text("Мультиплеер")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Image(String(7))
                .resizable()
                .scaledToFit()
            
            Button(action: {
                isPresentingCompetitiveGame = true
            }) {
                Text("⚔️ Играть 1 vs 1")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .fullScreenCover(isPresented: $isPresentingCompetitiveGame) {
                CompetitiveGameView()
            }

            Button(action: {
                isPresentingCooperativeGameCreate = true
            }) {
                Text("🎮 Создать игру")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .fullScreenCover(isPresented: $isPresentingCooperativeGameCreate) {
                CooperativeGameView(mode: .friends)
            }

            Button(action: {
                isPresentingCooperativeGameJoin = true
            }) {
                Text("🔗 Подключиться к игре")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .fullScreenCover(isPresented: $isPresentingCooperativeGameJoin) {
                CooperativeGameView(mode: .code_friend)
            }

            Spacer()
        }
        .navigationTitle("Назад")
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    MainMenuView()
}
