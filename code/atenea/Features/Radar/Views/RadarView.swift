//
//  RadarView.swift
//  atenea
//
//  Vista de radar que muestra merchants descubiertos via BLE/WiFi en tiempo real
//

import SwiftUI

struct RadarView: View {
    @ObservedObject private var radarService = RadarService.shared
    @ObservedObject private var userManager = UserManager.shared
    @State private var radarRotation: Double = 0
    @State private var selectedPeer: RadarPeer?
    @State private var showMerchantDetail = false

    var body: some View {
        ZStack {
            // Fondo
            LinearGradient(
                colors: [Color(hex: "#0A0A1A"), Color(hex: "#0D1B2A")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                radarHeader

                // Radar visual
                radarDisplay
                    .frame(height: 320)

                // Lista de descubiertos
                discoveredList

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
        }
        .onAppear {
            startRadar()
        }
        .onDisappear {
            // No detener el radar al salir — sigue en background
        }
        .sheet(item: $selectedPeer) { peer in
            RadarPeerDetailSheet(peer: peer)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var radarHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Radar")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text(radarService.radarStatus)
                    .font(.system(size: 13))
                    .foregroundColor(radarService.isScanning || radarService.isAdvertising ? .green : .white.opacity(0.5))
            }

            Spacer()

            // Toggle on/off
            Button {
                if radarService.isScanning || radarService.isAdvertising {
                    radarService.stopAll()
                } else {
                    startRadar()
                }
            } label: {
                Image(systemName: radarService.isScanning || radarService.isAdvertising ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 20))
                    .foregroundColor(radarService.isScanning || radarService.isAdvertising ? .green : .gray)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(radarService.isScanning || radarService.isAdvertising ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
                    )
            }
        }
    }

    // MARK: - Radar Display

    private var radarDisplay: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let maxRadius = min(geo.size.width, geo.size.height) / 2 - 10

            ZStack {
                radarGrid(center: center, maxRadius: maxRadius)
                radarSweep(center: center, maxRadius: maxRadius)
                radarCenterDot(center: center)
                radarPeers(center: center, maxRadius: maxRadius)
                radarLabels(center: center, maxRadius: maxRadius)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                radarRotation = 360
            }
        }
    }

    private func radarGrid(center: CGPoint, maxRadius: CGFloat) -> some View {
        ZStack {
            // Círculos concéntricos
            ForEach([1,2,3], id: \.self) { ring in
                Circle()
                    .stroke(Color.green.opacity(0.15), lineWidth: 1)
                    .frame(width: maxRadius * 2 * CGFloat(ring) / 3,
                           height: maxRadius * 2 * CGFloat(ring) / 3)
            }

            // Cruz central vertical
            Path { path in
                path.move(to: CGPoint(x: center.x, y: center.y - maxRadius))
                path.addLine(to: CGPoint(x: center.x, y: center.y + maxRadius))
            }
            .stroke(Color.green.opacity(0.1), lineWidth: 0.5)

            // Cruz central horizontal
            Path { path in
                path.move(to: CGPoint(x: center.x - maxRadius, y: center.y))
                path.addLine(to: CGPoint(x: center.x + maxRadius, y: center.y))
            }
            .stroke(Color.green.opacity(0.1), lineWidth: 0.5)
        }
    }

    private func radarSweep(center: CGPoint, maxRadius: CGFloat) -> some View {
        Group {
            if radarService.isScanning {
                RadarSweepLine(center: center, radius: maxRadius, rotation: radarRotation)
            }
        }
    }

    private func radarCenterDot(center: CGPoint) -> some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 12, height: 12)
            .shadow(color: .blue.opacity(0.5), radius: 6)
            .position(center)
    }

    private func radarPeers(center: CGPoint, maxRadius: CGFloat) -> some View {
        let merchants = radarService.discoveredMerchants
        let enumerated = Array(merchants.enumerated())

        return ForEach(enumerated, id: \.element.id) { index, peer in
            radarPeerBlip(peer: peer, index: index, center: center, maxRadius: maxRadius, totalCount: merchants.count)
        }
    }

    private func radarPeerBlip(peer: RadarPeer, index: Int, center: CGPoint, maxRadius: CGFloat, totalCount: Int) -> some View {
        let angle = Double(index) * (360.0 / max(Double(totalCount), 1)) * .pi / 180

        let ringFraction: CGFloat
        switch peer.signalStrength {
        case .strong: ringFraction = 0.35
        case .medium: ringFraction = 0.55
        case .weak: ringFraction = 0.75
        }

        let x = center.x + cos(angle) * maxRadius * ringFraction
        let y = center.y + sin(angle) * maxRadius * ringFraction

        return Button {
            selectedPeer = peer
        } label: {
            RadarBlip(peer: peer)
        }
        .buttonStyle(.plain)
        .position(x: x, y: y)
        .transition(.scale.combined(with: .opacity))
    }

    private func radarLabels(center: CGPoint, maxRadius: CGFloat) -> some View {
        ZStack {
            Text("~30m")
                .font(.system(size: 9))
                .foregroundColor(.green.opacity(0.3))
                .position(x: center.x + maxRadius / 3, y: center.y - 8)

            Text("~60m")
                .font(.system(size: 9))
                .foregroundColor(.green.opacity(0.3))
                .position(x: center.x + maxRadius * 2 / 3, y: center.y - 8)

            Text("~100m")
                .font(.system(size: 9))
                .foregroundColor(.green.opacity(0.3))
                .position(x: center.x + maxRadius - 5, y: center.y - 8)
        }
    }

    // MARK: - Discovered List

    private var activeMerchants: [RadarPeer] {
        radarService.discoveredMerchants.filter { !$0.isStale }
    }

    private var discoveredList: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !radarService.discoveredMerchants.isEmpty {
                Text("DETECTADOS EN VIVO")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .kerning(1.5)

                ForEach(activeMerchants) { peer in
                    Button {
                        selectedPeer = peer
                    } label: {
                        HStack(spacing: 12) {
                            Text(peer.emoji)
                                .font(.system(size: 24))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(peer.businessName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(peer.signalStrength.color)
                                        .frame(width: 6, height: 6)
                                    Text(signalText(peer.signalStrength))
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                    Text("·")
                                        .foregroundColor(.white.opacity(0.3))
                                    Text(peer.isStatic ? "Fijo" : "Nómada")
                                        .font(.system(size: 12))
                                        .foregroundColor(peer.isStatic ? .blue : .orange)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .padding(12)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.03))
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            } else if radarService.isScanning {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(.green)
                        Text("Buscando comerciantes cerca...")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            }
        }
    }

    // MARK: - Actions

    private func startRadar() {
        if let user = userManager.currentUser, user.isMerchant {
            if let merchant = MerchantManager.shared.currentMerchantProfile {
                radarService.startAdvertising(merchant: merchant)
            }
        }
        // Todos escanean (merchants también ven a otros merchants)
        radarService.startScanning()
    }

    private func signalText(_ strength: RadarPeer.SignalStrength) -> String {
        switch strength {
        case .strong: return "Muy cerca"
        case .medium: return "Cerca"
        case .weak: return "Alejándose"
        }
    }
}

