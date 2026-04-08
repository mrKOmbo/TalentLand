//
//  MainMapView.swift
//  atenea
//
//  Vista principal del mapa con botón de menú para acceder a funciones
//

import SwiftUI
import MapboxMaps
import MapboxNavigationCore
internal import MapboxDirections
import CoreLocation
import MapKit
import ConfettiSwiftUI

struct MainMapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchViewModel = SearchViewModel()
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject private var emergencyManager = EmergencyModeManager.shared
    @ObservedObject private var menuState = MenuStateManager.shared
    @ObservedObject private var demandManager = DemandZoneManager.shared
    @ObservedObject private var userManager = UserManager.shared
    @Binding var selectedTab: Int
    @Binding var isLoggedIn: Bool
    @State private var selectedSearchPlace: SearchPlace? = nil
    @State private var searchMarkers: [SearchPlace] = []
    @State private var preparedNavigation: PreparedNavigation? = nil
    @State private var showTangaraView = false
    @State private var showLine1Simulation = false
    @State private var showLine2Simulation = false
    @State private var showLine3Simulation = false
    @State private var showLine9Simulation = false
    @State private var selectedMapStyle: MapStyle = .standard
    @State private var showVenuesView = false
    @State private var reservations: [VenueReservation] = []
    @State private var sheetHeight: CGFloat = 164
    @State private var centerOnLocation: Bool = false
    @State private var modalState: SheetState = .collapsed
    @State private var cameraCenter: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 20.0, longitude: -100.0) // Centro en América para ver el globo completo
    @State private var cameraZoom: Double = 1.0 // Zoom mínimo para ver el globo completo
    @State private var cameraPitch: Double = 0 // Inclinación de la cámara (0 = 2D, 45-60 = 3D)
    @FocusState private var isSearchFocused: Bool
    @State private var selectedMarker: SearchPlace? = nil
    @State private var estimatedTravelTime: TimeInterval? = nil
    @State private var showDirections: Bool = false
    @State private var routePolylines: [MKPolyline] = []
    @State private var selectedDirectionsRouteIndex: Int = 0
    @State private var selectedTransportMode: TransportMode = .driving
    @State private var tappedCoordinate: CLLocationCoordinate2D? = nil
    @State private var temporaryMarker: SearchPlace? = nil
    @State private var showVenueMarkers = true // Mostrar sedes por defecto
    @State private var selectedVenue: WorldCupVenue? = nil
    @State private var showVenueDetailModal = false
    @State private var shouldFollowUser = false // No seguir al usuario inicialmente
    @State private var isFirstLocationLoad = true // Para detectar la primera carga de ubicación
    @State private var selectedChipId: String? = nil // ID del chip seleccionado
    @State private var showScheduleModal = false // Modal de reservaciones
    @State private var showEmergencyModal = false // Modal de emergencia

    // Chat con Claude states
    @State private var showChatSearch = false
    @State private var showStaffView = false

    // AR Poster Scanner
    @State private var showARPosterScanner = false
    @StateObject private var stickerCollectionManager = StickerCollectionManager.shared
    @State private var isARNavigationMode = false // Indica que estamos navegando a una sede detectada por AR

    // Collapsible Search Bar
    @State private var isSearchBarExpanded = false // Control de expansión del buscador

    // Accessibility
    @State private var showAccessibilityView = false

    // Profile & Settings
    @State private var showProfileView = false
    @State private var showSettingsView = false
    @State private var showFavoritesView = false
    @State private var showHelpView = false

    // World Cup celebration
    @State private var isWorldCupToday = false
    @State private var confettiCounter = 0

    // Navigation State Manager
    @StateObject private var navigationStateManager = NavigationStateManager.shared

    // Location Banner
    @State private var showLocationBanner = false
    @State private var currentLocationText = "New York, États-Unis"

    // Category Filter
    @State private var selectedCategory: MapCategory? = nil
    @State private var isCategoryFilterExpanded = false

    // MARK: - Body Components (dividido para ayudar al compilador)

    var body: some View {
        viewWithModals
    }

    private var viewWithModals: some View {
        baseView
            .onAppear {
                loadReservations()
                handleAppIntentRequests()
                loadUserRouteOnMap()
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                if newValue == 0 && modalState == SheetState.hidden {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        modalState = SheetState.collapsed
                    }
                }

                // Mostrar banner de ubicación al regresar al mapa desde otro tab
                if newValue == 0 && oldValue != 0 {
                    // Resetear estado del buscador para mostrar el filtro de categorías
                    isSearchBarExpanded = false
                    isSearchFocused = false

                    if let userLocation = locationManager.currentLocation {
                        // Delay breve para que la vista termine de cargar
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            currentLocationText = getLocationName(for: userLocation)
                            showLocationBanner = true
                            print("📍 Banner de ubicación mostrado al regresar al mapa: \(currentLocationText)")
                        }
                    }
                }
            }
            .onChange(of: navigationStateManager.shouldOpenNavigation) { oldValue, newValue in
                if newValue && preparedNavigation != nil {
                    // La navegación ya está abierta o se va a abrir
                    print("🧭 [DEEP LINK] Navegación ya está abierta")
                    // Reset el flag
                    navigationStateManager.shouldOpenNavigation = false
                }
            }
            .onChange(of: showDirections) { oldValue, newValue in
                // Sincronizar el estado local con el manager global
                navigationStateManager.showDirections = newValue
            }
            .sheet(isPresented: $showVenuesView) {
                NavigationView {
                    VenuesListView()
                }
            }
            .sheet(isPresented: $showAccessibilityView) {
                VisualAccessibilitySettingsView()
            }
            .sheet(isPresented: $showProfileView) {
                UserProfileView()
            }
            .sheet(isPresented: $showSettingsView) {
                SettingsView(languageManager: languageManager)
            }
            .sheet(isPresented: $showFavoritesView) {
                FavoritesView()
            }
            .sheet(isPresented: $showHelpView) {
                HelpView()
            }
            .modifier(FullScreenCoversModifier(
                preparedNavigation: $preparedNavigation,
                showTangaraView: $showTangaraView,
                showLine1Simulation: $showLine1Simulation,
                showLine2Simulation: $showLine2Simulation,
                showLine3Simulation: $showLine3Simulation,
                showLine9Simulation: $showLine9Simulation,
                showChatSearch: $showChatSearch,
                showStaffView: $showStaffView,
                showARPosterScanner: $showARPosterScanner,
                stickerCollectionManager: stickerCollectionManager,
                selectedMarker: $selectedMarker,
                temporaryMarker: $temporaryMarker,
                showDirections: $showDirections,
                cameraCenter: $cameraCenter,
                cameraZoom: $cameraZoom,
                locationManager: locationManager,
                languageManager: languageManager,
                onNavigationCancel: {
                    preparedNavigation = nil
                    selectedMarker = nil
                    temporaryMarker = nil
                    showDirections = false
                    routePolylines = []
                    selectedDirectionsRouteIndex = 0
                    estimatedTravelTime = nil
                },
                onVenueDetected: { venue in
                    // Activar modo de navegación AR para prevenir que el seguimiento se reactive
                    isARNavigationMode = true

                    // Desactivar seguimiento del usuario para mantener la cámara en la sede
                    shouldFollowUser = false

                    // Asegurar que los marcadores de sedes estén visibles
                    showVenueMarkers = true

                    // Limpiar cualquier búsqueda o marcador temporal anterior
                    searchMarkers = []
                    selectedMarker = nil
                    temporaryMarker = nil
                    showDirections = false
                    selectedChipId = nil

                    print("🎯 Sede detectada por AR: \(venue.name)")
                    print("📍 Coordenadas: \(venue.coordinate.latitude), \(venue.coordinate.longitude)")
                    print("🔒 Modo navegación AR activado - seguimiento deshabilitado")

                    // Pequeño delay para asegurar que la vista AR se cierre primero
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        // Centrar el mapa en la sede detectada
                        withAnimation(.easeInOut(duration: 1.5)) {
                            cameraCenter = venue.coordinate
                            cameraZoom = 15.0
                        }

                        // Esperar a que la animación del mapa termine antes de mostrar el modal
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedVenue = venue
                                showVenueDetailModal = true
                            }

                            print("✅ Modal de sede mostrado: \(venue.name)")
                        }
                    }
                }
            ))
            .modifier(OverlaysModifier(
                showEmergencyModal: $showEmergencyModal,
                isFirstLocationLoad: $isFirstLocationLoad,
                locationManager: locationManager,
                languageManager: languageManager
            ))
            .modifier(LocationObserverModifier(
                locationManager: locationManager,
                searchViewModel: searchViewModel,
                isFirstLocationLoad: $isFirstLocationLoad,
                isWorldCupToday: $isWorldCupToday,
                confettiCounter: $confettiCounter,
                cameraCenter: $cameraCenter,
                cameraZoom: $cameraZoom,
                cameraPitch: $cameraPitch,
                shouldFollowUser: $shouldFollowUser,
                modalState: $modalState,
                showLocationBanner: $showLocationBanner,
                currentLocationText: $currentLocationText
            ))
            .onShake {
                // Abrir modal de emergencia cuando se agite el dispositivo
                if !emergencyManager.isEmergencyActive {
                    showEmergencyModal = true
                    print("🚨 Emergencia activada por shake gesture")
                }
            }
    }

    private var baseView: some View {
        ZStack {
            // Contenido principal con efecto 3D cuando el menú está abierto
            mainContentWithOverlays
        }
        .edgesIgnoringSafeArea(.all)
        .id(languageManager.currentLanguage)
        .zIndex(menuState.showMenu ? 100 : 1)
        .confettiCannon(trigger: $confettiCounter,
                        num: 50,
                        confettis: [.shape(.circle), .shape(.triangle), .text("⚽"), .text("🏆")],
                        confettiSize: 20,
                        rainHeight: 600,
                        radius: 400)
    }


    private var mainContentWithOverlays: some View {
        ZStack {
            mainContentView

            // Panel de direcciones cuando se selecciona un marcador (NO mostrar si el modal de sede está abierto, y ocultar en emergencia)
            if showDirections && !showVenueDetailModal && !emergencyManager.isEmergencyActive, let marker = selectedMarker, let markerCoord = marker.coordinate, let userLocation = locationManager.currentLocation {
                DirectionsView(
                    isPresented: $showDirections,
                    origin: userLocation,
                    destination: markerCoord,
                    destinationName: marker.name,
                    routePolylines: $routePolylines,
                    selectedRouteIndex: $selectedDirectionsRouteIndex,
                    selectedTransportMode: $selectedTransportMode,
                    onClose: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDirections = false
                            selectedMarker = nil
                            temporaryMarker = nil
                            estimatedTravelTime = nil
                            // Limpiar rutas del mapa
                            routePolylines = []
                            selectedDirectionsRouteIndex = 0
                        }
                    }
                )
                .id(marker.id)
                .transition(.move(edge: .bottom))
                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: marker.id)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: menuState.showMenu)
                .zIndex(100)
            }

            // Modal de detalle de sede FIFA (ocultar en emergencia)
            if showVenueDetailModal && !emergencyManager.isEmergencyActive, let venue = selectedVenue {
                VenueDetailView(
                    venue: venue,
                    isPresented: $showVenueDetailModal,
                    onDismiss: {
                        // Limpiar estado de la sede
                        selectedVenue = nil
                        // Asegurar que no haya panel de direcciones activo
                        if showDirections {
                            showDirections = false
                            selectedMarker = nil
                            temporaryMarker = nil
                        }
                    },
                    onGetDirections: {
                        handleVenueGetDirections()
                    }
                )
                .id(venue.id)
                .transition(.opacity)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: menuState.showMenu)
                .zIndex(101)
            }

            // Botones flotantes (ubicación y emergencia)
            VStack {
                Spacer()

                // Botón para desactivar modo de emergencia (solo visible en modo emergencia)
                if emergencyManager.isEmergencyActive {
                    Button(action: {
                        // Animar botón
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)

                        // Desactivar modo de emergencia
                        EmergencyModeManager.shared.deactivateEmergency()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)

                            Text(LocalizedString("emergency.endEmergency"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.green)
                                .shadow(color: Color.green.opacity(0.5), radius: 12, x: 0, y: 4)
                        )
                    }
                    .padding(.bottom, 40)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: emergencyManager.isEmergencyActive)
                }

                // Botones normales (ocultar en modo emergencia)
                if !emergencyManager.isEmergencyActive {
                    HStack(spacing: 12) {
                        // Botón de emergencia
                        Button(action: {
                            showEmergencyModal = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 50, height: 50)
                                    .shadow(color: Color.red.opacity(0.4), radius: 8, x: 0, y: 4)

                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: CGFloat(22)))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.leading, 20)
                        .transition(.move(edge: .leading).combined(with: .opacity))

                        // Botón de heatmap
                        Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                demandManager.showHeatMap.toggle()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(demandManager.showHeatMap ? Color.orange : Color.white)
                                        .frame(width: 50, height: 50)
                                        .shadow(color: (demandManager.showHeatMap ? Color.orange : Color.black).opacity(0.3), radius: 8, x: 0, y: 4)

                                    Image(systemName: demandManager.showHeatMap ? "flame.fill" : "flame")
                                        .font(.system(size: CGFloat(22)))
                                        .foregroundColor(demandManager.showHeatMap ? .white : .orange)
                                }
                            }
                        .transition(.scale.combined(with: .opacity))

                    Spacer()

                    // Botón de ubicación
                    Button(action: {
                        // Centrar el mapa en la ubicación actual y reactivar seguimiento
                        if let userLocation = locationManager.currentLocation {
                            // Desactivar modo de navegación AR
                            isARNavigationMode = false
                            shouldFollowUser = true
                            searchMarkers = []  // Limpiar marcadores de categorías
                            cameraCenter = nil  // Limpiar centro de cámara
                            selectedChipId = nil  // Deseleccionar chip
                            centerOnLocation.toggle()
                            print("📍 Centrando mapa en ubicación actual y activando seguimiento")
                            print("🔓 Modo navegación AR desactivado")

                            // Mostrar banner de ubicación
                            currentLocationText = getLocationName(for: userLocation)
                            showLocationBanner = true
                            print("📍 Banner de ubicación mostrado: \(currentLocationText)")
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)

                            Image(systemName: "location.fill")
                                .font(.system(size: CGFloat(22)))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, locationButtonOffset)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: menuState.showMenu)
                }
            }


            // Modal de reservaciones desde bottom sheet (ocultar en emergencia)
            if showScheduleModal && !emergencyManager.isEmergencyActive {
                ScheduleMatchModal(isPresented: $showScheduleModal) { match in
                    addReservation(from: match)
                }
                .environmentObject(languageManager)
                .zIndex(1000)
                .transition(.opacity)
            }

            // Banner de ubicación superior (ocultar en emergencia)
            if !emergencyManager.isEmergencyActive {
                LocationBannerView(
                    locationText: currentLocationText,
                    isVisible: $showLocationBanner
                )
                .zIndex(200)
            }
        }
        // Vista principal estática - no se mueve cuando el menú está abierto
        .allowsHitTesting(!menuState.showMenu)
    }


    // MARK: - Search Place Handling

    private func handlePlaceSelection(_ place: SearchPlace) {
        print("✅ Lugar seleccionado: \(place.name)")

        // Guardar el lugar seleccionado
        selectedSearchPlace = place

        // Agregar marcador si no está ya en la lista
        if !searchMarkers.contains(where: { $0.id == place.id }) {
            searchMarkers.append(place)
        }

        // Animar a la ubicación del lugar
        if let coordinate = place.coordinate {
            withAnimation(.easeInOut(duration: 1.2)) {
                cameraCenter = coordinate
                cameraZoom = 15
            }

            // Resetear después de la animación
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                cameraCenter = nil
            }

            print("📍 Volando a: \(place.name) (\(coordinate.latitude), \(coordinate.longitude))")
        }
    }

    // MARK: - Category Filter Selection

    private func handleCategorySelection(_ category: MapCategory?) {
        guard let category = category else {
            // Deseleccionar: limpiar marcadores y reactivar seguimiento
            searchMarkers = []
            if !isARNavigationMode {
                shouldFollowUser = true
            }
            cameraCenter = nil
            print("❌ Categoría deseleccionada")
            return
        }

        print("✅ Categoría seleccionada: \(category.name)")

        // Obtener lugares de la categoría
        let categoryPlaces = searchViewModel.getPlacesByCategory(category.searchTerm)

        if !categoryPlaces.isEmpty {
            // Desactivar seguimiento del usuario para mantener el mapa en esta vista
            shouldFollowUser = false

            // Agregar todos los lugares encontrados como marcadores
            searchMarkers = categoryPlaces

            // Centrar el mapa en el primer lugar
            if let firstPlace = categoryPlaces.first,
               let coordinate = firstPlace.coordinate {
                withAnimation(.easeInOut(duration: 1.0)) {
                    cameraCenter = coordinate
                    cameraZoom = 13  // Zoom más alejado para ver varios lugares
                }
            }

            print("📍 Se agregaron \(categoryPlaces.count) lugares de tipo '\(category.searchTerm)' al mapa")
        } else {
            print("⚠️ No se encontraron lugares para la categoría '\(category.name)'")
        }
    }

    // MARK: - Chip Selection

    private func handleChipSelection(_ chip: RecommendedChip) {
        print("✅ Chip seleccionado: \(chip.name)")

        // Si el chip ya está seleccionado, deseleccionarlo
        if selectedChipId == chip.id {
            selectedChipId = nil
            searchMarkers = []
            // No reactivar seguimiento si estamos en modo de navegación AR
            if !isARNavigationMode {
                shouldFollowUser = true
            }
            cameraCenter = nil
            print("❌ Chip deseleccionado: \(chip.name)")
            return
        }

        if chip.isCategory {
            // Obtener lugares de la categoría sin actualizar suggestions
            let categoryPlaces = searchViewModel.getPlacesByCategory(chip.category)

            if !categoryPlaces.isEmpty {
                // Marcar este chip como seleccionado
                selectedChipId = chip.id

                // Desactivar seguimiento del usuario para mantener el mapa en esta vista
                shouldFollowUser = false

                // Agregar todos los lugares encontrados como marcadores
                searchMarkers = categoryPlaces

                // Centrar el mapa en el primer lugar
                if let firstPlace = categoryPlaces.first,
                   let coordinate = firstPlace.coordinate {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        cameraCenter = coordinate
                        cameraZoom = 13  // Zoom más alejado para ver varios lugares
                    }
                }

                print("📍 Se agregaron \(categoryPlaces.count) lugares de tipo '\(chip.category)' al mapa")
            }
        }
    }

    // MARK: - Marker Tap Handling

    private func handleMarkerTap(_ marker: SearchPlace) {
        print("✅ Marcador tocado: \(marker.name)")

        // Si el panel ya está abierto, solo actualizar el marcador sin animación
        // para evitar conflictos con la transición del .id()
        if showDirections {
            selectedMarker = marker
        } else {
            // Panel cerrado, abrirlo con animación
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedMarker = marker
                showDirections = true
            }
        }

        // Calcular tiempo estimado si tenemos ubicación del usuario
        if let userLocation = locationManager.currentLocation,
           let markerCoordinate = marker.coordinate {
            calculateEstimatedTravelTime(from: userLocation, to: markerCoordinate)
        }
    }

    private func handleVenueTap(_ venue: WorldCupVenue) {
        print("⚽ Sede FIFA tocada: \(venue.name)")

        // Asegurarse de cerrar el panel de direcciones si está abierto
        showDirections = false
        selectedMarker = nil
        temporaryMarker = nil
        // Limpiar rutas anteriores
        routePolylines = []
        selectedDirectionsRouteIndex = 0

        // Si el modal de detalle ya está abierto, cerrarlo brevemente para refrescar
        if showVenueDetailModal {
            showVenueDetailModal = false

            // Esperar un momento antes de actualizar con la nueva sede
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.selectedVenue = venue
                    self.showVenueDetailModal = true
                }

                // Centrar cámara en la sede
                self.cameraCenter = venue.coordinate
                self.cameraZoom = 15
            }
        } else {
            // Modal cerrado, abrirlo normalmente
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedVenue = venue
                showVenueDetailModal = true
            }

            // Centrar cámara en la sede
            cameraCenter = venue.coordinate
            cameraZoom = 15
        }
    }

    private func handleVenueGetDirections() {
        guard let venue = selectedVenue, let userLocation = locationManager.currentLocation else {
            print("⚠️ No hay sede seleccionada o ubicación del usuario")
            return
        }

        print("🗺️ Obteniendo direcciones a: \(venue.name)")

        // Crear un marcador temporal para la sede
        let venueMarker = SearchPlace(
            id: venue.id.uuidString,
            name: venue.name,
            subtitle: venue.city,
            fullAddress: "\(venue.city), \(venue.country)",
            category: LocalizedString("map.stadiumCategory"),
            icon: "soccerball.circle.fill",
            coordinate: venue.coordinate,
            isRecommended: false
        )

        // Calcular tiempo estimado
        calculateEstimatedTravelTime(from: userLocation, to: venue.coordinate)

        // Si el panel ya está abierto, solo actualizar el marcador sin animación
        if showDirections {
            selectedMarker = venueMarker
        } else {
            // Panel cerrado, abrirlo con animación
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedMarker = venueMarker
                showDirections = true
            }
        }
    }

    // MARK: - Map Tap Handling

    private func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        print("🗺️ Tap en el mapa: (\(coordinate.latitude), \(coordinate.longitude))")

        // Crear un marcador temporal en la ubicación del tap
        let tempMarker = SearchPlace(
            id: UUID().uuidString,
            name: LocalizedString("map.selectedLocation"),
            subtitle: LocalizedString("map.pointOnMap"),
            fullAddress: String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude),
            category: LocalizedString("map.location"),
            icon: "mappin.circle.fill",
            coordinate: coordinate,
            isRecommended: false
        )

        // Si el panel ya está abierto, solo actualizar el marcador sin animación
        if showDirections {
            temporaryMarker = tempMarker
            selectedMarker = tempMarker
        } else {
            // Panel cerrado, abrirlo con animación
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                temporaryMarker = tempMarker
                selectedMarker = tempMarker
                showDirections = true
            }
        }

        // Calcular tiempo estimado si tenemos ubicación del usuario
        if let userLocation = locationManager.currentLocation {
            calculateEstimatedTravelTime(from: userLocation, to: coordinate)
        }
    }

    // MARK: - Travel Time Calculation

    private func calculateEstimatedTravelTime(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        let distanceInMeters = fromLocation.distance(from: toLocation)

        // Calcular tiempo estimado basado en velocidad promedio
        // Usamos diferentes velocidades según la distancia
        let estimatedSpeed: Double

        if distanceInMeters < 500 {
            // Caminando: 1.4 m/s (5 km/h)
            estimatedSpeed = 1.4
        } else if distanceInMeters < 2000 {
            // Caminando rápido: 2 m/s (7.2 km/h)
            estimatedSpeed = 2.0
        } else {
            // En transporte/auto: 8.3 m/s (30 km/h promedio en ciudad)
            estimatedSpeed = 8.3
        }

        let timeInSeconds = distanceInMeters / estimatedSpeed

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            estimatedTravelTime = timeInSeconds
        }

        print("📊 Tiempo estimado calculado: \(formatTravelTime(timeInSeconds)) para \(distanceInMeters) metros")
    }

    private func formatTravelTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        if minutes < 1 {
            return LocalizedString("time.lessThanMin")
        } else if minutes == 1 {
            return "1 \(LocalizedString("time.min"))"
        } else if minutes < 60 {
            return "\(minutes) \(LocalizedString("time.min"))"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) \(LocalizedString("time.hour"))"
            } else {
                return "\(hours) \(LocalizedString("time.hour")) \(remainingMinutes) \(LocalizedString("time.min"))"
            }
        }
    }

    // MARK: - Computed Properties for Map

    private var allMapMarkers: [SearchPlace] {
        var markers = searchMarkers
        if let tempMarker = temporaryMarker {
            markers.append(tempMarker)
        }
        return markers
    }

    private var mainContentView: some View {
        ZStack {
            // Mapa principal
            MapboxMainMapView(
                userLocation: locationManager.currentLocation,
                mapStyle: selectedMapStyle,
                centerOnLocation: $centerOnLocation,
                searchMarkers: allMapMarkers,
                venueMarkers: showVenueMarkers ? WorldCupVenue.allVenues : [],
                routePolylines: routePolylines,
                selectedRouteIndex: selectedDirectionsRouteIndex,
                selectedTransportMode: selectedTransportMode,
                cameraCenter: cameraCenter,
                cameraZoom: cameraZoom,
                cameraPitch: cameraPitch,
                shouldFollowUser: shouldFollowUser,
                isEmergencyActive: emergencyManager.isEmergencyActive,
                demandZones: demandManager.demandZones,
                showHeatMap: demandManager.showHeatMap,
                onMarkerTapped: { marker in
                    handleMarkerTap(marker)
                },
                onVenueTapped: { venue in
                    handleVenueTap(venue)
                },
                onMapTapped: { coordinate in
                    handleMapTap(at: coordinate)
                }
            )
            .ignoresSafeArea()

            // Barra de búsqueda y UI superior
            if !emergencyManager.isEmergencyActive {
                searchBarView
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: menuState.showMenu)
            }
        }
    }

    @ViewBuilder
    private var searchBarView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Nuevo buscador desplegable
            CollapsibleSearchBar(
                searchViewModel: searchViewModel,
                isExpanded: $isSearchBarExpanded,
                isSearchFocused: $isSearchFocused,
                isWorldCupToday: $isWorldCupToday
            )

            // Filtro de categorías desplegable (solo visible cuando el buscador NO está expandido)
            if !isSearchBarExpanded && !isSearchFocused {
                CategoryFilterScrollView(
                    selectedCategory: $selectedCategory,
                    isExpanded: $isCategoryFilterExpanded,
                    onCategorySelected: { category in
                        handleCategorySelection(category)
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()
        }
    }

    private var searchBarContent: some View {
        // Search bar delgado con liquid glass (más redondeado si es día del Mundial)
        HStack(spacing: 10) {
            // Ícono de búsqueda con symbol effect
            Image(systemName: isWorldCupToday ? "trophy.fill" : "magnifyingglass")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(
                    isSearchFocused ?
                    (isWorldCupToday ?
                        LinearGradient(
                            colors: [.orange, .yellow, .green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    ) :
                    LinearGradient(
                        colors: [.secondary, .secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, options: .repeat(2), value: isSearchFocused)

            // Campo de texto
            TextField(LocalizedString("map.searchPlaceholder"), text: $searchViewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .autocorrectionDisabled()
                .focused($isSearchFocused)
                .onTapGesture {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }

            // Indicador de carga o botón de limpiar
            if searchViewModel.isSearching {
                ProgressView()
                    .scaleEffect(CGFloat(0.75))
                    .tint(.blue)
            } else if !searchViewModel.searchText.isEmpty {
                Button(action: {
                    searchViewModel.clearSearch()
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }

        }
        .padding(.horizontal, 14)
        .padding(.vertical, isWorldCupToday ? 12 : 8)
        .background(
            // Liquid glass effect intenso (más redondeado si es día del Mundial)
            ZStack {
                // Capa 1: Base blur ultra intenso
                RoundedRectangle(cornerRadius: isWorldCupToday ? 28 : 25, style: .continuous)
                    .fill(.ultraThickMaterial)

                // Capa 2: Gradiente de luz superior (colores festivos si es día del Mundial)
                RoundedRectangle(cornerRadius: isWorldCupToday ? 28 : 25, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isWorldCupToday ? [
                                Color.yellow.opacity(0.15),
                                Color.orange.opacity(0.1),
                                Color.green.opacity(0.05)
                            ] : [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Capa 3: Border highlight brillante
                RoundedRectangle(cornerRadius: isWorldCupToday ? 28 : 25, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isSearchFocused ? 0.5 : 0.3),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )

                // Capa 4: Glow azul cuando está enfocado O arcoíris si es el día del Mundial
                if isSearchFocused {
                    if isWorldCupToday {
                        // Animación arcoíris estilo "Today is the World Cup"
                        RainbowBorderRounded(cornerRadius: 28)
                    } else {
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.3),
                                        Color.cyan.opacity(0.2)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                            .blur(radius: 4)
                    }
                }

                // Estrellas parpadeantes si es día del Mundial
                if isWorldCupToday {
                    celebrationStarsOverlay
                }
            }
            .shadow(color: isSearchFocused && isWorldCupToday ? Color.purple.opacity(0.3) : (isSearchFocused ? Color.blue.opacity(0.2) : Color.black.opacity(0.12)), radius: 16, x: 0, y: 8)
            .shadow(color: isSearchFocused && isWorldCupToday ? Color.blue.opacity(0.2) : Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSearchFocused)
    }

    @ViewBuilder
    private var searchResultsDropdown: some View {
        if !searchViewModel.suggestions.isEmpty {
            VStack(spacing: 0) {
                ForEach(searchViewModel.suggestions.prefix(6)) { place in
                    searchResultRow(for: place)

                    if place.id != searchViewModel.suggestions.prefix(6).last?.id {
                        Divider()
                            .padding(.leading, 64)
                    }
                }
            }
            .background(
                // Glassmorphism mejorado
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThickMaterial)

                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            Color.white.opacity(0.2),
                            lineWidth: 0.5
                        )
                }
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity),
                removal: .scale(scale: 0.95).combined(with: .opacity)
            ))
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: searchViewModel.suggestions.count)
        }
    }

    private func searchResultRow(for place: SearchPlace) -> some View {
        Button(action: {
            handlePlaceSelection(place)
            searchViewModel.clearSearch()
            isSearchFocused = false
            isSearchBarExpanded = false

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            HStack(spacing: 14) {
                // Icono con glassmorphism
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .strokeBorder(Color(.separator).opacity(0.2), lineWidth: 0.5)
                        )

                    Image(systemName: place.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(place.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(place.category)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)

                        if let distance = searchViewModel.distanceToPlace(place) {
                            Text("•")
                                .foregroundStyle(.tertiary)
                            Text(distance)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var recommendationChipsView: some View {
        if searchViewModel.searchText.isEmpty && !isSearchFocused {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    CategoryButton(
                        title: LocalizedString("map.suggestions"),
                        icon: "sparkles",
                        color: Color.purple,
                        isSelected: showChatSearch,
                        action: {
                            showChatSearch = true
                        },
                        isWorldCupDay: isWorldCupToday
                    )

                    ForEach(recommendedChips) { chip in
                        chipButton(for: chip)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private var celebrationStarsOverlay: some View {
        GeometryReader { geometry in
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.yellow)
                    .offset(
                        x: CGFloat(10 + index * 30),
                        y: -5
                    )
                    .opacity(0.8)
                    .scaleEffect(1.0 + CGFloat(index) * 0.2)
                    .modifier(PulsingStarModifier(delay: Double(index) * 0.3))
            }
        }
    }

    private func chipButton(for chip: RecommendedChip) -> some View {
        let isSelected = selectedChipId == chip.id
        let chipColor = isWorldCupToday ? celebrationColor(for: chip.color) : chip.color

        return Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                handleChipSelection(chip)
            }

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: isSelected ? .medium : .light)
            generator.impactOccurred()
        }) {
            HStack(spacing: 8) {
                // Contenedor del icono con fondo circular
                ZStack {
                    // Fondo circular con glassmorphism (más grande y colorido si es día del Mundial)
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [chipColor.opacity(isWorldCupToday ? 0.25 : 0.15), chipColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: isWorldCupToday ? 32 : 28, height: isWorldCupToday ? 32 : 28)

                    // Icono
                    Image(systemName: isSelected ? "checkmark" : chip.icon)
                        .font(.system(size: isSelected ? 12 : (isWorldCupToday ? 16 : 14), weight: .semibold))
                        .foregroundStyle(
                            isSelected ?
                            LinearGradient(
                                colors: [.white, .white],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [chipColor, chipColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce, value: isSelected)
                }

                // Texto
                Text(chip.name)
                    .font(.system(size: isWorldCupToday ? 15 : 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .padding(.leading, 5)
            .padding(.trailing, isWorldCupToday ? 16 : 14)
            .padding(.vertical, isWorldCupToday ? 8 : 6)
            .background(
                Group {
                    if isSelected {
                        // Chip seleccionado: Gradiente vibrante
                        ZStack {
                            // Base con gradiente vibrante
                            RoundedRectangle(cornerRadius: isWorldCupToday ? 20 : 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            chipColor,
                                            chipColor.opacity(0.85)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            // Capa de brillo superior
                            RoundedRectangle(cornerRadius: isWorldCupToday ? 20 : 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            // Border brillante
                            RoundedRectangle(cornerRadius: isWorldCupToday ? 20 : 16, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.2)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: chipColor.opacity(isWorldCupToday ? 0.6 : 0.5), radius: isWorldCupToday ? 20 : 16, x: 0, y: isWorldCupToday ? 10 : 8)
                        .shadow(color: chipColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        // Chip no seleccionado: Glassmorphism elegante (más redondeado si es día del Mundial)
                        ZStack {
                            // Base material
                            RoundedRectangle(cornerRadius: isWorldCupToday ? 20 : 16, style: .continuous)
                                .fill(.ultraThinMaterial)

                            // Gradiente sutil de luz (con colores festivos si es día del Mundial)
                            RoundedRectangle(cornerRadius: isWorldCupToday ? 20 : 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: isWorldCupToday ? [
                                            chipColor.opacity(0.15),
                                            chipColor.opacity(0.05)
                                        ] : [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            // Border delicado
                            RoundedRectangle(cornerRadius: isWorldCupToday ? 20 : 16, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 0.5
                                )
                        }
                        .shadow(color: isWorldCupToday ? chipColor.opacity(0.2) : Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                }
            )
            .scaleEffect(isWorldCupToday ? CGFloat(1.05) : CGFloat(1.0))
        }
        .buttonStyle(ChipButtonStyle())
    }

    // Colores más vibrantes para el día del Mundial
    private func celebrationColor(for color: Color) -> Color {
        switch color {
        case .orange: return .orange
        case .blue: return .cyan
        case .green: return .green
        case .red: return .pink
        case .purple: return .purple
        default: return color
        }
    }

    // MARK: - Recommended Chips Data

    private var recommendedChips: [RecommendedChip] {
        [
            RecommendedChip(
                id: "cat-1",
                name: LocalizedString("map.bars"),
                category: "Bar",
                icon: "wineglass.fill",
                color: .orange,
                isCategory: true
            ),
            RecommendedChip(
                id: "cat-2",
                name: LocalizedString("map.restaurants"),
                category: "Restaurante",
                icon: "fork.knife",
                color: .red,
                isCategory: true
            ),
            RecommendedChip(
                id: "cat-3",
                name: LocalizedString("map.cafes"),
                category: "Café",
                icon: "cup.and.saucer.fill",
                color: .brown,
                isCategory: true
            ),
            RecommendedChip(
                id: "cat-4",
                name: LocalizedString("map.museums"),
                category: "Museo",
                icon: "building.columns",
                color: .purple,
                isCategory: true
            ),
            RecommendedChip(
                id: "cat-5",
                name: LocalizedString("map.parks"),
                category: "Parque",
                icon: "leaf.fill",
                color: .green,
                isCategory: true
            ),
            RecommendedChip(
                id: "cat-6",
                name: LocalizedString("map.markets"),
                category: "Mercado",
                icon: "bag.fill",
                color: .cyan,
                isCategory: true
            ),
            RecommendedChip(
                id: "cat-7",
                name: LocalizedString("map.shopping"),
                category: "Tienda",
                icon: "cart.fill",
                color: .pink,
                isCategory: true
            ),
            RecommendedChip(
                id: "cat-8",
                name: LocalizedString("map.gyms"),
                category: "Gimnasio",
                icon: "figure.run",
                color: .indigo,
                isCategory: true
            )
        ]
    }

    // MARK: - Reservations Persistence
    private func loadReservations() {
        // Limpiar reservaciones de ejemplo anteriores (comentar esta línea después de la primera ejecución si quieres mantener reservaciones)
        UserDefaults.standard.removeObject(forKey: "venueReservations")

        if let data = UserDefaults.standard.data(forKey: "venueReservations"),
           let decoded = try? JSONDecoder().decode([VenueReservation].self, from: data) {
            reservations = decoded
        } else {
            // Iniciar con array vacío - no crear reservaciones de ejemplo
            reservations = []
        }
    }

    private func loadUserRouteOnMap() {
        // Cargar ruta del usuario registrado si existe
        guard let user = userManager.currentUser,
              user.routeHistory.count > 0 else {
            return
        }

        // Convertir historial de rutas a polyline
        let coordinates = user.routeHistory.map { location in
            CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        }

        guard coordinates.count >= 2 else { return }

        // Crear polyline
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)

        // Agregar a las rutas mostradas en el mapa
        routePolylines.append(polyline)

        print("📍 Ruta del usuario cargada con \(coordinates.count) puntos")
    }

    // MARK: - App Intent Request Handler

    /// Maneja las solicitudes provenientes de App Intents
    private func handleAppIntentRequests() {
        // Verificar si hay una navegación pendiente desde un Intent
        if let destination = UserDefaults.standard.dictionary(forKey: "pendingNavigationDestination"),
           let name = destination["name"] as? String,
           let latitude = destination["latitude"] as? Double,
           let longitude = destination["longitude"] as? Double {

            print("🧭 [APP INTENT] Procesando navegación pendiente a \(name)")

            // Crear coordenada de destino
            let destinationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

            // Activar navegación
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Buscar el venue correspondiente
                if let venue = WorldCupVenue.allVenues.first(where: { $0.name == name }) {
                    // Iniciar navegación al venue
                    self.startNavigationToVenue(venue)
                }

                // Limpiar flag
                UserDefaults.standard.removeObject(forKey: "pendingNavigationDestination")
            }
        }

        // Verificar si debe navegar al estadio más cercano
        if UserDefaults.standard.bool(forKey: "shouldNavigateToNearest") {
            print("🧭 [APP INTENT] Procesando navegación al estadio más cercano")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Buscar el estadio más cercano
                if let userLocation = locationManager.currentLocation {
                    let nearestVenue = self.findNearestVenue(to: userLocation)
                    if let venue = nearestVenue {
                        print("🧭 [APP INTENT] Navegando al estadio más cercano: \(venue.name)")
                        self.startNavigationToVenue(venue)
                    }
                } else {
                    print("⚠️ [APP INTENT] No se pudo obtener la ubicación del usuario")
                }

                // Limpiar flag
                UserDefaults.standard.removeObject(forKey: "shouldNavigateToNearest")
            }
        }
    }

    /// Encuentra el venue más cercano a una ubicación
    private func findNearestVenue(to location: CLLocationCoordinate2D) -> WorldCupVenue? {
        let userCLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        var nearestVenue: WorldCupVenue?
        var shortestDistance: Double = .infinity

        for venue in WorldCupVenue.allVenues {
            let venueLocation = CLLocation(latitude: venue.coordinate.latitude, longitude: venue.coordinate.longitude)
            let distance = userCLLocation.distance(from: venueLocation)

            if distance < shortestDistance {
                shortestDistance = distance
                nearestVenue = venue
            }
        }

        return nearestVenue
    }

    /// Inicia navegación a un venue específico
    private func startNavigationToVenue(_ venue: WorldCupVenue) {
        // Centrar el mapa en el venue
        withAnimation(.easeInOut(duration: 1.0)) {
            cameraCenter = venue.coordinate
            cameraZoom = 15.0
        }

        // Después de la animación, preparar la navegación
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            // Crear el marcador de destino
            self.temporaryMarker = SearchPlace(
                name: venue.name,
                subtitle: venue.city,
                fullAddress: "\(venue.name), \(venue.city), \(venue.country)",
                category: "Stadium",
                icon: "building.2.fill",
                coordinate: venue.coordinate,
                isRecommended: false
            )

            // Cargar y preparar la navegación
            guard let userLocation = self.locationManager.currentLocation else {
                print("⚠️ [APP INTENT] No se pudo obtener la ubicación del usuario para navegación")
                return
            }

            Task {
                do {
                    let preparedNav = try await NavigationLoader.shared.loadNavigation(
                        from: userLocation,
                        to: venue.coordinate
                    )
                    await MainActor.run {
                        self.preparedNavigation = preparedNav
                        print("🧭 [APP INTENT] Navegación preparada a \(venue.name)")
                    }
                } catch {
                    print("❌ [APP INTENT] Error cargando navegación: \(error.localizedDescription)")
                }
            }
        }
    }

    private func saveReservations() {
        if let encoded = try? JSONEncoder().encode(reservations) {
            UserDefaults.standard.set(encoded, forKey: "venueReservations")
        }
    }

    // Calcular el offset del botón de ubicación
    private var locationButtonOffset: CGFloat {
        // Posición fija desde el bottom (considerando el tab bar)
        return 110
    }

    // Abrir el modal de reservaciones desde el bottom sheet
    private func openReservationModal() {
        // Colapsar el bottom sheet
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            modalState = SheetState.collapsed
        }

        // Esperar a que termine la animación del sheet antes de abrir el modal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showScheduleModal = true
        }
    }

    // Manejar la reservación creada desde el modal
    private func addReservation(from match: ScheduledMatch) {
        let venueName = match.venue
        let cityName = extractCity(from: venueName)

        let reservation = VenueReservation(
            id: UUID(),
            venueName: venueName,
            venueCity: cityName,
            date: match.date,
            seatNumber: match.seats,
            status: match.status
        )

        reservations.append(reservation)
        saveReservations()

        print("✅ Nueva reservación creada: \(reservation.venueName) - \(reservation.seatNumber)")
    }

    private func extractCity(from venueName: String) -> String {
        let components = venueName.components(separatedBy: " - ")
        if components.count > 1 {
            return components[1]
        }
        return venueName
    }
}

// MARK: - View Modifiers para dividir la complejidad del body

struct FullScreenCoversModifier: ViewModifier {
    @Binding var preparedNavigation: PreparedNavigation?
    @Binding var showTangaraView: Bool
    @Binding var showLine1Simulation: Bool
    @Binding var showLine2Simulation: Bool
    @Binding var showLine3Simulation: Bool
    @Binding var showLine9Simulation: Bool
    @Binding var showChatSearch: Bool
    @Binding var showStaffView: Bool
    @Binding var showARPosterScanner: Bool
    @ObservedObject var stickerCollectionManager: StickerCollectionManager
    @Binding var selectedMarker: SearchPlace?
    @Binding var temporaryMarker: SearchPlace?
    @Binding var showDirections: Bool
    @Binding var cameraCenter: CLLocationCoordinate2D?
    @Binding var cameraZoom: Double
    let locationManager: LocationManager
    let languageManager: LanguageManager
    let onNavigationCancel: () -> Void
    let onVenueDetected: (WorldCupVenue) -> Void

    func body(content: Content) -> some View {
        content
            .fullScreenCover(item: $preparedNavigation) { nav in
                NavigationViewWrapper(
                    preparedNavigation: nav,
                    onCancel: onNavigationCancel
                )
                .edgesIgnoringSafeArea(.all)
            }
            .fullScreenCover(isPresented: $showTangaraView) {
                TangaraMapView(onDismiss: {
                    showTangaraView = false
                })
            }
            .fullScreenCover(isPresented: $showLine1Simulation) {
                if let line1 = metroLinesCDMX.first(where: { $0.number == 1 }) {
                    Line3SimulationView(metroLine: line1, onDismiss: {
                        showLine1Simulation = false
                    })
                }
            }
            .fullScreenCover(isPresented: $showLine2Simulation) {
                if let line2 = metroLinesCDMX.first(where: { $0.number == 2 }) {
                    Line3SimulationView(metroLine: line2, onDismiss: {
                        showLine2Simulation = false
                    })
                }
            }
            .fullScreenCover(isPresented: $showLine3Simulation) {
                if let line3 = metroLinesCDMX.first(where: { $0.number == 3 }) {
                    Line3SimulationView(metroLine: line3, onDismiss: {
                        showLine3Simulation = false
                    })
                }
            }
            .fullScreenCover(isPresented: $showLine9Simulation) {
                if let line9 = metroLinesCDMX.first(where: { $0.number == 9 }) {
                    Line3SimulationView(metroLine: line9, onDismiss: {
                        showLine9Simulation = false
                    })
                }
            }
            .fullScreenCover(isPresented: $showChatSearch) {
                AISearchView(
                    isPresented: $showChatSearch,
                    selectedCategory: nil,
                    onNavigateToLocation: { coordinate, name, zoom in
                        withAnimation {
                            cameraCenter = coordinate
                            cameraZoom = zoom
                        }
                    },
                    onShowDirections: { coordinate, name in
                        let temporaryPlace = SearchPlace(
                            id: UUID().uuidString,
                            name: name,
                            subtitle: "",
                            fullAddress: "",
                            category: "Lugar",
                            icon: "mappin.circle.fill",
                            coordinate: coordinate
                        )
                        selectedMarker = temporaryPlace
                        temporaryMarker = temporaryPlace
                        showDirections = true
                    },
                    userLocation: locationManager.currentLocation
                )
            }
            .fullScreenCover(isPresented: $showStaffView) {
                StaffView(
                    isPresented: $showStaffView,
                    onNavigateToEmergency: { coordinate, userName, startNavigation in
                        withAnimation(.easeInOut(duration: 1.0)) {
                            cameraCenter = coordinate
                            cameraZoom = 15.0
                        }

                        let emergencyMarker = SearchPlace(
                            id: UUID().uuidString,
                            name: "🚨 Emergencia: \(userName)",
                            subtitle: "Emergencia Activa",
                            fullAddress: "",
                            category: "Emergencia",
                            icon: "exclamationmark.triangle.fill",
                            coordinate: coordinate
                        )
                        selectedMarker = emergencyMarker
                        temporaryMarker = emergencyMarker

                        if startNavigation, let userLocation = locationManager.currentLocation {
                            Task {
                                do {
                                    let preparedNav = try await NavigationLoader.shared.loadNavigation(
                                        from: userLocation,
                                        to: coordinate
                                    )
                                    await MainActor.run {
                                        preparedNavigation = preparedNav
                                    }
                                } catch {
                                    print("❌ Error loading emergency navigation: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                )
                .environmentObject(languageManager)
            }
            .fullScreenCover(isPresented: $showARPosterScanner) {
                ARPosterView(
                    collectionManager: stickerCollectionManager,
                    onVenueDetected: { venue in
                        // Llamar al callback del modifier para centrar el mapa en la sede
                        self.onVenueDetected(venue)
                    },
                    onStickersCollected: { venue in
                        // Cuando se coleccionan stickers, simplemente cerrar la vista AR
                        print("✅ Stickers coleccionados para: \(venue.name)")
                    }
                )
            }
    }
}

struct OverlaysModifier: ViewModifier {
    @Binding var showEmergencyModal: Bool
    @Binding var isFirstLocationLoad: Bool
    let locationManager: LocationManager
    let languageManager: LanguageManager

    func body(content: Content) -> some View {
        content
            .overlay {
                if showEmergencyModal {
                    EmergencyModal(
                        isPresented: $showEmergencyModal,
                        userLocation: locationManager.currentLocation,
                        onEmergencyActivated: {
                            EmergencyModeManager.shared.activateEmergency()
                        }
                    )
                    .environmentObject(languageManager)
                    .transition(.opacity)
                    .zIndex(2000)
                }
            }
            .overlay {
                if isFirstLocationLoad {
                    WorldCupCelebrationView()
                        .zIndex(100)
                        .transition(.opacity)
                }
            }
    }
}

struct LocationObserverModifier: ViewModifier {
    let locationManager: LocationManager
    let searchViewModel: SearchViewModel
    @Binding var isFirstLocationLoad: Bool
    @Binding var isWorldCupToday: Bool
    @Binding var confettiCounter: Int
    @Binding var cameraCenter: CLLocationCoordinate2D?
    @Binding var cameraZoom: Double
    @Binding var cameraPitch: Double
    @Binding var shouldFollowUser: Bool
    @Binding var modalState: SheetState
    @Binding var showLocationBanner: Bool
    @Binding var currentLocationText: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                isWorldCupToday = checkIfWorldCupToday()
                searchViewModel.updateUserLocation(locationManager.currentLocation)
            }
            .onChange(of: locationManager.currentLocation) { oldValue, newValue in
                searchViewModel.updateUserLocation(newValue)

                if isFirstLocationLoad, let userLocation = newValue {
                    print("🌍 Primera ubicación detectada: \(userLocation.latitude), \(userLocation.longitude)")

                    if isWorldCupToday {
                        // Delay de 3 segundos para que la vista del mapa cargue completamente
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            confettiCounter += 1
                            print("🎉 ¡Lanzando confeti por el día del Mundial!")
                        }
                    }

                    // Esperar 2 segundos para que el usuario vea el globo completo
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        cameraCenter = userLocation
                        cameraZoom = 16.0
                        print("🎬 Iniciando animación hacia ubicación del usuario")

                        // Después de llegar a la ubicación (3.5s), hacer transición a vista 3D (3s adicionales)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                            withAnimation(.easeInOut(duration: 3.0)) {
                                cameraPitch = 45
                                print("🌐 Activando vista 3D (pitch: 45°)")
                            }

                            // Activar seguimiento del usuario después de la transición 3D
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                shouldFollowUser = true
                                print("📍 Seguimiento de usuario activado")
                            }
                        }

                        isFirstLocationLoad = false
                    }

                    // Mostrar banner de ubicación al entrar al mapa
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        // Obtener nombre de ubicación (puedes agregar reverse geocoding aquí)
                        currentLocationText = getLocationName(for: userLocation)
                        showLocationBanner = true
                        print("📍 Banner de ubicación mostrado: \(currentLocationText)")
                    }
                }
            }
    }

    /// Verifica si hoy es el día del Mundial (11 de junio de 2026)
    /// O si está habilitado en UserDefaults para pruebas o desde el login
    private func checkIfWorldCupToday() -> Bool {
        // Verificar si el usuario marcó la casilla en el login
        if UserDefaults.standard.bool(forKey: "isWorldCupToday") {
            print("🎉 [CONFETTI] Celebración del Mundial activada desde login")
            return true
        }

        // Verificar si está forzado en UserDefaults para pruebas
        if UserDefaults.standard.bool(forKey: "forceWorldCupCelebration") {
            print("🎉 [CONFETTI] Celebración del Mundial forzada para pruebas")
            return true
        }

        // Verificar si es la fecha real del Mundial
        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: today)

        // Mundial 2026 comienza el 11 de junio de 2026
        if components.year == 2026 && components.month == 6 && components.day == 11 {
            print("🎉 [CONFETTI] ¡Hoy es el día del Mundial 2026!")
            return true
        }

        return false
    }
}

// MARK: - Helper Functions

/// Obtiene el nombre de la ubicación basado en las coordenadas
/// Puede ser mejorado con reverse geocoding real usando CLGeocoder o Amazon Location Service
func getLocationName(for coordinate: CLLocationCoordinate2D) -> String {
    // Por ahora, retornar ubicación genérica basada en coordenadas
    // TODO: Implementar reverse geocoding real con Amazon Location Service o CLGeocoder

    // Detectar si está en México (aproximado)
    if coordinate.latitude >= 14.5 && coordinate.latitude <= 32.7 &&
       coordinate.longitude >= -118.4 && coordinate.longitude <= -86.7 {

        // Detección de ciudades principales en México
        if coordinate.latitude >= 19.0 && coordinate.latitude <= 19.6 &&
           coordinate.longitude >= -99.4 && coordinate.longitude <= -98.9 {
            return "Ciudad de México, CDMX"
        } else if coordinate.latitude >= 25.5 && coordinate.latitude <= 25.8 &&
                  coordinate.longitude >= -100.5 && coordinate.longitude <= -100.1 {
            return "Monterrey, Nuevo León"
        } else if coordinate.latitude >= 20.5 && coordinate.latitude <= 20.8 &&
                  coordinate.longitude >= -103.5 && coordinate.longitude <= -103.2 {
            return "Guadalajara, Jalisco"
        }

        return "México"
    }

    // Detectar si está en Estados Unidos (aproximado)
    if coordinate.latitude >= 25.0 && coordinate.latitude <= 49.0 &&
       coordinate.longitude >= -125.0 && coordinate.longitude <= -66.0 {

        // Detección de ciudades principales en USA
        if coordinate.latitude >= 40.6 && coordinate.latitude <= 40.9 &&
           coordinate.longitude >= -74.1 && coordinate.longitude <= -73.7 {
            return "New York, NY"
        } else if coordinate.latitude >= 34.0 && coordinate.latitude <= 34.4 &&
                  coordinate.longitude >= -118.7 && coordinate.longitude <= -118.1 {
            return "Los Angeles, CA"
        } else if coordinate.latitude >= 29.6 && coordinate.latitude <= 30.0 &&
                  coordinate.longitude >= -95.8 && coordinate.longitude <= -95.0 {
            return "Houston, TX"
        }

        return "United States"
    }

    // Detectar si está en Canadá (aproximado)
    if coordinate.latitude >= 41.0 && coordinate.latitude <= 83.0 &&
       coordinate.longitude >= -141.0 && coordinate.longitude <= -52.0 {

        // Detección de ciudades principales en Canadá
        if coordinate.latitude >= 43.5 && coordinate.latitude <= 43.9 &&
           coordinate.longitude >= -79.6 && coordinate.longitude <= -79.1 {
            return "Toronto, ON"
        } else if coordinate.latitude >= 45.4 && coordinate.latitude <= 45.6 &&
                  coordinate.longitude >= -73.8 && coordinate.longitude <= -73.4 {
            return "Montreal, QC"
        }

        return "Canada"
    }

    // Por defecto
    return String(format: "%.4f°, %.4f°", coordinate.latitude, coordinate.longitude)
}

// MARK: - Vista del mapa base de Mapbox

struct MapboxMainMapView: UIViewRepresentable {
    var userLocation: CLLocationCoordinate2D?
    var mapStyle: MapStyle
    @Binding var centerOnLocation: Bool
    var searchMarkers: [SearchPlace]
    var venueMarkers: [WorldCupVenue]
    var routePolylines: [MKPolyline]
    var selectedRouteIndex: Int
    var selectedTransportMode: TransportMode
    var cameraCenter: CLLocationCoordinate2D?
    var cameraZoom: CGFloat
    var cameraPitch: Double
    var shouldFollowUser: Bool
    var isEmergencyActive: Bool
    var demandZones: [DemandZone]
    var showHeatMap: Bool
    var onMarkerTapped: ((SearchPlace) -> Void)?
    var onVenueTapped: ((WorldCupVenue) -> Void)?
    var onMapTapped: ((CLLocationCoordinate2D) -> Void)?

    func makeUIView(context: Context) -> MapView {
        let mapView = MapView(frame: .zero)
        context.coordinator.mapView = mapView

        // Configurar cámara inicial - usar cameraCenter y cameraZoom si están disponibles
        let initialLocation = cameraCenter ?? CLLocationCoordinate2D(
            latitude: 10, // Latinoamérica y Estados Unidos por defecto
            longitude: -85
        )

        let initialZoom = cameraZoom

        mapView.mapboxMap.setCamera(to: CameraOptions(
            center: initialLocation,
            zoom: initialZoom,
            pitch: 0
        ))

        print("🗺️ Mapa inicializado con zoom: \(initialZoom), centro: \(initialLocation.latitude), \(initialLocation.longitude)")

        // Cargar estilo del mapa
        mapView.mapboxMap.loadStyleURI(mapStyle.styleURI) { error in
            if let error = error {
                print("❌ Error cargando estilo: \(error)")
            } else {
                print("✅ Estilo \(mapStyle.displayName) cargado")
                context.coordinator.styleLoaded = true
                // Agregar marcadores de sedes FIFA después de cargar el estilo
                if !self.venueMarkers.isEmpty {
                    context.coordinator.updateVenueMarkers(self.venueMarkers, on: mapView)
                }
                // Agregar heatmap pendiente o activo
                print("🔥 [styleLoaded] showHeatMap=\(self.showHeatMap), zones=\(self.demandZones.count), pending=\(context.coordinator.pendingHeatmapZones?.count ?? -1)")
                if let pendingZones = context.coordinator.pendingHeatmapZones {
                    print("🔥 [styleLoaded] Agregando heatmap pendiente con \(pendingZones.count) zonas")
                    context.coordinator.addDemandHeatmap(zones: pendingZones, on: mapView)
                    context.coordinator.pendingHeatmapZones = nil
                } else if self.showHeatMap && !self.demandZones.isEmpty {
                    print("🔥 [styleLoaded] Agregando heatmap directo con \(self.demandZones.count) zonas")
                    context.coordinator.addDemandHeatmap(zones: self.demandZones, on: mapView)
                } else {
                    print("🔥 [styleLoaded] No se agrega heatmap — showHeatMap=\(self.showHeatMap), zones=\(self.demandZones.count)")
                }
            }
        }

        // CONFIGURAR UBICACIÓN DEL USUARIO CON ORIENTACIÓN
        // Configurar el puck 2D con cono de luz y anillo de precisión (estilo Apple Maps)
        var puckConfig = Puck2DConfiguration.makeDefault(showBearing: true)

        // Mostrar anillo de precisión (círculo azul alrededor)
        puckConfig.showsAccuracyRing = true

        // Personalizar colores para aspecto similar a Apple Maps
        puckConfig.accuracyRingColor = UIColor.systemBlue.withAlphaComponent(0.2)  // Anillo azul claro
        puckConfig.accuracyRingBorderColor = UIColor.systemBlue.withAlphaComponent(0.3)  // Borde azul

        // El bearing image (cono de luz) se muestra automáticamente con showBearing: true
        // El cono apunta en la dirección del heading (giroscopio)

        // Configurar las opciones de ubicación con heading (brújula/giroscopio)
        mapView.location.options = LocationOptions(
            puckType: .puck2D(puckConfig),
            puckBearing: .heading,  // Usar brújula/giroscopio para orientación
            puckBearingEnabled: true
        )

        // Seguir la ubicación del usuario automáticamente con el mapa rotando (solo si shouldFollowUser es true)
        if shouldFollowUser {
            let followPuckOptions = FollowPuckViewportStateOptions(
                zoom: 16,
                bearing: .heading,  // Rotar el mapa según la orientación del dispositivo (giroscopio)
                pitch: 0
            )
            let followPuckState = mapView.viewport.makeFollowPuckViewportState(options: followPuckOptions)
            mapView.viewport.transition(to: followPuckState)
            print("📍 Seguimiento de usuario activado desde inicio")
        } else {
            print("🌍 Mapa libre - no siguiendo usuario desde inicio")
        }

        // Actualizar el estado del coordinator
        context.coordinator.currentShouldFollowUser = shouldFollowUser

        // Ocultar brújula, escala, logo y atribución
        mapView.ornaments.options.compass.visibility = .hidden
        mapView.ornaments.options.scaleBar.visibility = .hidden

        // Ocultar logo y botón de atribución moviéndolos fuera de la pantalla
        mapView.ornaments.options.logo.margins = CGPoint(x: -1000, y: -1000)
        mapView.ornaments.options.attributionButton.margins = CGPoint(x: -1000, y: -1000)

        // Agregar tap gesture recognizer para detectar taps en el mapa
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)

        print("✅ Mapa configurado con ubicación del usuario y orientación por giroscopio")

        return mapView
    }

    func updateUIView(_ mapView: MapView, context: Context) {
        // Verificar si cambió shouldFollowUser
        if context.coordinator.currentShouldFollowUser != shouldFollowUser {
            context.coordinator.currentShouldFollowUser = shouldFollowUser

            if !shouldFollowUser {
                // Simplemente no hacer nada - dejar que el usuario mueva el mapa libremente
                // El mapa ya no seguirá automáticamente al usuario
                print("📍 Seguimiento de usuario desactivado - mapa libre")
            } else {
                // Volver a seguir al usuario
                let followPuckOptions = FollowPuckViewportStateOptions(
                    zoom: 16,
                    bearing: .heading,
                    pitch: 0
                )
                let followPuckState = mapView.viewport.makeFollowPuckViewportState(options: followPuckOptions)
                mapView.viewport.transition(to: followPuckState)
                print("📍 Viewport cambiado a follow - siguiendo usuario")
            }
        }

        // Verificar si cambió el estilo del mapa
        if context.coordinator.currentStyle != mapStyle {
            context.coordinator.currentStyle = mapStyle
            context.coordinator.styleLoaded = false
            context.coordinator.heatmapAdded = false

            // Cambiar el estilo del mapa
            mapView.mapboxMap.loadStyleURI(mapStyle.styleURI) { error in
                if let error = error {
                    print("❌ Error cambiando estilo: \(error)")
                } else {
                    print("✅ Estilo cambiado a \(mapStyle.displayName)")
                    context.coordinator.styleLoaded = true
                    // Re-agregar marcadores de búsqueda
                    context.coordinator.updateSearchMarkers(searchMarkers, on: mapView)
                    // Re-agregar marcadores de sedes
                    context.coordinator.updateVenueMarkers(venueMarkers, on: mapView)
                    // Re-agregar rutas
                    context.coordinator.updateRoutePolylines(routePolylines, selectedIndex: selectedRouteIndex, transportMode: selectedTransportMode, on: mapView)
                    // Re-agregar heatmap si estaba activo
                    if self.showHeatMap && !self.demandZones.isEmpty {
                        context.coordinator.addDemandHeatmap(zones: self.demandZones, on: mapView)
                    }
                }
            }
        }

        // Actualizar marcadores de búsqueda si cambiaron
        if context.coordinator.currentSearchMarkers != searchMarkers {
            context.coordinator.updateSearchMarkers(searchMarkers, on: mapView)
            context.coordinator.currentSearchMarkers = searchMarkers
        }

        // Actualizar marcadores de sedes si cambiaron (solo después de que el estilo esté cargado)
        if context.coordinator.currentVenueMarkers.count != venueMarkers.count {
            // Verificar que el mapa esté listo antes de actualizar
            DispatchQueue.main.async {
                context.coordinator.updateVenueMarkers(venueMarkers, on: mapView)
                context.coordinator.currentVenueMarkers = venueMarkers
            }
        }

        // Actualizar rutas si cambiaron
        if context.coordinator.currentRoutePolylines.count != routePolylines.count ||
           context.coordinator.currentSelectedRouteIndex != selectedRouteIndex ||
           context.coordinator.currentTransportMode != selectedTransportMode {
            context.coordinator.updateRoutePolylines(routePolylines, selectedIndex: selectedRouteIndex, transportMode: selectedTransportMode, on: mapView)
            context.coordinator.currentRoutePolylines = routePolylines
            context.coordinator.currentSelectedRouteIndex = selectedRouteIndex
            context.coordinator.currentTransportMode = selectedTransportMode
        }

        // Animar cámara si se especificó un centro y cambió
        if let center = cameraCenter {
            let cameraCenterChanged = context.coordinator.currentCameraCenter == nil ||
                                      abs(context.coordinator.currentCameraCenter!.latitude - center.latitude) > 0.0001 ||
                                      abs(context.coordinator.currentCameraCenter!.longitude - center.longitude) > 0.0001
            let cameraZoomChanged = abs(context.coordinator.currentCameraZoom - cameraZoom) > 0.1
            let cameraPitchChanged = abs(context.coordinator.currentCameraPitch - cameraPitch) > 1.0

            if cameraCenterChanged || cameraZoomChanged || cameraPitchChanged {
                mapView.camera.fly(
                    to: CameraOptions(center: center, zoom: cameraZoom, pitch: cameraPitch),
                    duration: 3.0  // Duración más larga para animación suave
                )
                context.coordinator.currentCameraCenter = center
                context.coordinator.currentCameraZoom = cameraZoom
                context.coordinator.currentCameraPitch = cameraPitch
                print("🎬 Animando cámara hacia: \(center.latitude), \(center.longitude) con zoom: \(cameraZoom), pitch: \(cameraPitch)")
            }
        }

        // Centrar en la ubicación del usuario si se solicita
        if centerOnLocation, let location = userLocation {
            mapView.mapboxMap.setCamera(to: CameraOptions(
                center: location,
                zoom: 16,
                pitch: 0
            ))
        }

        // Actualizar puck si cambió el modo de emergencia
        if context.coordinator.currentIsEmergencyActive != isEmergencyActive {
            context.coordinator.currentIsEmergencyActive = isEmergencyActive
            context.coordinator.updateEmergencyPuck(isActive: isEmergencyActive, on: mapView)
        }

        // Actualizar heatmap de demanda
        let heatmapToggled = context.coordinator.currentShowHeatMap != showHeatMap
        let zonesChanged = context.coordinator.currentDemandZoneCount != demandZones.count

        print("🔥 [updateUIView] showHeatMap=\(showHeatMap), zones=\(demandZones.count), toggled=\(heatmapToggled), zonesChanged=\(zonesChanged), styleLoaded=\(context.coordinator.styleLoaded), heatmapAdded=\(context.coordinator.heatmapAdded)")

        if heatmapToggled {
            context.coordinator.currentShowHeatMap = showHeatMap
            if showHeatMap && !demandZones.isEmpty {
                if !context.coordinator.styleLoaded {
                    print("🔥 [updateUIView] Estilo no cargado, guardando \(demandZones.count) zonas como pendientes")
                    context.coordinator.pendingHeatmapZones = demandZones
                } else if !context.coordinator.heatmapAdded {
                    print("🔥 [updateUIView] Agregando heatmap ahora")
                    context.coordinator.addDemandHeatmap(zones: demandZones, on: mapView)
                } else {
                    print("🔥 [updateUIView] Toggling visibility ON")
                    context.coordinator.toggleDemandHeatmapVisibility(show: true, on: mapView)
                }
            } else {
                if context.coordinator.heatmapAdded {
                    print("🔥 [updateUIView] Toggling visibility OFF")
                    context.coordinator.toggleDemandHeatmapVisibility(show: false, on: mapView)
                }
            }
        } else if zonesChanged && showHeatMap && context.coordinator.styleLoaded {
            context.coordinator.currentDemandZoneCount = demandZones.count
            if context.coordinator.heatmapAdded {
                print("🔥 [updateUIView] Actualizando datos del heatmap")
                context.coordinator.updateDemandHeatmapData(zones: demandZones, on: mapView)
            } else {
                print("🔥 [updateUIView] Agregando heatmap (zones changed)")
                context.coordinator.addDemandHeatmap(zones: demandZones, on: mapView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(initialStyle: mapStyle, onMarkerTapped: onMarkerTapped, onVenueTapped: onVenueTapped, onMapTapped: onMapTapped)
    }

    class Coordinator {
        var mapView: MapView?
        var currentStyle: MapStyle
        var currentSearchMarkers: [SearchPlace] = []
        var currentVenueMarkers: [WorldCupVenue] = []
        var currentRoutePolylines: [MKPolyline] = []
        var currentSelectedRouteIndex: Int = 0
        var currentTransportMode: TransportMode = .driving
        var currentShouldFollowUser: Bool = false
        var currentIsEmergencyActive: Bool = false
        var currentCameraCenter: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 10, longitude: -85)
        var currentCameraZoom: CGFloat = 2.5
        var currentCameraPitch: Double = 0
        var emergencyPulseView: UIView?
        var emergencyPulseTimer: Timer?
        var searchAnnotationManager: PointAnnotationManager?
        var venueAnnotationManager: PointAnnotationManager?
        var onMarkerTapped: ((SearchPlace) -> Void)?
        var onVenueTapped: ((WorldCupVenue) -> Void)?
        var onMapTapped: ((CLLocationCoordinate2D) -> Void)?
        var currentShowHeatMap: Bool = false
        var currentDemandZoneCount: Int = 0
        var heatmapAdded: Bool = false
        var styleLoaded: Bool = false
        var pendingHeatmapZones: [DemandZone]?

        init(initialStyle: MapStyle, onMarkerTapped: ((SearchPlace) -> Void)?, onVenueTapped: ((WorldCupVenue) -> Void)?, onMapTapped: ((CLLocationCoordinate2D) -> Void)?) {
            self.currentStyle = initialStyle
            self.onMarkerTapped = onMarkerTapped
            self.onVenueTapped = onVenueTapped
            self.onMapTapped = onMapTapped
        }

        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = mapView else { return }

            let point = gesture.location(in: mapView)
            let coordinate = mapView.mapboxMap.coordinate(for: point)

            // Llamar al callback con las coordenadas del tap
            onMapTapped?(coordinate)
        }

        // MARK: - Search Markers

        func updateSearchMarkers(_ markers: [SearchPlace], on mapView: MapView) {
            // Crear annotation manager si no existe
            if searchAnnotationManager == nil {
                searchAnnotationManager = mapView.annotations.makePointAnnotationManager()

                // Configurar delegado para detectar taps
                searchAnnotationManager?.delegate = self
            }

            // Limpiar marcadores anteriores
            searchAnnotationManager?.annotations = []

            // Crear anotaciones para cada marcador
            var annotations: [PointAnnotation] = []

            for marker in markers {
                guard let coordinate = marker.coordinate else { continue }

                var annotation = PointAnnotation(id: marker.id, coordinate: coordinate)

                // Usar imagen personalizada según el ícono
                let markerImage = createMarkerImage(
                    icon: marker.icon,
                    color: marker.isRecommended ? .systemYellow : .systemRed
                )

                annotation.image = .init(image: markerImage, name: "marker-\(marker.id)")
                annotation.iconAnchor = .bottom
                annotation.iconOffset = [0, 0]

                // Sin texto - solo el marcador visual
                // annotation.textField = marker.name
                // annotation.textOffset = [0, -2.5]
                // annotation.textSize = 12
                // annotation.textColor = StyleColor(.white)
                // annotation.textHaloColor = StyleColor(.black)
                // annotation.textHaloWidth = 1.5

                annotations.append(annotation)
            }

            // Actualizar anotaciones en el mapa
            searchAnnotationManager?.annotations = annotations

            print("✅ \(annotations.count) marcadores de búsqueda agregados al mapa")
        }

        // Actualizar marcadores de sedes FIFA 2026
        func updateVenueMarkers(_ venues: [WorldCupVenue], on mapView: MapView) {
            guard !venues.isEmpty else {
                print("⚠️ No hay sedes para mostrar")
                return
            }

            // Crear annotation manager si no existe o recrearlo para forzar actualización
            if venueAnnotationManager == nil {
                venueAnnotationManager = mapView.annotations.makePointAnnotationManager()
                venueAnnotationManager?.delegate = self
                print("✅ Venue annotation manager creado")
            }

            guard let manager = venueAnnotationManager else {
                print("❌ Error: No se pudo crear venue annotation manager")
                return
            }

            // Limpiar marcadores anteriores completamente
            manager.annotations = []

            print("🔄 Recreando marcadores de sedes con map_marker.png...")

            // Crear anotaciones para cada sede
            var annotations: [PointAnnotation] = []

            for (index, venue) in venues.enumerated() {
                var annotation = PointAnnotation(id: venue.id.uuidString, coordinate: venue.coordinate)

                // Crear imagen del marcador personalizado con foto del estadio
                let venueImage = createVenueMarkerImage(imageName: venue.imageName, primaryColor: venue.primaryColor.toUIColor())

                // Usar timestamp para evitar caché
                let imageName = "venue-marker-\(venue.city)-\(Date().timeIntervalSince1970)"
                annotation.image = .init(image: venueImage, name: imageName)
                annotation.iconAnchor = .bottom // El pin apunta desde la punta inferior
                annotation.iconSize = 0.65 // Tamaño perfecto para visibilidad

                // Agregar texto con el nombre de la ciudad
                annotation.textField = venue.city
                annotation.textOffset = [0, -5.5] // Ajustado para el nuevo marcador de 100px
                annotation.textSize = 12
                annotation.textColor = StyleColor(.white)
                annotation.textHaloColor = StyleColor(.black)
                annotation.textHaloWidth = 2.5

                annotations.append(annotation)

                print("📍 Marcador \(index+1)/\(venues.count): \(venue.city) - Imagen: \(venue.imageName)")
            }

            // Actualizar anotaciones en el mapa
            manager.annotations = annotations

            print("⚽ \(annotations.count) marcadores de sedes FIFA 2026 agregados al mapa")
        }

        // Crear marcador hermoso estilo Google Maps
        private func createVenueMarkerImage(imageName: String, primaryColor: UIColor) -> UIImage {
            // Tamaño del marcador (un poco más grande para mejor visibilidad)
            let markerSize = CGSize(width: 70, height: 100)
            let renderer = UIGraphicsImageRenderer(size: markerSize)

            return renderer.image { context in
                let ctx = context.cgContext

                // PASO 1: Dibujar sombra suave debajo del pin
                let shadowPath = UIBezierPath()
                let shadowCenterX: CGFloat = markerSize.width / 2
                let shadowY: CGFloat = markerSize.height - 8

                shadowPath.addArc(
                    withCenter: CGPoint(x: shadowCenterX, y: shadowY),
                    radius: 15,
                    startAngle: 0,
                    endAngle: .pi * 2,
                    clockwise: true
                )

                ctx.saveGState()
                ctx.setShadow(offset: CGSize(width: 0, height: 2), blur: 8, color: UIColor.black.withAlphaComponent(0.3).cgColor)
                UIColor.black.withAlphaComponent(0.2).setFill()
                shadowPath.fill()
                ctx.restoreGState()

                // PASO 2: Dibujar el pin principal (forma de gota invertida estilo Google Maps)
                let pinPath = UIBezierPath()
                let centerX: CGFloat = markerSize.width / 2
                let topY: CGFloat = 15
                let radius: CGFloat = 22

                // Parte circular superior
                pinPath.addArc(
                    withCenter: CGPoint(x: centerX, y: topY + radius),
                    radius: radius,
                    startAngle: .pi,
                    endAngle: 0,
                    clockwise: true
                )

                // Punto inferior (punta del pin)
                pinPath.addCurve(
                    to: CGPoint(x: centerX, y: markerSize.height - 15),
                    controlPoint1: CGPoint(x: centerX + radius, y: topY + radius + 15),
                    controlPoint2: CGPoint(x: centerX + 10, y: markerSize.height - 25)
                )

                pinPath.addCurve(
                    to: CGPoint(x: centerX - radius, y: topY + radius),
                    controlPoint1: CGPoint(x: centerX - 10, y: markerSize.height - 25),
                    controlPoint2: CGPoint(x: centerX - radius, y: topY + radius + 15)
                )

                pinPath.close()

                // Gradiente del pin (color de la sede)
                ctx.saveGState()
                pinPath.addClip()

                let colors = [primaryColor.cgColor, primaryColor.withAlphaComponent(0.8).cgColor]
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!

                ctx.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: centerX, y: topY),
                    end: CGPoint(x: centerX, y: topY + radius * 2),
                    options: []
                )
                ctx.restoreGState()

                // Borde blanco del pin
                UIColor.white.setStroke()
                pinPath.lineWidth = 3
                pinPath.stroke()

                // PASO 3: Dibujar círculo interior para la foto
                let photoSize: CGFloat = 32
                let photoX = centerX - photoSize / 2
                let photoY = topY + radius - photoSize / 2
                let photoRect = CGRect(x: photoX, y: photoY, width: photoSize, height: photoSize)

                // Borde blanco alrededor de la foto
                let whiteCircle = UIBezierPath(ovalIn: photoRect.insetBy(dx: -3, dy: -3))
                UIColor.white.setFill()
                whiteCircle.fill()

                // Clip circular para la foto
                ctx.saveGState()
                let photoClip = UIBezierPath(ovalIn: photoRect)
                photoClip.addClip()

                // Intentar cargar y dibujar la foto del estadio
                if let stadiumImage = UIImage(named: imageName) {
                    stadiumImage.draw(in: photoRect)
                    print("✅ Imagen '\(imageName)' en marcador Google-style")
                } else {
                    // Fallback: gradiente con ícono
                    let fallbackColors = [primaryColor.withAlphaComponent(0.9).cgColor, primaryColor.withAlphaComponent(0.7).cgColor]
                    let fallbackGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: fallbackColors as CFArray, locations: [0.0, 1.0])!

                    ctx.drawRadialGradient(
                        fallbackGradient,
                        startCenter: CGPoint(x: photoRect.midX, y: photoRect.midY),
                        startRadius: 0,
                        endCenter: CGPoint(x: photoRect.midX, y: photoRect.midY),
                        endRadius: photoSize / 2,
                        options: []
                    )

                    // Ícono de estadio o balón
                    if let icon = UIImage(systemName: "figure.soccer") ?? UIImage(systemName: "soccerball") {
                        let iconSize: CGFloat = 18
                        let iconRect = CGRect(
                            x: photoRect.midX - iconSize / 2,
                            y: photoRect.midY - iconSize / 2,
                            width: iconSize,
                            height: iconSize
                        )
                        icon.withTintColor(.white, renderingMode: .alwaysOriginal).draw(in: iconRect)
                    }
                    print("⚠️ Imagen '\(imageName)' no encontrada, usando fallback")
                }

                ctx.restoreGState()

                // PASO 4: Brillo/reflejo en la parte superior (efecto glass)
                ctx.saveGState()
                let glossPath = UIBezierPath()
                glossPath.addArc(
                    withCenter: CGPoint(x: centerX, y: topY + radius),
                    radius: radius - 3,
                    startAngle: .pi * 1.2,
                    endAngle: .pi * 1.8,
                    clockwise: true
                )

                let glossColors = [UIColor.white.withAlphaComponent(0.4).cgColor, UIColor.white.withAlphaComponent(0.0).cgColor]
                let glossGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: glossColors as CFArray, locations: [0.0, 1.0])!

                glossPath.addClip()
                ctx.drawLinearGradient(
                    glossGradient,
                    start: CGPoint(x: centerX, y: topY),
                    end: CGPoint(x: centerX, y: topY + radius),
                    options: []
                )
                ctx.restoreGState()
            }
        }

        // Marcador simple como fallback si no existe map_marker.png
        private func createSimpleMarker(color: UIColor) -> UIImage {
            let size = CGSize(width: 50, height: 60)
            let renderer = UIGraphicsImageRenderer(size: size)

            return renderer.image { context in
                // Dibujar pin simple
                let pinPath = UIBezierPath()
                pinPath.move(to: CGPoint(x: 25, y: 60))
                pinPath.addLine(to: CGPoint(x: 18, y: 48))
                pinPath.addCurve(
                    to: CGPoint(x: 25, y: 12),
                    controlPoint1: CGPoint(x: 12, y: 42),
                    controlPoint2: CGPoint(x: 12, y: 24)
                )
                pinPath.addCurve(
                    to: CGPoint(x: 32, y: 48),
                    controlPoint1: CGPoint(x: 38, y: 24),
                    controlPoint2: CGPoint(x: 38, y: 42)
                )
                pinPath.close()

                color.setFill()
                pinPath.fill()

                UIColor.white.setStroke()
                pinPath.lineWidth = 2
                pinPath.stroke()
            }
        }

        // Crear marcador simple y limpio
        private func createMarkerImage(icon: String, color: UIColor) -> UIImage {
            let size = CGSize(width: 50, height: 60)
            let renderer = UIGraphicsImageRenderer(size: size)

            return renderer.image { context in
                let ctx = context.cgContext
                let centerX: CGFloat = size.width / 2
                let topY: CGFloat = 10
                let radius: CGFloat = 16

                // Sombra sutil
                ctx.saveGState()
                ctx.setShadow(offset: CGSize(width: 0, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.3).cgColor)

                // Pin simple (forma de lágrima)
                let pinPath = UIBezierPath()

                // Círculo superior
                pinPath.addArc(
                    withCenter: CGPoint(x: centerX, y: topY + radius),
                    radius: radius,
                    startAngle: 0,
                    endAngle: .pi * 2,
                    clockwise: true
                )

                // Punta inferior
                pinPath.move(to: CGPoint(x: centerX - 8, y: topY + radius + 12))
                pinPath.addLine(to: CGPoint(x: centerX, y: size.height - 5))
                pinPath.addLine(to: CGPoint(x: centerX + 8, y: topY + radius + 12))

                // Relleno del pin
                color.setFill()
                pinPath.fill()
                ctx.restoreGState()

                // Borde blanco delgado
                UIColor.white.setStroke()
                pinPath.lineWidth = 2
                pinPath.stroke()

                // Ícono en el centro del círculo
                if let iconImage = UIImage(systemName: icon) {
                    let iconSize: CGFloat = 14
                    let iconRect = CGRect(
                        x: centerX - iconSize / 2,
                        y: topY + radius - iconSize / 2,
                        width: iconSize,
                        height: iconSize
                    )
                    iconImage.withTintColor(.white, renderingMode: .alwaysOriginal).draw(in: iconRect)
                }
            }
        }
        // MARK: - Emergency Puck

        func updateEmergencyPuck(isActive: Bool, on mapView: MapView) {
            if isActive {
                // Activar marcador de emergencia rojo pulsante
                var configuration = Puck2DConfiguration()
                configuration.topImage = createEmergencyPuckImage()
                configuration.scale = .constant(1.0)

                mapView.location.options.puckType = .puck2D(configuration)

                // DESHABILITAR TODOS LOS GESTOS - Mapa bloqueado
                mapView.gestures.options.panEnabled = false
                mapView.gestures.options.pinchEnabled = false
                mapView.gestures.options.rotateEnabled = false
                mapView.gestures.options.pitchEnabled = false
                mapView.gestures.options.doubleTapToZoomInEnabled = false
                mapView.gestures.options.doubleTouchToZoomOutEnabled = false
                mapView.gestures.options.quickZoomEnabled = false

                // FORZAR SEGUIMIENTO CONSTANTE DEL USUARIO
                let followPuckOptions = FollowPuckViewportStateOptions(
                    zoom: 16,
                    bearing: .heading,
                    pitch: 0
                )
                let followPuckState = mapView.viewport.makeFollowPuckViewportState(options: followPuckOptions)
                mapView.viewport.transition(to: followPuckState, completion: { _ in
                    // Asegurar que el viewport permanezca en este estado
                    print("📍 Viewport bloqueado en ubicación del usuario")
                })

                // Iniciar animación de pulsación
                startPulseAnimation(on: mapView)

                print("🚨 Marcador de emergencia ACTIVADO - Mapa BLOQUEADO en ubicación actual")
            } else {
                // Restaurar marcador predeterminado
                var puckConfig = Puck2DConfiguration.makeDefault(showBearing: true)
                puckConfig.showsAccuracyRing = true
                puckConfig.accuracyRingColor = UIColor.systemBlue.withAlphaComponent(0.2)
                puckConfig.accuracyRingBorderColor = UIColor.systemBlue.withAlphaComponent(0.3)

                mapView.location.options = LocationOptions(
                    puckType: .puck2D(puckConfig),
                    puckBearing: .heading,
                    puckBearingEnabled: true
                )

                // RESTAURAR TODOS LOS GESTOS - Mapa libre de nuevo
                mapView.gestures.options.panEnabled = true
                mapView.gestures.options.pinchEnabled = true
                mapView.gestures.options.rotateEnabled = true
                mapView.gestures.options.pitchEnabled = true
                mapView.gestures.options.doubleTapToZoomInEnabled = true
                mapView.gestures.options.doubleTouchToZoomOutEnabled = true
                mapView.gestures.options.quickZoomEnabled = true

                // Detener animación de pulsación
                stopPulseAnimation()

                print("✅ Marcador restaurado al modo normal - Mapa DESBLOQUEADO")
            }
        }

        func createEmergencyPuckImage() -> UIImage {
            let size = CGSize(width: 70, height: 70)
            let renderer = UIGraphicsImageRenderer(size: size)

            return renderer.image { context in
                let cgContext = context.cgContext
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius: CGFloat = 30

                // Sombra exterior suave
                cgContext.saveGState()
                cgContext.setShadow(offset: CGSize(width: 0, height: 2), blur: 6, color: UIColor.black.withAlphaComponent(0.3).cgColor)

                // Círculo blanco exterior (borde grueso)
                let whiteCircle = UIBezierPath(ovalIn: CGRect(x: center.x - radius - 5, y: center.y - radius - 5, width: (radius + 5) * 2, height: (radius + 5) * 2))
                UIColor.white.setFill()
                whiteCircle.fill()
                cgContext.restoreGState()

                // Círculo rojo principal con gradiente radial
                cgContext.saveGState()
                let redCircle = UIBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))

                // Gradiente de rojo brillante a rojo oscuro
                let colors = [
                    UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0).cgColor,
                    UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0).cgColor
                ]
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!

                redCircle.addClip()
                cgContext.drawRadialGradient(
                    gradient,
                    startCenter: CGPoint(x: center.x, y: center.y - 10),
                    startRadius: 0,
                    endCenter: center,
                    endRadius: radius,
                    options: []
                )
                cgContext.restoreGState()

                // Símbolo de alerta: triángulo blanco con exclamación roja
                let symbolSize: CGFloat = 24
                let symbolY = center.y - 2

                // Triángulo blanco
                let trianglePath = UIBezierPath()
                trianglePath.move(to: CGPoint(x: center.x, y: symbolY - symbolSize/2))
                trianglePath.addLine(to: CGPoint(x: center.x - symbolSize/2, y: symbolY + symbolSize/2 - 2))
                trianglePath.addLine(to: CGPoint(x: center.x + symbolSize/2, y: symbolY + symbolSize/2 - 2))
                trianglePath.close()
                UIColor.white.setFill()
                trianglePath.fill()

                // Línea vertical de la exclamación
                let exclamationLine = UIBezierPath()
                exclamationLine.move(to: CGPoint(x: center.x, y: symbolY - 5))
                exclamationLine.addLine(to: CGPoint(x: center.x, y: symbolY + 3))
                exclamationLine.lineWidth = 2.2
                exclamationLine.lineCapStyle = .round
                UIColor(red: 0.85, green: 0.0, blue: 0.0, alpha: 1.0).setStroke()
                exclamationLine.stroke()

                // Punto de la exclamación
                let exclamationDot = UIBezierPath(ovalIn: CGRect(x: center.x - 1.5, y: symbolY + 6, width: 3, height: 3))
                UIColor(red: 0.85, green: 0.0, blue: 0.0, alpha: 1.0).setFill()
                exclamationDot.fill()
            }
        }

        func startPulseAnimation(on mapView: MapView) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let userLocation = mapView.location.latestLocation?.coordinate else { return }

                // Crear vista de pulso rojo
                let pulseView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
                pulseView.backgroundColor = .clear
                pulseView.isUserInteractionEnabled = false

                // Crear círculo rojo
                let circleLayer = CAShapeLayer()
                let circlePath = UIBezierPath(ovalIn: pulseView.bounds)
                circleLayer.path = circlePath.cgPath
                circleLayer.fillColor = UIColor.systemRed.withAlphaComponent(0.4).cgColor
                pulseView.layer.addSublayer(circleLayer)

                // Agregar vista al mapa centrada en la ubicación del usuario
                mapView.addSubview(pulseView)

                // Guardar referencia
                self.emergencyPulseView = pulseView

                // Iniciar animación de pulsación
                self.animatePulse(view: pulseView)

                // Crear timer para actualizar la posición del pulso según la ubicación del usuario
                self.emergencyPulseTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self, weak mapView, weak pulseView] _ in
                    guard let self = self, let mapView = mapView, let pulseView = pulseView,
                          let userLocation = mapView.location.latestLocation?.coordinate else { return }

                    // Convertir coordenadas del usuario a coordenadas de pantalla
                    let screenPoint = mapView.mapboxMap.point(for: userLocation)

                    // Centrar la vista de pulso en la ubicación del usuario
                    pulseView.center = screenPoint
                }
            }
        }

        func animatePulse(view: UIView) {
            UIView.animate(withDuration: 1.0, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
                view.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                view.alpha = 0.0
            }) { _ in
                view.transform = .identity
                view.alpha = 1.0
                // Repetir la animación
                self.animatePulse(view: view)
            }
        }

        func stopPulseAnimation() {
            emergencyPulseTimer?.invalidate()
            emergencyPulseTimer = nil

            emergencyPulseView?.layer.removeAllAnimations()
            emergencyPulseView?.removeFromSuperview()
            emergencyPulseView = nil
        }

        func addMetroLines(to mapView: MapView) {
            // Agregar cada línea del metro
            for metroLine in metroLinesCDMX {
                addMetroLine(metroLine, to: mapView, direction: "outbound")
                addMetroLine(metroLine, to: mapView, direction: "inbound")
            }
        }

        // MARK: - Route Polylines

        func updateRoutePolylines(_ polylines: [MKPolyline], selectedIndex: Int, transportMode: TransportMode, on mapView: MapView) {
            // Eliminar rutas anteriores
            removeRouteLayers(from: mapView)

            guard !polylines.isEmpty else {
                print("⚠️ No hay rutas para mostrar")
                return
            }

            print("🛣️ Dibujando \(polylines.count) rutas en el mapa (ruta seleccionada: \(selectedIndex), modo: \(transportMode.title))")

            // Dibujar cada ruta
            for (index, polyline) in polylines.enumerated() {
                let isSelected = (index == selectedIndex)
                drawRoute(polyline, index: index, isSelected: isSelected, transportMode: transportMode, on: mapView)
            }

            // Hacer zoom para encuadrar la ruta seleccionada
            if selectedIndex < polylines.count {
                let selectedPolyline = polylines[selectedIndex]
                fitRouteBounds(selectedPolyline, on: mapView)
            }
        }

        // Hacer zoom para mostrar toda la ruta
        private func fitRouteBounds(_ polyline: MKPolyline, on mapView: MapView) {
            let coordinates = polyline.coordinates()

            guard !coordinates.isEmpty else {
                print("⚠️ No se pueden calcular bounds: ruta sin coordenadas")
                return
            }

            // Calcular los límites (bounds) de la ruta
            var minLat = coordinates[0].latitude
            var maxLat = coordinates[0].latitude
            var minLon = coordinates[0].longitude
            var maxLon = coordinates[0].longitude

            for coord in coordinates {
                minLat = min(minLat, coord.latitude)
                maxLat = max(maxLat, coord.latitude)
                minLon = min(minLon, coord.longitude)
                maxLon = max(maxLon, coord.longitude)
            }

            // Crear CoordinateBounds para Mapbox
            let southwest = CLLocationCoordinate2D(latitude: minLat, longitude: minLon)
            let northeast = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon)
            let bounds = CoordinateBounds(southwest: southwest, northeast: northeast)

            // Padding para que la ruta no esté pegada a los bordes
            // Top: más padding para evitar la barra de búsqueda
            // Bottom: más padding para evitar el panel de direcciones
            let edgePadding = UIEdgeInsets(top: 150, left: 50, bottom: 400, right: 50)

            // Calcular el centro y el zoom apropiado para los bounds
            let centerLat = (minLat + maxLat) / 2
            let centerLon = (minLon + maxLon) / 2
            let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)

            // Calcular el zoom necesario para mostrar toda la ruta
            let latDelta = maxLat - minLat
            let lonDelta = maxLon - minLon
            let maxDelta = max(latDelta, lonDelta)

            // Fórmula aproximada para calcular el zoom basado en el delta
            // Zoom más bajo = más alejado
            var zoom: CGFloat = 14.0
            if maxDelta > 0.1 {
                zoom = 10.0
            } else if maxDelta > 0.05 {
                zoom = 11.5
            } else if maxDelta > 0.02 {
                zoom = 12.5
            } else if maxDelta > 0.01 {
                zoom = 13.5
            }

            // Crear CameraOptions con centro y zoom calculados
            let cameraOptions = CameraOptions(
                center: center,
                padding: edgePadding,
                zoom: zoom,
                bearing: 0,
                pitch: 0
            )

            // Animar la cámara suavemente
            mapView.camera.fly(
                to: cameraOptions,
                duration: 1.5,
                completion: nil
            )

            print("📍 Zoom ajustado para mostrar toda la ruta (zoom: \(zoom))")
        }

        private func drawRoute(_ polyline: MKPolyline, index: Int, isSelected: Bool, transportMode: TransportMode, on mapView: MapView) {
            let sourceId = "route-\(index)-source"
            let casingLayerId = "route-\(index)-casing"
            let lineLayerId = "route-\(index)-line"
            let arrowLayerId = "route-\(index)-arrows"

            // Convertir MKPolyline a coordenadas de Mapbox
            let coordinates = polyline.coordinates().map {
                LocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            }

            guard !coordinates.isEmpty else {
                print("⚠️ Ruta \(index) sin coordenadas")
                return
            }

            // Crear LineString
            let lineString = LineString(coordinates)

            // Crear source
            var source = GeoJSONSource(id: sourceId)
            source.data = .geometry(.lineString(lineString))

            // Agregar source
            do {
                try mapView.mapboxMap.addSource(source)
            } catch {
                print("❌ Error agregando source de ruta \(index): \(error)")
                return
            }

            // Estilos según el modo de transporte y si está seleccionada
            let lineColor: UIColor
            let lineWidth: Double
            let lineOpacity: Double
            let lineDasharray: [Double]?

            switch transportMode {
            case .driving:
                lineColor = isSelected ? .systemBlue : .systemGray
                lineWidth = isSelected ? 7.0 : 4.5
                lineOpacity = isSelected ? 1.0 : 0.5
                lineDasharray = nil // Línea sólida

            case .walking:
                lineColor = isSelected ? UIColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1.0) : .systemGray // Verde
                lineWidth = isSelected ? 6.0 : 4.0
                lineOpacity = isSelected ? 1.0 : 0.5
                lineDasharray = [2, 3] // Línea punteada

            case .cycling:
                lineColor = isSelected ? .systemPurple : .systemGray
                lineWidth = isSelected ? 6.5 : 4.2
                lineOpacity = isSelected ? 1.0 : 0.5
                lineDasharray = [5, 4, 2, 4] // Patrón dash-dot

            case .transit:
                lineColor = isSelected ? .systemOrange : .systemGray
                lineWidth = isSelected ? 7.0 : 4.5
                lineOpacity = isSelected ? 1.0 : 0.5
                lineDasharray = [8, 4] // Línea discontinua

            case .rideshare:
                // Color magenta vibrante estilo Lyft/Uber - premium y rápido
                lineColor = isSelected ? UIColor(red: 1.0, green: 0.1, blue: 0.8, alpha: 1.0) : .systemGray
                lineWidth = isSelected ? 8.5 : 5.0 // La más gruesa - servicio premium
                lineOpacity = isSelected ? 0.95 : 0.5 // Ligeramente transparente para efecto neón
                lineDasharray = [15, 2] // Estelas de velocidad: líneas muy largas + espacios mínimos
            }

            // CAPA 1: CASING (borde) - Especial para rideshare con efecto glow
            var casingLayer = LineLayer(id: casingLayerId, source: sourceId)
            if transportMode == .rideshare && isSelected {
                // Efecto glow magenta para rideshare
                casingLayer.lineColor = .constant(StyleColor(UIColor(red: 1.0, green: 0.4, blue: 0.9, alpha: 1.0)))
                casingLayer.lineWidth = .constant(lineWidth + 4) // Borde más grueso
                casingLayer.lineOpacity = .constant(0.6) // Semi-transparente para efecto glow
            } else {
                casingLayer.lineColor = .constant(StyleColor(.white))
                casingLayer.lineWidth = .constant(lineWidth + 2)
                casingLayer.lineOpacity = .constant(lineOpacity * 0.8)
            }
            casingLayer.lineCap = .constant(.round)
            casingLayer.lineJoin = .constant(.round)

            // Aplicar patrón al casing si existe (para mantener consistencia visual)
            if let dasharray = lineDasharray {
                casingLayer.lineDasharray = .constant(dasharray)
            }

            // CAPA 2: LÍNEA PRINCIPAL
            var mainLineLayer = LineLayer(id: lineLayerId, source: sourceId)
            mainLineLayer.lineColor = .constant(StyleColor(lineColor))
            mainLineLayer.lineWidth = .constant(lineWidth)
            mainLineLayer.lineOpacity = .constant(lineOpacity)
            mainLineLayer.lineCap = .constant(.round)
            mainLineLayer.lineJoin = .constant(.round)

            // Aplicar patrón de línea si existe
            if let dasharray = lineDasharray {
                mainLineLayer.lineDasharray = .constant(dasharray)
            }

            // CAPA 3: FLECHAS DIRECCIONALES
            // Espaciado según el modo de transporte (menor espaciado = más flechas para modos rápidos)
            let arrowSpacing: Double
            switch transportMode {
            case .rideshare:
                arrowSpacing = 70 // EL MÁS RÁPIDO - máxima densidad de flechas
            case .driving:
                arrowSpacing = 80 // Más flechas para coche (rápido)
            case .cycling:
                arrowSpacing = 100 // Velocidad media
            case .transit:
                arrowSpacing = 120 // Menos flechas (paradas frecuentes)
            case .walking:
                arrowSpacing = 150 // Menos flechas para caminar (lento)
            }

            // Crear imagen de flecha con color específico del modo de transporte
            let arrowImageName = "route-arrow-\(transportMode.rawValue)-\(isSelected ? "selected" : "alt")"
            if mapView.mapboxMap.image(withId: arrowImageName) == nil {
                let arrowImage = createArrowImage(color: lineColor, isSelected: isSelected)
                try? mapView.mapboxMap.addImage(arrowImage, id: arrowImageName)
            }

            var arrowLayer = SymbolLayer(id: arrowLayerId, source: sourceId)
            arrowLayer.iconImage = .constant(.name(arrowImageName))
            arrowLayer.iconSize = .constant(isSelected ? 0.45 : 0.35)

            // IMPORTANTE: Configuración para que las flechas sigan la dirección de la línea
            arrowLayer.symbolPlacement = .constant(.line) // Coloca símbolos a lo largo de la línea
            arrowLayer.iconRotationAlignment = .constant(.map) // Rota con el mapa
            arrowLayer.iconPitchAlignment = .constant(.map) // Alineación en 3D

            // QUITAR iconKeepUpright para que las flechas siempre sigan la dirección
            // arrowLayer.iconKeepUpright = .constant(true)
            // Sin esta propiedad, las flechas seguirán exactamente la dirección de cada segmento

            arrowLayer.symbolSpacing = .constant(arrowSpacing) // Espaciado dinámico según velocidad
            arrowLayer.iconAllowOverlap = .constant(true)
            arrowLayer.iconIgnorePlacement = .constant(true) // Permite que se superpongan
            arrowLayer.iconOpacity = .constant(lineOpacity)

            // Agregar capas
            do {
                try mapView.mapboxMap.addLayer(casingLayer)
                try mapView.mapboxMap.addLayer(mainLineLayer)
                try mapView.mapboxMap.addLayer(arrowLayer)
                print("✅ Ruta \(index) dibujada: \(transportMode.title) - Espaciado flechas: \(arrowSpacing)m (\(isSelected ? "seleccionada" : "alternativa"))")
            } catch {
                print("❌ Error agregando layers de ruta \(index): \(error)")
            }
        }

        // Crear imagen de flecha para la ruta
        private func createArrowImage(color: UIColor, isSelected: Bool) -> UIImage {
            let size = CGSize(width: 40, height: 40)
            let renderer = UIGraphicsImageRenderer(size: size)

            return renderer.image { context in
                let ctx = context.cgContext

                // Dibujar triángulo (flecha) apuntando hacia LA DERECHA
                // Mapbox espera que la flecha apunte a 0° (derecha) para rotarla correctamente
                let arrowPath = UIBezierPath()
                let centerX = size.width / 2
                let centerY = size.height / 2

                // Triángulo apuntando a la derecha
                arrowPath.move(to: CGPoint(x: centerX + 12, y: centerY)) // Punta (derecha)
                arrowPath.addLine(to: CGPoint(x: centerX - 8, y: centerY - 8)) // Arriba
                arrowPath.addLine(to: CGPoint(x: centerX - 8, y: centerY + 8)) // Abajo
                arrowPath.close()

                // Relleno
                color.setFill()
                arrowPath.fill()

                // Borde blanco para mejor visibilidad
                if isSelected {
                    UIColor.white.setStroke()
                    arrowPath.lineWidth = 2
                    arrowPath.stroke()
                }
            }
        }

        // MARK: - Demand Heatmap

        func addDemandHeatmap(zones: [DemandZone], on mapView: MapView) {
            removeDemandHeatmap(from: mapView)

            // Generar cientos de puntos individuales alrededor de Expo Santa Fe
            let expoCenter = CLLocationCoordinate2D(latitude: 19.3585, longitude: -99.2740)
            let featureCollection = DemandHeatmapBuilder.generateCrowdFeatures(around: expoCenter)
            let source = DemandHeatmapBuilder.makeSource(with: featureCollection)

            do {
                try mapView.mapboxMap.addSource(source)
            } catch {
                print("🔥 [HEATMAP] ERROR source: \(error)")
                return
            }

            // Agregar capas — mismo patrón que addMetroLine (sin layerPosition)
            do {
                try mapView.mapboxMap.addLayer(DemandHeatmapBuilder.makeGlowLayer())
                try mapView.mapboxMap.addLayer(DemandHeatmapBuilder.makeCircleLayer())
                try mapView.mapboxMap.addLayer(DemandHeatmapBuilder.makeSymbolLayer())
                heatmapAdded = true
                print("🔥 [HEATMAP] OK — \(featureCollection.features.count) puntos, glow+circle+symbol")
            } catch {
                print("🔥 [HEATMAP] ERROR layers: \(error)")
            }
        }

        func removeDemandHeatmap(from mapView: MapView) {
            try? mapView.mapboxMap.removeLayer(withId: DemandHeatmapBuilder.symbolLayerId)
            try? mapView.mapboxMap.removeLayer(withId: DemandHeatmapBuilder.circleLayerId)
            try? mapView.mapboxMap.removeLayer(withId: DemandHeatmapBuilder.glowLayerId)
            try? mapView.mapboxMap.removeSource(withId: DemandHeatmapBuilder.sourceId)
            heatmapAdded = false
        }

        func updateDemandHeatmapData(zones: [DemandZone], on mapView: MapView) {
            // Regenerar todos los puntos
            guard heatmapAdded else { return }
            let expoCenter = CLLocationCoordinate2D(latitude: 19.3585, longitude: -99.2740)
            let featureCollection = DemandHeatmapBuilder.generateCrowdFeatures(around: expoCenter)
            mapView.mapboxMap.updateGeoJSONSource(
                withId: DemandHeatmapBuilder.sourceId,
                geoJSON: .featureCollection(featureCollection)
            )
        }

        func toggleDemandHeatmapVisibility(show: Bool, on mapView: MapView) {
            guard heatmapAdded else { return }
            let visibility: MapboxMaps.Visibility = show ? .visible : .none
            do {
                try mapView.mapboxMap.updateLayer(withId: DemandHeatmapBuilder.glowLayerId, type: CircleLayer.self) { layer in
                    layer.visibility = .constant(visibility)
                }
                try mapView.mapboxMap.updateLayer(withId: DemandHeatmapBuilder.circleLayerId, type: CircleLayer.self) { layer in
                    layer.visibility = .constant(visibility)
                }
                try mapView.mapboxMap.updateLayer(withId: DemandHeatmapBuilder.symbolLayerId, type: SymbolLayer.self) { layer in
                    layer.visibility = .constant(visibility)
                }
            } catch {
                print("❌ Error toggling heatmap: \(error)")
            }
        }

        private func removeRouteLayers(from mapView: MapView) {
            // Eliminar todas las capas y sources de rutas anteriores
            for i in 0..<10 { // Asumir máximo 10 rutas
                let sourceId = "route-\(i)-source"
                let casingLayerId = "route-\(i)-casing"
                let lineLayerId = "route-\(i)-line"
                let arrowLayerId = "route-\(i)-arrows"

                // Eliminar layers (incluir flechas)
                try? mapView.mapboxMap.removeLayer(withId: arrowLayerId)
                try? mapView.mapboxMap.removeLayer(withId: lineLayerId)
                try? mapView.mapboxMap.removeLayer(withId: casingLayerId)

                // Eliminar source
                try? mapView.mapboxMap.removeSource(withId: sourceId)
            }
        }

        private func addMetroLine(_ metroLine: MetroLine, to mapView: MapView, direction: String) {
            let sourceId = "\(metroLine.id)-\(direction)-source"
            let casingLayerId = "\(metroLine.id)-\(direction)-casing"
            let lineLayerId = "\(metroLine.id)-\(direction)-line"
            let glowLayerId = "\(metroLine.id)-\(direction)-glow"

            // Crear coordenadas (invertir si es dirección de regreso)
            let coords = direction == "inbound" ? metroLine.coordinates.reversed() : metroLine.coordinates

            // Crear LineString con las coordenadas
            let lineCoordinates = coords.map { coord in
                LocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            }
            let lineString = LineString(lineCoordinates)

            // Crear GeoJSON source (solo una vez por dirección)
            var source = GeoJSONSource(id: sourceId)
            source.data = .geometry(.lineString(lineString))

            // Agregar source
            do {
                try mapView.mapboxMap.addSource(source)
            } catch {
                print("❌ Error agregando source \(sourceId): \(error)")
                return
            }

            // Offset para separar líneas de ida/vuelta (líneas paralelas claramente visibles)
            // Formula: offset debe ser > lineWidth para tener gap visible
            // Gap visible = offset - lineWidth. Con offset 10 y lineWidth 5 = gap de 5px
            let baseOffset: Double = 10.0  // Offset base para separación clara

            // CAPA 1: GLOW/RESPLANDOR (capa inferior para efecto de brillo)
            var glowLayer = LineLayer(id: glowLayerId, source: sourceId)
            glowLayer.lineColor = .constant(StyleColor(metroLine.color.withAlphaComponent(0.3)))
            // Escalar lineWidth con zoom para mantener proporción
            glowLayer.lineWidth = .expression(
                Exp(.interpolate) {
                    Exp(.linear)
                    Exp(.zoom)
                    10; 6.0   // Zoom 10: 6px
                    16; 10.0  // Zoom 16: 10px
                    20; 14.0  // Zoom 20: 14px
                }
            )
            glowLayer.lineBlur = .constant(3.0)
            glowLayer.lineOpacity = .constant(0.5)
            // Escalar offset con zoom para mantener separación consistente
            glowLayer.lineOffset = .expression(
                Exp(.interpolate) {
                    Exp(.linear)
                    Exp(.zoom)
                    10; direction == "inbound" ? baseOffset : -baseOffset        // Zoom 10: ±10px
                    16; direction == "inbound" ? baseOffset + 4 : -(baseOffset + 4)  // Zoom 16: ±14px
                    20; direction == "inbound" ? baseOffset + 8 : -(baseOffset + 8)  // Zoom 20: ±18px
                }
            )
            glowLayer.lineCap = .constant(.round)
            glowLayer.lineJoin = .constant(.round)

            // CAPA 2: CASING/BORDE (contorno blanco)
            var casingLayer = LineLayer(id: casingLayerId, source: sourceId)
            casingLayer.lineColor = .constant(StyleColor(.white))
            casingLayer.lineWidth = .expression(
                Exp(.interpolate) {
                    Exp(.linear)
                    Exp(.zoom)
                    10; 5.0
                    16; 8.0
                    20; 11.0
                }
            )
            casingLayer.lineOpacity = .constant(0.9)
            casingLayer.lineOffset = .expression(
                Exp(.interpolate) {
                    Exp(.linear)
                    Exp(.zoom)
                    10; direction == "inbound" ? baseOffset : -baseOffset
                    16; direction == "inbound" ? baseOffset + 4 : -(baseOffset + 4)
                    20; direction == "inbound" ? baseOffset + 8 : -(baseOffset + 8)
                }
            )
            casingLayer.lineCap = .constant(.round)
            casingLayer.lineJoin = .constant(.round)

            // CAPA 3: LÍNEA PRINCIPAL (color del metro)
            var mainLineLayer = LineLayer(id: lineLayerId, source: sourceId)
            mainLineLayer.lineColor = .constant(StyleColor(metroLine.color))
            mainLineLayer.lineWidth = .expression(
                Exp(.interpolate) {
                    Exp(.linear)
                    Exp(.zoom)
                    10; 3.5
                    16; 6.0
                    20; 8.5
                }
            )
            mainLineLayer.lineOpacity = .constant(1.0)
            mainLineLayer.lineOffset = .expression(
                Exp(.interpolate) {
                    Exp(.linear)
                    Exp(.zoom)
                    10; direction == "inbound" ? baseOffset : -baseOffset
                    16; direction == "inbound" ? baseOffset + 4 : -(baseOffset + 4)
                    20; direction == "inbound" ? baseOffset + 8 : -(baseOffset + 8)
                }
            )
            mainLineLayer.lineCap = .constant(.round)
            mainLineLayer.lineJoin = .constant(.round)

            // Agregar las 3 capas en orden (glow → casing → main)
            do {
                try mapView.mapboxMap.addLayer(glowLayer)
                try mapView.mapboxMap.addLayer(casingLayer)
                try mapView.mapboxMap.addLayer(mainLineLayer)
                print("✅ Línea \(metroLine.name) (\(direction)) con estilo profesional agregada")
            } catch {
                print("❌ Error agregando layers: \(error)")
            }
        }
    }
}

