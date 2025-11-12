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
import PhotosUI

struct SettingsView: View {
    @AppStorage("gameLanguage") private var selectedLanguage: String = "RU"
    @AppStorage("gameCategory") private var selectedCategory: String = ""
    @AppStorage("appTheme") private var selectedTheme: String = AppTheme.system.rawValue
    @AppStorage("name") private var name: String = "Noname"
    @AppStorage("avatarImage") private var avatarData: Data?

    @State private var isEditingName = false
    @State private var selectedItem: PhotosPickerItem?

    let languages = ["RU": "Русский", "EN": "Английский"]
    let categories = ["": "Любая", "colors": "Цвета", "flowers": "Цветы", "fruits": "Фрукты"]

    var avatarImage: Image {
        if let data = avatarData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: "person.fill")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Аватарка + имя
                Section(header: Text("Профиль")) {
                    HStack(spacing: 16) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            avatarImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12))
                                        .padding(6)
                                        .background(.gray.opacity(0.7))
                                        .clipShape(Circle())
                                        .foregroundColor(.white)
                                }
                        }
                        .buttonStyle(.plain)
                        .onChange(of: selectedItem) { _ in
                            Task {
                                if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    let resizedImage = uiImage.resize(to: CGSize(width: 1024, height: 1024))
                                    avatarData = resizedImage?.jpegData(compressionQuality: 1.0)
                                }
                            }
                        }

                        Text(name.isEmpty ? "Noname" : name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.vertical, 6)
                }

                Section(header: Text("Имя пользователя")) {
                    HStack {
                        TextField("Noname", text: $name)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .disabled(!isEditingName)

                        Button {
                            isEditingName.toggle()
                        } label: {
                            Image(systemName: isEditingName ? "checkmark.circle.fill" : "pencil")
                                .foregroundColor(isEditingName ? .green : .accentColor)
                                .font(.title2)
                        }
                    }
                }

                // MARK: Язык
                Section(header: Text("Язык игры")) {
                    Picker(selection: $selectedLanguage) {
                        ForEach(languages.keys.sorted(), id: \.self) { key in
                            Text(languages[key] ?? key)
                                .tag(key)
                        }
                    } label: {
                        Label("Язык", systemImage: "globe")
                    }
                }

                // MARK: Категория
                Section(header: Text("Категория"), footer: Text("Эта настройка применяется только для одиночной игры.")) {
                    Picker(selection: $selectedCategory) {
                        ForEach(categories.keys.sorted(), id: \.self) { key in
                            Text(categories[key] ?? key)
                                .tag(key)
                        }
                    } label: {
                        Label("Категория", systemImage: "tag")
                    }
                }

                // MARK: Оформление
                Section(header: Text("Оформление")) {
                    Picker(selection: $selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme.rawValue)
                        }
                    } label: {
                        Label("Тема", systemImage: "paintbrush")
                    }
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
                        Text("3.0.0")
                    }
                }
            }
            .navigationTitle("Настройки")
        }
    }
}

#Preview {
    MainMenuView()
}

extension UIImage {
    func resize(to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
