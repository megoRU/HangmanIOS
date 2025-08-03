import SwiftUI

struct KeyboardView: View {
    let alphabet: [Character]
    let guessedLetters: Set<Character>
    let onLetterTapped: (Character) -> Void

    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(alphabet, id: \.self) { letter in
                Button(action: {
                    onLetterTapped(letter)
                }) {
                    Text(String(letter))
                        .frame(width: 40, height: 40)
                        .background(buttonBackgroundColor(for: letter))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(guessedLetters.contains(letter))
            }
        }
    }

    private func buttonBackgroundColor(for letter: Character) -> Color {
        return guessedLetters.contains(letter) ? .gray : .blue
    }
}

extension Set where Element == Character {
    // This is a small convenience initializer that might be useful later.
    init(_ strings: [String]) {
        self.init(strings.flatMap { $0 })
    }
}
