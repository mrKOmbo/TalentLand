//
//  ContentView.swift
//  watchAtenea Watch App
//
//  Vista principal de la aplicación Atenea para Apple Watch
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Inicio / Quick Actions
            HomeWatchView()
                .tag(0)

            // Tab 2: Guía háptica a vendedores (accesibilidad)
            HapticVendorNavView()
                .tag(1)

            // Tab 3: Navegación
            NavigationWatchView()
                .tag(2)

            // Tab 4: Comunidad
            CommunityWatchView()
                .tag(3)

            // Tab 5: Actividad
            ActivityWatchView()
                .tag(4)
        }
        .tabViewStyle(.verticalPage)
    }
}

// MARK: - Home View
struct HomeWatchView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                VStack(spacing: 4) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Atenea")
                        .font(.title3.bold())

                    Text("Navegación Accesible")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.top, 8)

                Divider()

                // Quick Actions
                VStack(spacing: 8) {
                    QuickActionButton(
                        icon: "location.fill",
                        title: "Navegar",
                        color: .blue
                    )

                    QuickActionButton(
                        icon: "star.fill",
                        title: "Favoritos",
                        color: .yellow
                    )

                    QuickActionButton(
                        icon: "clock.fill",
                        title: "Recientes",
                        color: .orange
                    )

                    QuickActionButton(
                        icon: "hand.point.up.braille.fill",
                        title: "Guía Háptica",
                        color: .green
                    )

                    QuickActionButton(
                        icon: "person.2.fill",
                        title: "Comunidad",
                        color: .teal
                    )
                }
            }
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Button(action: {
            // Acción del botón
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 30)

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(white: 0.15))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Navigation View
struct NavigationWatchView: View {
    @State private var isNavigating = false
    @State private var currentDirection: NavigationDirection = .forward
    @State private var distanceRemaining: Double = 240 // metros
    @State private var nextInstruction = "Continúa recto"

    var body: some View {
        Group {
            if isNavigating {
                // Vista de navegación activa con flechas
                ActiveNavigationView(
                    direction: $currentDirection,
                    distance: $distanceRemaining,
                    instruction: $nextInstruction,
                    onStop: {
                        withAnimation {
                            isNavigating = false
                        }
                    }
                )
            } else {
                // Vista previa de navegación
                NavigationPreviewView(onStart: {
                    withAnimation {
                        isNavigating = true
                    }
                })
            }
        }
    }
}

// MARK: - Navigation Direction Enum
enum NavigationDirection {
    case forward, left, right, slightLeft, slightRight, sharpLeft, sharpRight, uTurn

    var arrowIcon: String {
        switch self {
        case .forward: return "arrow.up"
        case .left: return "arrow.turn.up.left"
        case .right: return "arrow.turn.up.right"
        case .slightLeft: return "arrow.up.left"
        case .slightRight: return "arrow.up.right"
        case .sharpLeft: return "arrow.uturn.left"
        case .sharpRight: return "arrow.uturn.right"
        case .uTurn: return "arrow.uturn.backward"
        }
    }

    var color: Color {
        switch self {
        case .forward: return .cyan
        case .left, .right: return .blue
        case .slightLeft, .slightRight: return .green
        case .sharpLeft, .sharpRight, .uTurn: return .orange
        }
    }
}

// MARK: - Active Navigation View
struct ActiveNavigationView: View {
    @Binding var direction: NavigationDirection
    @Binding var distance: Double
    @Binding var instruction: String
    let onStop: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var isPointingCorrectly: Bool = false
    @State private var previousPointingState: Bool = false

