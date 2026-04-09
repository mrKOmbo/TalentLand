//
//  RadarService.swift
//  atenea
//
//  Servicio de radar BLE dual-role inspirado en bitchat.
//  Merchants se anuncian via CBPeripheralManager, clientes descubren via CBCentralManager.
//  Data exchange (timbres) via GATT characteristic write + notify.
//  Funciona en background con bluetooth-central/peripheral modes.
//

import Foundation
internal import Combine
import CoreBluetooth
import SwiftUI

// MARK: - BLE UUIDs (Atenea)

struct AteneaBLE {
    static let serviceUUID = CBUUID(string: "A1E2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D")
    static let timbreCharUUID = CBUUID(string: "B2F3D4E5-F6A7-5B6C-9D0E-1F2A3B4C5D6E")

    static let centralRestoreKey = "com.atenea.ble.central"
    static let peripheralRestoreKey = "com.atenea.ble.peripheral"

    // Duty cycling
    static let scanOnDuration: TimeInterval = 5.0
    static let scanOffDuration: TimeInterval = 10.0
    static let pruneInterval: TimeInterval = 10.0
    static let staleTimeout: TimeInterval = 90.0
}

// MARK: - Discovered Peer (BLE)

struct RadarPeer: Identifiable, Equatable {
    let id: String                     // peripheral.identifier.uuidString
    var peripheral: CBPeripheral?      // referencia para conexión y write
    let businessName: String
    let category: String
    let emoji: String
    let isStatic: Bool
    var lastSeen: Date
    var signalStrength: SignalStrength
    var rssi: Int                      // RSSI real del BLE scan

    enum SignalStrength: String {
        case strong = "strong"
        case medium = "medium"
        case weak = "weak"

        var color: SwiftUI.Color {
            switch self {
            case .strong: return .green
            case .medium: return .yellow
            case .weak: return .orange
            }
        }

        static func from(rssi: Int) -> SignalStrength {
            if rssi > -60 { return .strong }
            if rssi > -80 { return .medium }
            return .weak
        }
    }

    var isStale: Bool {
        Date().timeIntervalSince(lastSeen) > AteneaBLE.staleTimeout
    }

    static func == (lhs: RadarPeer, rhs: RadarPeer) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Radar Service (CoreBluetooth dual-role)

class RadarService: NSObject, ObservableObject {
    static let shared = RadarService()

    // MARK: - Published State (misma API pública — consumidores no cambian)

    @Published var discoveredMerchants: [RadarPeer] = []
    @Published var isScanning = false
    @Published var isAdvertising = false
    @Published var radarStatus: String = "Inactivo"

    // Mapeo peerID string → nombre para rutear respuestas
    var peerMerchantMap: [String: String] = [:]

    // MARK: - CoreBluetooth Managers

    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    private let bleQueue = DispatchQueue(label: "com.atenea.ble.queue", qos: .userInitiated)

    // Peripheral state (merchant)
    private var timbreCharacteristic: CBMutableCharacteristic?
    private var timbreService: CBMutableService?
    private var subscribedCentrals: [CBCentral] = []
    private var currentMerchantInfo: String?

    // Central state (client)
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    private var connectedPeripheral: CBPeripheral?
    private var remoteTimbreCharacteristic: CBCharacteristic?

    // Timers
    private var scanDutyTimer: Timer?
    private var pruneTimer: Timer?
    private var isScanDutyOn = true

    // Pending operations
    private var pendingTimbreToSend: (data: Data, peripheral: CBPeripheral)?
    private var pendingScanStart = false
    private var pendingAdvertiseInfo: String?

    // MARK: - Init

    private override init() {
        super.init()
        centralManager = CBCentralManager(
            delegate: self,
            queue: bleQueue,
            options: [CBCentralManagerOptionRestoreIdentifierKey: AteneaBLE.centralRestoreKey]
        )
        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: bleQueue,
            options: [CBPeripheralManagerOptionRestoreIdentifierKey: AteneaBLE.peripheralRestoreKey]
        )
        print("📡 [BLE] RadarService inicializado con CoreBluetooth dual-role")
    }

    // MARK: - Merchant: Anunciarse via BLE Peripheral

