//
//  VisualAccessibilitySettingsView.swift
//  atenea
//
//  Vista de configuración de accesibilidad visual
//

import SwiftUI

struct VisualAccessibilitySettingsView: View {
    @StateObject private var accessibilityManager = AccessibilitySettingsManager.shared
    @StateObject private var userManager = UserManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Fondo
                (accessibilityManager.visualSettings.highContrastMode
                    ? Color.black
                    : Color(UIColor.systemGroupedBackground))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header Info
                        if userManager.currentUser?.hasVisualDisability == true {
                            InfoCard(
                                icon: "eye.slash.fill",
                                title: "Modo de Accesibilidad Visual",
                                description: "Configuraciones optimizadas para usuarios con discapacidad visual"
                            )
                        }

                        // Modo de Alto Contraste
                        SettingsSection(title: "Visualización") {
                            ToggleSetting(
                                icon: "circle.lefthalf.filled",
                                title: "Modo de Alto Contraste",
                                description: "Aumenta el contraste para mejor visibilidad",
                                isOn: $accessibilityManager.visualSettings.highContrastMode,
                                action: {
                                    accessibilityManager.toggleHighContrast()
                                }
                            )
                        }

                        // Tamaño de Texto
                        SettingsSection(title: "Tamaño de Texto") {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "textformat.size")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                        .frame(width: 30)

                                    Text("Tamaño de Texto")
                                        .dynamicFont(size: 16, weight: .medium)
                                }

                                // Slider para tamaño de texto
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("A")
                                            .font(.system(size: 12))
                                        Slider(
                                            value: $accessibilityManager.visualSettings.textSizeMultiplier,
                                            in: 0.8...2.5,
                                            step: 0.1
                                        ) { editing in
                                            if !editing {
                                                accessibilityManager.saveSettings()
                                                accessibilityManager.announce(
                                                    "Tamaño de texto ajustado"
                                                )
                                            }
                                        }
                                        .accessibilityLabel("Control de tamaño de texto")
                                        .accessibilityValue("\(Int(accessibilityManager.visualSettings.textSizeMultiplier * 100))%")

                                        Text("A")
                                            .font(.system(size: 24))
                                    }

                                    // Preview
                                    Text("Vista previa del tamaño de texto")
                                        .dynamicFont(size: 16)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.1))
                                        )
                                }
                            }
                            .padding(.vertical, 8)
                        }

                        // Audio y Voz
                        SettingsSection(title: "Audio y Voz") {
                            VStack(spacing: 12) {
                                ToggleSetting(
                                    icon: "speaker.wave.3",
                                    title: "VoiceOver",
                                    description: "Lectura de pantalla con voz",
                                    isOn: $accessibilityManager.visualSettings.voiceOverEnabled,
                                    action: {
                                        accessibilityManager.visualSettings.voiceOverEnabled.toggle()
                                        accessibilityManager.saveSettings()
                                        accessibilityManager.announce(
                                            "VoiceOver \(accessibilityManager.visualSettings.voiceOverEnabled ? "activado" : "desactivado")"
                                        )
                                    }
                                )

                                ToggleSetting(
                                    icon: "location.north.fill",
                                    title: "Navegación por Audio",
                                    description: "Instrucciones de navegación habladas",
                                    isOn: $accessibilityManager.visualSettings.audioNavigationEnabled,
                                    action: {
                                        accessibilityManager.toggleAudioNavigation()
                                    }
                                )

                                // Verbosidad del lector de pantalla
                                if accessibilityManager.visualSettings.voiceOverEnabled {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "text.bubble")
                                                .font(.system(size: 20))
                                                .foregroundColor(.blue)
                                                .frame(width: 30)

                                            Text("Nivel de Detalle")
                                                .dynamicFont(size: 16, weight: .medium)
                                        }

                                        Picker("Verbosidad", selection: $accessibilityManager.visualSettings.screenReaderVerbosity) {
                                            ForEach(VisualAccessibilitySettings.ScreenReaderVerbosity.allCases, id: \.self) { verbosity in
                                                Text(verbosity.displayName).tag(verbosity)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        .onChange(of: accessibilityManager.visualSettings.screenReaderVerbosity) { _, newValue in
                                            accessibilityManager.saveSettings()
                                            accessibilityManager.announce("Nivel de detalle: \(newValue.displayName)")
                                        }
                                    }
                                }
                            }
                        }

                        // Feedback Háptico
                        SettingsSection(title: "Feedback Táctil") {
                            ToggleSetting(
                                icon: "hand.tap",
                                title: "Feedback Háptico",
                                description: "Vibraciones al interactuar",
                                isOn: $accessibilityManager.visualSettings.hapticFeedbackEnabled,
                                action: {
                                    accessibilityManager.toggleHapticFeedback()
                                }
                            )
                        }

                        // Daltonismo
                        SettingsSection(title: "Daltonismo") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "paintpalette")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                        .frame(width: 30)

                                    Text("Modo de Color")
                                        .dynamicFont(size: 16, weight: .medium)
                                }

                                Picker("Modo de color", selection: $accessibilityManager.visualSettings.colorBlindMode) {
                                    ForEach(VisualAccessibilitySettings.ColorBlindMode.allCases, id: \.self) { mode in
                                        Text(mode.displayName).tag(mode)
                                    }
                                }
                                .pickerStyle(.menu)
                                .onChange(of: accessibilityManager.visualSettings.colorBlindMode) { _, newValue in
                                    accessibilityManager.saveSettings()
                                    accessibilityManager.announce("Modo de color: \(newValue.displayName)")
                                }
                            }
                            .padding(.vertical, 8)
                        }

                        // Test de Audio
                        SettingsSection(title: "Pruebas") {
                            Button(action: {
                                accessibilityManager.announce(
                                    "Esta es una prueba de texto a voz. Las funciones de accesibilidad están funcionando correctamente.",
                                    priority: .required
                                )
                                accessibilityManager.provideHapticFeedback(.success)
                            }) {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)

                                    Text("Probar Audio y Vibración")
                                        .dynamicFont(size: 16, weight: .medium)
                                        .foregroundColor(.primary)

                                    Spacer()
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                )
                            }
                            .accessibleButton(
                                label: "Probar audio y vibración",
                                hint: "Reproduce un mensaje de prueba y activa feedback háptico"
                            )
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Accesibilidad Visual")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                    .accessibleButton(
                        label: "Cerrar configuración",
                        announcement: "Configuración guardada"
                    )
                }
            }
            .onAppear {
                if userManager.currentUser?.hasVisualDisability == true {
                    accessibilityManager.announce("Configuración de accesibilidad visual")
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .dynamicFont(size: 16, weight: .semibold)

                Text(description)
                    .dynamicFont(size: 14)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
        .accessibleElement(
            label: title,
            value: description,
            traits: .isStaticText
        )
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .dynamicFont(size: 13, weight: .semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                content
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }
}

struct ToggleSetting: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { isOn },
                set: { newValue in
                    isOn = newValue
                    action()
                }
            )) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .dynamicFont(size: 16, weight: .medium)

                        Text(description)
                            .dynamicFont(size: 13)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .accessibilityLabel(title)
            .accessibilityValue(isOn ? "Activado" : "Desactivado")
            .accessibilityHint(description)
        }
    }
}

// MARK: - Preview

#Preview {
    VisualAccessibilitySettingsView()
}
