//
//  AteneaAppShortcuts.swift
//  Atenea
//
//  Defines suggested shortcuts that appear in the Shortcuts app
//  and in Siri suggestions
//

import Foundation
import AppIntents

/// Provider of suggested shortcuts for Atenea
struct AteneaAppShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        return [
            // Navigate to nearest stadium
            AppShortcut(
                intent: NavigateToNearestStadiumIntent(),
                phrases: [
                    "Go to nearest stadium in \(.applicationName)",
                    "Nearby stadium with \(.applicationName)",
                    "Navigate to closest stadium in \(.applicationName)"
                ],
                shortTitle: "Nearby Stadium",
                systemImageName: "building.2.fill"
            ),

            // Toggle emergency (combines activate/deactivate)
            AppShortcut(
                intent: ToggleEmergencyIntent(),
                phrases: [
                    "Activate emergency in \(.applicationName)",
                    "Emergency mode in \(.applicationName)",
                    "Emergency in \(.applicationName)",
                    "Toggle emergency in \(.applicationName)"
                ],
                shortTitle: "Emergency",
                systemImageName: "exclamationmark.triangle.fill"
            ),

            // View my album
            AppShortcut(
                intent: ShowAlbumIntent(),
                phrases: [
                    "View my album in \(.applicationName)",
                    "Show my collection in \(.applicationName)",
                    "Open sticker album in \(.applicationName)"
                ],
                shortTitle: "My Album",
                systemImageName: "book.fill"
            ),

            // Collection progress
            AppShortcut(
                intent: GetCollectionProgressIntent(),
                phrases: [
                    "How many stickers do I have in \(.applicationName)?",
                    "My collection progress in \(.applicationName)",
                    "Album progress in \(.applicationName)",
                    "What stickers am I missing in \(.applicationName)?"
                ],
                shortTitle: "My Progress",
                systemImageName: "chart.bar.fill"
            ),

            // Find nearby stadium
            AppShortcut(
                intent: FindNearbyVenueIntent(),
                phrases: [
                    "What stadium is nearby in \(.applicationName)?",
                    "Find stadium near me in \(.applicationName)"
                ],
                shortTitle: "Stadium Nearby",
                systemImageName: "location.circle.fill"
            )
        ]
    }

    static var shortcutTileColor: ShortcutTileColor {
        // Tile color in the Shortcuts app (based on Atenea's color)
        .teal
    }
}