// MARK: - AnnotationInteractionDelegate

extension MapboxMainMapView.Coordinator: AnnotationInteractionDelegate {
    func annotationManager(_ manager: AnnotationManager, didDetectTappedAnnotations annotations: [MapboxMaps.Annotation]) {
        guard let tappedAnnotation = annotations.first as? PointAnnotation else { return }

        print("📍 Tap detectado en anotación ID: \(tappedAnnotation.id)")

        // Verificar si es un marcador de sede FIFA PRIMERO
        if let tappedVenue = currentVenueMarkers.first(where: { venue in
            venue.id.uuidString == tappedAnnotation.id
        }) {
            print("⚽ Tap detectado en sede FIFA: \(tappedVenue.name)")
            onVenueTapped?(tappedVenue)
            return
        }

        // Luego verificar si es un marcador de búsqueda
        if let tappedMarker = currentSearchMarkers.first(where: { marker in
            marker.id == tappedAnnotation.id
        }) {
            print("🎯 Tap detectado en marcador: \(tappedMarker.name)")
            onMarkerTapped?(tappedMarker)
            return
        }

        print("⚠️ Tap en anotación no reconocida")
    }
}

// Extensión para convertir SwiftUI Color a UIColor de manera segura
extension Color {
    func toUIColor() -> UIColor {
        // Crear un UIColor temporal para extraer componentes
        let color = UIColor(self)

        // Obtener componentes RGBA
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        // Extraer componentes en el espacio de color RGB
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Crear y devolver un nuevo UIColor con esos componentes
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

// Vista del menú tipo drawer (slide-in lateral)
struct DrawerMenuView: View {
    @Binding var isPresented: Bool
    @ObservedObject var locationManager: LocationManager
    @Binding var preparedNavigation: PreparedNavigation?
    @Binding var showTangaraView: Bool
    @Binding var showLine1Simulation: Bool
    @Binding var showLine2Simulation: Bool
    @Binding var showLine3Simulation: Bool
    @Binding var showLine9Simulation: Bool
    @Binding var selectedMapStyle: MapStyle
    @Binding var showVenuesView: Bool
    @Binding var reservations: [VenueReservation]
    @ObservedObject var languageManager: LanguageManager
    @Binding var showScheduleModal: Bool
    @Binding var showStaffView: Bool
    @ObservedObject var userManager = UserManager.shared
    var onLogout: (() -> Void)?

    @State private var drawerOffset: CGFloat = 380
    @State private var isMapStyleExpanded: Bool = false
    @State private var isPredictionsExpanded: Bool = false

    // Helper para obtener strings localizados que se actualizan con el idioma
    private func L(_ key: String) -> String {
        return languageManager.localizedString(key)
    }

    var body: some View {
        ZStack {
            // Overlay oscuro con blur ultrathink
            overlayBackground

            // Drawer panel - Alineado a la derecha
            HStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: 0) {
                    // Header simple sin gradiente
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("menu.options"))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.primary)

                                Text("Atenea 2026")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button(action: {
                                closeDrawer()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color(UIColor.systemGray6))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 56)
                        .padding(.bottom, 16)
                    }
                    .background(Color(UIColor.systemBackground))

                    // Indicador de usuario actual
                    if let currentUser = userManager.currentUser {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(currentUser.isAdmin ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                                    .frame(width: 40, height: 40)

                                Image(systemName: currentUser.isAdmin ? "person.badge.key.fill" : "person.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(currentUser.isAdmin ? .orange : .blue)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(currentUser.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)

                                Text(currentUser.role.displayName)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }

                    Divider()
                        .padding(.horizontal, 24)

                    // Contenido del menú en ScrollView
                    ScrollView(showsIndicators: false) {
                        menuContent
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(width: 340)
                .frame(maxHeight: .infinity)
                .background(
                    Color(UIColor.systemBackground)
                        .ignoresSafeArea()
                )
                .offset(x: drawerOffset)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: drawerOffset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
        .id(languageManager.currentLanguage) // Force re-render when language changes
        .onAppear {
            // Slide in animation
            withAnimation {
                drawerOffset = 0
            }
        }
    }

    // MARK: - Computed Properties

    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 16) {
                            // Sección de estilo de mapa (colapsable)
                            VStack(alignment: .leading, spacing: 12) {
                                Text(L("menu.mapStyle"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 24)

                                VStack(spacing: 0) {
                                    // Campo principal que muestra el estilo seleccionado
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            isMapStyleExpanded.toggle()
                                        }
                                    }) {
                                        HStack(spacing: 16) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.blue.opacity(0.1))
                                                    .frame(width: 40, height: 40)

                                                Image(systemName: selectedMapStyle.icon)
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.blue)
                                            }

                                            Text(selectedMapStyle.displayName)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.primary)

