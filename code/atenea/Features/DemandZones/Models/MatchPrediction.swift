/*
//
//  MatchPrediction.swift
//  atenea
//
//  Modelo de predicción de demanda por partido del Mundial
//  Motor determinístico basado en reglas (no ML)
//
//  Variables: hora relativa al kickoff, distancia al estadio, clima,
//  importancia del partido, categoría de producto
//

import Foundation
import CoreLocation

// MARK: - Match Prediction

struct MatchPrediction: Identifiable {
    let id = UUID()
    let match: WorldCupMatch
    let venue: WorldCupVenue
    let kickoffDate: Date
    let zones: [PredictedZone]
    let peakDemandWindow: String
    let estimatedFootTraffic: Int
    let topCategories: [(MerchantCategory, Double)] // (categoría, multiplicador)
}

// MARK: - Predicted Zone

struct PredictedZone: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let geohash: String
    let demandScore: Double // 0-100
    let intensity: DemandIntensity
    let peakTime: String // "2h antes del partido"
    let recommendedProducts: [MerchantCategory]
    let distanceFromStadium: Double // metros
}

// MARK: - Weather Condition (para predicción)

enum WeatherCondition: String, CaseIterable {
    case sunny = "sunny"
    case cloudy = "cloudy"
    case lightRain = "light_rain"
    case heavyRain = "heavy_rain"
    case hot = "hot" // >30°C
    case cool = "cool" // <18°C

    var displayName: String {
        switch self {
        case .sunny: return "Soleado"
        case .cloudy: return "Nublado"
        case .lightRain: return "Lluvia ligera"
        case .heavyRain: return "Lluvia fuerte"
        case .hot: return "Caluroso (>30°C)"
        case .cool: return "Fresco (<18°C)"
        }
    }

    var emoji: String {
        switch self {
        case .sunny: return "☀️"
        case .cloudy: return "⛅"
        case .lightRain: return "🌦️"
        case .heavyRain: return "🌧️"
        case .hot: return "🔥"
        case .cool: return "🌙"
        }
    }

    // Multiplicadores por categoría de producto según clima
    func multiplier(for category: MerchantCategory) -> Double {
        switch (self, category) {
        // Bebidas frías explotan con calor
        case (.hot, .bebidas), (.hot, .jugos): return 2.5
        case (.hot, .helados): return 2.2
        case (.sunny, .bebidas), (.sunny, .jugos): return 1.5
        case (.sunny, .helados): return 1.8

        // Comida caliente sube con frío/lluvia
        case (.cool, .tacos), (.cool, .tamales): return 1.8
        case (.lightRain, .tacos), (.lightRain, .tamales): return 1.5
        case (.lightRain, .antojitos): return 1.3

        // Lluvia fuerte baja todo excepto comida caliente
        case (.heavyRain, .tacos), (.heavyRain, .tamales): return 1.2
        case (.heavyRain, _): return 0.3

        // Calor baja comida caliente
        case (.hot, .tamales): return 0.6
        case (.hot, .tacos): return 0.8

        default: return 1.0
        }
    }
}

// MARK: - Match Stage Multiplier

extension WorldCupMatch {
    var stageMultiplier: Double {
        let stageLower = stage.lowercased()
        if stageLower.contains("final") && !stageLower.contains("semi") && !stageLower.contains("cuartos") && !stageLower.contains("tercer") {
            return 1.4
        } else if stageLower.contains("semi") {
            return 1.25
        } else if stageLower.contains("cuartos") || stageLower.contains("quarter") {
            return 1.15
        } else if stageLower.contains("octavos") || stageLower.contains("round of 16") {
            return 1.05
        } else if stageLower.contains("tercer") || stageLower.contains("third") {
            return 0.9
        }
        return 1.0 // Fase de grupos
    }

    var isMexicoPlaying: Bool {
        let teamsLower = teams.lowercased()
        return teamsLower.contains("méxico") || teamsLower.contains("mexico") || teamsLower.contains("mex")
    }
}

// MARK: - Time Window

enum MatchTimeWindow: CaseIterable {
    case earlyArrival    // t-3h a t-1h
    case lateArrival     // t-1h a kickoff
    case duringMatch     // durante
    case earlyExit       // t+0 a t+1h
    case lateExit        // t+1h a t+3h

    var label: String {
        switch self {
        case .earlyArrival: return "3-1h antes"
        case .lateArrival: return "1h antes"
        case .duringMatch: return "Durante"
        case .earlyExit: return "0-1h después"
        case .lateExit: return "1-3h después"
        }
    }

    // Porcentaje del gasto total en esta ventana (datos FIFA 2014/2018)
    var spendingShare: Double {
        switch self {
        case .earlyArrival: return 0.375
        case .lateArrival: return 0.225
        case .duringMatch: return 0.075
        case .earlyExit: return 0.275
        case .lateExit: return 0.05
        }
    }

    var icon: String {
        switch self {
        case .earlyArrival: return "figure.walk.arrival"
        case .lateArrival: return "figure.walk"
        case .duringMatch: return "sportscourt.fill"
        case .earlyExit: return "figure.walk.departure"
        case .lateExit: return "moon.fill"
        }
    }
}
*/
