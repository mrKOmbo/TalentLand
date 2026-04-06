//
//  INTEGRATION_EXAMPLE.swift
//  Atenea
//
//  Ejemplo de cómo integrar Live Activities en tu código existente
//
//  ⚠️ ESTE ARCHIVO ES SOLO DE REFERENCIA - ESTÁ COMPLETAMENTE COMENTADO
//  Para usarlo, descomentar cuando tengas un Widget Extension configurado
//

import SwiftUI

/*
import MapboxNavigationCore
import CoreLocation

// MARK: - Ejemplo 1: Integración Básica en MainMapView

/*
 Agrega esto a tu MainMapView.swift donde manejas la navegación
*/

extension MainMapView {

    // PASO 1: Cuando inicias la navegación
    func startNavigationToVenue(_ venue: WorldCupVenue, route: Route) {
        // Tu código existente de navegación Mapbox
        // ...

        // ✅ AGREGAR: Iniciar Live Activity
        let totalDistanceKm = route.distance / 1000
        LiveActivityHelper.shared.startNavigationLiveActivity(
            to: venue,
            totalDistance: totalDistanceKm
        )

        print("🟢 [NAVIGATION] Live Activity iniciado para \(venue.name)")
    }

    // PASO 2: Actualizar durante la navegación
    // Agrega esto en tu NavigationService delegate
    func handleNavigationUpdate(
        progress: RouteProgress,
        location: CLLocation
    ) {
        // Extraer datos de Mapbox
        let distanceRemaining = progress.distanceRemaining  // metros
        let timeRemaining = Int(progress.durationRemaining / 60)  // minutos

        // Obtener instrucción actual
        let instruction = progress.currentLegProgress
            .currentStepProgress
            .currentSpokenInstruction?
            .text ?? "Continúa recto"

        // Nombre de calle actual
        let streetName = progress.currentLegProgress.currentStep.name ?? ""

        // Velocidad actual (convertir m/s a km/h)
        let speedKmh = (location.speed > 0) ? location.speed * 3.6 : 0

        // ✅ AGREGAR: Actualizar Live Activity
        LiveActivityHelper.shared.updateNavigationLiveActivity(
            distanceRemaining: distanceRemaining,
            estimatedMinutes: timeRemaining,
            instruction: instruction,
            currentStreet: streetName,
            currentSpeed: speedKmh
        )

        print("🔄 [LIVE ACTIVITY] Actualizado: \(Int(distanceRemaining))m, \(timeRemaining)min")
    }

    // PASO 3: Finalizar cuando llegas
    func handleArrival() {
        // Tu código de llegada (confetti, etc)
        // ...

        // ✅ AGREGAR: Finalizar Live Activity
        LiveActivityHelper.shared.endNavigationLiveActivity()

        print("✅ [NAVIGATION] Has llegado! Live Activity finalizado")
    }

    // PASO 4: Cancelar si usuario cancela
    func cancelNavigation() {
        // Detener Mapbox navigation
        // ...

        // ✅ AGREGAR: Cancelar Live Activity
        LiveActivityHelper.shared.cancelNavigationLiveActivity()

        print("🚫 [NAVIGATION] Cancelado por usuario")
    }
}

// MARK: - Ejemplo 2: Integración con NavigationViewWrapper

/*
 Si usas NavigationViewWrapper, agrega estos métodos
*/

extension NavigationViewWrapper {

    // Cuando Mapbox NavigationController inicia
    func navigationDidStart(route: Route, destination: WorldCupVenue) {
        let totalDistanceKm = route.distance / 1000

        // Iniciar Live Activity
        LiveActivityHelper.shared.startNavigationLiveActivity(
            to: destination,
            totalDistance: totalDistanceKm
        )
    }

    // En el delegate de MapboxNavigation
    func mapView(_ mapView: NavigationMapView,
                 didUpdate progress: RouteProgress,
                 with location: CLLocation,
                 rawLocation: CLLocation) {

        // Actualizar cada 5 segundos para no saturar
        // (puedes agregar un timer o contador)

        let distanceRemaining = progress.distanceRemaining
        let timeRemaining = Int(progress.durationRemaining / 60)
        let instruction = getCurrentInstruction(from: progress)
        let street = progress.currentLegProgress.currentStep.name ?? ""
        let speed = location.speed * 3.6  // m/s a km/h

        LiveActivityHelper.shared.updateNavigationLiveActivity(
            distanceRemaining: distanceRemaining,
            estimatedMinutes: timeRemaining,
            instruction: instruction,
            currentStreet: street,
            currentSpeed: speed
        )
    }

    // Helper para obtener instrucción
    private func getCurrentInstruction(from progress: RouteProgress) -> String {
        if let spokenInstruction = progress.currentLegProgress
            .currentStepProgress
            .currentSpokenInstruction {
            return spokenInstruction.text
        }

        // Fallback a instrucciones básicas
        let step = progress.currentLegProgress.currentStep
        if let primaryText = step.instructionsDisplayedAlongStep?.primaryInstruction.text {
            return primaryText
        }

        return "Continúa por esta vía"
    }

