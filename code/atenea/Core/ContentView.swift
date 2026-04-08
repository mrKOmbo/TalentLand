//
//  ContentView.swift
//  atenear
//
//  Main navigation controller managing app flow
//

import SwiftUI

struct ContentView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var collectionManager = StickerCollectionManager.shared
    @ObservedObject private var emergencyManager = EmergencyModeManager.shared
    @ObservedObject private var navigationStateManager = NavigationStateManager.shared
    @State private var menuState = MenuStateManager.shared
    @State private var showSplash = true  // Mostrar SplashScreen al inicio
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var showOnboardingWelcome = false  // Pantalla de bienvenida personalizada
    @State private var isLoggedIn: Bool = UserDefaults.standard.bool(forKey: "isUserLoggedIn")
    @State private var currentUserName: String = UserDefaults.standard.string(forKey: "currentUserName") ?? "Usuario"
    @State private var selectedTab = 0
    @State private var lastCollectedVenue: WorldCupVenue?
    @State private var showCollectionAnimation = false

    // Estados para modales del nuevo menú
    @State private var showProfileView = false
    @State private var showSettingsView = false
    @State private var showFavoritesView = false
    @State private var showHelpView = false
    @State private var showVenuesView = false
    @State private var showARPosterScanner = false
    @State private var showScheduleModal = false
    @State private var showAccessibilityView = false

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if showSplash {
                    // Show splash screen
                    SplashScreenView(showSplash: $showSplash)
                        .environmentObject(languageManager)
                } else if showOnboarding {
                    // Show onboarding after splash
                    OnboardingView(showOnboarding: $showOnboarding)
                        .environmentObject(languageManager)
                } else if !isLoggedIn {
                    // Show welcome/login flow
                    WelcomeView(isLoggedIn: $isLoggedIn)
                        .environmentObject(languageManager)
                        .transition(.move(edge: .bottom))
                        .onChange(of: isLoggedIn) { _, newValue in
                            if newValue {
                                // Usuario acaba de iniciar sesión
                                // Mostrar pantalla de bienvenida personalizada
                                showOnboardingWelcome = true

                                // Persistir el estado de login
                                UserDefaults.standard.set(newValue, forKey: "isUserLoggedIn")
                            }
                        }
                } else if showOnboardingWelcome {
                    // Show personalized welcome screen after login
                    OnboardingWelcomeView(userName: currentUserName) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showOnboardingWelcome = false
                        }
                    }
                    .transition(.opacity)
                } else {
                    // Main app content with sidebar push menu
                    SidebarPushMenuContainer(languageManager: languageManager) {
                        // Contenido principal con tabs
                        ZStack {
                            Group {
                                switch selectedTab {
                                case 0:
                                    MainMapView(selectedTab: $selectedTab, isLoggedIn: $isLoggedIn)
                                        .environmentObject(languageManager)
                                case 1:
                                    CommunityView(selectedTab: $selectedTab)
                                        .environmentObject(languageManager)
                                case 2:
                                    StickerAlbumView(
                                        selectedTab: $selectedTab,
                                        collectionManager: collectionManager,
                                        lastCollectedVenue: $lastCollectedVenue,
                                        showCollectionAnimation: $showCollectionAnimation
                                    )
                                    .environmentObject(languageManager)
                                default:
                                    MainMapView(selectedTab: $selectedTab, isLoggedIn: $isLoggedIn)
                                        .environmentObject(languageManager)
                                }
                            }
                            .transition(.opacity)

                            // Tab Bar global en todos los tabs (ocultar en modo emergencia y cuando showDirections es true)
                            if !emergencyManager.isEmergencyActive {
                                VStack {
                                    Spacer()

                                    SimpleTabBar(selectedTab: $selectedTab)
                                        .environmentObject(languageManager)
                                }
                                .zIndex(10)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .offset(y: navigationStateManager.showDirections ? 120 : 0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: navigationStateManager.showDirections)
                            }

                            // Resplandor rojo ultrathink en todos los bordes (modo emergencia)
                            if emergencyManager.isEmergencyActive {
                                EmergencyGlowOverlay()
                                    .zIndex(1000)
                                    .allowsHitTesting(false)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .onProfile {
                        showProfileView = true
                    }
                    .onSettings {
                        showSettingsView = true
                    }
                    .onFavorites {
                        showFavoritesView = true
                    }
                    .onHelp {
                        showHelpView = true
                    }
                    .onShowVenues {
                        showVenuesView = true
                    }
                    .onShowARScanner {
                        showARPosterScanner = true
                    }
                    .onShowSchedule {
                        showScheduleModal = true
                    }
                    .onAccessibility {
                        showAccessibilityView = true
                    }
                    .onLogout {
                        handleLogout()
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
                    .sheet(isPresented: $showAccessibilityView) {
                        VisualAccessibilitySettingsView()
                    }
                    .sheet(isPresented: $showVenuesView) {
                        NavigationView {
                            VenuesListView()
                        }
                    }
                    .onChange(of: isLoggedIn) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "isUserLoggedIn")
                    }
                }
            }
            .ignoresSafeArea()
        }
        .environment(\.layoutDirection, languageManager.layoutDirection)
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .animation(.easeInOut(duration: 0.5), value: showOnboarding)
        .animation(.easeInOut(duration: 0.5), value: isLoggedIn)
        .animation(.easeInOut(duration: 0.5), value: languageManager.currentLanguage)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: emergencyManager.isEmergencyActive)
        .onAppear {
            handleAppIntentRequests()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Detectar cuando la app regresa al foreground
            if newPhase == .active {
                handleAppIntentRequests()
            }
        }
    }

    // MARK: - App Intent Request Handler

    /// Maneja las solicitudes provenientes de App Intents
    private func handleAppIntentRequests() {
        // Verificar si debe abrir el álbum
        if UserDefaults.standard.bool(forKey: "shouldOpenAlbum") {
            print("📖 [APP INTENT] Abriendo álbum desde shortcut")

            // Limpiar flag primero
            UserDefaults.standard.removeObject(forKey: "shouldOpenAlbum")

            // Cambiar al tab del álbum (tab 2)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = 2
                }
            }
        }
    }

    // MARK: - Handle Logout

    private func handleLogout() {
        withAnimation {
            isLoggedIn = false
        }
        UserDefaults.standard.set(false, forKey: "isUserLoggedIn")
        print("🔓 Usuario cerró sesión")
    }
}

