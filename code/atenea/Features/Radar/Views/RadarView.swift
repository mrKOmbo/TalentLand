//
//  RadarView.swift
//  atenea
//
//  Radar real con dirección GPS + brújula.
//  Muestra merchants posicionados por bearing y distancia reales.
//

import SwiftUI
import CoreLocation

// MARK: - Radar Merchant Model

struct RadarMerchant: Identifiable {
    let id: UUID
    let name: String
    let emoji: String
    let category: String
    let isStatic: Bool
    let coordinate: CLLocationCoordinate2D
    let distance: Double        // metros
    let bearing: Double         // grados (0 = norte, 90 = este)
    let mpcPeer: RadarPeer?     // nil si viene solo de GPS
    let merchant: Merchant?

    var formattedDistance: String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

// MARK: - Bearing Utilities

/// Bearing geográfico de un punto a otro (en grados, 0=norte, 90=este)
func bearingBetween(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
    let lat1 = from.latitude * .pi / 180
    let lat2 = to.latitude * .pi / 180
    let dLon = (to.longitude - from.longitude) * .pi / 180

    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
    let bearing = atan2(y, x) * 180 / .pi
    return (bearing + 360).truncatingRemainder(dividingBy: 360)
}

/// Convierte (bearing, distance) en (x, y) relativo al centro del radar
func radarOffset(bearing: Double, distance: Double, heading: Double, maxRadius: CGFloat, maxDistance: Double) -> CGPoint {
    let relativeBearing = (bearing - heading + 360).truncatingRemainder(dividingBy: 360)
    let angle = relativeBearing * .pi / 180 - .pi / 2 // -π/2 porque 0° es arriba (norte)
    let normalizedDist = min(distance / maxDistance, 1.0)
    let r = Double(maxRadius) * normalizedDist

    return CGPoint(x: cos(angle) * r, y: sin(angle) * r)
}

// MARK: - Main Radar View

struct RadarView: View {
    @ObservedObject private var radarService = RadarService.shared
    @ObservedObject private var merchantManager = MerchantManager.shared
    @ObservedObject private var userManager = UserManager.shared
    @StateObject private var locationManager = LocationManager()

    @State private var radarRotation: Double = 0
    @State private var selectedMerchant: RadarMerchant?
    @State private var showDirectionArrow = false
    @State private var maxDistance: Double = 500 // metros

    @Environment(\.dismiss) private var dismiss

    private var heading: Double {
        locationManager.currentHeading?.trueHeading ?? 0
    }

    private var userLocation: CLLocationCoordinate2D {
        locationManager.currentLocation ?? CLLocationCoordinate2D(latitude: mockUserLatitude, longitude: mockUserLongitude)
    }

    /// Merchants con ubicación conocida, con bearing y distancia calculados
    private var radarMerchants: [RadarMerchant] {
        var result: [RadarMerchant] = []
        var includedNames = Set<String>()

        // 1. Merchants con GPS cercano
        let activeMerchants = merchantManager.merchants.filter { $0.isActive && $0.currentLocation != nil }
        for merchant in activeMerchants {
            guard let loc = merchant.currentLocation else { continue }
            let coord = loc.coordinate

            let blePeer = radarService.discoveredMerchants.first {
                $0.businessName == merchant.businessName
            }

            // Prioridad: UWB > GPS haversine
            let dist: Double
            if let uwb = blePeer?.uwbDistance {
                dist = Double(uwb)
            } else {
                dist = MerchantManager.haversineDistance(
                    lat1: userLocation.latitude, lon1: userLocation.longitude,
                    lat2: coord.latitude, lon2: coord.longitude
                )
            }

            guard dist <= maxDistance * 1.2 else { continue }

            let bear = bearingBetween(from: userLocation, to: coord)

            result.append(RadarMerchant(
                id: merchant.id,
                name: merchant.businessName,
                emoji: merchant.emoji,
                category: merchant.category.displayName,
                isStatic: merchant.isStatic,
                coordinate: coord,
                distance: dist,
                bearing: bear,
                mpcPeer: blePeer,
                merchant: merchant
            ))
            includedNames.insert(merchant.businessName)
        }

        // 2. Peers BLE que NO están ya incluidos — UWB si disponible, sino RSSI
        for peer in radarService.discoveredMerchants where !includedNames.contains(peer.businessName) {
            let clampedDist: Double
            if let uwb = peer.uwbDistance {
                clampedDist = Double(uwb)
            } else {
                let txPower: Double = -59
                let estimatedDist = pow(10.0, (txPower - Double(peer.rssi)) / 20.0)
                clampedDist = min(max(estimatedDist, 1.0), maxDistance)
            }

            // Buscar merchant en catálogo para datos completos (productos, etc.)
            let catalogMerchant = merchantManager.merchants.first { $0.businessName == peer.businessName }

            // Bearing aleatorio estable por peer (para que no salten en cada render)
            let stableBearing = Double(abs(peer.id.hashValue) % 360)

            result.append(RadarMerchant(
                id: catalogMerchant?.id ?? UUID(),
                name: peer.businessName,
                emoji: peer.emoji,
                category: catalogMerchant?.category.displayName ?? peer.category,
                isStatic: peer.isStatic,
                coordinate: userLocation,
                distance: clampedDist,
                bearing: stableBearing,
                mpcPeer: peer,
                merchant: catalogMerchant
            ))
            includedNames.insert(peer.businessName)
        }

        return result.sorted { $0.distance < $1.distance }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0A0A1A"), Color(hex: "#0D1B2A")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            if showDirectionArrow, let merchant = selectedMerchant {
                DirectionArrowView(
                    merchant: merchant,
                    heading: heading,
                    userLocation: userLocation,
                    onBack: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDirectionArrow = false
                        }
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                VStack(spacing: 16) {
                    radarHeader
                    radarDisplay
                        .frame(height: 320)
                    distanceSelector
                    merchantList
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 16)
                .padding(.top, 60)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showDirectionArrow)
        .onAppear {
            startRadar()
        }
    }

