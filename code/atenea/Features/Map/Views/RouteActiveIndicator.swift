//
//  RouteActiveIndicator.swift
//  atenea
//
//  Indicador flotante que muestra al comerciante que está en modo "En Ruta"
//  con progreso, waypoint actual y botón para terminar.
//

import SwiftUI

struct RouteActiveIndicator: View {
    @ObservedObject var routeTracker = RouteTrackingManager.shared
    @ObservedObject var merchantManager = MerchantManager.shared

    private var merchantEmoji: String {
        merchantManager.currentMerchantProfile?.emoji ?? "🛒"
    }

    private var currentWaypointName: String {
        guard let route = routeTracker.activeRoute else { return "" }
        let waypoints = route.sortedWaypoints
        let idx = min(routeTracker.currentWaypointIndex + 1, waypoints.count - 1)
        return waypoints[idx].name ?? "Waypoint \(idx + 1)"
    }

    private var progressPercent: Int {
        Int(routeTracker.routeProgress * 100)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            HStack(spacing: 12) {
                // Emoji animado del comerciante
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 42, height: 42)

                    Text(merchantEmoji)
                        .font(.system(size: 20))
                        .modifier(BouncingModifier())
                }

                // Info de ruta
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)

                        Text(LocalizedString("route.onRoute"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("· \(progressPercent)%")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    // Barra de progreso
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.orange.opacity(0.15))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .yellow],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * routeTracker.routeProgress, height: 6)
                                .animation(.easeInOut(duration: 0.5), value: routeTracker.routeProgress)
                        }
                    }
                    .frame(height: 6)

                    // Siguiente parada
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)

                        Text(currentWaypointName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Botón terminar ruta
                Button(action: {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                    routeTracker.endRoute()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .red.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThickMaterial)

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.06),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.3),
                                    Color.white.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
                .shadow(color: Color.orange.opacity(0.12), radius: 12, x: 0, y: 6)
                .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 120)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Bouncing Animation Modifier

private struct BouncingModifier: ViewModifier {
    @State private var isBouncing = false

    func body(content: Content) -> some View {
        content
            .offset(y: isBouncing ? -3 : 0)
            .animation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true),
                value: isBouncing
            )
            .onAppear { isBouncing = true }
    }
}
