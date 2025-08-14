import Foundation

struct Player: Codable, Identifiable {
    let id = UUID()
    let name: String
    let image: String?

    enum CodingKeys: String, CodingKey {
        case name
        case image
    }
}
