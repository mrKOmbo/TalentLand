//
//  TimbreManager.swift
//  atenea
//
//  Gestor del sistema de Timbre Virtual
//

import Foundation
import UIKit
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

        print("📨 [Timbre SEND] from=\(client.name) to=\(merchant.businessName) type=\(type.rawValue) msg=\(message ?? "nil") lat=\(clientLatitude) lon=\(clientLongitude)")

        /* // Registrar demanda
        DemandZoneManager.shared.recordDemand(
            latitude: clientLatitude,
            longitude: clientLongitude,
            source: .timbre,
            category: merchant.category
        )
        */

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
            pendingTimbres[index].responses.append(response)
        }

        // Actualizar en sentTimbres (para que el cliente vea la respuesta)
        if let index = sentTimbres.firstIndex(where: { $0.id == timbreId }) {
            sentTimbres[index].isResponded = true
            sentTimbres[index].response = response
            sentTimbres[index].responses.append(response)
        }

        lastResponse = response
        print("📤 [Timbre RESPOND] merchant=\(merchant.businessName) type=\(responseType.rawValue) msg=\(message ?? "nil") timbreId=\(timbreId)")

        // Enviar respuesta por BLE notify al cliente
        if let timbre = pendingTimbres.first(where: { $0.id == timbreId }) {
            let clientPeerID = RadarService.shared.peerMerchantMap.first(where: { $0.value == timbre.clientName })?.key
            if let peerID = clientPeerID {
                RadarService.shared.sendResponseP2P(response, to: peerID)
                print("🔔 [Timbre BLE] 📤 Respuesta enviada al cliente \(timbre.clientName)")
            } else {
                // Fallback: notify a todos los suscritos
                RadarService.shared.sendResponseP2P(response, to: "")
                print("🔔 [Timbre BLE] 📤 Respuesta broadcast a todos los suscritos")
            }
        }

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

    // MARK: - P2P Reception

    /// Llamado cuando un timbre llega de otro dispositivo vía MPC
    func receiveTimbre(_ timbre: TimbreEvent) {
        pendingTimbres.insert(timbre, at: 0)
        newTimbreReceived = timbre
        print("📩 [Timbre RECV] from=\(timbre.clientName) to=\(timbre.merchantName) type=\(timbre.type.rawValue) msg=\(timbre.message ?? "nil") clientLat=\(timbre.clientLatitude) clientLon=\(timbre.clientLongitude)")

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)

        // Auto-clear después de 60s
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
            if self?.newTimbreReceived?.id == timbre.id {
                self?.newTimbreReceived = nil
            }
        }
    }

    /// Llamado cuando una respuesta llega de otro dispositivo vía MPC
    func receiveResponse(_ response: TimbreResponse) {
        if let index = sentTimbres.firstIndex(where: { $0.id == response.timbreId }) {
            sentTimbres[index].isResponded = true
            sentTimbres[index].response = response
            sentTimbres[index].responses.append(response)
        }
        lastResponse = response
        print("📩 [Timbre RECV RESPONSE] type=\(response.type.rawValue) msg=\(response.message ?? "nil") minutes=\(response.estimatedMinutes.map { String($0) } ?? "nil") timbreId=\(response.timbreId)")

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // MARK: - Cleanup

    func clearOldTimbres(olderThan seconds: TimeInterval = 3600) {
        let cutoff = Date().addingTimeInterval(-seconds)
        pendingTimbres.removeAll { $0.timestamp < cutoff }
        sentTimbres.removeAll { $0.timestamp < cutoff }
    }

    /// Inyecta una respuesta simulada (por Claude) directamente en sentTimbres del cliente.
    /// No toca lastResponse — el chat ya observa sentTimbres directamente.
    /// lastResponse solo se usa para notificar respuestas BLE cuando el chat NO está abierto.
    func applySimulatedResponse(for timbreId: UUID, type: TimbreResponseType, message: String, estimatedMinutes: Int?, merchantId: UUID) {
        let response = TimbreResponse(
            timbreId: timbreId,
            merchantId: merchantId,
            type: type,
            estimatedMinutes: estimatedMinutes,
            message: message
        )
        if let index = sentTimbres.firstIndex(where: { $0.id == timbreId }) {
            sentTimbres[index].isResponded = true
            sentTimbres[index].response = response
            sentTimbres[index].responses.append(response)
        }
        if let index = pendingTimbres.firstIndex(where: { $0.id == timbreId }) {
            pendingTimbres[index].isResponded = true
            pendingTimbres[index].response = response
            pendingTimbres[index].responses.append(response)
        }
        // NO tocar lastResponse — evita que el onChange de HomeView cierre/reabra el chat
        print("🤖 [Timbre Claude] Respuesta simulada: \(type.displayName) — \(message)")
    }

    /// Limpiar todo el estado al cerrar sesión
    func resetSession() {
        pendingTimbres.removeAll()
        sentTimbres.removeAll()
        lastResponse = nil
        newTimbreReceived = nil
    }
}
