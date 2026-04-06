//
//  FindNearbyVenueIntent.swift
//  Atenea
//
//  Intent to find the nearest stadium
//  Usage: "Hey Siri, find the nearest stadium in Atenea"
//         "Hey Siri, what stadium is near me in Atenea?"
//

import Foundation
import AppIntents
import CoreLocation

/// Intent to find and show the nearest venue
struct FindNearbyVenueIntent: AppIntent {
    static var title: LocalizedStringResource = "Find Nearby Stadium"
    static var description = IntentDescription("Find the 2026 World Cup stadium nearest to your location")

    static var openAppWhenRun: Bool = false // Can respond without opening the app

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Request current location (requires location permissions)
        guard let userLocation = await getCurrentLocation() else {
            return .result(
                dialog: IntentDialog(stringLiteral: "Could not get your location. Please verify that Atenea has location permissions enabled.")
            )
        }

        // Find the nearest venue
        let nearestVenue = findNearestVenue(to: userLocation)

        guard let venue = nearestVenue else {
            return .result(
                dialog: IntentDialog(stringLiteral: "Could not find nearby stadiums. Please try again later.")
            )
        }

        // Calculate distance
        let venueLocation = CLLocation(latitude: venue.coordinate.latitude, longitude: venue.coordinate.longitude)
        let distance = userLocation.distance(from: venueLocation) / 1000 // Convert to km

        let message: String
        if distance < 1 {
            message = "You're very close! \(venue.name) in \(venue.city) is only \(Int(distance * 1000)) meters away."
        } else if distance < 10 {
            message = "The nearest stadium is \(venue.name) in \(venue.city), \(String(format: "%.1f", distance)) kilometers from you."
        } else {
            message = "The nearest stadium is \(venue.name) in \(venue.city), \(venue.country), \(Int(distance)) kilometers away."
        }

        print("📍 [APP INTENT] Nearest stadium: \(venue.name) at \(distance)km")

        return .result(dialog: IntentDialog(stringLiteral: message))
    }

    // Helper function to get current location
    private func getCurrentLocation() async -> CLLocation? {
        // In a real Intent, this should use CLLocationManager
        // For now, we return nil and the logic will be handled in the app
        // Since App Intents have limitations to access LocationManager directly

        // Try to read last known location from UserDefaults
        if let lat = UserDefaults.standard.object(forKey: "lastKnownLatitude") as? Double,
           let lon = UserDefaults.standard.object(forKey: "lastKnownLongitude") as? Double {
            return CLLocation(latitude: lat, longitude: lon)
        }

        return nil
    }

    // Helper function to find the nearest venue
    private func findNearestVenue(to location: CLLocation) -> WorldCupVenue? {
        let venues = WorldCupVenue.allVenues

        var nearestVenue: WorldCupVenue?
        var shortestDistance: Double = .infinity

        for venue in venues {
            let venueLocation = CLLocation(latitude: venue.coordinate.latitude, longitude: venue.coordinate.longitude)
            let distance = location.distance(from: venueLocation)

            if distance < shortestDistance {
                shortestDistance = distance
                nearestVenue = venue
            }
        }

        return nearestVenue
    }
}

/// Intent to list all nearby venues within a radius
struct ListNearbyVenuesIntent: AppIntent {
    static var title: LocalizedStringResource = "List Nearby Stadiums"
    static var description = IntentDescription("Show all 2026 World Cup stadiums near you")

    @Parameter(title: "Radius (km)", description: "Search radius in kilometers", default: 50)
    var radiusKm: Int

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Get location
        guard let userLocation = await getCurrentLocation() else {
            return .result(
                dialog: IntentDialog(stringLiteral: "Could not get your location. Please verify that Atenea has location permissions.")
            )
        }

        // Find venues within radius
        let nearbyVenues = findVenuesWithinRadius(location: userLocation, radiusKm: Double(radiusKm))

        if nearbyVenues.isEmpty {
            return .result(
                dialog: IntentDialog(stringLiteral: "There are no 2026 World Cup stadiums within \(radiusKm) kilometers of your location.")
            )
        }

        // Create message with venue list
        let venueList = nearbyVenues.prefix(5).map { venue, distance in
            "\(venue.name) in \(venue.city) (\(Int(distance))km)"
        }.joined(separator: ", ")

        let message = "I found \(nearbyVenues.count) stadium\(nearbyVenues.count == 1 ? "" : "s") near you: \(venueList)."

        print("📍 [APP INTENT] \(nearbyVenues.count) stadiums found within \(radiusKm)km radius")

        return .result(dialog: IntentDialog(stringLiteral: message))
    }

    private func getCurrentLocation() async -> CLLocation? {
        if let lat = UserDefaults.standard.object(forKey: "lastKnownLatitude") as? Double,
           let lon = UserDefaults.standard.object(forKey: "lastKnownLongitude") as? Double {
            return CLLocation(latitude: lat, longitude: lon)
        }
        return nil
    }

    private func findVenuesWithinRadius(location: CLLocation, radiusKm: Double) -> [(venue: WorldCupVenue, distance: Double)] {
        let radiusMeters = radiusKm * 1000
        var venuesWithDistance: [(WorldCupVenue, Double)] = []

        for venue in WorldCupVenue.allVenues {
            let venueLocation = CLLocation(latitude: venue.coordinate.latitude, longitude: venue.coordinate.longitude)
            let distance = location.distance(from: venueLocation)

            if distance <= radiusMeters {
                venuesWithDistance.append((venue, distance / 1000)) // distance in km
            }
        }

        // Sort by distance
        return venuesWithDistance.sorted { $0.1 < $1.1 }
    }
}
