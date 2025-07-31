import SwiftUI

struct MultiplayerGameView: View {
    let mode: MultiplayerMode
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"
    @StateObject private var viewModel = MultiplayerGameViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showCopiedAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.statusText)
                .font(.title2)
            
            if let gameId = viewModel.createdGameId {
                HStack {
                    Text("Game ID: \(gameId)")
                        .font(.subheadline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Button(action: {
                        UIPasteboard.general.string = gameId
                        showCopiedAlert = true
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                }
            }
            
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

            Spacer()
        }
        .padding()
        .navigationTitle("Мультиплеер")
        .alert("Игра окончена", isPresented: $viewModel.gameOver) {
            Button("OK") {
                viewModel.resetGame()
                dismiss()
            }
        } message: {
            Text(viewModel.gameOverMessage)
        }
        .alert("Противник вышел из игры", isPresented: $viewModel.opponentLeftAlert) {
            Button("OK") {
                viewModel.resetGame()
                dismiss()
            }
        }
        .alert("ID скопирован!", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) { }
        }
        .onAppear {
            print("🔌 onConnect:", selectedLanguage)
            viewModel.connect(mode: mode, language: selectedLanguage)
        }
        .onDisappear {
            print("🔌 onDisappear вызван")
            viewModel.leaveGame()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.disconnect()
            }
        }
    }
}

import Foundation
import SwiftUI

final class MultiplayerGameViewModel: ObservableObject, WebSocketManagerDelegate {
    
    @Published var maskedWord = ""
    @Published var attemptsLeft = 8
    @Published var guessedLetters = Set<Character>()
    @Published var statusText = "Подключение..."
    @Published var gameOver = false
    @Published var gameOverMessage = ""
    @Published var opponentLeftAlert = false
    @Published var shouldExitGame = false
    @Published var createdGameId: String? = nil
    
    static var manualJoinGameId: String? = nil

    @AppStorage("gameLanguage") private var selectedLanguage = ""
    private var webSocketManager = WebSocketManager()
    private(set) var currentGameId: String?

    public var alphabet: [Character] {
        selectedLanguage == "RU"
        ? Array("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ")
        : Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    }

    func connect(mode: MultiplayerMode, language: String) {
        webSocketManager.delegate = self
        webSocketManager.connect(mode: mode, language: language)
    }

    func leaveGame() {
        print("🔌 leaveGame вызван")
        webSocketManager.leaveGame(gameId: currentGameId)
    }

    func disconnect() {
        if let gameId = currentGameId {
            let msg: [String: Any] = [
                "type": "LEAVE_GAME",
                "gameId": gameId
            ]
            webSocketManager.send(json: msg)
        }
        webSocketManager.disconnect()
    }

    func chooseLetter(_ letter: Character) {
        guard !gameOver, !guessedLetters.contains(letter), let gameId = currentGameId else { return }
        guessedLetters.insert(letter)
        webSocketManager.sendMove(letter: letter, gameId: gameId)
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

    // MARK: WebSocketManagerDelegate

    func didReceiveWaiting() {
        statusText = "Ожидание соперника..."
    }
    
    func didReceiveWaitingFriend() {
        statusText = "Ожидаем друга..."
    }

    func didFindMatch(wordLength: Int) {
        statusText = "Игра началась! Слово длиной \(wordLength) букв"
        maskedWord = String(repeating: "_ ", count: wordLength).trimmingCharacters(in: .whitespaces)
        attemptsLeft = 8
        guessedLetters.removeAll()
        gameOver = false
        opponentLeftAlert = false
        currentGameId = webSocketManager.currentGameId
    }

    func didReceiveStateUpdate(maskedWord: String, attemptsLeft: Int, duplicate: Bool) {
        self.maskedWord = maskedWord.replacingOccurrences(of: "\u{2007}", with: " ")
        self.attemptsLeft = attemptsLeft
        statusText = duplicate ? statusText : "Ход принят"
    }
    
    func didReceiveGameOver(win: Bool, word: String) {
        gameOver = true
        gameOverMessage = win ? "Вы выиграли! Слово: \(word)" : "Вы проиграли! Слово: \(word)"
        statusText = "Игра окончена"
        shouldExitGame = true
    }

    func didReceivePlayerLeft(playerId: String) {
        opponentLeftAlert = true
        statusText = "Противник вышел из игры"
        gameOver = true
        shouldExitGame = true
    }

    func didReceiveError(_ message: String) {
        statusText = "Ошибка: \(message)"
    }
    
    func didCreateRoom(gameId: String) {
        self.createdGameId = gameId
        self.statusText = "Комната создана. Отправьте ID другу."
    }
}
