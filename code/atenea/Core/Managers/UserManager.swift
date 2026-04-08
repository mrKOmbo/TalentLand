//
//  UserManager.swift
//  atenea
//
//  Gestor de usuarios y roles
//

import Foundation
internal import Combine

class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published var currentUser: User?

    // Usuarios predefinidos para la app
    private let predefinedUsers: [User] = [
        User(
            email: "emi@atenea.com",
            name: "Emi",
            role: .admin,
            accessibilityOption: .none,
            age: "25",
            country: "México",
            phoneNumber: "+52 55 1234 5678",
            profileImage: "MILO"
        ),
        User(
            email: "sebas@atenea.com",
            name: "Sebas",
            role: .user,
            accessibilityOption: .none,
            age: "28",
            country: "España",
            phoneNumber: "+34 91 234 5678",
            profileImage: nil
        ),
        User(
            email: "don.taco@atenea.com",
            name: "Don Taco",
            role: .merchant,
            accessibilityOption: .none,
            age: "45",
            country: "México",
            phoneNumber: "+52 55 9876 5432",
            profileImage: nil
        )
    ]

    private init() {
        // No iniciar con ningún usuario - forzar login
        currentUser = nil
    }

    // MARK: - User Management

    /// Cambiar usuario actual por email
    func loginUser(withEmail email: String) -> Bool {
        if let user = predefinedUsers.first(where: { $0.email.lowercased() == email.lowercased() }) {
            currentUser = user
            // Si es merchant, vincular perfil de negocio
            if user.isMerchant {
                MerchantManager.shared.currentMerchantProfile = MerchantManager.shared.merchantForUser(user.id)
            }
            print("✅ Usuario logueado: \(user.name) (\(user.role.displayName))")
            return true
        }
        print("❌ Usuario no encontrado: \(email)")
        return false
    }

    /// Cerrar sesión
    func logout() {
        MerchantManager.shared.currentMerchantProfile = nil
        currentUser = nil
        print("👋 Usuario deslogueado")
    }

    /// Verificar si el usuario actual es administrador
    var isCurrentUserAdmin: Bool {
        return currentUser?.isAdmin ?? false
    }

    /// Verificar si el usuario actual tiene acceso a Staff
    var hasStaffAccess: Bool {
        return currentUser?.hasStaffAccess ?? false
    }

    /// Obtener todos los usuarios disponibles (para testing)
    func getAllUsers() -> [User] {
        return predefinedUsers
    }

    /// Agregar un nuevo usuario (para futuras expansiones)
    func addUser(_ user: User) {
        // Esta función se puede implementar para agregar usuarios dinámicamente
        // Por ahora solo usamos los predefinidos
        print("⚠️ Agregar usuarios dinámicamente no está implementado aún")
    }
}
