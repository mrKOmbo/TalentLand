import Foundation

/// Niveles de canales de ubicación mapeados a precisiones de geohash.
/// Adaptado de bitchat (public domain).
enum GeohashChannelLevel: CaseIterable, Codable, Equatable {
    case building      // ~20m  — precisión de edificio
    case block         // ~150m — cuadra
    case neighborhood  // ~1km  — colonia/barrio
    case city          // ~5km  — ciudad
    case province      // ~40km — estado/provincia
    case region        // ~600km — país/región

    var precision: Int {
        switch self {
        case .building: return 8
        case .block: return 7
        case .neighborhood: return 6
        case .city: return 5
        case .province: return 4
        case .region: return 2
        }
    }

    var displayName: String {
        switch self {
        case .building: return "Edificio"
        case .block: return "Cuadra"
        case .neighborhood: return "Colonia"
        case .city: return "Ciudad"
        case .province: return "Estado"
        case .region: return "Región"
        }
    }

    var radiusDescription: String {
        switch self {
        case .building: return "~20m"
        case .block: return "~150m"
        case .neighborhood: return "~1km"
        case .city: return "~5km"
        case .province: return "~40km"
        case .region: return "~600km"
        }
    }
}

/// Canal geohash computado.
struct GeohashChannel: Codable, Equatable, Hashable, Identifiable {
    let level: GeohashChannelLevel
    let geohash: String

    var id: String { "\(level)-\(geohash)" }

    var displayName: String {
        "\(level.displayName) • \(geohash)"
    }
}
