import Foundation
import UIKit
internal import Combine
import CoreBluetooth
import NearbyInteraction

// MARK: - GATT UUIDs (Atenea Pay Service)

private let kServiceUUID  = CBUUID(string: "A7B3C2D1-E4F5-4A6B-8C7D-9E0F1A2B3C4D")
private let kCharMToken   = CBUUID(string: "A7B3C2D1-0001-4A6B-8C7D-9E0F1A2B3C4D") // merchant NI token (read)
private let kCharCToken   = CBUUID(string: "A7B3C2D1-0002-4A6B-8C7D-9E0F1A2B3C4D") // customer NI token (write)
private let kCharPayInfo  = CBUUID(string: "A7B3C2D1-0003-4A6B-8C7D-9E0F1A2B3C4D") // payment info JSON (read)
private let kCharConfirm  = CBUUID(string: "A7B3C2D1-0004-4A6B-8C7D-9E0F1A2B3C4D") // confirmation (notify)

// MARK: - Role

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

    private let tapThreshold: Float = 0.30  // 30 cm
    private var hasTriggered = false
    private var isActive = false

    var onPaymentTriggered: (() -> Void)?

    // MARK: - CoreBluetooth — Peripheral (Merchant)

    private var peripheralManager: CBPeripheralManager?
    private var charConfirmMutable: CBMutableCharacteristic?

    // MARK: - CoreBluetooth — Central (Customer)

    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var merchantTokenData: Data?

    // MARK: - NearbyInteraction

    private var niSession: NISession?

    // MARK: - Init

    init(role: TapToPayRole, amount: Int? = nil, merchantName: String? = nil, description: String? = nil) {
        self.role = role
        self.amount = amount
        self.merchantName = merchantName
        self.paymentDescription = description
        super.init()
    }

    // MARK: - Start / Stop

    func start() {
        guard !isActive else {
            print("[TapToPay] ⚠️ start() ignorado — ya activo")
            return
        }
        isActive = true
        print("[TapToPay] ▶️ start() role=\(role.rawValue)")

        niSession = NISession()
        niSession?.delegate = self
        print("[TapToPay] NISession creado — token: \(niSession?.discoveryToken != nil ? "OK" : "nil (sin UWB)")")

        if role == .merchant {
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
            print("[TapToPay] Merchant: CBPeripheralManager creado, esperando .poweredOn")
        } else {
            centralManager = CBCentralManager(delegate: self, queue: nil)
            print("[TapToPay] Customer: CBCentralManager creado, esperando .poweredOn")
        }
    }

    func stop() {
        print("[TapToPay] ⏹ stop() role=\(role.rawValue) isActive=\(isActive)")
        isActive = false
        hasTriggered = false

        niSession?.invalidate()
        niSession = nil

        peripheralManager?.stopAdvertising()
        peripheralManager = nil
        charConfirmMutable = nil

        if let p = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(p)
        }
        centralManager?.stopScan()
        centralManager = nil
        connectedPeripheral = nil
        merchantTokenData = nil

        DispatchQueue.main.async {
            self.phase = .preparing
            self.isConnected = false
            self.peerDistance = nil
        }
    }

    // MARK: - Merchant: enviar confirmación por BLE notify

    private var pendingConfirmationData: Data?

    func sendConfirmation(approved: Bool) {
        print("[TapToPay] Merchant: enviando confirmación BLE approved=\(approved)")
        guard let char = charConfirmMutable,
              let manager = peripheralManager else {
            print("[TapToPay] ⚠️ sendConfirmation: peripheralManager o char nil")
            return
        }
        let payload: [String: Any] = ["approved": approved]
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        pendingConfirmationData = data
        let sent = manager.updateValue(data, for: char, onSubscribedCentrals: nil)
        print("[TapToPay] Merchant: notify enviado=\(sent) — si false, se reintentará en peripheralManagerIsReady")
        if sent { pendingConfirmationData = nil }
    }

    // Retry automático cuando la cola BLE está lista (updateValue retornó false)
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        guard let data = pendingConfirmationData,
              let char = charConfirmMutable else { return }
        print("[TapToPay] Merchant: reintentando notify (cola BLE liberada)")
        let sent = peripheral.updateValue(data, for: char, onSubscribedCentrals: nil)
        print("[TapToPay] Merchant: retry notify enviado=\(sent)")
        if sent { pendingConfirmationData = nil }
    }

    // MARK: - Merchant: construir servicio GATT

    private func buildGATTService() {
        guard let niToken = niSession?.discoveryToken else {
            print("[TapToPay] ⚠️ buildGATTService: discoveryToken nil — NI no disponible en este dispositivo")
            return
        }
        guard let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: niToken, requiringSecureCoding: true) else {
            print("[TapToPay] ⚠️ buildGATTService: no se pudo archivar NI token")
            return
        }
        print("[TapToPay] Merchant: NI token archivado (\(tokenData.count) bytes)")

        // Payment info JSON
        let payInfo: [String: Any] = [
            "merchantName": merchantName ?? "Comerciante",
            "amount": amount ?? 0,
            "description": paymentDescription ?? ""
        ]
        let payInfoData = (try? JSONSerialization.data(withJSONObject: payInfo)) ?? Data()
        print("[TapToPay] Merchant: payInfo (\(payInfoData.count) bytes) — \(merchantName ?? "?") \(amount ?? 0)¢")

        // Characteristic: merchant NI token — valor estático, se responde automáticamente
        let charMerchantToken = CBMutableCharacteristic(
            type: kCharMToken,
            properties: [.read],
            value: tokenData,
            permissions: [.readable]
        )

        // Characteristic: customer NI token — el customer escribe aquí
        let charCustomerToken = CBMutableCharacteristic(
            type: kCharCToken,
            properties: [.write],
            value: nil,
            permissions: [.writeable]
        )

        // Characteristic: payment info — valor estático
        let charPayInfoChar = CBMutableCharacteristic(
            type: kCharPayInfo,
            properties: [.read],
            value: payInfoData,
            permissions: [.readable]
        )

        // Characteristic: confirmation notify — el merchant pushea el resultado
        charConfirmMutable = CBMutableCharacteristic(
            type: kCharConfirm,
            properties: [.notify],
            value: nil,
            permissions: [.readable]
        )

        let service = CBMutableService(type: kServiceUUID, primary: true)
        service.characteristics = [charMerchantToken, charCustomerToken, charPayInfoChar, charConfirmMutable!]
        peripheralManager?.add(service)
        print("[TapToPay] Merchant: servicio GATT agregado al manager")
    }

    // MARK: - Customer: iniciar NI con token del merchant

    private func startNIWithMerchantToken(_ data: Data) {
        guard let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) else {
            print("[TapToPay] ⚠️ Customer: no se pudo deserializar NIDiscoveryToken del merchant")
            return
        }
        let config = NINearbyPeerConfiguration(peerToken: token)
        niSession?.run(config)
        print("[TapToPay] Customer: NISession.run() — UWB midiendo distancia")
    }

    // MARK: - Customer: escribir token propio al merchant

    private func writeCustomerToken(to peripheral: CBPeripheral) {
        guard let niToken = niSession?.discoveryToken,
              let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: niToken, requiringSecureCoding: true),
              let service = peripheral.services?.first(where: { $0.uuid == kServiceUUID }),
              let char = service.characteristics?.first(where: { $0.uuid == kCharCToken })
        else {
            print("[TapToPay] ⚠️ Customer: writeCustomerToken — prerequisitos no listos")
            return
        }
        print("[TapToPay] Customer: escribiendo token NI propio (\(tokenData.count) bytes) → CHAR_C_TOKEN")
        peripheral.writeValue(tokenData, for: char, type: .withResponse)
    }
}

