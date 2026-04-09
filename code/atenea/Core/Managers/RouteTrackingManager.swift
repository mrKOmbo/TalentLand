//
//  RouteTrackingManager.swift
//  atenea
//
//  Detecta si el comerciante está cerca de su ruta y trackea su posición en tiempo real.
//

import Foundation
import CoreLocation
internal import Combine

class RouteTrackingManager: ObservableObject {
    static let shared = RouteTrackingManager()

    // MARK: - Published State

    /// El comerciante está activamente recorriendo su ruta
    @Published var isOnRoute: Bool = false

    /// Se detectó que el comerciante está cerca de su ruta (para mostrar el prompt)
    @Published var isNearRoute: Bool = false

    /// Ya se mostró el prompt y el usuario lo descartó (no volver a mostrar hasta reinicio)
    @Published var promptDismissed: Bool = false

    /// Progreso del comerciante a lo largo de la ruta (0.0 a 1.0)
    @Published var routeProgress: Double = 0.0

    /// Índice del waypoint más cercano al que se dirige
    @Published var currentWaypointIndex: Int = 0

    /// Distancia al waypoint más cercano de la ruta (metros)
    @Published var distanceToRoute: Double = .infinity

    /// La ruta activa del comerciante
    @Published var activeRoute: MerchantRoute?

    /// Coordenadas de la ruta para dibujar en el mapa
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []

    // MARK: - Config

    /// Distancia máxima para considerar que el comerciante está "cerca" de su ruta (metros)
    private let nearRouteThreshold: Double = 2000

    /// Distancia para considerar que llegó a un waypoint (metros)
    private let waypointArrivalThreshold: Double = 50

    private var cancellables = Set<AnyCancellable>()
    private var locationCancellable: AnyCancellable?

    private init() {}

    // MARK: - Start / Stop

    /// Comienza a observar la ubicación para detectar cercanía a la ruta
    func startMonitoring(location: AnyPublisher<CLLocationCoordinate2D?, Never>) {
        let profile = MerchantManager.shared.currentMerchantProfile
        print("🔍 [RouteTracking] startMonitoring — perfil: \(profile?.businessName ?? "nil"), isStatic: \(profile?.isStatic.description ?? "?"), waypoints: \(profile?.route?.waypoints.count ?? 0)")
        guard let merchant = profile,
              !merchant.isStatic,
              let route = merchant.route,
              route.waypoints.count >= 2 else {
            print("⚠️ [RouteTracking] Guard falló — monitoring no iniciado")
            return
        }

        activeRoute = route
        routeCoordinates = route.sortedWaypoints.map { $0.coordinate }

        locationCancellable = location
            .compactMap { $0 }
            .sink { [weak self] coordinate in
                self?.updatePosition(coordinate)
            }

        print("📍 [RouteTracking] Monitoreo iniciado con \(route.waypoints.count) waypoints")
    }

    func stopMonitoring() {
        locationCancellable?.cancel()
        locationCancellable = nil
        reset()
        print("📍 [RouteTracking] Monitoreo detenido")
    }

    /// El comerciante acepta iniciar su ruta
    func startRoute() {
        guard activeRoute != nil else { return }
        isOnRoute = true
        isNearRoute = false
        currentWaypointIndex = 0
        routeProgress = 0.0
        print("🚀 [RouteTracking] Ruta iniciada")
        syncRouteStatus(isOnRoute: true)
    }

    /// El comerciante termina su ruta
    func endRoute() {
        isOnRoute = false
        routeProgress = 0.0
        currentWaypointIndex = 0
        print("🏁 [RouteTracking] Ruta terminada")
        syncRouteStatus(isOnRoute: false)
    }

    private func syncRouteStatus(isOnRoute: Bool) {
        guard let merchantId = MerchantManager.shared.currentMerchantProfile?.id else { return }
        Task {
            try? await SupabaseService.shared.updateMerchantRouteStatus(
                merchantId: merchantId,
                isOnRoute: isOnRoute
            )
        }
    }

    /// El comerciante descarta el prompt de "¿Iniciar ruta?"
    func dismissPrompt() {
        promptDismissed = true
        isNearRoute = false
    }

    // MARK: - Position Updates

