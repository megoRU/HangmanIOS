import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 80))
                Text("Hangman")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
        }
    }
}
