internal import MapboxDirections
import SwiftUI
import MapboxNavigationUIKit
import MapboxNavigationCore
import CoreLocation
import MapboxMaps
import UIKit
import ObjectiveC
import RealityKit
import ARKit
import AVFoundation
internal import Combine
import ActivityKit

// MARK: - Emergency Mode Manager

/// Gestor global del modo de emergencia que sincroniza el estado entre el modal y la navegación
class EmergencyModeManager: ObservableObject {
    static let shared = EmergencyModeManager()

    @Published var isEmergencyActive: Bool = false
    @Published var clientNIManager: NearbyInteractionManager?

    private init() {}

    /// Activa el modo de emergencia desde el cliente (usuario en peligro)
    func activateEmergency() {
        isEmergencyActive = true

        // Inicializar el NearbyInteractionManager como cliente
        if clientNIManager == nil {
            clientNIManager = NearbyInteractionManager(role: .client)
            clientNIManager?.start()
        }

        // Empezar a buscar staff cercano
        clientNIManager?.startBrowsing()

        print("🚨 Modo de emergencia ACTIVADO - Buscando staff cercano...")
    }

    /// Desactiva el modo de emergencia
    func deactivateEmergency() {
        isEmergencyActive = false

        // Detener el NearbyInteractionManager
        clientNIManager?.stop()
        clientNIManager = nil

        print("✅ Modo de emergencia DESACTIVADO")
    }
}

// MARK: - Arrow Icon Creation
extension NavigationViewWrapper {
    /// Crea un icono de flecha programáticamente para usar en las direcciones de ruta
    static func createArrowIcon(size: CGSize = CGSize(width: 12, height: 12),
                               color: UIColor = .systemBlue) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let path = UIBezierPath()

            // Crear triángulo apuntando hacia la derecha (se auto-rotará con la línea)
            path.move(to: CGPoint(x: size.width, y: size.height / 2))  // Punta
            path.addLine(to: CGPoint(x: 0, y: 0))                        // Arriba izquierda
            path.addLine(to: CGPoint(x: 0, y: size.height))              // Abajo izquierda
            path.close()

            color.setFill()
            path.fill()
        }
    }

    /// Agrega flechas direccionales a la ruta de navegación
    static func addRouteArrows(to mapView: MapView, routeCoordinates: [CLLocationCoordinate2D]) {
        // Crear y agregar el icono de flecha
        let arrowImage = createArrowIcon(size: CGSize(width: 12, height: 12),
                                          color: .systemBlue)

        do {
            try mapView.mapboxMap.addImage(arrowImage, id: "route-arrow-icon")
            print("✅ Icono de flecha agregado al mapa")
        } catch {
            print("❌ Error agregando icono de flecha: \(error)")
            return
        }

        // Crear LineString desde las coordenadas de la ruta
        let lineCoordinates = routeCoordinates.map { coord in
            LocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
        }
        let lineString = LineString(lineCoordinates)

        // Crear GeoJSON source para la ruta
        var source = GeoJSONSource(id: "route-arrows-source")
        source.data = .geometry(.lineString(lineString))

        do {
            try mapView.mapboxMap.addSource(source)
            print("✅ Source de ruta para flechas agregado")
        } catch {
            print("❌ Error agregando source de ruta: \(error)")
            return
        }

        // Agregar SymbolLayer con flechas direccionales
        var arrowLayer = SymbolLayer(id: "route-arrows-layer", source: "route-arrows-source")
        arrowLayer.symbolPlacement = .constant(.line)                    // Colocar a lo largo de la línea
        arrowLayer.iconImage = .constant(.name("route-arrow-icon"))     // Usar el icono de flecha
        arrowLayer.symbolSpacing = .constant(75.0)                       // Flecha cada 75px
        arrowLayer.iconSize = .constant(0.8)                             // Escala al 80%
        arrowLayer.iconAllowOverlap = .constant(true)                    // Siempre mostrar flechas
        arrowLayer.iconKeepUpright = .constant(true)                     // Nunca al revés
        arrowLayer.iconRotationAlignment = .constant(.map)               // Rotar con la ruta

        do {
            try mapView.mapboxMap.addLayer(arrowLayer)
            print("✅ Layer de flechas direccionales agregado")
        } catch {
            print("❌ Error agregando layer de flechas: \(error)")
        }
    }
}

// MARK: - AR Navigation SwiftUI View

struct ARNavigationView: View {
    @StateObject private var arrowManager = ArrowNavigationManager()
    @StateObject private var textDetectionManager = TextDetectionManager()
    @Environment(\.dismiss) var dismiss
    @State private var showArrowOverlay = true
    @State private var isInCorrectRange = false
    @State private var hasVibratedForCorrectDirection = false
    @State private var isScanning = false
    @State private var detectedPlanesCount = 0

