//
//  SidebarPushMenuContainer.swift
//  atenea
//
//  Contenedor principal que maneja el menú lateral tipo "push" (desliza el contenido hacia la derecha)
//  Inspirado en diseños modernos de apps de e-commerce
//

import SwiftUI

// MARK: - Sidebar Push Menu Container

// Note: Color extensions (coppelBlue, etc.) are defined in Core/Theme/CoppelColors.swift

struct SidebarPushMenuContainer<Content: View>: View {
    @ObservedObject var menuStateManager = MenuStateManager.shared
    @ObservedObject var languageManager: LanguageManager
    @ObservedObject var userManager = UserManager.shared

    // Contenido principal (vista del mapa o cualquier contenido)
    let content: Content

    // Callbacks del menú
    var onProfile: (() -> Void)?
    var onSettings: (() -> Void)?
    var onFavorites: (() -> Void)?
    var onHelp: (() -> Void)?
    var onShowVenues: (() -> Void)?
    var onAccessibility: (() -> Void)?
    var onLogout: (() -> Void)?

    var selectedTab: Int

    init(
        languageManager: LanguageManager,
        selectedTab: Int = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.languageManager = languageManager
        self.selectedTab = selectedTab
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fondo base (transparente para mapa, gris para otras vistas)
                Group {
                    if selectedTab == 1 && !menuStateManager.showMenu {
                        Color.clear
                    } else {
                        Color(hex: "#F5F3F0")
                    }
                }
                .ignoresSafeArea()

                // Menú azul (solo cuando menú abierto)
                if menuStateManager.showMenu {
                    greenMenuBackground
                        .ignoresSafeArea()
                }

                // CONTENIDO: Vista principal que se desliza
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: menuStateManager.showMenu ? 24 : 0,
                            style: .continuous
                        )
                    )
                    .shadow(
                        color: Color.black.opacity(menuStateManager.showMenu ? 0.3 : 0),
                        radius: menuStateManager.showMenu ? 30 : 0,
                        x: -8,
                        y: 0
                    )
                    .offset(x: menuStateManager.showMenu ? geometry.size.width * 0.75 : 0)
                    .scaleEffect(menuStateManager.showMenu ? CGSize(width: 0.90, height: 0.90) : CGSize(width: 1.0, height: 1.0))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: menuStateManager.showMenu)
                    .onTapGesture {
                        // Cerrar el menú cuando se toca el contenido desplazado
                        if menuStateManager.showMenu {
                            closeMenu()
                        }
                    }
                    .gesture(
                        // Permitir arrastrar para cerrar el menú
                        DragGesture()
                            .onEnded { value in
                                if menuStateManager.showMenu && value.translation.width < -50 {
                                    // Si se arrastra hacia la izquierda más de 50pt, cerrar menú
                                    closeMenu()
                                }
                            }
                    )
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Blue Menu Background

    private var greenMenuBackground: some View {
        ZStack(alignment: .topLeading) {
            // Fondo azul Coppel con gradiente suave
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.coppelBlue,
                    Color.coppelMediumBlue,
                    Color.coppelDarkBlue
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Overlay de textura sutil
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.1),
                    Color.clear,
                    Color.black.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Contenido del menú
            VStack(alignment: .leading, spacing: 0) {
                // Header con icono de perfil y botón de cierre
                menuHeader
                    .padding(.top, 60)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)

                // Opciones del menú
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Sección FIFA World Cup
                        menuDivider()

                        menuSectionTitle("FIFA World Cup 2026™")

                        menuItem(icon: "location.fill", title: LocalizedString("sidebar.venues")) {
                            onShowVenues?()
                            closeMenu()
                        }

                        // Sección de configuración
                        menuDivider()

                        menuItem(icon: "person.crop.circle.fill", title: "Profile") {
                            onProfile?()
                            closeMenu()
                        }

                        menuItem(icon: "star.fill", title: "Favorites") {
                            onFavorites?()
                            closeMenu()
                        }

                        menuItem(icon: "gearshape.fill", title: "Settings") {
                            onSettings?()
                            closeMenu()
                        }

                        menuItem(icon: "questionmark.circle.fill", title: "Help") {
                            onHelp?()
                            closeMenu()
                        }

                        // Accessibility (condicional)
                        if userManager.currentUser?.needsAccessibilityFeatures == true {
                            menuDivider()

                            menuItem(icon: "accessibility.fill", title: "Accessibility") {
                                onAccessibility?()
                                closeMenu()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                // Botón de Logout fijo al fondo
                logoutButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Menu Header

    private var menuHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: "person.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }

                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(userManager.currentUser?.name ?? "Usuario")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(userManager.currentUser?.email ?? "usuario@atenea.com")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Botón de cierre (X)
                Button(action: closeMenu) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 44, height: 44)
                }
            }
        }
    }

    // MARK: - Menu Item

    private func menuItem(icon: String, title: String, action: (() -> Void)? = nil) -> some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            action?()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 28)

                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Menu Section Title

    private func menuSectionTitle(_ title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "soccerball.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.9))

            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.vertical, 12)
    }

    // MARK: - Menu Divider

    private func menuDivider() -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.2))
            .frame(height: 0.5)
            .padding(.vertical, 12)
    }

    // MARK: - Logout Button

    private var logoutButton: some View {
        Button(action: {
            onLogout?()
            closeMenu()
        }) {
            HStack(spacing: 16) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 28)

                Text(LocalizedString("sidebar.logout"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.2))
            )
        }
    }

    // MARK: - Helpers

    private func closeMenu() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            menuStateManager.closeMenu()
        }
    }
}

// MARK: - Builder Extensions

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
    SidebarPushMenuContainer(languageManager: LanguageManager.shared) {
        // Contenido de ejemplo (mapa simulado)
        ZStack {
            // Fondo del mapa
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#667eea"),
                    Color(hex: "#764ba2")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack {
                HStack {
                    Button(action: {
                        MenuStateManager.shared.toggleMenu()
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                            )
                    }
                    .padding(.leading, 20)

                    Spacer()
                }
                .padding(.top, 60)

                Spacer()

                Text("Main Map View")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()
            }
        }
    }
}
