import SwiftUI

@MainActor
class MultiplayerGameViewModel: ObservableObject, WebSocketManagerDelegate {

    // MARK: - Published Properties
    @Published var maskedWord = ""
    @Published var attemptsLeft = 8
    @Published var guessedLetters = Set<Character>()
    @Published var statusText = "Подключение..."
    @Published var gameOver = false
    @Published var gameOverMessage = ""
    @Published var shouldExitGame = false
    @Published var createdGameId: String? = nil
    @Published var playerCount = 0

    // MARK: - Properties
    @AppStorage("gameLanguage") var selectedLanguage = "RU"

    internal var webSocketManager = WebSocketManager()
    private(set) var currentGameId: String?

    var alphabet: [Character] {
        selectedLanguage == "RU"
        ? Array("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ")
        : Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    }

    // MARK: - Initializer
    init() {
        webSocketManager.delegate = self
    }

    // MARK: - Public Methods

    func connect(mode: MultiplayerMode, language: String) {
        statusText = "Подключение..."
        webSocketManager.connect(mode: mode, language: language)
    }

    func leaveGame() {
        webSocketManager.leaveGame(gameId: currentGameId)
    }

    func disconnect() {
        leaveGame()
        webSocketManager.disconnect()
    }

    func chooseLetter(_ letter: Character) {
        guard !gameOver, !guessedLetters.contains(letter), let gameId = currentGameId else { return }
        guessedLetters.insert(letter)
        webSocketManager.sendMove(letter: letter, gameId: gameId)
    }

    func startNewGame() {
        // To be overridden by subclasses
        fatalError("startNewGame() must be overridden")
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
        shouldExitGame = false
        playerCount = 0
    }

    func joinMulti(gameId: String) {
        webSocketManager.joinMulti(gameId: gameId)
    }

    // MARK: - WebSocketManagerDelegate

    func didReceiveWaiting() {
        statusText = "Ожидание игрока..."
    }

    func didReceiveWaitingFriend() {
        statusText = "Ожидаем друга..."
    }

    func didFindMatch(wordLength: Int) {
        statusText = "Игра началась!"
        maskedWord = String(repeating: "_", count: wordLength).map { String($0) }.joined(separator: "\u{2007}")
        attemptsLeft = 8
        guessedLetters.removeAll()
        gameOver = false
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
        self.createdGameId = gameId
        self.currentGameId = gameId
        self.statusText = "Комната создана"
    }

    func didReceivePlayerJoined(attemptsLeft: Int, wordLength: Int, players: Int, gameId: String, guessed: Set<String>) {
        self.currentGameId = gameId
        self.statusText = "Игра началась"
        self.maskedWord = String(repeating: "_", count: wordLength).map { String($0) }.joined(separator: "\u{2007}")
        self.attemptsLeft = attemptsLeft
        self.guessedLetters = Set(guessed.map { Character($0) })
        self.gameOver = false
        self.playerCount = players
    }

    func didReceiveCoopGameOver(result: String, word: String, newWord: String) {
        // To be overridden by CooperativeGameViewModel
    }
}
