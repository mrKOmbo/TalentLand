//
//  EmergencyModal.swift
//  atenea
//
//  Modal de emergencia para contactos de emergencia
//

import SwiftUI
import CoreLocation

struct EmergencyModal: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var languageManager: LanguageManager
    let userLocation: CLLocationCoordinate2D?
    var onEmergencyActivated: (() -> Void)? = nil

    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            // Fondo oscuro
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isPresented = false
                    }
                }

            // Contenido del modal
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    // Icono de emergencia pulsante
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.red)
                    }

                    Text(LocalizedString("emergency.title"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 32)
                .padding(.bottom, 24)

                // Opciones de emergencia
                VStack(spacing: 16) {
                    // Llamar 911
                    EmergencyButton(
                        icon: "phone.fill",
                        title: LocalizedString("emergency.call911"),
                        color: .orange,
                        action: {
                            callEmergency(number: "911")
                        }
                    )

                    // Policía - Activa modo emergencia
                    EmergencyButton(
                        icon: "shield.fill",
                        title: LocalizedString("emergency.callPolice"),
                        color: .red,
                        action: {
                            // Activar modo de emergencia
                            onEmergencyActivated?()
                            callEmergency(number: "911")
                        }
                    )

                    // Compartir ubicación
                    if userLocation != nil {
                        EmergencyButton(
                            icon: "location.fill",
                            title: LocalizedString("emergency.shareLocation"),
                            color: .blue,
                            action: {
                                shareLocation()
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                // Botón de cancelar
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isPresented = false
                    }
                }) {
                    Text(LocalizedString("action.cancel"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: 400)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#1a1a1a"),
                                Color(hex: "#0f0f0f")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 10)
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Actions

    private func callEmergency(number: String) {
        if let url = URL(string: "tel://\(number)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        isPresented = false
    }

    private func shareLocation() {
        guard let location = userLocation else { return }

        let locationText = """
        🚨 \(LocalizedString("emergency.locationShare"))
        Latitude: \(location.latitude)
        Longitude: \(location.longitude)

        Google Maps: https://maps.google.com/?q=\(location.latitude),\(location.longitude)
        Apple Maps: http://maps.apple.com/?ll=\(location.latitude),\(location.longitude)
        """

        let activityVC = UIActivityViewController(
            activityItems: [locationText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }

        isPresented = false
    }
}

// MARK: - Emergency Button

struct EmergencyButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
