//
//  DemandEvent.swift
//  atenea
//
//  Modelos de demanda por zona geohash
//

import Foundation
import SwiftUI

// MARK: - Demand Source

enum DemandSource: String, Codable {
    case timbre = "timbre"
    case search = "search"
    case browse = "browse"
}

// MARK: - Demand Event

struct DemandEvent: Identifiable, Codable {
    let id: UUID
    let geohash: String
    let source: DemandSource
    let category: MerchantCategory?
    let timestamp: Date

    init(id: UUID = UUID(), geohash: String, source: DemandSource, category: MerchantCategory? = nil, timestamp: Date = Date()) {
        self.id = id
        self.geohash = geohash
        self.source = source
        self.category = category
        self.timestamp = timestamp
    }
}

// MARK: - Demand Zone

struct DemandZone: Identifiable {
    let id: String
    let geohash: String
    let center: (lat: Double, lon: Double)
    let bounds: (latMin: Double, latMax: Double, lonMin: Double, lonMax: Double)
    let demandScore: Int
    let topCategory: MerchantCategory?
    let lastActivity: Date

    var intensity: DemandIntensity {
        switch demandScore {
        case 0...2: return .low
        case 3...5: return .medium
        case 6...10: return .high
        default: return .veryHigh
        }
    }
}

// MARK: - Demand Intensity

enum DemandIntensity: Int, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
    case veryHigh = 3

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .veryHigh: return .red
        }
    }

    var opacity: Double {
        switch self {
        case .low: return 0.15
        case .medium: return 0.25
        case .high: return 0.35
        case .veryHigh: return 0.45
        }
    }

    var displayName: String {
        switch self {
        case .low: return "Baja"
        case .medium: return "Media"
        case .high: return "Alta"
        case .veryHigh: return "Muy alta"
        }
    }
}
