import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    @AppStorage("gameCategory") private var selectedCategory = ""

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Загрузка слова...")
            } else {
                GameContentView(
                    attemptsLeft: viewModel.attemptsLeft,
                    maskedWord: viewModel.displayedWord,
                    alphabet: viewModel.alphabet,
                    guessedLetters: Set(viewModel.guessedLetters),
                    onLetterTapped: viewModel.chooseLetter
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Hangman")
                        .font(.system(size: 20, weight: .bold))

                    Text("Категория: \(viewModel.categories[selectedCategory, default: "Любая"])")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .multilineTextAlignment(.center)
            }
        }
        .navigationTitle("") // скрываем стандартный заголовок
        .alert("Игра окончена", isPresented: $viewModel.isGameOver) {
            Button("OK") {
                viewModel.resetGame()
            }
        } message: {
            Text(viewModel.gameOverMessage)
        }
        .onAppear {
            viewModel.loadWord()
        }
    }
}

#Preview {
    MainMenuView()
}
