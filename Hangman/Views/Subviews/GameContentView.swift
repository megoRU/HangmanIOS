import SwiftUI

struct GameContentView: View {
    let attemptsLeft: Int
    let maskedWord: String
    let alphabet: [Character]
    let guessedLetters: Set<Character>
    let onLetterTapped: (Character) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(String(8 - attemptsLeft))
                .resizable()
                .scaledToFit()

            Text(maskedWord)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding()

            KeyboardView(
                alphabet: alphabet,
                guessedLetters: guessedLetters,
                onLetterTapped: onLetterTapped
            )

            Spacer()
        }
        .padding()
    }
}
