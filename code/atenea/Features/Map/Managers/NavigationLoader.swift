import MapboxNavigationCore
import CoreLocation

class NavigationLoader {
    // Singleton instance
    static let shared = NavigationLoader()

    // Single MapboxNavigationProvider instance - CRITICAL: Only create once!
    private let navigationProvider: MapboxNavigationProvider

    // Private initializer to enforce singleton pattern
    private init() {
        // Use live location source by default
        let locationSource: LocationSource = .live
        // For simulation, use: .simulation(initialLocation: .init(CLLocation(latitude: 0, longitude: 0)))

        // Create the provider ONCE in the initializer
        self.navigationProvider = MapboxNavigationProvider(coreConfig: .init(locationSource: locationSource))
        print("✅ NavigationLoader singleton initialized with MapboxNavigationProvider")
    }

    func loadNavigation(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> PreparedNavigation {
        // Reuse the existing provider instead of creating a new one
        let result = await navigationProvider.mapboxNavigation
            .routingProvider()
            .calculateRoutes(options: NavigationRouteOptions(coordinates: [origin, destination]))
            .result

        return switch result {
        case .failure(let error):
            throw error
        case .success(let routes):
            // Return the routes with the singleton provider
            PreparedNavigation(routes: routes, navigationProvider: navigationProvider)
        }
    }
}
