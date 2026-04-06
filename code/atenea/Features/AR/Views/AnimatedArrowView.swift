//
//  AnimatedArrowView.swift
  //  atenea
//
//  Vista que muestra el modelo USDZ animado usando RealityKit
//  Anclado en AR con control de giroscopio
//

import SwiftUI
import RealityKit
import ARKit
internal import Combine
import Vision

/// Vista que integra el modelo USDZ animado en AR con detección de texto
struct AnimatedArrowView: UIViewRepresentable {
    @ObservedObject var arrowManager: ArrowNavigationManager
    @ObservedObject var textDetectionManager: TextDetectionManager

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configurar sesión AR simple (sin tracking de mundo, solo orientación)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [] // No detectar planos
        arView.session.run(config)

        // Configurar delegate para recibir frames
        arView.session.delegate = context.coordinator

        // Cargar el modelo con animación
        context.coordinator.loadArrowModel(in: arView)
        context.coordinator.arView = arView
        context.coordinator.textDetectionManager = textDetectionManager

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Actualizar rotación del modelo según giroscopio
        context.coordinator.updateRotation(
            yaw: arrowManager.targetDirection - arrowManager.deviceHeading,
            pitch: arrowManager.devicePitch,
            roll: arrowManager.deviceRoll,
            manualOffset: arrowManager.manualRotationOffset
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        var arrowEntity: Entity?
        var anchor: AnchorEntity?
        var cancellables = Set<AnyCancellable>()
        weak var textDetectionManager: TextDetectionManager?

        /// Carga el modelo USDZ con animación
        func loadArrowModel(in arView: ARView) {
            let modelFileName = "Direction_Arrow"

            // Buscar el archivo en el bundle
            guard let modelURL = Bundle.main.url(
                forResource: modelFileName,
                withExtension: "usdz",
                subdirectory: "Resources/Models"
            ) ?? Bundle.main.url(
                forResource: modelFileName,
                withExtension: "usdz"
            ) else {
                print("❌ No se encontró \(modelFileName).usdz")
                return
            }

            print("✅ Cargando modelo animado desde: \(modelURL.path)")

            // Cargar con Entity.load (para modelos con animaciones)
            do {
                let arrowEntity = try Entity.load(contentsOf: modelURL)
                self.arrowEntity = arrowEntity

                // Crear anchor fijo a la cámara (HUD mode - siempre centrado)
                let anchor = AnchorEntity(.camera)
                anchor.name = "ArrowCameraAnchor"
                self.anchor = anchor

                // Ajustar escala y posición para que se vea como overlay centrado
                arrowEntity.scale = [0.0003, 0.0003, 0.0003] // Diminuta (0.3% del tamaño)
                arrowEntity.position = [0, 0, -0.2] // Muy cerca de la cámara (0.2m)

                // Añadir el modelo al anchor
                anchor.addChild(arrowEntity)
                arView.scene.addAnchor(anchor)

                print("✅ Modelo añadido al anchor")

                // Reproducir animación si existe
                if let animation = arrowEntity.availableAnimations.first {
                    arrowEntity.playAnimation(
                        animation.repeat(),
                        transitionDuration: 0.5,
                        startsPaused: false
                    )
                    print("✅ Animación de la flecha iniciada: \(animation)")
                } else {
                    print("⚠️ Modelo cargado, pero no se encontraron animaciones")
                }

            } catch {
                print("❌ Error cargando modelo: \(error.localizedDescription)")
                loadAsModelEntity(from: modelURL, in: arView)
            }
        }

        /// Método alternativo usando ModelEntity
        private func loadAsModelEntity(from url: URL, in arView: ARView) {
            print("🔄 Intentando cargar como ModelEntity...")

            ModelEntity.loadModelAsync(contentsOf: url)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("✅ ModelEntity cargado exitosamente")
                        case .failure(let error):
                            print("❌ Error con ModelEntity: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { [weak self] modelEntity in
                        guard let self = self else { return }

                        self.arrowEntity = modelEntity

                        // Crear anchor anclado a la cámara (HUD mode)
                        let anchor = AnchorEntity(.camera)
                        anchor.name = "ArrowCameraAnchor"
                        self.anchor = anchor

                        // Ajustar escala y posición para HUD
                        modelEntity.scale = [0.0003, 0.0003, 0.0003]
                        modelEntity.position = [0, 0, -0.2]

                        // Añadir a la escena
                        anchor.addChild(modelEntity)
                        arView.scene.addAnchor(anchor)

                        print("✅ ModelEntity añadido a la escena")

                        // Buscar animaciones
                        if let animation = modelEntity.availableAnimations.first {
                            modelEntity.playAnimation(animation.repeat())
                            print("✅ Animación reproducida")
                        }
                    }
                )
                .store(in: &cancellables)
        }

