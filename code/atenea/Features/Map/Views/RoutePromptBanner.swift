//
//  RoutePromptBanner.swift
//  atenea
//
//  Banner que aparece cuando el comerciante está cerca de su ruta.
//  Ofrece iniciar el modo "En Ruta" para trackear su posición visualmente.
//

import SwiftUI

struct RoutePromptBanner: View {
    @ObservedObject var routeTracker = RouteTrackingManager.shared
    @ObservedObject var merchantManager = MerchantManager.shared

    @State private var opacity: Double = 0
    @State private var dragOffset: CGFloat = 0

    private let minimumDragDistance: CGFloat = 50

    private var merchantName: String {
        merchantManager.currentMerchantProfile?.businessName ?? "Comerciante"
    }

    private var merchantEmoji: String {
        merchantManager.currentMerchantProfile?.emoji ?? "🛒"
    }

    private var waypointCount: Int {
        routeTracker.activeRoute?.waypoints.count ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Banner principal
            VStack(spacing: 12) {
                // Header con icono y texto
                HStack(spacing: 12) {
                    // Icono del comerciante con pulso
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .scaleEffect(CGFloat(routeTracker.isNearRoute ? 1.15 : 1.0))
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: routeTracker.isNearRoute)

                        Text(merchantEmoji)
                            .font(.system(size: 24))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(LocalizedString("route.nearRoute"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(String(format: LocalizedString("route.startPrompt"), waypointCount))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                // Botones
                HStack(spacing: 10) {
                    // Descartar
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        dismissBanner()
                        routeTracker.dismissPrompt()
                    }) {
                        Text(LocalizedString("route.notNow"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                    }

                    // Iniciar ruta
                    Button(action: {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        routeTracker.startRoute()
                        dismissBanner()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill.viewfinder")
                                .font(.system(size: 14, weight: .semibold))
                            Text(LocalizedString("route.startRoute"))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                }
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThickMaterial)

                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.08),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.3),
                                    Color.white.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
                .shadow(color: Color.orange.opacity(0.15), radius: 16, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
            )
            .padding(.horizontal, 16)
            .offset(y: dragOffset)
            .opacity(opacity)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.height < 0 {
                            dragOffset = gesture.translation.height
                        }
                    }
                    .onEnded { gesture in
                        if gesture.translation.height < -minimumDragDistance {
                            dismissBanner()
                            routeTracker.dismissPrompt()
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dragOffset = 0
                            }
                        }
                    }
            )

            Spacer()
        }
        .padding(.top, 60)
        .onAppear {
            if routeTracker.isNearRoute && !routeTracker.isOnRoute && !routeTracker.promptDismissed {
                showBanner()
            }
        }
        .onChange(of: routeTracker.isNearRoute) { _, isNear in
            if isNear && !routeTracker.isOnRoute && !routeTracker.promptDismissed {
                showBanner()
            } else if !isNear {
                hideBanner()
            }
        }
    }

    private func showBanner() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            opacity = 1.0
        }
    }

    private func hideBanner() {
        withAnimation(.easeInOut(duration: 0.3)) {
            opacity = 0
            dragOffset = 0
        }
    }

    private func dismissBanner() {
        withAnimation(.easeInOut(duration: 0.3)) {
            opacity = 0
            dragOffset = 0
        }
    }
}
