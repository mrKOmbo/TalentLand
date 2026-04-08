//
//  BusinessLocationMapView.swift
//  Atenea
//
//  Map view for selecting business location and route waypoints
//

import SwiftUI
import MapKit
import MapboxMaps

struct BusinessLocationMapView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLocation: BusinessLocation?
    let isMobileBusinesse: Bool // If true, allow multiple waypoints
    @Binding var routeWaypoints: [RouteWaypoint]?

    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var waypoints: [RouteWaypoint] = []
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var showRouteConfig = false
    @State private var isCalculatingRoute = false
    @State private var estimatedDistance: Double?
    @State private var estimatedDuration: Double?

    var body: some View {
        ZStack {
            // Mapbox Map
            MapboxMapView(
                waypoints: $waypoints,
                selectedCoordinate: $selectedCoordinate,
                routeCoordinates: $routeCoordinates,
                isMobileBusinesse: isMobileBusinesse,
                onMapTap: handleMapTap
            )
            .ignoresSafeArea()

            // Overlay UI
            VStack {
                // Search bar
                searchBar

                Spacer()

                // Instructions and confirm button
                bottomControls
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Atrás")
                            .font(.system(size: 17, weight: .regular))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.black.opacity(0.6))
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
                    )
                }
            }
        }
        .sheet(isPresented: $showRouteConfig) {
            RouteConfigurationSheet(
                waypoints: $waypoints,
                onSave: { /* Route saved */ }
            )
        }
    }

    // MARK: - Helper Functions

    private func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if isMobileBusinesse {
            // Add waypoint to route
            let newWaypoint = RouteWaypoint(
                coordinate: coordinate,
                order: waypoints.count
            )
            waypoints.append(newWaypoint)

            // Calculate route preview if we have at least 2 points
            if waypoints.count >= 2 {
                calculateRoutePreview()
            }
        } else {
            // Set single location
            selectedCoordinate = coordinate
        }
    }

    private func calculateRoutePreview() {
        isCalculatingRoute = true

        MapboxRoutingService.shared.calculateRoute(waypoints: waypoints, profile: .walking) { result in
            DispatchQueue.main.async {
                isCalculatingRoute = false

                switch result {
                case .success(let response):
                    guard let route = response.routes.first else { return }

                    // Extract coordinates from geometry
                    let coordinates = route.geometry.coordinates.map {
                        CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0])
                    }

                    routeCoordinates = coordinates
                    estimatedDistance = route.distance
                    estimatedDuration = route.duration

                case .failure(let error):
                    print("❌ Error calculando preview: \(error.localizedDescription)")
                    // Clear route line on error
                    routeCoordinates = []
                }
            }
        }
    }

    private func reverseRoute() {
        guard waypoints.count >= 2 else { return }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Reverse the waypoints array
        waypoints.reverse()

        // Update order indices
        for index in waypoints.indices {
            waypoints[index] = RouteWaypoint(
                id: waypoints[index].id,
                coordinate: waypoints[index].coordinate,
                order: index,
                name: waypoints[index].name
            )
        }

        // Recalculate route with new direction
        calculateRoutePreview()
    }

    private var searchBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)

                TextField("Buscar dirección o lugar", text: $searchText)
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Route stats (mobile only)
            if isMobileBusinesse && waypoints.count >= 2 {
                HStack(spacing: 16) {
                    // Distance
                    if let distance = estimatedDistance {
                        VStack(spacing: 4) {
                            Text(String(format: "%.1f km", distance / 1000))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.purple)

                            Text("Distancia")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    Divider()
                        .frame(height: 40)

                    // Duration
                    if let duration = estimatedDuration {
                        VStack(spacing: 4) {
                            Text(String(format: "%d min", Int(duration / 60)))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.purple)

                            Text("Duración")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    Divider()
                        .frame(height: 40)

                    // Waypoints
                    VStack(spacing: 4) {
                        Text("\(waypoints.count)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.purple)

                        Text("Puntos")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
                )
            }

            // Instructions card
            HStack(spacing: 12) {
                Image(systemName: isCalculatingRoute ? "hourglass" : "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.purple)
                    .symbolEffect(.pulse, isActive: isCalculatingRoute)

                VStack(alignment: .leading, spacing: 4) {
                    Text(isCalculatingRoute ? "Calculando ruta..." : (isMobileBusinesse ? "Marca tu ruta" : "Ubica tu negocio"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(isMobileBusinesse
                         ? "Mantén presionado en el mapa para añadir puntos. Pellizca para hacer zoom."
                         : "Mantén presionado en el mapa para marcar tu ubicación")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
            )

            // Waypoint management buttons (mobile only)
            if isMobileBusinesse && !waypoints.isEmpty {
                VStack(spacing: 12) {
                    // Top row: Reverse and Clear
                    HStack(spacing: 12) {
                        // Reverse direction button (only if 2+ points)
                        if waypoints.count >= 2 {
                            Button(action: {
                                reverseRoute()
                            }) {
                                Label("Invertir", systemImage: "arrow.left.arrow.right")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(.white)
                                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                                    )
                            }
                        }

                        Button(action: {
                            waypoints.removeAll()
                            routeCoordinates = []
                            estimatedDistance = nil
                            estimatedDuration = nil
                        }) {
                            Label("Borrar", systemImage: "trash")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.white)
                                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                                )
                        }
                    }

                    // Bottom row: Undo
                    Button(action: {
                        if !waypoints.isEmpty {
                            waypoints.removeLast()
                            // Recalculate route if still enough points
                            if waypoints.count >= 2 {
                                calculateRoutePreview()
                            } else {
                                routeCoordinates = []
                                estimatedDistance = nil
                                estimatedDuration = nil
                            }
                        }
                    }) {
                        Label("Deshacer último punto", systemImage: "arrow.uturn.backward")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                            )
                    }
                }
            }

            // Confirm button
            Button(action: confirmLocation) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))

                    Text(isMobileBusinesse ? "Guardar ruta" : "Confirmar ubicación")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: canConfirm ? [.purple, .pink] : [.gray, .gray],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(
                    color: canConfirm ? Color.purple.opacity(0.4) : .clear,
                    radius: 12,
                    x: 0,
                    y: 6
                )
            }
            .disabled(!canConfirm)
        }
        .padding(16)
    }

    private var canConfirm: Bool {
        if isMobileBusinesse {
            return waypoints.count >= 2 // Need at least 2 points for a route
        } else {
            return selectedCoordinate != nil
        }
    }

    private func confirmLocation() {
        if isMobileBusinesse {
            // Save waypoints for mobile business
            guard waypoints.count >= 2 else { return }
            routeWaypoints = waypoints
        } else {
            // Save single location for fixed business
            guard let coordinate = selectedCoordinate else { return }
            selectedLocation = BusinessLocation(
                coordinate: coordinate,
                address: "Ubicación seleccionada" // TODO: Reverse geocoding
            )
        }

        dismiss()
    }
}

