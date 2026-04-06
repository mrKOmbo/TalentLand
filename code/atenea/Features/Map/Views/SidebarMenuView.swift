//
//  SidebarMenuView.swift
//  atenea
//
//  Ultra-modern animated sidebar menu with glassmorphism and elegant animations
//

import SwiftUI

// MARK: - Sidebar Menu View
struct SidebarMenuView: View {
    @ObservedObject var menuStateManager = MenuStateManager.shared
    @ObservedObject var languageManager: LanguageManager
    @ObservedObject var userManager = UserManager.shared

    // Callbacks para las acciones del menú
    var onHome: (() -> Void)?
    var onSearch: (() -> Void)?
    var onProfile: (() -> Void)?
    var onFavorites: (() -> Void)?
    var onHelp: (() -> Void)?
    var onHistory: (() -> Void)?
    var onNotifications: (() -> Void)?
    var onSettings: (() -> Void)?
    var onAccessibility: (() -> Void)?
    var onLogout: (() -> Void)?

    // Callbacks adicionales
    var onShowVenues: (() -> Void)?
    var onShowSchedule: (() -> Void)?
    var onShowARScanner: (() -> Void)?
    var onShowStaff: (() -> Void)?
    var onShowLine1: (() -> Void)?
    var onShowLine2: (() -> Void)?
    var onShowLine3: (() -> Void)?
    var onShowLine9: (() -> Void)?
    var selectedMapStyle: Binding<MapStyle>?

    @State private var selectedItem: String? = "Home"
    @State private var isMetroLinesExpanded: Bool = false
    @State private var isMapStyleExpanded: Bool = false
    @State private var isLanguageExpanded: Bool = false

    // Helper para obtener strings localizados
    private func L(_ key: String) -> String {
        return languageManager.localizedString(key)
    }

    var body: some View {
        ZStack {
            // Fondo oscuro con animación de opacidad
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    closeSidebar()
                }
                .transition(.opacity)

            // Panel del menú con animación de deslizamiento
            HStack(spacing: 0) {
                Spacer()

                // Sidebar panel
                VStack(spacing: 0) {
                // Header con perfil de usuario
                headerView

                // Contenido del menú con scroll
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        // Perfil
                        modernMenuButton(
                            icon: "person.fill",
                            title: "Perfil",
                            gradient: [Color.blue, Color.cyan],
                            action: {
                                selectedItem = "Perfil"
                                onProfile?()
                                closeSidebar()
                            }
                        )

                        // Configuración
                        modernMenuButton(
                            icon: "gearshape.fill",
                            title: "Configuración",
                            gradient: [Color.purple, Color.pink],
                            action: {
                                selectedItem = "Configuración"
                                onSettings?()
                                closeSidebar()
                            }
                        )

                        // Accesibilidad (mostrar solo si el usuario tiene discapacidad)
                        if userManager.currentUser?.needsAccessibilityFeatures == true {
                            modernMenuButton(
                                icon: "accessibility",
                                title: "Accesibilidad",
                                gradient: [Color.green, Color.mint],
                                action: {
                                    selectedItem = "Accesibilidad"
                                    onAccessibility?()
                                    closeSidebar()
                                }
                            )
                        }

                        // Favoritos
                        modernMenuButton(
                            icon: "star.fill",
                            title: "Favoritos",
                            gradient: [Color.orange, Color.yellow],
                            action: {
                                selectedItem = "Favoritos"
                                onFavorites?()
                                closeSidebar()
                            }
                        )

                        // Ayuda
                        modernMenuButton(
                            icon: "questionmark.circle.fill",
                            title: "Ayuda",
                            gradient: [Color.indigo, Color.blue],
                            action: {
                                selectedItem = "Ayuda"
                                onHelp?()
                                closeSidebar()
                            }
                        )

                        // Separador elegante
                        elegantDivider()

                        // Sección de Estilo de Mapa
                        if selectedMapStyle != nil {
                            mapStyleSection
                            elegantDivider()
                        }

                        // Sección de Idioma
                        languageSection

                        elegantDivider()

                        // Sección FIFA 2026
                        fifa2026Section

                        elegantDivider()

                        // Sección de Metro
                        metroLinesSection

                        // Sección de Staff (solo para admin)
                        if userManager.hasStaffAccess {
                            elegantDivider()
                            staffSection
                        }

                        // Espacio al final
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 12)
                }
                .frame(maxHeight: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color.gray.opacity(0.02)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Cerrar Sesión al final (fijo)
                logoutSection
            }
            .frame(width: 300)
            .frame(maxHeight: .infinity)
            .background(
                ZStack {
                    // Fondo con glassmorphism
                    Color.white

                    // Efecto de blur sutil
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.02),
                            Color.purple.opacity(0.02),
                            Color.pink.opacity(0.02)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(
                .rect(
                    topLeadingRadius: 24,
                    bottomLeadingRadius: 24,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
            )
            .shadow(color: Color.black.opacity(0.15), radius: 30, x: -8, y: 0)
            .shadow(color: Color.blue.opacity(0.08), radius: 20, x: -4, y: 0)
                .transition(.move(edge: .trailing))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .bottom)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: menuStateManager.showMenu)
    }

