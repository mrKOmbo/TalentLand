//
//  AteneaWidgets.swift
//  AteneaWidgets
//
//  Widget Extension para Live Activities con Dynamic Island
//  VERSIÓN SIMPLIFICADA PARA PRUEBAS
//

import ActivityKit
import WidgetKit
import SwiftUI

@main
struct AteneaWidgetsBundle: WidgetBundle {
    var body: some Widget {
        NavigationLiveActivity()
    }
}

struct NavigationLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NavigationActivityAttributes.self) { context in
            // MARK: - Lock Screen / Banner View
            VStack(spacing: 12) {
                // Destino
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.destinationName)
                            .font(.headline)
                            .foregroundColor(.white)

                        if !context.attributes.destinationCity.isEmpty {
                            Text(context.attributes.destinationCity)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    Spacer()

                    // Estado de navegación
                    Text(context.state.navigationState.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.3))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }

                Divider()
                    .background(Color.white.opacity(0.3))

                // Instrucción
                HStack {
                    Image(systemName: "arrow.turn.up.right")
                        .foregroundColor(.blue)

                    Text(context.state.currentInstruction)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Info
                HStack(spacing: 20) {
                    VStack {
                        Text(formatMinutes(context.state.estimatedMinutes))
                            .font(.title2)
                            .bold()
                        Text("ETA")
                            .font(.caption)
                    }

                    Divider()
                        .frame(height: 40)
                        .background(Color.white.opacity(0.3))

                    VStack {
                        Text(formatDistance(context.state.distanceRemaining))
                            .font(.title2)
                            .bold()
                        Text("Distancia")
                            .font(.caption)
                    }

                    if context.state.currentSpeed > 0 {
                        Divider()
                            .frame(height: 40)
                            .background(Color.white.opacity(0.3))

                        VStack {
                            Text("\(Int(context.state.currentSpeed))")
                                .font(.title2)
                                .bold()
                            Text("km/h")
                                .font(.caption)
                        }
                    }
                }
                .foregroundColor(.white)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.95), Color.black.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

        } dynamicIsland: { context in
            // MARK: - Dynamic Island
            DynamicIsland {
                // Expanded - Leading
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.green)

                            Text(context.attributes.destinationName)
                                .font(.headline)
                                .lineLimit(1)
                        }

                        if !context.state.currentStreet.isEmpty {
                            Text(context.state.currentStreet)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                // Expanded - Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(formatMinutes(context.state.estimatedMinutes))
                            .font(.title3)
                            .bold()
                        Text("ETA")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Expanded - Center
                DynamicIslandExpandedRegion(.center) {
                    HStack {
                        Image(systemName: "arrow.turn.up.right")
                            .foregroundColor(.blue)

                        Text(context.state.currentInstruction)
                            .font(.caption)
                            .lineLimit(2)
                    }
                }

                // Expanded - Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        // Distancia
                        HStack {
                            Image(systemName: "road.lanes")
                                .foregroundColor(.secondary)
                            Text(formatDistance(context.state.distanceRemaining))
                                .font(.caption)
                                .bold()
                        }

                        Spacer()

                        // Velocidad (si está disponible)
                        if context.state.currentSpeed > 0 {
                            HStack {
                                Image(systemName: "speedometer")
                                    .foregroundColor(.secondary)
                                Text("\(Int(context.state.currentSpeed)) km/h")
                                    .font(.caption)
                                    .bold()
                            }
                        }

                        Spacer()

                        // Estado
                        Text(context.state.navigationState.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(4)
                    }
                    .padding(.horizontal)
                }

            } compactLeading: {
                // Compact - Leading
                HStack(spacing: 2) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)
                    Text(formatDistance(context.state.distanceRemaining))
                        .font(.caption2)
                        .bold()
                }

            } compactTrailing: {
                // Compact - Trailing
                Text(formatMinutes(context.state.estimatedMinutes))
                    .font(.caption)
                    .bold()

            } minimal: {
                // Minimal
                Image(systemName: context.state.navigationState == .active ? "location.fill" : "location.slash.fill")
                    .foregroundColor(context.state.navigationState == .active ? .green : .orange)
            }
        }
    }

    // MARK: - Helper Functions

    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            let km = meters / 1000
            return String(format: "%.1f km", km)
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes == 0 {
            return "< 1 min"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            if remainingMinutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes) min"
        }
    }
}
