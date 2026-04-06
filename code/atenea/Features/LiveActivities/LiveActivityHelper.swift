//
//  LiveActivityHelper.swift
//  Atenea
//
//  Helper para integrar Live Activities con la navegación existente
//
//  ⚠️ IMPORTANTE: Este archivo está temporalmente deshabilitado
//  Descomentar cuando se configure el Widget Extension target
//

import Foundation
import CoreLocation

/*
#if canImport(ActivityKit)
import ActivityKit

/// Helper para gestionar Live Activities de forma sencilla
@available(iOS 16.1, *)
class LiveActivityHelper {
    static let shared = LiveActivityHelper()

    private init() {}

    // NOTA: Este helper necesita ser reimplementado cuando se habiliten los Live Activities
    // Las referencias a NavigationLiveActivityManager han sido removidas temporalmente

    /// Verifica si Live Activities están disponibles y habilitadas
    var isLiveActivityAvailable: Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }

    // Métodos stub - implementar cuando se habilite el Live Activity Manager
    func startNavigationLiveActivity(to venue: WorldCupVenue, totalDistance: Double) {
        print("⚠️ [LIVE ACTIVITY] No disponible - Widget Extension no configurado")
    }

    func updateNavigationLiveActivity(distanceRemaining: CLLocationDistance, estimatedMinutes: Int, instruction: String, currentStreet: String = "", currentSpeed: Double = 0) {
        // No-op
    }

    func endNavigationLiveActivity() {
        // No-op
    }

    func cancelNavigationLiveActivity() {
        // No-op
    }
}

#endif
*/

// MARK: - Stub Implementation (Para compilación sin Widget Extension)

/// Helper stub para Live Activities cuando no está disponible
class LiveActivityHelper {
    static let shared = LiveActivityHelper()

    private init() {}

    var isLiveActivityAvailable: Bool {
        return false
    }

    func startNavigationLiveActivity(to venue: WorldCupVenue, totalDistance: Double) {
        print("⚠️ [LIVE ACTIVITY] No disponible - Requiere Widget Extension configurado")
    }

    func updateNavigationLiveActivity(distanceRemaining: CLLocationDistance, estimatedMinutes: Int, instruction: String, currentStreet: String = "", currentSpeed: Double = 0) {
        // No-op
    }

    func endNavigationLiveActivity() {
        // No-op
    }

    func cancelNavigationLiveActivity() {
        // No-op
    }
}
