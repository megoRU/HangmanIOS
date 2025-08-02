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
    @AppStorage("useSystemTheme") private var useSystemTheme = true
    @AppStorage("useDarkMode") private var useDarkMode = false
    
    let languages = ["RU": "Русский", "EN": "Английский"]
    let categories = ["": "Любая", "colors": "Цвета", "flowers": "Цветы", "fruits": "Фрукты"]

    
    var body: some View {
        NavigationStack {
            Form {
                // Язык
                Section(header: Text("Язык игры")) {
                    Picker("Выберите язык", selection: $selectedLanguage) {
                        ForEach(languages.keys.sorted(), id: \.self) { key in
                            Text(languages[key] ?? key)
                                .tag(key)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                // Категория
                Section(header: Text("Категория")) {
                    Picker("Выберите категорию", selection: $selectedCategory) {
                        ForEach(categories.keys.sorted(), id: \.self) { key in
                            Text(categories[key] ?? key)
                                .tag(key)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section(header: Text("Оформление"),
                        footer: Text(footerText())) {
                    Toggle(isOn: $useSystemTheme) {
                        Text("Cистемная")
                    }
                    .onChange(of: useSystemTheme) {
                        applyTheme()
                    }
                    
                    Toggle(isOn: $useDarkMode) {
                        Text("Темный режим")
                    }
                    .disabled(useSystemTheme) // Делаем тумблер неактивным при включенных системных настройках
                    .onChange(of: useDarkMode) {
                        applyTheme()
                    }
                }
                
                Section(header: Text("Информация")) {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("2.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Настройки")
            .onAppear { applyTheme() }
        }
    }
    
    private func applyTheme() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        if useSystemTheme {
            window.overrideUserInterfaceStyle = .unspecified
        } else {
            window.overrideUserInterfaceStyle = useDarkMode ? .dark : .light
        }
    }
    
    private func footerText() -> String {
            if useSystemTheme {
                return "Сейчас используется системная тема устройства."
            } else {
                return useDarkMode ? "Сейчас используется темная тема." : "Сейчас используется светлая тема."
            }
        }
}

#Preview {
    SettingsView()
}
