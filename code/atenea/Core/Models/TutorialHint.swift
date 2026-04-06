//
//  TutorialHint.swift
//  Atenea
//
//  Model for in-app tutorial hints with spotlight effect
//

import SwiftUI

// MARK: - Tutorial Hint Model

struct TutorialHint: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let position: CGRect  // Position of the spotlight
    let arrowDirection: ArrowDirection
    let textPosition: TextPosition

    static func == (lhs: TutorialHint, rhs: TutorialHint) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Arrow Direction

enum ArrowDirection {
    case up
    case down
    case left
    case right
    case none
}

// MARK: - Text Position

enum TextPosition {
    case top
    case bottom
    case left
    case right
}

// MARK: - Tutorial Steps

enum TutorialStep: String, CaseIterable {
    case mapMarkers = "map.markers"
    case menuButton = "menu.button"
    case searchButton = "search.button"
    case emergencyButton = "emergency.button"
    case communityTab = "community.tab"
    case albumTab = "album.tab"

    var localizedTitle: String {
        LocalizedString("tutorial.\(rawValue).title")
    }

    var localizedDescription: String {
        LocalizedString("tutorial.\(rawValue).description")
    }
}
