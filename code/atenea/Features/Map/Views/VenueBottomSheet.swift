//
//  VenueBottomSheet.swift
//  atenea
//
//  Bottom sheet deslizable para mostrar reservaciones de sedes del Mundial
//

import SwiftUI
import CoreLocation

// MARK: - Sheet States
enum SheetState {
    case hidden
    case collapsed
    case partial
    case expanded

    func height(for geometry: GeometryProxy, hasReservations: Bool = true) -> CGFloat {
        switch self {
        case .hidden: return 0
        case .collapsed: return 164  // Altura original
        case .partial: return hasReservations ? 400 : 520  // Más alto cuando no hay reservaciones
        case .expanded: return geometry.size.height - 100
        }
    }
}

// MARK: - Reservation Status
enum ReservationStatus: String, Codable {
    case confirmed = "confirmed"
    case pending = "pending"
    case cancelled = "cancelled"

    var color: Color {
        switch self {
        case .confirmed: return .green
        case .pending: return .orange
        case .cancelled: return .red
        }
    }

    var text: String {
        switch self {
        case .confirmed: return LocalizedString("status.confirmed")
        case .pending: return LocalizedString("status.pending")
        case .cancelled: return LocalizedString("status.cancelled")
        }
    }
}

// MARK: - Venue Reservation Model
struct VenueReservation: Identifiable, Codable {
    let id: UUID
    let venueName: String
    let venueCity: String
    let date: Date
    let seatNumber: String
    let status: String

    // Helper para crear desde WorldCupVenue
    init(id: UUID = UUID(), venue: WorldCupVenue, date: Date, seatNumber: String, status: ReservationStatus) {
        self.id = id
        self.venueName = venue.name
        self.venueCity = venue.city
        self.date = date
        self.seatNumber = seatNumber
        self.status = status.rawValue
    }

    // Init directo para Codable
    init(id: UUID = UUID(), venueName: String, venueCity: String, date: Date, seatNumber: String, status: String) {
        self.id = id
        self.venueName = venueName
        self.venueCity = venueCity
        self.date = date
        self.seatNumber = seatNumber
        self.status = status
    }

    var statusColor: Color {
        switch status {
        case "confirmed": return .green
        case "pending": return .orange
        case "cancelled": return .red
        default: return .blue
        }
    }

    var statusText: String {
        switch status {
        case "confirmed": return LocalizedString("status.confirmed")
        case "pending": return LocalizedString("status.pending")
        case "cancelled": return LocalizedString("status.cancelled")
        default: return LocalizedString("status.unknown")
        }
    }
}

// MARK: - Draggable Bottom Sheet
struct VenueBottomSheet: View {
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject var locationManager: LocationManager
    @Binding var reservations: [VenueReservation]
    @Binding var sheetHeight: CGFloat  // Para comunicar la altura al parent
    @Binding var sheetState: SheetState  // Para controlar el estado desde el parent
    var onCreateReservation: (() -> Void)?

