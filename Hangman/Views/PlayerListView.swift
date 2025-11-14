import SwiftUI

struct PlayerListView: View {
    @AppStorage("userAge") private var userAge: Int = 0
    let players: [Player]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(players) { player in
                HStack {
                    if userAge >= 18,
                       let base64String = player.image,
                       let imageData = Data(base64Encoded: base64String),
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    Text(player.name)
                        .font(.headline)
                }
            }
            .navigationTitle(NSLocalizedString("players_list_title", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("done_button", comment: "")) {
                        dismiss()
                    }
                }
            }
        }
    }
}
