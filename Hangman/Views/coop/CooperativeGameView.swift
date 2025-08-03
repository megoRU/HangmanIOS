import SwiftUI

struct CooperativeGameView: View {
    let mode: MultiplayerMode
    @StateObject private var viewModel = CooperativeGameViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showCopiedAlert = false
    @State private var manualJoinId = ""

    var body: some View {
        Group {
            if viewModel.currentGameId == nil && mode == .code_friend {
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
                    
                    if viewModel.playerCount > 0 {
                        Text("Игроков: \(viewModel.playerCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(viewModel.statusText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .alert("Игрок вышел", isPresented: $viewModel.shouldExitGame) {
            Button("Выйти") { dismiss() }
        } message: {
            Text(viewModel.gameOverMessage)
        }
        .alert("Игра окончена", isPresented: $viewModel.gameOver) {
            Button("Новая игра") { viewModel.startNewGame() }
            Button("Выйти") { dismiss() }
        } message: {
            Text(viewModel.gameOverMessage)
        }
        .alert("ID скопирован!", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) { }
        }
        .onAppear {
            viewModel.connect(mode: mode, language: viewModel.selectedLanguage)
        }
        .onDisappear {
            viewModel.disconnect()
        }
    }

    private var connectionView: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            TextField("Введите ID игры", text: $manualJoinId)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Подключиться") {
                viewModel.joinMulti(gameId: manualJoinId)
            }
            .disabled(manualJoinId.isEmpty)
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }
    
    @ViewBuilder
    private var gameContentView: some View {
        if viewModel.statusText == "Подключение..." {
            ProgressView(viewModel.statusText)
        } else {
            VStack {
                if let gameId = viewModel.createdGameId, viewModel.playerCount < 2 {
                    HStack {
                        Text("Код комнаты: \(gameId)")
                        Button(action: {
                            UIPasteboard.general.string = gameId
                            showCopiedAlert = true
                        }) {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                    .padding()
                }

                GameContentView(
                    attemptsLeft: viewModel.attemptsLeft,
                    maskedWord: viewModel.maskedWord,
                    alphabet: viewModel.alphabet,
                    guessedLetters: viewModel.guessedLetters,
                    onLetterTapped: viewModel.chooseLetter
                )
            }
        }
    }
}


@MainActor
final class CooperativeGameViewModel: MultiplayerGameViewModel {
    
    private var newWordFromCoop: String?

    override func startNewGame() {
        resetGame()
        if let newWord = newWordFromCoop {
            self.maskedWord = String(repeating: "_", count: newWord.count).map { String($0) }.joined(separator: "\u{2007}")
            self.newWordFromCoop = nil
            self.statusText = "Игра началась"
            self.gameOver = false
        }
    }
    
    override func resetGame() {
        super.resetGame()
        newWordFromCoop = nil
    }

    override func didReceiveCoopGameOver(result: String, word: String, newWord: String) {
        self.gameOver = true
        self.gameOverMessage = (result == "WIN" ? "Вы победили!" : "Вы проиграли!") + "\nСлово: \(word)"
        self.newWordFromCoop = newWord
        self.statusText = "Игра окончена"
    }

    override func didReceivePlayerLeft(playerId: String) {
        gameOver = true
        gameOverMessage = "Друг вышел из игры."
        shouldExitGame = true
    }
}

#Preview {
    MainMenuView()
}
