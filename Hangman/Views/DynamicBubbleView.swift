import SwiftUI

private let modelNumber = DeviceModelNumber.current

struct DynamicBubbleView: View {
    var body: some View {
        VStack {
            if let value = Int(modelNumber).map({ $0 - 1 }), value >= 15 {
                HStack(spacing: 8) {
                    Image("island")
                        .resizable()
                        .frame(width: 20, height: 20)
                    
                    Text("Hangman")
                        .foregroundColor(.white)
                        .bold()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(25)
                .shadow(radius: 4)
                .padding(14)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .edgesIgnoringSafeArea(.top)
    }
}

struct DeviceModelNumber {
    static var current: String {
        let identifier = hardwareIdentifier() // напр. "iPhone15,4"
        if identifier.hasPrefix("iPhone") {
            let digits = identifier
                .dropFirst("iPhone".count) // убираем "iPhone"
                .split(separator: ",")     // берём "15" из "15,4"
                .first ?? ""
            return String(digits)
        }
        return identifier
    }
    
    private static func hardwareIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) { ptr -> String in
            let int8Ptr = UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self)
            return String(cString: int8Ptr)
        }
    }
}

#Preview {
    MainMenuView()
}
