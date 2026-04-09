//
//  RadarService.swift
//  atenea
//
//  Servicio de radar P2P usando MultipeerConnectivity.
//  Merchants se anuncian, clientes descubren — sin internet, sin conectar.
//
//  Inspirado en bitchat BLEService (public domain) pero simplificado:
//  - No requiere conexión (solo discovery via MPC browser/advertiser)
//  - discoveryInfo lleva nombre, categoría, emoji directamente
//  - Funciona con WiFi y Bluetooth simultáneamente
//

import Foundation
internal import Combine
import MultipeerConnectivity
import SwiftUI
// MARK: - Discovered Peer

struct RadarPeer: Identifiable, Equatable {
    let id: String // MCPeerID.displayName
    let peerID: MCPeerID
    let businessName: String
    let category: String
    let emoji: String
    let isStatic: Bool
    var lastSeen: Date
    var signalStrength: SignalStrength

    enum SignalStrength: String {
        case strong = "strong"   // Descubierto recientemente
        case medium = "medium"   // Hace 30s+
        case weak = "weak"       // Hace 60s+, a punto de perderse

        var color: SwiftUI.Color {
            switch self {
            case .strong: return .green
            case .medium: return .yellow
            case .weak: return .orange
            }
        }
    }

    var isStale: Bool {
        Date().timeIntervalSince(lastSeen) > 90
    }

    static func == (lhs: RadarPeer, rhs: RadarPeer) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Radar Service

class RadarService: NSObject, ObservableObject {
    static let shared = RadarService()

    // MARK: - Published State

    @Published var discoveredMerchants: [RadarPeer] = []
    @Published var connectedPeers: [MCPeerID] = []
    @Published var isScanning = false
    @Published var isAdvertising = false
    @Published var radarStatus: String = "Inactivo"

    // MARK: - MPC

    private let serviceType = "atenea-rdr"
    private var myPeerID: MCPeerID
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var session: MCSession?
    private var pruneTimer: Timer?
    private var refreshTimer: Timer?

    // Mapeo peerID → nombre para rutear respuestas
    var peerMerchantMap: [MCPeerID: String] = [:]

    // MARK: - Init

    private override init() {
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
    }

    // MARK: - Merchant: Anunciarse

    /// El merchant se anuncia para que clientes cercanos lo descubran.
    /// discoveryInfo se transmite en el beacon — no requiere conexión.
    func startAdvertising(merchant: Merchant) {
        stopAdvertising()

        let discoveryInfo: [String: String] = [
            "name": String(merchant.businessName.prefix(30)),
            "cat": merchant.category.rawValue,
            "emoji": merchant.emoji,
            "static": merchant.isStatic ? "1" : "0"
        ]

        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
        session?.delegate = self

        advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: discoveryInfo,
            serviceType: serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()

        DispatchQueue.main.async {
            self.isAdvertising = true
            self.radarStatus = "Anunciando: \(merchant.businessName)"
        }

        print("📡 [Radar] Merchant anunciándose: \(merchant.businessName)")
    }

    func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil

        DispatchQueue.main.async {
            self.isAdvertising = false
            if !self.isScanning {
                self.radarStatus = "Inactivo"
            }
        }

        print("📡 [Radar] Dejó de anunciarse")
    }

    // MARK: - Client: Escanear

    /// El cliente escanea para descubrir merchants cercanos.
    /// foundPeer da peerID + discoveryInfo sin necesidad de conectar.
    func startScanning() {
        stopScanning()

        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
        session?.delegate = self

        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()

        // Timer para actualizar signal strength y limpiar stale peers
        pruneTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.pruneAndUpdateSignals()
        }

        // UI se refresca automáticamente via @Published properties

        DispatchQueue.main.async {
            self.isScanning = true
            self.radarStatus = "Escaneando..."
        }

