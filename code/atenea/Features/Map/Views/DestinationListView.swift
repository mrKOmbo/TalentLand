import SwiftUI
import CoreLocation
internal import Combine
import MapboxNavigationCore
internal import MapboxDirections

// LocationManager handles the device's location updates
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    // Publishes the current location to subscribers
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var currentHeading: CLHeading?

    // Initializes the CLLocationManager and starts updating location
    // Expo Santa Fe, CDMX — ubicación de demostración para el simulador
    private static let expoSantaFe = CLLocationCoordinate2D(latitude: 19.3601, longitude: -99.2592)

    override init() {
        super.init()
        #if targetEnvironment(simulator)
        currentLocation = Self.expoSantaFe
        print("📍 [Simulator] Ubicación forzada: Expo Santa Fe CDMX")
        #endif
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 5
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        #if targetEnvironment(simulator)
        // En simulador ignoramos actualizaciones del sistema (San Francisco) y mantenemos Expo Santa Fe
        if currentLocation == nil {
            currentLocation = Self.expoSantaFe
        }
        #else
        if let location = locations.last?.coordinate,
           CLLocationCoordinate2DIsValid(location),
           !(location.latitude == 0.0 && location.longitude == 0.0) {
            currentLocation = location
        }
        #endif
    }

    // Delegate method called when heading (compass) is updated
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy >= 0 {
            currentHeading = newHeading
        }
    }

    // Delegate method called when location updates fail
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error)") // Print error if location fails
    }

    // Request location permission
    func requestLocationPermission() {
        manager.requestWhenInUseAuthorization()
    }
}

// Represents a destination point with name and coordinates
struct Destination: Identifiable {
    let id = UUID()
    let name: String
    let coordinates: CLLocationCoordinate2D
}

//
struct PreparedNavigation: Identifiable {
    let id = UUID()
    let routes: NavigationRoutes
    let navigationProvider: MapboxNavigationProvider
}

// List of predefined destination points
let destinations = [
    // Ciudad de México - Estaciones de Metro/Metrobús
    Destination(name: "Metro Zócalo (Línea 2)", coordinates: CLLocationCoordinate2D(latitude: 19.43305, longitude: -99.13269)),
    Destination(name: "Metro Insurgentes (Línea 1)", coordinates: CLLocationCoordinate2D(latitude: 19.42425, longitude: -99.16252)),
    Destination(name: "Metro Auditorio (Línea 7)", coordinates: CLLocationCoordinate2D(latitude: 19.42564, longitude: -99.19204)),
    Destination(name: "Metro Chabacano (Líneas 2, 8, 9)", coordinates: CLLocationCoordinate2D(latitude: 19.37883, longitude: -99.13562)),
    Destination(name: "Metro Pantitlán (Líneas 1, 5, 9, A)", coordinates: CLLocationCoordinate2D(latitude: 19.41521, longitude: -99.07242)),
    Destination(name: "Metrobús Reforma (Línea 7)", coordinates: CLLocationCoordinate2D(latitude: 19.42632, longitude: -99.16720)),
    Destination(name: "Terminal Central del Norte", coordinates: CLLocationCoordinate2D(latitude: 19.49055, longitude: -99.14113)),
]

// Main view that displays a list of destinations to choose from
struct DestinationListView: View {
    @State private var preparedNavigation: PreparedNavigation? = nil
    @State private var showTangaraView = false
    @StateObject private var locationManager = LocationManager() // Observes the user's current location

    var body: some View {
        NavigationStack {
            List {
                // Sección de modelo 3D
                Section(header: Text("Modelo 3D")) {
                    Button(action: {
                        showTangaraView = true
                    }) {
                        HStack {
                            Image(systemName: "cube.fill").foregroundColor(.purple)
                            Text("Ver Tren Tangara 3D")
                            Spacer()
                            Image(systemName: "arrow.right.circle").foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }

                // Sección de navegación
                Section(header: Text("Navegación")) {
                    ForEach(destinations) { destination in
                        Button(action: {
                            // Check if the current location is available and valid before proceeding
                            guard let origin = locationManager.currentLocation,
                                  CLLocationCoordinate2DIsValid(origin),
                                  !(origin.latitude == 0.0 && origin.longitude == 0.0) else {
                                print("Current location not available or invalid yet.")
                                return
                            }

                            Task {
                                let destinationCoord = destination.coordinates
                                // Use the singleton instance instead of creating a new one
                                if let result = try? await NavigationLoader.shared.loadNavigation(from: origin, to: destinationCoord) {
                                    preparedNavigation = result
                                    let distance = result.routes.mainRoute.route.distance
                                    print("✅ Navigation to \(destination.name) ready: route distance: \(distance) meters.")
                                }
                            }

                        }) {
                            // Layout for each destination button
                            HStack {
                                Image(systemName: "location.fill").foregroundColor(.blue)
                                Text(destination.name)
                                Spacer()
                                Image(systemName: "arrow.turn.up.right").foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("Choose Destination") // Title for the navigation stack
            // Present the navigation view full screen when OD pair is set
            .fullScreenCover(item: $preparedNavigation) { preparedNavigation in
                NavigationViewWrapper(
                    preparedNavigation: preparedNavigation,
                    onCancel: {
                        self.preparedNavigation = nil // Reset when user cancels
                    }
                )
                .edgesIgnoringSafeArea(.all) // Make the navigation view full screen
            }
            // Present the Tangara 3D view
            .fullScreenCover(isPresented: $showTangaraView) {
                TangaraMapView(onDismiss: {
                    showTangaraView = false
                })
            }
        }
    }
}
