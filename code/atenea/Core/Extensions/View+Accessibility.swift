//
//  View+Accessibility.swift
//  atenea
//
//  Extensiones de SwiftUI para funcionalidades de accesibilidad
//

import SwiftUI

// MARK: - View Extensions for Accessibility

extension View {

    // MARK: - Visual Accessibility

    /// Aplica configuraciones de accesibilidad visual
    func accessibleText(baseSize: CGFloat = 16) -> some View {
        let manager = AccessibilitySettingsManager.shared
        return self.font(.system(size: manager.adaptedFontSize(baseSize)))
    }

    /// Aplica color adaptado según configuraciones de accesibilidad
    func accessibleForeground(_ color: Color) -> some View {
        let manager = AccessibilitySettingsManager.shared
        return self.foregroundColor(manager.adaptedColor(color))
    }

    /// Aplica feedback háptico al interactuar
    func withHapticFeedback(_ type: AccessibilitySettingsManager.HapticType = .selection) -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    AccessibilitySettingsManager.shared.provideHapticFeedback(type)
                }
        )
    }

    /// Anuncia cambios importantes para usuarios con VoiceOver
    func announceAccessibility(_ message: String, on trigger: some Equatable) -> some View {
        self.onChange(of: trigger) { _, _ in
            AccessibilitySettingsManager.shared.announce(message)
        }
    }

    /// Botón accesible con feedback háptico y VoiceOver
    func accessibleButton(
        label: String,
        hint: String? = nil,
        announcement: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        AccessibilitySettingsManager.shared.provideHapticFeedback(.selection)
                        if let announcement = announcement {
                            AccessibilitySettingsManager.shared.announce(announcement)
                        }
                    }
            )
    }

    /// Elemento accesible con descripción detallada
    func accessibleElement(
        label: String,
        value: String? = nil,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }

    /// Modo de alto contraste condicional
    func highContrastStyle(
        normalColor: Color,
        highContrastColor: Color
    ) -> some View {
        let manager = AccessibilitySettingsManager.shared
        let color = manager.visualSettings.highContrastMode ? highContrastColor : normalColor
        return self.foregroundColor(color)
    }

    /// Aplicar fondo con contraste adecuado
    func accessibleBackground(_ color: Color) -> some View {
        let manager = AccessibilitySettingsManager.shared
        let adaptedColor = manager.visualSettings.highContrastMode
            ? color.opacity(1.0)
            : color
        return self.background(adaptedColor)
    }
}

// MARK: - Button Accessibility

struct AccessibleButtonStyle: ButtonStyle {
    let hapticType: AccessibilitySettingsManager.HapticType
    let announcement: String?

    init(
        hapticType: AccessibilitySettingsManager.HapticType = .selection,
        announcement: String? = nil
    ) {
        self.hapticType = hapticType
        self.announcement = announcement
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(x: configuration.isPressed ? 0.95 : 1.0, y: configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    AccessibilitySettingsManager.shared.provideHapticFeedback(hapticType)
                    if let announcement = announcement {
                        AccessibilitySettingsManager.shared.announce(announcement)
                    }
                }
            }
    }
}

// MARK: - Navigation Announcement

struct NavigationAnnouncementModifier: ViewModifier {
    let destination: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                let manager = AccessibilitySettingsManager.shared
                if UserManager.shared.currentUser?.hasVisualDisability == true {
                    manager.announce("Navegando a \(destination)")
                }
            }
    }
}

extension View {
    /// Anuncia navegación para usuarios con discapacidad visual
    func announceNavigation(to destination: String) -> some View {
        self.modifier(NavigationAnnouncementModifier(destination: destination))
    }
}

// MARK: - Dynamic Font Scaling

struct DynamicFontModifier: ViewModifier {
    let baseSize: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    init(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) {
        self.baseSize = size
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        let manager = AccessibilitySettingsManager.shared
        let adaptedSize = manager.adaptedFontSize(baseSize)

        return content
            .font(.system(size: adaptedSize, weight: weight, design: design))
    }
}

extension View {
    /// Aplica tamaño de fuente dinámico basado en configuraciones de accesibilidad
    func dynamicFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> some View {
        self.modifier(DynamicFontModifier(size: size, weight: weight, design: design))
    }
}

// MARK: - Image Accessibility

extension Image {
    /// Imagen con descripción accesible
    func accessibleImage(
        label: String,
        decorative: Bool = false
    ) -> some View {
        if decorative {
            return self
                .accessibilityHidden(true)
                .eraseToAnyView()
        } else {
            return self
                .accessibilityLabel(label)
                .eraseToAnyView()
        }
    }
}

// MARK: - Helper Extensions

private extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