// MARK: - CBPeripheralManagerDelegate (Merchant)

extension TapToPayPeerService: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        let stateStr: String
        switch peripheral.state {
        case .poweredOn:   stateStr = "poweredOn"
        case .poweredOff:  stateStr = "poweredOff"
        case .unauthorized: stateStr = "unauthorized"
        case .unsupported: stateStr = "unsupported"
        case .resetting:   stateStr = "resetting"
        case .unknown:     stateStr = "unknown"
        @unknown default:  stateStr = "unknown"
        }
        print("[TapToPay] Merchant: CBPeripheralManager state=\(stateStr)")

        switch peripheral.state {
        case .poweredOn:
            buildGATTService()
        case .poweredOff:
            print("[TapToPay] ⚠️ Bluetooth apagado — activa Bluetooth en Settings")
        case .unauthorized:
            print("[TapToPay] ⚠️ Bluetooth no autorizado — revisa permisos en Settings > Privacidad > Bluetooth")
        default:
            break
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error {
            print("[TapToPay] ⚠️ Merchant: error agregando servicio — \(error.localizedDescription)")
            return
        }
        print("[TapToPay] Merchant: servicio agregado OK — iniciando advertising")
        peripheral.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [kServiceUUID],
            CBAdvertisementDataLocalNameKey: "AtenPay"
        ])
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error {
            print("[TapToPay] ⚠️ Merchant: error al anunciar — \(error.localizedDescription)")
        } else {
            print("[TapToPay] Merchant: advertising activo — esperando customer")
            DispatchQueue.main.async { self.phase = .waitingForCard }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            print("[TapToPay] Merchant: write en \(request.characteristic.uuid) — \(request.value?.count ?? 0) bytes")

            guard request.characteristic.uuid == kCharCToken, let data = request.value else {
                peripheral.respond(to: request, withResult: .attributeNotFound)
                continue
            }

            peripheral.respond(to: request, withResult: .success)
            print("[TapToPay] Merchant: token del customer recibido — respondido .success")

            guard let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) else {
                print("[TapToPay] ⚠️ Merchant: no se pudo deserializar NIDiscoveryToken del customer")
                continue
            }
            let config = NINearbyPeerConfiguration(peerToken: token)
            niSession?.run(config)
            print("[TapToPay] Merchant: NISession.run() — UWB midiendo distancia")
            DispatchQueue.main.async { self.isConnected = true }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("[TapToPay] Merchant: central subscrito a \(characteristic.uuid) — listo para enviar confirmación")
        DispatchQueue.main.async { self.isConnected = true }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("[TapToPay] Merchant: central desuscrito de \(characteristic.uuid)")
    }
}

