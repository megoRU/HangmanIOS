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

struct SettingsView: View {
    @AppStorage("gameLanguage") private var selectedLanguage = "RU"
    @AppStorage("gameCategory") private var selectedCategory = ""
    @AppStorage("appTheme") private var selectedTheme = AppTheme.system.rawValue
    
    let languages = ["EN": "English", "RU": "Русский"]
    let categories = ["": "Любая", "colors": "Цвета", "flowers": "Цветы", "fruits": "Фрукты"]
    let themes = AppTheme.allCases
    
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
            
            Section(header: Text("Тема")) {
                Picker("Тема", selection: $selectedTheme) {
                    ForEach(themes) { theme in
                        Text(theme.displayName).tag(theme.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedTheme) { oldValue, newValue in
                    applyTheme(AppTheme(rawValue: newValue) ?? .system)
                }
                .onAppear {
                    applyTheme(AppTheme(rawValue: selectedTheme) ?? .system)
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
    
    private func applyTheme(_ theme: AppTheme) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        switch theme {
        case .system:
            window.overrideUserInterfaceStyle = .unspecified
        case .light:
            window.overrideUserInterfaceStyle = .light
        case .dark:
            window.overrideUserInterfaceStyle = .dark
        }
    }
}

#Preview {
    MainMenuView()
}
