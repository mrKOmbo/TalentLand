//
//  UltraThinkRecommendation.swift
//  Atenea
//
//  Modelo para recomendaciones contextuales avanzadas generadas por Claude
//  Genera 8-12 recomendaciones variadas de diferentes categorías
//

import Foundation
import MapKit

struct UltraThinkRecommendation: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let category: RecommendationCategory
    let location: LocationInfo?
    let contextualReason: String  // Por qué Claude lo recomienda basado en contexto
    let priority: Int  // 1-5, siendo 5 la más alta
    let suggestedTime: String?  // Horario sugerido (ej: "Por la mañana", "18:00-20:00")
    let tags: [String]
    let estimatedDuration: String?  // Duración estimada (ej: "2 horas")
    let weatherRelevance: String?  // Si aplica al clima actual

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: RecommendationCategory,
        location: LocationInfo? = nil,
        contextualReason: String,
        priority: Int = 3,
        suggestedTime: String? = nil,
        tags: [String] = [],
        estimatedDuration: String? = nil,
        weatherRelevance: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.location = location
        self.contextualReason = contextualReason
        self.priority = priority
        self.suggestedTime = suggestedTime
        self.tags = tags
        self.estimatedDuration = estimatedDuration
        self.weatherRelevance = weatherRelevance
    }

    static func == (lhs: UltraThinkRecommendation, rhs: UltraThinkRecommendation) -> Bool {
        lhs.id == rhs.id
    }
}

enum RecommendationCategory: String, Codable, CaseIterable {
    case restaurant = "Restaurante"
    case cafe = "Café"
    case activity = "Actividad"
    case worldCup = "Mundial 2026"
    case culture = "Cultura"
    case entertainment = "Entretenimiento"
    case nature = "Naturaleza"
    case shopping = "Compras"
    case nightlife = "Vida Nocturna"
    case sports = "Deportes"

    var emoji: String {
        switch self {
        case .restaurant: return "🍽️"
        case .cafe: return "☕"
        case .activity: return "🎯"
        case .worldCup: return "⚽"
        case .culture: return "🏛️"
        case .entertainment: return "🎭"
        case .nature: return "🌳"
        case .shopping: return "🛍️"
        case .nightlife: return "🌃"
        case .sports: return "🏃"
        }
    }

    var color: String {
        switch self {
        case .restaurant: return "orange"
        case .cafe: return "brown"
        case .activity: return "blue"
        case .worldCup: return "green"
        case .culture: return "purple"
        case .entertainment: return "pink"
        case .nature: return "green"
        case .shopping: return "red"
        case .nightlife: return "indigo"
        case .sports: return "cyan"
        }
    }
}

struct LocationInfo: Codable, Equatable {
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static func == (lhs: LocationInfo, rhs: LocationInfo) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// Estructura para la respuesta completa de UltraThink
struct UltraThinkAnalysis: Codable {
    let contextSummary: String  // Resumen del contexto analizado
    let recommendations: [UltraThinkRecommendation]
    let timestamp: Date
    let userLocation: LocationInfo?
    let weatherContext: String?
    let timeContext: String  // "mañana", "tarde", "noche"

    init(
        contextSummary: String,
        recommendations: [UltraThinkRecommendation],
        timestamp: Date = Date(),
        userLocation: LocationInfo? = nil,
        weatherContext: String? = nil,
        timeContext: String
    ) {
        self.contextSummary = contextSummary
        self.recommendations = recommendations
        self.timestamp = timestamp
        self.userLocation = userLocation
        self.weatherContext = weatherContext
        self.timeContext = timeContext
    }
}