    var body: some View {
        ZStack {
            // AR View con flecha 3D animada (siempre visible para mantener AR activo)
            if arrowManager.isArrowVisible {
                AnimatedArrowOverlay(
                    arrowManager: arrowManager,
                    textDetectionManager: textDetectionManager,
                    showOverlays: showArrowOverlay
                )
                .ignoresSafeArea(.all, edges: [.bottom, .horizontal])
            }

            // Indicador de dirección correcta y botones
            VStack {
                // Indicador de dirección correcta en la parte superior
                HStack {
                    if isInCorrectRange {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.green)

                            Text(String(localized: "ar.nav.correctDirection"))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.9))
                        )
                        .shadow(color: .green.opacity(0.5), radius: 10, x: 0, y: 4)
                        .transition(.scale.combined(with: .opacity))
                        .padding(.leading, 20)
                    }

                    Spacer()
                }
                .padding(.top, 8)

                Spacer()

                // Cuadrito de texto detectado
                if !textDetectionManager.detectedTexts.isEmpty,
                   let lastDetectedText = textDetectionManager.detectedTexts.last {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "text.viewfinder")
                                .font(.caption)
                                .foregroundColor(.green)

                            Text(String(localized: "ar.nav.textDetected"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.8))
                        }

                        Text(lastDetectedText.text)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)

                        HStack {
                            Spacer()
                            Text("\(String(localized: "ar.nav.confidence")) \(Int(lastDetectedText.confidence * 100))%")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.85))
                            .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: textDetectionManager.detectedTexts.count)
                }

                // Indicador de planos detectados durante el escaneo
                if isScanning {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.metering.multispot")
                            .font(.system(size: 16))
                            .foregroundColor(.purple)

                        Text(String(format: LocalizedString("navigation.planesDetected"), detectedPlanesCount))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.purple.opacity(0.9))
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Botones de toggle de flecha y escaneo en horizontal
                HStack(spacing: 12) {
                    // Botón de escaneo de entorno
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isScanning.toggle()

                            // Controlar detección de planos en ArrowNavigationManager
                            if isScanning {
                                arrowManager.startPlaneDetection()
                            } else {
                                arrowManager.stopPlaneDetection()
                                detectedPlanesCount = 0
                            }
                        }

                        // Feedback háptico
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isScanning ? "stop.circle.fill" : "camera.viewfinder")
                                .font(.system(size: 16))
                            Text(isScanning ? String(localized: "ar.nav.stopScan") : String(localized: "ar.nav.scanEnvironment"))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(isScanning ? Color.red.opacity(0.9) : Color.purple.opacity(0.9))
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }

                    // Botón de toggle de flecha
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showArrowOverlay.toggle()
                        }

                        // Feedback háptico
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: showArrowOverlay ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 16))
                            Text(showArrowOverlay ? String(localized: "ar.nav.hideArrow") : String(localized: "ar.nav.showArrow"))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(showArrowOverlay ? Color.blue.opacity(0.9) : Color.green.opacity(0.9))
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        .overlay(
                            // Borde brillante cuando está en dirección correcta
                            Capsule()
                                .stroke(Color.green, lineWidth: isInCorrectRange ? 3 : 0)
                                .shadow(color: .green.opacity(0.8), radius: isInCorrectRange ? 8 : 0)
                                .animation(.easeInOut(duration: 0.3), value: isInCorrectRange)
                        )
                    }
                }
                .padding(.bottom, 8)

                // Botón de cerrar (Salir de AR)
                Button(action: {
                    arrowManager.hideArrow()
                    textDetectionManager.stopDetection()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text(String(localized: "ar.nav.exitAR"))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.9))
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
                }
                .padding(.bottom, 30)
            }
        }
        .onChange(of: arrowManager.deviceHeading) { _, newHeading in
            // Verificar si está en la dirección correcta
            checkIfInCorrectDirection()
        }
        .onAppear {
            // Iniciar AR apuntando al norte por defecto
            // (En una implementación real, aquí calcularías la dirección al destino de navegación)
            let dummyARView = ARView(frame: .zero)
            arrowManager.showArrow(in: dummyARView)
            arrowManager.setTargetDirection(degrees: 0) // Norte por defecto

            // Iniciar detección de texto
            textDetectionManager.startDetection()
            print("📝 Detección de texto iniciada en AR Navigation")

            // Iniciar timer para verificación continua de dirección
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                if !arrowManager.isArrowVisible {
                    timer.invalidate()
                    return
                }
                checkIfInCorrectDirection()
            }

            // Sincronizar contador de planos detectados
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
                if !arrowManager.isArrowVisible {
                    timer.invalidate()
                    return
                }
                detectedPlanesCount = arrowManager.detectedPlanesCount
            }
        }
        .onDisappear {
            arrowManager.hideArrow()
            textDetectionManager.stopDetection()
        }
    }

    // MARK: - Helper Functions

    /// Verifica si el usuario está apuntando en la dirección correcta y proporciona feedback háptico
    private func checkIfInCorrectDirection() {
        let relativeDirection = arrowManager.targetDirection - arrowManager.deviceHeading
        var normalized = relativeDirection

        // Normalizar el ángulo entre -180 y 180
        while normalized > 180 { normalized -= 360 }
        while normalized < -180 { normalized += 360 }

        // Verificar si está dentro del rango correcto (±15°)
        let isNowInCorrectRange = abs(normalized) < 15

        // Si entró en el rango correcto y no ha vibrado aún
        if isNowInCorrectRange && !isInCorrectRange {
            // Vibración de éxito
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            print("✅ Usuario en dirección correcta - Vibrando")
            hasVibratedForCorrectDirection = true
        }
        // Si salió del rango correcto
        else if !isNowInCorrectRange && isInCorrectRange {
            hasVibratedForCorrectDirection = false
        }

        // Actualizar estado
        isInCorrectRange = isNowInCorrectRange
    }
}

