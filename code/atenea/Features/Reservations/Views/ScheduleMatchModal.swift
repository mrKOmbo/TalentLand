//
//  ScheduleMatchModal.swift
//  atenea
//
//  Modal para agendar partidos y crear reservaciones de sedes del Mundial
//

import SwiftUI

// MARK: - Scheduled Match Model
struct ScheduledMatch: Identifiable {
    let id = UUID()
    var venue: String
    var seats: String
    var date: Date
    var status: String

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Schedule Match Modal
struct ScheduleMatchModal: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var isPresented: Bool
    var onMatchScheduled: ((ScheduledMatch) -> Void)? = nil

    @State private var selectedVenue = "Estadio Azteca - México"
    @State private var selectedSeats = ""
    @State private var selectedDate = Date()
    @State private var selectedStatus = "confirmed"
    @State private var isVenueExpanded = false
    @State private var isStatusExpanded = false
    @State private var showSuccessAlert = false
    @State private var createdMatch: ScheduledMatch?

    let venues = [
        "Estadio Azteca - México",
        "Estadio BBVA - Monterrey",
        "Estadio Akron - Guadalajara",
        "SoFi Stadium - Los Ángeles",
        "MetLife Stadium - Nueva York",
        "AT&T Stadium - Dallas",
        "Arrowhead Stadium - Kansas City",
        "Mercedes-Benz Stadium - Atlanta",
        "Lumen Field - Seattle",
        "Levi's Stadium - San Francisco",
        "BMO Field - Toronto",
        "BC Place - Vancouver"
    ]

    var statusOptions: [(String, String)] {
        [
            ("confirmed", LocalizedString("status.confirmed")),
            ("pending", LocalizedString("status.pending")),
            ("cancelled", LocalizedString("status.cancelled")),
            ("waiting", LocalizedString("status.waiting"))
        ]
    }

    // Helper para obtener strings localizados
    private func L(_ key: String) -> String {
        return languageManager.localizedString(key)
    }