        // MARK: - ARSessionDelegate

        /// Recibe frames actualizados de la sesión AR
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // Enviar frame al TextDetectionManager para procesamiento
            textDetectionManager?.processARFrame(frame)
        }

        // MARK: - Rotation Updates

        /// Actualiza la rotación del modelo según los valores del giroscopio
        func updateRotation(yaw: Float, pitch: Float, roll: Float, manualOffset: Float) {
            guard let arrowEntity = arrowEntity else { return }

            // Normalizar yaw a -180 a 180
            var normalizedYaw = yaw + manualOffset
            while normalizedYaw > 180 { normalizedYaw -= 360 }
            while normalizedYaw < -180 { normalizedYaw += 360 }

            // Convertir grados a radianes
            let yawRadians = normalizedYaw * .pi / 180
            let pitchRadians = -pitch * .pi / 180 // Invertir pitch
            let rollRadians = roll * .pi / 180

            // Crear quaterniones para cada eje de rotación
            let yawRotation = simd_quatf(angle: yawRadians, axis: SIMD3(0, 1, 0))   // Y-axis
            let pitchRotation = simd_quatf(angle: pitchRadians, axis: SIMD3(1, 0, 0)) // X-axis
            let rollRotation = simd_quatf(angle: rollRadians, axis: SIMD3(0, 0, 1))  // Z-axis

            // Combinar rotaciones: Yaw * Pitch * Roll
            let combinedRotation = yawRotation * pitchRotation * rollRotation

            // Aplicar rotación al modelo
            arrowEntity.orientation = combinedRotation
        }
    }
}

// MARK: - Overlay completo con controles

/// Vista que envuelve el ARView animado con controles
struct AnimatedArrowOverlay: View {
    @ObservedObject var arrowManager: ArrowNavigationManager
    @ObservedObject var textDetectionManager: TextDetectionManager
    var showOverlays: Bool = true
    @State private var lastAnnouncedDirection: String = ""
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.7

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Layer 1: ARView con modelo animado (fondo completo)
                AnimatedArrowView(
                    arrowManager: arrowManager,
                    textDetectionManager: textDetectionManager
                )
                .edgesIgnoringSafeArea(.all)

                // Layer 2: Overlays de texto detectado (no interactivo)
                TextOverlayView(
                    textDetectionManager: textDetectionManager,
                    viewSize: geometry.size
                )
                .allowsHitTesting(false)