// MARK: - CBCentralManagerDelegate (Customer)

extension TapToPayPeerService: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let stateStr: String
        switch central.state {
        case .poweredOn:    stateStr = "poweredOn"
        case .poweredOff:   stateStr = "poweredOff"
        case .unauthorized: stateStr = "unauthorized"
        case .unsupported:  stateStr = "unsupported"
        case .resetting:    stateStr = "resetting"
        case .unknown:      stateStr = "unknown"
        @unknown default:   stateStr = "unknown"
        }
        print("[TapToPay] Customer: CBCentralManager state=\(stateStr)")

        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: [kServiceUUID], options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false
            ])
            print("[TapToPay] Customer: scan BLE iniciado para SERVICE_UUID")
            DispatchQueue.main.async { self.phase = .preparing }
        case .poweredOff:
            print("[TapToPay] ⚠️ Bluetooth apagado")
        case .unauthorized:
            print("[TapToPay] ⚠️ Bluetooth no autorizado")
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "?"
        print("[TapToPay] Customer: peripheral descubierto '\(name)' RSSI=\(RSSI) dBm")
        central.stopScan()
        print("[TapToPay] Customer: scan detenido — conectando a '\(name)'")
        connectedPeripheral = peripheral
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("[TapToPay] Customer: ✅ conectado a '\(peripheral.name ?? peripheral.identifier.uuidString)'")
        peripheral.discoverServices([kServiceUUID])
        print("[TapToPay] Customer: descubriendo servicios...")
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("[TapToPay] ⚠️ Customer: falló conexión — \(error?.localizedDescription ?? "unknown")")
        if isActive && !hasTriggered {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                guard self.isActive && !self.hasTriggered else { return }
                central.scanForPeripherals(withServices: [kServiceUUID], options: nil)
                print("[TapToPay] Customer: reintentando scan en 2s")
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("[TapToPay] Customer: desconectado de '\(peripheral.name ?? "?")' — \(error?.localizedDescription ?? "ok")")
        DispatchQueue.main.async { self.isConnected = false }
    }
}

// MARK: - CBPeripheralDelegate (Customer)