    var body: some View {
        ZStack {
            // Fondo oscuro
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }

            // Contenedor del modal
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Header con botón de cerrar
                    HStack {
                        Text(L("profile.scheduleMatch"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                isPresented = false
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 36, height: 36)

                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                    Divider()
                        .background(Color.white.opacity(0.2))

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Descripción
                            Text(L("profile.completeData"))
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.top, 16)

                            // Formulario
                            VStack(spacing: 16) {
                                // Selector de Estadio
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(L("profile.venue"))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))

                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            isVenueExpanded.toggle()
                                            if isVenueExpanded {
                                                isStatusExpanded = false
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "building.2.fill")
                                                .foregroundColor(.blue)

                                            Text(selectedVenue)
                                                .font(.system(size: 15))
                                                .foregroundColor(.white)

                                            Spacer()

                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.5))
                                                .rotationEffect(.degrees(isVenueExpanded ? 180 : 0))
                                        }
                                        .padding(14)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    if isVenueExpanded {
                                        VStack(spacing: 4) {
                                            ForEach(venues, id: \.self) { venue in
                                                Button(action: {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        selectedVenue = venue
                                                        isVenueExpanded = false
                                                    }
                                                }) {
                                                    HStack {
                                                        Text(venue)
                                                            .font(.system(size: 14))
                                                            .foregroundColor(selectedVenue == venue ? .blue : .white)

                                                        Spacer()

                                                        if selectedVenue == venue {
                                                            Image(systemName: "checkmark")
                                                                .font(.system(size: 12, weight: .bold))
                                                                .foregroundColor(.blue)
                                                        }
                                                    }
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 10)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(selectedVenue == venue ? Color.blue.opacity(0.15) : Color.white.opacity(0.05))
                                                    )
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .padding(.top, 4)
                                    }
                                }

                                // Campo de Asientos
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(L("profile.seats"))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))

                                    HStack {
                                        Image(systemName: "chair.fill")
                                            .foregroundColor(.blue)

                                        TextField(L("profile.seatsPlaceholder"), text: $selectedSeats)
                                            .font(.system(size: 15))
                                            .foregroundColor(.white)
                                            .tint(.blue)
                                    }
                                    .padding(14)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                }

                                // Selector de Fecha
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(L("profile.dateTime"))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))

                                    DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                        .tint(.blue)
                                        .padding(14)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(12)
                                }

                                // Selector de Estado
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(L("profile.status"))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))

                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            isStatusExpanded.toggle()
                                            if isStatusExpanded {
                                                isVenueExpanded = false
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: statusIcon(for: selectedStatus))
                                                .foregroundColor(statusColor(for: selectedStatus))

                                            Text(statusDisplayName(for: selectedStatus))
                                                .font(.system(size: 15))
                                                .foregroundColor(.white)

                                            Spacer()

                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.5))
                                                .rotationEffect(.degrees(isStatusExpanded ? 180 : 0))
                                        }
                                        .padding(14)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    if isStatusExpanded {
                                        VStack(spacing: 4) {
                                            ForEach(statusOptions, id: \.0) { status in
                                                Button(action: {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        selectedStatus = status.0
                                                        isStatusExpanded = false
                                                    }
                                                }) {
                                                    HStack {
                                                        Image(systemName: statusIcon(for: status.0))
                                                            .foregroundColor(statusColor(for: status.0))

                                                        Text(status.1)
                                                            .font(.system(size: 14))
                                                            .foregroundColor(selectedStatus == status.0 ? statusColor(for: status.0) : .white)

                                                        Spacer()

                                                        if selectedStatus == status.0 {
                                                            Image(systemName: "checkmark")
                                                                .font(.system(size: 12, weight: .bold))
                                                                .foregroundColor(statusColor(for: status.0))
                                                        }
                                                    }
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 10)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(selectedStatus == status.0 ? statusColor(for: status.0).opacity(0.15) : Color.white.opacity(0.05))
                                                    )
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)

                            // Botón de confirmar
                            Button(action: {
                                let match = ScheduledMatch(
                                    venue: selectedVenue,
                                    seats: selectedSeats.isEmpty ? LocalizedString("schedule.toBeAssigned") : selectedSeats,
                                    date: selectedDate,
                                    status: selectedStatus
                                )
                                createdMatch = match
                                showSuccessAlert = true
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))

                                    Text(L("profile.confirmReservation"))
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.cyan]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(14)
                                .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .cornerRadius(30, corners: [.topLeft, .topRight])
                .frame(maxHeight: 680)
            }
        }
        .id(languageManager.currentLanguage) // Force re-render when language changes
        .alert(L("profile.reservationConfirmed"), isPresented: $showSuccessAlert) {
            Button(L("action.accept")) {
                isPresented = false
                if let match = createdMatch {
                    onMatchScheduled?(match)
                }
            }
        } message: {
            if let match = createdMatch {
                Text("\(L("profile.yourMatchAt")) \(match.venue) \(match.formattedDate)")
            }
        }
    }

    // MARK: - Helper functions

    private func statusIcon(for status: String) -> String {
        switch status {
        case "confirmed": return "checkmark.circle.fill"
        case "pending": return "clock.fill"
        case "cancelled": return "xmark.circle.fill"
        case "waiting": return "hourglass"
        default: return "circle.fill"
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "confirmed": return .green
        case "pending": return .orange
        case "cancelled": return .red
        case "waiting": return .yellow
        default: return .blue
        }
    }

    private func statusDisplayName(for status: String) -> String {
        switch status {
        case "confirmed": return LocalizedString("status.confirmed")
        case "pending": return LocalizedString("status.pending")
        case "cancelled": return LocalizedString("status.cancelled")
        case "waiting": return LocalizedString("status.waiting")
        default: return LocalizedString("status.unknown")
        }
    }
}

// MARK: - View Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