    // MARK: - Header View
    private var headerView: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradiente de fondo mejorado
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.4, blue: 0.9),
                        Color(red: 0.3, green: 0.2, blue: 0.8),
                        Color(red: 0.5, green: 0.3, blue: 0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Efecto de brillo sutil
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.2),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .center
                )

                // Contenido
                HStack(spacing: 14) {
                    // Avatar con efecto glow
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 40
                                )
                            )
                            .frame(width: 70, height: 70)
                            .blur(radius: 8)

                        // Avatar principal
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
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 2.5)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)

                        Image(systemName: "person.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.2, green: 0.4, blue: 0.9),
                                        Color(red: 0.4, green: 0.3, blue: 0.8)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    // Información del usuario
                    VStack(alignment: .leading, spacing: 4) {
                        Text(userManager.currentUser?.name ?? "Usuario")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)

                        Text(userManager.currentUser?.email ?? "usuario@email.com")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 18)
                .padding(.top, max(geometry.safeAreaInsets.top + 50, 60))
                .padding(.bottom, 18)
            }
        }
        .frame(height: 140)
    }

    // MARK: - Modern Menu Button
    private func modernMenuButton(icon: String, title: String, gradient: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Ícono con gradiente
                ZStack {
                    // Sombra del círculo
                    Circle()
                        .fill(gradient[0].opacity(0.2))
                        .frame(width: 40, height: 40)
                        .blur(radius: 4)

                    // Círculo principal
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: gradient.map { $0.opacity(0.12) }),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: gradient),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    .shadow(color: gradient[0].opacity(0.08), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(ModernButtonStyle())
    }

    // MARK: - Elegant Divider
    private func elegantDivider() -> some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.clear,
                Color.gray.opacity(0.2),
                Color.clear
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
        .padding(.vertical, 10)
    }

    // MARK: - Map Style Section
    private var mapStyleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    isMapStyleExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple.opacity(0.12), Color.pink.opacity(0.08)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 38, height: 38)

                        Image(systemName: "map.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple, Color.pink]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    Text("Estilo de Mapa")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer(minLength: 4)

                    Image(systemName: isMapStyleExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.pink.opacity(0.5)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        .shadow(color: Color.purple.opacity(0.08), radius: 12, x: 0, y: 4)
                )
            }
            .buttonStyle(ModernButtonStyle())

            if isMapStyleExpanded, let mapStyleBinding = selectedMapStyle {
                VStack(spacing: 8) {
                    mapStyleOptionButton(
                        title: "Estándar",
                        icon: "map",
                        mapStyle: .standard,
                        currentStyle: mapStyleBinding
                    )

                    mapStyleOptionButton(
                        title: "Satélite",
                        icon: "globe.americas.fill",
                        mapStyle: .satellite,
                        currentStyle: mapStyleBinding
                    )

                    mapStyleOptionButton(
                        title: "Híbrido",
                        icon: "map.fill",
                        mapStyle: .satelliteStreets,
                        currentStyle: mapStyleBinding
                    )
                }
                .padding(.top, 4)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
    }

    // MARK: - Map Style Option Button
    private func mapStyleOptionButton(title: String, icon: String, mapStyle: MapStyle, currentStyle: Binding<MapStyle>) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                currentStyle.wrappedValue = mapStyle
            }
        }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(currentStyle.wrappedValue == mapStyle ?
                          LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.pink]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ) :
                          LinearGradient(
                            gradient: Gradient(colors: [Color.clear]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1.5)
                    )

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(currentStyle.wrappedValue == mapStyle ? .purple : .gray)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 14, weight: currentStyle.wrappedValue == mapStyle ? .semibold : .medium))
                    .foregroundColor(currentStyle.wrappedValue == mapStyle ? .purple : .primary)

                Spacer()

                if currentStyle.wrappedValue == mapStyle {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.pink]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(currentStyle.wrappedValue == mapStyle ? Color.purple.opacity(0.06) : Color.gray.opacity(0.03))
            )
        }
        .buttonStyle(ModernButtonStyle())
    }

    // MARK: - Language Section
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    isLanguageExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange.opacity(0.12), Color.yellow.opacity(0.08)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 38, height: 38)

                        Image(systemName: "globe")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Idioma")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(LanguageManager.availableLanguages[languageManager.currentLanguage] ?? "Español")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: isLanguageExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange.opacity(0.6), Color.yellow.opacity(0.5)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        .shadow(color: Color.orange.opacity(0.08), radius: 12, x: 0, y: 4)
                )
            }
            .buttonStyle(ModernButtonStyle())

            if isLanguageExpanded {
                VStack(spacing: 6) {
                    ForEach(Array(LanguageManager.availableLanguages.keys.sorted()), id: \.self) { languageCode in
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                languageManager.setLanguage(languageCode)
                                isLanguageExpanded = false
                            }
                        }) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(languageManager.currentLanguage == languageCode ?
                                          LinearGradient(
                                            gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                          ) :
                                          LinearGradient(
                                            gradient: Gradient(colors: [Color.clear]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                          )
                                    )
                                    .frame(width: 8, height: 8)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
                                    )

                                Text(languageCode.uppercased())
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(languageManager.currentLanguage == languageCode ? .orange : .gray)
                                    .frame(width: 24)

                                Text(LanguageManager.availableLanguages[languageCode] ?? languageCode)
                                    .font(.system(size: 14, weight: languageManager.currentLanguage == languageCode ? .semibold : .medium))
                                    .foregroundColor(languageManager.currentLanguage == languageCode ? .orange : .primary)

                                Spacer()

                                if languageManager.currentLanguage == languageCode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(languageManager.currentLanguage == languageCode ? Color.orange.opacity(0.06) : Color.gray.opacity(0.03))
                            )
                        }
                        .buttonStyle(ModernButtonStyle())
                    }
                }
                .padding(.top, 4)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
    }

    // MARK: - FIFA 2026 Section
    private var fifa2026Section: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header con gradiente mejorado
            HStack(spacing: 10) {
                Image(systemName: "soccerball")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text("FIFA World Cup 2026™")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer(minLength: 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.7, blue: 0.3),
                            Color(red: 0.1, green: 0.6, blue: 0.4)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )

                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            .cornerRadius(14)
            .shadow(color: Color.green.opacity(0.3), radius: 12, x: 0, y: 4)

            VStack(spacing: 8) {
                fifaButton(
                    icon: "map.fill",
                    title: "Explorar Sedes",
                    gradient: [Color.green, Color.mint],
                    action: {
                        onShowVenues?()
                        closeSidebar()
                    }
                )

                fifaButton(
                    icon: "camera.viewfinder",
                    title: "Escanear Posters",
                    gradient: [Color.purple, Color.blue],
                    action: {
                        onShowARScanner?()
                        closeSidebar()
                    }
                )

                fifaButton(
                    icon: "ticket.fill",
                    title: "Reservar",
                    gradient: [Color.orange, Color.yellow],
                    action: {
                        onShowSchedule?()
                        closeSidebar()
                    }
                )
            }
        }
    }

    // MARK: - FIFA Button
    private func fifaButton(icon: String, title: String, gradient: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: gradient.map { $0.opacity(0.15) }),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: gradient),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    .shadow(color: gradient[0].opacity(0.08), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(ModernButtonStyle())
    }

    // MARK: - Metro Lines Section
    private var metroLinesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    isMetroLinesExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.indigo.opacity(0.12), Color.blue.opacity(0.08)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 38, height: 38)

                        Image(systemName: "tram.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.indigo, Color.blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    Text("Líneas del Metro")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer(minLength: 4)

                    Image(systemName: isMetroLinesExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.indigo.opacity(0.6), Color.blue.opacity(0.5)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        .shadow(color: Color.indigo.opacity(0.08), radius: 12, x: 0, y: 4)
                )
            }
            .buttonStyle(ModernButtonStyle())

            if isMetroLinesExpanded {
                VStack(spacing: 8) {
                    metroLineButton(number: "1", color: Color(red: 0.95, green: 0.40, blue: 0.65), action: {
                        onShowLine1?()
                        closeSidebar()
                    })

                    metroLineButton(number: "2", color: Color(red: 0.0, green: 0.35, blue: 0.87), action: {
                        onShowLine2?()
                        closeSidebar()
                    })

                    metroLineButton(number: "3", color: Color(red: 0.67, green: 0.71, blue: 0.18), action: {
                        onShowLine3?()
                        closeSidebar()
                    })

                    metroLineButton(number: "9", color: Color(red: 0.43, green: 0.27, blue: 0.08), action: {
                        onShowLine9?()
                        closeSidebar()
                    })
                }
                .padding(.top, 4)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
    }

    // MARK: - Metro Line Button
    private func metroLineButton(number: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 38, height: 38)
                        .blur(radius: 6)

                    Circle()
                        .fill(color)
                        .frame(width: 36, height: 36)
                        .shadow(color: color.opacity(0.5), radius: 6, x: 0, y: 3)
                        .overlay(
                            Text(number)
                                .font(.system(size: 15, weight: .black))
                                .foregroundColor(.white)
                        )
                }

                Text("Línea \(number)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    .shadow(color: color.opacity(0.08), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(ModernButtonStyle())
    }

    // MARK: - Staff Section
    private var staffSection: some View {
        Button(action: {
            onShowStaff?()
            closeSidebar()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange.opacity(0.15), Color.red.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)

                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange, Color.red]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Staff Access")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)

                Spacer(minLength: 4)

                Text("ADMIN")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.red]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.orange.opacity(0.4), radius: 4, x: 0, y: 2)
                    )

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    .shadow(color: Color.orange.opacity(0.12), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(ModernButtonStyle())
    }

    // MARK: - Logout Section
    private var logoutSection: some View {
        VStack(spacing: 0) {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.gray.opacity(0.15),
                    Color.clear
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)

            Button(action: {
                onLogout?()
                closeSidebar()
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red.opacity(0.12), Color.pink.opacity(0.08)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)

                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red, Color.pink]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    Text("Cerrar Sesión")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.pink]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Spacer(minLength: 4)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .buttonStyle(ModernButtonStyle())
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white,
                        Color.red.opacity(0.02)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    // MARK: - Close Sidebar
    // MARK: - Close Sidebar
    private func closeSidebar() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            // Cambiar isPresented = false a:
            menuStateManager.closeMenu()
        }
    }
}

// MARK: - Modern Button Style
struct ModernButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? CGFloat(0.97) : CGFloat(1.0))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