extension TapToPayPeerService: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            print("[TapToPay] ⚠️ Customer: error descubriendo servicios — \(error.localizedDescription)")
            return
        }
        guard let service = peripheral.services?.first(where: { $0.uuid == kServiceUUID }) else {
            print("[TapToPay] ⚠️ Customer: SERVICE_UUID no encontrado en el peripheral")
            return
        }
        print("[TapToPay] Customer: servicio GATT encontrado — descubriendo características")
        peripheral.discoverCharacteristics([kCharMToken, kCharCToken, kCharPayInfo, kCharConfirm], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            print("[TapToPay] ⚠️ Customer: error descubriendo características — \(error.localizedDescription)")
            return
        }
        let uuids = service.characteristics?.map { $0.uuid.uuidString.prefix(8) } ?? []
        print("[TapToPay] Customer: \(service.characteristics?.count ?? 0) características — \(uuids)")

        for char in service.characteristics ?? [] {
            switch char.uuid {
            case kCharConfirm:
                peripheral.setNotifyValue(true, for: char)
                print("[TapToPay] Customer: subscrito a CHAR_CONFIRM (notify)")
            case kCharMToken:
                peripheral.readValue(for: char)
                print("[TapToPay] Customer: leyendo CHAR_M_TOKEN...")
            case kCharPayInfo:
                peripheral.readValue(for: char)
                print("[TapToPay] Customer: leyendo CHAR_PAY_INFO...")
            default:
                break
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            print("[TapToPay] ⚠️ Customer: error en didUpdateValue \(characteristic.uuid) — \(error.localizedDescription)")
            return
        }
        guard let data = characteristic.value else {
            print("[TapToPay] ⚠️ Customer: valor nil en \(characteristic.uuid)")
            return
        }
        print("[TapToPay] Customer: valor recibido para \(characteristic.uuid) — \(data.count) bytes")

        switch characteristic.uuid {

        case kCharMToken:
            print("[TapToPay] Customer: merchant NI token recibido (\(data.count) bytes)")
            merchantTokenData = data
            // Escribir nuestro token al merchant ahora que tenemos el suyo
            writeCustomerToken(to: peripheral)

        case kCharPayInfo:
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                DispatchQueue.main.async {
                    self.receivedMerchantName = json["merchantName"] as? String
                    self.receivedAmount       = json["amount"] as? Int
                    self.receivedDescription  = json["description"] as? String
                }
                print("[TapToPay] Customer: payInfo — '\(json["merchantName"] ?? "?")' \(json["amount"] ?? 0)¢")
            }

        case kCharConfirm:
            // Confirmación del merchant (notify)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let approved = json["approved"] as? Bool ?? false
                print("[TapToPay] Customer: 🔔 confirmación recibida — approved=\(approved) hasTriggered=\(self.hasTriggered)")
                DispatchQueue.main.async {
                    if approved && !self.hasTriggered {
                        self.hasTriggered = true
                        self.phase = .processing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            print("[TapToPay] Customer: llamando onPaymentTriggered")
                            self.onPaymentTriggered?()
                        }
                    } else if !approved {
                        self.phase = .declined("Pago rechazado")
                    }
                }
            }

        default:
            break
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            print("[TapToPay] ⚠️ Customer: error escribiendo \(characteristic.uuid) — \(error.localizedDescription)")
            return
        }
        print("[TapToPay] Customer: ✅ CHAR_C_TOKEN escrito — iniciando UWB")
        // Token enviado al merchant → arrancar NI con el token del merchant
        if let data = merchantTokenData {
            startNIWithMerchantToken(data)
        }
        DispatchQueue.main.async { self.phase = .waitingForCard }
    }
}

// MARK: - NISessionDelegate

extension TapToPayPeerService: NISessionDelegate {

    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let peer = nearbyObjects.first, let distance = peer.distance else {
            print("[TapToPay] NI: update sin distancia")
            return
        }
        print("[TapToPay] NI distancia: \(String(format: "%.1f", distance * 100))cm | umbral=\(tapThreshold * 100)cm | triggered=\(hasTriggered)")

        DispatchQueue.main.async {
            self.peerDistance = distance
            guard distance < self.tapThreshold, !self.hasTriggered else { return }
            print("[TapToPay] 🎯 TAP detectado (\(String(format: "%.1f", distance * 100))cm) — disparando pago")
            self.hasTriggered = true
            self.phase = .reading
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.phase = .processing
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.onPaymentTriggered?()
                }
            }
        }
    }

    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        print("[TapToPay] NI: peer removido — razón=\(reason.rawValue)")
        DispatchQueue.main.async { self.peerDistance = nil }
    }

    func session(_ session: NISession, didInvalidateWith error: Error) {
        print("[TapToPay] ⚠️ NISession invalidada: \(error.localizedDescription)")
    }

    func sessionWasSuspended(_ session: NISession) {
        print("[TapToPay] NI: sesión suspendida (app en background?)")
    }

    func sessionSuspensionEnded(_ session: NISession) {
        print("[TapToPay] NI: suspensión terminada")
    }
}