                // Layer 3: Indicador visual de rango correcto (pulso verde centrado) - solo si showOverlays
                if isInCorrectRange && showOverlays {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 8)
                            .foregroundColor(.green.opacity(0.8))
                            .frame(width: 150, height: 150)
                            .scaleEffect(pulseScale)
                            .opacity(pulseOpacity)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                    pulseScale = 1.2
                                    pulseOpacity = 0.3
                                }
                            }
                            .onDisappear {
                                pulseScale = 1.0
                                pulseOpacity = 0.7
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .allowsHitTesting(false)
                }

                // Layer 4: Panel compacto de dirección (top aligned) - solo si showOverlays
                if showOverlays {
                    // Panel de dirección compacto y translúcido
                    VStack(spacing: 8) {
                            // Indicador de rango correcto (más pequeño)
                            if isInCorrectRange {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text(LocalizedString("ar.nav.correctPath"))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.25))
                                .cornerRadius(8)
                                .transition(.scale.combined(with: .opacity))
                            }

                            // Dirección en una sola línea horizontal
                            HStack(spacing: 12) {
                                // Dirección principal (más compacto)
                                HStack(spacing: 6) {
                                    Image(systemName: "location.north.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(isInCorrectRange ? .green : Color(hex: "#00D084"))

                                    Text(fullDirectionText)
                                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                                        .foregroundColor(isInCorrectRange ? .green : .white)
                                        .minimumScaleFactor(0.6)
                                        .lineLimit(1)
                                        .animation(.easeInOut, value: isInCorrectRange)
                                }

                                Spacer()

                                // Grados más compacto
                                HStack(spacing: 6) {
                                    Text("\(Int(arrowManager.targetDirection))°")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(isInCorrectRange ? .green : .white)
                                        .animation(.easeInOut, value: isInCorrectRange)

                                    // Indicador cardinal
                                    Text(directionText)
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(isInCorrectRange ? Color.green.opacity(0.4) : Color.white.opacity(0.2))
                                        .cornerRadius(6)
                                        .accessibilityHidden(true)
                                        .animation(.easeInOut, value: isInCorrectRange)
                                }
                            }

                        // Botones de control (más compactos)
                        HStack(spacing: 8) {
                            // Botón para activar/desactivar detección de texto (compacto)
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if textDetectionManager.isDetecting {
                                        textDetectionManager.stopDetection()
                                    } else {
                                        textDetectionManager.startDetection()
                                    }
                                }

                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: textDetectionManager.isDetecting ? "text.viewfinder" : "text.slash")
                                        .font(.system(size: 10))
                                    Text(textDetectionManager.isDetecting ? "ON" : "OFF")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(textDetectionManager.isDetecting ? Color.green.opacity(0.7) : Color.gray.opacity(0.5))
                                .cornerRadius(6)
                            }
                            .accessibilityLabel(textDetectionManager.isDetecting ? LocalizedString("ar.nav.deactivateTextDetection") : LocalizedString("ar.nav.activateTextDetection"))
                            .accessibilityHint(String(format: LocalizedString("ar.nav.toggleTextDetectionHint"), textDetectionManager.isDetecting ? LocalizedString("ar.nav.deactivate") : LocalizedString("ar.nav.activate")))

                            // Botón para resetear rotación manual (compacto)
                            if abs(arrowManager.manualRotationOffset) > 1 {
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        arrowManager.manualRotationOffset = 0
                                    }

                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.system(size: 10))
                                        Text(LocalizedString("ar.nav.reset"))
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.7))
                                    .cornerRadius(6)
                                }
                                .accessibilityLabel(LocalizedString("ar.nav.resetView"))
                                .accessibilityHint(LocalizedString("ar.nav.resetViewHint"))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            // Background con glassmorphism
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)

                            // Gradiente oscuro sutil
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.black.opacity(0.6),
                                            Color.black.opacity(0.5)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 16)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(LocalizedString("ar.nav.directionPanel"))
                    .accessibilityValue(voiceOverAnnouncement)
                    .accessibilityHint(LocalizedString("ar.nav.directionPanelHint"))
                    .onChange(of: fullDirectionText) { newDirection in
                        // Anunciar cambios de dirección con VoiceOver
                        if newDirection != lastAnnouncedDirection {
                            announceDirectionChange(newDirection)
                            lastAnnouncedDirection = newDirection
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)

                    Spacer()
                }  // cierra if showOverlays
            }  // cierra ZStack
        }  // cierra GeometryReader
        .onAppear {
            // Iniciar detección de texto automáticamente cuando aparece la vista
            textDetectionManager.startDetection()
            print("📝 Detección de texto iniciada automáticamente")
        }
        .onDisappear {
            // Detener detección cuando desaparece la vista
            textDetectionManager.stopDetection()
            print("📝 Detección de texto detenida")
        }
    }

    /// Indica si el usuario está apuntando en la dirección correcta (±15°)
    private var isInCorrectRange: Bool {
        let relativeDirection = arrowManager.targetDirection - arrowManager.deviceHeading
        var normalized = relativeDirection
        while normalized > 180 { normalized -= 360 }
        while normalized < -180 { normalized += 360 }
        return abs(normalized) < 15
    }

    /// Texto que indica la dirección cardinal del objetivo (compacto)
    private var directionText: String {
        let angle = arrowManager.targetDirection

        switch angle {
        case 0..<22.5, 337.5..<360:
            return "N"
        case 22.5..<67.5:
            return "NE"
        case 67.5..<112.5:
            return "E"
        case 112.5..<157.5:
            return "SE"
        case 157.5..<202.5:
            return "S"
        case 202.5..<247.5:
            return "SO"
        case 247.5..<292.5:
            return "O"
        case 292.5..<337.5:
            return "NO"
        default:
            return "—"
        }
    }

    /// Texto completo de la dirección para mostrar en pantalla
    private var fullDirectionText: String {
        let angle = arrowManager.targetDirection

        switch angle {
        case 0..<22.5, 337.5..<360:
            return LocalizedString("ar.nav.north")
        case 22.5..<67.5:
            return LocalizedString("ar.nav.northeast")
        case 67.5..<112.5:
            return LocalizedString("ar.nav.east")
        case 112.5..<157.5:
            return LocalizedString("ar.nav.southeast")
        case 157.5..<202.5:
            return LocalizedString("ar.nav.south")
        case 202.5..<247.5:
            return LocalizedString("ar.nav.southwest")
        case 247.5..<292.5:
            return LocalizedString("ar.nav.west")
        case 292.5..<337.5:
            return LocalizedString("ar.nav.northwest")
        default:
            return LocalizedString("ar.nav.calculating")
        }
    }

    /// Anuncio completo para VoiceOver con toda la información
    private var voiceOverAnnouncement: String {
        let direction = fullDirectionText
        let degrees = Int(arrowManager.targetDirection)
        return "\(LocalizedString("ar.nav.direction")): \(direction), \(degrees) \(LocalizedString("ar.nav.degrees"))"
    }

    /// Anuncia cambios de dirección usando VoiceOver
    private func announceDirectionChange(_ newDirection: String) {
        // Usar UIAccessibility para anunciar el cambio
        let announcement = "\(LocalizedString("ar.nav.newDirection")): \(newDirection)"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}

