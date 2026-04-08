//
//  TimbreEvent.swift
//  atenea
//
//  Modelos del sistema de Timbre Virtual
//

import Foundation
import CoreLocation

// MARK: - Timbre Type

enum TimbreType: String, Codable, CaseIterable {
    case ring = "ring"
    case question = "question"
    case hurry = "hurry"

    var emoji: String {
        switch self {
        case .ring: return "🔔"
        case .question: return "❓"
        case .hurry: return "🏃"
        }
    }

    var displayName: String {
        switch self {
        case .ring: return "Quiero comprar"
        case .question: return "Tengo una pregunta"
        case .hurry: return "Ven rápido"
        }
    }

    var subtitle: String {
        switch self {
        case .ring: return "Avísale que estás cerca y quieres algo"
        case .question: return "Pregunta si tiene un producto"
        case .hurry: return "Pide que se acerque pronto"
        }
    }
}

// MARK: - Timbre Event

struct TimbreEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let clientId: UUID
    let clientName: String
    let merchantId: UUID
    let merchantName: String
    let type: TimbreType
    let message: String?
    let clientLatitude: Double
    let clientLongitude: Double
    let timestamp: Date
    var isRead: Bool
    var isResponded: Bool
    var response: TimbreResponse?

    init(
        id: UUID = UUID(),
        clientId: UUID,
        clientName: String,
        merchantId: UUID,
        merchantName: String,
        type: TimbreType,
        message: String? = nil,
        clientLatitude: Double,
        clientLongitude: Double,
        timestamp: Date = Date(),
        isRead: Bool = false,
        isResponded: Bool = false,
        response: TimbreResponse? = nil
    ) {
        self.id = id
        self.clientId = clientId
        self.clientName = clientName
        self.merchantId = merchantId
        self.merchantName = merchantName
        self.type = type
        self.message = message
        self.clientLatitude = clientLatitude
        self.clientLongitude = clientLongitude
        self.timestamp = timestamp
        self.isRead = isRead
        self.isResponded = isResponded
        self.response = response
    }

    var clientCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: clientLatitude, longitude: clientLongitude)
    }

    var timeAgo: String {
        let seconds = Int(Date().timeIntervalSince(timestamp))
        if seconds < 60 { return "ahora" }
        if seconds < 3600 { return "hace \(seconds / 60) min" }
        return "hace \(seconds / 3600)h"
    }

    static func == (lhs: TimbreEvent, rhs: TimbreEvent) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Timbre Response

enum TimbreResponseType: String, Codable, CaseIterable {
    case onMyWay = "on_my_way"
    case waitHere = "wait_here"
    case busy = "busy"
    case closed = "closed"

    var emoji: String {
        switch self {
        case .onMyWay: return "🚶"
        case .waitHere: return "📍"
        case .busy: return "⏳"
        case .closed: return "🔒"
        }
    }

    var displayName: String {
        switch self {
        case .onMyWay: return "Ya voy"
        case .waitHere: return "Espérame ahí"
        case .busy: return "Estoy ocupado"
        case .closed: return "Ya cerré"
        }
    }
}

struct TimbreResponse: Identifiable, Codable, Equatable {
    let id: UUID
    let timbreId: UUID
    let merchantId: UUID
    let type: TimbreResponseType
    let estimatedMinutes: Int?
    let message: String?
    let timestamp: Date

    init(
        id: UUID = UUID(),
        timbreId: UUID,
        merchantId: UUID,
        type: TimbreResponseType,
        estimatedMinutes: Int? = nil,
        message: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.timbreId = timbreId
        self.merchantId = merchantId
        self.type = type
        self.estimatedMinutes = estimatedMinutes
        self.message = message
        self.timestamp = timestamp
    }
}
