//
//  VenueEntity.swift
//  Atenea
//
//  App Intent Entity para WorldCupVenue
//  Permite que Siri y Shortcuts trabajen con venues
//

import Foundation
import AppIntents
import CoreLocation

/// Entity que representa un venue del Mundial 2026 para App Intents
struct VenueEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Estadio"

    static var defaultQuery = VenueEntityQuery()

    // Registrar el query de strings
    @available(iOS 16.0, *)
    static var stringQuery: some EntityStringQuery = VenueEntityStringQuery()

    // Identificador único
    let id: String

    // Propiedades del venue
    let name: String
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double
    let capacity: String

    // Representación para mostrar en Siri/Shortcuts
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(city), \(country)",
            image: DisplayRepresentation.Image(systemName: "building.2.fill")
        )
    }

    /// Convierte un WorldCupVenue en VenueEntity
    static func from(venue: WorldCupVenue) -> VenueEntity {
        return VenueEntity(
            id: venue.id.uuidString,
            name: venue.name,
            city: venue.city,
            country: venue.country,
            latitude: venue.coordinate.latitude,
            longitude: venue.coordinate.longitude,
            capacity: venue.capacity
        )
    }

    /// Encuentra el venue original correspondiente
    func toWorldCupVenue() -> WorldCupVenue? {
        return WorldCupVenue.allVenues.first { $0.id.uuidString == self.id }
    }
}

/// Query para buscar y filtrar venues
struct VenueEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [VenueEntity] {
        return WorldCupVenue.allVenues
            .filter { identifiers.contains($0.id.uuidString) }
            .map { VenueEntity.from(venue: $0) }
    }

    func suggestedEntities() async throws -> [VenueEntity] {
        // Sugerir los 5 venues más icónicos
        let iconicVenues = [
            "Estadio Azteca",
            "MetLife Stadium",
            "SoFi Stadium",
            "Mercedes-Benz Stadium",
            "AT&T Stadium"
        ]

        return WorldCupVenue.allVenues
            .filter { iconicVenues.contains($0.name) }
            .map { VenueEntity.from(venue: $0) }
    }

    func defaultResult() async -> VenueEntity? {
        // Por defecto, el Estadio Azteca (sede inaugural)
        guard let azteca = WorldCupVenue.allVenues.first(where: { $0.name == "Estadio Azteca" }) else {
            return nil
        }
        return VenueEntity.from(venue: azteca)
    }
}

/// Query para buscar venues por texto
struct VenueEntityStringQuery: EntityStringQuery {
    static var findIntentDescription: IntentDescription? {
        IntentDescription("Busca estadios del Mundial 2026 por nombre o ciudad")
    }

    func entities(matching string: String) async throws -> [VenueEntity] {
        let lowercased = string.lowercased()

        return WorldCupVenue.allVenues
            .filter {
                $0.name.lowercased().contains(lowercased) ||
                $0.city.lowercased().contains(lowercased) ||
                $0.country.lowercased().contains(lowercased)
            }
            .map { VenueEntity.from(venue: $0) }
    }

    func suggestedEntities() async throws -> [VenueEntity] {
        // Sugerir los 5 venues más icónicos
        let iconicVenues = [
            "Estadio Azteca",
            "MetLife Stadium",
            "SoFi Stadium",
            "Mercedes-Benz Stadium",
            "AT&T Stadium"
        ]

        return WorldCupVenue.allVenues
            .filter { iconicVenues.contains($0.name) }
            .map { VenueEntity.from(venue: $0) }
    }

    func entities(for identifiers: [VenueEntity.ID]) async throws -> [VenueEntity] {
        return WorldCupVenue.allVenues
            .filter { identifiers.contains($0.id.uuidString) }
            .map { VenueEntity.from(venue: $0) }
    }
}