    @State private var currentHeight: CGFloat = 164
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Indicador de arrastre (solo visible en partial y expanded)
                    if sheetState == .partial || sheetState == .expanded {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 40, height: 5)
                            .padding(.top, 8)
                            .padding(.bottom, 12)
                    }

                    // Contenido según el estado
                    if sheetState == .hidden {
                        // Estado oculto - no mostrar contenido
                        EmptyView()
                    } else if sheetState == .collapsed {
                        CollapsedSheetView(locationManager: locationManager, reservations: reservations)
                            .padding(.vertical, 12)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    sheetState = .partial
                                    currentHeight = sheetState.height(for: geometry, hasReservations: !reservations.isEmpty)
                                }
                            }
                    } else {
                        ExpandedSheetView(
                            locationManager: locationManager,
                            sheetState: $sheetState,
                            reservations: $reservations,
                            geometry: geometry,
                            onCreateReservation: onCreateReservation
                        )
                    }

                    Spacer(minLength: 0)
                }
                .frame(height: max(0, currentHeight + dragOffset))
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .cornerRadius(30, corners: [.topLeft, .topRight])
                .clipped()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: -5)
                .opacity(sheetState == .hidden ? 0 : 1)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation.height
                        }
                        .onEnded { value in
                            let snapDistance = value.translation.height
                            handleDragEnd(translation: snapDistance, geometry: geometry)
                        }
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentHeight)
                .animation(.easeInOut(duration: 0.3), value: sheetState)
                .onChange(of: sheetState) { oldState, newState in
                    currentHeight = newState.height(for: geometry, hasReservations: !reservations.isEmpty)
                    sheetHeight = currentHeight  // Actualizar binding
                }
                .onChange(of: currentHeight) { oldValue, newValue in
                    sheetHeight = newValue  // Actualizar binding durante el drag
                }
                .onAppear {
                    currentHeight = sheetState.height(for: geometry, hasReservations: !reservations.isEmpty)
                }
                .id(languageManager.currentLanguage) // Force re-render when language changes
            }
        }
    }

    private func handleDragEnd(translation: CGFloat, geometry: GeometryProxy) {
        let velocityThreshold: CGFloat = 100

        // Deslizar hacia arriba (expandir) - translation negativo
        if translation < -velocityThreshold {
            if sheetState == .hidden {
                sheetState = .collapsed
                currentHeight = sheetState.height(for: geometry, hasReservations: !reservations.isEmpty)
            } else if sheetState == .collapsed {
                sheetState = .partial
                currentHeight = sheetState.height(for: geometry, hasReservations: !reservations.isEmpty)
            } else if sheetState == .partial {
                sheetState = .expanded
                currentHeight = sheetState.height(for: geometry, hasReservations: !reservations.isEmpty)
            }
        }
        // Deslizar hacia abajo (colapsar/ocultar) - translation positivo
        else if translation > velocityThreshold {
            if sheetState == .expanded {
                sheetState = .partial
                currentHeight = sheetState.height(for: geometry, hasReservations: !reservations.isEmpty)
            } else if sheetState == .partial {
                sheetState = .collapsed
                currentHeight = sheetState.height(for: geometry, hasReservations: !reservations.isEmpty)
            } else if sheetState == .collapsed {
                sheetState = .hidden
                currentHeight = sheetState.height(for: geometry, hasReservations: !reservations.isEmpty)
            }
        }
        // Ajustar según posición actual
        else {
            snapToNearestState(geometry: geometry)
        }
    }

    private func snapToNearestState(geometry: GeometryProxy) {
        let hasReservations = !reservations.isEmpty
        let hiddenHeight = SheetState.hidden.height(for: geometry, hasReservations: hasReservations)
        let collapsedHeight = SheetState.collapsed.height(for: geometry, hasReservations: hasReservations)
        let partialHeight = SheetState.partial.height(for: geometry, hasReservations: hasReservations)
        let expandedHeight = SheetState.expanded.height(for: geometry, hasReservations: hasReservations)

        let hiddenDistance = abs(currentHeight - hiddenHeight)
        let collapsedDistance = abs(currentHeight - collapsedHeight)
        let partialDistance = abs(currentHeight - partialHeight)
        let expandedDistance = abs(currentHeight - expandedHeight)

        let minDistance = min(hiddenDistance, collapsedDistance, partialDistance, expandedDistance)

        if minDistance == hiddenDistance {
            sheetState = .hidden
            currentHeight = hiddenHeight
        } else if minDistance == collapsedDistance {
            sheetState = .collapsed
            currentHeight = collapsedHeight
        } else if minDistance == partialDistance {
            sheetState = .partial
            currentHeight = partialHeight
        } else {
            sheetState = .expanded
            currentHeight = expandedHeight
        }
    }
}

