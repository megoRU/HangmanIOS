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
    @AppStorage("name") private var name: String = ""
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
                Section(header: Text("Персонализация"))  {
                    HStack(spacing: 16) {
                        // Аватарка
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            avatarImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(
                                        LinearGradient(colors: [.blue, .purple],
                                                       startPoint: .topLeading,
                                                       endPoint: .bottomTrailing),
                                        lineWidth: 3
                                    )
                                )
                                .shadow(radius: 4)
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12))
                                        .padding(5)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                        .foregroundColor(.white)
                                        .shadow(radius: 1)
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

                        // Если имя пустое — кнопка, иначе поле с галкой
                        if name.isEmpty && !isEditingName {
                            Button {
                                isEditingName = true
                            } label: {
                                HStack {
                                    Spacer()
                                    Image(systemName: "pencil")
                                    Text("Задать имя")
                                    
                                    Spacer()
                                }
                                .foregroundColor(.blue)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            LinearGradient(colors: [.blue, .purple],
                                                           startPoint: .leading,
                                                           endPoint: .trailing),
                                            lineWidth: 2
                                        )
                                )
                            }
                        } else {
                            HStack {
                                TextField("", text: $name)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                LinearGradient(colors: [.blue, .purple],
                                                               startPoint: .leading,
                                                               endPoint: .trailing),
                                                lineWidth: 2
                                            )
                                    )
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.words)
                                    .disabled(!isEditingName)

                                Button {
                                    isEditingName.toggle()
                                } label: {
                                    Image(systemName: isEditingName ? "checkmark.circle.fill" : "pencil.circle.fill")
                                        .foregroundColor(isEditingName ? .green : .accentColor)
                                        .font(.title)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }


                // MARK: Язык
                Section(header: Text("Язык игры")) {
                    Picker("Выберите язык", selection: $selectedLanguage) {
                        ForEach(languages.keys.sorted(), id: \.self) { key in
                            Text(languages[key] ?? key)
                                .tag(key)
                        }
                    }
                }

                // MARK: Категория
                Section(header: Text("Категория"), footer: Text("Эта настройка применяется только для одиночной игры.")) {
                    Picker("Выберите категорию", selection: $selectedCategory) {
                        ForEach(categories.keys.sorted(), id: \.self) { key in
                            Text(categories[key] ?? key)
                                .tag(key)
                        }
                    }
                }

                // MARK: Оформление
                Section(header: Text("Оформление")) {
                    Picker("Тема", selection: $selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme.rawValue)
                        }
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
