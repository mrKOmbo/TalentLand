//
//  TripStartedView.swift
//  atenea
//
//  Vista animada que aparece cuando el usuario inicia un viaje
//

import SwiftUI
import MapKit

struct TripStartedView: View {
    @Binding var isPresented: Bool
    let destination: String
    let destinationCoordinate: CLLocationCoordinate2D
    let route: RouteInfo
    let onEndTrip: () -> Void
    let onStartNavigation: () -> Void

    @State private var showContent: Bool = false
    @State private var pulseAnimation: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fondo oscuro sólido que cubre TODO incluyendo tab bar
                Color.black
                    .ignoresSafeArea(.all)

                // Gradiente sutil para profundidad
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color(hex: "00D084").opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(.all)
                .overlay(
                    // Efecto de pulso sutil
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "00D084").opacity(0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 400
                            )
                        )
                        .scaleEffect(pulseAnimation ? CGFloat(1.5) : CGFloat(1.0))
                        .opacity(pulseAnimation ? 0 : 0.3)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false), value: pulseAnimation)
                )

                VStack(spacing: 0) {
                    // Header con botón cerrar
                    HStack {
                        Spacer()

                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                onEndTrip()
                                isPresented = false
                            }
                        }) {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                    Spacer()

                    // Contenido principal
                    VStack(spacing: 32) {
                        // Icono animado grande
                        ZStack {
                            // Anillo exterior
                            Circle()
                                .stroke(Color(hex: "00D084").opacity(0.2), lineWidth: 4)
                                .frame(width: 160, height: 160)

                            // Anillo medio pulsante
                            Circle()
                                .stroke(Color(hex: "00D084").opacity(0.4), lineWidth: 3)
                                .frame(width: 140, height: 140)
                                .scaleEffect(pulseAnimation ? CGFloat(1.1) : CGFloat(1.0))
                                .opacity(pulseAnimation ? 0.5 : 1.0)

                            // Círculo interior con gradiente
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "C8FF00"), Color(hex: "00D084")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .shadow(color: Color(hex: "00D084").opacity(0.5), radius: 20, x: 0, y: 10)

                            // Icono de navegación
                            Image(systemName: route.mode.rawValue)
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .scaleEffect(showContent ? CGFloat(1.0) : CGFloat(0.5))
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: showContent)

                        // Título
                        VStack(spacing: 12) {
                            Text("Trip Started!")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(showContent ? CGFloat(1.0) : CGFloat(0.8))
                                .opacity(showContent ? 1.0 : 0.0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: showContent)

                            Text("Navigating to")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .opacity(showContent ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.4).delay(0.4), value: showContent)

                            Text(destination)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(Color(hex: "C8FF00"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .opacity(showContent ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.4).delay(0.5), value: showContent)
                        }

                        // Información del viaje
                        HStack(spacing: 40) {
                            TripInfoCard(
                                icon: "clock.fill",
                                title: "ETA",
                                value: route.durationText,
                                color: Color(hex: "00D084")
                            )

                            TripInfoCard(
                                icon: "location.fill",
                                title: "Distance",
                                value: route.distanceText,
                                color: Color(hex: "C8FF00")
                            )
                        }
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.5).delay(0.6), value: showContent)
                    }

                    Spacer()

                    // Botones de acción
                    VStack(spacing: 16) {
                        // Botón de iniciar navegación
                        Button(action: {
                            // Iniciar navegación
                            onStartNavigation()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 20, weight: .semibold))

                                Text("Start Navigation")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "C8FF00"), Color(hex: "00D084")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }

                        // Botón de cancelar viaje
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                onEndTrip()
                                isPresented = false
                            }
                        }) {
                            Text("End Trip")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20) + 20)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 50)
                    .animation(.easeOut(duration: 0.5).delay(0.7), value: showContent)
                }
            }
        }
        .onAppear {
            withAnimation {
                showContent = true
                pulseAnimation = true
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

// MARK: - Trip Info Card

struct TripInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 140, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
