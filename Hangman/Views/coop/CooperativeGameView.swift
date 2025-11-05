import SwiftUI

struct CooperativeGameView: View {
    let mode: MultiplayerMode
    @StateObject private var viewModel = GameViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var manualJoinId = ""
    @State private var showingPlayerList = false

    var body: some View {
        Group {
            if mode == .code_friend && viewModel.players.isEmpty {
                connectionView
            } else {
                gameContentView
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("Совместная игра")
                        .font(.system(size: 20, weight: .bold))
                }
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
            if mode == .friends {
                WebSocketManager.shared.findGame(mode: .friends)
            }
        }
        .onDisappear {
            WebSocketManager.shared.leaveGame(gameId: nil)
        }
    }
    
    private var connectionView: some View {
        VStack(spacing: 2) {
            TextField("Введите ID игры", text: $manualJoinId)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button {
                WebSocketManager.shared.joinMulti(gameId: manualJoinId)
            } label: {
                Text("Подключиться")
            }
            .disabled(manualJoinId.isEmpty)
            
            Spacer()
        }
        .padding()
    }
    
    private var gameContentView: some View {
        VStack {
            if viewModel.players.isEmpty {
                ProgressView("Ожидание друга...")
            } else {
                MultiplayerGameView()
                    .environmentObject(viewModel)
            }
        }
    }
}
