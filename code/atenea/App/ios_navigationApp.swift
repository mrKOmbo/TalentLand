import SwiftUI
import AppIntents
import CoreSpotlight
import CoreLocation

@main
struct ios_navigationApp: App {
    @StateObject private var emergencyModeManager = EmergencyModeManager.shared
    @StateObject private var navigationStateManager = NavigationStateManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
                    handleSpotlightActivity(userActivity)
                }
                .onAppear {
                    handleAppIntentRequests()
                    initializeSpotlightIndex()
                    MastodonService.shared.preload()
                }
                .environmentObject(emergencyModeManager)
                .environmentObject(navigationStateManager)
        }
    }

    // MARK: - Deep Linking Handler

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "atenea" else { return }

        print("🔗 [DEEP LINK] Recibido: \(url)")

        switch url.host {
        case "emergency":
            // Activar modo de emergencia
            DispatchQueue.main.async {
                EmergencyModeManager.shared.activateEmergency()

                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)

                print("🚨 Modo de emergencia activado desde widget")
            }

        case "navigation":
            // Manejar navegación
            if url.pathComponents.contains("active") {
                DispatchQueue.main.async {
                    // Solicitar abrir la navegación activa
                    NavigationStateManager.shared.requestOpenNavigation()

                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()

                    print("🧭 [DEEP LINK] Solicitado abrir navegación activa")
                }
            }

        default:
            print("⚠️ Deep link no reconocido: \(url)")
        }
    }

    // MARK: - App Intent Request Handler

    /// Maneja las solicitudes provenientes de App Intents
    private func handleAppIntentRequests() {
        // Verificar si hay una navegación pendiente desde un Intent
        if UserDefaults.standard.bool(forKey: "shouldStartNavigation"),
           let destination = UserDefaults.standard.dictionary(forKey: "pendingNavigationDestination"),
           let name = destination["name"] as? String,
           let latitude = destination["latitude"] as? Double,
           let longitude = destination["longitude"] as? Double {

            print("🧭 [APP INTENT] Procesando navegación pendiente a \(name)")

            // Activar navegación
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NavigationStateManager.shared.shouldOpenNavigation = true

                // Limpiar flags
                UserDefaults.standard.removeObject(forKey: "shouldStartNavigation")
                UserDefaults.standard.removeObject(forKey: "pendingNavigationDestination")
            }
        }

        // Verificar si debe navegar al estadio más cercano
        if UserDefaults.standard.bool(forKey: "shouldNavigateToNearest") {
            print("🧭 [APP INTENT] Procesando navegación al estadio más cercano")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NavigationStateManager.shared.shouldOpenNavigation = true

                // Limpiar flag
                UserDefaults.standard.removeObject(forKey: "shouldNavigateToNearest")
            }
        }

        // NOTA: El manejo de shouldOpenAlbum se realiza en ContentView

        // NOTA: Modo emergencia NO persiste entre sesiones
        // El modo emergencia es temporal y debe activarse manualmente en cada sesión
        // Limpiar cualquier estado persistido anterior
        UserDefaults.standard.set(false, forKey: "emergencyModeActive")
    }

    // MARK: - Spotlight Integration

    /// Inicializa el índice de Spotlight con el contenido de la app
    private func initializeSpotlightIndex() {
        // Indexar en background para no bloquear el inicio
        DispatchQueue.global(qos: .utility).async {
            SpotlightManager.shared.updateSpotlightIndex()
        }

        print("🔍 [SPOTLIGHT] Iniciando indexación de contenido")
    }

    /// Maneja la activación desde un resultado de Spotlight
    private func handleSpotlightActivity(_ userActivity: NSUserActivity) {
        guard let identifier = SpotlightManager.handleSpotlightActivity(userActivity) else {
            return
        }

        print("🔍 [SPOTLIGHT] Abriendo desde búsqueda: \(identifier)")

        // Parsear el identificador
        guard let (type, id) = SpotlightManager.parseIdentifier(identifier) else {
            print("⚠️ [SPOTLIGHT] No se pudo parsear identificador: \(identifier)")
            return
        }

        // Manejar según el tipo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            switch type {
            case "venue":
                // Buscar el venue y abrir navegación
                if let venue = WorldCupVenue.allVenues.first(where: { $0.id.uuidString == id }) {
                    handleSpotlightVenue(venue)
                }

            case "sticker-collection":
                // Abrir el álbum de stickers
                UserDefaults.standard.set(true, forKey: "shouldOpenAlbum")
                print("📖 [SPOTLIGHT] Abriendo álbum de stickers")

            default:
                print("⚠️ [SPOTLIGHT] Tipo no reconocido: \(type)")
            }
        }
    }

    /// Maneja la apertura de un venue desde Spotlight
    private func handleSpotlightVenue(_ venue: WorldCupVenue) {
        // Guardar destino para navegación
        let destination = [
            "name": venue.name,
            "latitude": venue.coordinate.latitude,
            "longitude": venue.coordinate.longitude
        ] as [String : Any]

        UserDefaults.standard.set(destination, forKey: "pendingNavigationDestination")
        UserDefaults.standard.set(true, forKey: "shouldStartNavigation")

        // Activar navegación
        NavigationStateManager.shared.shouldOpenNavigation = true

        print("🔍 [SPOTLIGHT] Iniciando navegación a \(venue.name) desde búsqueda")

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
