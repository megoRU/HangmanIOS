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
                    Text(NSLocalizedString("cooperative_game_title", comment: ""))
                        .font(.system(size: 20, weight: .bold))
                }
            }
            if !viewModel.players.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingPlayerList = true }) {
                        Image(systemName: "person.2.fill")
                    }
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    WebSocketManager.shared.leaveGame(gameId: viewModel.gameId)
                    dismiss()
                } label: {
                    Text(NSLocalizedString("exit_button", comment: ""))
                }
            }
        }
        .sheet(isPresented: $showingPlayerList) {
            PlayerListView(players: viewModel.players)
        }
        .navigationBarBackButtonHidden(true)
        .withAlerts(viewModel: viewModel, dismiss: dismiss)
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

                    Text(NSLocalizedString("join_game_title", comment: ""))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(NSLocalizedString("join_game_subtitle", comment: ""))
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    TextField(NSLocalizedString("game_code_placeholder", comment: ""), text: $manualJoinId)
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
                        Text(NSLocalizedString("connect_button", comment: ""))
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
        GeometryReader { geometry in
            VStack(spacing: 20) {
                if viewModel.players.isEmpty {
                    if let gameId = viewModel.gameId {
                        Spacer()
                        Text(NSLocalizedString("room_created_title", comment: ""))
                            .font(.title.bold())

                        Text(NSLocalizedString("share_code_prompt", comment: ""))
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

                        ProgressView(NSLocalizedString("waiting_for_friend_progress", comment: ""))
                        Spacer()

                    } else {
                        ProgressView(NSLocalizedString("creating_room_progress", comment: ""))
                    }
                } else {
                    MultiplayerGameView()
                        .environmentObject(viewModel)
                }
            }
            .frame(maxWidth: .infinity, minHeight: geometry.size.height)
        }
    }
}

fileprivate struct WithAlerts: ViewModifier {
    @ObservedObject var viewModel: GameViewModel
    var dismiss: DismissAction

    func body(content: Content) -> some View {
        content
            .alert(
                (viewModel.coopRoundResult?.result ?? "") == "WIN" ? NSLocalizedString("you_won_alert_title", comment: "") : NSLocalizedString("you_lost_alert_title", comment: ""),
                isPresented: .constant(viewModel.coopRoundResult != nil)
            ) {
                if let payload = viewModel.coopRoundResult {
                    Button(NSLocalizedString("continue_button", comment: "")) {
                        viewModel.continueCoopGame(with: payload)
                    }
                }
                Button(NSLocalizedString("exit_button", comment: "")) {
                    dismiss()
                }
            } message: {
                Text(String(format: NSLocalizedString("word_was_alert_message", comment: ""), viewModel.wordToGuess))
            }
            .alert(NSLocalizedString("error_alert_title", comment: ""), isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert(NSLocalizedString("game_over_alert_title", comment: ""), isPresented: .constant(viewModel.gameResult != nil)) {
                Button(NSLocalizedString("exit_button", comment: "")) {
                    dismiss()
                }
            } message: {
                Text(NSLocalizedString("opponent_left_alert_message", comment: ""))
            }
    }
}

fileprivate extension View {
    func withAlerts(viewModel: GameViewModel, dismiss: DismissAction) -> some View {
        self.modifier(WithAlerts(viewModel: viewModel, dismiss: dismiss))
    }
}
