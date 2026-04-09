//
//  StaffEmergenciesView.swift
//  atenea
//
//  Vista de emergencias activadas por usuarios para el staff
//

import SwiftUI
import CoreLocation

// MARK: - Emergency Model
struct UserEmergency: Identifiable {
    let id: UUID
    let userName: String
    let userAvatar: String
    let location: String
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let emergencyType: EmergencyType
    let status: EmergencyStatus

    init(id: UUID = UUID(), userName: String, userAvatar: String, location: String, coordinate: CLLocationCoordinate2D, timestamp: Date, emergencyType: EmergencyType, status: EmergencyStatus) {
        self.id = id
        self.userName = userName
        self.userAvatar = userAvatar
        self.location = location
        self.coordinate = coordinate
        self.timestamp = timestamp
        self.emergencyType = emergencyType
        self.status = status
    }

    enum EmergencyType: String {
        case medical = "Médica"
        case security = "Seguridad"
        case fire = "Incendio"
        case other = "Otra"

        var icon: String {
            switch self {
            case .medical: return "cross.circle.fill"
            case .security: return "shield.fill"
            case .fire: return "flame.fill"
            case .other: return "exclamationmark.triangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .medical: return .red
            case .security: return .orange
            case .fire: return .red
            case .other: return .yellow
            }
        }
    }

    enum EmergencyStatus: String {
        case active = "Activa"
        case responding = "En atención"
        case disconnected = "Desconectada"
        case resolved = "Resuelta"

        var color: Color {
            switch self {
            case .active: return .red
            case .responding: return .orange
            case .disconnected: return .yellow
            case .resolved: return .green
            }
        }
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: timestamp)
    }
}