// Helper class for Emergency Deactivation button
class EmergencyDeactivationHandler: NSObject {
    weak var button: UIButton?
    var cancellable: AnyCancellable?

    init(button: UIButton) {
        self.button = button
        super.init()

        // Observar cambios en el modo de emergencia
        cancellable = EmergencyModeManager.shared.$isEmergencyActive
            .sink { [weak self, weak button] isActive in
                guard let button = button else { return }
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.3) {
                        button.alpha = isActive ? 1.0 : 0.0
                        button.transform = isActive ? .identity : CGAffineTransform(scaleX: 0.8, y: 0.8)
                    }
                }
            }

        // Conectar acción
        button.addTarget(self, action: #selector(deactivateEmergency(_:)), for: .touchUpInside)
    }

    @objc func deactivateEmergency(_ sender: UIButton) {
        // Animar botón
        UIView.animate(withDuration: 0.2) {
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                sender.transform = .identity
            }
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Desactivar modo de emergencia
        EmergencyModeManager.shared.deactivateEmergency()
    }
}

// Helper class for Emergency button
class EmergencyButtonHandler: NSObject, ObservableObject {
    weak var navigationViewController: NavigationViewController?
    var hostingController: UIHostingController<AnyView>?
    var showEmergencyModal = false

    // Implementación manual de ObservableObject
    let objectWillChange = ObservableObjectPublisher()

    init(navigationViewController: NavigationViewController) {
        self.navigationViewController = navigationViewController
        super.init()
    }

    @objc func emergencyButtonTapped(_ sender: UIButton) {
        guard let navigationViewController = navigationViewController else { return }

        // Animar botón
        UIView.animate(withDuration: 0.2) {
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                sender.transform = .identity
            }
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)

        // Abrir modal de emergencia
        openEmergencyModal()
    }

    private func openEmergencyModal() {
        guard let navigationViewController = navigationViewController else { return }

        // Crear vista SwiftUI de Emergency con binding mutable
        let emergencyView = EmergencyModalWrapper(handler: self)
        let hostingController = UIHostingController(rootView: AnyView(emergencyView))
        hostingController.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        hostingController.view.backgroundColor = UIColor.clear

        // Guardar referencia
        self.hostingController = hostingController

        DispatchQueue.main.async {
            navigationViewController.present(hostingController, animated: true) {
                print("🚨 Modal de emergencia abierto durante navegación")
            }
        }
    }

    func dismissModal() {
        hostingController?.dismiss(animated: true)
    }
}

// Wrapper para EmergencyModal que maneja el estado
struct EmergencyModalWrapper: View {
    @ObservedObject var handler: EmergencyButtonHandler
    @State private var isPresented = true
    @StateObject private var languageManager = LanguageManager.shared
    @ObservedObject private var emergencyManager = EmergencyModeManager.shared

    var body: some View {
        EmergencyModal(
            isPresented: $isPresented,
            userLocation: nil,
            onEmergencyActivated: {
                // Activar modo de emergencia
                EmergencyModeManager.shared.activateEmergency()
            }
        )
        .environmentObject(languageManager)
        .onChange(of: isPresented) { newValue in
            if !newValue {
                handler.dismissModal()
            }
        }
    }
}

// Helper class for AR button
class ARButtonHandler: NSObject {
    weak var navigationViewController: NavigationViewController?
    var hostingController: UIHostingController<ARNavigationView>?

    init(navigationViewController: NavigationViewController) {
        self.navigationViewController = navigationViewController
        super.init()
    }

    @objc func arButtonTapped(_ sender: UIButton) {
        guard let navigationViewController = navigationViewController else { return }

        // Animar botón
        UIView.animate(withDuration: 0.2) {
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                sender.transform = .identity
            }
        }

        // Verificar soporte de AR
        guard ARWorldTrackingConfiguration.isSupported else {
            showARNotSupportedAlert()
            return
        }

