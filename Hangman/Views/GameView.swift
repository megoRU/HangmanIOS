import SwiftUI

struct GameView: View {
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"
    @AppStorage("gameCategory") private var selectedCategory = ""
    
    @State private var wordToGuess: String = ""
    @State private var guessedLetters: [Character] = []
    @State private var attemptsLeft = 8
    @State private var isLoading = true
    
    let categories = ["": "Любая", "colors": "Цвета", "flowers": "Цветы", "fruits": "Фрукты"]
    
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
                ProgressView("Загрузка слова...")
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
                    Text("Одиночная")
                        .font(.system(size: 20, weight: .bold))

                    Text("Категория: \(categories[selectedCategory, default: "Любая"])")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .multilineTextAlignment(.center)
            }
        }
        .navigationTitle("")
        .alert("Игра окончена", isPresented: .constant(gameOver())) {
            Button("OK") {
                resetGame()
            }
        } message: {
            Text(attemptsLeft == 0 ? "Вы проиграли! Слово: \(wordToGuess)" : "Вы выиграли! Слово: \(wordToGuess)")
        }
        .onAppear(perform: loadWord)
    }
    
    private func chooseLetter(_ letter: Character) {
        guessedLetters.append(letter)
        if !wordToGuess.contains(letter) {
            attemptsLeft -= 1
        }
    }
    
    private func gameOver() -> Bool {
        attemptsLeft == 0 || !displayedWord.contains("_")
    }
    
    private func resetGame() {
        guessedLetters.removeAll()
        attemptsLeft = 8
        loadWord()
    }
    
    private func loadWord() {
        isLoading = true
        WordService.shared.fetchWord(language: selectedLanguage, category: selectedCategory.isEmpty ? nil : selectedCategory) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let word):
                    self.wordToGuess = word
                case .failure:
                    self.wordToGuess = "ERROR"
                }
                self.isLoading = false
            }
        }
    }
}

#Preview {
    MainMenuView()
}
