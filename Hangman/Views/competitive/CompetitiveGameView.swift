import SwiftUI

struct CompetitiveGameView: View {
    @StateObject private var viewModel = CompetitiveGameViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.statusText == "Подключение..." || viewModel.statusText == "Ожидание соперника..." {
                ProgressView(viewModel.statusText)
            } else {
                GameContentView(
                    attemptsLeft: viewModel.attemptsLeft,
                    maskedWord: viewModel.maskedWord,
                    alphabet: viewModel.alphabet,
                    guessedLetters: viewModel.guessedLetters,
                    onLetterTapped: viewModel.chooseLetter
                )
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Соревновательный")
                        .font(.system(size: 20, weight: .bold))

                    Text(viewModel.statusText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .multilineTextAlignment(.center)
            }
        }
        .alert("Игра окончена", isPresented: $viewModel.gameOver) {
            Button("Новая игра") {
                viewModel.startNewGame()
            }
            Button("Выйти") {
                dismiss()
            }
        } message: {
            Text(viewModel.gameOverMessage)
        }
        .onAppear {
            viewModel.connect(mode: .duel, language: viewModel.selectedLanguage)
        }
        .onDisappear {
            viewModel.disconnect()
        }
    }
}

@MainActor
final class CompetitiveGameViewModel: MultiplayerGameViewModel {

    override func startNewGame() {
        resetGame()
        webSocketManager.disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.connect(mode: .duel, language: self.selectedLanguage)
        }
    }

    // MARK: - Delegate methods that are not used in competitive mode

    override func didCreateRoom(gameId: String) {
        // This should not be called in duel mode
    }

    override func didReceivePlayerJoined(attemptsLeft: Int, wordLength: Int, players: Int, gameId: String, guessed: Set<String>) {
        // This should not be called in duel mode
    }

    override func didReceiveWaitingFriend() {
        // This should not be called in duel mode
    }

    override func didReceiveCoopGameOver(result: String, word: String, newWord: String) {
        // Not used in competitive
    }
}

#Preview {
    MainMenuView()
}
