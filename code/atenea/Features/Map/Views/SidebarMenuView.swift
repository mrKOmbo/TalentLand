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
            Color.coppelDarkBlue.opacity(0.45)
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
                            title: L("menu.profile"),
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
                            title: L("menu.settings"),
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
                                title: L("menu.accessibility"),
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
                            title: L("menu.favorites"),
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
                            title: L("menu.help"),
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
                .background(Color.white)

                // Cerrar Sesión al final (fijo)
                logoutSection
            }
            .frame(width: 300)
            .frame(maxHeight: .infinity)
            .background(Color.white)
            .clipShape(
                .rect(
                    topLeadingRadius: 24,
                    bottomLeadingRadius: 24,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
            )
            .shadow(color: Color.coppelDarkBlue.opacity(0.15), radius: 24, x: -8, y: 0)
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
                // Coppel Blue solid background
                Color.coppelBlue

                // Contenido
                HStack(spacing: 14) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle()
                                    .stroke(Color.coppelYellow, lineWidth: 2.5)
                            )

                        Image(systemName: "person.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color.coppelBlue)
                    }

                    // Información del usuario
                    VStack(alignment: .leading, spacing: 4) {
                        Text(userManager.currentUser?.name ?? L("menu.defaultUser"))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(userManager.currentUser?.email ?? L("menu.defaultEmail"))
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
                ZStack {
                    Circle()
                        .fill(Color.coppelBlue.opacity(0.08))
                        .frame(width: 38, height: 38)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.coppelBlue)
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.coppelDarkBlue)

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.coppelDarkGrey.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.coppelDarkBlue.opacity(0.06), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(ModernButtonStyle())
    }

    // MARK: - Elegant Divider
    private func elegantDivider() -> some View {
        Rectangle()
            .fill(Color.coppelBeige)
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
                            .fill(Color.coppelLightBlue.opacity(0.12))
                            .frame(width: 38, height: 38)

                        Image(systemName: "map.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.coppelLightBlue)
                    }

                    Text(L("menu.mapStyle"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.coppelDarkBlue)

                    Spacer(minLength: 4)

                    Image(systemName: isMapStyleExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.coppelDarkGrey)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .shadow(color: Color.coppelDarkBlue.opacity(0.06), radius: 8, x: 0, y: 2)
                )
            }
            .buttonStyle(ModernButtonStyle())

            if isMapStyleExpanded, let mapStyleBinding = selectedMapStyle {
                VStack(spacing: 8) {
                    mapStyleOptionButton(
                        title: L("menu.mapStandard"),
                        icon: "map",
                        mapStyle: .standard,
                        currentStyle: mapStyleBinding
                    )

                    mapStyleOptionButton(
                        title: L("menu.mapSatellite"),
                        icon: "globe.americas.fill",
                        mapStyle: .satellite,
                        currentStyle: mapStyleBinding
                    )

                    mapStyleOptionButton(
                        title: L("menu.mapHybrid"),
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
        let isSelected = currentStyle.wrappedValue == mapStyle
        return Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                currentStyle.wrappedValue = mapStyle
            }
        }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(isSelected ? Color.coppelBlue : Color.clear)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.coppelBlue.opacity(0.3), lineWidth: 1.5)
                    )

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? Color.coppelBlue : Color.coppelDarkGrey)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? Color.coppelBlue : Color.coppelDarkBlue)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.coppelBlue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.coppelBlue.opacity(0.06) : Color.coppelBeige.opacity(0.5))
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
                            .fill(Color.coppelOrange.opacity(0.12))
                            .frame(width: 38, height: 38)

                        Image(systemName: "globe")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.coppelOrange)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("menu.language"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.coppelDarkBlue)

                        Text(LanguageManager.availableLanguages[languageManager.currentLanguage] ?? "Español")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.coppelDarkGrey)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: isLanguageExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.coppelDarkGrey)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .shadow(color: Color.coppelDarkBlue.opacity(0.06), radius: 8, x: 0, y: 2)
                )
            }
            .buttonStyle(ModernButtonStyle())

            if isLanguageExpanded {
                VStack(spacing: 6) {
                    ForEach(Array(LanguageManager.availableLanguages.keys.sorted()), id: \.self) { languageCode in
                        let isSelected = languageManager.currentLanguage == languageCode
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                languageManager.setLanguage(languageCode)
                                isLanguageExpanded = false
                            }
                        }) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(isSelected ? Color.coppelBlue : Color.clear)
                                    .frame(width: 8, height: 8)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.coppelBlue.opacity(0.3), lineWidth: 1.5)
                                    )

                                Text(languageCode.uppercased())
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(isSelected ? Color.coppelBlue : Color.coppelDarkGrey)
                                    .frame(width: 24)

                                Text(LanguageManager.availableLanguages[languageCode] ?? languageCode)
                                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .rounded))
                                    .foregroundColor(isSelected ? Color.coppelBlue : Color.coppelDarkBlue)

                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.coppelBlue)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSelected ? Color.coppelBlue.opacity(0.06) : Color.coppelBeige.opacity(0.5))
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
            // Header — coppelDarkBlue background, coppelYellow headline
            HStack(spacing: 10) {
                Image(systemName: "soccerball")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.coppelYellow)

                Text("FIFA World Cup 2026")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color.coppelYellow)

                Spacer(minLength: 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.coppelDarkBlue)
            )

            VStack(spacing: 8) {
                fifaButton(
                    icon: "map.fill",
                    title: L("menu.exploreVenues2"),
                    color: Color.coppelGreen,
                    action: {
                        onShowVenues?()
                        closeSidebar()
                    }
                )

                fifaButton(
                    icon: "camera.viewfinder",
                    title: L("menu.scanPosters"),
                    color: Color.coppelPurple,
                    action: {
                        onShowARScanner?()
                        closeSidebar()
                    }
                )

                fifaButton(
                    icon: "ticket.fill",
                    title: L("menu.reserve2"),
                    color: Color.coppelOrange,
                    action: {
                        onShowSchedule?()
                        closeSidebar()
                    }
                )
            }
        }
    }

    // MARK: - FIFA Button
    private func fifaButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 38, height: 38)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.coppelDarkBlue)

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.coppelDarkGrey.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.coppelDarkBlue.opacity(0.06), radius: 8, x: 0, y: 2)
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
                            .fill(Color.coppelBlue.opacity(0.12))
                            .frame(width: 38, height: 38)

                        Image(systemName: "tram.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.coppelBlue)
                    }

                    Text(L("menu.metroLines"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.coppelDarkBlue)

                    Spacer(minLength: 4)

                    Image(systemName: isMetroLinesExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.coppelDarkGrey)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .shadow(color: Color.coppelDarkBlue.opacity(0.06), radius: 8, x: 0, y: 2)
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
                Circle()
                    .fill(color)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(number)
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(.white)
                    )

                Text(String(format: L("menu.line"), number))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.coppelDarkBlue)

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.coppelDarkGrey.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.coppelDarkBlue.opacity(0.06), radius: 8, x: 0, y: 2)
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
                        .fill(Color.coppelRed.opacity(0.12))
                        .frame(width: 38, height: 38)

                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.coppelRed)
                }

                Text(L("menu.staffAccess"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color.coppelDarkBlue)

                Spacer(minLength: 4)

                Text("Admin")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.coppelRed)
                    )

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.coppelDarkGrey.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.coppelDarkBlue.opacity(0.06), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(ModernButtonStyle())
    }

    // MARK: - Logout Section
    private var logoutSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.coppelBeige)
                .frame(height: 1)

            Button(action: {
                onLogout?()
                closeSidebar()
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.coppelRed.opacity(0.10))
                            .frame(width: 40, height: 40)

                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Color.coppelRed)
                    }

                    Text(L("menu.logout"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color.coppelRed)

                    Spacer(minLength: 4)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .buttonStyle(ModernButtonStyle())
            .background(Color.white)
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
