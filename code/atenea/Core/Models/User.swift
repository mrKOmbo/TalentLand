//
//  User.swift
//  atenea
//
//  Modelo de usuario con sistema de roles
//

import Foundation

// MARK: - User Role
enum UserRole: String, Codable {
    case admin = "admin"
    case user = "user"

    var displayName: String {
        switch self {
        case .admin: return "Administrador"
        case .user: return "Usuario"
        }
    }
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

    init(id: UUID = UUID(), email: String, name: String, role: UserRole, createdAt: Date = Date(), accessibilityOption: AccessibilityOption = .none, age: String? = nil, country: String? = nil, phoneNumber: String? = nil, profileImage: String? = nil) {
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
    }

    // Verificar si el usuario es administrador
    var isAdmin: Bool {
        return role == .admin
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