// MARK: - Collapsed Sheet View
struct CollapsedSheetView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject var locationManager: LocationManager
    let reservations: [VenueReservation]

    @State private var locationName: String = ""
    @State private var countryName: String = ""

    var body: some View {
        HStack(spacing: 12) {
            // Ícono según contenido
            Circle()
                .fill(hasActiveReservation ? Color.green : Color.blue)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: hasActiveReservation ? "ticket.fill" : "mappin.circle.fill")
                        .font(.system(size: CGFloat(20)))
                        .foregroundColor(.white)
                )

            // Información
            if let nextReservation = nextActiveReservation {
                // Mostrar próxima reservación
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(LocalizedString("reservation.next"))
                            .font(.system(size: CGFloat(12)))
                            .foregroundColor(.gray)

                        // Badge de estado
                        Text(nextReservation.statusText)
                            .font(.system(size: CGFloat(10), weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(nextReservation.statusColor)
                            .cornerRadius(8)
                    }

                    Text(nextReservation.venueName)
                        .font(.system(size: CGFloat(14), weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(shortDate(for: nextReservation.date))
                        .font(.system(size: CGFloat(11)))
                        .foregroundColor(.gray)
                }
            } else {
                // Mostrar ubicación
                VStack(alignment: .leading, spacing: 4) {
                    Text(locationName.isEmpty ? LocalizedString("location.loading") : locationName)
                        .font(.system(size: CGFloat(16), weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if locationManager.currentLocation != nil {
                        Text(countryName)
                            .font(.system(size: CGFloat(11)))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    } else {
                        Text(LocalizedString("location.enable"))
                            .font(.system(size: CGFloat(11)))
                            .foregroundColor(.gray)
                    }
                }
                .onAppear {
                    fetchLocationName()
                }
                .onChange(of: locationManager.currentLocation) { oldValue, newValue in
                    if newValue != nil {
                        fetchLocationName()
                    }
                }
                .onChange(of: languageManager.currentLanguage) { _, _ in
                    // Re-fetch location name when language changes
                    fetchLocationName()
                }
            }

            Spacer()

            // Indicador de que se puede expandir
            Image(systemName: "chevron.up")
                .font(.system(size: CGFloat(14), weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private var hasActiveReservation: Bool {
        !reservations.filter { $0.status != "cancelled" }.isEmpty
    }

    private var nextActiveReservation: VenueReservation? {
        reservations
            .filter { $0.status != "cancelled" }
            .sorted { $0.date < $1.date }
            .first
    }

    private func fetchLocationName() {
        guard let location = locationManager.currentLocation else {
            locationName = LocalizedString("map.locationDisabled")
            countryName = ""
            return
        }

        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let geocoder = CLGeocoder()

        geocoder.reverseGeocodeLocation(clLocation) { placemarks, error in
            if let error = error {
                print("Error en geocoding: \(error.localizedDescription)")
                locationName = LocalizedString("location.defaultCity")
                countryName = LocalizedString("location.defaultCountry")
                return
            }

            if let placemark = placemarks?.first {
                // Obtener el nombre más específico disponible
                if let locality = placemark.locality {
                    // Nombre de la ciudad
                    locationName = locality
                } else if let subLocality = placemark.subLocality {
                    // Colonia o distrito
                    locationName = subLocality
                } else if let administrativeArea = placemark.administrativeArea {
                    // Estado
                    locationName = administrativeArea
                } else {
                    locationName = LocalizedString("location.current")
                }

                // Obtener el país
                if let country = placemark.country {
                    countryName = country
                } else {
                    countryName = ""
                }
            }
        }
    }

    private func shortDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, HH:mm"
        // Use app language instead of system language
        formatter.locale = Locale(identifier: languageManager.currentLanguage)
        return formatter.string(from: date)
    }
}

// MARK: - Expanded Sheet View
struct ExpandedSheetView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject var locationManager: LocationManager
    @Binding var sheetState: SheetState
    @Binding var reservations: [VenueReservation]
    let geometry: GeometryProxy
    var onCreateReservation: (() -> Void)?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedString("reservation.myReservations"))
                            .font(.system(size: CGFloat(24), weight: .bold))
                            .foregroundColor(.white)
                        Text(String(format: LocalizedString("reservation.activeCount"), reservations.count))
                            .font(.system(size: CGFloat(14)))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            sheetState = .collapsed
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: CGFloat(24)))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Lista de reservaciones
                if reservations.isEmpty {
                    EmptyReservationsView(onCreateReservation: onCreateReservation)
                } else {
                    ForEach(reservations) { reservation in
                        ReservationCard(reservation: reservation)
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Empty Reservations View
struct EmptyReservationsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    var onCreateReservation: (() -> Void)?

    var body: some View {
        Button(action: {
            onCreateReservation?()
        }) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: CGFloat(50)))
                        .foregroundColor(.blue)
                }

                Text(LocalizedString("reservation.empty"))
                    .font(.system(size: CGFloat(18), weight: .semibold))
                    .foregroundColor(.white)

                Text(LocalizedString("reservation.emptyDescription"))
                    .font(.system(size: CGFloat(14)))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                // Call to action
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text(LocalizedString("profile.scheduleMatch"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                .padding(.top, 8)
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reservation Card
struct ReservationCard: View {
    @EnvironmentObject var languageManager: LanguageManager
    let reservation: VenueReservation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Ícono de la sede con gradiente
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue,
                                Color.purple
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "soccerball")
                            .font(.system(size: CGFloat(24)))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(reservation.venueName)
                        .font(.system(size: CGFloat(16), weight: .semibold))
                        .foregroundColor(.white)

                    Text(reservation.venueCity)
                        .font(.system(size: CGFloat(14)))
                        .foregroundColor(.gray)
                }

                Spacer()

                // Estado
                Text(reservation.statusText)
                    .font(.system(size: CGFloat(12), weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(reservation.statusColor)
                    )
            }

            Divider()
                .background(Color.gray.opacity(0.3))

            // Información del partido
            HStack(spacing: 20) {
                InfoItem(icon: "calendar", text: formattedDate)
                InfoItem(icon: "chair.fill", text: String(format: LocalizedString("reservation.seat"), reservation.seatNumber))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal, 20)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        // Use app language instead of system language
        formatter.locale = Locale(identifier: languageManager.currentLanguage)
        return formatter.string(from: reservation.date)
    }
}

// MARK: - Info Item
struct InfoItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: CGFloat(14)))
                .foregroundColor(.gray)
            Text(text)
                .font(.system(size: CGFloat(13)))
                .foregroundColor(.white)
        }
    }
}
