//
//  ContentView.swift
//  Hangman
//
//  Created by mego on 30.07.2025.
//

import SwiftUI

struct MainMenuView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Text("Hangman")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 60)

                NavigationLink(destination: GameView()) {
                    Text("🎮 Начать игру")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                NavigationLink(destination: SettingsView()) {
                    Text("⚙️ Настройки")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Главное меню")
        }
    }
}

#Preview {
    MainMenuView()
}