                                            Spacer()

                                            Image(systemName: isMapStyleExpanded ? "chevron.up" : "chevron.down")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 14)
                                    }
                                    .buttonStyle(.plain)

                                    // Opciones desplegables
                                    if isMapStyleExpanded {
                                        VStack(spacing: 0) {
                                            Divider()
                                                .padding(.horizontal, 20)

                                            ForEach(MapStyle.allCases.filter { $0 != selectedMapStyle }) { style in
                                                Button(action: {
                                                    selectedMapStyle = style
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                        isMapStyleExpanded = false
                                                    }
                                                }) {
                                                    HStack(spacing: 16) {
                                                        ZStack {
                                                            Circle()
                                                                .fill(Color.gray.opacity(0.1))
                                                                .frame(width: 40, height: 40)

                                                            Image(systemName: style.icon)
                                                                .font(.system(size: 18))
                                                                .foregroundColor(.gray)
                                                        }

                                                        Text(style.displayName)
                                                            .font(.system(size: 16))
                                                            .foregroundColor(.primary)

                                                        Spacer()
                                                    }
                                                    .padding(.horizontal, 20)
                                                    .padding(.vertical, 12)
                                                }
                                                .buttonStyle(.plain)

                                                if style != MapStyle.allCases.filter({ $0 != selectedMapStyle }).last {
                                                    Divider()
                                                        .padding(.horizontal, 20)
                                                }
                                            }
                                        }
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(.ultraThinMaterial)

                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.3),
                                                        Color.white.opacity(0.1)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    }
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
                                .padding(.horizontal, 20)
                            }

                            // Sección de idioma
                            VStack(alignment: .leading, spacing: 12) {
                                Text(L("menu.language"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 24)

                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill(Color.blue.opacity(0.1))
                                                .frame(width: 40, height: 40)

                                            Image(systemName: "globe")
                                                .font(.system(size: 18))
                                                .foregroundColor(.blue)
                                        }

                                        Text(L("menu.currentLanguage"))
                                            .font(.system(size: 15))
                                            .foregroundColor(.secondary)

                                        Spacer()

                                        Text(LanguageManager.availableLanguages[languageManager.currentLanguage] ?? languageManager.currentLanguage)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 24)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(Array(LanguageManager.availableLanguages.keys.sorted()), id: \.self) { languageCode in
                                                Button(action: {
                                                    languageManager.setLanguage(languageCode)
                                                }) {
                                                    VStack(spacing: 4) {
                                                        Text(LanguageManager.availableLanguages[languageCode] ?? languageCode)
                                                            .font(.system(size: 13, weight: .medium))
                                                            .foregroundColor(languageManager.currentLanguage == languageCode ? .white : .primary)

                                                        Text(languageCode)
                                                            .font(.system(size: 10))
                                                            .foregroundColor(languageManager.currentLanguage == languageCode ? .white.opacity(0.8) : .secondary)
                                                    }
                                                    .frame(minWidth: 70)
                                                    .padding(.vertical, 10)
                                                    .padding(.horizontal, 12)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(languageManager.currentLanguage == languageCode ? Color.blue : Color(.systemGray6))
                                                    )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal, 24)
                                    }
                                }
                                .padding(.vertical, 16)
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                                .padding(.horizontal, 24)
                            }

                            // Sección de FIFA 2026 - Rediseño ultrathink
                            VStack(alignment: .leading, spacing: 16) {
                                Text("FIFA World Cup 2026™")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .padding(.horizontal, 20)

                                // FIFA 2026 Card glassmorphism
                                ZStack {
                                    // Fondo con gradiente
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.blue.opacity(0.1),
                                                    Color.cyan.opacity(0.05)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )

                                    // Material ultrathink
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(.ultraThinMaterial)

                                    // Borde con gradiente
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.blue.opacity(0.4),
                                                    Color.cyan.opacity(0.2)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )

                                    // Contenido
                                    VStack(alignment: .leading, spacing: 20) {
                                        // Header con ícono
                                        HStack(spacing: 16) {
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [.blue, .cyan],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 60, height: 60)
                                                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 4)

                                                Image(systemName: "soccerball")
                                                    .font(.system(size: 28, weight: .semibold))
                                                    .foregroundColor(.white)
                                            }

                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack(spacing: 20) {
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text("16")
                                                            .font(.system(size: 32, weight: .bold))
                                                            .foregroundStyle(
                                                                LinearGradient(
                                                                    colors: [.blue, .cyan],
                                                                    startPoint: .leading,
                                                                    endPoint: .trailing
                                                                )
                                                            )
                                                        Text(L("menu.stadiums"))
                                                            .font(.system(size: 11, weight: .medium))
                                                            .foregroundColor(.secondary)
                                                    }

                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text("3")
                                                            .font(.system(size: 32, weight: .bold))
                                                            .foregroundStyle(
                                                                LinearGradient(
                                                                    colors: [.blue, .cyan],
                                                                    startPoint: .leading,
                                                                    endPoint: .trailing
                                                                )
                                                            )
                                                        Text(L("menu.countries"))
                                                            .font(.system(size: 11, weight: .medium))
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }

                                            Spacer()
                                        }

                                    // Botones de acción
                                    HStack(spacing: 12) {
                                        // Botón de explorar sedes
                                        Button(action: {
                                            closeDrawer()
                                            showVenuesView = true
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "map.fill")
                                                    .font(.system(size: 12, weight: .bold))
                                                Text(L("menu.exploreVenues"))
                                                    .font(.system(size: 13, weight: .semibold))
                                            }
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                LinearGradient(
                                                    colors: [Color.blue, Color.cyan],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .cornerRadius(12)
                                        }
                                        .buttonStyle(.plain)

                                        // Botón de reservar
                                        Button(action: {
                                            closeDrawer()
                                            // Esperar a que el drawer se cierre antes de mostrar el modal
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                                showScheduleModal = true
                                            }
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "ticket.fill")
                                                    .font(.system(size: 12, weight: .bold))
                                                Text(L("menu.reserve"))
                                                    .font(.system(size: 13, weight: .semibold))
                                            }
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                LinearGradient(
                                                    colors: [Color.blue, Color.cyan],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .cornerRadius(14)
                                            .shadow(color: Color.cyan.opacity(0.3), radius: 8, x: 0, y: 4)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    }
                                    .padding(24)
                                }
                                .shadow(color: Color.blue.opacity(0.15), radius: 20, x: 0, y: 8)
                                .padding(.horizontal, 20)
                            }

                            // Sección de Predicciones (colapsable)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Predicciones")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 20)

                                VStack(spacing: 0) {
                                    // Header colapsable
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            isPredictionsExpanded.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Text("Líneas del Metro")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.primary)

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.gray)
                                                .rotationEffect(.degrees(isPredictionsExpanded ? 90 : 0))
                                        }
                                        .padding(16)
                                        .background(.ultraThinMaterial)
                                    }
                                    .buttonStyle(.plain)

                                    // Opciones de líneas (expandible)
                                    if isPredictionsExpanded {
                                        VStack(spacing: 8) {
                                            // Línea 1 (Rosa) - ACTIVA
                                            MetroLineOption(lineNumber: 1, lineColor: Color(red: 0.95, green: 0.40, blue: 0.65), isEnabled: true) {
                                                closeDrawer()
                                                showLine1Simulation = true
                                            }

                                            // Línea 2 (Azul) - ACTIVA
                                            MetroLineOption(lineNumber: 2, lineColor: Color(red: 0.0, green: 0.35, blue: 0.87), isEnabled: true) {
                                                closeDrawer()
                                                showLine2Simulation = true
                                            }

                                            // Línea 3 (Verde Olivo) - ACTIVA
                                            MetroLineOption(lineNumber: 3, lineColor: Color(red: 0.67, green: 0.71, blue: 0.18), isEnabled: true) {
                                                closeDrawer()
                                                showLine3Simulation = true
                                            }

                                            // Línea 4 (Cian)
                                            MetroLineOption(lineNumber: 4, lineColor: Color(red: 0.4, green: 0.8, blue: 0.8), isEnabled: false)

                                            // Línea 5 (Amarillo)
                                            MetroLineOption(lineNumber: 5, lineColor: Color(red: 1.0, green: 0.85, blue: 0.0), isEnabled: false)

                                            // Línea 6 (Rojo)
                                            MetroLineOption(lineNumber: 6, lineColor: Color(red: 0.85, green: 0.1, blue: 0.1), isEnabled: false)

                                            // Línea 7 (Naranja)
                                            MetroLineOption(lineNumber: 7, lineColor: Color(red: 1.0, green: 0.5, blue: 0.0), isEnabled: false)

                                            // Línea 8 (Verde)
                                            MetroLineOption(lineNumber: 8, lineColor: Color(red: 0.0, green: 0.6, blue: 0.3), isEnabled: false)

                                            // Línea 9 (Café) - ACTIVA
                                            MetroLineOption(lineNumber: 9, lineColor: Color(red: 0.43, green: 0.27, blue: 0.08), isEnabled: true) {
                                                closeDrawer()
                                                showLine9Simulation = true
                                            }

                                            // Línea A (Morado)
                                            MetroLineOption(lineNumber: "A", lineColor: Color(red: 0.6, green: 0.2, blue: 0.8), isEnabled: false)

                                            // Línea B (Verde/Gris)
                                            MetroLineOption(lineNumber: "B", lineColor: Color(red: 0.5, green: 0.6, blue: 0.5), isEnabled: false)

                                            // Línea 12 (Dorado)
                                            MetroLineOption(lineNumber: 12, lineColor: Color(red: 0.8, green: 0.65, blue: 0.0), isEnabled: false)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 12)
                                        .background(.ultraThinMaterial)
                                    }
                                }
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                                .padding(.horizontal, 24)
                            }

                            // Sección de Staff (solo visible para administradores)
                            if userManager.hasStaffAccess {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Staff")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 24)
                                        .padding(.top, 20)

                                    Button(action: {
                                        closeDrawer()
                                        // Esperar a que el drawer se cierre antes de mostrar la vista
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                            showStaffView = true
                                        }
                                    }) {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.orange.opacity(0.2))
                                                    .frame(width: 40, height: 40)

                                                Image(systemName: "person.badge.key.fill")
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(.orange)
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Staff Access")
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(.primary)

                                                Text("Acceso especial para personal")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.gray)
                                        }
                                        .padding(16)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(16)
                                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 24)
                                }
                            }

                            // Botón de Log out - Rediseño ultrathink
                            VStack(alignment: .leading, spacing: 12) {
                                Button(action: {
                                    closeDrawer()
                                    // Esperar a que el drawer se cierre antes de hacer logout
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        onLogout?()
                                    }
                                }) {
                                    ZStack {
                                        // Fondo con gradiente rojo sutil
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color.red.opacity(0.08),
                                                        Color.orange.opacity(0.05)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )

                                        // Material ultrathink
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(.ultraThinMaterial)

                                        // Borde con gradiente rojo
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color.red.opacity(0.3),
                                                        Color.orange.opacity(0.2)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )

                                        // Contenido
                                        HStack(spacing: 16) {
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [Color.red, Color.orange],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 50, height: 50)
                                                    .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)

                                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                                    .font(.system(size: 20, weight: .semibold))
                                                    .foregroundColor(.white)
                                            }

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(L("menu.logout"))
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundStyle(
                                                        LinearGradient(
                                                            colors: [.red, .orange],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )

                                                Text(L("menu.logoutDescription"))
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.secondary)
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.secondary.opacity(0.5))
                                        }
                                        .padding(20)
                                    }
                                }
                                .buttonStyle(.plain)
                                .shadow(color: Color.red.opacity(0.1), radius: 15, x: 0, y: 5)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                            }

        }
        .padding(.bottom, 32)
    }

    private var drawerBackground: some View {
        ZStack {
            // Gradiente de fondo sutil
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.03),
                    Color.purple.opacity(0.02),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Material ultrathink
            Color.clear
                .background(.ultraThinMaterial)
        }
    }

    private var drawerBorder: some View {
        RoundedRectangle(cornerRadius: 32)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }

    private var overlayBackground: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                closeDrawer()
            }
    }

    private func closeDrawer() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            drawerOffset = 380
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Metro Line Option Component
struct MetroLineOption: View {
    let lineNumber: String  // String para soportar números y letras (A, B, 12, etc)
    let lineColor: Color
    let isEnabled: Bool
    let action: (() -> Void)?  // Acción opcional al hacer tap

