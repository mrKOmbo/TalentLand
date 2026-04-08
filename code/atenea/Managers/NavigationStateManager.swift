//
//  NavigationStateManager.swift
//  atenea
//
//  Manager para mantener el estado de navegación activa
//

import Foundation
internal import Combine

class NavigationStateManager: ObservableObject {
    static let shared = NavigationStateManager()

    @Published var isNavigationActive: Bool = false
    @Published var shouldOpenNavigation: Bool = false
    @Published var merchantLocationEditMode: Bool = false

    private init() {}

    func startNavigation() {
        isNavigationActive = true
        print("🧭 [NAV STATE] Navegación marcada como activa")
    }

    func stopNavigation() {
        isNavigationActive = false
        print("🧭 [NAV STATE] Navegación marcada como inactiva")
    }

    func requestOpenNavigation() {
        if isNavigationActive {
            shouldOpenNavigation = true
            print("🧭 [NAV STATE] Solicitado abrir navegación activa")
        } else {
            print("⚠️ [NAV STATE] No hay navegación activa para abrir")
        }
    }
}
