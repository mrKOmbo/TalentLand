//
//  ArrowNavigationManager.swift
//  atenea
//
//  Manager para controlar la flecha de navegación 3D en AR
//  Integra giroscopio y orientación del dispositivo
//

import Foundation
import CoreMotion
import ARKit
import RealityKit
import UIKit
internal import Combine

/// Manager para la flecha de navegación en AR
final class ArrowNavigationManager: ObservableObject {

    // MARK: - Published Properties

    /// Indica si la flecha está visible
    @Published var isArrowVisible: Bool = false

    /// Dirección objetivo en grados (0° = Norte, 90° = Este)
    @Published var targetDirection: Float = 0 {
        didSet {
            updateArrowDirection()
        }
    }

    /// Heading del dispositivo en grados (rotación horizontal - yaw)
    @Published var deviceHeading: Float = 0

    /// Pitch del dispositivo en grados (inclinación arriba/abajo)
    @Published var devicePitch: Float = 0

    /// Roll del dispositivo en grados (inclinación lateral)
    @Published var deviceRoll: Float = 0

    /// Offset manual de rotación aplicado por gestos del usuario (en grados)
    @Published var manualRotationOffset: Float = 0

    /// Posición de la flecha en pantalla (coordenadas)
    @Published var arrowPosition: CGPoint = .zero // .zero significa centrado

    /// Indica si llegaste al destino
    @Published var hasReachedDestination: Bool = false

    /// Indica si está en modo de detección de planos
    @Published var isPlaneDetectionActive: Bool = false

    /// Contador de planos detectados
    @Published var detectedPlanesCount: Int = 0

    // MARK: - Private Properties

    private let motionManager = CMMotionManager()
    private weak var arView: ARView?
    private var arrowEntity: USDZArrowEntity?
    private var arrowAnchor: AnchorEntity?

    // Plane detection properties
    private var planeAnchors: [UUID: AnchorEntity] = [:]
    private var arSession: ARSession?
    private var cancellables = Set<AnyCancellable>()

    // Configuración
    private let updateInterval: TimeInterval = 0.05 // 20 Hz
    private let smoothingFactor: Float = 0.15 // Para suavizar movimientos

    // Haptic Feedback
    private let hapticGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private var isInTargetRange: Bool = false // Track if currently in range
    private var lastHapticTime: Date = Date.distantPast

    // MARK: - Initialization

    init() {
        setupMotionManager()
    }

    deinit {
        stopTracking()
    }

    // MARK: - Setup

    private func setupMotionManager() {
        // Configurar frecuencia de actualización
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.gyroUpdateInterval = updateInterval

        // Preparar generadores de haptic feedback
        hapticGenerator.prepare()
        impactGenerator.prepare()
    }

    // MARK: - Arrow Management

    /// Muestra la flecha de navegación (el overlay 2D se muestra automáticamente)
    func showArrow(in arView: ARView, color: UIColor = .systemBlue) {
        self.arView = arView
        self.arSession = arView.session

        // Solo iniciar tracking del giroscopio
        // El modelo USDZ se muestra como overlay 2D centrado
        startTracking()

        isArrowVisible = true

        print("✅ Tracking iniciado - Flecha USDZ se mostrará centrada en pantalla")
    }

    /// Oculta la flecha de navegación
    func hideArrow() {
        stopTracking()
        isArrowVisible = false

        print("✅ Tracking detenido - Flecha USDZ oculta")
    }

    /// Remueve completamente la flecha
    func removeArrow() {
        hideArrow()
    }

    // MARK: - Motion Tracking