    // Convenience init para números enteros
    init(lineNumber: Int, lineColor: Color, isEnabled: Bool, action: (() -> Void)? = nil) {
        self.lineNumber = "\(lineNumber)"
        self.lineColor = lineColor
        self.isEnabled = isEnabled
        self.action = action
    }

    // Init para strings (A, B)
    init(lineNumber: String, lineColor: Color, isEnabled: Bool, action: (() -> Void)? = nil) {
        self.lineNumber = lineNumber
        self.lineColor = lineColor
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: {
            if isEnabled, let action = action {
                action()
            }
        }) {
            HStack(spacing: 12) {
                // Círculo con el número de la línea
                ZStack {
                    Circle()
                        .fill(lineColor.opacity(isEnabled ? 1.0 : 0.3))
                        .frame(width: 40, height: 40)

                    Text(lineNumber)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                // Texto de la línea
                Text("Línea \(lineNumber)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isEnabled ? .primary : .secondary.opacity(0.5))

                Spacer()

                // Indicador de estado
                if isEnabled {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Activa")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.green)
                    }
                } else {
                    Text("Próximamente")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isEnabled ? lineColor.opacity(0.05) : Color.clear)
            .cornerRadius(12)
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || action == nil)
    }
}

// MARK: - Recommended Chip Model

struct RecommendedChip: Identifiable {
    let id: String
    let name: String
    let category: String  // Esta es la categoría para buscar
    let icon: String
    let color: Color
    let isCategory: Bool  // true = buscar por categoría, false = lugar específico
}

// MARK: - Marker Info Panel

struct MarkerInfoPanel: View {
    let marker: SearchPlace
    let distance: String?
    let estimatedTime: TimeInterval?
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Ícono del lugar
            ZStack {
                Circle()
                    .fill(marker.isRecommended ? Color.yellow.opacity(0.2) : Color.red.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: marker.icon)
                    .font(.system(size: 22))
                    .foregroundColor(marker.isRecommended ? .yellow : .red)
            }

