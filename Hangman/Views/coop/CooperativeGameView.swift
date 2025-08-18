import SwiftUI

struct CooperativeGameView: View {
    let mode: MultiplayerMode
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"
    @StateObject private var viewModel = CooperativeGameViewModel()
    @Environment(\.dismiss) private var dismiss

    init(mode: MultiplayerMode) {
        self.mode = mode
    }
    
    @State private var showCopiedAlert = false
    @State private var manualJoinId = ""
    @State private var showingPlayerList = false
    
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingPlayerList = true }) {
                    Image(systemName: "person.2.fill")
                }
                .disabled(viewModel.players.isEmpty)
            }
        }
        .alert("Игрок вышел", isPresented: $viewModel.shouldExitGame) {
            Button("Выйти") {
                dismiss()
            }
        } message: {
            Text(viewModel.gameOverMessage)
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
        .alert("Скопировано!", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) { }
        }
        .sheet(isPresented: $showingPlayerList) {
            PlayerListView(players: viewModel.players)
        }
        .onAppear {
            print("🔌 onConnect:", selectedLanguage)
            viewModel.connect(mode: mode, language: selectedLanguage)
        }
        .onDisappear {
            print("🔌 onDisappear вызван: " + (viewModel.currentGameId ?? ""))
            viewModel.leaveGame()
        }
    }
    
    private var connectionView: some View {
        VStack(spacing: 2) {
            
            VStack(spacing: 12) {
                
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
    
    private var waitingFriendView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(2)
            
            AnimatedDotsText(text: "Ожидаем друга")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.white, Color.blue.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom)
        )
        .cornerRadius(16)
        .padding()
    }
    
    private var gameContentView: some View {
        VStack(spacing: 25) {
            if viewModel.statusText == "Ожидаем друга..."
                || viewModel.statusText == "Подключение..." {
                waitingFriendView
                
                HStack {
                    let gameId = viewModel.createdGameId
                    let buttonText = "Ожидайте..."
                    
                    Text("Код:")
                        .font(.system(size: 18, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Text(viewModel.createdGameId ?? buttonText)
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
                    .disabled(gameId == buttonText)
                }
            } else {
                Image(String(min(8, max(0, 8 - viewModel.attemptsLeft))))
                    .resizable()
                    .padding(.top, -50)
                
                Text(viewModel.maskedWord)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
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
    
    let manager = StatsManager.shared
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
    @Published var players: [Player] = []
    
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"
    private var webSocketManager = WebSocketManager.shared
    private(set) var currentGameId: String?
    private var mode: MultiplayerMode = .friends

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
        print("🔌 leaveGame вызван: " + (createdGameId ?? ""))
        webSocketManager.leaveGame(gameId: currentGameId)
    }
    
    func disconnect() {
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
    }
    
    func resetGame() {
        // The game state is already reset by didReceiveCoopGameOver.
        // This function is now just for dismissing the alert and resetting UI state.
        gameOver = false
        gameOverMessage = ""
        statusText = "Игра началась"
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
    
    func didFindMatch(gameId: String, wordLength: Int, players: [Player]) {
        statusText = "Игра началась!"
        maskedWord = String(repeating: "_ ", count: wordLength).trimmingCharacters(in: .whitespaces)
        attemptsLeft = 8
        guessedLetters.removeAll()
        gameOver = false
        opponentLeftAlert = false
        currentGameId = gameId
        self.players = players
        self.playerCount = players.count
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
        
        manager.addStat(mode: .cooperative, result: win ? GameResult.win : GameResult.lose)
    }
    
    func didReceiveCoopGameOver(result: String, word: String, attemptsLeft: Int, wordLength: Int, players: [Player], gameId: String, guessed: Set<String>) {
        self.gameOver = true
        self.gameOverMessage = (result == "WIN" ? "Вы победили!" : "Вы проиграли!") + "\nСлово: \(word)"
        self.statusText = "Игра окончена"

        // Reset the state for the NEXT round using data from the server
        self.maskedWord = String(repeating: "_ ", count: wordLength).trimmingCharacters(in: .whitespaces)
        self.attemptsLeft = attemptsLeft
        self.guessedLetters = Set(guessed.map { Character($0) })
        self.players = players
        self.playerCount = players.count
        self.currentGameId = gameId

        manager.addStat(mode: .cooperative, result: result == "WIN" ? GameResult.win : GameResult.lose)
    }
    
    func didReceiveGameCanceled(word: String) {
        self.gameOverMessage = "Игра была отменена.\nСлово: \(word)"
        self.statusText = "Игра окончена"
        self.shouldExitGame = true
    }
    
    func didRestoreGame(gameId: String, wordLength: Int, maskedWord: String, attemptsLeft: Int, guessed: Set<String>, players: [Player]) {
            print("✅ Игра восстановлена: \(gameId)")
            self.currentGameId = gameId
            if self.mode != .duel {
                self.createdGameId = gameId
            }
            self.maskedWord = maskedWord.replacingOccurrences(of: "\u{2007}", with: " ")
            self.attemptsLeft = attemptsLeft
            self.guessedLetters = Set(guessed.map { Character($0) })
            self.players = players
            self.playerCount = players.count

            if self.mode != .duel && self.playerCount < 2 {
                self.statusText = "Ожидаем друга..."
            } else {
                self.statusText = "Игра восстановлена"
            }

            self.gameOver = false
        }
    
    func didReceivePlayerLeft(name: String) {
        playerCount -= 1
        players.removeAll { $0.name == name }

        let localState = statusText
        statusText = "Игрок \(name) вышел"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.statusText = localState
        }
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
    
    func didReceivePlayerJoined(attemptsLeft: Int, wordLength: Int, players: [Player], gameId: String, guessed: Set<String>) {
        self.currentGameId = gameId
        self.statusText = "Игра началась"
        maskedWord = String(repeating: "_ ", count: wordLength).trimmingCharacters(in: .whitespaces)
        self.attemptsLeft = attemptsLeft
        guessedLetters = Set(guessed.map { Character($0) })
        gameOver = false
        opponentLeftAlert = false
        self.players = players
        self.playerCount = players.count
    }
}
