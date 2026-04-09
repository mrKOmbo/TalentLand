//
//  ContextEngine.swift
//  atenea
//
//  Motor local de inteligencia contextual para el Home.
//  Evalúa señales (hora, merchants, partido, demanda) y genera
//  insights priorizados sin llamadas de red.
//

import Foundation
import CoreLocation
internal import Combine

// MARK: - Context Insight

struct ContextInsight: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: String
    let action: ContextAction

    static func == (lhs: ContextInsight, rhs: ContextInsight) -> Bool {
        lhs.title == rhs.title && lhs.subtitle == rhs.subtitle
    }
}

enum ContextAction {
    case openMap
    case openChat(prefill: String)
    case openMerchant(name: String)
    case openPrediction
}

// MARK: - Smart Chip

struct SmartChip: Identifiable {
    let id = UUID()
    let emoji: String
    let label: String
    let query: String
}

// MARK: - Context Engine

@MainActor
class ContextEngine: ObservableObject {

    @Published var currentInsight: ContextInsight?
    @Published var chips: [SmartChip] = []

    private let merchantManager = MerchantManager.shared
    // private let predictionEngine = PredictionEngine.shared
    // private let demandManager = DemandZoneManager.shared

    private var cycleIndex = 0
    private var allInsights: [ContextInsight] = []

    // MARK: - Evaluar contexto

    func evaluate(userLat: Double = mockUserLatitude, userLon: Double = mockUserLongitude) {
        allInsights = []

        /* // 1. Partido próximo
        if let matchInsight = evaluateMatch() {
            allInsights.append(matchInsight)
        }
        */

        // 2. Merchants cercanos activos
        if let merchantInsight = evaluateNearbyMerchants(lat: userLat, lon: userLon) {
            allInsights.append(merchantInsight)
        }

        /* // 3. Zona de demanda caliente
        if let demandInsight = evaluateDemandZones() {
            allInsights.append(demandInsight)
        }
        */

        // 4. Hora del día (siempre genera algo)
        allInsights.append(evaluateTimeOfDay())

        // Mostrar el primero
        cycleIndex = 0
        currentInsight = allInsights.first

        // Generar chips
        chips = generateChips(lat: userLat, lon: userLon)
    }

    // MARK: - Ciclar entre insights

    func nextInsight() {
        guard !allInsights.isEmpty else { return }
        cycleIndex = (cycleIndex + 1) % allInsights.count
        currentInsight = allInsights[cycleIndex]
    }

    // MARK: - Evaluadores de señales

    /* private func evaluateMatch() -> ContextInsight? {
        guard let next = predictionEngine.nextMatch else { return nil }
        let teams = next.match.teams
        let venue = next.venue.name
        let isMexico = next.match.isMexicoPlaying

        let title = isMexico
            ? "¡Juega México! \(teams)"
            : "\(teams) pronto"
        let subtitle = "Zona caliente cerca de \(venue) — los taqueros ya se posicionan"

        return ContextInsight(
            icon: "soccerball",
            title: title,
            subtitle: subtitle,
            accentColor: "#0ABF4F",
            action: .openPrediction
        )
    }
    */

    private func evaluateNearbyMerchants(lat: Double, lon: Double) -> ContextInsight? {
        let nearby = merchantManager.nearbyMerchantsList(fromLatitude: lat, longitude: lon)
        let activos = nearby.filter { $0.isActive }
        guard let closest = activos.first else { return nil }

        let count = activos.count
        let extra = count > 1 ? " y \(count - 1) más" : ""

        return ContextInsight(
            icon: "mappin.and.ellipse",
            title: "\(closest.emoji) \(closest.name) a \(closest.distance)",
            subtitle: "Abierto ahora\(extra) cerca de ti",
            accentColor: "#1C42E8",
            action: .openMerchant(name: closest.name)
        )
    }

