//
//  NavigationDynamicIsland.swift
//  atenea
//
//  Vista tipo Dynamic Island para mostrar información de navegación en tiempo real
//

import SwiftUI
import MapboxNavigationCore
internal import MapboxDirections
import CoreLocation
internal import Combine

// MARK: - Navigation Dynamic Island

struct NavigationDynamicIsland: View {
    let instruction: String
    let maneuverType: ManeuverType?
    let distance: CLLocationDistance
    let eta: Date?
    let totalDistance: CLLocationDistance

    @State private var isExpanded: Bool = false
    @State private var showContent: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            }) {
                if isExpanded {
                    expandedView
                } else {
                    compactView
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showContent = true
            }
        }
    }

    // MARK: - Compact View (Collapsed) - Estilo Google Maps

    private var compactView: some View {
        HStack(spacing: 8) {
            // Icono de maniobra compacto
            Image(systemName: maneuverIcon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color.blue)
                )

            // Distancia solo (más compacto)
            Text(distanceText)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            // ETA si existe
            if let eta = eta {
                Text("•")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))

                Text(etaText(from: eta))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }

            // Indicador de expansión
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(height: 36)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 2)
        .opacity(showContent ? 1.0 : 0.0)
        .scaleEffect(showContent ? CGFloat(1.0) : CGFloat(0.8))
    }

    // MARK: - Expanded View - Estilo Google Maps

    private var expandedView: some View {
        VStack(spacing: 12) {
            // Header con instrucción principal
            HStack(spacing: 10) {
                // Icono de maniobra
                Image(systemName: maneuverIcon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.blue)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(String(format: LocalizedString("navigation.inDistance"), distanceText))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.cyan)
                        .textCase(.uppercase)

                    Text(instruction)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                }

                Spacer()

                // Indicador de colapso
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }

            Divider()
                .background(Color.white.opacity(0.15))

            // Información adicional compacta
            HStack(spacing: 16) {
                // ETA
                if let eta = eta {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.green)

                        Text(etaText(from: eta))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Distancia total restante
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)

                    Text(totalDistanceText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: 300)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 4)
    }

    // MARK: - Helper Properties

    private var maneuverIcon: String {
        guard let maneuver = maneuverType else {
            return "arrow.up"
        }

        switch maneuver {
        case .turn:
            return "arrow.turn.up.right"
        case .arrive:
            return "mappin.circle.fill"
        case .depart:
            return "arrow.up.circle.fill"
        case .merge:
            return "arrow.merge"
        case .takeOnRamp:
            return "arrow.up.right"
        case .takeOffRamp:
            return "arrow.turn.down.right"
        case .reachFork:
            return "arrow.triangle.branch"
        case .takeRoundabout, .takeRotary:
            return "arrow.triangle.turn.up.right.diamond.fill"
        case .exitRoundabout, .exitRotary:
            return "arrow.uturn.right"
        case .continue:
            return "arrow.up"
        default:
            return "arrow.up"
        }
    }

    private var distanceText: String {
        if distance < 1000 {
            return "\(Int(distance)) m"
        } else {
            let km = distance / 1000.0
            return String(format: "%.1f km", km)
        }
    }

    private var totalDistanceText: String {
        if totalDistance < 1000 {
            return "\(Int(totalDistance)) m"
        } else {
            let km = totalDistance / 1000.0
            return String(format: "%.1f km", km)
        }
    }

    private func etaText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Navigation Info Card

struct NavigationInfoCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)

                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Dynamic Island Hosting View

struct NavigationDynamicIslandHostingView: View {
    @ObservedObject var navigationState: NavigationStateObserver

    var body: some View {
        VStack {
            if let currentInstruction = navigationState.currentInstruction,
               let distance = navigationState.distanceToNextManeuver {
                NavigationDynamicIsland(
                    instruction: currentInstruction,
                    maneuverType: navigationState.maneuverType,
                    distance: distance,
                    eta: navigationState.eta,
                    totalDistance: navigationState.remainingDistance ?? 0
                )
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()
        }
    }
}

// MARK: - Navigation State Observer

class NavigationStateObserver: ObservableObject {
    @Published var currentInstruction: String?
    @Published var maneuverType: ManeuverType?
    @Published var distanceToNextManeuver: CLLocationDistance?
    @Published var remainingDistance: CLLocationDistance?
    @Published var eta: Date?

    func update(with progress: RouteProgress) {
        DispatchQueue.main.async {
            // Obtener la instrucción actual
            let currentStep = progress.currentLegProgress.currentStepProgress.step
            let instruction = currentStep.instructions
            self.currentInstruction = instruction

            // Obtener tipo de maniobra
            let maneuverType = progress.currentLegProgress.currentStepProgress.step.maneuverType
            self.maneuverType = maneuverType

            // Distancia a la próxima maniobra
            self.distanceToNextManeuver = progress.currentLegProgress.currentStepProgress.distanceRemaining

            // Distancia total restante
            self.remainingDistance = progress.distanceRemaining

            // ETA (tiempo estimado de llegada)
            if progress.durationRemaining > 0 {
                self.eta = Date().addingTimeInterval(progress.durationRemaining)
            }
        }
    }
}
