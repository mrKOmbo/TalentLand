//
//  HapticVendorNavView.swift
//  watchAtenea Watch App
//
//  Navegación háptica hacia vendedores para personas con discapacidad visual
//  Usa WKHapticType.directionUp/Down para guiar por vibración
//
//  Patrones:
//  - directionUp (taps rápidos) = gira a la derecha
//  - directionDown (taps lentos) = gira a la izquierda
//  - notification (vibración continua) = vas en línea recta, bien
//  - success = ¡llegaste al vendedor!
//  - failure = te estás alejando, da la vuelta
//

import SwiftUI
import WatchKit

// MARK: - Vendor Info (mock data para Watch)

struct WatchVendor: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let category: String
    let initialDistance: Double // metros
}

// MARK: - Haptic Vendor Navigation View

struct HapticVendorNavView: View {
    @State private var isNavigating = false
    @State private var selectedVendor: WatchVendor?
    @State private var currentDistance: Double = 0
    @State private var currentDirection: VendorDirection = .straight
    @State private var hasArrived = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var hapticTimer: Timer?
    @State private var simulationTimer: Timer?

    let vendors: [WatchVendor] = [
        WatchVendor(emoji: "🌮", name: "Don Beto Tacos", category: "Tacos al Pastor", initialDistance: 350),
        WatchVendor(emoji: "🫔", name: "Doña Mary", category: "Tamales Oaxaqueños", initialDistance: 180),
        WatchVendor(emoji: "🌽", name: "El Elotero", category: "Elotes y Esquites", initialDistance: 95),
        WatchVendor(emoji: "🍦", name: "Helados Lupita", category: "Helados artesanales", initialDistance: 420),
    ]

    var body: some View {
        Group {
            if isNavigating, let vendor = selectedVendor {
                activeNavigation(vendor: vendor)
            } else {
                vendorList
            }
        }
    }

    // MARK: - Vendor List

    private var vendorList: some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    Image(systemName: "hand.point.up.braille.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Guía Háptica")
                        .font(.system(size: 16, weight: .bold))

                    Text("Navega con vibraciones")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .padding(.top, 4)

                ForEach(vendors) { vendor in
                    Button {
                        selectedVendor = vendor
                        currentDistance = vendor.initialDistance
                        hasArrived = false
                        withAnimation { isNavigating = true }
                        startHapticNavigation()
                    } label: {
                        HStack(spacing: 10) {
                            Text(vendor.emoji)
                                .font(.system(size: 22))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(vendor.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("\(Int(vendor.initialDistance))m · \(vendor.category)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Image(systemName: "hand.point.right.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.cyan)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(white: 0.15))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Active Navigation

    private func activeNavigation(vendor: WatchVendor) -> some View {
        ZStack {
            // Fondo que cambia según estado
            backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentDirection)
                .animation(.easeInOut(duration: 0.5), value: hasArrived)

            VStack(spacing: 8) {
                if hasArrived {
                    arrivedView(vendor: vendor)
                } else {
                    navigationView(vendor: vendor)
                }
            }
        }
        .onDisappear {
            stopNavigation()
        }
    }

    private var backgroundColor: Color {
        if hasArrived { return Color.green.opacity(0.2) }
        switch currentDirection {
        case .straight: return Color.cyan.opacity(0.1)
        case .left, .slightLeft: return Color.blue.opacity(0.1)
        case .right, .slightRight: return Color.purple.opacity(0.1)
        case .behind: return Color.red.opacity(0.1)
        }
    }

    // MARK: - Navigation View

    private func navigationView(vendor: WatchVendor) -> some View {
        VStack(spacing: 6) {
            // Vendor info
            HStack(spacing: 6) {
                Text(vendor.emoji)
                    .font(.system(size: 16))
                Text(vendor.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            // Distance
            Text(distanceText)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(distanceGradient)
                .contentTransition(.numericText())

            // Direction arrow
            ZStack {
                Circle()
                    .fill(currentDirection.color.opacity(0.25))
                    .frame(width: 70, height: 70)
                    .scaleEffect(pulseScale)

                Circle()
                    .fill(currentDirection.color.opacity(0.35))
                    .frame(width: 58, height: 58)

                Image(systemName: currentDirection.arrow)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulseScale = 1.2
                }
            }

            // Instruction
            Text(currentDirection.instruction)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(currentDirection.color)
                .multilineTextAlignment(.center)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 16)

            // Stop button
            Button {
                stopNavigation()
                withAnimation { isNavigating = false }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Arrived View

    private func arrivedView(vendor: WatchVendor) -> some View {
        VStack(spacing: 12) {
            Text(vendor.emoji)
                .font(.system(size: 44))

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.green)

            Text("¡Llegaste!")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.green)

            Text(vendor.name)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))

            Button {
                stopNavigation()
                withAnimation { isNavigating = false }
            } label: {
                Text("Listo")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(16)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Haptic Engine

    private func startHapticNavigation() {
        // Simulación de acercamiento
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard !hasArrived else { return }

            // Reducir distancia
            let decrement = Double.random(in: 8...20)
            currentDistance = max(currentDistance - decrement, 0)

            // Cambiar dirección periódicamente (simula caminata real)
            let directions: [VendorDirection] = [.straight, .straight, .straight, .slightLeft, .slightRight, .left, .right]
            if Int.random(in: 0...3) == 0 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    currentDirection = directions.randomElement() ?? .straight
                }
            }

            // ¿Llegó?
            if currentDistance < 15 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    hasArrived = true
                }
                playArrivedPattern()
                stopNavigation()
            }
        }