// MARK: - Radar Blip

struct RadarBlip: View {
    let peer: RadarPeer
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Pulse
            Circle()
                .fill(peer.signalStrength.color.opacity(0.2))
                .frame(width: 36, height: 36)
                .scaleEffect(pulse ? CGFloat(1.3) : CGFloat(1.0))
                .opacity(pulse ? 0.0 : 0.4)

            // Emoji
            Text(peer.emoji)
                .font(.system(size: 20))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color(hex: "#0A0A1A"))
                        .overlay(
                            Circle()
                                .stroke(peer.signalStrength.color, lineWidth: 1.5)
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
        Path { path in
            path.move(to: center)
            let endX = center.x + cos(rotation * .pi / 180) * radius
            let endY = center.y + sin(rotation * .pi / 180) * radius
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
        .stroke(
            LinearGradient(
                colors: [.green.opacity(0.6), .green.opacity(0.0)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            lineWidth: 2
        )

        // Cone detrás del sweep
        Path { path in
            path.move(to: center)
            let startAngle = (rotation - 30) * .pi / 180
            let endAngle = rotation * .pi / 180
            path.addArc(center: center, radius: radius,
                       startAngle: .radians(startAngle),
                       endAngle: .radians(endAngle),
                       clockwise: false)
            path.closeSubpath()
        }
        .fill(
            AngularGradient(
                colors: [.green.opacity(0.0), .green.opacity(0.08)],
                center: .center,
                startAngle: .degrees(rotation - 30),
                endAngle: .degrees(rotation)
            )
        )
    }
}

// MARK: - Peer Detail Sheet

struct RadarPeerDetailSheet: View {
    let peer: RadarPeer

    var body: some View {
        VStack(spacing: 16) {
            // Emoji + nombre
            Text(peer.emoji)
                .font(.system(size: 56))

            Text(peer.businessName)
                .font(.system(size: 22, weight: .bold))

            // Info
            HStack(spacing: 12) {
                // Signal
                HStack(spacing: 4) {
                    Circle()
                        .fill(peer.signalStrength.color)
                        .frame(width: 8, height: 8)
                    Text(signalText(peer.signalStrength))
                        .font(.system(size: 13))
                        .foregroundColor(peer.signalStrength.color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(peer.signalStrength.color.opacity(0.1)))

                // Tipo
                HStack(spacing: 4) {
                    Image(systemName: peer.isStatic ? "mappin.circle.fill" : "figure.walk")
                        .font(.system(size: 11))
                    Text(peer.isStatic ? "Puesto fijo" : "Ambulante")
                        .font(.system(size: 13))
                }
                .foregroundColor(peer.isStatic ? .blue : .orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(peer.isStatic ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1)))

                // Categoría
                Text(peer.category.capitalized)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.gray.opacity(0.1)))
            }

            Divider()

            // Status
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(.green)
                    Text("Detectado via Bluetooth/WiFi")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                Text("Sin internet · Conexión directa P2P")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.7))
            }

            Spacer()

            // Buscar en el mapa si tiene merchant registrado
            if let merchant = MerchantManager.shared.merchants.first(where: { $0.businessName == peer.businessName }) {
                TimbreButtonView(merchant: merchant)
                    .padding(.bottom, 20)
            }
        }
        .padding(.top, 24)
    }

    private func signalText(_ strength: RadarPeer.SignalStrength) -> String {
        switch strength {
        case .strong: return "Muy cerca"
        case .medium: return "Cerca"
        case .weak: return "Alejándose"
        }
    }
}

