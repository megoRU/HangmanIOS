import SwiftUI

struct CompetitiveGameView: View {
    @StateObject private var viewModel = GameViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingPlayerList = false

    var body: some View {
        VStack {
            if viewModel.players.isEmpty {
                waitingView
            } else {
                gameContentView
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Соревновательный")
                        .font(.system(size: 20, weight: .bold))
                }
                .multilineTextAlignment(.center)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingPlayerList = true }) {
                    Image(systemName: "person.2.fill")
                }
                .disabled(viewModel.players.isEmpty)
            }
        }
        .sheet(isPresented: $showingPlayerList) {
            PlayerListView(players: viewModel.players)
        }
        .alert("Игра окончена", isPresented: .constant(viewModel.isGameOver)) {
            Button("Выйти") {
                dismiss()
            }
        } message: {
            Text(viewModel.gameResult == "LOSE" ? "Вы проиграли! Слово: \(viewModel.wordToGuess)" : "Вы выиграли! Слово: \(viewModel.wordToGuess)")
        }
        .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            WebSocketManager.shared.findGame(mode: .duel)
        }
        .onDisappear {
            WebSocketManager.shared.leaveGame(gameId: nil)
        }
    }

    private var waitingView: some View {
        VStack(spacing: 16) {
            ProgressView("Ожидание соперника...")
        }
    }
    
    private var gameContentView: some View {
        MultiplayerGameView()
            .environmentObject(viewModel)
    }
}
