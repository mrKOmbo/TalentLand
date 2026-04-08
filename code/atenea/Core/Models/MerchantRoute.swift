//
//  MerchantRoute.swift
//  Atenea
//
//  Model for merchant routes with multiple waypoints
//

import Foundation
import CoreLocation

// MARK: - Route Waypoint
struct RouteWaypoint: Codable, Identifiable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let order: Int
    let name: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: UUID = UUID(),
        coordinate: CLLocationCoordinate2D,
        order: Int,
        name: String? = nil
    ) {
        self.id = id
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.order = order
        self.name = name
    }
}

// MARK: - Merchant Route
struct MerchantRoute: Codable, Identifiable {
    let id: UUID
    let merchantId: UUID
    let waypoints: [RouteWaypoint]
    let routeGeometry: String? // Encoded polyline from Mapbox
    let estimatedDuration: Double? // In seconds
    let estimatedDistance: Double? // In meters
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        merchantId: UUID,
        waypoints: [RouteWaypoint],
        routeGeometry: String? = nil,
        estimatedDuration: Double? = nil,
        estimatedDistance: Double? = nil,
        isActive: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.merchantId = merchantId
        self.waypoints = waypoints
        self.routeGeometry = routeGeometry
        self.estimatedDuration = estimatedDuration
        self.estimatedDistance = estimatedDistance
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var sortedWaypoints: [RouteWaypoint] {
        waypoints.sorted { $0.order < $1.order }
    }

    var coordinatesString: String {
        sortedWaypoints
            .map { "\($0.longitude),\($0.latitude)" }
            .joined(separator: ";")
    }
}
