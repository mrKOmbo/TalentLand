//
//  User.swift
//  atenea
//
//  Modelo de usuario con sistema de roles
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - User Role
enum UserRole: String, Codable {
    case admin = "admin"
    case merchant = "merchant"
    case user = "user"

    var displayName: String {
        switch self {
        case .admin: return "Administrador"
        case .merchant: return "Comerciante"
        case .user: return "Usuario"
        }
    }
}

// MARK: - Trust Level
enum TrustLevel: String, Codable, CaseIterable {
    case unverified = "unverified"
    case basic = "basic"           // Email verificado
    case verified = "verified"     // Identidad verificada
    case trusted = "trusted"       // Cadena de confianza (verificado por otros verificados)

    var displayName: String {
        switch self {
        case .unverified: return "Sin verificar"
        case .basic: return "Básico"
        case .verified: return "Verificado"
        case .trusted: return "Confianza"
        }
    }

    var icon: String {
        switch self {
        case .unverified: return "person.fill.questionmark"
        case .basic: return "person.fill.checkmark"
        case .verified: return "checkmark.seal.fill"
        case .trusted: return "checkmark.shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .unverified: return .gray
        case .basic: return .blue
        case .verified: return .green
        case .trusted: return .green
        }
    }

    var isGreen: Bool {
        self == .verified || self == .trusted
    }
}

// MARK: - User Location
struct UserLocation: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let address: String?
}

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let name: String
    let role: UserRole
    let createdAt: Date
    let accessibilityOption: AccessibilityOption
    let age: String?
    let country: String?
    let phoneNumber: String?
    let profileImage: String?
    var currentLocation: UserLocation?
    var routeHistory: [UserLocation]
    let isVerified: Bool
    let trustLevel: TrustLevel

    init(id: UUID = UUID(), email: String, name: String, role: UserRole, createdAt: Date = Date(), accessibilityOption: AccessibilityOption = .none, age: String? = nil, country: String? = nil, phoneNumber: String? = nil, profileImage: String? = nil, currentLocation: UserLocation? = nil, routeHistory: [UserLocation] = [], isVerified: Bool = false, trustLevel: TrustLevel = .unverified) {
        self.id = id
        self.email = email
        self.name = name
        self.role = role
        self.createdAt = createdAt
        self.accessibilityOption = accessibilityOption
        self.age = age
        self.country = country
        self.phoneNumber = phoneNumber
        self.profileImage = profileImage
        self.currentLocation = currentLocation
        self.routeHistory = routeHistory
        self.isVerified = isVerified
        self.trustLevel = trustLevel
    }

    // Verificar si el usuario es administrador
    var isAdmin: Bool {
        return role == .admin
    }

    var isMerchant: Bool {
        return role == .merchant
    }

    // Verificar si el usuario tiene permisos de staff
    var hasStaffAccess: Bool {
        return role == .admin
    }

    // MARK: - Accessibility Helpers

    /// Verifica si el usuario tiene discapacidad visual
    var hasVisualDisability: Bool {
        return accessibilityOption == .visual || accessibilityOption == .multiple
    }

    /// Verifica si el usuario tiene discapacidad auditiva
    var hasHearingDisability: Bool {
        return accessibilityOption == .hearing || accessibilityOption == .multiple
    }

    /// Verifica si el usuario tiene discapacidad motriz
    var hasMotorDisability: Bool {
        return accessibilityOption == .motor || accessibilityOption == .multiple
    }

    /// Verifica si el usuario tiene discapacidad cognitiva
    var hasCognitiveDisability: Bool {
        return accessibilityOption == .cognitive || accessibilityOption == .multiple
    }

    /// Verifica si el usuario tiene discapacidad del habla
    var hasSpeechDisability: Bool {
        return accessibilityOption == .speech || accessibilityOption == .multiple
    }

    /// Verifica si el usuario tiene discapacidad neurológica
    var hasNeurologicalDisability: Bool {
        return accessibilityOption == .neurological || accessibilityOption == .multiple
    }

    /// Verifica si el usuario necesita funcionalidades de accesibilidad
    var needsAccessibilityFeatures: Bool {
        return accessibilityOption != .none && accessibilityOption != .preferNotToSay
    }
}
