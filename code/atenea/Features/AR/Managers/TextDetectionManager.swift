//
//  TextDetectionManager.swift
//  atenea
//
//  Manager para detectar texto en tiempo real usando Vision Framework
//  durante la navegación AR
//

import Foundation
import Vision
import ARKit
import CoreImage
import UIKit
internal import Combine

/// Modelo para representar un texto detectado con su posición y bounds
struct DetectedTextBox: Identifiable {
    let id = UUID()
    let text: String
    let boundingBox: CGRect  // En coordenadas normalizadas (0-1)
    let confidence: Float
    let timestamp: Date

    /// Convierte el bounding box normalizado a coordenadas de pantalla
    func screenRect(for viewSize: CGSize) -> CGRect {
        let x = boundingBox.origin.x * viewSize.width
        let y = (1 - boundingBox.origin.y - boundingBox.height) * viewSize.height // Vision usa sistema de coordenadas invertido
        let width = boundingBox.width * viewSize.width
        let height = boundingBox.height * viewSize.height

        return CGRect(x: x, y: y, width: width, height: height)
    }
}

/// Manager para detectar texto en frames de AR usando Vision Framework
final class TextDetectionManager: ObservableObject {

    // MARK: - Published Properties

    /// Textos detectados actualmente visibles
    @Published var detectedTexts: [DetectedTextBox] = []

    /// Indica si la detección está activa
    @Published var isDetecting: Bool = false

    /// Nivel de confianza mínimo para considerar un texto válido (0.0 - 1.0)
    @Published var minimumConfidence: Float = 0.6

    // MARK: - Private Properties

    private var visionQueue = DispatchQueue(label: "com.atenea.textdetection", qos: .userInitiated)
    private var lastProcessedTime: Date = Date.distantPast
    private let processingInterval: TimeInterval = 0.5 // Procesar cada 0.5 segundos para no saturar

    // Vision Request
    private lazy var textDetectionRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest { [weak self] request, error in
            self?.handleDetectedText(request: request, error: error)
        }

        // Configuración del request
        request.recognitionLevel = .accurate // Más preciso pero más lento (.fast para velocidad)
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.03 // Textos de al menos 3% de altura de la imagen

        // Soportar múltiples idiomas (español e inglés)
        request.recognitionLanguages = ["es-ES", "en-US"]

        return request
    }()

    // MARK: - Initialization

    init() {
        print("📝 TextDetectionManager inicializado")
    }

    // MARK: - Public Methods

    /// Inicia la detección de texto
    func startDetection() {
        isDetecting = true
        print("✅ Detección de texto INICIADA")
    }

    /// Detiene la detección de texto
    func stopDetection() {
        isDetecting = false
        detectedTexts.removeAll()
        print("⏸️ Detección de texto DETENIDA")
    }

    /// Procesa un frame de AR para detectar texto
    /// - Parameter frame: Frame de ARSession
    func processARFrame(_ frame: ARFrame) {
        // Solo procesar si la detección está activa
        guard isDetecting else { return }

        // Throttling: solo procesar cada X segundos para no saturar el CPU
        let now = Date()
        guard now.timeIntervalSince(lastProcessedTime) >= processingInterval else { return }
        lastProcessedTime = now

        // Obtener el pixel buffer del frame de la cámara
        let pixelBuffer = frame.capturedImage

        // Procesar en background thread
        visionQueue.async { [weak self] in
            self?.performTextDetection(on: pixelBuffer)
        }
    }

    /// Limpia textos antiguos (opcional, para evitar acumulación)
    func cleanOldDetections(olderThan interval: TimeInterval = 3.0) {
        let now = Date()
        detectedTexts.removeAll { text in
            now.timeIntervalSince(text.timestamp) > interval
        }
    }

    // MARK: - Private Methods

    /// Ejecuta la detección de texto usando Vision Framework
    private func performTextDetection(on pixelBuffer: CVPixelBuffer) {
        // Crear image request handler desde el pixel buffer
        let requestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up,
            options: [:]
        )

        do {
            // Ejecutar el request de detección de texto
            try requestHandler.perform([textDetectionRequest])
        } catch {
            print("❌ Error ejecutando detección de texto: \(error.localizedDescription)")
        }
    }

    /// Maneja los resultados de la detección de texto
    private func handleDetectedText(request: VNRequest, error: Error?) {
        if let error = error {
            print("❌ Error en Vision request: \(error.localizedDescription)")
            return
        }

        // Obtener observaciones de texto reconocido
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return
        }

        // Procesar cada observación
        var newDetectedTexts: [DetectedTextBox] = []

        for observation in observations {
            // Obtener el texto con mayor confianza
            guard let topCandidate = observation.topCandidates(1).first else { continue }

            // Filtrar por confianza mínima
            guard topCandidate.confidence >= minimumConfidence else { continue }

            // Crear DetectedTextBox con la información
            let detectedText = DetectedTextBox(
                text: topCandidate.string,
                boundingBox: observation.boundingBox,
                confidence: topCandidate.confidence,
                timestamp: Date()
            )

            newDetectedTexts.append(detectedText)
        }

        // Actualizar en el main thread para que SwiftUI pueda reaccionar
        DispatchQueue.main.async { [weak self] in
            self?.detectedTexts = newDetectedTexts

            if !newDetectedTexts.isEmpty {
                print("📝 Detectados \(newDetectedTexts.count) textos:")
                for text in newDetectedTexts.prefix(3) { // Mostrar solo los primeros 3
                    print("  - \"\(text.text)\" (confianza: \(Int(text.confidence * 100))%)")
                }
            }
        }
    }
}

// MARK: - Debug Helpers

extension TextDetectionManager {
    /// Información de debug del estado actual
    var debugInfo: String {
        """
        📝 Text Detection Debug:
        - Detecting: \(isDetecting)
        - Texts Found: \(detectedTexts.count)
        - Min Confidence: \(Int(minimumConfidence * 100))%
        - Processing Interval: \(processingInterval)s
        """
    }

    /// Imprime información de debug
    func printDebugInfo() {
        print(debugInfo)
    }
}
