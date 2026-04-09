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
@preconcurrency import NearbyInteraction

// MARK: - BLE UUIDs (Atenea)

struct AteneaBLE {
    static let serviceUUID = CBUUID(string: "A1E2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D")
    static let timbreCharUUID = CBUUID(string: "B2F3D4E5-F6A7-5B6C-9D0E-1F2A3B4C5D6E")

    static let niTokenCharUUID = CBUUID(string: "A2E3D4F5-E6A7-5B8C-0D1E-2F3A4B5C6D7E")

    static let centralRestoreKey = "com.atenea.ble.central"
    static let peripheralRestoreKey = "com.atenea.ble.peripheral"

    // Duty cycling
    static let scanOnDuration: TimeInterval = 5.0
    static let scanOffDuration: TimeInterval = 10.0
    static let pruneInterval: TimeInterval = 5.0
    static let staleTimeout: TimeInterval = 30.0
}

// MARK: - Discovered Peer (BLE)

struct RadarPeer: Identifiable, Equatable {
    let id: String                     // peripheral.identifier.uuidString
    var peripheral: CBPeripheral?      // referencia para conexión y write
    let businessName: String
    let category: String
    let emoji: String
    let isStatic: Bool
    var isOnRoute: Bool
    var lastSeen: Date
    var signalStrength: SignalStrength
    var rssi: Int                      // RSSI real del BLE scan
    var uwbDistance: Float?            // Distancia UWB (NearbyInteraction), nil si no disponible

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

    // NearbyInteraction (UWB)
    private var niSession: NISession?
    private var niTokenMutableChar: CBMutableCharacteristic?
    private var niTokenData: Data?
    private var niCurrentPeerID: String?

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
        let info = "\(merchant.emoji)|\(name)|\(merchant.category.rawValue)|\(merchant.isStatic ? "1" : "0")|\(merchant.isOnRoute ? "1" : "0")"
        currentMerchantInfo = info
        print("📡 [BLE Periph] startAdvertising: \(name) | peripheralState=\(peripheralManager.state.rawValue)")

        guard peripheralManager.state == .poweredOn else {
            pendingAdvertiseInfo = info
            print("📡 [BLE Periph] ⏳ Esperando poweredOn para anunciar: \(name)")
            return
        }

        setupPeripheralService()
        // advertising arranca en peripheralManager(_:didAdd:error:) cuando el servicio está listo
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
        // Crear NISession si no existe (merchant necesita su token para el GATT char)
        if niSession == nil {
            niSession = NISession()
            niSession?.delegate = self
        }

        let timbreChar = CBMutableCharacteristic(
            type: AteneaBLE.timbreCharUUID,
            properties: [.write, .writeWithoutResponse, .notify],
            value: nil,
            permissions: [.writeable]
        )
        timbreCharacteristic = timbreChar

        var chars: [CBMutableCharacteristic] = [timbreChar]