        // Solicitar permisos de cámara para AR
        checkCameraPermissions { [weak self] granted in
            if granted {
                self?.openARNavigation()
            } else {
                self?.showCameraPermissionAlert()
            }
        }
    }

    private func checkCameraPermissions(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            completion(true)

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }

        case .denied, .restricted:
            completion(false)

        @unknown default:
            completion(false)
        }
    }

    private func openARNavigation() {
        guard let navigationViewController = navigationViewController else { return }

        // Crear vista SwiftUI de AR
        let arView = ARNavigationView()
        let hostingController = UIHostingController(rootView: arView)
        hostingController.modalPresentationStyle = .fullScreen

        // Guardar referencia
        self.hostingController = hostingController

        DispatchQueue.main.async {
            navigationViewController.present(hostingController, animated: true) {
                print("🥽 AR Navigation con sistema ultrathink abierta")
            }
        }
    }

    private func showARNotSupportedAlert() {
        guard let navigationViewController = navigationViewController else { return }

        let alert = UIAlertController(
            title: LocalizedString("navigation.arNotSupported"),
            message: LocalizedString("navigation.arNotSupportedDesc"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: LocalizedString("action.accept"), style: .default))

        DispatchQueue.main.async {
            navigationViewController.present(alert, animated: true)
        }
    }

    private func showCameraPermissionAlert() {
        guard let navigationViewController = navigationViewController else { return }

        let alert = UIAlertController(
            title: LocalizedString("navigation.cameraRequired"),
            message: LocalizedString("navigation.cameraRequiredDesc"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: LocalizedString("action.cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: LocalizedString("action.openSettings"), style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })

        DispatchQueue.main.async {
            navigationViewController.present(alert, animated: true)
        }
    }
}

// Coordinator to bridge UIKit's NavigationViewController delegate with SwiftUI
class Coordinator: NSObject, NavigationViewControllerDelegate {
    var onCancel: () -> Void
    var arButtonHandler: ARButtonHandler?
    var emergencyButtonHandler: EmergencyButtonHandler?
    var navigationStateObserver: NavigationStateObserver?
    var dynamicIslandHostingController: UIHostingController<NavigationDynamicIslandHostingView>?
    var emergencyModeObserver: AnyCancellable?
    weak var navigationViewController: NavigationViewController?

    // Live Activity para Dynamic Island
    var activity: Activity<NavigationActivityAttributes>?
    var destinationName: String = ""

    // Initialize with a closure that will be called when navigation is cancelled or dismissed
    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
        super.init()
        setupEmergencyModeObserver()
    }

    private func setupEmergencyModeObserver() {
        emergencyModeObserver = EmergencyModeManager.shared.$isEmergencyActive
            .sink { [weak self] isActive in
                self?.updateUserPuckForEmergency(isActive: isActive)
            }
    }

    private func updateUserPuckForEmergency(isActive: Bool) {
        guard let navigationViewController = navigationViewController,
              let mapView = navigationViewController.navigationMapView?.mapView else {
            return
        }

        if isActive {
            // Cambiar a marcador rojo simple sin pulsing para evitar problemas de rendimiento
            var configuration = Puck2DConfiguration()
            configuration.topImage = createEmergencyPuckImage()
            configuration.scale = .constant(1.0)

            mapView.location.options.puckType = .puck2D(configuration)
            print("🚨 Marcador de usuario cambiado a MODO EMERGENCIA")
        } else {
            // Restaurar marcador predeterminado
            mapView.location.options.puckType = .puck2D()
            print("✅ Marcador de usuario restaurado al modo normal")
        }
    }

    private func createEmergencyPuckImage() -> UIImage {
        let size = CGSize(width: 60, height: 60)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Círculo rojo de fondo
            UIColor.systemRed.setFill()
            let outerCircle = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            outerCircle.fill()

            // Círculo blanco interior
            UIColor.white.setFill()
            let innerCircle = UIBezierPath(ovalIn: CGRect(x: 10, y: 10, width: size.width - 20, height: size.height - 20))
            innerCircle.fill()

            // Punto rojo en el centro
            UIColor.systemRed.setFill()
            let centerDot = UIBezierPath(ovalIn: CGRect(x: 20, y: 20, width: size.width - 40, height: size.height - 40))
            centerDot.fill()
        }
    }

    // MARK: - Live Activity Management

    func startLiveActivity(destinationName: String) {
        self.destinationName = destinationName

        print("🔵 [LIVE ACTIVITY] Intentando iniciar Live Activity para: \(destinationName)")

        // Verificar que Live Activities estén habilitadas
        let authInfo = ActivityAuthorizationInfo()
        print("🔵 [LIVE ACTIVITY] Estado de autorización: \(authInfo.areActivitiesEnabled)")

        guard authInfo.areActivitiesEnabled else {
            print("⚠️ [LIVE ACTIVITY] Live Activities NO están habilitadas en el sistema")
            print("⚠️ [LIVE ACTIVITY] Ve a Ajustes > Atenea y habilita 'Live Activities'")
            return
        }

        // Intentar obtener una actividad existente primero
        let existingActivities = Activity<NavigationActivityAttributes>.activities
        print("🔵 [LIVE ACTIVITY] Actividades existentes: \(existingActivities.count)")

        if let existingActivity = existingActivities.first {
            // Usar la actividad existente y actualizarla
            activity = existingActivity
            print("✅ [LIVE ACTIVITY] Usando Live Activity existente: \(existingActivity.id)")
            return
        }

        // Si no existe, crear una nueva con animación bonita
        let attributes = NavigationActivityAttributes(
            destinationName: destinationName,
            destinationCity: "",
            totalDistance: 0,
            startTime: Date(),
            venueColorHex: "#00A651"
        )
        let initialState = NavigationActivityAttributes.ContentState(
            distanceRemaining: 0,
            estimatedMinutes: 0,
            currentInstruction: LocalizedString("navigation.startingNavigation"),
            currentStreet: "",
            currentSpeed: 0,
            lastUpdate: Date(),
            navigationState: .active
        )

        print("🔵 [LIVE ACTIVITY] Creando nueva Live Activity...")

        do {
            // Iniciar la actividad con contenido inicial
            activity = try Activity<NavigationActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            print("✅ [LIVE ACTIVITY] Live Activity INICIADA EXITOSAMENTE!")
            print("✅ [LIVE ACTIVITY] ID: \(activity?.id ?? "unknown")")
            print("✅ [LIVE ACTIVITY] Destino: \(destinationName)")

            // Haptic feedback para indicar que se inició
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // ANIMACIÓN INICIAL: Mostrar alerta en Dynamic Island al iniciar navegación
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 segundos
                guard let self = self, let activity = self.activity else {
                    print("⚠️ [LIVE ACTIVITY] No se pudo obtener referencia a la actividad")
                    return
                }

                // Crear alerta animada para mostrar inicio de navegación
                let startedTitle = LocalizedString("navigation.started")
                let headingBody = "\(LocalizedString("navigation.headingTo")) \(destinationName)"
                let alertConfig = AlertConfiguration(
                    title: LocalizedStringResource(stringLiteral: startedTitle),
                    body: LocalizedStringResource(stringLiteral: headingBody),
                    sound: .default
                )

                let startState = NavigationActivityAttributes.ContentState(
                    distanceRemaining: 0,
                    estimatedMinutes: 0,
                    currentInstruction: "🚀 Navegación iniciada",
                    currentStreet: "",
                    currentSpeed: 0,
                    lastUpdate: Date(),
                    navigationState: .active
                )

                Task {
                    // Actualizar con animación de alerta
                    await activity.update(
                        ActivityContent(
                            state: startState,
                            staleDate: nil
                        ),
                        alertConfiguration: alertConfig
                    )
                    print("🎬 [LIVE ACTIVITY] Animación de inicio mostrada en Dynamic Island")
                }
            }

            // Después de un breve delay, actualizar con el mensaje de cálculo
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 segundos
                guard let self = self, let activity = self.activity else {
                    print("⚠️ [LIVE ACTIVITY] No se pudo obtener referencia a la actividad")
                    return
                }

                let readyState = NavigationActivityAttributes.ContentState(
                    distanceRemaining: 0,
                    estimatedMinutes: 0,
                    currentInstruction: LocalizedString("navigation.calculatingRoute"),
                    currentStreet: "",
                    currentSpeed: 0,
                    lastUpdate: Date(),
                    navigationState: .active
                )

                await activity.update(using: readyState)
                print("✅ [LIVE ACTIVITY] Actualizada a estado 'Calculando ruta'")
            }
        } catch {
            print("❌ [LIVE ACTIVITY] ERROR al iniciar Live Activity:")
            print("❌ [LIVE ACTIVITY] \(error.localizedDescription)")
            print("❌ [LIVE ACTIVITY] Detalles: \(error)")
        }
    }

    func updateLiveActivity(instruction: String, distanceRemaining: Double, timeRemaining: Double) {
        guard let activity = activity else {
            print("⚠️ [LIVE ACTIVITY] No hay actividad activa para actualizar")
            return
        }

        // Convertir timeRemaining de segundos a minutos
        let estimatedMinutes = Int(timeRemaining / 60)

        // Crear estado actualizado
        let updatedState = NavigationActivityAttributes.ContentState(
            distanceRemaining: distanceRemaining,
            estimatedMinutes: estimatedMinutes,
            currentInstruction: instruction,
            currentStreet: "",
            currentSpeed: 0,
            lastUpdate: Date(),
            navigationState: .active
        )

        print("🔄 [LIVE ACTIVITY] Actualizando: \(instruction) | \(distanceRemaining)m | \(timeRemaining)s")

        // Actualizar de forma asíncrona con animación implícita
        Task {
            await activity.update(
                ActivityContent(
                    state: updatedState,
                    staleDate: Date().addingTimeInterval(60) // Marcar como obsoleto después de 1 minuto
                ),
                alertConfiguration: nil
            )
        }
    }

    func stopLiveActivity() {
        guard let activity = activity else { return }

        // Finalizar la actividad
        Task {
            await activity.end(using: nil, dismissalPolicy: .immediate)
        }

        self.activity = nil
        print("✅ Live Activity detenida")
    }

    // Called when the NavigationViewController is dismissed
    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        print("Dismissed. Canceled: \(canceled)")

        // Detener Live Activity al cerrar navegación
        stopLiveActivity()

        // Marcar navegación como inactiva
        NavigationStateManager.shared.stopNavigation()

        onCancel() // Invoke the callback to dismiss the SwiftUI sheet
    }

    // Called as the user progresses along the route
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        didUpdate progress: RouteProgress,
        with location: CLLocation,
        rawLocation: CLLocation
    ) {
        // Actualizar el estado de la Dynamic Island con el progreso de navegación
        navigationStateObserver?.update(with: progress)

        // Actualizar Live Activity con el progreso actual
        let currentStep = progress.currentLegProgress.currentStepProgress.step
        let instruction = currentStep.instructions.isEmpty ? LocalizedString("navigation.continueStraight") : currentStep.instructions
        let distanceRemaining = progress.distanceRemaining
        let timeRemaining = progress.durationRemaining

        updateLiveActivity(
            instruction: instruction,
            distanceRemaining: distanceRemaining,
            timeRemaining: timeRemaining
        )
    }
}



