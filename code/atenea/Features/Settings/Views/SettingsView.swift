//
//  SettingsView.swift
//  atenea
//
//  Coppel Brand Toolkit 2024 — Clean settings view
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var languageManager: LanguageManager
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("autoNavigation") private var autoNavigation = false
    @State private var showResetAlert = false

    init(languageManager: LanguageManager = LanguageManager.shared) {
        self.languageManager = languageManager
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Settings")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color.coppelDarkBlue)

                            Text("Personalize your experience")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.gray.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Notifications
                    settingSection(title: "Notifications", icon: "bell.fill") {
                        toggleItem(
                            icon: "bell.badge.fill",
                            title: "Push notifications",
                            subtitle: "Stay updated with alerts",
                            isOn: $notificationsEnabled
                        )

                        toggleItem(
                            icon: "speaker.wave.2.fill",
                            title: "Sounds",
                            subtitle: "App sound effects",
                            isOn: $soundEnabled
                        )

                        toggleItem(
                            icon: "waveform.circle.fill",
                            title: "Haptics",
                            subtitle: "Vibration feedback",
                            isOn: $hapticEnabled
                        )
                    }

                    // Navigation
                    settingSection(title: "Navigation", icon: "location.fill") {
                        toggleItem(
                            icon: "arrow.triangle.turn.up.right.circle.fill",
                            title: "Auto-navigate",
                            subtitle: "Start routes automatically",
                            isOn: $autoNavigation
                        )
                    }

                    // Language
                    settingSection(title: "Language", icon: "globe.fill") {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.99, green: 0.73, blue: 0.18).opacity(0.1))
                                    .frame(width: 40, height: 40)

                                Image(systemName: "globe.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(red: 0.99, green: 0.73, blue: 0.18))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Current language")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)

                                Text(LanguageManager.availableLanguages[languageManager.currentLanguage] ?? "English")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.coppelDarkBlue)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.gray.opacity(0.4))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemBackground))
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                    }

                    // About
                    settingSection(title: "About", icon: "info.circle.fill") {
                        VStack(spacing: 12) {
                            infoItem(label: "Version", value: "1.0.0")
                            infoItem(label: "Built", value: "Genius Arena 2026")
                        }
                    }

                    // Danger Zone
                    VStack(spacing: 12) {
                        Button(action: { showResetAlert = true }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 1, green: 0.35, blue: 0.3).opacity(0.1))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: "arrow.counterclockwise.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color.coppelRed)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Reset settings")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color.coppelRed)

                                    Text("Restore defaults")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.systemBackground))
                                    .stroke(Color.coppelRed.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Footer
                    Text("Made with care in Mexico")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.vertical, 20)

                    Spacer(minLength: 40)
                }
            }
        }
        .alert("Reset settings?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetSettings()
            }
        } message: {
            Text("All settings will be restored to defaults.")
        }
    }

    private func settingSection<Content: View>(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.11, green: 0.26, blue: 0.91).opacity(0.1))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.coppelBlue)
                }

                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color.coppelDarkBlue)

                Spacer()
            }

            VStack(spacing: 10) {
                content()
            }
        }
        .padding(.horizontal, 20)
    }

    private func toggleItem(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.11, green: 0.26, blue: 0.91).opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.coppelBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.coppelDarkBlue)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.coppelBlue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    private func infoItem(label: String, value: String) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)

                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.coppelDarkBlue)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    private func resetSettings() {
        notificationsEnabled = true
        soundEnabled = true
        hapticEnabled = true
        autoNavigation = false
    }
}

#Preview {
    SettingsView()
}
