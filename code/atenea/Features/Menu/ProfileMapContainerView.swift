//
//  ProfileMapContainerView.swift
//  atenea
//
//  Vista de ejemplo que combina el menú lateral verde (Imagen 1) con el contenido de perfil/mapa (Imagen 3)
//  Este es el contenedor principal que muestra el menú deslizante tipo "push"
//

import SwiftUI

struct ProfileMapContainerView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var userManager = UserManager.shared
    @ObservedObject private var menuStateManager = MenuStateManager.shared

    // Estados para mostrar sheets y modales
    @State private var showProfileSheet = false
    @State private var showSettingsSheet = false
    @State private var showFavoritesSheet = false
    @State private var showHelpSheet = false
    @State private var showVenuesSheet = false
    @State private var showARScannerSheet = false
    @State private var showScheduleSheet = false
    @State private var showAccessibilitySheet = false
    @State private var isLoggedIn = true

    var body: some View {
        SidebarPushMenuContainer(languageManager: languageManager) {
            // Contenido principal que se desliza (la vista del mapa/perfil de la Imagen 3)
            profileMapContentView
        }
        .onProfile {
            showProfileSheet = true
        }
        .onSettings {
            showSettingsSheet = true
        }
        .onFavorites {
            showFavoritesSheet = true
        }
        .onHelp {
            showHelpSheet = true
        }
        .onShowVenues {
            showVenuesSheet = true
        }
        .onShowARScanner {
            showARScannerSheet = true
        }
        .onShowSchedule {
            showScheduleSheet = true
        }
        .onAccessibility {
            showAccessibilitySheet = true
        }
        .onLogout {
            handleLogout()
        }
        // Sheets para las diferentes vistas
        .sheet(isPresented: $showProfileSheet) {
            UserProfileView()
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView(languageManager: languageManager)
        }
        .sheet(isPresented: $showFavoritesSheet) {
            FavoritesView()
        }
        .sheet(isPresented: $showHelpSheet) {
            HelpView()
        }
        .sheet(isPresented: $showVenuesSheet) {
            NavigationView {
                VenuesListView()
            }
        }
        .sheet(isPresented: $showARScannerSheet) {
            Text("AR Scanner")
                .font(.largeTitle)
        }
        .sheet(isPresented: $showScheduleSheet) {
            Text("Schedule/Reservations")
                .font(.largeTitle)
        }
        .sheet(isPresented: $showAccessibilitySheet) {
            VisualAccessibilitySettingsView()
        }
    }

    // MARK: - Profile Map Content (Imagen 3)

    private var profileMapContentView: some View {
        ZStack {
            // Fondo del mapa (o imagen de mapa simulado)
            mapBackgroundView

            // Overlay con contenido de perfil
            VStack(spacing: 0) {
                // Header con perfil
                profileHeaderView
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.4, green: 0.5, blue: 0.9),
                                Color(red: 0.5, green: 0.3, blue: 0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(
                        .rect(
                            bottomLeadingRadius: 24,
                            bottomTrailingRadius: 24
                        )
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)

                Spacer()

                // Bottom sheet con opciones de perfil
                profileBottomSheet
            }
            .ignoresSafeArea(edges: .top)
        }
    }

    // MARK: - Map Background

    private var mapBackgroundView: some View {
        // Simulación de mapa de fondo
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#1a2a6c"),
                    Color(hex: "#b21f1f"),
                    Color(hex: "#fdbb2d")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Overlay para simular un mapa
            Color.black.opacity(0.2)

            // Texto de marcador de posición
            VStack {
                Spacer()
                Text("Map Background")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 300)
                Spacer()
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeaderView: some View {
        VStack(spacing: 16) {
            HStack {
                // Botón de menú (hamburguesa)
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        menuStateManager.toggleMenu()
                    }
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.2))
                        )
                }
                .padding(.leading, 20)

                Spacer()

                // Botón de búsqueda
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 44, height: 44)
                }
                .padding(.trailing, 20)
            }
            .padding(.top, 60)

            // Avatar y nombre de usuario
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.blue.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 3)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)

                    Image(systemName: "person.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.9))
                }

                VStack(spacing: 4) {
                    Text(userManager.currentUser?.name ?? "Emi")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text(userManager.currentUser?.email ?? "emi@atenea.com")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Profile Bottom Sheet

    private var profileBottomSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Opciones de menú
            VStack(spacing: 12) {
                profileOption(icon: "person.fill", title: "Perfil", iconColor: .blue) {
                    showProfileSheet = true
                }

                profileOption(icon: "gearshape.fill", title: "Configuración", iconColor: .pink) {
                    showSettingsSheet = true
                }

                profileOption(icon: "star.fill", title: "Favoritos", iconColor: .orange) {
                    showFavoritesSheet = true
                }

                profileOption(icon: "questionmark.circle.fill", title: "Ayuda", iconColor: .purple) {
                    showHelpSheet = true
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Separador
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)

            // Sección de Estilo de Mapa
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "map.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.pink)

                    Text("Estilo de Mapa")
                        .font(.system(size: 16, weight: .semibold))

                    Spacer()

                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.pink.opacity(0.6))
                }
                .padding(.horizontal, 20)
            }

            // Sección de Idioma
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "globe")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Idioma")
                            .font(.system(size: 16, weight: .semibold))
                        Text("English")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange.opacity(0.6))
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            // FIFA World Cup 2026
            Button(action: {
                showVenuesSheet = true
            }) {
                HStack {
                    Image(systemName: "soccerball")
                        .font(.system(size: 18))
                        .foregroundColor(.white)

                    Text("FIFA World Cup 2026™")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#4CAF50"),
                            Color(hex: "#45A049")
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Explorar Sedes
            Button(action: {
                showVenuesSheet = true
            }) {
                HStack {
                    Image(systemName: "map.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)

                    Text("Explorar Sedes")
                        .font(.system(size: 16, weight: .semibold))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.5))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .padding(.top, 12)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -8)
        )
    }

    // MARK: - Profile Option

    private func profileOption(icon: String, title: String, iconColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 46, height: 46)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.gray.opacity(0.4))
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Handle Logout

    private func handleLogout() {
        withAnimation {
            isLoggedIn = false
        }
        // Aquí puedes agregar lógica adicional de logout
        print("🔓 Usuario cerró sesión")
    }
}

// MARK: - SidebarPushMenuContainer Extension

extension SidebarPushMenuContainer {
    func onProfile(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onProfile = action
        return view
    }

    func onSettings(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onSettings = action
        return view
    }

    func onFavorites(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onFavorites = action
        return view
    }

    func onHelp(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onHelp = action
        return view
    }

    func onShowVenues(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onShowVenues = action
        return view
    }

    func onShowARScanner(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onShowARScanner = action
        return view
    }

    func onShowSchedule(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onShowSchedule = action
        return view
    }

    func onAccessibility(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onAccessibility = action
        return view
    }

    func onLogout(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onLogout = action
        return view
    }
}

// MARK: - Preview

#Preview {
    ProfileMapContainerView()
}
