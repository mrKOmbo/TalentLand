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
        loadMockDemandData()
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

    private func loadMockDemandData() {
        // Coordenadas reales de CDMX con demanda simulada
        let mockPoints: [(lat: Double, lon: Double, cat: MerchantCategory, count: Int)] = [
            // Zona Azteca — alta demanda de tacos (pre-partido)
            (19.3029, -99.1506, .tacos, 8),
            (19.3035, -99.1510, .bebidas, 4),
            // Zócalo — tamales y antojitos
            (19.4326, -99.1332, .tamales, 6),
            (19.4330, -99.1340, .antojitos, 3),
            // Coyoacán — helados
            (19.3492, -99.1617, .helados, 5),
            // Roma Norte — jugos
            (19.4185, -99.1654, .jugos, 3),
            // Chapultepec — elotes
            (19.4204, -99.1895, .elotes, 7),
            (19.4210, -99.1890, .bebidas, 2),
            // Condesa
            (19.4115, -99.1748, .tacos, 4),
        ]

        for point in mockPoints {
            for i in 0..<point.count {
                let minutesAgo = Double.random(in: 0...50)
                let geohash = Geohash.encode(latitude: point.lat, longitude: point.lon, precision: GeohashChannelLevel.neighborhood.precision)
                events.append(DemandEvent(
                    geohash: geohash,
                    source: [.timbre, .search, .browse].randomElement()!,
                    category: point.cat,
                    timestamp: Date().addingTimeInterval(-minutesAgo * 60)
                ))
            }
        }
    }
}
