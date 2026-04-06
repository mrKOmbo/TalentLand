//
//  FUTURE_LIVE_ACTIVITIES.swift
//  Atenea
//
//  Ideas y ejemplos para expandir Live Activities en el futuro
//  ESTE ARCHIVO ES SOLO DE REFERENCIA
//

import Foundation
import ActivityKit
import SwiftUI

// MARK: - 1. Live Activity para Partidos en Vivo

/// Atributos para seguir un partido del Mundial en tiempo real
struct MatchLiveActivityAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        /// Marcador equipo local
        var homeScore: Int

        /// Marcador equipo visitante
        var awayScore: Int

        /// Minuto actual del partido
        var currentMinute: Int

        /// Período del partido
        var period: MatchPeriod

        /// Último evento importante
        var lastEvent: String  // ej: "⚽ GOL de Messi!"

        /// Timestamp de última actualización
        var lastUpdate: Date

        enum MatchPeriod: String, Codable {
            case notStarted = "Próximamente"
            case firstHalf = "1er Tiempo"
            case halfTime = "Medio Tiempo"
            case secondHalf = "2do Tiempo"
            case extraTime = "Tiempo Extra"
            case penalties = "Penales"
            case finished = "Finalizado"
        }
    }

    /// Nombre equipo local
    var homeTeam: String

    /// Bandera equipo local (emoji)
    var homeTeamFlag: String

    /// Nombre equipo visitante
    var awayTeam: String

    /// Bandera equipo visitante (emoji)
    var awayTeamFlag: String

    /// Fase del torneo
    var stage: String  // "Fase de Grupos", "Octavos", "Final", etc

    /// Estadio donde se juega
    var venueName: String

    /// Hora de inicio
    var kickoffTime: Date
}

// Ejemplo de uso:
/*
 func startMatchLiveActivity() {
     let attributes = MatchLiveActivityAttributes(
         homeTeam: "México",
         homeTeamFlag: "🇲🇽",
         awayTeam: "Argentina",
         awayTeamFlag: "🇦🇷",
         stage: "Final",
         venueName: "Estadio Azteca",
         kickoffTime: Date()
     )

     let initialState = MatchLiveActivityAttributes.ContentState(
         homeScore: 0,
         awayScore: 0,
         currentMinute: 0,
         period: .notStarted,
         lastEvent: "El partido comenzará pronto",
         lastUpdate: Date()
     )

     let activity = try? Activity<MatchLiveActivityAttributes>.request(
         attributes: attributes,
         content: .init(state: initialState, staleDate: nil),
         pushType: nil
     )
 }

 // Actualizar cuando hay gol
 func updateMatchScore(homeScore: Int, awayScore: Int, minute: Int, event: String) {
     let newState = MatchLiveActivityAttributes.ContentState(
         homeScore: homeScore,
         awayScore: awayScore,
         currentMinute: minute,
         period: .firstHalf,
         lastEvent: event,
         lastUpdate: Date()
     )

     await activity?.update(.init(state: newState, staleDate: nil))
 }
*/

// MARK: - 2. Live Activity para Sticker Desbloqueado

/// Atributos para celebrar cuando desbloqueas un sticker
struct StickerUnlockedActivityAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        /// Mensaje de celebración
        var message: String

        /// Progreso actual
        var currentProgress: Int  // ej: 5 de 16

        /// Total de stickers
        var totalStickers: Int

        /// Timestamp
        var unlockedAt: Date
    }

    /// Nombre del sticker desbloqueado
    var stickerName: String

    /// Número del sticker
    var stickerNumber: Int

    /// Tipo de sticker (rarity)
    var rarity: String  // "Común", "Rara", "Épica", "Legendaria"

    /// Color del sticker
    var colorHex: String
}

// Ejemplo de uso:
/*
 func showStickerUnlockedCelebration(sticker: Sticker) {
     let attributes = StickerUnlockedActivityAttributes(
         stickerName: "Estadio Azteca",
         stickerNumber: 3,
         rarity: "Épica",
         colorHex: "#34A853"
     )

     let state = StickerUnlockedActivityAttributes.ContentState(
         message: "¡Sticker desbloqueado!",
         currentProgress: 5,
         totalStickers: 16,
         unlockedAt: Date()
     )

     // Mostrar por 5 segundos y luego auto-dismiss
     let activity = try? Activity<StickerUnlockedActivityAttributes>.request(
         attributes: attributes,
         content: .init(state: state, staleDate: Date().addingTimeInterval(5)),
         pushType: nil
     )

     // Auto-finalizar después de 5 segundos
     Task {
         try? await Task.sleep(nanoseconds: 5_000_000_000)
         await activity?.end(nil, dismissalPolicy: .immediate)
     }
 }
*/

