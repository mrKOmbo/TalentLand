//
//  TimbreManager.swift
//  atenea
//
//  Gestor del sistema de Timbre Virtual
//

import Foundation
internal import Combine

class TimbreManager: ObservableObject {
    static let shared = TimbreManager()

    /// Timbres recibidos (para el merchant)
    @Published var pendingTimbres: [TimbreEvent] = []

    /// Timbres enviados (para el cliente)
    @Published var sentTimbres: [TimbreEvent] = []

    /// Última respuesta recibida (para notificar al cliente)
    @Published var lastResponse: TimbreResponse?

    /// Nuevo timbre recibido (para trigger de notificación)
    @Published var newTimbreReceived: TimbreEvent?

    private init() {}

    // MARK: - Cliente envía timbre

    @discardableResult
    func sendTimbre(
        from client: User,
        to merchant: Merchant,
        type: TimbreType,
        message: String? = nil,
        clientLatitude: Double,
        clientLongitude: Double
    ) -> TimbreEvent {
        let timbre = TimbreEvent(
            clientId: client.id,
            clientName: client.name,
            merchantId: merchant.id,
            merchantName: merchant.businessName,
            type: type,
            message: message,
            clientLatitude: clientLatitude,
            clientLongitude: clientLongitude
        )

        sentTimbres.insert(timbre, at: 0)
        pendingTimbres.insert(timbre, at: 0)
        newTimbreReceived = timbre

        // Registrar demanda
        DemandZoneManager.shared.recordDemand(
            latitude: clientLatitude,
            longitude: clientLongitude,
            source: .timbre,
            category: merchant.category
        )

        // Auto-limpiar notificación después de 5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if self?.newTimbreReceived?.id == timbre.id {
                self?.newTimbreReceived = nil
            }
        }

        return timbre
    }

    // MARK: - Merchant acciones

    func markAsRead(_ timbreId: UUID) {
        if let index = pendingTimbres.firstIndex(where: { $0.id == timbreId }) {
            pendingTimbres[index].isRead = true
        }
    }

    func markAllAsRead() {
        for i in pendingTimbres.indices {
            pendingTimbres[i].isRead = true
        }
    }

    func respond(to timbreId: UUID, with responseType: TimbreResponseType, estimatedMinutes: Int? = nil, message: String? = nil) {
        guard let merchant = MerchantManager.shared.currentMerchantProfile else { return }

        let response = TimbreResponse(
            timbreId: timbreId,
            merchantId: merchant.id,
            type: responseType,
            estimatedMinutes: estimatedMinutes,
            message: message
        )

        // Actualizar en pendingTimbres
        if let index = pendingTimbres.firstIndex(where: { $0.id == timbreId }) {
            pendingTimbres[index].isResponded = true
            pendingTimbres[index].response = response
        }

        // Actualizar en sentTimbres (para que el cliente vea la respuesta)
        if let index = sentTimbres.firstIndex(where: { $0.id == timbreId }) {
            sentTimbres[index].isResponded = true
            sentTimbres[index].response = response
        }

        lastResponse = response

        // Si respondió "Ya voy", iniciar LiveTrack para el cliente
        if responseType == .onMyWay,
           let merchant = MerchantManager.shared.currentMerchantProfile,
           let timbre = pendingTimbres.first(where: { $0.id == timbreId }) {
            LiveTrackManager.shared.startTracking(timbre: timbre, merchant: merchant)
        }
    }

    // MARK: - Computed

    var unreadCount: Int {
        pendingTimbres.filter { !$0.isRead }.count
    }

    var unansweredCount: Int {
        pendingTimbres.filter { !$0.isResponded }.count
    }

    func timbresForMerchant(_ merchantId: UUID) -> [TimbreEvent] {
        pendingTimbres.filter { $0.merchantId == merchantId }
    }

    func timbresFromClient(_ clientId: UUID) -> [TimbreEvent] {
        sentTimbres.filter { $0.clientId == clientId }
    }

    // MARK: - Cleanup

    func clearOldTimbres(olderThan seconds: TimeInterval = 3600) {
        let cutoff = Date().addingTimeInterval(-seconds)
        pendingTimbres.removeAll { $0.timestamp < cutoff }
        sentTimbres.removeAll { $0.timestamp < cutoff }
    }
}
