import SwiftUI

struct MultiplayerGameView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"

    private var alphabet: [Character] {
        selectedLanguage == "RU"
            ? Array("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ")
            : Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    }

    var body: some View {
        VStack(spacing: 25) {
            Image(String(8 - viewModel.attemptsLeft))
                .resizable()
                .padding(.top, -50)

            Text(viewModel.maskedWord)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7),
                spacing: 8
            ) {
                ForEach(alphabet, id: \.self) { letter in
                    Button {
                        viewModel.chooseLetter(letter)
                    } label: {
                        Text(String(letter))
                            .frame(width: 40, height: 40)
                            .background(viewModel.guessedLetters.contains(letter) ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(viewModel.guessedLetters.contains(letter))
                }
            }
        }
        .padding()
    }
}