    private func updatePosition(_ coordinate: CLLocationCoordinate2D) {
        guard let route = activeRoute else { return }
        let waypoints = route.sortedWaypoints
        print("🗺️ [RouteTracking] updatePosition — lat:\(String(format: "%.5f", coordinate.latitude)) lon:\(String(format: "%.5f", coordinate.longitude)) | isOnRoute:\(isOnRoute) | isNearRoute:\(isNearRoute)")

        // Calcular distancia al waypoint más cercano de la ruta
        let (nearestIndex, nearestDistance) = findNearestWaypoint(to: coordinate, in: waypoints)
        distanceToRoute = nearestDistance
        print("📏 [RouteTracking] Distancia al waypoint \(nearestIndex): \(Int(nearestDistance))m | threshold: \(Int(nearRouteThreshold))m")

        if isOnRoute {
            // Actualizar progreso
            updateRouteProgress(coordinate: coordinate, waypoints: waypoints)

            // Actualizar ubicación del comerciante en MerchantManager
            if let merchantId = MerchantManager.shared.currentMerchantProfile?.id {
                MerchantManager.shared.updateLocation(
                    merchantId: merchantId,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
            }
        } else if !promptDismissed {
            // Detectar si está cerca de la ruta para mostrar prompt
            let wasNear = isNearRoute
            isNearRoute = nearestDistance <= nearRouteThreshold

            if isNearRoute && !wasNear {
                print("📍 [RouteTracking] Comerciante cerca de ruta (\(Int(nearestDistance))m del waypoint \(nearestIndex))")
            }
        }
    }

    private func updateRouteProgress(coordinate: CLLocationCoordinate2D, waypoints: [RouteWaypoint]) {
        guard waypoints.count >= 2 else { return }

        // Verificar si llegó al waypoint actual
        let targetIndex = min(currentWaypointIndex + 1, waypoints.count - 1)
        let distToTarget = distance(from: coordinate, to: waypoints[targetIndex].coordinate)

        if distToTarget <= waypointArrivalThreshold && targetIndex < waypoints.count - 1 {
            currentWaypointIndex = targetIndex
            print("✅ [RouteTracking] Llegó al waypoint \(targetIndex): \(waypoints[targetIndex].name ?? "Sin nombre")")
        }

        // Calcular progreso total (0.0 a 1.0)
        let totalSegments = Double(waypoints.count - 1)
        guard totalSegments > 0 else { return }

        // Progreso base por waypoints completados
        let baseProgress = Double(currentWaypointIndex) / totalSegments

        // Progreso parcial dentro del segmento actual
        if currentWaypointIndex < waypoints.count - 1 {
            let segmentStart = waypoints[currentWaypointIndex].coordinate
            let segmentEnd = waypoints[currentWaypointIndex + 1].coordinate
            let segmentLength = distance(from: segmentStart, to: segmentEnd)

            if segmentLength > 0 {
                let distFromStart = distance(from: segmentStart, to: coordinate)
                let segmentProgress = min(distFromStart / segmentLength, 1.0)
                routeProgress = baseProgress + (segmentProgress / totalSegments)
            }
        } else {
            routeProgress = 1.0
        }

        // Si llegó al último waypoint, terminar ruta
        if currentWaypointIndex >= waypoints.count - 1 {
            let distToLast = distance(from: coordinate, to: waypoints.last!.coordinate)
            if distToLast <= waypointArrivalThreshold {
                print("🏁 [RouteTracking] Ruta completada")
                endRoute()
            }
        }
    }

    // MARK: - Helpers

    private func findNearestWaypoint(to coordinate: CLLocationCoordinate2D, in waypoints: [RouteWaypoint]) -> (index: Int, distance: Double) {
        var nearestIndex = 0
        var nearestDist = Double.infinity

        for (i, wp) in waypoints.enumerated() {
            let dist = distance(from: coordinate, to: wp.coordinate)
            if dist < nearestDist {
                nearestDist = dist
                nearestIndex = i
            }
        }

        return (nearestIndex, nearestDist)
    }

    private func distance(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let locA = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let locB = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return locA.distance(from: locB)
    }

    private func reset() {
        isOnRoute = false
        isNearRoute = false
        promptDismissed = false
        routeProgress = 0.0
        currentWaypointIndex = 0
        distanceToRoute = .infinity
        activeRoute = nil
        routeCoordinates = []
    }
}
