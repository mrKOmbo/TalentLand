/*
//
//  PredictionEngine.swift
//  atenea
//
//  Motor de predicción de demanda "Atenea Predict"
//  Algoritmo determinístico multiplicativo:
//  demanda = base × evento × temporal × clima × distancia
//
//  Basado en datos empíricos de FIFA 2014/2018, NFL, y estudios de flujo peatonal
//

import Foundation
import CoreLocation
internal import Combine

class PredictionEngine: ObservableObject {
    static let shared = PredictionEngine()

    @Published var currentPrediction: MatchPrediction?
    @Published var nextMatch: (match: WorldCupMatch, venue: WorldCupVenue)?

    private init() {
        DispatchQueue.main.async { [self] in
            findNextMatch()
        }
    }

    // MARK: - Generar Predicción

    func predict(for match: WorldCupMatch, at venue: WorldCupVenue, weather: WeatherCondition = .sunny) -> MatchPrediction {
        let kickoff = parseMatchDate(match)

        // Calcular tráfico base: capacidad × ocupación estimada
        let capacityNum = parseCapacity(venue.capacity)
        let occupancy = match.stageMultiplier * (match.isMexicoPlaying ? 1.0 : 0.85)
        let baseTraffic = Int(Double(capacityNum) * min(occupancy, 1.0))

        // Generar zonas de predicción alrededor del estadio
        let zones = generatePredictedZones(
            venue: venue,
            match: match,
            weather: weather,
            baseTraffic: baseTraffic
        )

        // Top categorías según clima y hora
        let topCats = rankCategories(weather: weather, kickoff: kickoff)

        // Ventana de pico
        let peakWindow: String
        let hour = Calendar.current.component(.hour, from: kickoff)
        if hour < 14 {
            peakWindow = "10:00 - 12:00 (llegada matutina)"
        } else if hour < 18 {
            peakWindow = "\(hour - 2):00 - \(hour):00 (pre-partido)"
        } else {
            peakWindow = "\(hour - 2):00 - \(hour + 1):00 (tarde-noche)"
        }

        let prediction = MatchPrediction(
            match: match,
            venue: venue,
            kickoffDate: kickoff,
            zones: zones,
            peakDemandWindow: peakWindow,
            estimatedFootTraffic: baseTraffic,
            topCategories: topCats
        )

        currentPrediction = prediction
        return prediction
    }

    // MARK: - Predecir para el siguiente partido

    func predictNextMatch(weather: WeatherCondition = .sunny) -> MatchPrediction? {
        guard let next = nextMatch else { return nil }
        return predict(for: next.match, at: next.venue, weather: weather)
    }

    // MARK: - Recomendación para un merchant

    func recommendPosition(
        for category: MerchantCategory,
        match: WorldCupMatch,
        venue: WorldCupVenue,
        weather: WeatherCondition = .sunny
    ) -> (zone: PredictedZone, reason: String, arriveBy: String)? {
        let prediction = predict(for: match, at: venue, weather: weather)

        // Filtrar zonas que recomienden esta categoría, ordenar por score
        let relevantZones = prediction.zones
            .filter { $0.recommendedProducts.contains(category) }
            .sorted { $0.demandScore > $1.demandScore }

        guard let bestZone = relevantZones.first else {
            // Si no hay zona específica, usar la de mayor score general
            guard let fallback = prediction.zones.first else { return nil }
            return (fallback, "Zona con mayor flujo general", "2h antes del partido")
        }

        let kickoff = parseMatchDate(match)
        let hour = Calendar.current.component(.hour, from: kickoff)
        let arriveBy = "\(max(hour - 3, 6)):00"

        let weatherBonus = weather.multiplier(for: category)
        var reason = "Zona óptima para \(category.displayName)"
        if weatherBonus > 1.5 {
            reason += " · \(weather.emoji) el clima favorece tu producto x\(String(format: "%.1f", weatherBonus))"
        }
        if match.isMexicoPlaying {
            reason += " · Juega México: demanda +30%"
        }

        return (bestZone, reason, arriveBy)
    }

    // MARK: - Zonas de Predicción

    private func generatePredictedZones(
        venue: WorldCupVenue,
        match: WorldCupMatch,
        weather: WeatherCondition,
        baseTraffic: Int
    ) -> [PredictedZone] {
        let stadiumCoord = venue.coordinate

        // Zonas clave alrededor del estadio (genéricas, aplicables a cualquier sede)
        let zoneTemplates: [(name: String, latOffset: Double, lonOffset: Double, baseWeight: Double, peakTime: String)] = [
            ("Entrada Principal Norte", 0.003, 0.0, 1.0, "2h antes"),
            ("Zona Metro / Transporte", 0.005, 0.002, 0.9, "3h antes"),
            ("Corredor Peatonal Este", 0.001, 0.004, 0.85, "2h antes"),
            ("Estacionamiento Sur", -0.003, 0.001, 0.7, "1h antes"),
            ("Dispersión Oeste", -0.001, -0.004, 0.6, "1h después"),
            ("Fan Zone / Explanada", 0.002, -0.002, 0.95, "3h antes"),
            ("Zona Residencial Cercana", -0.005, 0.003, 0.5, "1h después"),
            ("Corredor Comercial", 0.004, -0.003, 0.75, "2h antes"),
        ]

        // Para Estadio Azteca agregar zonas específicas
        let isAzteca = venue.name.lowercased().contains("azteca")
        let extraZones: [(name: String, latOffset: Double, lonOffset: Double, baseWeight: Double, peakTime: String)]
        if isAzteca {
            extraZones = [
                ("Calzada de Tlalpan", 0.006, 0.001, 0.95, "2h antes"),
                ("Metro Estadio Azteca", 0.004, 0.003, 0.9, "3h antes"),
                ("Perisur / Centro Comercial", 0.008, -0.005, 0.5, "3h antes"),
                ("Salida Periférico", -0.004, -0.003, 0.55, "30min después"),
            ]
        } else {
            extraZones = []
        }

        let allTemplates = zoneTemplates + extraZones

        return allTemplates.map { template in
            let coord = CLLocationCoordinate2D(
                latitude: stadiumCoord.latitude + template.latOffset,
                longitude: stadiumCoord.longitude + template.lonOffset
            )

            let distance = CLLocation(latitude: stadiumCoord.latitude, longitude: stadiumCoord.longitude)
                .distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))

            // Score = base × peso_zona × evento × clima_promedio × decaimiento_distancia
            let distanceDecay = exp(-distance / 800.0) // radio de 800m
            let eventMult = match.stageMultiplier * (match.isMexicoPlaying ? 1.3 : 1.0)
            let climateMult = averageClimateMultiplier(weather: weather)

            let rawScore = template.baseWeight * eventMult * climateMult * distanceDecay * 100.0
            let score = min(max(rawScore, 0), 100)

            // Productos recomendados según posición y clima
            let products = recommendedProducts(distance: distance, weather: weather, template: template.name)

            let geohash = Geohash.encode(
                latitude: coord.latitude,
                longitude: coord.longitude,
                precision: GeohashChannelLevel.neighborhood.precision
            )

            let intensity: DemandIntensity
            switch score {
            case 70...: intensity = .veryHigh
            case 50..<70: intensity = .high
            case 30..<50: intensity = .medium
            default: intensity = .low
            }

            return PredictedZone(
                name: template.name,
                coordinate: coord,
                geohash: geohash,
                demandScore: score,
                intensity: intensity,
                peakTime: template.peakTime,
                recommendedProducts: products,
                distanceFromStadium: distance
            )
        }
        .sorted { $0.demandScore > $1.demandScore }
    }

    // MARK: - Helpers

    private func recommendedProducts(distance: Double, weather: WeatherCondition, template: String) -> [MerchantCategory] {
        var products: [MerchantCategory] = []

        // Cerca del estadio: snacks rápidos y bebidas
        if distance < 500 {
            products.append(contentsOf: [.bebidas, .elotes, .frutas])
            if weather == .hot || weather == .sunny {
                products.append(contentsOf: [.helados, .jugos])
            }
        }

        // Distancia media: comida completa
        if distance >= 300 && distance < 1000 {
            products.append(contentsOf: [.tacos, .antojitos])
            if weather == .cool || weather == .lightRain {
                products.append(.tamales)
            }
        }

        // Zonas de dispersión post-partido: todo tipo de comida
        if template.lowercased().contains("dispersión") || template.lowercased().contains("salida") {
            products.append(contentsOf: [.tacos, .tamales, .antojitos, .bebidas])
        }

        // Fan Zone: de todo
        if template.lowercased().contains("fan") || template.lowercased().contains("explanada") {
            products = MerchantCategory.allCases.filter { $0 != .otro }
        }

        return Array(Set(products))
    }

    private func rankCategories(weather: WeatherCondition, kickoff: Date) -> [(MerchantCategory, Double)] {
        let hour = Calendar.current.component(.hour, from: kickoff)
        let isNight = hour >= 19 || hour <= 6

        return MerchantCategory.allCases
            .filter { $0 != .otro }
            .map { cat in
                var mult = weather.multiplier(for: cat)
                // Bonus nocturno para comida caliente
                if isNight && (cat == .tacos || cat == .tamales || cat == .antojitos) {
                    mult *= 1.3
                }
                // Bonus diurno para bebidas frías
                if !isNight && (cat == .bebidas || cat == .jugos || cat == .helados) {
                    mult *= 1.2
                }
                return (cat, mult)
            }
            .sorted { $0.1 > $1.1 }
    }

    private func averageClimateMultiplier(weather: WeatherCondition) -> Double {
        let allCats = MerchantCategory.allCases.filter { $0 != .otro }
        let total = allCats.reduce(0.0) { $0 + weather.multiplier(for: $1) }
        return total / Double(allCats.count)
    }

    private func parseCapacity(_ capacity: String) -> Int {
        let digits = capacity.filter { $0.isNumber || $0 == "," }
            .replacingOccurrences(of: ",", with: "")
        return Int(digits) ?? 80000
    }

    private func parseMatchDate(_ match: WorldCupMatch) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")

        // Intentar parsear la fecha del match
        for format in ["d 'de' MMMM, yyyy", "MMMM d, yyyy", "d/MM/yyyy"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: match.date) {
                return date
            }
        }

        // Fallback: próximo partido a las 4pm
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 16
        return Calendar.current.date(from: components) ?? Date()
    }

    func findNextMatch() {
        let now = Date()
        var closest: (match: WorldCupMatch, venue: WorldCupVenue, date: Date)?

        for venue in WorldCupVenue.allVenues {
            for match in venue.matches {
                let matchDate = parseMatchDate(match)
                if matchDate > now {
                    if closest == nil || matchDate < closest!.date {
                        closest = (match, venue, matchDate)
                    }
                }
            }
        }

        // Si no hay partidos futuros, usar el primer partido del Azteca como demo
        if closest == nil {
            if let azteca = WorldCupVenue.allVenues.first(where: { $0.name.contains("Azteca") }),
               let firstMatch = azteca.matches.first {
                nextMatch = (firstMatch, azteca)
                return
            }
        }

        if let c = closest {
            nextMatch = (c.match, c.venue)
        }
    }
}
*/