    // MARK: - Header

    private var radarHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedString("radar.title"))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    Circle()
                        .fill(radarService.isScanning ? Color.green : Color.gray)
                        .frame(width: 6, height: 6)
                    Text(String(format: LocalizedString("radar.merchantsInRange"), radarMerchants.count))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()

            // Indicador de brújula
            VStack(spacing: 2) {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.cyan)
                    .rotationEffect(.degrees(-heading))
                Text("\(Int(heading))°")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.cyan.opacity(0.7))
            }

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
        }
    }

    // MARK: - Radar Display

    private var radarDisplay: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let maxRadius = min(geo.size.width, geo.size.height) / 2 - 16

            ZStack {
                // Anillos concéntricos
                ForEach([0.33, 0.66, 1.0], id: \.self) { scale in
                    Circle()
                        .stroke(Color.green.opacity(0.12), lineWidth: 0.5)
                        .frame(width: maxRadius * 2 * scale, height: maxRadius * 2 * scale)
                }

                // Cruz cardinal
                cardinalLines(center: center, radius: maxRadius)

                // Labels N/S/E/O (rotan con heading para mantener norte arriba)
                cardinalLabels(center: center, radius: maxRadius)

                // Sweep
                if radarService.isScanning || !radarMerchants.isEmpty {
                    RadarSweepLine(center: center, radius: maxRadius, rotation: radarRotation)
                }

                // Labels de distancia
                distanceLabels(center: center, maxRadius: maxRadius)

                // Blips de merchants
                ForEach(radarMerchants) { merchant in
                    let offset = radarOffset(
                        bearing: merchant.bearing,
                        distance: merchant.distance,
                        heading: heading,
                        maxRadius: maxRadius,
                        maxDistance: maxDistance
                    )

                    Button {
                        selectedMerchant = merchant
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDirectionArrow = true
                        }
                    } label: {
                        RadarBlip(
                            emoji: merchant.emoji,
                            isLive: merchant.mpcPeer != nil,
                            distance: merchant.distance
                        )
                    }
                    .buttonStyle(.plain)
                    .position(x: center.x + offset.x, y: center.y + offset.y)
                }

                // Punto central (yo)
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 20, height: 20)
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                }
                .shadow(color: .blue.opacity(0.5), radius: 6)
                .position(center)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                radarRotation = 360
            }
        }
    }

    // MARK: - Cardinal Lines & Labels

    private func cardinalLines(center: CGPoint, radius: CGFloat) -> some View {
        let headingRad = -heading * .pi / 180

        return ZStack {
            // Línea N-S
            Path { path in
                path.move(to: CGPoint(
                    x: center.x + sin(headingRad) * radius,
                    y: center.y - cos(headingRad) * radius
                ))
                path.addLine(to: CGPoint(
                    x: center.x - sin(headingRad) * radius,
                    y: center.y + cos(headingRad) * radius
                ))
            }
            .stroke(Color.green.opacity(0.08), lineWidth: 0.5)

            // Línea E-O
            Path { path in
                path.move(to: CGPoint(
                    x: center.x + cos(headingRad) * radius,
                    y: center.y + sin(headingRad) * radius
                ))
                path.addLine(to: CGPoint(
                    x: center.x - cos(headingRad) * radius,
                    y: center.y - sin(headingRad) * radius
                ))
            }
            .stroke(Color.green.opacity(0.08), lineWidth: 0.5)
        }
    }

    private func cardinalLabels(center: CGPoint, radius: CGFloat) -> some View {
        let labels: [(String, Double)] = [("N", 0), ("E", 90), ("S", 180), ("O", 270)]
        let headingRad = -heading * .pi / 180

        return ZStack {
            ForEach(labels, id: \.0) { label, angle in
                let rad = (angle * .pi / 180) + headingRad
                let labelRadius = radius + 12
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(label == "N" ? .red.opacity(0.6) : .green.opacity(0.25))
                    .position(
                        x: center.x + sin(rad) * labelRadius,
                        y: center.y - cos(rad) * labelRadius
                    )
            }
        }
    }

    private func distanceLabels(center: CGPoint, maxRadius: CGFloat) -> some View {
        let distances: [(String, CGFloat)] = [
            ("\(Int(maxDistance / 3))m", 0.33),
            ("\(Int(maxDistance * 2 / 3))m", 0.66),
            ("\(Int(maxDistance))m", 1.0)
        ]

        return ZStack {
            ForEach(distances, id: \.0) { label, fraction in
                Text(label)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.green.opacity(0.25))
                    .position(x: center.x + maxRadius * fraction - 4, y: center.y - 8)
            }
        }
    }

    // MARK: - Distance Selector

    private var distanceSelector: some View {
        HStack(spacing: 0) {
            ForEach([500.0, 1000.0, 2000.0], id: \.self) { dist in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        maxDistance = dist
                    }
                } label: {
                    Text(dist < 1000 ? "\(Int(dist))m" : "\(Int(dist / 1000))km")
                        .font(.system(size: 13, weight: maxDistance == dist ? .semibold : .regular))
                        .foregroundColor(maxDistance == dist ? .white : .white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            maxDistance == dist
                                ? RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.2))
                                : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
    }

    // MARK: - Merchant List

    private var merchantList: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !radarMerchants.isEmpty {
                Text(LocalizedString("radar.merchantsInRangeLabel"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .kerning(1.5)

                ForEach(radarMerchants.prefix(5)) { merchant in
                    Button {
                        selectedMerchant = merchant
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDirectionArrow = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(merchant.emoji)
                                .font(.system(size: 22))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(merchant.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                HStack(spacing: 4) {
                                    Text(merchant.formattedDistance)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.cyan)
                                    if merchant.mpcPeer != nil {
                                        Text("· \(LocalizedString("radar.live"))")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                }
                            }

                            Spacer()

                            Text(merchant.formattedDistance)
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan.opacity(0.8))
                        }
                        .padding(12)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.03))
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helpers

    private func startRadar() {
        print("📡 [RadarView] startRadar() — user=\(userManager.currentUser?.name ?? "nil") isMerchant=\(userManager.currentUser?.isMerchant ?? false)")
        print("📡 [RadarView] userLocation=(\(userLocation.latitude), \(userLocation.longitude)) | maxDist=\(maxDistance)m")
        if let user = userManager.currentUser, user.isMerchant,
           let merchant = MerchantManager.shared.currentMerchantProfile {
            radarService.startAdvertising(merchant: merchant)
            print("📡 [RadarView] Merchant advertising: \(merchant.businessName)")
        }
        radarService.startScanning()

        // Log completo una sola vez
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            let gps = merchantManager.merchants.filter { $0.isActive && $0.currentLocation != nil }
            let ble = radarService.discoveredMerchants
            print("📡 [RadarView] ── SCAN REPORT ──")
            print("📡   GPS merchants: \(gps.count) | BLE peers: \(ble.count) | radarMerchants: \(radarMerchants.count)")
            for m in radarMerchants {
                let source = m.mpcPeer != nil ? "BLE+GPS" : "GPS"
                print("📡   ✅ \(m.emoji) \(m.name) dist=\(m.formattedDistance) bearing=\(Int(m.bearing))° [\(source)]")
            }
            for peer in ble {
                let inRadar = radarMerchants.contains { $0.name == peer.businessName }
                if !inRadar {
                    print("📡   ⚠️ BLE peer \(peer.emoji) \(peer.businessName) RSSI=\(peer.rssi) — NO en radar (bug?)")
                }
            }
            print("📡 [RadarView] ── END REPORT ──")
        }
    }

    private func directionLabel(_ bearing: Double) -> String {
        let dirs = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]
        let index = Int((bearing + 22.5) / 45) % 8
        return dirs[index]
    }
}

