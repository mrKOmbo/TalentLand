//
//  AteneaWidgets.swift
//  ateneaWidgets
//
//  Widget Extension para Live Activities con Dynamic Island
//  Copiado desde proyecto preProject
//

import ActivityKit
import WidgetKit
import SwiftUI

@main
struct AteneaWidgetsBundle: WidgetBundle {
    var body: some Widget {
        EmergencyWidget()
        NavigationLiveActivity()
    }
}

// MARK: - Widget Estándar de Emergencia

struct EmergencyWidget: Widget {
    let kind: String = "EmergencyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EmergencyProvider()) { entry in
            EmergencyWidgetView(entry: entry)
        }
        .configurationDisplayName("Atenea Emergency")
        .description("Quick access to emergency services")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct EmergencyEntry: TimelineEntry {
    let date: Date
}

struct EmergencyProvider: TimelineProvider {
    func placeholder(in context: Context) -> EmergencyEntry {
        EmergencyEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (EmergencyEntry) -> ()) {
        let entry = EmergencyEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EmergencyEntry>) -> ()) {
        let entry = EmergencyEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct EmergencyWidgetView: View {
    var entry: EmergencyProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallEmergencyWidget()
        case .systemMedium:
            MediumEmergencyWidget()
        default:
            SmallEmergencyWidget()
        }
    }
}

// MARK: - Small Widget (Botón de Emergencia)

struct SmallEmergencyWidget: View {
    var body: some View {
        VStack(spacing: 12) {
            // Icono pulsante
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 80, height: 80)

                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("Emergency")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Text("Tap to activate")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color.red,
                    Color.red.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .widgetURL(URL(string: "atenea://emergency")!)
    }
}

// MARK: - Medium Widget (Emergencia + Info)

struct MediumEmergencyWidget: View {
    var body: some View {
        HStack(spacing: 16) {
            // Lado izquierdo - Botón de emergencia
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 70, height: 70)

                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 55, height: 55)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Emergency")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)

            // Lado derecho - Información
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Quick Access")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 4, height: 4)

                        Text("Activate emergency mode")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 4, height: 4)

                        Text("Share location")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 4, height: 4)

                        Text("Alert contacts")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color.red,
                    Color.red.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .widgetURL(URL(string: "atenea://emergency")!)
    }
}

