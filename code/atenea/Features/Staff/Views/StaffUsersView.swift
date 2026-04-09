//
//  StaffUsersView.swift
//  atenea
//
//  Vista de gestión de usuarios para el staff
//

import SwiftUI

// MARK: - User Model
struct StaffUser: Identifiable {
    let id = UUID()
    let name: String
    let email: String
    let status: UserStatus
    let joinDate: String
    let avatar: String

    enum UserStatus: String {
        case active = "Activo"
        case inactive = "Inactivo"
        case suspended = "Suspendido"

        var color: Color {
            switch self {
            case .active: return .green
            case .inactive: return .gray
            case .suspended: return .red
            }
        }
    }
}

struct StaffUsersView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var isPresented: Bool
    @State private var searchText: String = ""

    // Datos de ejemplo
    let sampleUsers = [
        StaffUser(name: "Carlos Mendoza", email: "carlos@example.com", status: .active, joinDate: "15/10/2024", avatar: "person.circle.fill"),
        StaffUser(name: "María García", email: "maria@example.com", status: .active, joinDate: "12/10/2024", avatar: "person.circle.fill"),
        StaffUser(name: "Juan Pérez", email: "juan@example.com", status: .inactive, joinDate: "08/10/2024", avatar: "person.circle.fill"),
        StaffUser(name: "Ana López", email: "ana@example.com", status: .active, joinDate: "05/10/2024", avatar: "person.circle.fill"),
        StaffUser(name: "Pedro Ramírez", email: "pedro@example.com", status: .suspended, joinDate: "01/10/2024", avatar: "person.circle.fill"),
        StaffUser(name: "Laura Torres", email: "laura@example.com", status: .active, joinDate: "28/09/2024", avatar: "person.circle.fill"),
        StaffUser(name: "Diego Sánchez", email: "diego@example.com", status: .active, joinDate: "25/09/2024", avatar: "person.circle.fill"),
        StaffUser(name: "Sofia Martínez", email: "sofia@example.com", status: .inactive, joinDate: "20/09/2024", avatar: "person.circle.fill")
    ]

    var filteredUsers: [StaffUser] {
        if searchText.isEmpty {
            return sampleUsers
        } else {
            return sampleUsers.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.email.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        ZStack {
            // Fondo
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.05, blue: 0.15)]),
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
                            Text(LocalizedString("staff.users.back"))
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Text(LocalizedString("staff.users.title"))
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

                // Barra de búsqueda
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.5))

                    TextField(LocalizedString("staff.users.searchPlaceholder"), text: $searchText)
                        .foregroundColor(.white)
                        .tint(.purple)

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // Estadísticas rápidas
                HStack(spacing: 12) {
                    QuickStatView(title: LocalizedString("staff.users.total"), value: "\(sampleUsers.count)", color: .blue)
                    QuickStatView(title: LocalizedString("staff.users.active"), value: "\(sampleUsers.filter { $0.status == .active }.count)", color: .green)
                    QuickStatView(title: LocalizedString("staff.users.suspended"), value: "\(sampleUsers.filter { $0.status == .suspended }.count)", color: .red)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // Lista de usuarios
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredUsers) { user in
                            UserCard(user: user)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - User Card Component
struct UserCard: View {
    let user: StaffUser

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(user.status.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: user.avatar)
                    .font(.system(size: 24))
                    .foregroundColor(user.status.color)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(user.email)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))

                HStack(spacing: 8) {
                    Circle()
                        .fill(user.status.color)
                        .frame(width: 6, height: 6)

                    Text(user.status.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(user.status.color)

                    Text("•")
                        .foregroundColor(.white.opacity(0.3))

                    Text(user.joinDate)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            // Action button
            Button(action: {
                // Acción para ver detalles del usuario
            }) {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Quick Stat Component
struct QuickStatView: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
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

#Preview {
    StaffUsersView(isPresented: .constant(true))
        .environmentObject(LanguageManager.shared)
}