// MARK: - Arrow Shape

/// Forma custom de flecha para dibujar en SwiftUI
struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Dimensiones de la flecha
        let shaftWidth: CGFloat = width * 0.2
        let headWidth: CGFloat = width * 0.5
        let headHeight: CGFloat = height * 0.35
        let shaftHeight: CGFloat = height * 0.65

        // Centro horizontal
        let centerX = width / 2

        // Dibujar desde abajo hacia arriba
        // Inicio: parte inferior del shaft
        path.move(to: CGPoint(x: centerX - shaftWidth / 2, y: height))

        // Lado izquierdo del shaft
        path.addLine(to: CGPoint(x: centerX - shaftWidth / 2, y: headHeight))

        // Esquina izquierda de la punta
        path.addLine(to: CGPoint(x: centerX - headWidth / 2, y: headHeight))

        // Punta superior (centro)
        path.addLine(to: CGPoint(x: centerX, y: 0))

        // Esquina derecha de la punta
        path.addLine(to: CGPoint(x: centerX + headWidth / 2, y: headHeight))

        // Lado derecho del shaft
        path.addLine(to: CGPoint(x: centerX + shaftWidth / 2, y: headHeight))

        // Parte inferior derecha del shaft
        path.addLine(to: CGPoint(x: centerX + shaftWidth / 2, y: height))

        // Cerrar el path
        path.closeSubpath()

        return path
    }
}

// MARK: - Color Extensions

extension Color {
    /// Crea una versión más clara del color
    func lighter(by percentage: Double = 0.3) -> Color {
        return self.adjust(by: abs(percentage))
    }

    /// Crea una versión más oscura del color
    func darker(by percentage: Double = 0.3) -> Color {
        return self.adjust(by: -abs(percentage))
    }

    /// Ajusta el brillo del color
    private func adjust(by percentage: Double) -> Color {
        #if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return Color(
            red: min(red + percentage, 1.0),
            green: min(green + percentage, 1.0),
            blue: min(blue + percentage, 1.0),
            opacity: Double(alpha)
        )
        #else
        return self
        #endif
    }
}