    /// Inicia el tracking de giroscopio y orientación
    func startTracking() {
        guard motionManager.isDeviceMotionAvailable else {
            print("⚠️ Device motion no disponible")
            return
        }

        // Iniciar device motion (incluye giroscopio + acelerómetro + magnetómetro)
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryCorrectedZVertical,
            to: .main
        ) { [weak self] (motion, error) in
            guard let self = self, let motion = motion else { return }

            // Obtener orientación 3D completa del dispositivo
            let attitude = motion.attitude

            // YAW (rotación horizontal) - en radianes
            let heading = Float(attitude.yaw)
            var headingDegrees = heading * 180 / .pi
            if headingDegrees < 0 {
                headingDegrees += 360
            }

            // PITCH (inclinación arriba/abajo) - en radianes
            // Pitch positivo = inclinado hacia arriba, negativo = hacia abajo
            let pitch = Float(attitude.pitch)
            let pitchDegrees = pitch * 180 / .pi

            // ROLL (inclinación lateral) - en radianes
            let roll = Float(attitude.roll)
            let rollDegrees = roll * 180 / .pi

            // Aplicar suavizado con wrap-around en 360° para heading
            self.deviceHeading = self.smoothAngle(
                current: self.deviceHeading,
                target: headingDegrees,
                factor: self.smoothingFactor
            )

            // Aplicar suavizado simple para pitch y roll
            self.devicePitch = self.smoothValue(
                current: self.devicePitch,
                target: pitchDegrees,
                factor: self.smoothingFactor
            )

            self.deviceRoll = self.smoothValue(
                current: self.deviceRoll,
                target: rollDegrees,
                factor: self.smoothingFactor
            )

            // Actualizar dirección de la flecha
            self.updateArrowDirection()
        }
    }

    /// Detiene el tracking
    func stopTracking() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }

    // MARK: - Direction Updates

    /// Actualiza la dirección hacia donde apunta la flecha
    private func updateArrowDirection() {
        // La rotación es manejada por AnimatedArrowView que observa estos valores
        // No necesitamos actualizar nada aquí

        // Calcular diferencia entre heading del dispositivo y objetivo
        let relativeDirection = targetDirection - deviceHeading

        // Normalizar a -180 a 180
        var normalized = relativeDirection
        while normalized > 180 { normalized -= 360 }
        while normalized < -180 { normalized += 360 }

        let absAngle = abs(normalized)

        // Verificar si estamos en el rango objetivo (± 15 grados)
        let inTargetRange = absAngle < 15

        // HAPTIC FEEDBACK - Vibrar cuando entramos al rango correcto
        if inTargetRange && !isInTargetRange {
            // Acabamos de entrar al rango - vibración de éxito
            triggerSuccessHaptic()
            isInTargetRange = true
            print("✅ Entrando al rango objetivo - VIBRANDO")
        } else if !inTargetRange && isInTargetRange {
            // Salimos del rango
            isInTargetRange = false
            print("⚠️ Saliendo del rango objetivo")
        } else if inTargetRange && isInTargetRange {
            // Estamos en rango - vibración continua suave cada 2 segundos
            let timeSinceLastHaptic = Date().timeIntervalSince(lastHapticTime)
            if timeSinceLastHaptic > 2.0 {
                triggerContinuousHaptic()
                lastHapticTime = Date()
            }
        }

        // Verificar si llegamos al destino (± 5 grados - más preciso)
        if absAngle < 5 && !hasReachedDestination {
            onDestinationReached()
        }
    }

    // MARK: - Haptic Feedback

    /// Vibración de éxito cuando entramos al rango correcto
    private func triggerSuccessHaptic() {
        hapticGenerator.notificationOccurred(.success)
    }

    /// Vibración continua suave mientras estamos en el rango
    private func triggerContinuousHaptic() {
        impactGenerator.impactOccurred(intensity: 0.5)
    }

    /// Vibración fuerte al llegar al destino exacto
    private func triggerDestinationHaptic() {
        // Patrón de vibración: 3 pulsos rápidos
        hapticGenerator.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.impactGenerator.impactOccurred(intensity: 1.0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.impactGenerator.impactOccurred(intensity: 1.0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.hapticGenerator.notificationOccurred(.success)
        }
    }


    // MARK: - Destination

    /// Establece una dirección objetivo en grados
    /// - Parameter degrees: Dirección en grados (0° = Norte, 90° = Este, 180° = Sur, 270° = Oeste)
    func setTargetDirection(degrees: Float) {
        self.targetDirection = degrees
        self.hasReachedDestination = false
    }

    /// Establece una dirección objetivo en radianes
    func setTargetDirection(radians: Float) {
        self.targetDirection = radians * 180 / .pi
        self.hasReachedDestination = false
    }

    /// Establece un punto objetivo en coordenadas del mundo
    func setTargetLocation(worldPosition: SIMD3<Float>, from currentPosition: SIMD3<Float>) {
        // Calcular vector hacia el objetivo
        let direction = worldPosition - currentPosition

        // Calcular ángulo en el plano XZ (horizontal)
        let angle = atan2(direction.x, direction.z)

        // Convertir a grados
        var degrees = angle * 180 / .pi
        if degrees < 0 { degrees += 360 }

        setTargetDirection(degrees: degrees)
    }

    /// Llamado cuando llegas al destino
    private func onDestinationReached() {
        hasReachedDestination = true

        // Vibración especial de destino alcanzado
        triggerDestinationHaptic()

        print("🎯 ¡Destino alcanzado! - VIBRACIÓN ESPECIAL")
    }


    // MARK: - Helpers

    /// Suaviza ángulos manejando el wrap-around de 0°/360°
    private func smoothAngle(current: Float, target: Float, factor: Float) -> Float {
        // Calcular la diferencia más corta entre ángulos
        var delta = target - current

        // Normalizar delta a -180 a 180
        while delta > 180 { delta -= 360 }
        while delta < -180 { delta += 360 }

        // Aplicar suavizado a la diferencia
        let smoothedDelta = delta * factor
        var result = current + smoothedDelta

        // Normalizar resultado a 0-360
        while result >= 360 { result -= 360 }
        while result < 0 { result += 360 }

        return result
    }

    /// Suaviza valores para evitar movimientos bruscos
    private func smoothValue(current: Float, target: Float, factor: Float) -> Float {
        return current + (target - current) * factor
    }

    /// Normaliza ángulo a rango 0-360
    private func normalizeAngle(_ angle: Float) -> Float {
        var normalized = angle
        while normalized >= 360 { normalized -= 360 }
        while normalized < 0 { normalized += 360 }
        return normalized
    }
}

