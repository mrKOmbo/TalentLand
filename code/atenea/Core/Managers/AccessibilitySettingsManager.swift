//
//  AccessibilitySettingsManager.swift
//  atenea
//
//  Manager para configuraciones de accesibilidad
//

import Foundation
import SwiftUI
internal import Combine
import AVFoundation

// MARK: - Accessibility Settings

/// Configuraciones de accesibilidad para usuarios con discapacidad visual
struct VisualAccessibilitySettings {
    var highContrastMode: Bool = false
    var textSizeMultiplier: CGFloat = 1.0  // 1.0 = normal, 1.5 = grande, 2.0 = extra grande
    var voiceOverEnabled: Bool = false
    var audioNavigationEnabled: Bool = true
    var hapticFeedbackEnabled: Bool = true
    var screenReaderVerbosity: ScreenReaderVerbosity = .detailed
    var colorBlindMode: ColorBlindMode = .none

    enum ScreenReaderVerbosity: String, Codable, CaseIterable {
        case brief = "brief"
        case normal = "normal"
        case detailed = "detailed"

        var displayName: String {
            switch self {
            case .brief: return "Breve"
            case .normal: return "Normal"
            case .detailed: return "Detallado"
            }
        }
    }

    enum ColorBlindMode: String, Codable, CaseIterable {
        case none = "none"
        case protanopia = "protanopia"          // Dificultad con rojo
        case deuteranopia = "deuteranopia"      // Dificultad con verde
        case tritanopia = "tritanopia"          // Dificultad con azul
        case achromatopsia = "achromatopsia"    // Sin percepción de color

        var displayName: String {
            switch self {
            case .none: return "Ninguno"
            case .protanopia: return "Protanopía (Rojo)"
            case .deuteranopia: return "Deuteranopía (Verde)"
            case .tritanopia: return "Tritanopía (Azul)"
            case .achromatopsia: return "Acromatopsia (Sin color)"
            }
        }
    }
}

// MARK: - Accessibility Settings Manager

class AccessibilitySettingsManager: ObservableObject {
    static let shared = AccessibilitySettingsManager()

    // MARK: - Published Properties

    @Published var visualSettings = VisualAccessibilitySettings()

    // Text-to-Speech
    private let synthesizer = AVSpeechSynthesizer()
    private var isSpeaking = false

    // User Manager reference
    private var userManager = UserManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    private init() {
        loadSettings()
        observeUserChanges()
    }

    // MARK: - Settings Persistence

    private func loadSettings() {
        // Cargar configuraciones guardadas desde UserDefaults
        if let data = UserDefaults.standard.data(forKey: "visualAccessibilitySettings"),
           let decoded = try? JSONDecoder().decode(VisualAccessibilitySettings.self, from: data) {
            visualSettings = decoded
        }
    }

    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(visualSettings) {
            UserDefaults.standard.set(encoded, forKey: "visualAccessibilitySettings")
        }
    }

    // MARK: - User Observation

    private func observeUserChanges() {
        userManager.$currentUser
            .sink { [weak self] user in
                self?.updateSettingsForUser(user)
            }
            .store(in: &cancellables)
    }

    private func updateSettingsForUser(_ user: User?) {
        guard let user = user else { return }

        // Aplicar configuraciones predeterminadas según el tipo de discapacidad
        if user.hasVisualDisability {
            enableVisualAccessibilityDefaults()
        }
    }

    private func enableVisualAccessibilityDefaults() {
        visualSettings.audioNavigationEnabled = true
        visualSettings.hapticFeedbackEnabled = true
        visualSettings.voiceOverEnabled = true
        visualSettings.textSizeMultiplier = 1.3
        saveSettings()
    }

    // MARK: - Visual Accessibility Features

    /// Alternar modo de alto contraste
    func toggleHighContrast() {
        visualSettings.highContrastMode.toggle()
        saveSettings()
        announceChange("Modo de alto contraste \(visualSettings.highContrastMode ? "activado" : "desactivado")")
    }

    /// Ajustar tamaño de texto
    func setTextSize(_ multiplier: CGFloat) {
        visualSettings.textSizeMultiplier = max(0.8, min(2.5, multiplier))
        saveSettings()

        let sizeDescription: String
        switch multiplier {
        case ..<1.0: sizeDescription = "pequeño"
        case 1.0..<1.3: sizeDescription = "normal"
        case 1.3..<1.7: sizeDescription = "grande"
        default: sizeDescription = "extra grande"
        }
        announceChange("Tamaño de texto ajustado a \(sizeDescription)")
    }

    /// Alternar navegación por audio
    func toggleAudioNavigation() {
        visualSettings.audioNavigationEnabled.toggle()
        saveSettings()
        announceChange("Navegación por audio \(visualSettings.audioNavigationEnabled ? "activada" : "desactivada")")
    }

    /// Alternar feedback háptico
    func toggleHapticFeedback() {
        visualSettings.hapticFeedbackEnabled.toggle()
        saveSettings()
        provideHapticFeedback(.success)
    }

    // MARK: - Text-to-Speech

    /// Anunciar texto con Text-to-Speech
    func announce(_ text: String, priority: AVSpeechUtterance.SpeechPriority = .default) {
        guard visualSettings.voiceOverEnabled else { return }

        // Detener anuncio actual si es de menor prioridad
        if isSpeaking && priority == .required {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-MX") // Español México

        // Ajustar velocidad según verbosidad
        switch visualSettings.screenReaderVerbosity {
        case .brief:
            utterance.rate = 0.6
        case .normal:
            utterance.rate = 0.5
        case .detailed:
            utterance.rate = 0.45
        }

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    /// Anunciar cambio en configuración
    private func announceChange(_ message: String) {
        announce(message, priority: .required)
    }

    /// Detener todos los anuncios
    func stopAnnouncing() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    // MARK: - Haptic Feedback

    enum HapticType {
        case success
        case warning
        case error
        case selection
        case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    }

    /// Proporcionar feedback háptico
    func provideHapticFeedback(_ type: HapticType) {
        guard visualSettings.hapticFeedbackEnabled else { return }

        switch type {
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)

        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)

        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()

        case .impact(let style):
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }

    // MARK: - Color Helpers

    /// Obtener color adaptado según configuraciones de accesibilidad
    func adaptedColor(_ baseColor: Color) -> Color {
        if visualSettings.highContrastMode {
            // Aumentar contraste
            return baseColor.opacity(1.0)
        }

        // Aplicar filtros de daltonismo si es necesario
        switch visualSettings.colorBlindMode {
        case .none:
            return baseColor
        case .protanopia, .deuteranopia, .tritanopia, .achromatopsia:
            // Aquí se pueden aplicar filtros específicos
            // Por ahora retornamos el color base
            return baseColor
        }
    }

    /// Obtener tamaño de fuente adaptado
    func adaptedFontSize(_ baseSize: CGFloat) -> CGFloat {
        return baseSize * visualSettings.textSizeMultiplier
    }
}

// MARK: - Codable Conformance

extension VisualAccessibilitySettings: Codable {}

// MARK: - AVSpeechUtterance Extension

extension AVSpeechUtterance {
    enum SpeechPriority {
        case `default`
        case required
    }
}
