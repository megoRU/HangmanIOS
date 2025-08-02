import SwiftUI

struct CooperativeGameView: View {
    let mode: MultiplayerMode
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"
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
    
    private var connectionView: some View {
        VStack(spacing: 30) {
            
            VStack(spacing: 12) {
                
                Image(String("7"))
                    .resizable()
                    .scaledToFit()
                
                TextField("Введите ID игры", text: $manualJoinId)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 15)
                    .padding(.top, 20)
                    .font(.system(size: 16, weight: .medium))
                    .accentColor(.gray)
                
                Button {
                    viewModel.joinMulti(gameId: manualJoinId)
                } label: {
                    Text("Подключиться")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(manualJoinId.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(manualJoinId.isEmpty)
                .padding(.horizontal)
                
            }
            Spacer()
        }
        .padding()
    }
    
    private var gameContentView: some View {
        VStack(spacing: 20) {
            
            if let gameId = viewModel.createdGameId {
                if viewModel.playerCount < 2 {
                    HStack {
                        Text("Код:")
                            .font(.system(size: 18, weight: .medium))
                        
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Text(gameId)
                            .font(.system(size: 20, weight: .bold))
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
    }
}

#Preview {
    MainMenuView()
}

import Foundation
import SwiftUI

final class CooperativeGameViewModel: ObservableObject, WebSocketManagerDelegate {
    
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
    private var mode: MultiplayerMode = .friends
    private var newWord: String?
    
    public var alphabet: [Character] {
        selectedLanguage == "RU"
        ? Array("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ")
        : Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    }
    
    // MARK: - Подключение
    func connect(mode: MultiplayerMode, language: String) {
        self.mode = mode
        statusText = mode == .code_friend ? "Ожидание кода..." : "Подключение..."
        webSocketManager.delegate = self
        webSocketManager.connect(mode: mode, language: language)
    }
    
    func joinMulti(gameId: String) {
        webSocketManager.joinMulti(gameId: gameId)
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
        if let newWord = newWord {
            maskedWord = String(repeating: "_ ", count: newWord.count).trimmingCharacters(in: .whitespaces)
            self.newWord = nil
        }
    }

    func resetGame() {
        attemptsLeft = 8
        guessedLetters.removeAll()
        statusText = "Игра началась"
        gameOver = false
        gameOverMessage = ""
        opponentLeftAlert = false
        shouldExitGame = false
    }
    
    // MARK: - WebSocketManagerDelegate
    
    func didReceiveWaiting() {
        statusText = "Ожидание соперника..."
    }
    
    func didReceiveWaitingFriend() {
        statusText = "Ожидаем друга..."
    }
    
    func didFindMatch(wordLength: Int) {
        // This is for duel, but we can have a generic message
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
    
    func didReceiveCoopGameOver(result: String, word: String, newWord: String) {
        self.gameOver = true
        self.gameOverMessage = (result == "WIN" ? "Вы победили!" : "Вы проиграли!") + "\nСлово: \(word)"
        self.newWord = newWord
        self.statusText = "Игра окончена"
    }

    func didReceivePlayerLeft(playerId: String) {
        gameOver = true
        gameOverMessage = "Друг вышел"
        shouldExitGame = true
    }
    
    func didReceiveError(_ message: String) {
        let localState = statusText
        statusText = "Ошибка: \(message)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.statusText = localState
        }
        
    }
    
    func didCreateRoom(gameId: String) {
        self.createdGameId = gameId
        self.statusText = "Комната создана"
    }
    
    func didReceivePlayerJoined(attemptsLeft: Int, wordLength: Int, players: Int, gameId: String, guessed: Set<String>) {
        self.currentGameId = gameId
        self.statusText = "Игра началась"
        maskedWord = String(repeating: "_ ", count: wordLength).trimmingCharacters(in: .whitespaces)
        self.attemptsLeft = attemptsLeft
        guessedLetters = Set(guessed.map { Character($0) })
        gameOver = false
        opponentLeftAlert = false
        playerCount = players
    }
}
