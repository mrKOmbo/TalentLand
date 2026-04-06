//
//  AudioNavigationManager.swift
//  atenea
//
//  Manager para navegación por audio accesible
//

import Foundation
import CoreLocation
import AVFoundation
import UIKit
internal import Combine

class AudioNavigationManager: NSObject, ObservableObject {
    static let shared = AudioNavigationManager()

    // MARK: - Published Properties

    @Published var isNavigating: Bool = false
    @Published var currentInstruction: String = ""
    @Published var distanceToNextTurn: CLLocationDistance = 0
    @Published var estimatedTimeRemaining: TimeInterval = 0

    // MARK: - Private Properties

    private let synthesizer = AVSpeechSynthesizer()
    private var accessibilityManager = AccessibilitySettingsManager.shared
    private var userManager = UserManager.shared
    private var cancellables = Set<AnyCancellable>()

    // Navigation state
    private var route: [CLLocationCoordinate2D] = []
    private var currentStepIndex: Int = 0
    private var destinationName: String = ""
    private var lastAnnouncedDistance: CLLocationDistance = 0
    private var announcementTimer: Timer?

    // Distance thresholds for announcements (in meters)
    private let distanceThresholds: [CLLocationDistance] = [1000, 500, 200, 100, 50, 25]

    // MARK: - Init

    private override init() {
        super.init()
        synthesizer.delegate = self
        observeAccessibilitySettings()
    }

    // MARK: - Observation

