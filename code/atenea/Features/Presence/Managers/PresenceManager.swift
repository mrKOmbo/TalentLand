//
//  PresenceManager.swift
//  atenea
//
//  Gestiona la presencia de vendedores por zona geohash.
//  Patrón adaptado de bitchat/GeohashPresenceService.
//

import Foundation
internal import Combine
import CoreLocation
import SwiftUI

@MainActor
class PresenceManager: ObservableObject {
    static let shared = PresenceManager()

    @Published var activeMerchantPresences: [MerchantPresence] = []
    @Published var currentUserGeohash: String = ""

    private var heartbeatTimer: Timer?
    private let heartbeatInterval: TimeInterval = 30.0
    private let presenceTimeout: TimeInterval = 300.0 // 5 minutos
    private var cancellables = Set<AnyCancellable>()
    private var isBroadcasting = false

    private init() {
        DispatchQueue.main.async { [self] in
            loadMockPresences()
        }
    }

    // MARK: - Merchant side

    func startBroadcasting(merchant: Merchant) {
        guard !isBroadcasting else { return }
        isBroadcasting = true

        performHeartbeat(merchant: merchant)

        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.performHeartbeat(merchant: merchant)
            }
        }
    }

    func stopBroadcasting() {
        isBroadcasting = false
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    func updateLocation(merchantId: UUID, latitude: Double, longitude: Double) {
        let geohash = Geohash.encode(latitude: latitude, longitude: longitude, precision: GeohashChannelLevel.neighborhood.precision)

        if let index = activeMerchantPresences.firstIndex(where: { $0.id == merchantId }) {
            activeMerchantPresences[index].geohash = geohash
            activeMerchantPresences[index].lastSeen = Date()
        }
    }

    // MARK: - Client side

    func updateUserLocation(latitude: Double, longitude: Double) {
        currentUserGeohash = Geohash.encode(latitude: latitude, longitude: longitude, precision: GeohashChannelLevel.neighborhood.precision)
        recalculateDistances(userLat: latitude, userLon: longitude)
    }

    func getMerchantsInZone(geohash: String, includeNeighbors: Bool = true) -> [MerchantPresence] {
        let validGeohashes: Set<String>
        if includeNeighbors {
            let prefix = String(geohash.prefix(GeohashChannelLevel.neighborhood.precision))
            var set = Set(Geohash.neighbors(of: prefix))
            set.insert(prefix)
            validGeohashes = set
        } else {
            validGeohashes = [geohash]
        }

        return activeMerchantPresences.filter { presence in
            let presencePrefix = String(presence.geohash.prefix(GeohashChannelLevel.neighborhood.precision))
            return validGeohashes.contains(presencePrefix) && !presence.isStale
        }
    }

    func getMerchantsNear(latitude: Double, longitude: Double, level: GeohashChannelLevel = .neighborhood) -> [MerchantPresence] {
        let geohash = Geohash.encode(latitude: latitude, longitude: longitude, precision: level.precision)
        return getMerchantsInZone(geohash: geohash, includeNeighbors: true)
            .sorted { ($0.distanceFromUser ?? .infinity) < ($1.distanceFromUser ?? .infinity) }
    }

    var activeMerchantCount: Int {
        activeMerchantPresences.filter { !$0.isStale }.count
    }

    // MARK: - Internal

    private func performHeartbeat(merchant: Merchant) {
        guard let location = merchant.currentLocation else { return }

        let geohash = Geohash.encode(
            latitude: location.latitude,
            longitude: location.longitude,
            precision: GeohashChannelLevel.neighborhood.precision
        )

        if let index = activeMerchantPresences.firstIndex(where: { $0.id == merchant.id }) {
            activeMerchantPresences[index].lastSeen = Date()
            activeMerchantPresences[index].geohash = geohash
        } else {
            let presence = MerchantPresence(
                id: merchant.id,
                merchant: merchant,
                geohash: geohash,
                lastSeen: Date()
            )
            activeMerchantPresences.append(presence)
        }

        pruneStalePresences()
    }

    private func pruneStalePresences() {
        activeMerchantPresences.removeAll { $0.isStale }
    }

    private func recalculateDistances(userLat: Double, userLon: Double) {
        for i in activeMerchantPresences.indices {
            guard let loc = activeMerchantPresences[i].merchant.currentLocation else { continue }
            activeMerchantPresences[i].distanceFromUser = MerchantManager.haversineDistance(
                lat1: userLat, lon1: userLon,
                lat2: loc.latitude, lon2: loc.longitude
            )
        }
        activeMerchantPresences.sort { ($0.distanceFromUser ?? .infinity) < ($1.distanceFromUser ?? .infinity) }
    }

    // MARK: - Mock Data

    private func loadMockPresences() {
        let merchants = MerchantManager.shared.activeMerchants()
        activeMerchantPresences = merchants.compactMap { merchant in
            guard let loc = merchant.currentLocation else { return nil }
            let geohash = Geohash.encode(
                latitude: loc.latitude,
                longitude: loc.longitude,
                precision: GeohashChannelLevel.neighborhood.precision
            )
            return MerchantPresence(
                id: merchant.id,
                merchant: merchant,
                geohash: geohash,
                lastSeen: Date().addingTimeInterval(-Double.random(in: 0...120))
            )
        }

        // Calcular distancias desde mock user location
        recalculateDistances(userLat: mockUserLatitude, userLon: mockUserLongitude)
    }
}

// MARK: - MerchantPresence Model

struct MerchantPresence: Identifiable {
    let id: UUID
    let merchant: Merchant
    var geohash: String
    var lastSeen: Date
    var distanceFromUser: Double?

    var isStale: Bool {
        Date().timeIntervalSince(lastSeen) > 300
    }

    var activityStatus: ActivityStatus {
        let elapsed = Date().timeIntervalSince(lastSeen)
        if elapsed < 60 { return .active }
        if elapsed < 300 { return .recent }
        return .stale
    }

    var formattedDistance: String {
        guard let dist = distanceFromUser else { return "?" }
        if dist < 1000 { return "\(Int(dist))m" }
        return String(format: "%.1fkm", dist / 1000)
    }

    enum ActivityStatus {
        case active   // < 1 min
        case recent   // < 5 min
        case stale    // > 5 min

        var color: SwiftUI.Color {
            switch self {
            case .active: return .green
            case .recent: return .yellow
            case .stale: return .gray
            }
        }
    }
}
