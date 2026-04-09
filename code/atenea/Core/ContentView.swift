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
    @State private var showSplash = false  // Mostrar SplashScreen al inicio
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var showOnboardingWelcome = false  // Pantalla de bienvenida personalizada
    @State private var isLoggedIn: Bool = UserDefaults.standard.bool(forKey: "isUserLoggedIn")
    @State private var currentUserName: String = UserDefaults.standard.string(forKey: "currentUserName") ?? LocalizedString("login.defaultUser")
    @State private var selectedTab = 0
    @State private var lastCollectedVenue: WorldCupVenue?
    @State private var showCollectionAnimation = false

    // Estados para modales del menú
    @State private var showProfileView = false
    @State private var showSettingsView = false
    @State private var showFavoritesView = false
    @State private var showHelpView = false
    @State private var showVenuesView = false
    @State private var showAccessibilityView = false
    @State private var showSaleSheet = false

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let _ = print("📱 [ContentView BODY] splash=\(showSplash) onboarding=\(showOnboarding) loggedIn=\(isLoggedIn) welcome=\(showOnboardingWelcome)")
            ZStack {
                if showSplash {
                    let _ = print("📱 [ContentView] → Showing SPLASH")
                    SplashScreenView(showSplash: $showSplash)
                        .environmentObject(languageManager)
                } else if showOnboarding {
                    let _ = print("📱 [ContentView] → Showing ONBOARDING")
                    OnboardingView(showOnboarding: $showOnboarding)
                        .environmentObject(languageManager)
                } else if !isLoggedIn {
                    let _ = print("📱 [ContentView] → Showing LOGIN")
                    LoginView(isLoggedIn: $isLoggedIn)
                        .environmentObject(languageManager)
                        .transition(.move(edge: .bottom))
                        .onChange(of: isLoggedIn) { _, newValue in
                            print("📱 [ContentView] isLoggedIn changed to \(newValue)")
                            if newValue {
                                showOnboardingWelcome = true
                                UserDefaults.standard.set(newValue, forKey: "isUserLoggedIn")
                                print("📱 [ContentView] showOnboardingWelcome = true")
                            }
                        }
                } else if showOnboardingWelcome {
                    let _ = print("📱 [ContentView] → Showing WELCOME")
                    OnboardingWelcomeView(userName: currentUserName) {
                        print("📱 [ContentView] Ingresar pressed")
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showOnboardingWelcome = false
                        }
                        print("📱 [ContentView] welcome dismissed → main content")
                    }
                    .transition(.opacity)
                } else {
                    let _ = print("📱 [ContentView] → Showing MAIN CONTENT")
                    // Main app content with sidebar push menu
                    SidebarPushMenuContainer(languageManager: languageManager) {
                        // Contenido principal con tabs
                        ZStack {
                            Group {
                                switch selectedTab {
                                case 0:
                                    HomeView(selectedTab: $selectedTab, pendingMerchantPlace: .constant(nil))
                                        .environmentObject(languageManager)
                                case 1:
                                    MainMapView(selectedTab: $selectedTab, isLoggedIn: $isLoggedIn)
                                        .environmentObject(languageManager)
                                case 2:
                                    CommunityView(selectedTab: $selectedTab)
                                        .environmentObject(languageManager)
                                case 3:
                                    StickerAlbumView(
                                        selectedTab: $selectedTab,
                                        collectionManager: collectionManager,
                                        lastCollectedVenue: $lastCollectedVenue,
                                        showCollectionAnimation: $showCollectionAnimation
                                    )
                                    .environmentObject(languageManager)
                                case 4:
                                    MerchantStatsView()
                                default:
                                    HomeView(selectedTab: $selectedTab, pendingMerchantPlace: .constant(nil))
                                        .environmentObject(languageManager)
                                }
                            }
                            .transition(.opacity)

                            // Tab Bar global en todos los tabs (ocultar en modo emergencia y cuando showDirections es true)
                            if !emergencyManager.isEmergencyActive {
                                VStack {
                                    Spacer()

                                    SimpleTabBar(selectedTab: $selectedTab, showSaleSheet: $showSaleSheet)
                                        .environmentObject(languageManager)
                                }
                                .zIndex(10)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .offset(y: navigationStateManager.showDirections && selectedTab == 1 ? 120 : 0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: navigationStateManager.showDirections)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
                            }

                            // LiveTrack Dynamic Island — "Uber al revés"
                            LiveTrackIslandView()
                                .zIndex(50)

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
                    .sheet(isPresented: $showSaleSheet) {
                        SaleFlowView()
                    }
                    .onChange(of: isLoggedIn) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "isUserLoggedIn")
                    }
                    .onChange(of: selectedTab) { _, newTab in
                        if newTab != 1 && navigationStateManager.showDirections {
                            navigationStateManager.showDirections = false
                        }
                    }
                }
            }
        .environment(\.layoutDirection, languageManager.layoutDirection)
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .animation(.easeInOut(duration: 0.5), value: showOnboarding)
        .animation(.easeInOut(duration: 0.5), value: isLoggedIn)
        .animation(.easeInOut(duration: 0.5), value: languageManager.currentLanguage)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: emergencyManager.isEmergencyActive)
        .onAppear {
            UserManager.shared.ensureMerchantLinked()
            handleAppIntentRequests()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                handleAppIntentRequests()
            } else if newPhase == .background {
                // Limpiar servicios al cerrar la app
                RadarService.shared.stopAll()
                PresenceManager.shared.stopBroadcasting()
                NavigationStateManager.shared.showDirections = false
                print("🔒 [App] Background: radar, presencia y navegación detenidos")
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
        // Detener todos los servicios activos
        RadarService.shared.stopAll()
        PresenceManager.shared.stopBroadcasting()
        NavigationStateManager.shared.showDirections = false
        NavigationStateManager.shared.isNavigationActive = false

        // Limpiar estado del usuario
        UserManager.shared.logout()

        // Resetear tab y UI
        selectedTab = 0

        withAnimation {
            isLoggedIn = false
        }
        UserDefaults.standard.set(false, forKey: "isUserLoggedIn")
        print("🔓 Logout completo: usuario, radar, presencia, navegación limpiados")
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
