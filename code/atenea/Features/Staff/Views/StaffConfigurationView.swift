//
//  StaffConfigurationView.swift
//  atenea
//
//  Vista de configuración para el staff
//

import SwiftUI

struct StaffConfigurationView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var isPresented: Bool

    @State private var notificationsEnabled = true
    @State private var emergencyAlertsEnabled = true
    @State private var analyticsEnabled = true
    @State private var autoBackupEnabled = false
    @State private var maintenanceMode = false

    var body: some View {
        ZStack {
            // Fondo
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.15, green: 0.08, blue: 0.0)]),
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
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text(LocalizedString("staff.config.back"))
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Text(LocalizedString("staff.config.title"))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    // Espaciador para centrar el título
                    Color.clear
                        .frame(width: 80, height: 28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)

                // Contenido
                ScrollView {
                    VStack(spacing: 24) {
                        // Icono principal
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 20)

                        // Sección de Notificaciones
                        ConfigSection(title: LocalizedString("staff.config.notifications")) {
                            VStack(spacing: 0) {
                                ConfigToggleRow(
                                    title: LocalizedString("staff.config.pushNotifications"),
                                    description: LocalizedString("staff.config.pushDesc"),
                                    icon: "bell.fill",
                                    color: .blue,
                                    isOn: $notificationsEnabled
                                )

                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 16)

                                ConfigToggleRow(
                                    title: LocalizedString("staff.config.emergencyAlerts"),
                                    description: LocalizedString("staff.config.emergencyAlertsDesc"),
                                    icon: "exclamationmark.triangle.fill",
                                    color: .red,
                                    isOn: $emergencyAlertsEnabled
                                )
                            }
                        }

                        // Sección de Sistema
                        ConfigSection(title: LocalizedString("staff.config.system")) {
                            VStack(spacing: 0) {
                                ConfigToggleRow(
                                    title: LocalizedString("staff.config.analytics"),
                                    description: LocalizedString("staff.config.analyticsDesc"),
                                    icon: "chart.bar.fill",
                                    color: .green,
                                    isOn: $analyticsEnabled
                                )

                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 16)

                                ConfigToggleRow(
                                    title: LocalizedString("staff.config.autoBackup"),
                                    description: LocalizedString("staff.config.autoBackupDesc"),
                                    icon: "cloud.fill",
                                    color: .cyan,
                                    isOn: $autoBackupEnabled
                                )

                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 16)

                                ConfigToggleRow(
                                    title: LocalizedString("staff.config.maintenanceMode"),
                                    description: LocalizedString("staff.config.maintenanceModeDesc"),
                                    icon: "wrench.fill",
                                    color: .orange,
                                    isOn: $maintenanceMode
                                )
                            }
                        }

                        // Sección de Acciones
                        ConfigSection(title: LocalizedString("staff.config.actions")) {
                            VStack(spacing: 12) {
                                ConfigActionButton(
                                    title: LocalizedString("staff.config.clearCache"),
                                    icon: "trash.fill",
                                    color: .yellow
                                ) {
                                    // Acción para limpiar caché
                                }

                                ConfigActionButton(
                                    title: LocalizedString("staff.config.exportData"),
                                    icon: "square.and.arrow.up.fill",
                                    color: .blue
                                ) {
                                    // Acción para exportar datos
                                }

                                ConfigActionButton(
                                    title: LocalizedString("staff.config.restartServices"),
                                    icon: "arrow.clockwise.circle.fill",
                                    color: .purple
                                ) {
                                    // Acción para reiniciar servicios
                                }

                                ConfigActionButton(
                                    title: LocalizedString("staff.config.viewSystemLogs"),
                                    icon: "doc.text.fill",
                                    color: .cyan
                                ) {
                                    // Acción para ver logs
                                }
                            }
                        }

                        // Información de versión
                        VStack(spacing: 8) {
                            Text(LocalizedString("staff.config.staffPanel"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))

                            Text(LocalizedString("staff.config.version"))
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}

// MARK: - Config Section Component
struct ConfigSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 20)

            content
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Config Toggle Row Component
struct ConfigToggleRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(16)
    }
}

// MARK: - Config Action Button Component
struct ConfigActionButton: View {
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
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StaffConfigurationView(isPresented: .constant(true))
        .environmentObject(LanguageManager.shared)
}