// MARK: - Radar Blip

struct RadarBlip: View {
    let emoji: String
    let isLive: Bool
    let distance: Double
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(isLive ? Color.green.opacity(0.15) : Color.orange.opacity(0.1))
                .frame(width: 38, height: 38)
                .scaleEffect(pulse ? CGFloat(1.3) : CGFloat(1.0))
                .opacity(pulse ? 0.0 : 0.5)

            Text(emoji)
                .font(.system(size: 18))
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(Color(hex: "#0A0A1A"))
                        .overlay(
                            Circle().stroke(isLive ? Color.green : Color.orange.opacity(0.5), lineWidth: 1.5)
                        )
                )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Sweep Line

struct RadarSweepLine: View {
    let center: CGPoint
    let radius: CGFloat
    let rotation: Double

    var body: some View {
        // Línea principal
        Path { path in
            path.move(to: center)
            let endX = center.x + cos(rotation * .pi / 180 - .pi / 2) * radius
            let endY = center.y + sin(rotation * .pi / 180 - .pi / 2) * radius
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
        .stroke(Color.green.opacity(0.5), lineWidth: 1.5)

        // Cono de barrido
        Path { path in
            path.move(to: center)
            let startAngle = (rotation - 30) * .pi / 180 - .pi / 2
            let endAngle = rotation * .pi / 180 - .pi / 2
            path.addArc(center: center, radius: radius,
                       startAngle: .radians(startAngle),
                       endAngle: .radians(endAngle),
                       clockwise: false)
            path.closeSubpath()
        }
        .fill(
            AngularGradient(
                colors: [.green.opacity(0.0), .green.opacity(0.06)],
                center: UnitPoint(x: center.x / (radius * 2 + 20), y: center.y / (radius * 2 + 20)),
                startAngle: .degrees(rotation - 30),
                endAngle: .degrees(rotation)
            )
        )
    }
}

// MARK: - Direction Arrow View

struct DirectionArrowView: View {
    let merchant: RadarMerchant
    let heading: Double
    let userLocation: CLLocationCoordinate2D
    let onBack: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var hapticTimer: Timer?

