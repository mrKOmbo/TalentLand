//
//  NavigateToStadiumIntent.swift
//  Atenea
//
//  Intent to start navigation to a 2026 World Cup stadium
//  Usage: "Hey Siri, navigate to Estadio Azteca in Atenea"
//

import Foundation
import AppIntents
import CoreLocation
import SwiftUI

/// Intent to navigate to a specific stadium
struct NavigateToStadiumIntent: AppIntent {
    static var title: LocalizedStringResource = "Navigate to Stadium"
    static var description = IntentDescription("Start navigation to a 2026 World Cup stadium")

    static var openAppWhenRun: Bool = true

    // Parameter: the stadium to navigate to (optional for shortcuts)
    @Parameter(title: "Stadium", description: "The destination stadium")
    var venue: VenueEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Navigate to \(\.$venue)")
    }

    // Intent execution
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Verificar que se haya proporcionado un venue
        guard let venue = venue else {
            return .result(
                dialog: "Please specify which stadium you want to navigate to."
            )
        }

        // Find the original venue
        guard let worldCupVenue = venue.toWorldCupVenue() else {
            return .result(
                dialog: "Could not find stadium \(venue.name). Please try again."
            )
        }

        // Activate navigation using the manager
        NavigationStateManager.shared.shouldOpenNavigation = true

        // Save the destination in UserDefaults for the app to read when opening
        let destination = [
            "name": worldCupVenue.name,
            "latitude": worldCupVenue.coordinate.latitude,
            "longitude": worldCupVenue.coordinate.longitude
        ] as [String : Any]

        UserDefaults.standard.set(destination, forKey: "pendingNavigationDestination")
        UserDefaults.standard.set(true, forKey: "shouldStartNavigation")

        print("🧭 [APP INTENT] Navigation scheduled to \(worldCupVenue.name)")

        // Confirmation message for Siri
        return .result(
            dialog: "Starting navigation to \(worldCupVenue.name) in \(worldCupVenue.city). Opening Atenea..."
        )
    }
}

/// Intent to navigate to the nearest stadium
struct NavigateToNearestStadiumIntent: AppIntent {
    static var title: LocalizedStringResource = "Go to Nearest Stadium"
    static var description = IntentDescription("Navigate to the 2026 World Cup stadium nearest to your location")

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Mark that we want to navigate to the nearest
        UserDefaults.standard.set(true, forKey: "shouldNavigateToNearest")
        NavigationStateManager.shared.shouldOpenNavigation = true

        print("🧭 [APP INTENT] Navigation to nearest stadium requested")

        return .result(
            dialog: "Searching for the nearest stadium. Opening Atenea..."
        )
    }
}