        // NI token char: el merchant expone su token (readable) y acepta el del cliente (writable)
        // CoreBluetooth: chars con value cacheado deben ser read-only.
        // Para read+write, value=nil y se responde dinámicamente en didReceiveRead.
        if let niToken = niSession?.discoveryToken,
           let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: niToken, requiringSecureCoding: true) {
            let niChar = CBMutableCharacteristic(
                type: AteneaBLE.niTokenCharUUID,
                properties: [.read, .write],
                value: nil,
                permissions: [.readable, .writeable]
            )
            niTokenData = tokenData
            niTokenMutableChar = niChar
            chars.append(niChar)
            print("📡 [UWB] NI token char agregado al GATT (\(tokenData.count) bytes)")
        }

        let service = CBMutableService(type: AteneaBLE.serviceUUID, primary: true)
        service.characteristics = chars
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

        #if targetEnvironment(simulator)
        print("🔍 [BLE Central] 🖥️ Simulator detectado — usando mock discovery")
        loadMockPeers()
        return
        #else
        guard centralManager.state == .poweredOn else {
            pendingScanStart = true
            print("🔍 [BLE Central] ⏳ Esperando poweredOn para escanear (state=\(centralManager.state.rawValue))")
            return
        }

        beginScan()
        #endif
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

        // Desconectar peripherals activos y limpiar cache
        for (_, peripheral) in discoveredPeripherals {
            if peripheral.state == .connected || peripheral.state == .connecting {
                centralManager.cancelPeripheralConnection(peripheral)
            }
        }
        discoveredPeripherals.removeAll()
        connectedPeripheral = nil
        remoteTimbreCharacteristic = nil

        DispatchQueue.main.async {
            self.isScanning = false
            self.discoveredMerchants.removeAll()
            self.peerMerchantMap.removeAll()
            if !self.isAdvertising {
                self.radarStatus = "Inactivo"
            }
        }
        print("🔍 [BLE Central] Dejó de escanear — cache limpiado")
    }

    // MARK: - Stop All

    func stopAll() {
        print("🛑 [BLE] stopAll() — deteniendo advertising + scanning")
        stopAdvertising()
        stopScanning()
        // stopScanning() ya limpia discoveredPeripherals, discoveredMerchants y peerMerchantMap
        print("🛑 [BLE] stopAll() — completo")
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

        print("📡 [BLE P2P SEND] → \(peer.businessName) | client=\(timbre.clientName) type=\(timbre.type.rawValue) lat=\(timbre.clientLatitude) lon=\(timbre.clientLongitude) msg=\(timbre.message ?? "nil")")

        do {
            let message = TimbreP2PMessage.timbreEvent(timbre)
            let data = try JSONEncoder().encode(message)

            print("📡 [BLE P2P PAYLOAD] \(data.count) bytes | JSON: \(String(data: data, encoding: .utf8)?.prefix(300) ?? "?")")

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

    // MARK: - Simulator Mock

    /// Genera peers falsos a partir de MerchantManager para testing sin BLE
    private func loadMockPeers() {
        let merchants = MerchantManager.shared.merchants.filter { $0.isActive && $0.currentLocation != nil }
        print("🔍 [Mock] Cargando \(merchants.count) merchants como peers simulados")

        DispatchQueue.main.async {
            self.isScanning = true
            self.discoveredMerchants.removeAll()

            for merchant in merchants {
                let mockRSSI = Int.random(in: -75 ... -45)
                let peer = RadarPeer(
                    id: merchant.id.uuidString,
                    peripheral: nil,
                    businessName: merchant.businessName,
                    category: merchant.category.rawValue,
                    emoji: merchant.emoji,
                    isStatic: merchant.isStatic,
                    isOnRoute: merchant.route?.isActive ?? false,
                    lastSeen: Date(),
                    signalStrength: RadarPeer.SignalStrength.from(rssi: mockRSSI),
                    rssi: mockRSSI
                )
                self.discoveredMerchants.append(peer)
                self.peerMerchantMap[peer.id] = merchant.businessName
                print("📍 [Mock] Peer: \(merchant.emoji) \(merchant.businessName) RSSI:\(mockRSSI)")
            }

            self.radarStatus = "\(self.activeMerchantCount) comerciantes cerca"
            print("🔍 [Mock] ✅ \(self.discoveredMerchants.count) peers mock cargados")
        }
    }

    // MARK: - Internal

    private func pruneAndUpdateSignals() {
        let before = discoveredMerchants.count
        DispatchQueue.main.async {
            self.discoveredMerchants.removeAll { $0.isStale }
            let after = self.discoveredMerchants.count
            if before != after {
                print("🧹 [BLE] Pruned \(before - after) stale peers → \(after) restantes")
            }
        }
    }

    private func parseAdvertisementName(_ localName: String) -> (emoji: String, name: String, category: String, isStatic: Bool, isOnRoute: Bool)? {
        let parts = localName.components(separatedBy: "|")
        guard parts.count >= 4 else { return nil }
        return (emoji: parts[0], name: parts[1], category: parts[2], isStatic: parts[3] == "1", isOnRoute: parts.count >= 5 && parts[4] == "1")
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
                    isOnRoute: info.isOnRoute,
                    lastSeen: Date(),
                    signalStrength: RadarPeer.SignalStrength.from(rssi: rssiValue),
                    rssi: rssiValue
                )
                self.discoveredMerchants.append(peer)
                self.peerMerchantMap[peerId] = info.name

                // Sincronizar isOnRoute al MerchantManager local
                if info.isOnRoute, let idx = MerchantManager.shared.merchants.firstIndex(where: { $0.businessName == info.name }) {
                    MerchantManager.shared.merchants[idx].isOnRoute = true
                }

                print("📍 [BLE] Descubierto: \(info.emoji) \(info.name) (\(info.category)) isOnRoute=\(info.isOnRoute) RSSI: \(rssiValue)")

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
            peripheral.discoverCharacteristics([AteneaBLE.timbreCharUUID, AteneaBLE.niTokenCharUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let chars = service.characteristics else { return }
        for char in chars {
            switch char.uuid {
            case AteneaBLE.timbreCharUUID:
                remoteTimbreCharacteristic = char
                peripheral.setNotifyValue(true, for: char)
                if let pending = pendingTimbreToSend, pending.peripheral.identifier == peripheral.identifier {
                    peripheral.writeValue(pending.data, for: char, type: .withResponse)
                    print("📡 [BLE] ✅ Timbre pendiente enviado (\(pending.data.count) bytes)")
                    pendingTimbreToSend = nil
                }
            case AteneaBLE.niTokenCharUUID:
                // Iniciar NISession del cliente si no existe
                if niSession == nil {
                    niSession = NISession()
                    niSession?.delegate = self
                }
                peripheral.readValue(for: char)   // leer token del merchant
                print("📡 [UWB] Leyendo NI token del merchant...")
            default:
                break
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

        // NI token read response — intercambiar token y arrancar UWB session
        if characteristic.uuid == AteneaBLE.niTokenCharUUID {
            guard let merchantToken = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: NIDiscoveryToken.self, from: data
            ) else {
                print("📡 [UWB] ❌ No se pudo decodificar NI token del merchant")
                return
            }

            niCurrentPeerID = peripheral.identifier.uuidString

            // Escribir nuestro token en la char del merchant para que él también arranque
            if let myToken = niSession?.discoveryToken,
               let myTokenData = try? NSKeyedArchiver.archivedData(withRootObject: myToken, requiringSecureCoding: true) {
                peripheral.writeValue(myTokenData, for: characteristic, type: .withResponse)
                print("📡 [UWB] Token propio enviado al merchant (\(myTokenData.count) bytes)")
            }

            let config = NINearbyPeerConfiguration(peerToken: merchantToken)
            niSession?.run(config)
            print("📡 [UWB] NISession del cliente iniciada con token del merchant")
            return
        }

        // Timbre notify
        do {
            let message = try JSONDecoder().decode(TimbreP2PMessage.self, from: data)
            DispatchQueue.main.async {
                if case .timbreResponse(let response) = message {
                    print("📩 [BLE RECV RESPONSE] type=\(response.type.rawValue) msg=\(response.message ?? "nil") minutes=\(response.estimatedMinutes.map { String($0) } ?? "nil")")
                    TimbreManager.shared.receiveResponse(response)
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
            currentMerchantInfo = info
            setupPeripheralService()
            // advertising arranca en didAdd callback
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("📡 [BLE Periph] ❌ Error service: \(error.localizedDescription)")
            return
        }
        // Servicio GATT listo — ahora sí anunciarse
        if let info = currentMerchantInfo {
            startPeripheralAdvertising(info: info)
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
            guard let data = request.value else {
                peripheral.respond(to: request, withResult: .unlikelyError)
                continue
            }

            if request.characteristic.uuid == AteneaBLE.niTokenCharUUID {
                // Cliente escribió su NI token — arrancar UWB session como merchant
                peripheral.respond(to: request, withResult: .success)

                guard let clientToken = try? NSKeyedUnarchiver.unarchivedObject(
                    ofClass: NIDiscoveryToken.self, from: data
                ) else {
                    print("📡 [UWB] ❌ No se pudo decodificar NI token del cliente")
                    continue
                }

                niCurrentPeerID = request.central.identifier.uuidString
                let config = NINearbyPeerConfiguration(peerToken: clientToken)
                niSession?.run(config)
                print("📡 [UWB] NISession del merchant iniciada con token del cliente")

            } else if request.characteristic.uuid == AteneaBLE.timbreCharUUID {
                peripheral.respond(to: request, withResult: .success)
                print("📩 [BLE RECV] \(data.count) bytes de central=\(request.central.identifier.uuidString.prefix(8))")

                do {
                    let message = try JSONDecoder().decode(TimbreP2PMessage.self, from: data)
                    DispatchQueue.main.async {
                        if case .timbreEvent(let timbre) = message {
                            print("📩 [BLE RECV TIMBRE] client=\(timbre.clientName) type=\(timbre.type.rawValue) lat=\(timbre.clientLatitude) lon=\(timbre.clientLongitude) msg=\(timbre.message ?? "nil")")
                            TimbreManager.shared.receiveTimbre(timbre)
                            self.peerMerchantMap[request.central.identifier.uuidString] = timbre.clientName
                        }
                    }
                } catch {
                    print("📡 [BLE Periph] ❌ Error decodificando: \(error)")
                }
            } else {
                peripheral.respond(to: request, withResult: .unlikelyError)
            }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if request.characteristic.uuid == AteneaBLE.niTokenCharUUID, let data = niTokenData {
            request.value = data
            peripheral.respond(to: request, withResult: .success)
        } else {
            peripheral.respond(to: request, withResult: .attributeNotFound)
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

// MARK: - NISessionDelegate (UWB ranging)

extension RadarService: NISessionDelegate {

    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let object = nearbyObjects.first,
              let distance = object.distance,
              let peerID = niCurrentPeerID else { return }

        DispatchQueue.main.async {
            if let idx = self.discoveredMerchants.firstIndex(where: { $0.id == peerID }) {
                self.discoveredMerchants[idx].uwbDistance = distance
                print("📡 [UWB] 📏 \(String(format: "%.2f", distance))m → \(self.discoveredMerchants[idx].businessName)")
            }
        }
    }

    func session(_ session: NISession, didInvalidateWith error: Error) {
        print("📡 [UWB] ❌ NISession invalidada: \(error.localizedDescription)")
        niSession = nil
        niCurrentPeerID = nil
    }

    func sessionWasSuspended(_ session: NISession) {
        print("📡 [UWB] ⏸ NISession suspendida")
    }

    func sessionSuspensionEnded(_ session: NISession) {
        print("📡 [UWB] ▶️ NISession reanudada — reiniciando")
        if let peerID = niCurrentPeerID,
           let peer = discoveredMerchants.first(where: { $0.id == peerID }),
           let _ = peer.peripheral {
            // La session fue suspendida (background) — el peer necesita re-intercambiar tokens
            // Reconectarse forzará un nuevo intercambio de tokens via GATT
            print("📡 [UWB] Re-intercambio de tokens necesario")
        }
    }
}