    func startAdvertising(merchant: Merchant) {
        stopAdvertising()

        let name = String(merchant.businessName.prefix(20))
        let info = "\(merchant.emoji)|\(name)|\(merchant.category.rawValue)|\(merchant.isStatic ? "1" : "0")"
        currentMerchantInfo = info

        guard peripheralManager.state == .poweredOn else {
            pendingAdvertiseInfo = info
            print("📡 [BLE Periph] ⏳ Esperando poweredOn para anunciar: \(name)")
            return
        }

        setupPeripheralService()
        startPeripheralAdvertising(info: info)
    }

    func stopAdvertising() {
        peripheralManager.stopAdvertising()
        if let service = timbreService {
            peripheralManager.remove(service)
        }
        timbreService = nil
        timbreCharacteristic = nil
        subscribedCentrals.removeAll()
        currentMerchantInfo = nil
        pendingAdvertiseInfo = nil

        DispatchQueue.main.async {
            self.isAdvertising = false
            if !self.isScanning {
                self.radarStatus = "Inactivo"
            }
        }
        print("📡 [BLE Periph] Dejó de anunciarse")
    }

    private func setupPeripheralService() {
        let characteristic = CBMutableCharacteristic(
            type: AteneaBLE.timbreCharUUID,
            properties: [.write, .writeWithoutResponse, .notify],
            value: nil,
            permissions: [.writeable]
        )
        timbreCharacteristic = characteristic

        let service = CBMutableService(type: AteneaBLE.serviceUUID, primary: true)
        service.characteristics = [characteristic]
        timbreService = service

        peripheralManager.add(service)
        print("📡 [BLE Periph] GATT service agregado")
    }

