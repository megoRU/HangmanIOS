import SwiftUI

struct MultiplayerGameView: View {
    let mode: MultiplayerMode
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"
    @StateObject private var viewModel = MultiplayerGameViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.statusText)
                .font(.title2)

            Text(viewModel.maskedWord)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding()

            Text("Попыток осталось: \(viewModel.attemptsLeft)")
                .font(.title3)

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
            }
        } message: {
            Text(viewModel.gameOverMessage)
        }
        .onAppear {
            viewModel.connect(mode: mode, language: selectedLanguage)
        }
        .onDisappear {
            viewModel.disconnect()
        }
    }
}

final class MultiplayerGameViewModel: ObservableObject, WebSocketManagerDelegate {
    @Published var maskedWord = ""
    @Published var attemptsLeft = 8
    @Published var guessedLetters = Set<Character>()
    @Published var statusText = "Подключение..."
    @Published var gameOver = false
    @Published var gameOverMessage = ""
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
    }

    // MARK: WebSocketManagerDelegate

    func didReceiveWaiting() {
        statusText = "Ожидание соперника..."
    }

    func didFindMatch(wordLength: Int) {
        statusText = "Игра началась! Слово длиной \(wordLength) букв"
        maskedWord = String(repeating: "_ ", count: wordLength).trimmingCharacters(in: .whitespaces)
        attemptsLeft = 8
        guessedLetters.removeAll()
        gameOver = false
        // ⬇️ Просто сохраняем ID
        self.currentGameId = webSocketManager.currentGameId
    }

    func didReceiveStateUpdate(maskedWord: String, attemptsLeft: Int, duplicate: Bool) {
        self.maskedWord = maskedWord.replacingOccurrences(of: "\u{2007}", with: " ")
        self.attemptsLeft = attemptsLeft
        statusText = duplicate ? "Буква уже была" : "Ход принят"
    }

    func didReceiveGameOver(win: Bool, word: String) {
        gameOver = true
        gameOverMessage = win ? "Вы выиграли! Слово: \(word)" : "Вы проиграли! Слово: \(word)"
        statusText = "Игра окончена"
    }

    func didReceiveError(_ message: String) {
        statusText = "Ошибка: \(message)"
    }
}
