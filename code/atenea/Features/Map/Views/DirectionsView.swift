//
//  DirectionsView.swift
//  atenea
//
//  Panel de direcciones con múltiples modos de transporte y rutas
//

import SwiftUI
import MapKit
import MapboxNavigationCore

// MARK: - Transport Mode

enum TransportMode: String, CaseIterable {
    case driving = "car.fill"
    case walking = "figure.walk"
    case transit = "tram.fill"
    case cycling = "bicycle"
    case rideshare = "figure.wave"

    var title: String {
        switch self {
        case .driving: return LocalizedString("transport.drive")
        case .walking: return LocalizedString("transport.walk")
        case .transit: return LocalizedString("transport.transit")
        case .cycling: return LocalizedString("transport.cycle")
        case .rideshare: return LocalizedString("transport.ride")
        }
    }

    var mkDirectionsType: MKDirectionsTransportType? {
        switch self {
        case .driving: return .automobile
        case .walking: return .walking
        case .transit: return .transit
        default: return nil
        }
    }
}

// MARK: - Route Info

struct RouteInfo: Identifiable, Equatable {
    let id = UUID()
    let mode: TransportMode
    let duration: TimeInterval
    let distance: CLLocationDistance
    let route: MKRoute?
    let isFastest: Bool

    var durationText: String {
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return "\(hours)h \(remainingMinutes)min"
        } else {
            return "\(minutes) min"
        }
    }

    var distanceText: String {
        let kilometers = distance / 1000
        return String(format: "%.1f km", kilometers)
    }

    static func == (lhs: RouteInfo, rhs: RouteInfo) -> Bool {
        return lhs.id == rhs.id &&
               lhs.mode == rhs.mode &&
               lhs.duration == rhs.duration &&
               lhs.distance == rhs.distance &&
               lhs.isFastest == rhs.isFastest
    }
}

// MARK: - Modal Height State

enum DirectionsModalHeight {
    case quarter  // 25%
    case half     // 50%
    case full     // 92%

    func height(for geometry: GeometryProxy) -> CGFloat {
        switch self {
        case .quarter:
            return geometry.size.height * 0.25
        case .half:
            return geometry.size.height * 0.5
        case .full:
            return geometry.size.height * 0.92
        }
    }
}

// MARK: - Directions View

