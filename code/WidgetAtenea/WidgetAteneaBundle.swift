//
//  NavigationActivityAttributes.swift
//  AteneaWidgets
//
//  Activity Attributes para Live Activities de navegación
//

import Foundation
import ActivityKit
import SwiftUI

/// Atributos para el Live Activity de navegación
struct NavigationActivityAttributes: ActivityAttributes {

    // MARK: - Content State (datos dinámicos que cambian)

    public struct ContentState: Codable, Hashable {
        /// Distancia restante en metros
        var distanceRemaining: Double

        /// Tiempo estimado de llegada en minutos
        var estimatedMinutes: Int

        /// Instrucción actual de navegación (ej: "Gira a la derecha en 200m")
        var currentInstruction: String

        /// Nombre de la calle actual
        var currentStreet: String

        /// Velocidad actual en km/h
        var currentSpeed: Double

        /// Timestamp de la última actualización
        var lastUpdate: Date

        /// Estado de la navegación
        var navigationState: NavigationState

        enum NavigationState: String, Codable {
            case active = "En ruta"
            case paused = "Pausado"
            case recalculating = "Recalculando"
            case arrived = "Has llegado"
        }
    }

    // MARK: - Static Data (datos que no cambian durante el Live Activity)

    /// Nombre del destino
    var destinationName: String

    /// Ciudad del destino
    var destinationCity: String

    /// Distancia total del viaje en kilómetros
    var totalDistance: Double

    /// Hora de inicio de la navegación
    var startTime: Date

    /// Color principal del venue (en formato hex)
    var venueColorHex: String
}
