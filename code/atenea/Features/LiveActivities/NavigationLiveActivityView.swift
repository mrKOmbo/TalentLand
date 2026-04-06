//
//  NavigationLiveActivityView.swift
//  Atenea
//
//  Vistas para mostrar navegación activa en Dynamic Island y Lock Screen
//
//  ⚠️ IMPORTANTE: Este archivo está temporalmente deshabilitado
//
//  Los Live Activities requieren:
//  1. Un Widget Extension target separado
//  2. iOS 16.1+ como deployment target
//  3. Configuración especial en Info.plist
//  4. ActivityKit debe estar disponible en el target
//
//  Para habilitar Live Activities:
//  1. Crea un nuevo Widget Extension target en Xcode
//  2. Mueve este archivo al nuevo target
//  3. Implementa el ActivityConfiguration en el Widget Extension
//
//  Por ahora, este archivo no se compila para evitar errores.
//

import SwiftUI

// El código está comentado temporalmente para evitar errores de compilación
// Descomentar cuando se configure el Widget Extension target

/*
#if canImport(ActivityKit)
import ActivityKit

// MARK: - Views

/// Vista principal del Live Activity de navegación
@available(iOS 16.1, *)
struct NavigationLiveActivityView: View {
    let attributes: NavigationActivityAttributes
    let state: NavigationActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 0) {
            // Encabezado con destino
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(Color(hex: attributes.venueColorHex))
                    .font(.system(size: 16, weight: .semibold))

                VStack(alignment: .leading, spacing: 2) {
                    Text(attributes.destinationName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(attributes.destinationCity)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Estado
                Text(state.navigationState.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Información principal
            HStack(spacing: 20) {
                // Distancia
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDistance(state.distanceRemaining))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: attributes.venueColorHex))

                    Text("Restante")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 40)

                // Tiempo estimado
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(state.estimatedMinutes)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)

                    Text("minutos")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Instrucción actual
            HStack {
                Image(systemName: "arrow.turn.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text(state.currentInstruction)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }
}

// MARK: - Dynamic Island Views

/// Vista compacta del Dynamic Island (cuando está colapsado)
@available(iOS 16.1, *)
struct NavigationLiveActivityCompactView: View {
    let attributes: NavigationActivityAttributes
    let state: NavigationActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "location.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: attributes.venueColorHex))

            Text(formatDistance(state.distanceRemaining))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary)
        }
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }
}

/// Vista expandida del Dynamic Island (cuando se presiona y mantiene)
@available(iOS 16.1, *)
struct NavigationLiveActivityExpandedView: View {
    let attributes: NavigationActivityAttributes
    let state: NavigationActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 16) {
            // Top region - Destino y estado
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(attributes.destinationName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    Text(attributes.destinationCity)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Text(state.navigationState.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Center region - Información principal
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(formatDistance(state.distanceRemaining))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Restante")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                VStack(spacing: 4) {
                    Text("\(state.estimatedMinutes)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("min")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                if state.currentSpeed > 0 {
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f", state.currentSpeed))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Text("km/h")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 16)

            // Bottom region - Instrucción actual
            HStack {
                Image(systemName: "arrow.turn.up.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text(state.currentInstruction)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    if !state.currentStreet.isEmpty {
                        Text(state.currentStreet)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(hex: attributes.venueColorHex),
                    Color(hex: attributes.venueColorHex).opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }
}

#endif
*/
