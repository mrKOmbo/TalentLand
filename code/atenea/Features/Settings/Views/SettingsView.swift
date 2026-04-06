//
//  SettingsView.swift
//  atenea
//
//  Ultra-modern settings view with glassmorphism design
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var languageManager: LanguageManager
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("autoNavigation") private var autoNavigation = false
    @State private var showResetAlert = false

    init(languageManager: LanguageManager = LanguageManager.shared) {
        self.languageManager = languageManager
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.98, green: 0.95, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Configuración")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.pink]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("Personaliza tu experiencia")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: {
                            dismiss()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 40, height: 40)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)

                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Notificaciones
                    settingSection(
                        title: "Notificaciones",
                        icon: "bell.fill",
                        gradient: [Color.blue, Color.cyan]
                    ) {
                        VStack(spacing: 12) {
                            toggleRow(
                                icon: "bell.badge.fill",
                                title: "Notificaciones Push",
                                subtitle: "Recibe alertas importantes",
                                isOn: $notificationsEnabled,
                                gradient: [Color.blue, Color.cyan]
                            )

                            toggleRow(
                                icon: "speaker.wave.3.fill",
                                title: "Sonidos",
                                subtitle: "Efectos de sonido en la app",
                                isOn: $soundEnabled,
                                gradient: [Color.purple, Color.pink]
                            )

                            toggleRow(
                                icon: "waveform",
                                title: "Hápticos",
                                subtitle: "Vibraciones al tocar",
                                isOn: $hapticEnabled,
                                gradient: [Color.orange, Color.yellow]
                            )
                        }
                    }

                    // Apariencia
                    settingSection(
                        title: "Apariencia",
                        icon: "paintbrush.fill",
                        gradient: [Color.purple, Color.pink]
                    ) {
                        VStack(spacing: 12) {
                            toggleRow(
                                icon: "moon.fill",
                                title: "Modo Oscuro",
                                subtitle: "Tema oscuro automático",
                                isOn: $darkModeEnabled,
                                gradient: [Color.indigo, Color.purple]
                            )

                            // Language Selector
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.orange.opacity(0.15), Color.yellow.opacity(0.1)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 50, height: 50)

                                    Image(systemName: "globe")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Idioma")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)

                                    Text(LanguageManager.availableLanguages[languageManager.currentLanguage] ?? "Español")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                            )
                        }
                    }

                    // Navegación
                    settingSection(
                        title: "Navegación",
                        icon: "location.fill",
                        gradient: [Color.green, Color.mint]
                    ) {
                        toggleRow(
                            icon: "arrow.triangle.turn.up.right.circle.fill",
                            title: "Navegación Automática",
                            subtitle: "Inicia rutas automáticamente",
                            isOn: $autoNavigation,
                            gradient: [Color.green, Color.mint]
                        )
                    }

                    // Privacidad
                    settingSection(
                        title: "Privacidad",
                        icon: "lock.fill",
                        gradient: [Color.red, Color.pink]
                    ) {
                        VStack(spacing: 12) {
                            actionRow(
                                icon: "hand.raised.fill",
                                title: "Política de Privacidad",
                                subtitle: "Lee nuestra política",
                                gradient: [Color.blue, Color.cyan]
                            ) {
                                // Action
                            }

                            actionRow(
                                icon: "doc.text.fill",
                                title: "Términos y Condiciones",
                                subtitle: "Lee los términos de uso",
                                gradient: [Color.purple, Color.pink]
                            ) {
                                // Action
                            }
                        }
                    }

                    // Peligro
                    VStack(spacing: 16) {
                        Button(action: {
                            showResetAlert = true
                        }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.12))
                                        .frame(width: 50, height: 50)

                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.red)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Restablecer Configuración")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.red)

                                    Text("Volver a valores predeterminados")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.gray)
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.red.opacity(0.1), radius: 12, x: 0, y: 4)
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Version Info
                    VStack(spacing: 8) {
                        Text("Atenea v1.0.0")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        Text("Made with ❤️ in Mexico")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .padding(.vertical, 20)

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Restablecer Configuración", isPresented: $showResetAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Restablecer", role: .destructive) {
                resetSettings()
            }
        } message: {
            Text("¿Estás seguro de que quieres restablecer todas las configuraciones a sus valores predeterminados?")
        }
    }

    // MARK: - Components

    private func settingSection<Content: View>(
        title: String,
        icon: String,
        gradient: [Color],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: gradient.map { $0.opacity(0.15) }),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: gradient),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()
            }

            content()
        }
        .padding(.horizontal, 20)
    }

    private func toggleRow(
        icon: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        gradient: [Color]
    ) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradient.map { $0.opacity(0.15) }),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: gradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(
                    Color(
                        gradient.first ?? .blue
                    )
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    private func actionRow(
        icon: String,
        title: String,
        subtitle: String,
        gradient: [Color],
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: gradient.map { $0.opacity(0.15) }),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: gradient),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }

    private func resetSettings() {
        notificationsEnabled = true
        darkModeEnabled = false
        soundEnabled = true
        hapticEnabled = true
        autoNavigation = false
    }
}

#Preview {
    SettingsView()
}