    /* private func evaluateDemandZones() -> ContextInsight? {
        let topZones = demandManager.topZones(limit: 1)
        guard let zone = topZones.first, zone.intensity == .veryHigh || zone.intensity == .high else {
            return nil
        }

        let categoryEmoji = zone.topCategory?.emoji ?? "🔥"
        let categoryName = zone.topCategory?.displayName ?? "productos"

        return ContextInsight(
            icon: "flame.fill",
            title: "\(categoryEmoji) Alta demanda de \(categoryName)",
            subtitle: "Zona caliente activa — \(zone.demandScore) búsquedas recientes",
            accentColor: "#FF6B35",
            action: .openMap
        )
    }
    */

    private func evaluateTimeOfDay() -> ContextInsight {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 6..<10:
            return ContextInsight(
                icon: "sunrise.fill",
                title: "Buenos días — ¿tamales para empezar?",
                subtitle: "Los tamaleros madrugadores ya están activos",
                accentColor: "#FFAE43",
                action: .openChat(prefill: "¿Dónde hay tamales cerca de mí?")
            )
        case 10..<14:
            return ContextInsight(
                icon: "fork.knife",
                title: "Se acerca la hora de comer",
                subtitle: "Encuentra tacos, tortas y antojitos cerca",
                accentColor: "#FF6B35",
                action: .openChat(prefill: "¿Qué hay de comer por aquí?")
            )
        case 14..<18:
            let nearby = merchantManager.nearbyMerchantsList(fromLatitude: mockUserLatitude, longitude: mockUserLongitude)
            let count = nearby.filter { $0.isActive }.count
            return ContextInsight(
                icon: "cup.and.saucer.fill",
                title: "Tarde de antojitos",
                subtitle: "\(count) vendedores activos cerca — elotes, helados, jugos",
                accentColor: "#7D42FF",
                action: .openMap
            )
        case 18..<22:
            return ContextInsight(
                icon: "moon.stars.fill",
                title: "Antojitos nocturnos",
                subtitle: "Tacos al pastor, esquites y más te esperan",
                accentColor: "#1C42E8",
                action: .openChat(prefill: "¿Dónde hay tacos abiertos de noche?")
            )
        default:
            return ContextInsight(
                icon: "sparkles",
                title: "Explora comercio local",
                subtitle: "Descubre vendedores y productos únicos de CDMX",
                accentColor: "#1C42E8",
                action: .openMap
            )
        }
    }

    // MARK: - Smart Chips

    private func generateChips(lat: Double, lon: Double) -> [SmartChip] {
        var result: [SmartChip] = []

        // Chip basado en hora
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 11 {
            result.append(SmartChip(emoji: "🫔", label: LocalizedString("home.chip.breakfast"), query: "¿Dónde desayuno por aquí?"))
        } else if hour < 16 {
            result.append(SmartChip(emoji: "🌮", label: LocalizedString("home.chip.tacos"), query: "¿Dónde hay tacos cerca de mí?"))
        } else {
            result.append(SmartChip(emoji: "🌙", label: LocalizedString("home.chip.night"), query: "¿Qué antojitos hay abiertos de noche?"))
        }

        /* // Chip de partido (si hay próximo)
        if let next = predictionEngine.nextMatch {
            let teams = next.match.teams
            result.append(SmartChip(emoji: "⚽", label: LocalizedString("home.chip.match"), query: "¿Dónde comer antes del partido \(teams)?"))
        }

        // Chip de zona caliente
        if let topZone = demandManager.topZones(limit: 1).first, topZone.intensity == .high || topZone.intensity == .veryHigh {
            result.append(SmartChip(emoji: "🔥", label: LocalizedString("home.chip.hotZone"), query: "¿Qué zona tiene más demanda ahora?"))
        }
        */

        // Chip de merchant cercano real
        let nearby = merchantManager.nearbyMerchantsList(fromLatitude: lat, longitude: lon)
        if let first = nearby.first(where: { $0.isActive }) {
            result.append(SmartChip(emoji: first.emoji, label: first.name, query: "¿Qué vende \(first.name)?"))
        }

        return Array(result.prefix(4))
    }
}
