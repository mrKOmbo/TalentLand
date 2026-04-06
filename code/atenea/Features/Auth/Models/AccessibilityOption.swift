//
//  AccessibilityOption.swift
//  Atenea
//
//  Model for user accessibility preferences
//

import Foundation

enum AccessibilityOption: String, CaseIterable, Identifiable, Codable {
    case none = "none"
    case visual = "visual"
    case hearing = "hearing"
    case motor = "motor"
    case cognitive = "cognitive"
    case speech = "speech"
    case neurological = "neurological"
    case multiple = "multiple"
    case other = "other"
    case preferNotToSay = "prefer_not_to_say"

    var id: String { self.rawValue }

    // Localized display name
    var displayName: String {
        switch self {
        case .none:
            return LocalizedString("accessibility.none")
        case .visual:
            return LocalizedString("accessibility.visual")
        case .hearing:
            return LocalizedString("accessibility.hearing")
        case .motor:
            return LocalizedString("accessibility.motor")
        case .cognitive:
            return LocalizedString("accessibility.cognitive")
        case .speech:
            return LocalizedString("accessibility.speech")
        case .neurological:
            return LocalizedString("accessibility.neurological")
        case .multiple:
            return LocalizedString("accessibility.multiple")
        case .other:
            return LocalizedString("accessibility.other")
        case .preferNotToSay:
            return LocalizedString("accessibility.preferNotToSay")
        }
    }

    // Icon for each accessibility type
    var icon: String {
        switch self {
        case .none:
            return "checkmark.circle"
        case .visual:
            return "eye.slash"
        case .hearing:
            return "ear.badge.checkmark"
        case .motor:
            return "figure.walk"
        case .cognitive:
            return "brain.head.profile"
        case .speech:
            return "bubble.left.and.bubble.right"
        case .neurological:
            return "waveform.path.ecg"
        case .multiple:
            return "person.2"
        case .other:
            return "ellipsis.circle"
        case .preferNotToSay:
            return "hand.raised"
        }
    }
}
