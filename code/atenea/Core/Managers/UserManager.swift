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
        ),
        // Clientes nuevos
        User(
            email: "james@atenea.com",
            name: "James",
            role: .user,
            accessibilityOption: .none,
            age: "32",
            country: "Estados Unidos",
            phoneNumber: "+1 310 555 7890",
            profileImage: nil
        ),
        User(
            email: "sofia@atenea.com",
            name: "Sofía",
            role: .user,
            accessibilityOption: .none,
            age: "26",
            country: "Argentina",
            phoneNumber: "+54 11 4567 8901",
            profileImage: nil
        ),
        User(
            email: "carlos@atenea.com",
            name: "Carlos",
            role: .user,
            accessibilityOption: .none,
            age: "35",
            country: "México",
            phoneNumber: "+52 55 3344 5566",
            profileImage: nil
        ),
        // Comerciantes nuevos
        User(
            email: "maria.elotes@atenea.com",
            name: "María",
            role: .merchant,
            accessibilityOption: .none,
            age: "38",
            country: "México",
            phoneNumber: "+52 55 6677 8899",
            profileImage: nil
        ),
        User(
            email: "pepe.carnitas@atenea.com",
            name: "Pepe",
            role: .merchant,
            accessibilityOption: .none,
            age: "52",
            country: "México",
            phoneNumber: "+52 55 1122 3344",
            profileImage: nil
        )
    ]

    private var needsMerchantLink = false

    private init() {
        // Restaurar sesión previa si existe
        if UserDefaults.standard.bool(forKey: "isUserLoggedIn"),
           let email = UserDefaults.standard.string(forKey: "currentUserEmail"),
           let user = predefinedUsers.first(where: { $0.email.lowercased() == email.lowercased() }) {
            currentUser = user
            needsMerchantLink = user.isMerchant
            print("🔄 Sesión restaurada: \(user.name) (\(user.role.displayName))")
        } else {
            currentUser = nil
        }
    }

    /// Llamar una vez que la app esté lista para vincular el merchant profile
    func ensureMerchantLinked() {
        guard needsMerchantLink else { return }
        needsMerchantLink = false
        MerchantManager.shared.linkCurrentUserProfile()
    }

    // MARK: - User Management

    /// Cambiar usuario actual por email
    func loginUser(withEmail email: String) -> Bool {
        if let user = predefinedUsers.first(where: { $0.email.lowercased() == email.lowercased() }) {
            currentUser = user
            // Vincular perfil de negocio
            MerchantManager.shared.linkCurrentUserProfile()
            print("✅ Usuario logueado: \(user.name) (\(user.role.displayName))")

            // Sync user to Supabase
            Task {
                try? await SupabaseService.shared.saveUser(user)
            }

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
