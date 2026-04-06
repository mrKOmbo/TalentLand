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
    @State private var menuState = MenuStateManager.shared
    @State private var showSplash = true  // Temporalmente oculto para desarrollo
    @State private var showOnboarding = true  // Temporalmente oculto para desarrollo
    @State private var isLoggedIn: Bool = UserDefaults.standard.bool(forKey: "isUserLoggedIn")
    @State private var selectedTab = 0
    @State private var lastCollectedVenue: WorldCupVenue?
    @State private var showCollectionAnimation = false

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
                    // Show login after onboarding
                    LoginView(isLoggedIn: $isLoggedIn)
                        .environmentObject(languageManager)
                        .transition(.move(edge: .bottom))
                        .onChange(of: isLoggedIn) { _, newValue in
                            // Persistir el estado de login
                            UserDefaults.standard.set(newValue, forKey: "isUserLoggedIn")
                        }
                } else {
                    // Main app content with tab bar
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
                        .zIndex(menuState.showMenu ? 100 : 0) // Mayor zIndex cuando el menú está abierto

                        // Tab Bar global en todos los tabs (ocultar en modo emergencia)
                        if !emergencyManager.isEmergencyActive {
                            VStack {
                                Spacer()

                                VStack(spacing: 0) {
                                    SimpleTabBar(selectedTab: $selectedTab)
                                        .environmentObject(languageManager)
                                        .background(Color.black)
                                }
                                .cornerRadius(30, corners: [.topLeft, .topRight])
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            .padding(.bottom, -1000)
                                )
                                .clipped()
                            }
                            .ignoresSafeArea(edges: .bottom)
                            .zIndex(10) // Tab bar tiene zIndex 10
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .rotation3DEffect(
                                .degrees(menuState.showMenu && selectedTab == 0 ? 25 : 0),
                                axis: (x: 0, y: 1, z: 0),
                                anchor: .trailing,
                                perspective: 0.4
                            )
                            .offset(x: menuState.showMenu && selectedTab == 0 ? -300 : 0)
                            .scaleEffect(menuState.showMenu && selectedTab == 0 ? CGFloat(0.78) : CGFloat(1.0))
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: menuState.showMenu)
                        }

                        // Resplandor rojo ultrathink en todos los bordes (modo emergencia)
                        if emergencyManager.isEmergencyActive {
                            EmergencyGlowOverlay()
                                .zIndex(1000)
                                .allowsHitTesting(false)
                                .transition(.opacity)
                        }
                    }
                    .onChange(of: isLoggedIn) { _, newValue in
                        // Persistir el estado de login
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
