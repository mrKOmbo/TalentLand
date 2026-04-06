//
//  DirectionsViewModel.swift
//  atenea
//
//  ViewModel para calcular y manejar direcciones con múltiples rutas
//

import Foundation
import MapKit
internal import Combine

@MainActor
class DirectionsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Todas las rutas calculadas por modo de transporte
    @Published var routes: [TransportMode: RouteInfo] = [:]

    /// Todas las rutas para el modo seleccionado
    @Published var allRoutes: [RouteInfo] = []

    /// Índice de la ruta seleccionada
    @Published var selectedRouteIndex: Int = 0

    /// Indica si se está calculando rutas
    @Published var isLoading: Bool = false

    /// Mensaje de error
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let origin: CLLocationCoordinate2D
    private let destination: CLLocationCoordinate2D

    init(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {
        self.origin = origin
        self.destination = destination
    }

    // MARK: - Calculate Routes

    func calculateRoutes() {
        isLoading = true
        errorMessage = nil
        routes.removeAll()

        Task {
            await withTaskGroup(of: (TransportMode, [RouteInfo])?.self) { group in
                // Driving
                group.addTask { await self.calculateMultipleRoutes(for: .driving) }

                // Walking
                group.addTask { await self.calculateMultipleRoutes(for: .walking) }

                // Transit
                group.addTask { await self.calculateMultipleRoutes(for: .transit) }

                // Cycling (estimado)
                group.addTask { await self.calculateCyclingRoute() }

                // Recolectar resultados
                for await result in group {
                    if let (mode, routeInfos) = result, let fastest = routeInfos.first {
                        self.routes[mode] = fastest

                        // Si es el modo seleccionado (driving por defecto), guardar todas las rutas
                        if mode == .driving {
                            self.allRoutes = routeInfos
                        }
                    }
                }
            }

            isLoading = false
        }
    }

    // MARK: - Calculate Multiple Routes for a Mode

    private func calculateMultipleRoutes(for mode: TransportMode) async -> (TransportMode, [RouteInfo])? {
        guard let transportType = mode.mkDirectionsType else { return nil }

        let originItem = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        let destinationItem = MKMapItem(placemark: MKPlacemark(coordinate: destination))

        let request = MKDirections.Request()
        request.source = originItem
        request.destination = destinationItem
        request.transportType = transportType
        request.requestsAlternateRoutes = true  // Pedir rutas alternativas

        let directions = MKDirections(request: request)

        do {
            let response = try await directions.calculate()

            // Convertir todas las rutas a RouteInfo
            let routes = response.routes.enumerated().map { (index, mkRoute) in
                RouteInfo(
                    mode: mode,
                    duration: mkRoute.expectedTravelTime,
                    distance: mkRoute.distance,
                    route: mkRoute,
                    isFastest: index == 0  // La primera es la más rápida
                )
            }

            print("✅ \(mode.title): \(routes.count) rutas encontradas")
            return (mode, routes)

        } catch {
            print("❌ Error calculando \(mode.title): \(error.localizedDescription)")

            // Fallback para transit
            if mode == .transit {
                return await calculateTransitFallback()
            }
        }

        return nil
    }

    // MARK: - Calculate Cycling Route (Estimado)

    private func calculateCyclingRoute() async -> (TransportMode, [RouteInfo])? {
        let originItem = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        let destinationItem = MKMapItem(placemark: MKPlacemark(coordinate: destination))

        let request = MKDirections.Request()
        request.source = originItem
        request.destination = destinationItem
        request.transportType = .walking

        let directions = MKDirections(request: request)

        do {
            let response = try await directions.calculate()
            if let route = response.routes.first {
                // Estimación: cycling es ~40% del tiempo de caminar
                let cyclingDuration = route.expectedTravelTime * 0.4
                let routeInfo = RouteInfo(
                    mode: .cycling,
                    duration: cyclingDuration,
                    distance: route.distance,
                    route: route,
                    isFastest: true
                )
                return (.cycling, [routeInfo])
            }
        } catch {
            print("❌ Error calculating cycling route: \(error.localizedDescription)")
        }

        return nil
    }

    // MARK: - Transit Fallback

    private func calculateTransitFallback() async -> (TransportMode, [RouteInfo])? {
        let originItem = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        let destinationItem = MKMapItem(placemark: MKPlacemark(coordinate: destination))

        let request = MKDirections.Request()
        request.source = originItem
        request.destination = destinationItem
        request.transportType = .automobile

        let directions = MKDirections(request: request)

        do {
            let response = try await directions.calculate()
            if let route = response.routes.first {
                // Estimación: transit es ~1.5x el tiempo de auto
                let transitDuration = route.expectedTravelTime * 1.5
                let routeInfo = RouteInfo(
                    mode: .transit,
                    duration: transitDuration,
                    distance: route.distance,
                    route: route,
                    isFastest: true
                )
                return (.transit, [routeInfo])
            }
        } catch {
            print("❌ Error in transit fallback: \(error.localizedDescription)")
        }

        return nil
    }

    // MARK: - Select Route

    func selectRoute(at index: Int) {
        guard index >= 0 && index < allRoutes.count else { return }
        selectedRouteIndex = index
    }

    // MARK: - Get Current Route

    var currentRoute: RouteInfo? {
        guard selectedRouteIndex < allRoutes.count else { return nil }
        return allRoutes[selectedRouteIndex]
    }

    // MARK: - Get Polylines

    func getAllPolylines() -> [MKPolyline] {
        return allRoutes.compactMap { $0.route?.polyline }
    }
}

// MARK: - MKPolyline Extension

extension MKPolyline {
    func coordinates() -> [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

// MARK: - CLLocationCoordinate2D Extensions

extension CLLocationCoordinate2D {
    func distance(to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }

    func interpolate(to: CLLocationCoordinate2D, fraction: Double) -> CLLocationCoordinate2D {
        let lat = self.latitude + (to.latitude - self.latitude) * fraction
        let lon = self.longitude + (to.longitude - self.longitude) * fraction
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    func bearing(to: CLLocationCoordinate2D) -> Double {
        let lat1 = self.latitude * .pi / 180
        let lon1 = self.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x)

        return (bearing * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }
}