        // Haptic feedback basado en dirección y distancia
        startHapticFeedback()
    }

    private func startHapticFeedback() {
        hapticTimer = Timer.scheduledTimer(withTimeInterval: hapticInterval, repeats: false) { [self] _ in
            guard !hasArrived else { return }
            playDirectionHaptic()
            // Re-schedule con nuevo intervalo (más rápido si está más cerca)
            startHapticFeedback()
        }
    }

    /// Intervalo entre haptics: más cerca = más frecuente
    private var hapticInterval: TimeInterval {
        if currentDistance < 30 { return 0.4 }      // Muy cerca: vibra cada 0.4s
        if currentDistance < 80 { return 0.7 }      // Cerca: cada 0.7s
        if currentDistance < 150 { return 1.2 }     // Medio: cada 1.2s
        if currentDistance < 300 { return 2.0 }     // Lejos: cada 2s
        return 3.0                                   // Muy lejos: cada 3s
    }

    private func playDirectionHaptic() {
        let device = WKInterfaceDevice.current()

        switch currentDirection {
        case .straight:
            device.play(.notification)  // Vibración suave = sigue recto
        case .right, .slightRight:
            device.play(.directionUp)   // Taps rápidos = gira derecha
        case .left, .slightLeft:
            device.play(.directionDown) // Taps lentos = gira izquierda
        case .behind:
            device.play(.failure)       // Error = te alejaste, da la vuelta
        }
    }

    private func playArrivedPattern() {
        let device = WKInterfaceDevice.current()
        device.play(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            device.play(.success)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            device.play(.notification)
        }
    }

    private func stopNavigation() {
        hapticTimer?.invalidate()
        hapticTimer = nil
        simulationTimer?.invalidate()
        simulationTimer = nil
    }

    // MARK: - Computed

    private var distanceText: String {
        if currentDistance < 1 { return "Aquí" }
        if currentDistance < 1000 { return "\(Int(currentDistance))m" }
        return String(format: "%.1f km", currentDistance / 1000)
    }

    private var progress: Double {
        guard let vendor = selectedVendor, vendor.initialDistance > 0 else { return 0 }
        return 1.0 - (currentDistance / vendor.initialDistance)
    }

    private var distanceGradient: LinearGradient {
        if currentDistance < 50 {
            return LinearGradient(colors: [.green, .cyan], startPoint: .top, endPoint: .bottom)
        } else if currentDistance < 150 {
            return LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
        }
        return LinearGradient(colors: [.white, .gray], startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Vendor Direction

enum VendorDirection {
    case straight, left, right, slightLeft, slightRight, behind

    var arrow: String {
        switch self {
        case .straight: return "arrow.up"
        case .left: return "arrow.turn.up.left"
        case .right: return "arrow.turn.up.right"
        case .slightLeft: return "arrow.up.left"
        case .slightRight: return "arrow.up.right"
        case .behind: return "arrow.uturn.backward"
        }
    }

    var instruction: String {
        switch self {
        case .straight: return "Sigue recto"
        case .left: return "Gira a la izquierda"
        case .right: return "Gira a la derecha"
        case .slightLeft: return "Ligeramente izquierda"
        case .slightRight: return "Ligeramente derecha"
        case .behind: return "Da la vuelta"
        }
    }

    var color: Color {
        switch self {
        case .straight: return .cyan
        case .left, .slightLeft: return .blue
        case .right, .slightRight: return .purple
        case .behind: return .red
        }
    }
}
