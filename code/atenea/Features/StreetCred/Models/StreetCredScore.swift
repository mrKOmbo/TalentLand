//
//  StreetCredScore.swift
//  atenea
//
//  Sistema de scoring crediticio alternativo para vendedores ambulantes
//  Inspirado en M-Pesa/M-Shwari, Square Capital, Airbnb Superhost
//

import SwiftUI

// MARK: - Street Cred Level

enum StreetCredLevel: Int, Codable, CaseIterable, Comparable {
    case nuevo = 0
    case bronce = 1
    case plata = 2
    case oro = 3
    case platino = 4
    case diamante = 5

    var displayName: String {
        switch self {
        case .nuevo: return "Nuevo"
        case .bronce: return "Bronce"
        case .plata: return "Plata"
        case .oro: return "Oro"
        case .platino: return "Platino"
        case .diamante: return "Diamante"
        }
    }

    var icon: String {
        switch self {
        case .nuevo: return "star"
        case .bronce: return "shield.fill"
        case .plata: return "shield.lefthalf.filled"
        case .oro: return "star.circle.fill"
        case .platino: return "crown.fill"
        case .diamante: return "diamond.fill"
        }
    }

    var color: Color {
        switch self {
        case .nuevo: return Color(hex: "#9E9E9E")
        case .bronce: return Color(hex: "#CD7F32")
        case .plata: return Color(hex: "#A8B5C5")
        case .oro: return Color(hex: "#F4B942")
        case .platino: return Color(hex: "#7B68EE")
        case .diamante: return Color(hex: "#185ADB")
        }
    }

    var gradient: [Color] {
        switch self {
        case .nuevo: return [Color(hex: "#9E9E9E"), Color(hex: "#757575")]
        case .bronce: return [Color(hex: "#CD7F32"), Color(hex: "#8B5E3C")]
        case .plata: return [Color(hex: "#C0C0C0"), Color(hex: "#8BA5B5")]
        case .oro: return [Color(hex: "#FFD700"), Color(hex: "#F4B942")]
        case .platino: return [Color(hex: "#9B7BFF"), Color(hex: "#7B68EE")]
        case .diamante: return [Color(hex: "#4DA6FF"), Color(hex: "#185ADB")]
        }
    }

    var minScore: Int {
        switch self {
        case .nuevo: return 0
        case .bronce: return 200
        case .plata: return 400
        case .oro: return 600
        case .platino: return 800
        case .diamante: return 900
        }
    }

    var nextLevel: StreetCredLevel? {
        switch self {
        case .nuevo: return .bronce
        case .bronce: return .plata
        case .plata: return .oro
        case .oro: return .platino
        case .platino: return .diamante
        case .diamante: return nil
        }
    }

    var creditBenefit: String {
        switch self {
        case .nuevo: return "Registra ventas para construir tu historial"
        case .bronce: return "Visibilidad +10% en el mapa"
        case .plata: return "Elegible para microcrédito Coppel Emprende"
        case .oro: return "Crédito preferencial + prioridad en eventos"
        case .platino: return "Acceso anticipado a zonas del Mundial"
        case .diamante: return "Comerciante destacado + tasas preferenciales"
        }
    }

    static func < (lhs: StreetCredLevel, rhs: StreetCredLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Score Dimension

struct ScoreDimension: Identifiable, Codable {
    let id: String
    let name: String
    let value: Double // 0.0 - 1.0
    let maxPoints: Int
    let details: String

    var points: Int {
        Int(value * Double(maxPoints))
    }

    var percentage: Double {
        value * 100
    }

    var color: Color {
        switch id {
        case "actividad": return Color(hex: "#FF6B6B")
        case "volumen": return Color(hex: "#4ECDC4")
        case "consistencia": return Color(hex: "#45B7D1")
        case "reputacion": return Color(hex: "#96CEB4")
        case "diversificacion": return Color(hex: "#FFEAA7")
        case "cobertura": return Color(hex: "#DDA0DD")
        default: return .gray
        }
    }

    var icon: String {
        switch id {
        case "actividad": return "flame.fill"
        case "volumen": return "chart.bar.fill"
        case "consistencia": return "clock.arrow.circlepath"
        case "reputacion": return "star.fill"
        case "diversificacion": return "square.grid.3x3.fill"
        case "cobertura": return "map.fill"
        default: return "circle.fill"
        }
    }
}

// MARK: - Badge

struct StreetCredBadge: Identifiable, Codable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let earnedAt: Date?

    var isEarned: Bool { earnedAt != nil }
}

// MARK: - Street Cred Score

struct StreetCredScore: Codable {
    let merchantId: UUID
    let totalScore: Int // 0-1000
    let level: StreetCredLevel
    let dimensions: [ScoreDimension]
    let badges: [StreetCredBadge]
    let streak: Int // dias consecutivos activo
    let lastCalculated: Date

    // Progreso al siguiente nivel (0.0 - 1.0)
    var progressToNextLevel: Double {
        guard let next = level.nextLevel else { return 1.0 }
        let range = Double(next.minScore - level.minScore)
        let progress = Double(totalScore - level.minScore)
        return min(max(progress / range, 0), 1)
    }

    var pointsToNextLevel: Int {
        guard let next = level.nextLevel else { return 0 }
        return max(next.minScore - totalScore, 0)
    }

    // Para Coppel Emprende - elegibilidad crediticia
    var isCreditEligible: Bool {
        level >= .plata
    }

    var creditTier: String {
        switch level {
        case .nuevo, .bronce: return "No elegible"
        case .plata: return "Microcrédito básico"
        case .oro: return "Crédito estándar"
        case .platino: return "Crédito preferencial"
        case .diamante: return "Crédito premium"
        }
    }

    var estimatedCreditAmount: String {
        switch level {
        case .nuevo, .bronce: return "-"
        case .plata: return "Hasta $5,000 MXN"
        case .oro: return "Hasta $15,000 MXN"
        case .platino: return "Hasta $30,000 MXN"
        case .diamante: return "Hasta $50,000 MXN"
        }
    }
}