// SwiftUI wrapper to embed the Mapbox NavigationViewController
struct NavigationViewWrapper: UIViewControllerRepresentable {
    let preparedNavigation: PreparedNavigation
    var onCancel: () -> Void = {}  // Callback when navigation is cancelled
    
    // Provides the coordinator instance for delegate handling
    func makeCoordinator() -> Coordinator {
        Coordinator(onCancel: onCancel)
    }
    
    // Creates the UIKit view controller that hosts the navigation experience
    func makeUIViewController(context: Context) -> UIViewController {
        let routes = preparedNavigation.routes
        let navigationProvider = preparedNavigation.navigationProvider
        let navigationOptions = NavigationOptions(
            mapboxNavigation: navigationProvider.mapboxNavigation,
            voiceController: navigationProvider.routeVoiceController,
            eventsManager: navigationProvider.eventsManager()
        )

        // 4. Create a NavigationViewController using the routes and options
        let navigationViewController = NavigationViewController(
            navigationRoutes: routes,
            navigationOptions: navigationOptions
        )

        navigationViewController.delegate = context.coordinator // Set the delegate for dismissal
        navigationViewController.routeLineTracksTraversal = true // Show route line tracking
        navigationViewController.modalPresentationStyle = .fullScreen

        // Guardar referencia en el coordinator para el modo de emergencia
        context.coordinator.navigationViewController = navigationViewController

        // Iniciar Live Activity para Dynamic Island
        let destinationName = routes.waypoints.last?.name ?? LocalizedString("navigation.destination")
        context.coordinator.startLiveActivity(destinationName: destinationName)

        // Marcar navegación como activa
        NavigationStateManager.shared.startNavigation()

        // PERSONALIZACIÓN ESTÉTICA ULTRATHINK
        customizeNavigationAppearance(navigationViewController, coordinator: context.coordinator)

        // Optionally set the initial camera view with validation
        if let origin = routes.waypoints.first?.coordinate,
           CLLocationCoordinate2DIsValid(origin),
           !(origin.latitude == 0.0 && origin.longitude == 0.0),
           origin.latitude.isFinite && origin.longitude.isFinite {
            navigationViewController.navigationMapView?.mapView.mapboxMap.setCamera(
                to: CameraOptions(center: origin, zoom: 15.0, pitch: 45.0)
            )
        }

        // Agregar flechas direccionales a la ruta
        if let mapView = navigationViewController.navigationMapView?.mapView,
           let routeCoordinates = routes.mainRoute.route.shape?.coordinates {
            NavigationViewWrapper.addRouteArrows(to: mapView, routeCoordinates: routeCoordinates)
        }

        return navigationViewController
    }