    private func observeAccessibilitySettings() {
        accessibilityManager.$visualSettings
            .sink { [weak self] settings in
                // Ajustar comportamiento según configuraciones
                if !settings.audioNavigationEnabled && self?.isNavigating == true {
                    self?.stopNavigation()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Navigation Control

    /// Iniciar navegación con audio
    func startNavigation(
        route: [CLLocationCoordinate2D],
        destinationName: String,
        currentLocation: CLLocationCoordinate2D
    ) {
        guard userManager.currentUser?.hasVisualDisability == true else { return }
        guard accessibilityManager.visualSettings.audioNavigationEnabled else { return }

        self.route = route
        self.destinationName = destinationName
        self.currentStepIndex = 0
        self.lastAnnouncedDistance = 0
        self.isNavigating = true

        // Anuncio inicial
        let totalDistance = calculateTotalDistance()
        let distanceText = formatDistance(totalDistance)
        let initialMessage = "Iniciando navegación a \(destinationName). Distancia total: \(distanceText)"

        announceWithPriority(initialMessage, priority: .required)

        // Proporcionar feedback háptico
        accessibilityManager.provideHapticFeedback(.impact(.medium))

        // Iniciar actualizaciones periódicas
        startPeriodicAnnouncements()
    }

    /// Detener navegación
    func stopNavigation() {
        isNavigating = false
        route = []
        currentStepIndex = 0
        destinationName = ""
        lastAnnouncedDistance = 0

        announcementTimer?.invalidate()
        announcementTimer = nil

        synthesizer.stopSpeaking(at: .immediate)

        announceWithPriority("Navegación detenida", priority: .default)
    }

    /// Actualizar ubicación actual durante la navegación
    func updateLocation(_ location: CLLocationCoordinate2D) {
        guard isNavigating, !route.isEmpty else { return }

        // Calcular distancia al siguiente punto
        let nextPoint = route[min(currentStepIndex, route.count - 1)]
        let distance = location.distance(to: nextPoint)
        distanceToNextTurn = distance

        // Verificar si debemos anunciar la distancia
        checkAndAnnounceDistance(distance)

        // Verificar si llegamos al siguiente punto (dentro de 20 metros)
        if distance < 20 && currentStepIndex < route.count - 1 {
            currentStepIndex += 1
            announceNextStep()
            accessibilityManager.provideHapticFeedback(.selection)
        }

        // Verificar si llegamos al destino
        if currentStepIndex == route.count - 1 && distance < 20 {
            arriveAtDestination()
        }
    }

    // MARK: - Announcements

    private func announceNextStep() {
        guard currentStepIndex < route.count else { return }

        let currentPoint = route[currentStepIndex]
        let direction = calculateDirection(to: currentPoint)
        let distance = distanceToNextTurn

        let message = generateNavigationInstruction(direction: direction, distance: distance)
        currentInstruction = message

        announceWithPriority(message, priority: .required)
    }

    private func checkAndAnnounceDistance(_ distance: CLLocationDistance) {
        // Encontrar el threshold más cercano que sea mayor a la distancia
        for threshold in distanceThresholds {
            if distance <= threshold && lastAnnouncedDistance > threshold {
                let distanceText = formatDistance(distance)
                let message = "\(distanceText) hasta el siguiente punto"

                announceWithPriority(message, priority: .default)
                accessibilityManager.provideHapticFeedback(.impact(.light))

                lastAnnouncedDistance = distance
                break
            }
        }
    }

    private func arriveAtDestination() {
        isNavigating = false
        announcementTimer?.invalidate()

        let message = "Has llegado a tu destino: \(destinationName)"
        announceWithPriority(message, priority: .required)

        // Celebración con feedback háptico
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.accessibilityManager.provideHapticFeedback(.success)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.accessibilityManager.provideHapticFeedback(.success)
        }

        stopNavigation()
    }

    /// Anunciar con prioridad
    private func announceWithPriority(_ text: String, priority: AVSpeechUtterance.SpeechPriority) {
        accessibilityManager.announce(text, priority: priority)
    }

    // MARK: - Periodic Announcements

    private func startPeriodicAnnouncements() {
        announcementTimer?.invalidate()

        // Anunciar progreso cada 30 segundos
        announcementTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.announceProgress()
        }
    }

    private func announceProgress() {
        guard isNavigating else { return }

        let remainingDistance = calculateRemainingDistance()
        let distanceText = formatDistance(remainingDistance)

        let message = "Distancia restante: \(distanceText) hasta \(destinationName)"
        announceWithPriority(message, priority: .default)
    }

    // MARK: - Helper Methods

    private func calculateDirection(to coordinate: CLLocationCoordinate2D) -> String {
        // Por ahora retornamos dirección genérica
        // En una implementación real, calcularíamos el bearing y lo convertiríamos a dirección cardinal
        return "adelante"
    }

    private func generateNavigationInstruction(direction: String, distance: CLLocationDistance) -> String {
        let distanceText = formatDistance(distance)

        switch distance {
        case 0..<50:
            return "Muy cerca. Continúa \(direction)"
        case 50..<100:
            return "\(distanceText). Continúa \(direction)"
        case 100..<200:
            return "\(distanceText). Sigue \(direction)"
        default:
            return "\(distanceText) hasta el siguiente punto. Dirección: \(direction)"
        }
    }

    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return "\(Int(distance)) metros"
        } else {
            let km = distance / 1000.0
            return String(format: "%.1f kilómetros", km)
        }
    }

    private func calculateTotalDistance() -> CLLocationDistance {
        guard route.count > 1 else { return 0 }

        var total: CLLocationDistance = 0
        for i in 0..<(route.count - 1) {
            total += route[i].distance(to: route[i + 1])
        }
        return total
    }

    private func calculateRemainingDistance() -> CLLocationDistance {
        guard currentStepIndex < route.count - 1 else { return 0 }

        var remaining: CLLocationDistance = distanceToNextTurn
        for i in (currentStepIndex + 1)..<(route.count - 1) {
            remaining += route[i].distance(to: route[i + 1])
        }
        return remaining
    }

    // MARK: - Public Helpers

    /// Anunciar información sobre un lugar
    func announcePlaceInfo(name: String, category: String?, distance: CLLocationDistance?) {
        guard userManager.currentUser?.hasVisualDisability == true else { return }
        guard accessibilityManager.visualSettings.voiceOverEnabled else { return }

        var message = name

        if let category = category {
            message += ", \(category)"
        }

        if let distance = distance {
            let distanceText = formatDistance(distance)
            message += ". A \(distanceText) de distancia"
        }

        announceWithPriority(message, priority: .default)
    }

    /// Anunciar advertencia o alerta
    func announceAlert(_ alert: String) {
        guard userManager.currentUser?.hasVisualDisability == true else { return }

        announceWithPriority(alert, priority: .required)
        accessibilityManager.provideHapticFeedback(.warning)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension AudioNavigationManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        // Opcional: Tracking cuando empieza a hablar
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Opcional: Tracking cuando termina de hablar
    }
}
