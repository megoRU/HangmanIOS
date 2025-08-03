import SwiftUI

@MainActor
final class GameViewModel: ObservableObject {
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"
    @AppStorage("gameCategory") private var selectedCategory = ""

    @Published var wordToGuess: String = ""
    @Published var guessedLetters: [Character] = []
    @Published var attemptsLeft = 8
    @Published var isLoading = true
    @Published var isGameOver = false

    let categories = ["": "Любая", "colors": "Цвета", "flowers": "Цветы", "fruits": "Фрукты"]

    var alphabet: [Character] {
        selectedLanguage == "RU"
        ? Array("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ")
        : Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    }

    var displayedWord: String {
        wordToGuess.map { guessedLetters.contains($0) ? String($0) : "_" }.joined(separator: "\u{2007}")
    }

    var gameOverMessage: String {
        if attemptsLeft == 0 {
            return "Вы проиграли! Слово было: \(wordToGuess)"
        } else {
            return "Вы выиграли! Слово: \(wordToGuess)"
        }
    }

    func chooseLetter(_ letter: Character) {
        guard !isGameOver else { return }

        guessedLetters.append(letter)
        if !wordToGuess.contains(letter) {
            attemptsLeft -= 1
        }

        checkGameOver()
    }

    private func checkGameOver() {
        if attemptsLeft == 0 || !displayedWord.contains("_") {
            isGameOver = true
        }
    }

    func resetGame() {
        guessedLetters.removeAll()
        attemptsLeft = 8
        isGameOver = false
        loadWord()
    }

    func loadWord() {
        isLoading = true
        WordService.shared.fetchWord(language: selectedLanguage, category: selectedCategory.isEmpty ? nil : selectedCategory) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let word):
                    self.wordToGuess = word
                case .failure:
                    self.wordToGuess = "ОШИБКА" // Word for "ERROR" in Russian
                }
                self.isLoading = false
            }
        }
    }
}