// MARK: - Business Location Model

struct BusinessLocation: Codable {
    let latitude: Double
    let longitude: Double
    let address: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(coordinate: CLLocationCoordinate2D, address: String) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.address = address
    }
}

// MARK: - Route Configuration Sheet

struct RouteConfigurationSheet: View {
    @Binding var waypoints: [RouteWaypoint]
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(waypoints.sorted(by: { $0.order < $1.order })) { waypoint in
                        HStack {
                            Text("Punto \(waypoint.order + 1)")
                                .font(.system(size: 16, weight: .medium))

                            Spacer()

                            Text(String(format: "%.4f, %.4f", waypoint.latitude, waypoint.longitude))
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onMove { from, to in
                        waypoints.move(fromOffsets: from, toOffset: to)
                        reorderWaypoints()
                    }
                    .onDelete { indexSet in
                        waypoints.remove(atOffsets: indexSet)
                        reorderWaypoints()
                    }
                } header: {
                    Text("Puntos de la ruta")
                }
            }
            .navigationTitle("Configurar ruta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func reorderWaypoints() {
        for (index, _) in waypoints.enumerated() {
            waypoints[index] = RouteWaypoint(
                id: waypoints[index].id,
                coordinate: waypoints[index].coordinate,
                order: index,
                name: waypoints[index].name
            )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BusinessLocationMapView(
            selectedLocation: .constant(nil),
            isMobileBusinesse: false,
            routeWaypoints: .constant(nil)
        )
    }
}
