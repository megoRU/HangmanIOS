//
//  SettingsView.swift
//  Hangman
//
//  Created by mego on 30.07.2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"
    @AppStorage("gameCategory") private var selectedCategory = ""
    
    let languages = ["EN": "English", "RU": "Русский"]
    let categories = ["": "Любая", "colors": "Цвета", "flowers": "Цветы", "fruits": "Фрукты"]
    
    var body: some View {
        Form {
            Section(header: Text("Язык игры")) {
                Picker("Язык", selection: $selectedLanguage) {
                    ForEach(languages.keys.sorted(), id: \.self) { key in
                        Text(languages[key] ?? key).tag(key)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section(header: Text("Категория")) {
                Picker("Категория", selection: $selectedCategory) {
                    ForEach(categories.keys.sorted(), id: \.self) { key in
                        Text(categories[key] ?? key).tag(key)
                    }
                }
            }
            
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
    MainMenuView()
}