struct DirectionsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var isPresented: Bool
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let destinationName: String

    @Binding var routePolylines: [MKPolyline]
    @Binding var selectedRouteIndex: Int
    @Binding var selectedTransportMode: TransportMode
    var onClose: (() -> Void)? = nil

    @StateObject private var viewModel: DirectionsViewModel
    @State private var selectedMode: TransportMode = .driving
    @State private var showTripStarted: Bool = false

    // Navigation State
    @State private var preparedNavigation: PreparedNavigation? = nil
    @State private var showNavigation: Bool = false
    @State private var isLoadingNavigation: Bool = false

    // Modal Height Management
    @State private var modalHeight: DirectionsModalHeight = .half
    @GestureState private var dragOffset: CGFloat = 0

    init(
        isPresented: Binding<Bool>,
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        destinationName: String,
        routePolylines: Binding<[MKPolyline]> = .constant([]),
        selectedRouteIndex: Binding<Int> = .constant(0),
        selectedTransportMode: Binding<TransportMode> = .constant(.driving),
        onClose: (() -> Void)? = nil
    ) {
        self._isPresented = isPresented
        self.origin = origin
        self.destination = destination
        self.destinationName = destinationName
        self._routePolylines = routePolylines
        self._selectedRouteIndex = selectedRouteIndex
        self._selectedTransportMode = selectedTransportMode
        self.onClose = onClose
        self._viewModel = StateObject(wrappedValue: DirectionsViewModel(origin: origin, destination: destination))
    }

    var body: some View {
        directionsContent
            .fullScreenCover(isPresented: $showTripStarted) {
                if let routeInfo = viewModel.routes[selectedMode] {
                    TripStartedView(
                        isPresented: $showTripStarted,
                        destination: destinationName,
                        destinationCoordinate: destination,
                        route: routeInfo,
                        onEndTrip: endTrip,
                        onStartNavigation: handleStartNavigation
                    )
                }
            }
            .fullScreenCover(isPresented: $showNavigation) {
                if let preparedNav = preparedNavigation {
                    NavigationViewWrapper(
                        preparedNavigation: preparedNav,
                        onCancel: {
                            showNavigation = false
                            preparedNavigation = nil
                            isPresented = false
                        }
                    )
                    .ignoresSafeArea(.all) // Pantalla completa verdadera
                }
            }
            .overlay {
                if isLoadingNavigation {
                    ZStack {
                        Color.black.opacity(0.6)
                            .ignoresSafeArea(.all)

                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5 as CGFloat)
                                .tint(.white)

                            Text(LocalizedString("directions.preparingNavigation"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(40)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(white: 0.15))
                                .shadow(color: .black.opacity(0.5), radius: 20)
                        )
                    }
                    .transition(.opacity)
                }
            }
    }

    private var directionsContent: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    Spacer()

                    // Panel de direcciones
                    VStack(spacing: 0) {
                        // Handle mejorado
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.5),
                                            Color.white.opacity(0.3)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 50, height: 5)
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                            .contentShape(Rectangle().size(width: geometry.size.width, height: 30))
                            .gesture(
                                DragGesture()
                                    .updating($dragOffset) { value, state, _ in
                                        state = value.translation.height
                                    }
                                    .onEnded { value in
                                        handleDragEnded(value: value, geometry: geometry)
                                    }
                            )

                        // Header (fijo, fuera del scroll)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(LocalizedString("directions.title"))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)

                                if let routeInfo = viewModel.routes[selectedMode] {
                                    HStack(spacing: 6) {
                                        Image(systemName: "clock.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.blue)
                                        Text(routeInfo.durationText)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.blue)

                                        Circle()
                                            .fill(Color.white.opacity(0.4))
                                            .frame(width: 4, height: 4)

                                        Image(systemName: "arrow.triangle.swap")
                                            .font(.system(size: 12))
                                            .foregroundColor(.green)
                                        Text(routeInfo.distanceText)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.green)
                                    }
                                }
                            }

                            Spacer()

                            Button(action: {
                                onClose?()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    isPresented = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .padding(.top, 8)

                        // Contenido scrolleable con altura calculada
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(spacing: 0) {

                                // Botones de modo de transporte
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(TransportMode.allCases, id: \.self) { mode in
                                            TransportModeButton(
                                                mode: mode,
                                                isSelected: selectedMode == mode,
                                                routeInfo: viewModel.routes[mode]
                                            ) {
                                                selectedMode = mode
                                                selectedTransportMode = mode
                                                updateRoutesForMode(mode)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .padding(.bottom, 20)

                                // Selector de rutas alternativas
                                if viewModel.allRoutes.count > 1 {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "road.lanes")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.blue)

                                            Text(LocalizedString("directions.chooseRoute"))
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)

                                            Spacer()

                                            Text(String(format: LocalizedString("directions.optionsCount"), viewModel.allRoutes.count))
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                        .padding(.horizontal, 20)

                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 12) {
                                                ForEach(Array(viewModel.allRoutes.enumerated()), id: \.offset) { index, route in
                                                    RouteOptionCard(
                                                        index: index,
                                                        route: route,
                                                        isSelected: viewModel.selectedRouteIndex == index
                                                    ) {
                                                        viewModel.selectRoute(at: index)
                                                        selectedRouteIndex = index
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                        }
                                    }
                                    .padding(.bottom, 16)
                                }

                                // Lista de ubicaciones
                                VStack(spacing: 0) {
                                    // Origen
                                    LocationRow(
                                        icon: "location.fill",
                                        iconColor: .blue,
                                        title: LocalizedString("location.myLocation"),
                                        isOrigin: true
                                    )

                                    // Línea conectora animada
                                    HStack {
                                        ZStack {
                                            // Línea de fondo
                                            Rectangle()
                                                .fill(Color.white.opacity(0.15))
                                                .frame(width: 3, height: 40)

                                            // Puntos animados (decoración)
                                            VStack(spacing: 6) {
                                                ForEach(0..<3, id: \.self) { _ in
                                                    Circle()
                                                        .fill(Color.white.opacity(0.3))
                                                        .frame(width: 4, height: 4)
                                                }
                                            }
                                        }
                                        .padding(.leading, 35)

                                        Spacer()
                                    }

                                    // Destino
                                    LocationRow(
                                        icon: "mappin.circle.fill",
                                        iconColor: .orange,
                                        title: destinationName,
                                        isOrigin: false
                                    )
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(white: 0.12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)

                                // Información de la ruta seleccionada
                                if let routeInfo = viewModel.routes[selectedMode] {
                                    RouteDetailView(routeInfo: routeInfo)
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 20)
                                } else if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .padding(.bottom, 20)
                                }

                                // Botón GO
                                Button(action: {
                                    startNavigation()
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 20, weight: .bold))

                                        Text(LocalizedString("directions.go"))
                                            .font(.system(size: 18, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 64)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "#10b981"),
                                                Color(hex: "#059669")
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .shadow(
                                        color: Color(hex: "#10b981").opacity(0.4),
                                        radius: 15,
                                        x: 0,
                                        y: 8
                                    )
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .padding(.bottom, 80)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: modalHeight.height(for: geometry) - dragOffset)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#0f0f0f"),
                                Color(hex: "#1a1a1a")
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                    .shadow(
                        color: Color.black.opacity(0.5),
                        radius: 30,
                        x: 0,
                        y: -10
                    )
                }
            }
        }
        .onAppear {
            viewModel.calculateRoutes()
        }
        .onChange(of: viewModel.selectedRouteIndex) { newIndex in
            selectedRouteIndex = newIndex
            print("🎯 Ruta seleccionada: \(newIndex)")
        }
        .onChange(of: viewModel.routes[selectedMode]) { newRoute in
            // Cuando la ruta del modo seleccionado esté lista, actualizarla
            if let routeInfo = newRoute, let route = routeInfo.route {
                routePolylines = [route.polyline]
                selectedRouteIndex = 0
                print("✅ Ruta para \(selectedMode.title) calculada y actualizada")
            }
        }
        .id(languageManager.currentLanguage) // Force re-render when language changes
    }

    // MARK: - Update Routes for Mode

    private func updateRoutesForMode(_ mode: TransportMode) {
        // Actualizar las rutas mostradas basado en el modo seleccionado
        if let routeInfo = viewModel.routes[mode] {
            // Si hay una ruta para este modo, mostrarla
            if let route = routeInfo.route {
                routePolylines = [route.polyline]
                selectedRouteIndex = 0
                print("🚗 Modo de transporte cambiado a: \(mode.title) - Ruta cargada")
            }
        } else {
            // Si no hay ruta para este modo todavía, mantener las rutas anteriores visibles
            // Las rutas se actualizarán automáticamente cuando el cálculo termine
            print("⏳ Modo de transporte cambiado a: \(mode.title) - Calculando ruta...")
        }
    }

    // MARK: - Drag Handling

    private func handleDragEnded(value: DragGesture.Value, geometry: GeometryProxy) {
        let translation = value.translation.height
        let velocity = value.predictedEndTranslation.height - value.translation.height

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if translation > 100 || velocity > 500 {
                switch modalHeight {
                case .full:
                    modalHeight = .half
                case .half:
                    modalHeight = .quarter
                case .quarter:
                    break
                }
            } else if translation < -100 || velocity < -500 {
                switch modalHeight {
                case .quarter:
                    modalHeight = .half
                case .half:
                    modalHeight = .full
                case .full:
                    break
                }
            }
        }
    }

    // MARK: - Navigation Actions

    private func startNavigation() {
        // Mostrar vista de Trip Started primero
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showTripStarted = true
        }
    }

    private func endTrip() {
        // Cerrar vista de trip started y volver al mapa
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showTripStarted = false
            isPresented = false
        }
    }

    private func handleStartNavigation() {
        // Cerrar Trip Started inmediatamente para mejor UX
        withAnimation(.easeOut(duration: 0.25)) {
            showTripStarted = false
            isLoadingNavigation = true
        }

        // Cargar navegación desde origen hasta destino en segundo plano
        Task {
            do {
                print("🚀 Cargando navegación...")
                let preparedNav = try await NavigationLoader.shared.loadNavigation(
                    from: origin,
                    to: destination
                )

                // Actualizar en el main thread
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.25)) {
                        preparedNavigation = preparedNav
                        isLoadingNavigation = false
                    }
                    // Mostrar navegación sin animación para evitar glitches
                    showNavigation = true
                }

            } catch {
                print("❌ Error loading navigation: \(error.localizedDescription)")
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.25)) {
                        isLoadingNavigation = false
                        // Mostrar error al usuario
                        showTripStarted = true // Volver a mostrar TripStarted si hay error
                    }
                }
            }
        }
    }
}

