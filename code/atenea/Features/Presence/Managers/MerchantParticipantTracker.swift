//
//  MerchantParticipantTracker.swift
//  atenea
//
//  Tracking de participantes (merchants) por zona geohash.
//  Patrón adaptado de bitchat/GeohashParticipantTracker.
//

import Foundation
internal import Combine
import SwiftUI

@MainActor
final class MerchantParticipantTracker: ObservableObject {

    static let shared = MerchantParticipantTracker()

    /// Cutoff de actividad (5 minutos)
    let activityCutoff: TimeInterval = -300

    /// [geohash: [merchantId: lastSeen]]
    private var participants: [String: [UUID: Date]] = [:]

    /// Geohash activo observado
    private var activeGeohash: String?

    /// Merchants visibles en la zona activa
    @Published private(set) var visibleMerchantIds: [UUID] = []

    private var refreshTimer: Timer?

    private init() {}

    // MARK: - Active Zone

    func setActiveGeohash(_ geohash: String?) {
        activeGeohash = geohash
        if geohash == nil {
            visibleMerchantIds = []
        } else {
            refresh()
        }
    }

    // MARK: - Recording

    func recordParticipant(merchantId: UUID, geohash: String) {
        var map = participants[geohash] ?? [:]
        map[merchantId] = Date()
        participants[geohash] = map

        if activeGeohash == geohash {
            refresh()
        }
    }

    func removeParticipant(merchantId: UUID) {
        for (gh, var map) in participants {
            map.removeValue(forKey: merchantId)
            participants[gh] = map
        }
        refresh()
    }

    // MARK: - Queries

    func participantCount(for geohash: String) -> Int {
        let cutoff = Date().addingTimeInterval(activityCutoff)
        let map = participants[geohash] ?? [:]
        return map.values.filter { $0 >= cutoff }.count
    }

    func participantCountIncludingNeighbors(for geohash: String) -> Int {
        var total = participantCount(for: geohash)
        for neighbor in Geohash.neighbors(of: geohash) {
            total += participantCount(for: neighbor)
        }
        return total
    }

    // MARK: - Refresh

    func refresh() {
        guard let gh = activeGeohash else {
            visibleMerchantIds = []
            return
        }

        let cutoff = Date().addingTimeInterval(activityCutoff)
        let map = (participants[gh] ?? [:]).filter { $0.value >= cutoff }
        visibleMerchantIds = Array(map.keys).sorted { a, b in
            (map[a] ?? .distantPast) > (map[b] ?? .distantPast)
        }
    }

    func startRefreshTimer(interval: TimeInterval = 30.0) {
        stopRefreshTimer()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func clear() {
        participants.removeAll()
        visibleMerchantIds = []
    }
}
