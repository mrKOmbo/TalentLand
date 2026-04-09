import Foundation

struct Product: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let price: Double
    let description: String?
    let emoji: String
    let isAvailable: Bool
    var imageURL: String?

    init(id: UUID = UUID(), name: String, price: Double, description: String? = nil, emoji: String, isAvailable: Bool = true, imageURL: String? = nil) {
        self.id = id
        self.name = name
        self.price = price
        self.description = description
        self.emoji = emoji
        self.isAvailable = isAvailable
        self.imageURL = imageURL
    }

    var formattedPrice: String {
        "$\(String(format: "%.0f", price))"
    }
}
