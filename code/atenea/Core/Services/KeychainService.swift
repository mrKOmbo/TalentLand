import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    private let serviceName = "com.atenea.auth"

    // MARK: - Keys

    private enum Key: String {
        case userEmail = "userEmail"
        case biometricEnabled = "biometricEnabled"
    }

    // MARK: - Public API

    /// Email del usuario con sesión biométrica guardada
    var savedEmail: String? {
        get { read(key: .userEmail) }
        set {
            if let value = newValue {
                save(key: .userEmail, value: value)
            } else {
                delete(key: .userEmail)
            }
        }
    }

    /// Flag de biometría habilitada
    var isBiometricEnabled: Bool {
        get { read(key: .biometricEnabled) == "true" }
        set { save(key: .biometricEnabled, value: newValue ? "true" : "false") }
    }

    /// Limpiar todo (logout)
    func clearAll() {
        delete(key: .userEmail)
        delete(key: .biometricEnabled)
    }

    // MARK: - Private Keychain Operations

    private func save(key: Key, value: String) {
        let data = Data(value.utf8)

        // Borrar existente primero
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("[Keychain] Error guardando \(key.rawValue): \(status)")
        }
    }

    private func read(key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]
        SecItemDelete(query as CFDictionary)
    }
}
