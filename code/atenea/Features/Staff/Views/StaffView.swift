//
//  StaffView.swift
//  atenea
//
//  Vista especial para personal del staff
//

import SwiftUI
import CoreLocation

struct StaffView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var isPresented: Bool
    var onNavigateToEmergency: ((CLLocationCoordinate2D, String, Bool) -> Void)?

    @State private var showEmergencies = false
    @State private var showStatistics = false
    @State private var showUsers = false
    @State private var showConfiguration = false

    // NearbyInteraction Manager para recibir emergencias
    @StateObject private var niManager = NearbyInteractionManager(role: .staff)

    var body: some View {
        ZStack {
            // Fondo
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.05, blue: 0.0)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Text("Staff")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    // Espaciador para centrar el título
                    Color.clear
                        .frame(width: 28, height: 28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)

                // Contenido
                ScrollView {
                    VStack(spacing: 20) {
                        // Icono principal
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 120, height: 120)

                            Image(systemName: "person.badge.key.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 40)

                        Text("Staff Access")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Text("Vista especial para el personal")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Spacer()
                            .frame(height: 40)

                        // Botones de acceso rápido
                        VStack(spacing: 16) {
                            StaffActionButton(
                                title: "Emergencys",
                                icon: "exclamationmark.triangle.fill",
                                color: .red
                            ) {
                                showEmergencies = true
                            }

                            StaffActionButton(
                                title: "Estadísticas",
                                icon: "chart.line.uptrend.xyaxis",
                                color: .green
                            ) {
                                showStatistics = true
                            }

                            StaffActionButton(
                                title: "Gestión de Usuarios",
                                icon: "person.3.fill",
                                color: .purple
                            ) {
                                showUsers = true
                            }

                            StaffActionButton(
                                title: "Configuración",
                                icon: "gearshape.fill",
                                color: .orange
                            ) {
                                showConfiguration = true
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer()
                            .frame(height: 60)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showEmergencies) {
            StaffEmergenciesView(
                isPresented: $showEmergencies,
                niManager: niManager,
                onNavigateToEmergency: { coordinate, name, startNavigation in
                    // Cerrar StaffView también
                    isPresented = false
                    // Pasar la navegación al mapa
                    onNavigateToEmergency?(coordinate, name, startNavigation)
                }
            )
            .environmentObject(languageManager)
        }
        .fullScreenCover(isPresented: $showStatistics) {
            StaffStatisticsView(isPresented: $showStatistics)
                .environmentObject(languageManager)
        }
        .fullScreenCover(isPresented: $showUsers) {
            StaffUsersView(isPresented: $showUsers)
                .environmentObject(languageManager)
        }
        .fullScreenCover(isPresented: $showConfiguration) {
            StaffConfigurationView(isPresented: $showConfiguration)
                .environmentObject(languageManager)
        }
        .onAppear {
            // Iniciar el NI manager cuando el staff abre su vista
            // Esto hace que el dispositivo empiece a "advertise" y estar listo para recibir emergencias
            niManager.start()
            print("👮 Staff NI Manager iniciado - Esperando emergencias...")
        }
        .onDisappear {
            // Detener el NI manager cuando se cierra la vista
            niManager.stop()
            print("👮 Staff NI Manager detenido")
        }
    }
}

// MARK: - Staff Action Button
struct StaffActionButton: View {
    let title: String
    let icon: String
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
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StaffView(isPresented: .constant(true))
        .environmentObject(LanguageManager.shared)
}
