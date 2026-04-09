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
                                title: LocalizedString("accessibility.visualMode"),
                                description: LocalizedString("accessibility.visualModeDesc")
                            )
                        }

                        // Modo de Alto Contraste
                        SettingsSection(title: LocalizedString("accessibility.display")) {
                            ToggleSetting(
                                icon: "circle.lefthalf.filled",
                                title: LocalizedString("accessibility.highContrast"),
                                description: LocalizedString("accessibility.highContrastDesc"),
                                isOn: $accessibilityManager.visualSettings.highContrastMode,
                                action: {
                                    accessibilityManager.toggleHighContrast()
                                }
                            )
                        }

                        // Tamaño de Texto
                        SettingsSection(title: LocalizedString("accessibility.textSize")) {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "textformat.size")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                        .frame(width: 30)

                                    Text(LocalizedString("accessibility.textSize"))
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
                                                    LocalizedString("accessibility.textSizeAdjusted")
                                                )
                                            }
                                        }
                                        .accessibilityLabel(LocalizedString("accessibility.textSizeControl"))
                                        .accessibilityValue("\(Int(accessibilityManager.visualSettings.textSizeMultiplier * 100))%")

                                        Text("A")
                                            .font(.system(size: 24))
                                    }

                                    // Preview
                                    Text(LocalizedString("accessibility.textSizePreview"))
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
                        SettingsSection(title: LocalizedString("accessibility.audioAndVoice")) {
                            VStack(spacing: 12) {
                                ToggleSetting(
                                    icon: "speaker.wave.3",
                                    title: LocalizedString("accessibility.voiceOver"),
                                    description: LocalizedString("accessibility.voiceOverDesc"),
                                    isOn: $accessibilityManager.visualSettings.voiceOverEnabled,
                                    action: {
                                        accessibilityManager.visualSettings.voiceOverEnabled.toggle()
                                        accessibilityManager.saveSettings()
                                        accessibilityManager.announce(
                                            accessibilityManager.visualSettings.voiceOverEnabled ? LocalizedString("accessibility.voiceOverEnabled") : LocalizedString("accessibility.voiceOverDisabled")
                                        )
                                    }
                                )

                                ToggleSetting(
                                    icon: "location.north.fill",
                                    title: LocalizedString("accessibility.audioNavigation"),
                                    description: LocalizedString("accessibility.audioNavigationDesc"),
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

                                            Text(LocalizedString("accessibility.detailLevel"))
                                                .dynamicFont(size: 16, weight: .medium)
                                        }

                                        Picker(LocalizedString("accessibility.verbosity"), selection: $accessibilityManager.visualSettings.screenReaderVerbosity) {
                                            ForEach(VisualAccessibilitySettings.ScreenReaderVerbosity.allCases, id: \.self) { verbosity in
                                                Text(verbosity.displayName).tag(verbosity)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        .onChange(of: accessibilityManager.visualSettings.screenReaderVerbosity) { _, newValue in
                                            accessibilityManager.saveSettings()
                                            accessibilityManager.announce(String(format: LocalizedString("accessibility.detailLevelChanged"), newValue.displayName))
                                        }
                                    }
                                }
                            }
                        }

                        // Feedback Háptico
                        SettingsSection(title: LocalizedString("accessibility.tactileFeedback")) {
                            ToggleSetting(
                                icon: "hand.tap",
                                title: LocalizedString("accessibility.hapticFeedback"),
                                description: LocalizedString("accessibility.hapticFeedbackDesc"),
                                isOn: $accessibilityManager.visualSettings.hapticFeedbackEnabled,
                                action: {
                                    accessibilityManager.toggleHapticFeedback()
                                }
                            )
                        }

                        // Daltonismo
                        SettingsSection(title: LocalizedString("accessibility.colorBlindness")) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "paintpalette")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                        .frame(width: 30)

                                    Text(LocalizedString("accessibility.colorMode"))
                                        .dynamicFont(size: 16, weight: .medium)
                                }

                                Picker(LocalizedString("accessibility.colorMode"), selection: $accessibilityManager.visualSettings.colorBlindMode) {
                                    ForEach(VisualAccessibilitySettings.ColorBlindMode.allCases, id: \.self) { mode in
                                        Text(mode.displayName).tag(mode)
                                    }
                                }
                                .pickerStyle(.menu)
                                .onChange(of: accessibilityManager.visualSettings.colorBlindMode) { _, newValue in
                                    accessibilityManager.saveSettings()
                                    accessibilityManager.announce(String(format: LocalizedString("accessibility.colorModeChanged"), newValue.displayName))
                                }
                            }
                            .padding(.vertical, 8)
                        }

                        // Test de Audio
                        SettingsSection(title: LocalizedString("accessibility.tests")) {
                            Button(action: {
                                accessibilityManager.announce(
                                    LocalizedString("accessibility.testMessage"),
                                    priority: .required
                                )
                                accessibilityManager.provideHapticFeedback(.success)
                            }) {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)

                                    Text(LocalizedString("accessibility.testAudioVibration"))
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
                                label: LocalizedString("accessibility.testLabel"),
                                hint: LocalizedString("accessibility.testHint")
                            )
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle(LocalizedString("accessibility.visualTitle"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("accessibility.done")) {
                        dismiss()
                    }
                    .accessibleButton(
                        label: LocalizedString("accessibility.closeConfig"),
                        announcement: LocalizedString("accessibility.configSaved")
                    )
                }
            }
            .onAppear {
                if userManager.currentUser?.hasVisualDisability == true {
                    accessibilityManager.announce(LocalizedString("accessibility.visualConfig"))
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
            .accessibilityValue(isOn ? LocalizedString("accessibility.enabled") : LocalizedString("accessibility.disabled"))
            .accessibilityHint(description)
        }
    }
}

// MARK: - Preview

#Preview {
    VisualAccessibilitySettingsView()
}
