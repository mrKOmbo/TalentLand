//
//  EmergencyModeIntent.swift
//  Atenea
//
//  Intent to activate/deactivate emergency mode
//  Usage: "Hey Siri, activate emergency in Atenea"
//         "Hey Siri, deactivate emergency in Atenea"
//

import Foundation
import AppIntents

/// Intent to activate emergency mode
struct ActivateEmergencyIntent: AppIntent {
    static var title: LocalizedStringResource = "Activate Emergency Mode"
    static var description = IntentDescription("Activate emergency mode in Atenea")

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Activate emergency mode
        EmergencyModeManager.shared.activateEmergency()

        // NOTE: We do NOT save to UserDefaults - emergency mode is temporary
        // and should be deactivated when the app closes

        print("🚨 [APP INTENT] Emergency mode ACTIVATED (does not persist)")

        return .result(
            dialog: IntentDialog(stringLiteral: "Emergency mode activated. Stay safe.")
        )
    }
}

/// Intent to deactivate emergency mode
struct DeactivateEmergencyIntent: AppIntent {
    static var title: LocalizedStringResource = "Deactivate Emergency Mode"
    static var description = IntentDescription("Deactivate emergency mode in Atenea")

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Deactivate emergency mode
        EmergencyModeManager.shared.deactivateEmergency()

        print("✅ [APP INTENT] Emergency mode DEACTIVATED")

        return .result(
            dialog: IntentDialog(stringLiteral: "Emergency mode deactivated.")
        )
    }
}

/// Combined intent to toggle (activate/deactivate)
struct ToggleEmergencyIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Emergency"
    static var description = IntentDescription("Activate or deactivate emergency mode")

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let isCurrentlyActive = EmergencyModeManager.shared.isEmergencyActive

        if isCurrentlyActive {
            EmergencyModeManager.shared.deactivateEmergency()
            print("✅ [APP INTENT] Emergency mode DEACTIVATED (toggle)")
            return .result(dialog: IntentDialog(stringLiteral: "Emergency mode deactivated."))
        } else {
            EmergencyModeManager.shared.activateEmergency()
            print("🚨 [APP INTENT] Emergency mode ACTIVATED (toggle)")
            return .result(dialog: IntentDialog(stringLiteral: "Emergency mode activated. Stay safe."))
        }
    }
}