struct StaffEmergenciesView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var isPresented: Bool
    @ObservedObject var niManager: NearbyInteractionManager
    var onNavigateToEmergency: ((CLLocationCoordinate2D, String, Bool) -> Void)? // Bool indica si es navegación

    @State private var filterStatus: FilterStatus = .all
    @State private var selectedEmergency: UserEmergency?
    @State private var showEmergencyOptions = false
    @State private var showARNavigation = false

    // Mapeo de emergencias reales desde NI Manager
    private var emergencies: [UserEmergency] {
        // Convertir las emergencias activas del historial
        return niManager.activeEmergencies.map { emergency in
            // Mapear el estado de EmergencyRecord a UserEmergency
            let userEmergencyStatus: UserEmergency.EmergencyStatus
            switch emergency.status {
            case .active:
                userEmergencyStatus = .active
            case .disconnected:
                userEmergencyStatus = .disconnected
            case .resolved:
                userEmergencyStatus = .resolved
            }

            return UserEmergency(
                id: emergency.id, // Usar el mismo ID del EmergencyRecord
                userName: emergency.userName,
                userAvatar: "person.circle.fill",
                location: emergency.distance != nil ? "A \(String(format: "%.1f", emergency.distance!))m de distancia" : "Calculando ubicación...",
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), // Se actualizará con ubicación real
                timestamp: emergency.connectedAt,
                emergencyType: .security, // Por defecto, emergencia de seguridad
                status: userEmergencyStatus
            )
        }
    }

    enum FilterStatus: String, CaseIterable {
        case all = "Todas"
        case active = "Activas"
        case responding = "En atención"
        case disconnected = "Desconectadas"
        case resolved = "Resueltas"
    }

    var filteredEmergencies: [UserEmergency] {
        switch filterStatus {
        case .all:
            return emergencies
        case .active:
            return emergencies.filter { $0.status == .active }
        case .responding:
            return emergencies.filter { $0.status == .responding }
        case .disconnected:
            return emergencies.filter { $0.status == .disconnected }
        case .resolved:
            return emergencies.filter { $0.status == .resolved }
        }
    }

    var body: some View {
        ZStack {
            // Fondo
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.15, green: 0.0, blue: 0.0)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text(LocalizedString("staff.emergencies.back"))
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Text(LocalizedString("staff.emergencies.title"))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    // Espaciador para centrar el título
                    Color.clear
                        .frame(width: 80, height: 28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)

                // Filtros
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(FilterStatus.allCases, id: \.self) { status in
                            FilterButton(
                                title: status.rawValue,
                                isSelected: filterStatus == status
                            ) {
                                withAnimation {
                                    filterStatus = status
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)

                // Contador de emergencias
                HStack(spacing: 12) {
                    EmergencyCountBadge(
                        count: emergencies.filter { $0.status == .active }.count,
                        title: LocalizedString("staff.emergencies.active"),
                        color: .red
                    )

                    EmergencyCountBadge(
                        count: emergencies.filter { $0.status == .disconnected }.count,
                        title: LocalizedString("staff.emergencies.disconnected"),
                        color: .yellow
                    )

                    EmergencyCountBadge(
                        count: emergencies.filter { $0.status == .resolved }.count,
                        title: LocalizedString("staff.emergencies.resolved"),
                        color: .green
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // Contenido principal
                if filteredEmergencies.isEmpty {
                    // Estado vacío
                    EmptyEmergenciesView()
                } else {
                    // Lista de emergencias
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredEmergencies) { emergency in
                                EmergencyCard(emergency: emergency) {
                                    // Mostrar opciones
                                    selectedEmergency = emergency
                                    showEmergencyOptions = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .confirmationDialog(LocalizedString("staff.emergencies.whatToDo"), isPresented: $showEmergencyOptions, titleVisibility: .visible) {
            Button(LocalizedString("staff.emergencies.arNavigation")) {
                showARNavigation = true
                selectedEmergency = nil
            }

            Button(LocalizedString("staff.emergencies.showLocation")) {
                if let emergency = selectedEmergency {
                    isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onNavigateToEmergency?(emergency.coordinate, emergency.userName, false)
                    }
                }
            }

            Button(LocalizedString("staff.emergencies.startNavigation")) {
                if let emergency = selectedEmergency {
                    isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onNavigateToEmergency?(emergency.coordinate, emergency.userName, true)
                    }
                }
            }

            // Opciones de gestión de emergencias
            if let emergency = selectedEmergency, emergency.status != .resolved {
                Button(LocalizedString("staff.emergencies.markResolved")) {
                    niManager.resolveEmergency(emergencyID: emergency.id)
                    selectedEmergency = nil
                }
            }

            if let emergency = selectedEmergency {
                Button(LocalizedString("staff.emergencies.removeFromHistory"), role: .destructive) {
                    niManager.removeEmergency(emergencyID: emergency.id)
                    selectedEmergency = nil
                }
            }

            Button(LocalizedString("action.cancel"), role: .cancel) {
                selectedEmergency = nil
            }
        } message: {
            if let emergency = selectedEmergency {
                Text(String(format: LocalizedString("staff.emergencies.emergencyFormat"), emergency.userName, emergency.location))
            }
        }
        .fullScreenCover(isPresented: $showARNavigation) {
            StaffARNavigationView(isPresented: $showARNavigation, niManager: niManager)
        }
        .onReceive(niManager.$activeEmergencies) { emergencies in
            print("📋 [StaffView] activeEmergencies cambió. Total: \(emergencies.count)")
            for (index, emergency) in emergencies.enumerated() {
                print("   [\(index)] \(emergency.userName) - \(emergency.status)")
            }
        }
        .onAppear {
            print("👁️ [StaffView] Vista apareció")
            print("📊 [StaffView] Emergencias totales: \(niManager.activeEmergencies.count)")
            print("📊 [StaffView] Emergencias mapeadas: \(emergencies.count)")
        }
    }
}

// MARK: - Empty State View
struct EmptyEmergenciesView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(Color.red.opacity(0.05))
                    .frame(width: 180, height: 180)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red.opacity(0.6))
            }

            VStack(spacing: 12) {
                Text(LocalizedString("staff.emergencies.noActive"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text(LocalizedString("staff.emergencies.noActiveDesc"))
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Información adicional
            VStack(spacing: 16) {
                InfoRow(
                    icon: "checkmark.circle.fill",
                    text: LocalizedString("staff.emergencies.monitoring"),
                    color: .green
                )

                InfoRow(
                    icon: "bell.badge.fill",
                    text: LocalizedString("staff.emergencies.autoAlerts"),
                    color: .blue
                )

                InfoRow(
                    icon: "location.fill",
                    text: LocalizedString("staff.emergencies.realTimeTracking"),
                    color: .cyan
                )
            }
            .padding(.top, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))

            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Filter Button Component
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.red : Color.white.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Emergency Count Badge
struct EmergencyCountBadge: View {
    let count: Int
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text("\(count)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Emergency Card Component
struct EmergencyCard: View {
    let emergency: UserEmergency
    let action: () -> Void

    var body: some View {
        Button(action: action) {
        VStack(spacing: 0) {
            // Header con estado
            HStack {
                Circle()
                    .fill(emergency.status.color)
                    .frame(width: 8, height: 8)

                Text(emergency.status.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(emergency.status.color)

                Spacer()

                Text(emergency.formattedTime)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))

            // Contenido principal
            HStack(spacing: 16) {
                // Icono de tipo de emergencia
                ZStack {
                    Circle()
                        .fill(emergency.emergencyType.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: emergency.emergencyType.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(emergency.emergencyType.color)
                }

                // Info del usuario y ubicación
                VStack(alignment: .leading, spacing: 6) {
                    Text(emergency.userName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)

                        Text(emergency.location)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    HStack(spacing: 6) {
                        Image(systemName: emergency.emergencyType.icon)
                            .font(.system(size: 12))
                            .foregroundColor(emergency.emergencyType.color)

                        Text(emergency.emergencyType.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(emergency.emergencyType.color)
                    }
                }

                Spacer()

                // Indicador de navegación
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
        }
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StaffEmergenciesView(
        isPresented: .constant(true),
        niManager: NearbyInteractionManager(role: .staff)
    )
    .environmentObject(LanguageManager.shared)
}