    private var relativeBearing: Double {
        let bearing = bearingBetween(from: userLocation, to: merchant.coordinate)
        return (bearing - heading + 360).truncatingRemainder(dividingBy: 360)
    }

    private var currentDistance: Double {
        MerchantManager.haversineDistance(
            lat1: userLocation.latitude, lon1: userLocation.longitude,
            lat2: merchant.coordinate.latitude, lon2: merchant.coordinate.longitude
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(LocalizedString("radar.title"))
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.cyan)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)

            Spacer()

            // Info del merchant
            VStack(spacing: 8) {
                Text(merchant.emoji)
                    .font(.system(size: 48))
                Text(merchant.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text(merchant.category)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Flecha grande
            ZStack {
                // Anillo exterior pulsante
                Circle()
                    .stroke(Color.green.opacity(0.1), lineWidth: 2)
                    .frame(width: 220, height: 220)
                    .scaleEffect(pulseScale)

                Circle()
                    .stroke(Color.green.opacity(0.06), lineWidth: 1)
                    .frame(width: 260, height: 260)

                // Flecha
                Image(systemName: "location.north.fill")
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .cyan], startPoint: .top, endPoint: .bottom)
                    )
                    .rotationEffect(.degrees(relativeBearing))
                    .shadow(color: .green.opacity(0.4), radius: 20)
                    .animation(.easeInOut(duration: 0.3), value: relativeBearing)
            }

            Spacer()

            // Distancia
            VStack(spacing: 4) {
                Text(merchant.formattedDistance)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(directionLabel(bearingBetween(from: userLocation, to: merchant.coordinate)))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Botón timbrar si hay merchant
            if let fullMerchant = merchant.merchant {
                TimbreButtonView(merchant: fullMerchant)
                    .padding(.bottom, 30)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
            }
            startHaptics()
        }
        .onDisappear {
            hapticTimer?.invalidate()
        }
    }

    private func startHaptics() {
        // Haptic feedback cada X segundos — más frecuente si más cerca
        hapticTimer = Timer.scheduledTimer(withTimeInterval: hapticInterval(), repeats: false) { [self] _ in
            let generator = UIImpactFeedbackGenerator(style: currentDistance < 100 ? .heavy : .light)
            generator.impactOccurred()
            startHaptics() // Re-schedule con intervalo actualizado
        }
    }

    private func hapticInterval() -> TimeInterval {
        if currentDistance < 50 { return 0.5 }
        if currentDistance < 150 { return 1.5 }
        if currentDistance < 300 { return 3.0 }
        return 5.0
    }

    private func directionLabel(_ bearing: Double) -> String {
        let dirs = [
            LocalizedString("radar.north"), LocalizedString("radar.northeast"),
            LocalizedString("radar.east"), LocalizedString("radar.southeast"),
            LocalizedString("radar.south"), LocalizedString("radar.southwest"),
            LocalizedString("radar.west"), LocalizedString("radar.northwest")
        ]
        let index = Int((bearing + 22.5) / 45) % 8
        return String(format: LocalizedString("radar.towardsThe"), dirs[index])
    }
}
