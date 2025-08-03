import SwiftUI

struct CompetitiveGameView: View {
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"
    @StateObject private var viewModel = CompetitiveGameViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        gameContentView
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
            print("🔌 onConnect:", selectedLanguage)
            viewModel.connect(language: selectedLanguage)
        }
        .onDisappear {
            print("🔌 onDisappear вызван")
            viewModel.leaveGame()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.disconnect()
            }
        }
    }

    private var gameContentView: some View {
        VStack(spacing: 20) {

            if viewModel.maskedWord != "" {
                
                Image(String(8 - viewModel.attemptsLeft))
                    .resizable()
                    .scaledToFit()
                
                Text(viewModel.maskedWord)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(viewModel.alphabet, id: \.self) { letter in
                        Button(action: {
                            viewModel.chooseLetter(letter)
                        }) {
                            Text(String(letter))
                                .frame(width: 40, height: 40)
                                .background(viewModel.guessedLetters.contains(letter) ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(viewModel.guessedLetters.contains(letter) || viewModel.gameOver)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    MainMenuView()
}

import Foundation
import SwiftUI

final class CompetitiveGameViewModel: ObservableObject, WebSocketManagerDelegate {

    @Published var maskedWord = ""
    @Published var attemptsLeft = 8
    @Published var guessedLetters = Set<Character>()
    @Published var statusText = "Подключение..."
    @Published var gameOver = false
    @Published var gameOverMessage = ""
    @Published var opponentLeftAlert = false
    @Published var shouldExitGame = false
    @Published var createdGameId: String? = nil
    @Published var playerCount = 0

    @AppStorage("gameLanguage") private var selectedLanguage = "RU"
    private var webSocketManager = WebSocketManager()
    private(set) var currentGameId: String?

    public var alphabet: [Character] {
        selectedLanguage == "RU"
        ? Array("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ")
        : Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    }

    // MARK: - Подключение
    func connect(language: String) {
        statusText = "Подключение..."
        webSocketManager.delegate = self
        webSocketManager.connect(mode: .duel, language: language)
    }

    // MARK: - Выход и разрыв
    func leaveGame() {
        print("🔌 leaveGame вызван")
        webSocketManager.leaveGame(gameId: currentGameId)
    }

    func disconnect() {
        leaveGame()
        webSocketManager.disconnect()
    }

    // MARK: - Ходы
    func chooseLetter(_ letter: Character) {
        guard !gameOver, !guessedLetters.contains(letter), let gameId = currentGameId else { return }
        guessedLetters.insert(letter)
        webSocketManager.sendMove(letter: letter, gameId: gameId)
    }

    func startNewGame() {
        resetGame()
        webSocketManager.disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.connect(language: self.selectedLanguage)
        }
    }

    func resetGame() {
        maskedWord = ""
        attemptsLeft = 8
        guessedLetters.removeAll()
        statusText = "Подключение..."
        gameOver = false
        gameOverMessage = ""
        currentGameId = nil
        createdGameId = nil
        opponentLeftAlert = false
        shouldExitGame = false
    }

    // MARK: - WebSocketManagerDelegate

    func didReceiveWaiting() {
        statusText = "Ожидание соперника..."
    }

    func didReceiveWaitingFriend() {
        // This should not be called in duel mode
    }

    func didFindMatch(wordLength: Int) {
        statusText = "Игра началась!"
        maskedWord = String(repeating: "_ ", count: wordLength).trimmingCharacters(in: .whitespaces)
        attemptsLeft = 8
        guessedLetters.removeAll()
        gameOver = false
        opponentLeftAlert = false
        currentGameId = webSocketManager.currentGameId
        playerCount = 2
    }

    func didReceiveStateUpdate(maskedWord: String, attemptsLeft: Int, duplicate: Bool, guessed: Set<String>?) {
        self.maskedWord = maskedWord.replacingOccurrences(of: "\u{2007}", with: " ")
        self.attemptsLeft = attemptsLeft
        if let guessed = guessed {
            self.guessedLetters = Set(guessed.map { Character($0) })
        }
    }

    func didReceiveGameOver(win: Bool, word: String) {
        gameOver = true
        gameOverMessage = win ? "Вы выиграли!\nСлово: \(word)" : "Вы проиграли!\nСлово: \(word)"
        statusText = "Игра окончена"
        shouldExitGame = true
    }

    func didReceivePlayerLeft(playerId: String) {
        gameOver = true
        gameOverMessage = "Противник вышел. Победа за вами!"
        shouldExitGame = true
    }

    func didReceiveError(_ message: String) {
        statusText = "Ошибка: \(message)"
    }

    func didCreateRoom(gameId: String) {
        // This should not be called in duel mode
    }

    func didReceivePlayerJoined(attemptsLeft: Int, wordLength: Int, players: Int, gameId: String, guessed: Set<String>) {
        // This should not be called in duel mode
    }

    func joinMulti(gameId: String) {
        // Not used in competitive
    }

    func didReceiveCoopGameOver(result: String, word: String, newWord: String) {
        // Not used in competitive
    }
}
