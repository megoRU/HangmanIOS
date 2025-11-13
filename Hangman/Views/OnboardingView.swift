import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted: Bool = false
    @AppStorage("name") private var name: String = ""
    @AppStorage("userAge") private var userAge: Int = 0
    @AppStorage("avatarImage") private var avatarData: Data?

    @State private var ageInput: String = ""
    @State private var selectedItem: PhotosPickerItem?

    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isAgeFieldFocused: Bool

    var avatarImage: Image {
        if let data = avatarData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: "person.circle.fill")
        }
    }

    var isInputValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !ageInput.isEmpty &&
        (Int(ageInput) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    Text(NSLocalizedString("onboarding_welcome", comment: ""))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 40)

                    Text(NSLocalizedString("onboarding_subtitle", comment: ""))
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        VStack {
                            avatarImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .foregroundColor(.gray.opacity(0.5))

                            Text(NSLocalizedString("onboarding_select_photo", comment: ""))
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                    .onChange(of: selectedItem) { _ in
                        Task {
                            if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                let resizedImage = uiImage.resize(to: CGSize(width: 512, height: 512))
                                avatarData = resizedImage?.jpegData(compressionQuality: 0.8)
                            }
                        }
                    }

                    VStack(spacing: 20) {
                        TextField(NSLocalizedString("onboarding_name_placeholder", comment: ""), text: $name)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .textContentType(.username)
                            .focused($isNameFieldFocused)

                        TextField(NSLocalizedString("onboarding_age_placeholder", comment: ""), text: $ageInput)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .keyboardType(.numberPad)
                            .focused($isAgeFieldFocused)
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button(action: completeOnboarding) {
                        Text(NSLocalizedString("onboarding_continue_button", comment: ""))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isInputValid ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!isInputValid)
                    .padding()
                }
            }
            .navigationTitle(NSLocalizedString("onboarding_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(NSLocalizedString("onboarding_done_button", comment: "")) {
                        isNameFieldFocused = false
                        isAgeFieldFocused = false
                    }
                }
            }
        }
    }

    private func completeOnboarding() {
        if let age = Int(ageInput) {
            userAge = age
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                name = "Noname"
            }
            isOnboardingCompleted = true
        }
    }
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

#Preview {
    OnboardingView()
}
