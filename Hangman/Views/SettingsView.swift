import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return "Системная"
        case .light: return "Светлая"
        case .dark: return "Тёмная"
        }
    }
}

import SwiftUI

struct SettingsView: View {
    @AppStorage("gameLanguage") private var selectedLanguage: String = "RU"
    @AppStorage("gameCategory") private var selectedCategory: String = ""
    @AppStorage("appTheme") private var selectedTheme: String = AppTheme.system.rawValue

    let languages = ["RU": "Русский", "EN": "Английский"]
    let categories = ["": "Любая", "colors": "Цвета", "flowers": "Цветы", "fruits": "Фрукты"]
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: Язык
                Section(header: Text("Язык игры")) {
                    Picker("Выберите язык", selection: $selectedLanguage) {
                        ForEach(languages.keys.sorted(), id: \.self) { key in
                            Text(languages[key] ?? key)
                                .tag(key)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                // MARK: Категория
                Section(header: Text("Категория")) {
                    Picker("Выберите категорию", selection: $selectedCategory) {
                        ForEach(categories.keys.sorted(), id: \.self) { key in
                            Text(categories[key] ?? key)
                                .tag(key)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section(header: Text("Оформление")) {
                    Picker("Тема", selection: $selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme.rawValue)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section {
                    Link(destination: URL(string: "https://t.me/mego_RU")!) {
                        Label("Поддержка", systemImage: "link")
                    }
                }
                
                Section {
                    HStack {
                        Label("Версия", systemImage: "info.circle")
                        Spacer()
                        Text("2.0.0")
                    }
                }
                
            }
            .navigationTitle("Настройки")
        }
    }
}

#Preview {
    SettingsView()
}