struct NavigationLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NavigationActivityAttributes.self) { context in
            // MARK: - Lock Screen / Banner View
            ZStack {
                // Fondo con gradiente sutil
                LinearGradient(
                    colors: [
                        Color(hex: "#00D084").opacity(0.05),
                        Color.clear,
                        Color(hex: "#C8FF00").opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 12) {
                    // Header con destino
                    HStack(spacing: 12) {
                        ZStack {
                            // Círculo pulsante de fondo
                            Circle()
                                .fill(Color(hex: "#00D084").opacity(0.2))
                                .frame(width: 40, height: 40)

                            Image(systemName: "location.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(hex: "#00D084"))
                                .symbolEffect(.pulse)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Navigating to")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))

                            Text(context.attributes.destinationName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }

                        Spacer()
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))

                    // Instrucción actual con animación
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "#C8FF00").opacity(0.15))
                                .frame(width: 32, height: 32)

                            Image(systemName: "arrow.up")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "#C8FF00"))
                                .symbolEffect(.pulse)
                        }

                        Text(context.state.currentInstruction)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .transition(.push(from: .bottom))

                        Spacer()
                    }

                    // ETA y Distancia con diseño mejorado
                    HStack(spacing: 16) {
                        // Card de ETA
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#00D084"))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatTime(context.state.timeRemaining))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .contentTransition(.numericText())

                                Text("ETA")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#00D084").opacity(0.1))
                        )

                        // Card de Distancia
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#C8FF00"))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatDistance(context.state.distanceRemaining))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .contentTransition(.numericText())

                                Text("Distance")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#C8FF00").opacity(0.1))
                        )
                    }
                }
                .padding(16)
            }
            .activityBackgroundTint(Color.black.opacity(0.95))
            .activitySystemActionForegroundColor(Color(hex: "#00D084"))
            .widgetURL(URL(string: "atenea://navigation/active")!)

        } dynamicIsland: { context in
            // MARK: - Dynamic Island
            DynamicIsland {
                // MARK: Expanded - Leading (DESTINO E INSTRUCCIÓN CON ANIMACIONES)
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 8) {
                        // Destino con ícono animado
                        HStack(spacing: 8) {
                            ZStack {
                                // Resplandor exterior
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color(hex: "#00D084").opacity(0.4),
                                                Color(hex: "#00D084").opacity(0.0)
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 24
                                        )
                                    )
                                    .frame(width: 48, height: 48)
                                    .symbolEffect(.pulse)

                                // Círculo principal con gradiente
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#00D084"), Color(hex: "#00A066")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 36, height: 36)
                                    .shadow(color: Color(hex: "#00D084").opacity(0.6), radius: 8, x: 0, y: 4)

                                // Ícono con animación de rebote
                                Image(systemName: "location.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .symbolEffect(.bounce, options: .repeating.speed(0.5))
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Hacia")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .textCase(.uppercase)

                                Text(context.attributes.destinationName)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                        }
                        .transition(.scale.combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.7)))

                        // Instrucción actual con animación de entrada
                        HStack(spacing: 6) {
                            // Flecha con rotación y pulso
                            Image(systemName: "arrow.up")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "#C8FF00"))
                                .symbolEffect(.pulse, options: .repeating)

                            Text(context.state.currentInstruction)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                                .transition(.push(from: .bottom).combined(with: .opacity))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: context.state.currentInstruction)
                        }
                    }
                    .transition(.move(edge: .leading).combined(with: .scale).animation(.spring(response: 0.5, dampingFraction: 0.7)))
                }

                // MARK: Expanded - Trailing (TIEMPO RESTANTE CON ANIMACIÓN BRILLANTE)
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 6) {
                        // Tiempo restante MUY DESTACADO con múltiples sombras
                        Text(formatTime(context.state.timeRemaining))
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .shadow(color: Color(hex: "#C8FF00").opacity(0.6), radius: 6, x: 0, y: 3)
                            .shadow(color: Color(hex: "#C8FF00").opacity(0.3), radius: 12, x: 0, y: 6)

                        // Label con ícono animado
                        HStack(spacing: 4) {
                            // Reloj con efecto de respiración
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(hex: "#C8FF00"))
                                .symbolEffect(.pulse, options: .repeating.speed(0.8))
                                .shadow(color: Color(hex: "#C8FF00").opacity(0.5), radius: 4, x: 0, y: 2)

                            Text("Tiempo")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "#C8FF00"))
                        }
                    }
                    .transition(.move(edge: .trailing).combined(with: .scale).animation(.spring(response: 0.5, dampingFraction: 0.7)))
                }

                // MARK: Expanded - Bottom (DISTANCIA CON ANIMACIÓN ESPECTACULAR)
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 10) {
                        // Distancia restante con animación dinámica
                        HStack(spacing: 10) {
                            ZStack {
                                // Resplandor pulsante exterior
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color(hex: "#C8FF00").opacity(0.3),
                                                Color(hex: "#C8FF00").opacity(0.0)
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 20
                                        )
                                    )
                                    .frame(width: 40, height: 40)
                                    .symbolEffect(.pulse, options: .repeating)

                                // Círculo de fondo
                                Circle()
                                    .fill(Color(hex: "#C8FF00").opacity(0.25))
                                    .frame(width: 32, height: 32)

                                // Flecha animada
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: "#C8FF00"))
                                    .symbolEffect(.bounce, options: .repeating.speed(0.6))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                // Distancia con brillo
                                Text(formatDistance(context.state.distanceRemaining))
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(.white)
                                    .monospacedDigit()
                                    .contentTransition(.numericText())
                                    .shadow(color: Color(hex: "#C8FF00").opacity(0.4), radius: 4, x: 0, y: 2)

                                Text("Distancia restante")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Spacer()

                            // Indicador de navegación activa con animación
                            VStack(spacing: 2) {
                                ZStack {
                                    // Resplandor de fondo
                                    Circle()
                                        .fill(Color(hex: "#00D084").opacity(0.3))
                                        .frame(width: 12, height: 12)
                                        .symbolEffect(.pulse)

                                    // Punto central
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                        .foregroundColor(Color(hex: "#00D084"))
                                        .symbolEffect(.pulse, options: .repeating.speed(1.2))
                                }

                                Text("Activa")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(Color(hex: "#00D084"))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "#00D084").opacity(0.08),
                                            Color(hex: "#C8FF00").opacity(0.05)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color(hex: "#00D084").opacity(0.2), radius: 8, x: 0, y: 4)
                        )
                    }
                    .transition(.move(edge: .bottom).combined(with: .scale).animation(.spring(response: 0.6, dampingFraction: 0.7)))
                }

            } compactLeading: {
                // MARK: Compact - Leading (FLECHA DE NAVEGACIÓN ANIMADA)
                ZStack {
                    // Círculo de fondo con efecto de respiración
                    Circle()
                        .fill(Color(hex: "#00D084").opacity(0.25))
                        .frame(width: 20, height: 20)
                        .symbolEffect(.pulse.byLayer)

                    // Círculo brillante intermitente
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "#00D084").opacity(0.6),
                                    Color(hex: "#00D084").opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 10
                            )
                        )
                        .frame(width: 20, height: 20)
                        .symbolEffect(.pulse)

                    // Flecha con efecto de rebote
                    Image(systemName: "arrow.up")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#00D084"))
                        .symbolEffect(.bounce, options: .repeating.speed(0.5))
                }
                .transition(.scale.combined(with: .opacity))

            } compactTrailing: {
                // MARK: Compact - Trailing (TIEMPO CON ANIMACIÓN DESTACADA)
                HStack(spacing: 4) {
                    // Reloj con efecto pulsante
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "#C8FF00"))
                        .symbolEffect(.pulse, options: .repeating)

                    // Tiempo con brillo
                    Text(formatTime(context.state.timeRemaining))
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .shadow(color: Color(hex: "#C8FF00").opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                .transition(.push(from: .trailing).combined(with: .scale))

            } minimal: {
                // MARK: Minimal (FLECHA CON EFECTO BRILLANTE)
                ZStack {
                    // Resplandor de fondo
                    Image(systemName: "circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#00D084").opacity(0.3))
                        .symbolEffect(.pulse)

                    // Flecha principal con rebote
                    Image(systemName: "arrow.up")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#00D084"))
                        .symbolEffect(.bounce, options: .repeating.speed(0.6))
                }
                .transition(.scale.animation(.spring(response: 0.3, dampingFraction: 0.6)))
            }
        }
    }

    // MARK: - Helper Functions

    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            let km = meters / 1000
            if km < 10 {
                return String(format: "%.1f km", km)
            } else {
                return "\(Int(km)) km"
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "< 1 min"
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
