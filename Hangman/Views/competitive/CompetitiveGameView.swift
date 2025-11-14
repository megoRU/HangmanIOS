import SwiftUI

struct CompetitiveGameView: View {
    @StateObject private var viewModel = GameViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingPlayerList = false
    @State private var hasStartedSearch = false

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
                    Text(NSLocalizedString("competitive_game_title", comment: ""))
                        .font(.system(size: 20, weight: .bold))
                }
                .multilineTextAlignment(.center)
            }
            if !viewModel.players.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingPlayerList = true }) {
                        Image(systemName: "person.2.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showingPlayerList) {
            PlayerListView(players: viewModel.players)
        }
        .alert(NSLocalizedString("game_over_alert_title", comment: ""), isPresented: .constant(viewModel.isGameOver)) {
            Button(NSLocalizedString("new_game_button", comment: "")) {
                viewModel.resetAndFindGame()
            }
            Button(NSLocalizedString("exit_button", comment: "")) {
                dismiss()
            }
        } message: {
            Text(viewModel.gameResult == "LOSE" ? String(format: NSLocalizedString("you_lost_competitive_alert_message", comment: ""), viewModel.wordToGuess) : String(format: NSLocalizedString("you_won_competitive_alert_message", comment: ""), viewModel.wordToGuess))
        }
        .alert(NSLocalizedString("error_alert_title", comment: ""), isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            if !hasStartedSearch {
                hasStartedSearch = true
                WebSocketManager.shared.findGame(mode: .duel)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    WebSocketManager.shared.leaveGame(gameId: viewModel.gameId)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        }
    }

    private var waitingView: some View {
        VStack(spacing: 16) {
            ProgressView(NSLocalizedString("waiting_for_opponent_progress", comment: ""))
        }
    }
    
    private var gameContentView: some View {
        MultiplayerGameView()
            .environmentObject(viewModel)
    }
}