            // Información del lugar
            VStack(alignment: .leading, spacing: 6) {
                Text(marker.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Text(marker.category)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                // Distancia y tiempo estimado
                HStack(spacing: 12) {
                    if let distance = distance {
                        HStack(spacing: 4) {
                            Image(systemName: "location.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text(distance)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }

                    if let time = estimatedTime {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                            Text(formatTravelTime(time))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }
                }
            }

            Spacer()

            // Botón de cerrar
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -5)
        )
        .padding(.horizontal, 20)
    }

    private func formatTravelTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        if minutes < 1 {
            return "< 1 min"
        } else if minutes == 1 {
            return "1 min"
        } else if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) h"
            } else {
                return "\(hours) h \(remainingMinutes) min"
            }
        }
    }
}

// MARK: - Chip Button Style
struct ChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? CGFloat(0.95) : CGFloat(1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Rainbow Border Capsule (World Cup celebration)
struct RainbowBorderCapsule: View {
    @State private var rotation: Double = 0

    private let rainbowColors: [Color] = [
        .red,
        .orange,
        .yellow,
        .green,
        .blue,
        .purple,
        .pink,
        .red
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main rotating rainbow gradient border
                Capsule(style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: rainbowColors,
                            center: .center,
                            startAngle: .degrees(rotation),
                            endAngle: .degrees(rotation + 360)
                        ),
                        lineWidth: 2.5
                    )

                // Outer glow effect
                Capsule(style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: rainbowColors.map { $0.opacity(0.5) },
                            center: .center,
                            startAngle: .degrees(rotation + 30),
                            endAngle: .degrees(rotation + 390)
                        ),
                        lineWidth: 3
                    )
                    .blur(radius: 4)
                    .scaleEffect(CGFloat(1.02))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Rainbow Border Rounded Rectangle (World Cup celebration)
struct RainbowBorderRounded: View {
    let cornerRadius: CGFloat
    @State private var rotation: Double = 0

    private let rainbowColors: [Color] = [
        .red,
        .orange,
        .yellow,
        .green,
        .blue,
        .purple,
        .pink,
        .red
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main rotating rainbow gradient border
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: rainbowColors,
                            center: .center,
                            startAngle: .degrees(rotation),
                            endAngle: .degrees(rotation + 360)
                        ),
                        lineWidth: 2.5
                    )

                // Outer glow effect
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: rainbowColors.map { $0.opacity(0.5) },
                            center: .center,
                            startAngle: .degrees(rotation + 30),
                            endAngle: .degrees(rotation + 390)
                        ),
                        lineWidth: 3
                    )
                    .blur(radius: 4)
                    .scaleEffect(CGFloat(1.02))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Pulsing Star Modifier (World Cup celebration)
struct PulsingStarModifier: ViewModifier {
    let delay: Double
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? CGFloat(1.3) : CGFloat(0.8))
            .opacity(isAnimating ? 1.0 : 0.3)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    isAnimating = true
                }
            }
    }
}
