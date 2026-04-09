import Foundation
import LocalAuthentication

final class BiometricAuthService {
    static let shared = BiometricAuthService()
    private init() {}

    // MARK: - Biometric Type

    enum BiometricType {
        case faceID
        case touchID
        case none
    }

    /// Tipo de biometría disponible en el dispositivo
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        default: return .none
        }
    }

    /// Nombre para mostrar en UI ("Face ID" o "Touch ID")
    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .none: return ""
        }
    }

    /// SF Symbol correspondiente
    var biometricIcon: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .none: return "lock.fill"
        }
    }

    /// El dispositivo soporta biometría
    var isAvailable: Bool {
        biometricType != .none
    }

    /// Biometría configurada Y habilitada por el usuario en Atenea
    var isEnabled: Bool {
        isAvailable && KeychainService.shared.isBiometricEnabled
    }

    /// Hay una sesión biométrica guardada lista para usar
    var hasSavedSession: Bool {
        isEnabled && KeychainService.shared.savedEmail != nil
    }

    // MARK: - Authentication

    /// Autenticar con Face ID / Touch ID
    @MainActor
    func authenticate(reason: String? = nil) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancelar"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("[Biometric] No disponible: \(error?.localizedDescription ?? "unknown")")
            return false
        }

        let localizedReason = reason ?? "Inicia sesión con \(biometricName)"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: localizedReason
            )
            print("[Biometric] Resultado: \(success ? "OK" : "FAIL")")
            return success
        } catch {
            print("[Biometric] Error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Enable / Disable

    /// Activar biometría para el email dado (llamar tras login exitoso)
    func enable(forEmail email: String) {
        KeychainService.shared.savedEmail = email
        KeychainService.shared.isBiometricEnabled = true
        print("[Biometric] Habilitado para \(email)")
    }

    /// Desactivar biometría (no borra la sesión por si quieren reactivar)
    func disable() {
        KeychainService.shared.isBiometricEnabled = false
        print("[Biometric] Deshabilitado")
    }

    /// Limpiar todo (logout completo)
    func clearSession() {
        KeychainService.shared.clearAll()
        print("[Biometric] Sesión limpiada")
    }
}
