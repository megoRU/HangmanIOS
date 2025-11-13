import SwiftUI

struct GameView: View {
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"
    @AppStorage("gameCategory") private var selectedCategory = ""
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = StatsManager.shared

    @State private var wordToGuess: String = ""
    @State private var guessedLetters: [Character] = []
    @State private var attemptsLeft = 8
    @State private var isLoading = true
    @State private var showErrorAlert = false
    
    private var categories: [String: String] {
        [
            "": NSLocalizedString("category_any", comment: ""),
            "colors": NSLocalizedString("category_colors", comment: ""),
            "flowers": NSLocalizedString("category_flowers", comment: ""),
            "fruits": NSLocalizedString("category_fruits", comment: "")
        ]
    }
    
    private var alphabet: [Character] {
        selectedLanguage == "RU"
        ? Array("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ")
        : Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    }
    
    private var displayedWord: String {
        wordToGuess
            .map { guessedLetters.contains($0) ? String($0) : "_" }
            .joined(separator: "\u{2007}")
    }
    
    var body: some View {
        VStack(spacing: 25) {
            if isLoading {
                ProgressView(NSLocalizedString("loading_word", comment: ""))
                    .frame(maxHeight: .infinity)
            } else {
                // Картинка фиксированного размера
                Image(String(8 - attemptsLeft))
                    .resizable()
                    .padding(.top, -50)
                
                // Слово
                Text(displayedWord)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                // Клавиатура фиксированной высоты
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7),
                    spacing: 8
                ) {
                    ForEach(alphabet, id: \.self) { letter in
                        Button {
                            chooseLetter(letter)
                        } label: {
                            Text(String(letter))
                                .frame(width: 40, height: 40)
                                .background(guessedLetters.contains(letter) ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(guessedLetters.contains(letter))
                    }
                }
                
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(NSLocalizedString("single_player_game_title", comment: ""))
                        .font(.system(size: 20, weight: .bold))
                    
                    Text(String(format: NSLocalizedString("category_display", comment: ""), categories[selectedCategory, default: NSLocalizedString("category_any", comment: "")]))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .multilineTextAlignment(.center)
            }
        }
        .navigationTitle("")
        .alert(NSLocalizedString("game_over_alert_title", comment: ""), isPresented: .constant(gameOver())) {
            Button("OK", action: resetGame)
        } message: {
            Text(attemptsLeft == 0 ? String(format: NSLocalizedString("game_over_lose_message", comment: ""), wordToGuess) : String(format: NSLocalizedString("game_over_win_message", comment: ""), wordToGuess))
        }
        .onChange(of: gameOver()) { isGameOver in
            if isGameOver {
                let result: GameResult = attemptsLeft == 0 ? .lose : .win
                manager.addStat(mode: .single, result: result)
            }
        }
        .onAppear {
            if wordToGuess.isEmpty {
                loadWord()
            }
        }
        .alert(NSLocalizedString("loading_error_alert_title", comment: ""), isPresented: $showErrorAlert) {
            Button(NSLocalizedString("retry_button", comment: ""), action: loadWord)
            Button(NSLocalizedString("back_button", comment: "")) {
                dismiss()
            }
        } message: {
            Text(NSLocalizedString("loading_error_message", comment: ""))
        }
    }
    
    private func chooseLetter(_ letter: Character) {
        guessedLetters.append(letter)
        if !wordToGuess.contains(letter) {
            attemptsLeft -= 1
        }
    }
    
    private func gameOver() -> Bool {
        !wordToGuess.isEmpty && (attemptsLeft == 0 || !displayedWord.contains("_"))
    }
    
    private func resetGame() {
        guessedLetters.removeAll()
        attemptsLeft = 8
        loadWord()
    }
    
    private func loadWord() {
        isLoading = true
        showErrorAlert = false
        WordService.shared.fetchWord(language: selectedLanguage, category: selectedCategory.isEmpty ? nil : selectedCategory) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let word):
                    self.wordToGuess = word
                    self.isLoading = false
                case .failure:
                    self.showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    MainMenuView()
}