// MARK: - Convenience Methods

extension ArrowNavigationManager {

    /// Atajo: Muestra flecha apuntando al Norte
    func pointToNorth(in arView: ARView) {
        showArrow(in: arView)
        setTargetDirection(degrees: 0)
    }

    /// Atajo: Muestra flecha apuntando al Este
    func pointToEast(in arView: ARView) {
        showArrow(in: arView)
        setTargetDirection(degrees: 90)
    }

    /// Atajo: Muestra flecha apuntando al Sur
    func pointToSouth(in arView: ARView) {
        showArrow(in: arView)
        setTargetDirection(degrees: 180)
    }

    /// Atajo: Muestra flecha apuntando al Oeste
    func pointToWest(in arView: ARView) {
        showArrow(in: arView)
        setTargetDirection(degrees: 270)
    }
}

// MARK: - Debug Helpers

extension ArrowNavigationManager {

    /// Información de debug del estado actual
    var debugInfo: String {
        """
        🧭 Arrow Navigation Debug (3D):
        - Visible: \(isArrowVisible)
        - Device Heading (Yaw): \(String(format: "%.1f°", deviceHeading))
        - Device Pitch: \(String(format: "%.1f°", devicePitch))
        - Device Roll: \(String(format: "%.1f°", deviceRoll))
        - Target Direction: \(String(format: "%.1f°", targetDirection))
        - Relative Angle: \(String(format: "%.1f°", targetDirection - deviceHeading))
        - Reached: \(hasReachedDestination)
        """
    }

    /// Imprime información de debug
    func printDebugInfo() {
        print(debugInfo)
    }
}

// MARK: - Plane Detection

extension ArrowNavigationManager {

    /// Inicia la detección de planos en AR
    func startPlaneDetection() {
        guard let arView = arView else {
            print("⚠️ No hay ARView disponible para detección de planos")
            return
        }

        // Configurar ARConfiguration con detección de planos
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic

        // Ejecutar la sesión con la nueva configuración
        arView.session.run(configuration, options: [])

        isPlaneDetectionActive = true
        print("🔍 Detección de planos INICIADA")

        // Agregar un ancla subscription para detectar nuevos planos
        arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
            self?.updateDetectedPlanes()
        }.store(in: &cancellables)
    }

    /// Detiene la detección de planos
    func stopPlaneDetection() {
        guard let arView = arView else { return }

        // Remover todos los planos visualizados
        clearDetectedPlanes()

        // Configurar ARConfiguration SIN detección de planos
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = []

        // Ejecutar la sesión sin detección
        arView.session.run(configuration, options: [])

        isPlaneDetectionActive = false
        detectedPlanesCount = 0
        print("✋ Detección de planos DETENIDA")
    }

    /// Actualiza el contador de planos detectados
    private func updateDetectedPlanes() {
        guard let arView = arView else { return }

        // Obtener todos los anchors de planos
        let planeAnchors = arView.session.currentFrame?.anchors.compactMap { $0 as? ARPlaneAnchor } ?? []

        // Actualizar contador
        DispatchQueue.main.async { [weak self] in
            self?.detectedPlanesCount = planeAnchors.count
        }

        // Visualizar planos nuevos
        for planeAnchor in planeAnchors {
            if self.planeAnchors[planeAnchor.identifier] == nil {
                addPlaneVisualization(for: planeAnchor, in: arView)
            }
        }
    }

    /// Agrega visualización para un plano detectado
    private func addPlaneVisualization(for planeAnchor: ARPlaneAnchor, in arView: ARView) {
        // Crear un mesh para el plano
        let extent = planeAnchor.planeExtent
        let planeMesh = MeshResource.generatePlane(width: extent.width, depth: extent.height)

        // Material semitransparente
        var material = SimpleMaterial()
        if planeAnchor.alignment == .horizontal {
            material.color = .init(tint: .cyan.withAlphaComponent(0.3))
        } else {
            material.color = .init(tint: .purple.withAlphaComponent(0.3))
        }

        // Crear entidad del plano
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])

        // Crear anchor para el plano
        let anchorEntity = AnchorEntity(anchor: planeAnchor)
        anchorEntity.addChild(planeEntity)

        // Agregar a la escena
        arView.scene.addAnchor(anchorEntity)

        // Guardar referencia
        planeAnchors[planeAnchor.identifier] = anchorEntity

        print("✅ Plano detectado: \(planeAnchor.alignment == .horizontal ? "Horizontal" : "Vertical")")
    }

    /// Limpia todas las visualizaciones de planos
    private func clearDetectedPlanes() {
        guard let arView = arView else { return }

        for (_, anchor) in planeAnchors {
            arView.scene.removeAnchor(anchor)
        }

        planeAnchors.removeAll()
        print("🧹 Planos limpiados")
    }
}