// MARK: - Transport Mode Button

struct TransportModeButton: View {
    let mode: TransportMode
    let isSelected: Bool
    let routeInfo: RouteInfo?
    let action: () -> Void

    var modeColor: Color {
        switch mode {
        case .driving: return .blue
        case .walking: return .green
        case .transit: return .orange
        case .cycling: return .purple
        case .rideshare: return .pink
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Icono
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(modeColor.opacity(0.2))
                            .frame(width: 44, height: 44)
                    }

                    Image(systemName: mode.rawValue)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isSelected ? modeColor : .white.opacity(0.6))
                }

                // Texto
                if let info = routeInfo {
                    Text(info.durationText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                } else {
                    Text(mode.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                }
            }
            .frame(width: 80, height: 90)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ?
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(white: 0.22),
                                Color(white: 0.18)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(white: 0.15),
                                Color(white: 0.12)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? modeColor.opacity(0.5) : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? modeColor.opacity(0.3) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Location Row

struct LocationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let isOrigin: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Icono con círculo de fondo
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            // Texto
            VStack(alignment: .leading, spacing: 4) {
                Text(isOrigin ? LocalizedString("directions.from") : LocalizedString("directions.to"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .kerning(0.5)

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            Spacer()

            // Botón de opciones (opcional, comentado por ahora)
            // Button(action: {
            //     // Opciones de ubicación
            // }) {
            //     Image(systemName: "ellipsis")
            //         .font(.system(size: 16, weight: .semibold))
            //         .foregroundColor(.white.opacity(0.4))
            //         .frame(width: 32, height: 32)
            // }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Route Detail View

struct RouteDetailView: View {
    let routeInfo: RouteInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Info principal
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                // Tiempo
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)

                    Text(routeInfo.durationText)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }

                // Distancia
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 14))
                        .foregroundColor(.green)

                    Text(routeInfo.distanceText)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                // Badge fastest
                if routeInfo.isFastest {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11))
                        Text(LocalizedString("directions.fastest"))
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.15))
                    )
                }
            }

            // Info adicional
            HStack(spacing: 16) {
                // Zona de bajas emisiones
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.green)

                    Text(LocalizedString("directions.lowEmission"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Tráfico (opcional)
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)

                    Text(LocalizedString("directions.normalTraffic"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(white: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Route Option Card

struct RouteOptionCard: View {
    let index: Int
    let route: RouteInfo
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                // Header con número de ruta y badge
                HStack(spacing: 8) {
                    // Número de ruta con círculo
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                            .frame(width: 28, height: 28)

                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isSelected ? .blue : .white.opacity(0.7))
                    }

                    if route.isFastest {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 9))
                            Text(LocalizedString("directions.fastest").uppercased())
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.15))
                        )
                    }

                    Spacer()
                }

                // Tiempo
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(route.durationText)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.8))

                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .blue : .white.opacity(0.5))
                }

                // Distancia
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))

                    Text(route.distanceText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(16)
            .frame(width: 160)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ?
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.3),
                                Color.blue.opacity(0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(white: 0.2),
                                Color(white: 0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                isSelected ? Color.blue.opacity(0.6) : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? Color.blue.opacity(0.3) : .clear,
                radius: 10,
                x: 0,
                y: 5
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
