import SwiftUI

struct CompetitiveGameView: View {
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"
    @StateObject private var viewModel =  CompetitiveGameViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingPlayerList = false

    var body: some View {
        gameContentView
            .toolbar(.hidden, for: .tabBar)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingPlayerList = true }) {
                        Image(systemName: "person.2.fill")
                    }
                    .disabled(viewModel.players.isEmpty)
                }
            }
            .sheet(isPresented: $showingPlayerList) {
                PlayerListView(players: viewModel.players)
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
                print("🔌 onDisappear вызван: " + (viewModel.currentGameId ?? ""))
                viewModel.leaveGame()
            }
    }

    private var waitingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(2)

            AnimatedDotsText(text: "Ожидание соперника")
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
            
            if viewModel.statusText == "Подключение..." {
                waitingView
            }
            else if viewModel.statusText == "Ожидание соперника..." {
                waitingView
            } else if viewModel.maskedWord != "" {
                Image(String(8 - viewModel.attemptsLeft))
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

struct AnimatedDotsText: View {
    let text: String
    @State private var dots = 0
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(text + String(repeating: ".", count: dots))
            .onReceive(timer) { _ in
                dots = (dots + 1) % 4
            }
    }
}

#Preview {
    MainMenuView()
}

final class CompetitiveGameViewModel: ObservableObject, WebSocketManagerDelegate {
    
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
        print("🔌 leaveGame вызван: " + (currentGameId ?? ""))
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
        players.removeAll()
    }

    // MARK: - WebSocketManagerDelegate

    func didReceiveWaiting() {
        statusText = "Ожидание соперника..."
    }

    func didReceiveWaitingFriend() {
        // This should not be called in duel mode
    }

    func didFindMatch(wordLength: Int, players: [Player]) {
        statusText = "Игра началась!"
        maskedWord = String(repeating: "_ ", count: wordLength).trimmingCharacters(in: .whitespaces)
        attemptsLeft = 8
        guessedLetters.removeAll()
        gameOver = false
        opponentLeftAlert = false
        currentGameId = webSocketManager.currentGameId
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
        
        manager.addStat(mode: .multiplayer, result: win ? GameResult.win : GameResult.lose)
    }

    func didReceiveGameCanceled(word: String) {
        gameOver = true
        gameOverMessage = "Игра была отменена.\nСлово: \(word)"
        statusText = "Игра окончена"
        shouldExitGame = true

    }
    
    func didReceivePlayerLeft(name: String) {
        // Not used in competitive
//        manager.addStat(mode: .multiplayer, result: GameResult.win)
    }

    func didReceiveError(_ message: String) {
        statusText = "Ошибка: \(message)"
    }

    func didCreateRoom(gameId: String) {
        // This should not be called in duel mode
    }

    func didReceivePlayerJoined(attemptsLeft: Int, wordLength: Int, players: [Player], gameId: String, guessed: Set<String>) {
        self.players = players
        self.playerCount = players.count
    }

    func joinMulti(gameId: String) {
        // Not used in competitive
    }

    func didReceiveCoopGameOver(result: String, word: String, wordLength: Int) {
        // Not used in competitive
    }
}
