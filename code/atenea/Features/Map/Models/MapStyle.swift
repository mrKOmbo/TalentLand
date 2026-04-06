//
//  MapStyle.swift
//  atenea
//
//  Enum para los diferentes estilos de mapa de Mapbox
//

import Foundation
import MapboxMaps

enum MapStyle: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case streets = "Streets"
    case outdoors = "Outdoors"
    case light = "Light"
    case dark = "Dark"
    case satellite = "Satellite"
    case satelliteStreets = "Satellite Streets"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard:
            return LocalizedString("mapStyle.standard")
        case .streets:
            return LocalizedString("mapStyle.streets")
        case .outdoors:
            return LocalizedString("mapStyle.outdoors")
        case .light:
            return LocalizedString("mapStyle.light")
        case .dark:
            return LocalizedString("mapStyle.dark")
        case .satellite:
            return LocalizedString("mapStyle.satellite")
        case .satelliteStreets:
            return LocalizedString("mapStyle.satelliteStreets")
        }
    }

    var icon: String {
        switch self {
        case .standard:
            return "map.fill"
        case .streets:
            return "building.2.fill"
        case .outdoors:
            return "leaf.fill"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .satellite:
            return "globe.americas.fill"
        case .satelliteStreets:
            return "map.circle.fill"
        }
    }

    var styleURI: StyleURI {
        switch self {
        case .standard:
            return .standard
        case .streets:
            return .streets
        case .outdoors:
            return .outdoors
        case .light:
            return .light
        case .dark:
            return .dark
        case .satellite:
            return .satellite
        case .satelliteStreets:
            return .satelliteStreets
        }
    }
}
