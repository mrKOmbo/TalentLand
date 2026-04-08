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
    @Published var showHeatMap = true

    private var events: [DemandEvent] = []

    private init() {
        loadMockDemandData(around: (19.3585, -99.2740)) // Expo Santa Fe CDMX
        // Diferir para evitar "Publishing changes from within view updates"
        DispatchQueue.main.async { [self] in
            demandZones = calculateDemandZones()
        }
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
        // Muchos vendedores ambulantes concentrados alrededor de Expo Santa Fe
        // Offsets pequeños (~0.0005° ≈ 50m) para simular puestos individuales
        let mockOffsets: [(dLat: Double, dLon: Double, cat: MerchantCategory, count: Int)] = [
            // DENTRO de la Expo — alta densidad
            ( 0.0000,  0.0000, .tacos,     20),
            ( 0.0003, -0.0004, .bebidas,   15),
            (-0.0003,  0.0003, .tamales,   12),
            ( 0.0005,  0.0002, .antojitos, 10),
            (-0.0004, -0.0002, .elotes,    14),
            ( 0.0002, -0.0006, .jugos,      8),
            (-0.0006,  0.0001, .helados,   10),
            // Entrada norte — estacionamiento
            ( 0.0012,  0.0000, .tacos,     12),
            ( 0.0010,  0.0005, .bebidas,    8),
            ( 0.0014, -0.0003, .frutas,     6),
            // Entrada sur — Bancomer/DoubleTree
            (-0.0010,  0.0000, .tamales,   10),
            (-0.0012, -0.0004, .antojitos,  7),
            (-0.0008,  0.0006, .postres,    5),
            // Calle lateral este — Av. Santa Fe
            ( 0.0003,  0.0012, .tacos,      9),
            ( 0.0006,  0.0015, .elotes,     7),
            (-0.0002,  0.0010, .bebidas,    6),
            ( 0.0000,  0.0018, .jugos,      5),
            // Calle lateral oeste — Av. Vasco de Quiroga
            ( 0.0004, -0.0014, .helados,    8),
            (-0.0003, -0.0012, .tacos,      6),
            ( 0.0007, -0.0010, .tamales,    5),
            // Alrededores cercanos — Centro comercial Santa Fe
            ( 0.0020,  0.0010, .bebidas,    8),
            ( 0.0018,  0.0015, .antojitos,  6),
            ( 0.0025,  0.0005, .tacos,     10),
            // Tec de Monterrey CSF
            (-0.0018, -0.0008, .jugos,      7),
            (-0.0020,  0.0003, .frutas,     5),
            (-0.0015, -0.0015, .elotes,     8),
            // Corporativo Santa Fe
            ( 0.0008,  0.0025, .tacos,      6),
            ( 0.0012,  0.0020, .bebidas,    5),
            // Lomas de Santa Fe
            ( 0.0030,  0.0000, .helados,    4),
            ( 0.0028, -0.0010, .postres,    3),
            (-0.0025,  0.0012, .tamales,    5),
        ]

        for offset in mockOffsets {
            let baseLat = center.lat + offset.dLat
            let baseLon = center.lon + offset.dLon
            for _ in 0..<offset.count {
                // Jitter muy pequeño (~20m) para simular puestos individuales
                let jitterLat = Double.random(in: -0.0003...0.0003)
                let jitterLon = Double.random(in: -0.0003...0.0003)
                let minutesAgo = Double.random(in: 0...45)
                let lat = baseLat + jitterLat
                let lon = baseLon + jitterLon
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
