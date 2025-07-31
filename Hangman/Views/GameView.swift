import SwiftUI

struct GameView: View {
    @AppStorage("gameLanguage") private var selectedLanguage = ""
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
        let spaced = wordToGuess.map { guessedLetters.contains($0) ? String($0) : "_" }.joined(separator: "\u{2007}")
        return spaced
    }
    
    var body: some View {
        VStack(spacing: 30) {
            if isLoading {
                ProgressView("Загрузка слова...")
            } else {
                Image(String(8 - attemptsLeft))
                    .resizable()
                    .scaledToFit()
                
                Text(displayedWord)
                    .font(.system(size: fontSize(for: displayedWord), weight: .bold, design: .monospaced))
                    .lineLimit(1)                 // запрещаем перенос
                    .minimumScaleFactor(0.5)     // уменьшаем шрифт, чтобы поместилось
                    .truncationMode(.tail)       // если не влезает — обрезаем
                    .padding(.horizontal)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                    ForEach(alphabet, id: \.self) { letter in
                        Button(action: {
                            chooseLetter(letter)
                        }) {
                            Text(String(letter))
                                .frame(width: 40, height: 40)
                                .background(guessedLetters.contains(letter) ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(guessedLetters.contains(letter))
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Hangman")
                        .font(.system(size: 24, weight: .bold))

                    Text("Категория: \(categories[selectedCategory, default: "Любая"])")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)

                }
                .multilineTextAlignment(.center)
            }
        }
        .navigationTitle("") // скрываем стандартный заголовок
        .alert("Игра окончена", isPresented: .constant(gameOver())) {
            Button("OK") {
                resetGame()
            }
        } message: {
            Text(attemptsLeft == 0 ? "Вы проиграли! Слово: \(wordToGuess)" : "Вы выиграли! Слово: \(wordToGuess)")
        }
        .onAppear {
            loadWord()
        }
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

private func fontSize(for displayedWord: String) -> CGFloat {
    let length = displayedWord.filter { $0 != "\u{2007}" && $0 != "_" }.count

    switch length {
    case 0...5: return 40
    case 6...8: return 32
    case 9...12: return 28
    case 13...16: return 22
    case 17...20: return 18
    default: return 16
    }
}

#Preview {
    MainMenuView()
}
