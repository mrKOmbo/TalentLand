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

            // Overlay de menú cards con efecto 3D
            GeometryReader { geometry in
                ForEach(viewModel.visibleMerchants) { item in
                    let cardScale = scaleForDistance(item.distance)
                    let perspective3D = perspective3DForDistance(item.distance)

                    ARMenuCardView(
                        merchant: item.merchant,
                        distance: item.distance,
                        languageCode: languageManager.currentLanguage,
                        onTimbre: {
                            selectedMerchantForTimbre = item.merchant
                        }
                    )
                    // Efecto 3D: rotación en X (perspectiva de profundidad)
                    .rotation3DEffect(
                        .degrees(perspective3D.tiltX),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.5
                    )
                    // Rotación sutil en Y basada en posición horizontal
                    .rotation3DEffect(
                        .degrees(perspective3D.tiltY),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.4
                    )
                    .scaleEffect(CGFloat(cardScale))
                    .opacity(opacityForDistance(item.distance))
                    // Sombra de profundidad (más lejos = más difusa)
                    .shadow(
                        color: Color.cyan.opacity(item.distance < 100 ? 0.4 : 0.2),
                        radius: item.distance < 100 ? 12 : 6,
                        x: 0,
                        y: item.distance < 100 ? 8 : 4
                    )
                    // Glow holográfico sutil
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.4), .blue.opacity(0.2), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                            .scaleEffect(CGFloat(cardScale))
                    )
                    .frame(width: 220)
                    .offset(
                        x: item.screenPosition.x - geometry.size.width / 2,
                        y: item.screenPosition.y - geometry.size.height / 2
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: item.screenPosition.x)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: item.screenPosition.y)
                    .transition(.opacity.combined(with: .scale))
                }
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
                HStack(spacing: 6) {
                    Text("AR STREET MENU")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.cyan)
                        .kerning(1.5)
                    if viewModel.isDemoMode {
                        Text("DEMO")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.yellow))
                    }
                }
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

    /// Perspectiva 3D: las cards lejanas se inclinan más (como si estuvieran en el piso)
    private func perspective3DForDistance(_ distance: Double) -> (tiltX: Double, tiltY: Double) {
        // tiltX: inclinación hacia atrás (más lejos = más inclinado, como visto desde arriba)
        let tiltX: Double
        if distance < 60 { tiltX = -2 }
        else if distance < 120 { tiltX = -8 }
        else if distance < 250 { tiltX = -15 }
        else { tiltX = -22 }

        // tiltY: rotación lateral sutil basada en posición (da volumen)
        let tiltY = (distance.truncatingRemainder(dividingBy: 100) - 50) * 0.1
        return (tiltX, tiltY)
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
    @Published var isDemoMode: Bool = false

    private let locationManager = CLLocationManager()
    private var merchants: [Merchant] = []
    private var currentLocation: CLLocation?
    private var updateTimer: Timer?
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private var demoFloatPhase: Double = 0

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = 2
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

        // Si después de generar demo aún no hay visibles, activar demo mode
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }
            if self.visibleMerchants.isEmpty {
                self.activateDemoMode()
            }
        }
    }

    func stopSession() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        updateTimer?.invalidate()
        isDemoMode = false
    }

    // MARK: - Demo Mode (posiciones fijas para presentación)

    func activateDemoMode() {
        isDemoMode = true

        // Asegurar que haya merchants con ubicación
        let mockLoc = CLLocation(latitude: 19.3576, longitude: -99.2617)
        currentLocation = mockLoc
        generateDemoMerchantsAround(mockLoc)

        // Posiciones fijas distribuidas en pantalla
        let demoPositions: [(x: Double, y: Double, dist: Double)] = [
            (0.25, 0.30, 45),   // Arriba izquierda — cercano
            (0.72, 0.25, 120),  // Arriba derecha — medio
            (0.50, 0.42, 80),   // Centro — cercano
            (0.18, 0.52, 200),  // Abajo izquierda — lejos
            (0.80, 0.48, 150),  // Abajo derecha — medio
        ]

        var items: [VisibleMerchantItem] = []
        for (index, merchant) in merchants.prefix(5).enumerated() {
            let pos = demoPositions[index]
            items.append(VisibleMerchantItem(
                id: merchant.id,
                merchant: merchant,
                distance: pos.dist,
                bearing: Double(index) * 30,
                screenPosition: CGPoint(
                    x: pos.x * screenWidth,
                    y: pos.y * screenHeight
                )
            ))
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            visibleMerchants = items
        }

        // Animación de flotación sutil
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.animateDemoFloat()
        }

        print("🎬 Demo mode activado — \(items.count) merchants visibles")
    }

    private func animateDemoFloat() {
        demoFloatPhase += 0.05
        let basePositions: [(x: Double, y: Double)] = [
            (0.25, 0.30), (0.72, 0.25), (0.50, 0.42), (0.18, 0.52), (0.80, 0.48),
        ]

        for i in 0..<visibleMerchants.count {
            let base = basePositions[i]
            let offsetY = sin(demoFloatPhase + Double(i) * 1.2) * 6
            let offsetX = cos(demoFloatPhase * 0.7 + Double(i) * 0.9) * 3
            visibleMerchants[i].screenPosition = CGPoint(
                x: base.x * screenWidth + offsetX,
                y: base.y * screenHeight + offsetY
            )
        }
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
        guard !isDemoMode else { return }
        guard let userLoc = currentLocation else { return }
        let heading = userHeading

        let fov: Double = 60.0
        var items: [VisibleMerchantItem] = []

        for merchant in merchants {
            guard let loc = merchant.currentLocation else { continue }

            let merchantLoc = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
            let distance = userLoc.distance(from: merchantLoc)
            guard distance < 1000 else { continue }

            let bearing = bearingBetween(
                lat1: userLoc.coordinate.latitude,
                lon1: userLoc.coordinate.longitude,
                lat2: loc.latitude,
                lon2: loc.longitude
            )

            var angleDiff = bearing - heading
            while angleDiff > 180 { angleDiff -= 360 }
            while angleDiff < -180 { angleDiff += 360 }
            guard abs(angleDiff) < fov * 0.8 else { continue }

            let normalizedX = (angleDiff / fov) + 0.5
            let screenX = normalizedX * screenWidth

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
            let mockLoc = CLLocation(latitude: 19.4326, longitude: -99.1332)
            currentLocation = mockLoc
            generateDemoMerchantsAround(mockLoc)
            return
        }
        generateDemoMerchantsAround(loc)
    }

    private func generateDemoMerchantsAround(_ location: CLLocation) {
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
