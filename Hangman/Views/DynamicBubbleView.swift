import SwiftUI

struct DynamicBubbleView: View {
    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Image("island") // имя в Assets, не системный app icon
                    .resizable()
                    .frame(width: 20, height: 20)
                
                Text("Hangman")
                    .foregroundColor(.white)
                    .bold()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(25)
            .shadow(radius: 4)
            .padding(14)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .edgesIgnoringSafeArea(.top)
    }
}

#Preview {
    MainMenuView()
}