        print("🔍 [Radar] Escaneando merchants cercanos...")
    }

    func stopScanning() {
        browser?.stopBrowsingForPeers()
        browser = nil
        pruneTimer?.invalidate()
        pruneTimer = nil
        refreshTimer?.invalidate()
        refreshTimer = nil

        DispatchQueue.main.async {
            self.isScanning = false
            if !self.isAdvertising {
                self.radarStatus = "Inactivo"
            }
        }

        print("🔍 [Radar] Dejó de escanear")
    }

    // MARK: - Queries

    var activeMerchantCount: Int {
        discoveredMerchants.filter { !$0.isStale }.count
    }

    var nearbyMerchantNames: [String] {
        discoveredMerchants.filter { !$0.isStale }.map(\.businessName)
    }

    // MARK: - Stop All

    func stopAll() {
        stopAdvertising()
        stopScanning()
        DispatchQueue.main.async {
            self.discoveredMerchants.removeAll()
            self.connectedPeers.removeAll()
            self.peerMerchantMap.removeAll()
            self.radarStatus = "Inactivo"
        }
    }

    // MARK: - P2P Timbre (envío de datos reales entre dispositivos)

    /// Cliente invita a un merchant para enviarle un timbre
    func connectToPeer(_ peer: RadarPeer) {
        guard let browser = browser, let session = session else {
            print("📡 [Radar P2P] ❌ No hay browser/session activo")
            return
        }
        browser.invitePeer(peer.peerID, to: session, withContext: "timbre".data(using: .utf8), timeout: 10)
        peerMerchantMap[peer.peerID] = peer.businessName
        print("📡 [Radar P2P] 📤 Invitación enviada a \(peer.businessName)")
    }

    /// Envía un mensaje P2P a un peer conectado
    func sendP2P(_ message: TimbreP2PMessage, to peerID: MCPeerID) {
        guard let session = session else {
            print("📡 [Radar P2P] ❌ No hay session")
            return
        }
        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: [peerID], with: .reliable)
            print("📡 [Radar P2P] ✅ Mensaje enviado (\(data.count) bytes) a \(peerID.displayName)")
        } catch {
            print("📡 [Radar P2P] ❌ Error enviando: \(error.localizedDescription)")
        }
    }

    /// Envía timbre al merchant — conecta si no está conectado, luego envía
    func sendTimbreP2P(_ timbre: TimbreEvent, to peer: RadarPeer) {
        let peerID = peer.peerID

        if connectedPeers.contains(peerID) {
            // Ya conectado, enviar directo
            sendP2P(.timbreEvent(timbre), to: peerID)
        } else {
            // Conectar primero, luego enviar cuando la conexión se establezca
            connectToPeer(peer)
            // Guardar el timbre para enviarlo cuando se conecte
            pendingTimbreToSend = (timbre, peerID)
            print("📡 [Radar P2P] ⏳ Conectando a \(peer.businessName) — timbre en cola")
        }
    }

    /// Timbre pendiente de envío (esperando conexión)
    private var pendingTimbreToSend: (timbre: TimbreEvent, peer: MCPeerID)?

    /// Envía respuesta de timbre al cliente
    func sendResponseP2P(_ response: TimbreResponse, to peerID: MCPeerID) {
        sendP2P(.timbreResponse(response), to: peerID)
    }

    /// Busca el peerID de un merchant por nombre
    func peerForMerchant(named name: String) -> MCPeerID? {
        peerMerchantMap.first(where: { $0.value == name })?.key
    }

    // MARK: - Internal

    private func pruneAndUpdateSignals() {
        DispatchQueue.main.async {
            let now = Date()

            // Remover stale (>90s sin ver)
            self.discoveredMerchants.removeAll { $0.isStale }

            // Actualizar signal strength
            for i in self.discoveredMerchants.indices {
                let elapsed = now.timeIntervalSince(self.discoveredMerchants[i].lastSeen)
                if elapsed < 15 {
                    self.discoveredMerchants[i].signalStrength = .strong
                } else if elapsed < 45 {
                    self.discoveredMerchants[i].signalStrength = .medium
                } else {
                    self.discoveredMerchants[i].signalStrength = .weak
                }
            }
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate (Client descubre merchants)

extension RadarService: MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        let name = info?["name"] ?? peerID.displayName
        let category = info?["cat"] ?? "otro"
        let emoji = info?["emoji"] ?? "🛒"
        let isStatic = info?["static"] == "1"

        print("📍 [Radar] Descubierto: \(emoji) \(name) (\(category))")

        DispatchQueue.main.async {
            // Si ya existe, actualizar lastSeen
            if let index = self.discoveredMerchants.firstIndex(where: { $0.peerID == peerID }) {
                self.discoveredMerchants[index].lastSeen = Date()
                self.discoveredMerchants[index].signalStrength = .strong
            } else {
                // Nuevo merchant descubierto
                let peer = RadarPeer(
                    id: peerID.displayName,
                    peerID: peerID,
                    businessName: name,
                    category: category,
                    emoji: emoji,
                    isStatic: isStatic,
                    lastSeen: Date(),
                    signalStrength: .strong
                )
                self.discoveredMerchants.append(peer)

                // Haptic feedback al descubrir nuevo
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }

            self.radarStatus = "\(self.activeMerchantCount) comerciantes cerca"
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("👋 [Radar] Perdido: \(peerID.displayName)")

        DispatchQueue.main.async {
            // No remover inmediatamente — marcar como weak y dejar que prune lo limpie
            if let index = self.discoveredMerchants.firstIndex(where: { $0.peerID == peerID }) {
                self.discoveredMerchants[index].signalStrength = .weak
            }
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate (Merchant recibe invitaciones)

extension RadarService: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Aceptar invitaciones de timbre
        let contextStr = context.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        if contextStr == "timbre" {
            print("📡 [Radar P2P] 📥 Invitación de timbre aceptada de \(peerID.displayName)")
            invitationHandler(true, self.session)
        } else {
            // Aceptar todas las demás también (para flexibilidad)
            print("📡 [Radar P2P] 📥 Invitación aceptada de \(peerID.displayName) (contexto: \(contextStr))")
            invitationHandler(true, self.session)
        }
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("❌ [Radar] Error al anunciar: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.radarStatus = "Error: \(error.localizedDescription)"
            self.isAdvertising = false
        }
    }
}

// MARK: - MCSessionDelegate (P2P data exchange)

extension RadarService: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
                print("📡 [Radar P2P] 🤝 Conectado con \(peerID.displayName)")

                // Si hay un timbre pendiente de envío, enviarlo ahora
                if let pending = self.pendingTimbreToSend, pending.peer == peerID {
                    self.sendP2P(.timbreEvent(pending.timbre), to: peerID)
                    self.pendingTimbreToSend = nil
                }

            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                print("📡 [Radar P2P] 👋 Desconectado de \(peerID.displayName)")

            case .connecting:
                print("📡 [Radar P2P] ⏳ Conectando con \(peerID.displayName)...")

            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let message = try JSONDecoder().decode(TimbreP2PMessage.self, from: data)
            print("📡 [Radar P2P] 📨 Mensaje recibido de \(peerID.displayName) (\(data.count) bytes)")

            DispatchQueue.main.async {
                switch message {
                case .timbreEvent(let timbre):
                    // Soy merchant, recibí un timbre de un cliente
                    TimbreManager.shared.receiveTimbre(timbre)
                    // Guardar mapping para poder responder
                    self.peerMerchantMap[peerID] = timbre.clientName

                case .timbreResponse(let response):
                    // Soy cliente, recibí respuesta del merchant
                    TimbreManager.shared.receiveResponse(response)
                }
            }
        } catch {
            print("📡 [Radar P2P] ❌ Error decodificando mensaje: \(error.localizedDescription)")
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