// MARK: - 3. Live Activity para Recordatorio de Partido

/// Atributos para recordatorio antes de un partido
struct MatchReminderActivityAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        /// Minutos restantes hasta el partido
        var minutesUntilKickoff: Int

        /// Mensaje
        var message: String

        /// Countdown activo
        var isCountingDown: Bool
    }

    /// Equipos que juegan
    var matchup: String  // "México vs Argentina"

    /// Estadio
    var venue: String

    /// Hora de inicio
    var kickoffTime: Date

    /// Puede ver en persona (está cerca del estadio)
    var canAttend: Bool
}

// MARK: - 4. Live Activity para Ruta Multi-Estadios

/// Para usuarios que visitan múltiples estadios en un día
struct MultiVenueRouteActivityAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        /// Estadio actual (índice)
        var currentVenueIndex: Int

        /// Distancia al siguiente
        var distanceToNext: Double

        /// Tiempo al siguiente
        var minutesToNext: Int

        /// Stickers colectados hoy
        var stickersToday: Int

        /// Último update
        var lastUpdate: Date
    }

    /// Lista de estadios a visitar
    var venueNames: [String]

    /// Total de estadios en la ruta
    var totalVenues: Int

    /// Distancia total del tour
    var totalDistance: Double

    /// Hora de inicio del tour
    var tourStartTime: Date
}

// Ejemplo Dynamic Island para Multi-Venue:
/*
 // Compact: "Estadio 2/5 • 3km → Azteca"
 // Expanded:
 ┌────────────────────────┐
 │  Tour Mundial 2026     │
 │  ───────────────────   │
 │  ✅ BBVA              │
 │  📍 Azteca (actual)   │
 │     3km • 10min        │
 │  ⭕ Akron              │
 │  ⭕ MetLife            │
 │                        │
 │  Stickers hoy: 2/5     │
 └────────────────────────┘
*/

// MARK: - 5. Live Activity para Modo Emergencia

/// Para mostrar que el modo emergencia está activo
struct EmergencyModeActivityAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        /// Tiempo activo
        var elapsedMinutes: Int

        /// Última ubicación conocida
        var lastKnownLocation: String

        /// Contactos notificados
        var contactsNotified: Int

        /// Mensaje de estado
        var statusMessage: String
    }

    /// Hora de activación
    var activatedAt: Date

    /// Tipo de emergencia
    var emergencyType: String  // "Manual", "Caída detectada", etc
}

// MARK: - Helpers para Futuros Live Activities

class FutureLiveActivitiesHelper {

    // MARK: - Match Live Activity

    static func startMatchActivity(
        homeTeam: String,
        awayTeam: String,
        venue: String
    ) {
        guard #available(iOS 16.1, *) else { return }

        // Implementación similar a NavigationLiveActivity
        // ...
    }

    static func updateMatchScore(
        homeScore: Int,
        awayScore: Int,
        minute: Int
    ) {
        // Update match score in real-time
        // ...
    }

    // MARK: - Sticker Celebration

    static func showStickerUnlocked(
        stickerName: String,
        rarity: String,
        progress: (current: Int, total: Int)
    ) {
        guard #available(iOS 16.1, *) else { return }

        // Mostrar celebración de 5 segundos
        // Auto-dismiss después
        // ...
    }

    // MARK: - Multi-Venue Tour

    static func startMultiVenueTour(venues: [WorldCupVenue]) {
        guard #available(iOS 16.1, *) else { return }

        // Iniciar tour con checklist
        // Actualizar cuando llegas a cada uno
        // ...
    }

    static func checkInAtVenue(index: Int) {
        // Marcar venue como visitado
        // Actualizar progreso
        // ...
    }
}

// MARK: - Integración Futura

/*
 ROADMAP DE LIVE ACTIVITIES:

 Fase 1 (COMPLETADO) ✅
 - Navegación en tiempo real con Dynamic Island

 Fase 2 (PRÓXIMO)
 - Partidos en vivo
   - Marcador en tiempo real
   - Notificaciones de goles
   - Dynamic Island interactivo

 Fase 3
 - Sticker celebrations
   - Pop-up cuando desbloqueas
   - Progreso del álbum
   - Confetti en Dynamic Island

 Fase 4
 - Tours multi-estadios
   - Checklist de venues
   - Progreso del día
   - Stickers colectados

 Fase 5
 - Modo emergencia
   - Countdown de tiempo activo
   - Ubicación compartida
   - Botón de desactivación rápida

 PRIORIDADES:
 1. Navegación ✅ (Implementado)
 2. Partidos en vivo 🚧 (Siguiente)
 3. Stickers celebration 📋 (Planificado)
 4. Multi-venue tours 💡 (Futuro)
 5. Emergencia mode 💡 (Futuro)
*/
