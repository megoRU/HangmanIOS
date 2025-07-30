//
//  SettingsView.swift
//  Hangman
//
//  Created by mego on 30.07.2025.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Информация")) {
                HStack {
                    Text("Версия")
                    Spacer()
                    Text("1.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Настройки")
    }
}
#Preview {
    SettingsView()
}