// MARK: - Emergency Glow Overlay

/// Vista que muestra un resplandor rojo pulsante en todos los bordes durante modo emergencia
struct EmergencyGlowOverlay: View {
    @State private var pulseOpacity: Double = 0.6
    @State private var glowIntensity: Double = 30

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Borde superior
                LinearGradient(
                    colors: [
                        Color.red.opacity(pulseOpacity),
                        Color.red.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .blur(radius: glowIntensity)
                .position(x: geometry.size.width / 2, y: 0)

                // Borde inferior
                LinearGradient(
                    colors: [
                        Color.red.opacity(0),
                        Color.red.opacity(pulseOpacity)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .blur(radius: glowIntensity)
                .position(x: geometry.size.width / 2, y: geometry.size.height)

                // Borde izquierdo
                LinearGradient(
                    colors: [
                        Color.red.opacity(pulseOpacity),
                        Color.red.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 80)
                .frame(maxHeight: .infinity)
                .blur(radius: glowIntensity)
                .position(x: 0, y: geometry.size.height / 2)

                // Borde derecho
                LinearGradient(
                    colors: [
                        Color.red.opacity(0),
                        Color.red.opacity(pulseOpacity)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 80)
                .frame(maxHeight: .infinity)
                .blur(radius: glowIntensity)
                .position(x: geometry.size.width, y: geometry.size.height / 2)

                // Esquina superior izquierda
                RadialGradient(
                    colors: [
                        Color.red.opacity(pulseOpacity * 0.8),
                        Color.red.opacity(0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 100
                )
                .frame(width: 100, height: 100)
                .blur(radius: glowIntensity)
                .position(x: 0, y: 0)

                // Esquina superior derecha
                RadialGradient(
                    colors: [
                        Color.red.opacity(pulseOpacity * 0.8),
                        Color.red.opacity(0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 100
                )
                .frame(width: 100, height: 100)
                .blur(radius: glowIntensity)
                .position(x: geometry.size.width, y: 0)

                // Esquina inferior izquierda
                RadialGradient(
                    colors: [
                        Color.red.opacity(pulseOpacity * 0.8),
                        Color.red.opacity(0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 100
                )
                .frame(width: 100, height: 100)
                .blur(radius: glowIntensity)
                .position(x: 0, y: geometry.size.height)

                // Esquina inferior derecha
                RadialGradient(
                    colors: [
                        Color.red.opacity(pulseOpacity * 0.8),
                        Color.red.opacity(0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 100
                )
                .frame(width: 100, height: 100)
                .blur(radius: glowIntensity)
                .position(x: geometry.size.width, y: geometry.size.height)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            startPulseAnimation()
        }
    }

    private func startPulseAnimation() {
        // Animación de pulsación continua con estilo ultrathink
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
            pulseOpacity = 0.9
            glowIntensity = 40
        }
    }
}

#Preview {
    ContentView()
}