    private func startPeripheralAdvertising(info: String) {
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [AteneaBLE.serviceUUID],
            CBAdvertisementDataLocalNameKey: info
        ])
        DispatchQueue.main.async {
            self.isAdvertising = true
            let name = info.components(separatedBy: "|").dropFirst().first ?? "merchant"
            self.radarStatus = "Anunciando: \(name)"
        }
        print("📡 [BLE Periph] Anunciando: \(info)")
    }

    // MARK: - Client: Escanear via BLE Central

    func startScanning() {
        stopScanning()

        guard centralManager.state == .poweredOn else {
            pendingScanStart = true
            print("🔍 [BLE Central] ⏳ Esperando poweredOn para escanear")
            return
        }

        beginScan()
    }

    private func beginScan() {
        centralManager.scanForPeripherals(
            withServices: [AteneaBLE.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )

        scanDutyTimer?.invalidate()
        scanDutyTimer = Timer.scheduledTimer(withTimeInterval: AteneaBLE.scanOnDuration, repeats: false) { [weak self] _ in
            self?.dutyCyclePause()
        }

        pruneTimer?.invalidate()
        pruneTimer = Timer.scheduledTimer(withTimeInterval: AteneaBLE.pruneInterval, repeats: true) { [weak self] _ in
            self?.pruneAndUpdateSignals()
        }

        isScanDutyOn = true
        DispatchQueue.main.async {
            self.isScanning = true
            self.radarStatus = "Escaneando..."
        }
        print("🔍 [BLE Central] Escaneando merchants...")
    }

    private func dutyCyclePause() {
        guard isScanning else { return }
        centralManager.stopScan()
        isScanDutyOn = false

        scanDutyTimer = Timer.scheduledTimer(withTimeInterval: AteneaBLE.scanOffDuration, repeats: false) { [weak self] _ in
            self?.dutyCycleResume()
        }
    }

    private func dutyCycleResume() {
        guard isScanning else { return }
        centralManager.scanForPeripherals(
            withServices: [AteneaBLE.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        isScanDutyOn = true

        scanDutyTimer = Timer.scheduledTimer(withTimeInterval: AteneaBLE.scanOnDuration, repeats: false) { [weak self] _ in
            self?.dutyCyclePause()
        }
    }

    func stopScanning() {
        centralManager.stopScan()
        scanDutyTimer?.invalidate()
        scanDutyTimer = nil
        pruneTimer?.invalidate()
        pruneTimer = nil
        pendingScanStart = false

        DispatchQueue.main.async {
            self.isScanning = false
            if !self.isAdvertising {
                self.radarStatus = "Inactivo"
            }
        }
        print("🔍 [BLE Central] Dejó de escanear")
    }

    // MARK: - Stop All

    func stopAll() {
        stopAdvertising()
        stopScanning()

        for (_, peripheral) in discoveredPeripherals {
            if peripheral.state == .connected || peripheral.state == .connecting {
                centralManager.cancelPeripheralConnection(peripheral)
            }
        }
        discoveredPeripherals.removeAll()
        connectedPeripheral = nil
        remoteTimbreCharacteristic = nil

        DispatchQueue.main.async {
            self.discoveredMerchants.removeAll()
            self.peerMerchantMap.removeAll()
            self.radarStatus = "Inactivo"
        }
    }

    // MARK: - Queries

    var activeMerchantCount: Int {
        discoveredMerchants.filter { !$0.isStale }.count
    }

    var nearbyMerchantNames: [String] {
        discoveredMerchants.filter { !$0.isStale }.map(\.businessName)
    }

    // MARK: - P2P Timbre via GATT

    /// Cliente envía timbre al merchant via BLE write
    func sendTimbreP2P(_ timbre: TimbreEvent, to peer: RadarPeer) {
        guard let peripheral = peer.peripheral else {
            print("📡 [BLE P2P] ❌ No hay peripheral para \(peer.businessName)")
            return
        }

        do {
            let message = TimbreP2PMessage.timbreEvent(timbre)
            let data = try JSONEncoder().encode(message)

            if peripheral.state == .connected, let char = remoteTimbreCharacteristic {
                peripheral.writeValue(data, for: char, type: .withResponse)
                print("📡 [BLE P2P] ✅ Timbre enviado a \(peer.businessName) (\(data.count) bytes)")
            } else {
                pendingTimbreToSend = (data, peripheral)
                centralManager.connect(peripheral, options: nil)
                print("📡 [BLE P2P] ⏳ Conectando a \(peer.businessName) para enviar timbre...")
            }
        } catch {
            print("📡 [BLE P2P] ❌ Error codificando timbre: \(error)")
        }
    }

    /// Merchant envía respuesta al cliente via BLE notify
    func sendResponseP2P(_ response: TimbreResponse, to peerID: String) {
        guard let char = timbreCharacteristic else {
            print("📡 [BLE P2P] ❌ No hay characteristic para responder")
            return
        }

        do {
            let message = TimbreP2PMessage.timbreResponse(response)
            let data = try JSONEncoder().encode(message)

            let sent = peripheralManager.updateValue(data, for: char, onSubscribedCentrals: nil)
            print("📡 [BLE P2P] \(sent ? "✅" : "⏳") Respuesta \(sent ? "enviada" : "en cola") (\(data.count) bytes)")
        } catch {
            print("📡 [BLE P2P] ❌ Error codificando respuesta: \(error)")
        }
    }

    // MARK: - Internal

    private func pruneAndUpdateSignals() {
        DispatchQueue.main.async {
            self.discoveredMerchants.removeAll { $0.isStale }
        }
    }

    private func parseAdvertisementName(_ localName: String) -> (emoji: String, name: String, category: String, isStatic: Bool)? {
        let parts = localName.components(separatedBy: "|")
        guard parts.count >= 4 else { return nil }
        return (emoji: parts[0], name: parts[1], category: parts[2], isStatic: parts[3] == "1")
    }
}

// MARK: - CBCentralManagerDelegate (Cliente descubre merchants)

extension RadarService: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("🔍 [BLE Central] Estado: \(central.state.rawValue)")
        if central.state == .poweredOn && pendingScanStart {
            pendingScanStart = false
            beginScan()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let rssiValue = RSSI.intValue
        guard rssiValue != 127, rssiValue < 0 else { return }

        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? ""
        guard let info = parseAdvertisementName(localName) else { return }

        let peerId = peripheral.identifier.uuidString

        DispatchQueue.main.async {
            self.discoveredPeripherals[peripheral.identifier] = peripheral

            if let index = self.discoveredMerchants.firstIndex(where: { $0.id == peerId }) {
                self.discoveredMerchants[index].lastSeen = Date()
                self.discoveredMerchants[index].rssi = rssiValue
                self.discoveredMerchants[index].signalStrength = RadarPeer.SignalStrength.from(rssi: rssiValue)
                self.discoveredMerchants[index].peripheral = peripheral
            } else {
                let peer = RadarPeer(
                    id: peerId,
                    peripheral: peripheral,
                    businessName: info.name,
                    category: info.category,
                    emoji: info.emoji,
                    isStatic: info.isStatic,
                    lastSeen: Date(),
                    signalStrength: RadarPeer.SignalStrength.from(rssi: rssiValue),
                    rssi: rssiValue
                )
                self.discoveredMerchants.append(peer)
                self.peerMerchantMap[peerId] = info.name

                print("📍 [BLE] Descubierto: \(info.emoji) \(info.name) (\(info.category)) RSSI: \(rssiValue)")

                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }

            self.radarStatus = "\(self.activeMerchantCount) comerciantes cerca"
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("📡 [BLE] 🤝 Conectado a \(peripheral.name ?? peripheral.identifier.uuidString)")
        peripheral.delegate = self
        peripheral.discoverServices([AteneaBLE.serviceUUID])
        connectedPeripheral = peripheral
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("📡 [BLE] ❌ Falló conexión: \(error?.localizedDescription ?? "unknown")")
        pendingTimbreToSend = nil
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if connectedPeripheral?.identifier == peripheral.identifier {
            connectedPeripheral = nil
            remoteTimbreCharacteristic = nil
        }
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        print("📡 [BLE Central] 🔄 Background restore")
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for p in peripherals {
                discoveredPeripherals[p.identifier] = p
                p.delegate = self
            }
        }
    }
}

// MARK: - CBPeripheralDelegate (Cliente descubre services del merchant)

extension RadarService: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == AteneaBLE.serviceUUID {
            peripheral.discoverCharacteristics([AteneaBLE.timbreCharUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let chars = service.characteristics else { return }
        for char in chars where char.uuid == AteneaBLE.timbreCharUUID {
            remoteTimbreCharacteristic = char
            peripheral.setNotifyValue(true, for: char)

            // Enviar timbre pendiente
            if let pending = pendingTimbreToSend, pending.peripheral.identifier == peripheral.identifier {
                peripheral.writeValue(pending.data, for: char, type: .withResponse)
                print("📡 [BLE] ✅ Timbre pendiente enviado (\(pending.data.count) bytes)")
                pendingTimbreToSend = nil
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("📡 [BLE] ❌ Write error: \(error.localizedDescription)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        do {
            let message = try JSONDecoder().decode(TimbreP2PMessage.self, from: data)
            DispatchQueue.main.async {
                if case .timbreResponse(let response) = message {
                    TimbreManager.shared.receiveResponse(response)
                    print("📡 [BLE] 📨 Respuesta recibida del merchant")
                }
            }
        } catch {
            print("📡 [BLE] ❌ Error decodificando notify: \(error)")
        }
    }
}

// MARK: - CBPeripheralManagerDelegate (Merchant anuncia y recibe timbres)

extension RadarService: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("📡 [BLE Periph] Estado: \(peripheral.state.rawValue)")
        if peripheral.state == .poweredOn, let info = pendingAdvertiseInfo {
            pendingAdvertiseInfo = nil
            setupPeripheralService()
            startPeripheralAdvertising(info: info)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("📡 [BLE Periph] ❌ Error service: \(error.localizedDescription)")
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("📡 [BLE Periph] ❌ Error advertising: \(error.localizedDescription)")
            DispatchQueue.main.async { self.isAdvertising = false }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            guard request.characteristic.uuid == AteneaBLE.timbreCharUUID,
                  let data = request.value else {
                peripheral.respond(to: request, withResult: .unlikelyError)
                continue
            }

            peripheral.respond(to: request, withResult: .success)

            do {
                let message = try JSONDecoder().decode(TimbreP2PMessage.self, from: data)
                DispatchQueue.main.async {
                    if case .timbreEvent(let timbre) = message {
                        TimbreManager.shared.receiveTimbre(timbre)
                        self.peerMerchantMap[request.central.identifier.uuidString] = timbre.clientName
                        print("🔔 [BLE] ⚡ TIMBRE de \(timbre.clientName): \(timbre.type.displayName)")
                    }
                }
            } catch {
                print("📡 [BLE Periph] ❌ Error decodificando: \(error)")
            }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        if !subscribedCentrals.contains(where: { $0.identifier == central.identifier }) {
            subscribedCentrals.append(central)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        subscribedCentrals.removeAll { $0.identifier == central.identifier }
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // Retry de notify si la cola estaba llena
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        print("📡 [BLE Periph] 🔄 Background restore")
        if let services = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService] {
            for service in services {
                timbreService = service
                timbreCharacteristic = service.characteristics?.first as? CBMutableCharacteristic
            }
        }
    }
}