    // MARK: - Personalización Estética

    private func customizeNavigationAppearance(_ navigationViewController: NavigationViewController, coordinator: Coordinator) {
        // Aplicar personalizaciones sutiles y elegantes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.applyModernStyling(to: navigationViewController, coordinator: coordinator)
        }

        print("✨ Personalización estética ultrathink aplicada")
    }

    private func applyModernStyling(to navigationViewController: NavigationViewController, coordinator: Coordinator) {
        guard let navigationView = navigationViewController.view else { return }

        // Configurar layout del mapa
        if let navigationMapView = navigationViewController.navigationMapView {
            // Ajustar el layout para que respete el safe area
            navigationMapView.layoutMargins = UIEdgeInsets(
                top: 44,
                left: 0,
                bottom: 0,
                right: 0
            )
        }

        // Dynamic Island activada
        addDynamicIsland(to: navigationViewController, coordinator: coordinator)

        // Agregar botón de emergencia
        addEmergencyButton(to: navigationViewController, coordinator: coordinator)

        // Agregar botón de AR
        addARButton(to: navigationViewController, coordinator: coordinator)

        // Agregar botón para desactivar modo emergencia
        addEmergencyDeactivationButton(to: navigationViewController, coordinator: coordinator)

        // Aplicar estilos solo a elementos específicos de manera conservadora
        self.styleNavigationElements(in: navigationView, depth: 0)
    }

    private func addDynamicIsland(to navigationViewController: NavigationViewController, coordinator: Coordinator) {
        guard let navigationView = navigationViewController.view else { return }

        // Crear el observer para el estado de navegación
        let stateObserver = NavigationStateObserver()
        coordinator.navigationStateObserver = stateObserver

        // Crear la vista SwiftUI de Dynamic Island
        let dynamicIslandView = NavigationDynamicIslandHostingView(navigationState: stateObserver)
        let hostingController = UIHostingController(rootView: dynamicIslandView)

        // Configurar el hosting controller
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        // Guardar referencia
        coordinator.dynamicIslandHostingController = hostingController

        // Agregar como child view controller
        navigationViewController.addChild(hostingController)
        navigationView.addSubview(hostingController.view)
        hostingController.didMove(toParent: navigationViewController)

        // Constraints - arriba y centrado (estilo Google Maps)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: navigationView.safeAreaLayoutGuide.topAnchor, constant: 12),
            hostingController.view.centerXAnchor.constraint(equalTo: navigationView.centerXAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: navigationView.widthAnchor),
            hostingController.view.heightAnchor.constraint(equalToConstant: 220) // Altura para expandido
        ])

        // Asegurar que no tape las instrucciones de navegación
        hostingController.view.isUserInteractionEnabled = true
        hostingController.view.layer.zPosition = 100


        print("🏝️ Dynamic Island estilo Google Maps agregada (compacta y elegante)")
    }

    private func addARButton(to navigationViewController: NavigationViewController, coordinator: Coordinator) {
        guard let navigationView = navigationViewController.view else { return }

        // Crear handler para el botón
        let handler = ARButtonHandler(navigationViewController: navigationViewController)
        coordinator.arButtonHandler = handler

        // Crear botón de AR
        let arButton = UIButton(type: .system)
        arButton.translatesAutoresizingMaskIntoConstraints = false

        // Configuración del ícono de AR
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let arIcon = UIImage(systemName: "arkit", withConfiguration: config)
        arButton.setImage(arIcon, for: .normal)
        arButton.tintColor = .white

        // Estilo ultrathink - gradiente morado/azul para AR
        arButton.backgroundColor = UIColor.systemPurple
        arButton.layer.cornerRadius = 25
        arButton.layer.shadowColor = UIColor.systemPurple.cgColor
        arButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        arButton.layer.shadowRadius = 12
        arButton.layer.shadowOpacity = 0.4

        // Agregar a la vista
        navigationView.addSubview(arButton)

        // Constraints - esquina inferior derecha, arriba del botón X
        NSLayoutConstraint.activate([
            arButton.trailingAnchor.constraint(equalTo: navigationView.trailingAnchor, constant: -20),
            arButton.bottomAnchor.constraint(equalTo: navigationView.safeAreaLayoutGuide.bottomAnchor, constant: -90),
            arButton.widthAnchor.constraint(equalToConstant: 50),
            arButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        // Acción del botón
        arButton.addTarget(handler, action: #selector(ARButtonHandler.arButtonTapped(_:)), for: .touchUpInside)

        print("🥽 Botón de AR agregado")
    }

    private func addEmergencyButton(to navigationViewController: NavigationViewController, coordinator: Coordinator) {
        guard let navigationView = navigationViewController.view else { return }

        // Crear handler para el botón
        let handler = EmergencyButtonHandler(navigationViewController: navigationViewController)
        coordinator.emergencyButtonHandler = handler

        // Crear botón de emergencia
        let emergencyButton = UIButton(type: .system)
        emergencyButton.translatesAutoresizingMaskIntoConstraints = false

        // Configuración del ícono de emergencia
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        let emergencyIcon = UIImage(systemName: "exclamationmark.triangle.fill", withConfiguration: config)
        emergencyButton.setImage(emergencyIcon, for: .normal)
        emergencyButton.tintColor = .white

        // Estilo igual al de la pantalla principal - rojo con sombra
        emergencyButton.backgroundColor = UIColor.systemRed
        emergencyButton.layer.cornerRadius = 25
        emergencyButton.layer.shadowColor = UIColor.systemRed.cgColor
        emergencyButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        emergencyButton.layer.shadowRadius = 8
        emergencyButton.layer.shadowOpacity = 0.4

        // Agregar a la vista
        navigationView.addSubview(emergencyButton)

        // Constraints - esquina inferior izquierda, mismo nivel que el botón de AR
        NSLayoutConstraint.activate([
            emergencyButton.leadingAnchor.constraint(equalTo: navigationView.leadingAnchor, constant: 20),
            emergencyButton.bottomAnchor.constraint(equalTo: navigationView.safeAreaLayoutGuide.bottomAnchor, constant: -90),
            emergencyButton.widthAnchor.constraint(equalToConstant: 50),
            emergencyButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        // Acción del botón
        emergencyButton.addTarget(handler, action: #selector(EmergencyButtonHandler.emergencyButtonTapped(_:)), for: .touchUpInside)

        print("🚨 Botón de emergencia agregado")
    }

    private func addEmergencyDeactivationButton(to navigationViewController: NavigationViewController, coordinator: Coordinator) {
        guard let navigationView = navigationViewController.view else { return }

        // Crear botón de desactivación de emergencia
        let deactivateButton = UIButton(type: .system)
        deactivateButton.translatesAutoresizingMaskIntoConstraints = false
        deactivateButton.alpha = 0 // Inicialmente invisible
        deactivateButton.tag = 9999 // Tag para identificarlo

        // Configuración del ícono
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        let checkIcon = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
        deactivateButton.setImage(checkIcon, for: .normal)
        deactivateButton.tintColor = .white

        // Texto del botón
        deactivateButton.setTitle(" End Emergency", for: .normal)
        deactivateButton.setTitleColor(.white, for: .normal)
        deactivateButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        // Estilo - verde para indicar que todo está bien
        deactivateButton.backgroundColor = UIColor.systemGreen
        deactivateButton.layer.cornerRadius = 25
        deactivateButton.layer.shadowColor = UIColor.systemGreen.cgColor
        deactivateButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        deactivateButton.layer.shadowRadius = 12
        deactivateButton.layer.shadowOpacity = 0.5
        deactivateButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)

        // Agregar a la vista
        navigationView.addSubview(deactivateButton)

        // Constraints - centrado horizontalmente, arriba de los otros botones
        NSLayoutConstraint.activate([
            deactivateButton.centerXAnchor.constraint(equalTo: navigationView.centerXAnchor),
            deactivateButton.bottomAnchor.constraint(equalTo: navigationView.safeAreaLayoutGuide.bottomAnchor, constant: -160),
            deactivateButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        // Crear handler para el botón
        let handler = EmergencyDeactivationHandler(button: deactivateButton)

        // Guardar handler en associated object para evitar desalojo
        objc_setAssociatedObject(
            deactivateButton,
            "handler",
            handler,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        print("✅ Botón de desactivación de emergencia agregado")
    }

    private func styleNavigationElements(in view: UIView, depth: Int) {
        // Limitar profundidad de recursión para evitar problemas
        guard depth < 10 else { return }

        for subview in view.subviews {
            let className = String(describing: type(of: subview))

            // Estilizar solo tipos específicos conocidos
            if let button = subview as? UIButton {
                styleModernButton(button)
            }

            // Detectar contenedores de UI por nombre de clase (más confiable)
            if className.contains("Banner") || className.contains("Instruction") {
                styleBannerContainer(subview)
            }

            // Detectar indicadores pequeños
            if className.contains("Speed") || className.contains("Limit") {
                styleIndicator(subview)
            }

            // Continuar búsqueda recursiva
            styleNavigationElements(in: subview, depth: depth + 1)
        }
    }

    private func styleModernButton(_ button: UIButton) {
        // Solo aplicar si el botón no tiene ya un estilo muy específico
        guard button.layer.cornerRadius < 5 else { return }

        button.layer.cornerRadius = 14
        button.clipsToBounds = false

        // Sombra sutil
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 6
        button.layer.shadowOpacity = 0.15
    }

    private func styleBannerContainer(_ view: UIView) {
        // Aplicar esquinas redondeadas solo si la vista es lo suficientemente grande
        guard view.bounds.width > 100 else { return }

        // Detectar si es top o bottom por posición
        let screenHeight = UIScreen.main.bounds.height
        let isTopBanner = view.frame.origin.y < screenHeight / 3

        if isTopBanner {
            // Banner superior - sin esquinas redondeadas para evitar recortes
            view.clipsToBounds = false
            view.layer.masksToBounds = false

            // Solo agregar sombra sutil
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOffset = CGSize(width: 0, height: 2)
            view.layer.shadowRadius = 8
            view.layer.shadowOpacity = 0.08
        } else {
            // Banner inferior - esquinas superiores redondeadas
            view.layer.cornerRadius = 16
            view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            view.layer.masksToBounds = true

            // Sombra
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOffset = CGSize(width: 0, height: -2)
            view.layer.shadowRadius = 8
            view.layer.shadowOpacity = 0.1
        }
    }

    private func styleIndicator(_ view: UIView) {
        // Estilo sutil para indicadores pequeños
        guard view.bounds.width < 80 && view.bounds.height < 80 else { return }

        view.layer.cornerRadius = 10
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
    }
    
    // No need to update the UIViewController after it's created
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
