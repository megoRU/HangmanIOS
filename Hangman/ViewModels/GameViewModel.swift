import Foundation
import Combine
import SwiftUI

class GameViewModel: ObservableObject {
    @Published var wordToGuess: String = ""
    @Published var maskedWord: String = ""
    @Published var guessedLetters: Set<Character> = []
    @Published var attemptsLeft = 8
    @Published var players: [Player] = []
    @Published var gameResult: String?
    @Published var errorMessage: String?
    
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"
    
    private var webSocketManager = WebSocketManager.shared
    private var cancellables = Set<AnyCancellable>()
    @Published public var gameId: String?
    
    var isGameOver: Bool {
        gameResult != nil
    }
    
    private var alphabet: [Character] {
        selectedLanguage == "RU"
        ? Array("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ")
        : Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    }
    
    init() {
        webSocketManager.serverMessageSubject
            .sink { [weak self] message in
                self?.handleServerMessage(message)
            }
            .store(in: &cancellables)
    }
    
    func chooseLetter(_ letter: Character) {
        guessedLetters.insert(letter)
        guard let gameId = gameId else { return }
        webSocketManager.sendMove(letter: letter, gameId: gameId)
    }
    
    func resetGame() {
        // Логика сброса игры будет добавлена позже
    }
    
    private func handleServerMessage(_ message: ServerMessage) {
        switch message {
        case .matchFound(let payload):
            self.gameId = payload.gameId
            self.maskedWord = (0..<payload.wordLength).map { _ in "_"}.joined(separator:" ")
            self.players = payload.players
        case .roomCreated(let payload):
            self.gameId = payload.gameId
        case .playerJoined(let payload):
            self.gameId = payload.gameId
            self.maskedWord = (0..<payload.wordLength).map { _ in "_"}.joined(separator:" ")
            self.players = payload.players
            self.attemptsLeft = payload.attemptsLeft
            self.guessedLetters = Set(payload.guessed.map { Character($0.uppercased()) })
        case .playerLeft(let payload):
            self.players.removeAll { $0.name == payload.name }
        case .stateUpdate(let payload):
            self.maskedWord = payload.maskedWord
            self.attemptsLeft = payload.attemptsLeft
            if let guessed = payload.guessed {
                self.guessedLetters = Set(guessed.map { Character($0.uppercased()) })
            }
        case .gameOver(let payload):
            self.gameResult = payload.result
            self.wordToGuess = payload.word
        case .gameOverCoop(let payload):
            self.gameResult = payload.result
            self.wordToGuess = payload.word
        case .restored(let payload):
            self.gameId = payload.gameId
            self.maskedWord = payload.maskedWord
            self.attemptsLeft = payload.attemptsLeft
            self.guessedLetters = Set(payload.guessed.map { Character($0.uppercased()) })
            self.players = payload.players
        case .error(let payload):
            self.errorMessage = payload.msg
        default:
            break
        }
    }
}
