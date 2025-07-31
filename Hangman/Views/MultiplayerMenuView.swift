import SwiftUI

struct MultiplayerMenuView: View {
    @AppStorage("gameLanguage") private var selectedLanguage = "EN"
    @State private var joinGameId = ""
    @State private var showJoinAlert = false

    var body: some View {
        VStack(spacing: 30) {
            Text("Мультиплеер")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            NavigationLink(destination: MultiplayerGameView(mode: .duel)) {
                Text("⚔️ Играть 1 vs 1")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            NavigationLink(destination: MultiplayerGameView(mode: .friends)) {
                Text("👥 Создать игру с другом")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            Button(action: {
                showJoinAlert = true
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
            .alert("Введите Game ID", isPresented: $showJoinAlert) {
                TextField("Game ID", text: $joinGameId)
                Button("Подключиться") {
                    if !joinGameId.isEmpty {
                        // Переход сразу в игру, передаем gameId
                        MultiplayerGameViewModel.manualJoinGameId = joinGameId
                    }
                }
                Button("Отмена", role: .cancel) {}
            }

            Spacer()
        }
        .navigationTitle("")
    }
}

