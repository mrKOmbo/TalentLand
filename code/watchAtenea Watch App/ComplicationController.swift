//
//  ComplicationController.swift
//  watchAtenea Watch App
//
//  Complicaciones para la carátula del Apple Watch
//

import SwiftUI
import WidgetKit

// MARK: - Complication Entry
struct ComplicationEntry: TimelineEntry {
    let date: Date
    let routesCompleted: Int
    let activeUsers: Int
    let distance: String
}

// MARK: - Complication Provider
struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(
            date: Date(),
            routesCompleted: 12,
            activeUsers: 128,
            distance: "2.4 km"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        let entry = ComplicationEntry(
            date: Date(),
            routesCompleted: 12,
            activeUsers: 128,
            distance: "2.4 km"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        let currentDate = Date()
        let entries: [ComplicationEntry] = [
            ComplicationEntry(
                date: currentDate,
                routesCompleted: 12,
                activeUsers: 128,
                distance: "2.4 km"
            )
        ]

        // Actualizar cada hora
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Complication Views
struct ComplicationCircularView: View {
    let entry: ComplicationEntry

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 2) {
                Image(systemName: "map.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text("\(entry.routesCompleted)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

struct ComplicationRectangularView: View {
    let entry: ComplicationEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "map.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Atenea")
                    .font(.system(size: 14, weight: .bold))

                HStack(spacing: 6) {
                    Label("\(entry.routesCompleted)", systemImage: "figure.walk")
                        .font(.system(size: 11))

                    Label("\(entry.activeUsers)", systemImage: "person.2")
                        .font(.system(size: 11))
                }
                .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(8)
    }
}

struct ComplicationCornerView: View {
    let entry: ComplicationEntry

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)

            Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Widget Configuration
// Nota: @main removido porque la app principal ya lo tiene en watchAteneaApp.swift
// Los widgets en el mismo target no deben tener @main
struct AteneaComplication: Widget {
    let kind: String = "AteneaComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ComplicationProvider()) { entry in
            ComplicationCircularView(entry: entry)
        }
        .configurationDisplayName("Atenea")
        .description("Navegación accesible directamente en tu reloj")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}

// MARK: - Preview
#Preview("Circular", as: .accessoryCircular) {
    AteneaComplication()
} timeline: {
    ComplicationEntry(date: Date(), routesCompleted: 12, activeUsers: 128, distance: "2.4 km")
}

#Preview("Rectangular", as: .accessoryRectangular) {
    AteneaComplication()
} timeline: {
    ComplicationEntry(date: Date(), routesCompleted: 12, activeUsers: 128, distance: "2.4 km")
}
