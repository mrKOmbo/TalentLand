//
//  DemandZoneManager.swift
//  atenea
//
//  Agrega eventos de demanda por zona geohash y calcula zonas calientes
//

import Foundation
internal import Combine

@MainActor
class DemandZoneManager: ObservableObject {
    static let shared = DemandZoneManager()

    @Published var demandZones: [DemandZone] = []
    @Published var showHeatMap = false

    private var events: [DemandEvent] = []

    private init() {
        loadMockDemandData(around: (19.4326, -99.1332)) // fallback CDMX
        demandZones = calculateDemandZones()
    }

    /// Regenera el mock data centrado en la ubicación actual (para simulador/testing)
    func refreshMockData(around center: (lat: Double, lon: Double)) {
        events = []
        loadMockDemandData(around: center)
        demandZones = calculateDemandZones()
    }

    // MARK: - Registrar demanda

    func recordDemand(latitude: Double, longitude: Double, source: DemandSource, category: MerchantCategory? = nil) {
        let geohash = Geohash.encode(latitude: latitude, longitude: longitude, precision: GeohashChannelLevel.neighborhood.precision)
        let event = DemandEvent(geohash: geohash, source: source, category: category)
        events.append(event)
        demandZones = calculateDemandZones()
    }

    // MARK: - Calcular zonas

    func calculateDemandZones(timeWindow: TimeInterval = 3600) -> [DemandZone] {
        let cutoff = Date().addingTimeInterval(-timeWindow)
        let recentEvents = events.filter { $0.timestamp > cutoff }

        // Agrupar por geohash
        var grouped: [String: [DemandEvent]] = [:]
        for event in recentEvents {
            grouped[event.geohash, default: []].append(event)
        }

        return grouped.map { geohash, zoneEvents in
            let center = Geohash.decodeCenter(geohash)
            let bounds = Geohash.decodeBounds(geohash)

            // Categoría más frecuente
            let categoryCounts = zoneEvents.compactMap(\.category).reduce(into: [MerchantCategory: Int]()) { $0[$1, default: 0] += 1 }
            let topCategory = categoryCounts.max(by: { $0.value < $1.value })?.key

            return DemandZone(
                id: geohash,
                geohash: geohash,
                center: center,
                bounds: bounds,
                demandScore: zoneEvents.count,
                topCategory: topCategory,
                lastActivity: zoneEvents.map(\.timestamp).max() ?? Date()
            )
        }
        .sorted { $0.demandScore > $1.demandScore }
    }

    // MARK: - Queries

    func topZones(for category: MerchantCategory? = nil, limit: Int = 5) -> [DemandZone] {
        let zones: [DemandZone]
        if let category = category {
            zones = demandZones.filter { $0.topCategory == category }
        } else {
            zones = demandZones
        }
        return Array(zones.prefix(limit))
    }

    func demandScore(for geohash: String, timeWindow: TimeInterval = 3600) -> Int {
        let cutoff = Date().addingTimeInterval(-timeWindow)
        return events.filter { $0.geohash == geohash && $0.timestamp > cutoff }.count
    }

    func totalDemandLastHour() -> Int {
        let cutoff = Date().addingTimeInterval(-3600)
        return events.filter { $0.timestamp > cutoff }.count
    }

    // MARK: - Mock Data

    private func loadMockDemandData(around center: (lat: Double, lon: Double)) {
        // Offsets relativos al centro (en grados ≈ cuadras/colonias)
        let mockOffsets: [(dLat: Double, dLon: Double, cat: MerchantCategory, count: Int)] = [
            (0.000,  0.000,  .tacos,    8),
            (0.001, -0.001,  .bebidas,  4),
            (0.012,  0.017,  .tamales,  6),
            (0.013,  0.016,  .antojitos,3),
            (-0.008, 0.005,  .helados,  5),
            (0.010, -0.003,  .jugos,    3),
            (0.009, -0.025,  .elotes,   7),
            (0.010, -0.024,  .bebidas,  2),
            (0.008, -0.014,  .tacos,    4),
        ]

        for offset in mockOffsets {
            let lat = center.lat + offset.dLat
            let lon = center.lon + offset.dLon
            for _ in 0..<offset.count {
                let minutesAgo = Double.random(in: 0...50)
                let geohash = Geohash.encode(latitude: lat, longitude: lon, precision: GeohashChannelLevel.neighborhood.precision)
                events.append(DemandEvent(
                    geohash: geohash,
                    source: [.timbre, .search, .browse].randomElement()!,
                    category: offset.cat,
                    timestamp: Date().addingTimeInterval(-minutesAgo * 60)
                ))
            }
        }
    }
}