    var distanceText: String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return "\(Int(distance)) m"
        }
    }

    var body: some View {
        ZStack {
            // Background - Verde cuando está apuntando correctamente
            (isPointingCorrectly ? Color.green.opacity(0.15) : Color.black)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: isPointingCorrectly)

            VStack(spacing: 12) {
                // Distancia restante
                VStack(spacing: 4) {
                    Text(distanceText)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: isPointingCorrectly ? [.green, .cyan] : [.white, .gray],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .animation(.easeInOut(duration: 0.3), value: isPointingCorrectly)

                    Text(instruction)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isPointingCorrectly ? .green : .gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .animation(.easeInOut(duration: 0.3), value: isPointingCorrectly)
                }
                .padding(.top, 4)

                // Indicador de dirección correcta
                if isPointingCorrectly {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.green)
                        Text("¡Dirección correcta!")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.2))
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                // Flecha de dirección grande
                ZStack {
                    // Círculo de fondo con pulso - más intenso cuando está correcto
                    Circle()
                        .fill((isPointingCorrectly ? Color.green : direction.color).opacity(0.2))
                        .frame(width: 90, height: 90)
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeInOut(duration: isPointingCorrectly ? 0.8 : 1.5)
                                .repeatForever(autoreverses: true),
                            value: pulseScale
                        )

                    Circle()
                        .fill((isPointingCorrectly ? Color.green : direction.color).opacity(0.3))
                        .frame(width: 80, height: 80)

                    // Flecha principal
                    Image(systemName: direction.arrowIcon)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(isPointingCorrectly ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPointingCorrectly)
                }
                .onAppear {
                    pulseScale = 1.2
                }
                .onChange(of: isPointingCorrectly) { newValue in
                    // Vibración cuando entra en la dirección correcta
                    if newValue && !previousPointingState {
                        triggerSuccessHaptic()
                    }
                    previousPointingState = newValue
                }

                // Barra de progreso visual (opcional)
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index < 3 ? direction.color : Color.gray.opacity(0.3))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // Botón para detener
                Button(action: onStop) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Finalizar")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.red)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .digitalCrownRotation($distance, from: 0, through: 5000, by: 10, sensitivity: .medium)
        .onAppear {
            // Simular cambios de dirección para demo
            simulateNavigation()
        }
    }

    // Simular cambios de navegación
    private func simulateNavigation() {
        // Timer para cambiar dirección cada 3 segundos
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                // Cambiar dirección aleatoriamente
                let directions: [NavigationDirection] = [.forward, .left, .right, .slightLeft, .slightRight]
                direction = directions.randomElement() ?? .forward

                // Actualizar instrucción
                switch direction {
                case .forward:
                    instruction = "Continúa recto"
                case .left:
                    instruction = "Gira a la izquierda"
                case .right:
                    instruction = "Gira a la derecha"
                case .slightLeft:
                    instruction = "Mantén la izquierda"
                case .slightRight:
                    instruction = "Mantén la derecha"
                case .sharpLeft:
                    instruction = "Giro cerrado a la izquierda"
                case .sharpRight:
                    instruction = "Giro cerrado a la derecha"
                case .uTurn:
                    instruction = "Da la vuelta"
                }

                // Reducir distancia
                if distance > 50 {
                    distance -= 30
                }
            }
        }

        // Timer para simular cuando está apuntando correctamente (cada 1.5 segundos)
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                // Simular que apunta correctamente cuando la dirección es "forward"
                // En producción, esto vendría del giroscopio/brújula del Watch
                isPointingCorrectly = direction == .forward && Bool.random()
            }
        }
    }

    // Activar vibración háptica de éxito
    private func triggerSuccessHaptic() {
        // Vibración de éxito (patrón más fuerte)
        WKInterfaceDevice.current().play(.success)

        // Vibración adicional para enfatizar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            WKInterfaceDevice.current().play(.click)
        }
    }
}

// MARK: - Navigation Preview View
struct NavigationPreviewView: View {
    let onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Icon and title
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .cyan.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)

                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    Text("Navegación")
                        .font(.headline)

                    Text("Próximo destino")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                // Stats
                HStack(spacing: 20) {
                    StatBadge(value: "2.4", unit: "km", icon: "figure.walk")
                    StatBadge(value: "15", unit: "min", icon: "clock")
                }

                // Start Navigation Button
                Button(action: onStart) {
                    Label("Iniciar", systemImage: "location.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let value: String
    let unit: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.cyan)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.15))
        )
    }
}

// MARK: - Community View
struct CommunityWatchView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                VStack(spacing: 4) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Comunidad")
                        .font(.headline)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text("128 activos")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 8)

                Divider()

                // Posts recientes
                VStack(spacing: 8) {
                    CommunityPostCard(
                        username: "Ana M.",
                        time: "hace 5m",
                        content: "Nueva ruta accesible en el centro",
                        likes: 12
                    )

                    CommunityPostCard(
                        username: "Carlos R.",
                        time: "hace 1h",
                        content: "Excelente experiencia con RA",
                        likes: 8
                    )

                    CommunityPostCard(
                        username: "María G.",
                        time: "hace 2h",
                        content: "Gracias por las guías de audio",
                        likes: 15
                    )
                }
            }
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Community Post Card
struct CommunityPostCard: View {
    let username: String
    let time: String
    let content: String
    let likes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(String(username.prefix(1)))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 0) {
                    Text(username)
                        .font(.system(size: 12, weight: .semibold))
                    Text(time)
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            Text(content)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .lineLimit(2)

            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.red)
                Text("\(likes)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.15))
        )
    }
}

// MARK: - Activity View
struct ActivityWatchView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 8)
                            .foregroundColor(.gray.opacity(0.2))
                            .frame(width: 70, height: 70)

                        Circle()
                            .trim(from: 0, to: 0.65)
                            .stroke(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Text("65")
                                .font(.system(size: 22, weight: .bold))
                            Text("%")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }

                    Text("Tu Actividad")
                        .font(.headline)

                    Text("Esta semana")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.top, 8)

                Divider()

                // Activity Stats
                VStack(spacing: 8) {
                    ActivityRow(
                        icon: "figure.walk",
                        title: "Rutas completadas",
                        value: "12",
                        color: .blue
                    )

                    ActivityRow(
                        icon: "map",
                        title: "Kilómetros",
                        value: "24.5",
                        color: .green
                    )

                    ActivityRow(
                        icon: "clock",
                        title: "Tiempo total",
                        value: "3h 45m",
                        color: .orange
                    )

                    ActivityRow(
                        icon: "star.fill",
                        title: "Lugares favoritos",
                        value: "8",
                        color: .yellow
                    )
                }
            }
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.15))
        )
    }
}

#Preview {
    ContentView()
}
