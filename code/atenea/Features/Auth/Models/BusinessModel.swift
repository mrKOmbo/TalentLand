//
//  BusinessModel.swift
//  Atenea
//
//  Model for merchant business information
//

import Foundation

// MARK: - Business Type
enum BusinessType: String, CaseIterable, Identifiable, Codable {
    case food = "food"
    case clothing = "clothing"
    case crafts = "crafts"
    case beverages = "beverages"
    case electronics = "electronics"
    case services = "services"
    case other = "other"

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .food: return "Alimentos"
        case .clothing: return "Ropa"
        case .crafts: return "Artesanías"
        case .beverages: return "Bebidas"
        case .electronics: return "Electrónicos"
        case .services: return "Servicios"
        case .other: return "Otro"
        }
    }

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .clothing: return "tshirt.fill"
        case .crafts: return "paintpalette.fill"
        case .beverages: return "cup.and.saucer.fill"
        case .electronics: return "laptopcomputer"
        case .services: return "hammer.fill"
        case .other: return "tag.fill"
        }
    }
}

// MARK: - Business Size
enum BusinessSize: String, CaseIterable, Identifiable, Codable {
    case individual = "individual"
    case small = "small"
    case medium = "medium"

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .individual: return "Individual"
        case .small: return "Pequeño (2-5 personas)"
        case .medium: return "Mediano (6+ personas)"
        }
    }
}

// MARK: - Business Mobility
enum BusinessMobility: String, CaseIterable, Identifiable, Codable {
    case fixed = "fixed"
    case mobile = "mobile"

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .fixed: return "Estático"
        case .mobile: return "Ambulante"
        }
    }

    var icon: String {
        switch self {
        case .fixed: return "building.2.fill"
        case .mobile: return "figure.walk"
        }
    }
}

// MARK: - Business Model
struct BusinessModel: Codable, Identifiable {
    let id: UUID
    let ownerId: UUID
    let name: String
    let address: String
    let businessType: BusinessType
    let businessSize: BusinessSize
    let mobility: BusinessMobility
    let hasCoppelAccount: Bool
    let route: MerchantRoute? // Route for mobile merchants
    let createdAt: Date

    init(
        id: UUID = UUID(),
        ownerId: UUID,
        name: String,
        address: String,
        businessType: BusinessType,
        businessSize: BusinessSize,
        mobility: BusinessMobility,
        hasCoppelAccount: Bool = false,
        route: MerchantRoute? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.address = address
        self.businessType = businessType
        self.businessSize = businessSize
        self.mobility = mobility
        self.hasCoppelAccount = hasCoppelAccount
        self.route = route
        self.createdAt = createdAt
    }

    // Predefined Coppel Emprende business
    static func coppelEmprendeDefault(ownerId: UUID) -> BusinessModel {
        return BusinessModel(
            ownerId: ownerId,
            name: "Mi Negocio Coppel",
            address: "Ubicación por definir",
            businessType: .food,
            businessSize: .individual,
            mobility: .mobile,
            hasCoppelAccount: true
        )
    }
}
