//
//  LocationBannerView.swift
//  atenea
//
//  Banner superior que muestra la ubicación actual del usuario
//  Aparece con fade-in y desaparece automáticamente
//

import SwiftUI

struct LocationBannerView: View {
    let locationText: String
    @Binding var isVisible: Bool

    @State private var opacity: Double = 0
    @State private var dragOffset: CGFloat = 0

    private let autoDismissDelay: TimeInterval = 3.5
    private let minimumDragDistance: CGFloat = 50

    // Separar ciudad y país/estado del texto de ubicación
    private var cityName: String {
        let components = locationText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return components.first ?? locationText
    }

    private var countryOrState: String {
        let components = locationText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return components.count > 1 ? components[1...].joined(separator: ", ") : ""
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Botón de menú (invisible, solo para espaciado)
                Spacer()
                    .frame(width: 50, height: 50)

                // Banner de ubicación
                HStack(spacing: 10) {
                    // Icono circular con gradiente
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "location.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)

                    // Texto de ubicación con ciudad y país/estado
                    VStack(alignment: .leading, spacing: 2) {
                        // Ciudad (principal)
                        Text(cityName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        // País/Estado (secundario)
                        Text(countryOrState)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.8))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(
                    ZStack {
                        // Fondo con material glass
                        Capsule()
                            .fill(.ultraThinMaterial)

                        // Gradiente sutil
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        // Borde con brillo
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                )
                .offset(y: dragOffset)
                .opacity(opacity)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            // Solo permitir arrastrar hacia arriba
                            if gesture.translation.height < 0 {
                                dragOffset = gesture.translation.height
                            }
                        }
                        .onEnded { gesture in
                            if gesture.translation.height < -minimumDragDistance {
                                // Si el usuario arrastra suficiente hacia arriba, cerrar
                                dismissBanner()
                            } else {
                                // Si no, regresar a la posición original
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )

                // Buscador colapsado (invisible, solo para espaciado)
                Spacer()
                    .frame(width: 50, height: 50)
            }
            .padding(.horizontal, 16)
            .padding(.top, 56)

            Spacer()
        }
        .onChange(of: isVisible) { oldValue, newValue in
            if newValue {
                showBanner()
            } else {
                hideBanner()
            }
        }
        .onAppear {
            if isVisible {
                showBanner()
            }
        }
    }

    // MARK: - Animation Functions

    private func showBanner() {
        // Animación de entrada: fade-in suave
        withAnimation(.easeInOut(duration: 0.5)) {
            opacity = 1.0
        }

        // Auto-dismiss después del delay
        Task {
            try? await Task.sleep(nanoseconds: UInt64(autoDismissDelay * 1_000_000_000))
            if isVisible {
                dismissBanner()
            }
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

        // Pequeño delay antes de actualizar el binding para que la animación termine
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isVisible = false
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        LocationBannerView(
            locationText: "New York, États-Unis",
            isVisible: .constant(true)
        )
    }
}
