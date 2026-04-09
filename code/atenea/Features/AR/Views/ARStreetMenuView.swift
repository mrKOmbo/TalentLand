//
//  ARStreetMenuView.swift
//  atenea
//
//  AR Street Menu — Menús flotantes sobre vendedores en la calle
//  Usa cámara AR como fondo + overlay SwiftUI posicionado por GPS bearing
//
//  El turista apunta su cámara a la calle y ve menús flotando sobre los puestos
//  con precios en su moneda y su idioma
//

import SwiftUI
import ARKit
import RealityKit
import CoreLocation
internal import Combine

// MARK: - AR Street Menu View

struct ARStreetMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var viewModel = ARStreetMenuViewModel()
    @ObservedObject private var merchantManager = MerchantManager.shared
    @State private var selectedMerchantForTimbre: Merchant?

    var body: some View {
        ZStack {
            // Cámara AR como fondo
            ARStreetMenuCamera(viewModel: viewModel)
                .ignoresSafeArea()

            // Overlay de menú cards posicionadas por bearing
            ForEach(viewModel.visibleMerchants) { item in
                ARMenuCardView(
                    merchant: item.merchant,
                    distance: item.distance,
                    languageCode: languageManager.currentLanguage,
                    onTimbre: {
                        selectedMerchantForTimbre = item.merchant
                    }
                )
                .scaleEffect(CGFloat(scaleForDistance(item.distance)))
                .opacity(opacityForDistance(item.distance))
                .position(
                    x: item.screenPosition.x,
                    y: item.screenPosition.y
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: item.screenPosition.x)
                .transition(.opacity.combined(with: .scale))
            }

            // HUD superior
            VStack {
                hudHeader
                Spacer()
                hudFooter
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            viewModel.startSession(merchants: merchantManager.activeMerchants())
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .sheet(item: $selectedMerchantForTimbre) { merchant in
            TimbreButtonView(merchant: merchant)
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - HUD

    private var hudHeader: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("AR STREET MENU")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.cyan)
                    .kerning(1.5)
                Text(String(format: LocalizedString("ar.street.visibleVendors"), viewModel.visibleMerchants.count))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Idioma activo
            Text(languageFlag)
                .font(.system(size: 24))
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 10)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.6), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var hudFooter: some View {
        HStack(spacing: 16) {
            Image(systemName: "arrow.left.and.right")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
            Text(LocalizedString("ar.street.moveToExplore"))
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Helpers

    private var languageFlag: String {
        let flags: [String: String] = [
            "en": "🇺🇸", "es": "🇲🇽", "ja": "🇯🇵", "ko": "🇰🇷",
            "de": "🇩🇪", "fr": "🇫🇷", "it": "🇮🇹", "pt": "🇧🇷",
            "ar": "🇸🇦", "zh-Hans": "🇨🇳", "hi": "🇮🇳", "ru": "🇷🇺",
            "tr": "🇹🇷", "nl": "🇳🇱", "pl": "🇵🇱",
        ]
        return flags[languageManager.currentLanguage] ?? "🌍"
    }

    private func scaleForDistance(_ distance: Double) -> Double {
        // Más cerca = más grande
        if distance < 50 { return 1.1 }
        if distance < 100 { return 1.0 }
        if distance < 200 { return 0.85 }
        if distance < 500 { return 0.7 }
        return 0.55
    }

    private func opacityForDistance(_ distance: Double) -> Double {
        if distance < 500 { return 1.0 }
        if distance < 800 { return 0.7 }
        return 0.5
    }
}

// MARK: - Visible Merchant Item

struct VisibleMerchantItem: Identifiable {
    let id: UUID
    let merchant: Merchant
    let distance: Double
    let bearing: Double // radianes
    var screenPosition: CGPoint
}

// MARK: - AR Street Menu ViewModel

class ARStreetMenuViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var visibleMerchants: [VisibleMerchantItem] = []
    @Published var userHeading: Double = 0 // grados, 0 = norte

    private let locationManager = CLLocationManager()
    private var merchants: [Merchant] = []
    private var currentLocation: CLLocation?
    private var updateTimer: Timer?
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = 2 // Actualizar cada 2 grados
    }

    func startSession(merchants: [Merchant]) {
        self.merchants = merchants
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()

        // Timer para recalcular posiciones suavemente
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.recalculatePositions()
        }

        // Generar merchants de demo si no hay activos con ubicación
        if merchants.allSatisfy({ $0.currentLocation == nil }) {
            generateDemoMerchants()
        }
    }

    func stopSession() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        updateTimer?.invalidate()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        userHeading = newHeading.trueHeading
    }

    // MARK: - Position Calculation

    private func recalculatePositions() {
        guard let userLoc = currentLocation else { return }
        let heading = userHeading

        // Campo visual horizontal de la cámara: ~60 grados
        let fov: Double = 60.0

        var items: [VisibleMerchantItem] = []

        for merchant in merchants {
            guard let loc = merchant.currentLocation else { continue }

            let merchantLoc = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
            let distance = userLoc.distance(from: merchantLoc)

            // Solo mostrar merchants dentro de 1km
            guard distance < 1000 else { continue }

            // Calcular bearing al merchant
            let bearing = bearingBetween(
                lat1: userLoc.coordinate.latitude,
                lon1: userLoc.coordinate.longitude,
                lat2: loc.latitude,
                lon2: loc.longitude
            )

            // Diferencia angular entre heading del dispositivo y bearing al merchant
            var angleDiff = bearing - heading
            // Normalizar a [-180, 180]
            while angleDiff > 180 { angleDiff -= 360 }
            while angleDiff < -180 { angleDiff += 360 }

            // Solo mostrar si está dentro del FOV (con margen)
            guard abs(angleDiff) < fov * 0.8 else { continue }

            // Mapear ángulo a posición X en pantalla
            let normalizedX = (angleDiff / fov) + 0.5 // 0.0 = izquierda, 1.0 = derecha
            let screenX = normalizedX * screenWidth

            // Y basado en distancia (más lejos = más arriba)
            let normalizedY: Double
            if distance < 100 {
                normalizedY = 0.55
            } else if distance < 300 {
                normalizedY = 0.45
            } else {
                normalizedY = 0.35
            }
            let screenY = normalizedY * screenHeight

            items.append(VisibleMerchantItem(
                id: merchant.id,
                merchant: merchant,
                distance: distance,
                bearing: bearing,
                screenPosition: CGPoint(x: screenX, y: screenY)
            ))
        }

        DispatchQueue.main.async {
            withAnimation(.interpolatingSpring(stiffness: 80, damping: 12)) {
                self.visibleMerchants = items.sorted { $0.distance < $1.distance }
            }
        }
    }

    private func bearingBetween(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let dLon = (lon2 - lon1).radians
        let y = sin(dLon) * cos(lat2.radians)
        let x = cos(lat1.radians) * sin(lat2.radians) - sin(lat1.radians) * cos(lat2.radians) * cos(dLon)
        var bearing = atan2(y, x).degrees
        if bearing < 0 { bearing += 360 }
        return bearing
    }

    // MARK: - Demo Data

    private func generateDemoMerchants() {
        guard let loc = currentLocation else {
            // Usar ubicación mock de CDMX
            let mockLoc = CLLocation(latitude: 19.4326, longitude: -99.1332)
            currentLocation = mockLoc
            generateDemoMerchantsAround(mockLoc)
            return
        }
        generateDemoMerchantsAround(loc)
    }

    private func generateDemoMerchantsAround(_ location: CLLocation) {
        // Colocar merchants de MerchantManager con ubicaciones alrededor del usuario
        let offsets: [(lat: Double, lon: Double)] = [
            (0.0005, 0.0003),
            (-0.0003, 0.0006),
            (0.0008, -0.0002),
            (-0.0006, -0.0005),
            (0.0002, 0.0009),
        ]

        for (index, merchant) in MerchantManager.shared.merchants.prefix(5).enumerated() {
            let offset = offsets[index % offsets.count]
            MerchantManager.shared.updateLocation(
                merchantId: merchant.id,
                latitude: location.coordinate.latitude + offset.lat,
                longitude: location.coordinate.longitude + offset.lon
            )
        }

        merchants = MerchantManager.shared.activeMerchants()
    }
}

// MARK: - Double Extensions

private extension Double {
    var radians: Double { self * .pi / 180 }
    var degrees: Double { self * 180 / .pi }
}

// MARK: - AR Camera View (UIViewRepresentable)

struct ARStreetMenuCamera: UIViewRepresentable {
    let viewModel: ARStreetMenuViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false

        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravityAndHeading
        config.planeDetection = [] // No necesitamos planos
        arView.session.run(config)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
