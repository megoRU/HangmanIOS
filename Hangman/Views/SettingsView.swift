import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return NSLocalizedString("theme_system", comment: "")
        case .light: return NSLocalizedString("theme_light", comment: "")
        case .dark: return NSLocalizedString("theme_dark", comment: "")
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
    @FocusState private var isNameFieldFocused: Bool

    let languages = ["RU": NSLocalizedString("language_russian", comment: ""), "EN": NSLocalizedString("language_english", comment: "")]
    let categories = ["": NSLocalizedString("category_any", comment: ""), "colors": NSLocalizedString("category_colors", comment: ""), "flowers": NSLocalizedString("category_flowers", comment: ""), "fruits": NSLocalizedString("category_fruits", comment: "")]

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
                Section(header: Text(NSLocalizedString("profile_section", comment: ""))) {
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

                        if isEditingName {
                            TextField(NSLocalizedString("name_placeholder", comment: ""), text: $name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .focused($isNameFieldFocused)
                                .onSubmit {
                                    if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        name = "Noname"
                                    }
                                    isEditingName = false
                                }
                        } else {
                            Text(name.isEmpty ? "Noname" : name)
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        Button {
                            if isEditingName {
                                if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    name = "Noname"
                                }
                            }
                            isEditingName.toggle()
                        } label: {
                            Image(systemName: isEditingName ? "checkmark.circle.fill" : "pencil")
                                .foregroundColor(isEditingName ? .green : .accentColor)
                                .font(.title2)
                        }
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isEditingName = true
                    }
                    .onChange(of: isEditingName) { editing in
                        if editing {
                            isNameFieldFocused = true
                        }
                    }
                }

                // MARK: Язык
                Section(header: Text(NSLocalizedString("game_language_section", comment: ""))) {
                    Picker(selection: $selectedLanguage) {
                        ForEach(languages.keys.sorted(), id: \.self) { key in
                            Text(languages[key] ?? key)
                                .tag(key)
                        }
                    } label: {
                        Label(NSLocalizedString("language_label", comment: ""), systemImage: "globe")
                    }
                }

                // MARK: Категория
                Section(header: Text(NSLocalizedString("category_section", comment: "")), footer: Text(NSLocalizedString("category_footer", comment: ""))) {
                    Picker(selection: $selectedCategory) {
                        ForEach(categories.keys.sorted(), id: \.self) { key in
                            Text(categories[key] ?? key)
                                .tag(key)
                        }
                    } label: {
                        Label(NSLocalizedString("category_section", comment: ""), systemImage: "tag")
                    }
                }

                // MARK: Оформление
                Section(header: Text(NSLocalizedString("appearance_section", comment: ""))) {
                    Picker(selection: $selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme.rawValue)
                        }
                    } label: {
                        Label(NSLocalizedString("theme_label", comment: ""), systemImage: "paintbrush")
                    }
                }

                Section {
                    Link(destination: URL(string: "https://t.me/mego_RU")!) {
                        Label(NSLocalizedString("support_label", comment: ""), systemImage: "link")
                    }
                }

                Section {
                    HStack {
                        Label(NSLocalizedString("version_label", comment: ""), systemImage: "info.circle")
                        Spacer()
                        Text("3.0.0")
                    }
                }
            }
            .navigationTitle(NSLocalizedString("settings_tab", comment: ""))
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
