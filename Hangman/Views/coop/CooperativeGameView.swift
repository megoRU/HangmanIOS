import SwiftUI

struct CooperativeGameView: View {
    let mode: MultiplayerMode
    @StateObject private var viewModel = GameViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var manualJoinId = ""
    @State private var showingPlayerList = false

    var body: some View {
        Group {
            if mode == .code_friend && viewModel.players.isEmpty {
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
                }
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
        .alert(
            (viewModel.coopRoundResult?.result ?? "") == "WIN" ? "Вы выиграли!" : "Вы проиграли!",
            isPresented: .constant(viewModel.coopRoundResult != nil)
        ) {
            if let payload = viewModel.coopRoundResult {
                Button("Продолжить") {
                    viewModel.continueCoopGame(with: payload)
                }
            }
            Button("Выйти") {
                dismiss()
            }
        } message: {
            Text("Загаданное слово: \(viewModel.wordToGuess). Готовы к следующей игре?")
        }
        .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Игра окончена!", isPresented: .constant(viewModel.gameResult != nil)) {
            Button("Выйти") {
                dismiss()
            }
        } message: {
            Text("Ваш оппонент покинул игру. Вы победили!")
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    WebSocketManager.shared.leaveGame(gameId: viewModel.gameId)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        }
        .onAppear {
            if mode == .friends {
                WebSocketManager.shared.findGame(mode: .friends)
            }
        }
    }
    
    private var connectionView: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    Spacer(minLength: geometry.size.height * 0.1)

                    Text("Присоединиться к игре")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Введите код, который вам прислал друг, чтобы начать игру.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    TextField("Код игры", text: $manualJoinId)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                        .keyboardType(.asciiCapable)
                        .autocapitalization(.allCharacters)
                        .multilineTextAlignment(.center)

                    Button(action: {
                        WebSocketManager.shared.joinMulti(gameId: manualJoinId)
                    }) {
                        Text("Подключиться")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(manualJoinId.isEmpty)

                    Spacer()
                }
                .padding()
                .frame(minHeight: geometry.size.height)
            }
        }
    }
    
    private var gameContentView: some View {
        VStack(spacing: 20) {
            if viewModel.players.isEmpty {
                if let gameId = viewModel.gameId {
                    Text("Комната создана!")
                        .font(.title.bold())
                        .padding(.top)

                    Text("Поделитесь этим кодом с другом:")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    HStack {
                        Text(gameId)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .padding(.horizontal)

                        Button(action: {
                            UIPasteboard.general.string = gameId
                        }) {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)

                    ProgressView("Ожидание подключения...")
                    Spacer()

                } else {
                    ProgressView("Создание комнаты...")
                }
            } else {
                MultiplayerGameView()
                    .environmentObject(viewModel)
            }
        }
    }
}
