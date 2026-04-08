//
//  LiveTrackManager.swift
//  atenea
//
//  "LiveTrack" — Uber al revés
//  Cuando un merchant responde "Ya voy" a un timbre,
//  el cliente ve la distancia decreciente en tiempo real
//

import Foundation
import CoreLocation
internal import Combine

class LiveTrackManager: ObservableObject {
    static let shared = LiveTrackManager()

    // Estado del tracking activo
    @Published var isTracking = false
    @Published var currentDistance: Double = 0 // metros
    @Published var initialDistance: Double = 0
    @Published var estimatedMinutes: Int = 0
    @Published var merchantEmoji: String = ""
    @Published var merchantName: String = ""
    @Published var merchantCategory: String = ""
    @Published var hasArrived = false
    @Published var trackingTimbre: TimbreEvent?

    private var simulationTimer: Timer?
    private var startTime: Date?

    private init() {}

    // MARK: - Iniciar Tracking

    func startTracking(timbre: TimbreEvent, merchant: Merchant) {
        // Calcular distancia real entre cliente y merchant
        let merchantLocation = merchant.currentLocation
        let clientCoord = CLLocation(latitude: timbre.clientLatitude, longitude: timbre.clientLongitude)
        let merchantCoord: CLLocation

        if let loc = merchantLocation {
            merchantCoord = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
        } else {
            // Simular distancia si no hay ubicación real
            merchantCoord = CLLocation(
                latitude: timbre.clientLatitude + 0.004,
                longitude: timbre.clientLongitude + 0.002
            )
        }

        let distance = clientCoord.distance(from: merchantCoord)
        let cappedDistance = max(min(distance, 2000), 200) // Entre 200m y 2km

        // Estimar tiempo de llegada (velocidad promedio peatón: 5 km/h = 83 m/min)
        let walkingSpeedMPerMin = 83.0
        let eta = Int(ceil(cappedDistance / walkingSpeedMPerMin))

        // Configurar estado
        initialDistance = cappedDistance
        currentDistance = cappedDistance
        estimatedMinutes = eta
        merchantEmoji = merchant.emoji
        merchantName = merchant.businessName
        merchantCategory = merchant.category.displayName
        hasArrived = false
        isTracking = true
        trackingTimbre = timbre
        startTime = Date()

        // Iniciar simulación de acercamiento
        startSimulation(totalDistance: cappedDistance, totalMinutes: eta)
    }

    // MARK: - Simulación (para demo)

    private func startSimulation(totalDistance: Double, totalMinutes: Int) {
        simulationTimer?.invalidate()

        // Actualizar cada 2 segundos, simular acercamiento acelerado para demo (30s total)
        let totalSteps = 15
        let stepInterval = 2.0
        var currentStep = 0

        simulationTimer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }

            currentStep += 1

            // Distancia con curva de desaceleración (llega más lento al final)
            let progress = Double(currentStep) / Double(totalSteps)
            let easedProgress = 1.0 - pow(1.0 - progress, 2) // ease-out quadratic
            let newDistance = totalDistance * (1.0 - easedProgress)

            DispatchQueue.main.async {
                self.currentDistance = max(newDistance, 0)
                self.estimatedMinutes = max(Int(ceil(newDistance / 83.0)), 0)

                // Llegó
                if currentStep >= totalSteps || newDistance < 20 {
                    self.currentDistance = 0
                    self.estimatedMinutes = 0
                    self.hasArrived = true
                    timer.invalidate()

                    // Auto-dismiss después de 5 segundos
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.stopTracking()
                    }
                }
            }
        }
    }

    // MARK: - Parar Tracking

    func stopTracking() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        isTracking = false
        hasArrived = false
        currentDistance = 0
        trackingTimbre = nil
    }

    // MARK: - Computed

    var progress: Double {
        guard initialDistance > 0 else { return 0 }
        return 1.0 - (currentDistance / initialDistance)
    }

    var distanceText: String {
        if currentDistance < 1 {
            return "Aquí"
        } else if currentDistance < 1000 {
            return "\(Int(currentDistance))m"
        } else {
            return String(format: "%.1f km", currentDistance / 1000)
        }
    }

    var etaText: String {
        if estimatedMinutes <= 0 {
            return "Llegó"
        } else if estimatedMinutes == 1 {
            return "1 min"
        } else {
            return "\(estimatedMinutes) min"
        }
    }
}
