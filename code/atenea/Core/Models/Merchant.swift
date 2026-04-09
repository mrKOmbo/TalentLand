import Foundation
import CoreLocation

// MARK: - Merchant Category

enum MerchantCategory: String, Codable, CaseIterable {
    case tacos = "tacos"
    case tamales = "tamales"
    case helados = "helados"
    case jugos = "jugos"
    case elotes = "elotes"
    case frutas = "frutas"
    case antojitos = "antojitos"
    case bebidas = "bebidas"
    case postres = "postres"
    case otro = "otro"

    var emoji: String {
        switch self {
        case .tacos: return "🌮"
        case .tamales: return "🫔"
        case .helados: return "🍦"
        case .jugos: return "🥤"
        case .elotes: return "🌽"
        case .frutas: return "🍉"
        case .antojitos: return "🫘"
        case .bebidas: return "🧃"
        case .postres: return "🍮"
        case .otro: return "🛒"
        }
    }

    var displayName: String {
        switch self {
        case .tacos: return "Tacos"
        case .tamales: return "Tamales"
        case .helados: return "Helados"
        case .jugos: return "Jugos"
        case .elotes: return "Elotes y Esquites"
        case .frutas: return "Frutas"
        case .antojitos: return "Antojitos"
        case .bebidas: return "Bebidas"
        case .postres: return "Postres"
        case .otro: return "Otro"
        }
    }
}

// MARK: - Merchant Schedule

struct MerchantSchedule: Codable, Equatable {
    let openTime: String   // "08:00"
    let closeTime: String  // "22:00"
    let daysOfWeek: [Int]  // 1=lunes ... 7=domingo

    var isOpenNow: Bool {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        // Calendar.weekday: 1=domingo, 2=lunes ... 7=sábado
        // Convertir a 1=lunes ... 7=domingo
        let adjustedDay = weekday == 1 ? 7 : weekday - 1

        guard daysOfWeek.contains(adjustedDay) else { return false }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let nowString = formatter.string(from: now)

        return nowString >= openTime && nowString <= closeTime
    }
}

// MARK: - Merchant Location

struct MerchantLocation: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let geohash: String
    let updatedAt: Date
    let accuracy: Double?

    init(latitude: Double, longitude: Double, updatedAt: Date = Date(), accuracy: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.geohash = Geohash.encode(latitude: latitude, longitude: longitude, precision: GeohashChannelLevel.neighborhood.precision)
        self.updatedAt = updatedAt
        self.accuracy = accuracy
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Merchant

struct Merchant: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let businessName: String
    let category: MerchantCategory
    let emoji: String
    let description: String
    let products: [Product]
    let schedule: MerchantSchedule?
    var isActive: Bool
    let isStatic: Bool
    var currentLocation: MerchantLocation?
    let route: MerchantRoute? // Route for mobile merchants
    let createdAt: Date
    let isVerified: Bool
    let trustLevel: TrustLevel

    init(
        id: UUID = UUID(),
        userId: UUID,
        businessName: String,
        category: MerchantCategory,
        emoji: String? = nil,
        description: String = "",
        products: [Product] = [],
        schedule: MerchantSchedule? = nil,
        isActive: Bool = true,
        isStatic: Bool = true,
        currentLocation: MerchantLocation? = nil,
        route: MerchantRoute? = nil,
        createdAt: Date = Date(),
        isVerified: Bool = false,
        trustLevel: TrustLevel = .unverified
    ) {
        self.id = id
        self.userId = userId
        self.businessName = businessName
        self.category = category
        self.emoji = emoji ?? category.emoji
        self.description = description
        self.products = products
        self.schedule = schedule
        self.isActive = isActive
        self.isStatic = isStatic
        self.currentLocation = currentLocation
        self.route = route
        self.createdAt = createdAt
        self.isVerified = isVerified
        self.trustLevel = trustLevel
    }

    var isCurrentlyOpen: Bool {
        guard let schedule = schedule else { return isActive }
        return isActive && schedule.isOpenNow
    }

    static func == (lhs: Merchant, rhs: Merchant) -> Bool {
        lhs.id == rhs.id
    }
}
