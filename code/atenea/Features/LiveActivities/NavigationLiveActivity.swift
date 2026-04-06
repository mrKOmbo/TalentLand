//
//  NavigationLiveActivity.swift
//  Atenea
//
//  Widget configuration para el Live Activity de navegación
//
//  ⚠️ IMPORTANTE: Este archivo está temporalmente deshabilitado
//  Descomentar cuando se configure el Widget Extension target
//

import SwiftUI
internal import Combine

/*
#if canImport(ActivityKit)
import ActivityKit
import WidgetKit

/// Configuración del Live Activity para navegación
@available(iOS 16.1, *)
struct NavigationLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NavigationActivityAttributes.self) { context in
            // Vista para Lock Screen
            NavigationLiveActivityView(context: context)

        } dynamicIsland: { context in
            // Configuración del Dynamic Island
            DynamicIsland {
                // Región expandida (cuando se presiona y mantiene)
                DynamicIslandExpandedRegion(.center) {
                    NavigationLiveActivityExpandedView(context: context)
                }

            } compactLeading: {
                // Vista compacta lado izquierdo
                Image(systemName: "location.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: context.attributes.venueColorHex))

            } compactTrailing: {
                // Vista compacta lado derecho
                VStack(spacing: 0) {
                    Text(formatCompactDistance(context.state.distanceRemaining))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }

            } minimal: {
                // Vista mínima (cuando hay múltiples Live Activities)
                NavigationLiveActivityMinimalView(context: context)
            }
        }
    }

    private func formatCompactDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1f", meters / 1000) + "k"
        }
    }
}

// MARK: - Live Activity Manager

/// Manager para controlar el Live Activity de navegación
@available(iOS 16.1, *)
class NavigationLiveActivityManager: ObservableObject {
    static let shared = NavigationLiveActivityManager()

    @Published var currentActivity: Activity<NavigationActivityAttributes>?

    private init() {}

    /// Inicia un nuevo Live Activity de navegación
    func startNavigationActivity(
        destination: String,
        city: String,
        totalDistance: Double,
        venueColorHex: String
    ) async {
        // Verificar si Live Activities están permitidas
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("❌ [LIVE ACTIVITY] Live Activities no están habilitadas")
            return
        }

        // Detener actividad previa si existe
        await endNavigationActivity()

        // Crear los atributos estáticos
        let attributes = NavigationActivityAttributes(
            destinationName: destination,
            destinationCity: city,
            totalDistance: totalDistance,
            startTime: Date(),
            venueColorHex: venueColorHex
        )

        // Crear el estado inicial
        let initialState = NavigationActivityAttributes.ContentState(
            distanceRemaining: totalDistance * 1000, // Convertir a metros
            estimatedMinutes: Int(totalDistance * 2), // Estimación inicial
            currentInstruction: "Iniciando navegación...",
            currentStreet: "",
            currentSpeed: 0,
            lastUpdate: Date(),
            navigationState: .active
        )

        do {
            // Solicitar el Live Activity
            let activity = try Activity<NavigationActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            currentActivity = activity
            print("✅ [LIVE ACTIVITY] Navegación iniciada: \(destination)")

        } catch {
            print("❌ [LIVE ACTIVITY] Error al iniciar: \(error)")
        }
    }

    /// Actualiza el estado del Live Activity
    func updateNavigationActivity(
        distanceRemaining: Double,
        estimatedMinutes: Int,
        instruction: String,
        street: String,
        speed: Double,
        state: NavigationActivityAttributes.ContentState.NavigationState = .active
    ) async {
        guard let activity = currentActivity else {
            print("⚠️ [LIVE ACTIVITY] No hay actividad activa para actualizar")
            return
        }

        let updatedState = NavigationActivityAttributes.ContentState(
            distanceRemaining: distanceRemaining,
            estimatedMinutes: estimatedMinutes,
            currentInstruction: instruction,
            currentStreet: street,
            currentSpeed: speed,
            lastUpdate: Date(),
            navigationState: state
        )

        await activity.update(
            .init(
                state: updatedState,
                staleDate: Date().addingTimeInterval(60) // Stale después de 1 minuto
            )
        )

        print("🔄 [LIVE ACTIVITY] Actualizado: \(Int(distanceRemaining))m, \(estimatedMinutes)min")
    }

    /// Finaliza el Live Activity
    func endNavigationActivity(dismissalPolicy: ActivityUIDismissalPolicy = .default) async {
        guard let activity = currentActivity else { return }

        // Actualizar a estado "llegado"
        let arrivedState = NavigationActivityAttributes.ContentState(
            distanceRemaining: 0,
            estimatedMinutes: 0,
            currentInstruction: "¡Has llegado a tu destino!",
            currentStreet: "",
            currentSpeed: 0,
            lastUpdate: Date(),
            navigationState: .arrived
        )

        await activity.update(
            .init(
                state: arrivedState,
                staleDate: nil
            )
        )

        // Finalizar después de 2 segundos para que el usuario vea el mensaje
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 segundos

        await activity.end(
            .init(
                state: arrivedState,
                staleDate: nil
            ),
            dismissalPolicy: dismissalPolicy
        )

        currentActivity = nil
        print("✅ [LIVE ACTIVITY] Navegación finalizada")
    }

    /// Cancela el Live Activity inmediatamente
    func cancelNavigationActivity() async {
        guard let activity = currentActivity else { return }

        await activity.end(nil, dismissalPolicy: .immediate)
        currentActivity = nil

        print("🚫 [LIVE ACTIVITY] Navegación cancelada")
    }
}

#endif
*/
