import Foundation
internal import Combine
import NearbyInteraction
import MultipeerConnectivity

// MARK: - Payment Data exchanged via MPC

struct TapToPayPeerData: Codable {
    let niTokenData: Data
    let role: TapToPayRole
    let merchantName: String?
    let amount: Int?
    let description: String?
}

enum TapToPayRole: String, Codable {
    case merchant
    case customer
}

// MARK: - TapToPayPeerService

class TapToPayPeerService: NSObject, ObservableObject {

    // MARK: - Published State

    @Published var phase: TapToPayPhase = .preparing
    @Published var peerDistance: Float?
    @Published var isConnected = false
    @Published var receivedMerchantName: String?
    @Published var receivedAmount: Int?
    @Published var receivedDescription: String?

    // MARK: - Config

    let role: TapToPayRole
    let amount: Int?
    let merchantName: String?
    let paymentDescription: String?

    private let tapThreshold: Float = 0.06 // 6cm — distancia de "tap"
    private var hasTriggered = false

    var onPaymentTriggered: (() -> Void)?

    // MARK: - NI + MPC

    private var niSession: NISession?
    private let serviceType = "atenea-pay"
    private var myPeerID: MCPeerID
    private var mpcSession: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var connectedPeer: MCPeerID?

    // MARK: - Init

    init(role: TapToPayRole, amount: Int? = nil, merchantName: String? = nil, description: String? = nil) {
        self.role = role
        self.amount = amount
        self.merchantName = merchantName
        self.paymentDescription = description
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
    }

    // MARK: - Start / Stop

    func start() {
        niSession = NISession()
        niSession?.delegate = self

        mpcSession = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        mpcSession?.delegate = self

        if role == .merchant {
            advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: ["type": "pay"], serviceType: serviceType)
            advertiser?.delegate = self
            advertiser?.startAdvertisingPeer()
            DispatchQueue.main.async {
                self.phase = .waitingForCard
            }
        } else {
            browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
            browser?.delegate = self
            browser?.startBrowsingForPeers()
            DispatchQueue.main.async {
                self.phase = .preparing
            }
        }
    }

    func stop() {
        niSession?.invalidate()
        niSession = nil
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        mpcSession?.disconnect()
        connectedPeer = nil
        hasTriggered = false
    }

    // MARK: - Send NI Token + Payment Info

    private func sendDataToPeer(_ peer: MCPeerID) {
        guard let token = niSession?.discoveryToken,
              let mpcSession else { return }

        do {
            let tokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
            let payload = TapToPayPeerData(
                niTokenData: tokenData,
                role: role,
                merchantName: role == .merchant ? merchantName : nil,
                amount: role == .merchant ? amount : nil,
                description: role == .merchant ? paymentDescription : nil
            )
            let encoded = try JSONEncoder().encode(payload)
            try mpcSession.send(encoded, toPeers: [peer], with: .reliable)
        } catch {
            print("[TapToPay] Error sending data: \(error)")
        }
    }

    // MARK: - Send Payment Confirmation back to peer

    func sendConfirmation(approved: Bool) {
        guard let peer = connectedPeer,
              let mpcSession else { return }

        let confirmation: [String: Any] = [
            "type": "confirmation",
            "approved": approved
        ]
        if let data = try? JSONSerialization.data(withJSONObject: confirmation) {
            try? mpcSession.send(data, toPeers: [peer], with: .reliable)
        }
    }
}

// MARK: - NISessionDelegate

extension TapToPayPeerService: NISessionDelegate {

    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let peer = nearbyObjects.first,
              let distance = peer.distance else { return }

        DispatchQueue.main.async {
            self.peerDistance = distance

            if distance < self.tapThreshold && !self.hasTriggered {
                self.hasTriggered = true
                self.phase = .reading

                // Haptic — simula la vibración del tap real
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred()

                // Pequeño delay para la animación de "leyendo"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    self.phase = .processing

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.onPaymentTriggered?()
                    }
                }
            }
        }
    }

    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        DispatchQueue.main.async {
            self.peerDistance = nil
        }
    }

    func sessionWasSuspended(_ session: NISession) {}
    func sessionSuspensionEnded(_ session: NISession) {
        if let peer = connectedPeer {
            sendDataToPeer(peer)
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate (Merchant)

extension TapToPayPeerService: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, self.mpcSession)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate (Customer)

extension TapToPayPeerService: MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard let mpcSession else { return }
        browser.invitePeer(peerID, to: mpcSession, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}

// MARK: - MCSessionDelegate

extension TapToPayPeerService: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.isConnected = true
                self.connectedPeer = peerID

                if self.role == .customer {
                    self.phase = .waitingForCard
                }

                // Send NI token
                self.sendDataToPeer(peerID)

                self.advertiser?.stopAdvertisingPeer()
                self.browser?.stopBrowsingForPeers()

            case .notConnected:
                self.isConnected = false
                if self.role == .merchant && !self.hasTriggered {
                    self.advertiser?.startAdvertisingPeer()
                }
            default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Try to decode as payment data (NI token + info)
        if let peerData = try? JSONDecoder().decode(TapToPayPeerData.self, from: data) {
            // Start NI session with peer's token
            if let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: peerData.niTokenData) {
                let config = NINearbyPeerConfiguration(peerToken: token)
                self.niSession?.run(config)
            }

            // If we're customer, store the merchant's payment info
            if peerData.role == .merchant {
                DispatchQueue.main.async {
                    self.receivedMerchantName = peerData.merchantName
                    self.receivedAmount = peerData.amount
                    self.receivedDescription = peerData.description
                }
            }
        }

        // Try to decode as confirmation
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           json["type"] as? String == "confirmation" {
            DispatchQueue.main.async {
                let approved = json["approved"] as? Bool ?? false
                self.phase = approved ? .approved : .declined("Pago rechazado")
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