    // Cuando llegas
    func didArrive(at waypoint: Waypoint) {
        LiveActivityHelper.shared.endNavigationLiveActivity()

        // Mostrar celebración
        showArrivalCelebration()
    }

    // Si falla la navegación
    func navigationDidFail(with error: Error) {
        // Cancelar Live Activity si hay error
        LiveActivityHelper.shared.cancelNavigationLiveActivity()

        // Mostrar error al usuario
        showErrorAlert(error)
    }
}

// MARK: - Ejemplo 3: Con Throttling (Recomendado)

/*
 Para evitar actualizar el Live Activity demasiado frecuentemente
*/

class NavigationLiveActivityThrottler {
    private var lastUpdate: Date = .distantPast
    private let updateInterval: TimeInterval = 3.0  // 3 segundos

    func shouldUpdate() -> Bool {
        let now = Date()
        if now.timeIntervalSince(lastUpdate) >= updateInterval {
            lastUpdate = now
            return true
        }
        return false
    }
}

// Uso:
extension MainMapView {
    private let liveActivityThrottler = NavigationLiveActivityThrottler()

    func updateNavigationProgress(_ progress: RouteProgress, location: CLLocation) {
        // Tu código existente...

        // Solo actualizar Live Activity cada 3 segundos
        guard liveActivityThrottler.shouldUpdate() else { return }

        LiveActivityHelper.shared.updateNavigationLiveActivity(
            distanceRemaining: progress.distanceRemaining,
            estimatedMinutes: Int(progress.durationRemaining / 60),
            instruction: getCurrentInstruction(from: progress),
            currentStreet: progress.currentLegProgress.currentStep.name ?? "",
            currentSpeed: location.speed * 3.6
        )
    }
}

// MARK: - Ejemplo 4: Con Manejo de Errores

extension MainMapView {

    func startNavigationWithLiveActivity(to venue: WorldCupVenue, route: Route) {
        // Verificar si Live Activities están disponibles
        guard LiveActivityHelper.shared.isLiveActivityAvailable else {
            print("⚠️ Live Activities no disponibles en este dispositivo")
            // Continuar con navegación normal sin Live Activity
            startRegularNavigation(route: route)
            return
        }

        // Iniciar navegación
        startRegularNavigation(route: route)

        // Iniciar Live Activity
        do {
            LiveActivityHelper.shared.startNavigationLiveActivity(
                to: venue,
                totalDistance: route.distance / 1000
            )
            print("✅ Live Activity iniciado exitosamente")
        } catch {
            print("❌ Error iniciando Live Activity: \(error)")
            // La navegación continúa normalmente sin Live Activity
        }
    }
}

// MARK: - Ejemplo 5: Testing/Debugging

extension MainMapView {

    // Función de prueba para Live Activity
    func testLiveActivity() {
        // Obtener un venue de prueba
        guard let azteca = WorldCupVenue.allVenues.first(where: { $0.name == "Estadio Azteca" }) else {
            return
        }

        // Iniciar con datos de prueba
        LiveActivityHelper.shared.startNavigationLiveActivity(
            to: azteca,
            totalDistance: 15.5  // 15.5 km
        )

        // Simular updates cada 2 segundos
        var testDistance: Double = 15500  // metros
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            testDistance -= 200  // Reduce 200m cada update

            if testDistance <= 0 {
                LiveActivityHelper.shared.endNavigationLiveActivity()
                timer.invalidate()
                return
            }

            LiveActivityHelper.shared.updateNavigationLiveActivity(
                distanceRemaining: testDistance,
                estimatedMinutes: Int(testDistance / 250),  // ~250m/min promedio
                instruction: testDistance < 1000 ? "Llegarás pronto" : "Continúa recto",
                currentStreet: "Av. Insurgentes Sur",
                currentSpeed: 45.0
            )
        }
    }
}

// MARK: - Ubicación en tu código

/*
 DÓNDE AGREGAR CADA PIEZA:

 1. MainMapView.swift:
    - Importar: import ActivityKit (condicional iOS 16.1+)
    - En startNavigation(): LiveActivityHelper.shared.startNavigationLiveActivity()
    - En cancelNavigation(): LiveActivityHelper.shared.cancelNavigationLiveActivity()

 2. NavigationViewWrapper.swift:
    - En MapboxNavigationService delegate
    - Método didUpdate progress: LiveActivityHelper.shared.updateNavigationLiveActivity()
    - Método didArrive: LiveActivityHelper.shared.endNavigationLiveActivity()

 3. DirectionsView.swift (opcional):
    - Mostrar badge si Live Activities está disponible
    - Indicar al usuario que verá updates en Dynamic Island

 IMPORTANTE:
 - No olvides el throttling (cada 3-5 segundos)
 - Siempre cancelar/finalizar el Live Activity cuando terminas
 - Verifica disponibilidad con LiveActivityHelper.shared.isLiveActivityAvailable
*/
*/
