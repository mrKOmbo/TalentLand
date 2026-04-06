//
//  SpotlightManager.swift
//  Atenea
//
//  Manager para indexar contenido de la app en Spotlight
//  Permite que los usuarios busquen estadios, stickers y más desde la búsqueda de iOS
//

import Foundation
import CoreSpotlight
import MobileCoreServices
import UniformTypeIdentifiers
import CoreLocation

/// Manager para gestionar la indexación de contenido en Spotlight
class SpotlightManager {
    static let shared = SpotlightManager()

    private let searchableIndex = CSSearchableIndex.default()

    private init() {}

    // MARK: - Public Methods

    /// Indexa todos los estadios del Mundial 2026 en Spotlight
    func indexAllVenues() {
        let venues = WorldCupVenue.allVenues
        var items: [CSSearchableItem] = []

        for venue in venues {
            if let item = createSearchableItem(for: venue) {
                items.append(item)
            }
        }

        searchableIndex.indexSearchableItems(items) { error in
            if let error = error {
                print("❌ [SPOTLIGHT] Error indexando venues: \(error)")
            } else {
                print("✅ [SPOTLIGHT] \(items.count) venues indexados")
            }
        }
    }

    /// Indexa el progreso de la colección de stickers
    func indexStickerCollection(collectedCount: Int, totalCount: Int) {
        let item = createStickerCollectionItem(collected: collectedCount, total: totalCount)

        searchableIndex.indexSearchableItems([item]) { error in
            if let error = error {
                print("❌ [SPOTLIGHT] Error indexando colección: \(error)")
            } else {
                print("✅ [SPOTLIGHT] Colección de stickers indexada")
            }
        }
    }

    /// Elimina un venue específico del índice
    func removeVenue(id: String) {
        searchableIndex.deleteSearchableItems(withIdentifiers: ["venue-\(id)"]) { error in
            if let error = error {
                print("❌ [SPOTLIGHT] Error eliminando venue: \(error)")
            }
        }
    }

    /// Elimina todo el contenido indexado de Atenea
    func clearAllIndexedContent() {
        searchableIndex.deleteAllSearchableItems { error in
            if let error = error {
                print("❌ [SPOTLIGHT] Error limpiando índice: \(error)")
            } else {
                print("✅ [SPOTLIGHT] Índice limpiado")
            }
        }
    }

    // MARK: - Private Methods

    /// Crea un CSSearchableItem para un venue
    private func createSearchableItem(for venue: WorldCupVenue) -> CSSearchableItem? {
        // Attributes set
        let attributeSet = CSSearchableItemAttributeSet(contentType: UTType.content)

        // Título
        attributeSet.title = venue.name

        // Descripción
        attributeSet.contentDescription = """
        \(venue.city), \(venue.country) • \(venue.capacity)
        Inauguración: \(venue.inauguration)
        Mundial 2026: \(venue.matches.count) partidos
        """

        // Keywords para búsqueda
        attributeSet.keywords = [
            venue.name,
            venue.city,
            venue.country,
            "estadio",
            "stadium",
            "mundial",
            "world cup",
            "2026",
            "fútbol",
            "football",
            "soccer"
        ]

        // Información adicional
        attributeSet.rating = NSNumber(value: 5) // Rating ficticio para darle relevancia
        attributeSet.contentType = "Estadio Mundial 2026"
        attributeSet.contentTypeTree = [
            "Estadio",
            "Mundial 2026",
            venue.country
        ]

        // Thumbnail (si tienes imagen)
        // attributeSet.thumbnailData = venue.imageData

        // Ubicación geográfica (mejora resultados locales)
        attributeSet.latitude = NSNumber(value: venue.coordinate.latitude)
        attributeSet.longitude = NSNumber(value: venue.coordinate.longitude)
        attributeSet.namedLocation = "\(venue.city), \(venue.country)"

        // Crear el item
        let uniqueIdentifier = "venue-\(venue.id.uuidString)"
        let domainIdentifier = "com.atenea.venues"

        let item = CSSearchableItem(
            uniqueIdentifier: uniqueIdentifier,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )

        // Expiración (opcional - renovar cada 30 días)
        item.expirationDate = Date().addingTimeInterval(30 * 24 * 60 * 60)

        return item
    }

    /// Crea un item para la colección de stickers
    private func createStickerCollectionItem(collected: Int, total: Int) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: UTType.content)

        let percentage = total > 0 ? Int((Double(collected) / Double(total)) * 100) : 0

        attributeSet.title = "Mi Álbum de Stickers"
        attributeSet.contentDescription = """
        Progreso: \(collected)/\(total) stickers (\(percentage)%)
        \(total - collected) stickers restantes
        Mundial 2026 - Colección de Estadios
        """

        attributeSet.keywords = [
            "album",
            "stickers",
            "colección",
            "panini",
            "mundial",
            "progreso",
            "mi album"
        ]

        let item = CSSearchableItem(
            uniqueIdentifier: "sticker-collection",
            domainIdentifier: "com.atenea.collection",
            attributeSet: attributeSet
        )

        return item
    }
}

// MARK: - Deep Link Handler Extension

extension SpotlightManager {

    /// Maneja la activación desde un resultado de Spotlight
    static func handleSpotlightActivity(_ userActivity: NSUserActivity) -> String? {
        // Verificar que es de Spotlight
        guard userActivity.activityType == CSSearchableItemActionType else {
            return nil
        }

        // Obtener el identificador único
        guard let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return nil
        }

        print("🔍 [SPOTLIGHT] Usuario tocó resultado: \(uniqueIdentifier)")

        return uniqueIdentifier
    }

    /// Parsea el identificador y retorna el tipo de contenido
    static func parseIdentifier(_ identifier: String) -> (type: String, id: String)? {
        let components = identifier.split(separator: "-")
        guard components.count >= 2 else { return nil }

        let type = String(components[0])
        let id = components.dropFirst().joined(separator: "-")

        return (type, id)
    }
}

// MARK: - Convenience Methods

extension SpotlightManager {

    /// Actualiza el índice de Spotlight con el contenido más reciente
    func updateSpotlightIndex() {
        print("🔄 [SPOTLIGHT] Actualizando índice...")

        // Indexar venues
        indexAllVenues()

        // Indexar colección de stickers
        let collectedCount = UserDefaults.standard.integer(forKey: "totalCollectedStickers")
        indexStickerCollection(collectedCount: collectedCount, totalCount: 672)

        print("✅ [SPOTLIGHT] Índice actualizado")
    }

    /// Verifica si Spotlight está disponible
    var isSpotlightAvailable: Bool {
        return CSSearchableIndex.isIndexingAvailable()
    }
}
