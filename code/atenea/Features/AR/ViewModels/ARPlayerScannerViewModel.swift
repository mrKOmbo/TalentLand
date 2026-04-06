//
//  ARPlayerScannerViewModel.swift
//  Atenea
//
//  Created by Claude on 10/15/25.
//

import SwiftUI
import UIKit
import ARKit
import RealityKit
import AVFoundation
internal import Combine

// MARK: - Jugador Detectable
struct DetectablePlayer {
    let playerName: String
    let imageName: String
    let albumPage: Int  // Página del álbum donde aparece
    let physicalWidth: CGFloat  // Tamaño físico en metros
}

// MARK: - AR Player Scanner ViewModel
class ARPlayerScannerViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var isTrackingReady: Bool = false
    @Published var detectedPlayer: DetectablePlayer?
    @Published var showPlayerInfo: Bool = false
    @Published var shouldOpenAlbum: Bool = false
    @Published var albumTargetPage: Int = 0
    @Published var capturedImageFrame: CGRect = .zero
    @Published var showTransitionAnimation: Bool = false

    // Flash control
    @Published var isFlashOn: Bool = false

    // MARK: - Properties
    var arView: ARView?
    private var referenceImages: Set<ARReferenceImage> = []
    private var detectedAnchors: Set<UUID> = []

    // MARK: - Jugadores Detectables
    // Aquí agregas todos los jugadores que quieres detectar con AR
    private let detectablePlayers: [DetectablePlayer] = [
        DetectablePlayer(
            playerName: "Sticker Copa",
            imageName: "stickerCOPA",  // Nombre del asset en Assets.xcassets
            albumPage: 2,  // Página 3 (índice 2, porque empieza en 0)
            physicalWidth: 0.10  // 10cm - tamaño típico de una tarjeta de jugador
        )
        // Puedes agregar más jugadores aquí:
        // DetectablePlayer(playerName: "Otro Jugador", imageName: "imagen-otro", albumPage: 15, physicalWidth: 0.10)
    ]

    // MARK: - Initialization
    init() {
        loadReferenceImages()
    }

    deinit {
        print("🧹 ARPlayerScannerViewModel deinit - cleaning up")
        if let arView = arView {
            arView.session.pause()
        }
        detectedAnchors.removeAll()
        referenceImages.removeAll()
    }

    // MARK: - Image Loading
    private func loadReferenceImages() {
        print("🔄 [PLAYER SCANNER] Starting to load player images...")
        print("📋 [PLAYER SCANNER] Total players to load: \(detectablePlayers.count)")

        for player in detectablePlayers {
            // Intentar cargar la imagen desde Assets
            if let uiImage = UIImage(named: player.imageName) {
                print("🖼️ [PLAYER SCANNER] UIImage loaded for: \(player.playerName) (\(player.imageName))")

                if let cgImage = uiImage.cgImage {
                    let arImage = ARReferenceImage(
                        cgImage,
                        orientation: .up,
                        physicalWidth: player.physicalWidth
                    )
                    arImage.name = player.playerName
                    referenceImages.insert(arImage)

                    print("✅ [PLAYER SCANNER] ARReferenceImage created for: \(player.playerName)")
                    print("   📏 Physical width: \(player.physicalWidth)m")
                    print("   📄 Album page: \(player.albumPage + 1)")
                } else {
                    print("❌ [PLAYER SCANNER] Failed to get CGImage from UIImage: \(player.imageName)")
                }
            } else {
                print("❌ [PLAYER SCANNER] Failed to load UIImage: \(player.imageName)")
            }
        }

        print("✅ [PLAYER SCANNER] Total reference images loaded: \(referenceImages.count)")
    }

    // MARK: - AR Session Setup
    func setupARView(_ arView: ARView) {
        self.arView = arView

        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = referenceImages
        configuration.maximumNumberOfTrackedImages = detectablePlayers.count

        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        // Subscribe to anchor updates
        arView.scene.subscribe(to: SceneEvents.AnchoredStateChanged.self) { [weak self] event in
            self?.handleAnchorUpdate(event)
        }.store(in: &cancellables)

        print("🎬 [PLAYER SCANNER] AR Session started with \(referenceImages.count) player images")
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Anchor Handling
    private func handleAnchorUpdate(_ event: SceneEvents.AnchoredStateChanged) {
        guard let imageAnchor = event.anchor as? ARImageAnchor else { return }

        if event.isAnchored {
            handleImageDetected(imageAnchor)
        }
    }

    private func handleImageDetected(_ imageAnchor: ARImageAnchor) {
        guard let playerName = imageAnchor.referenceImage.name,
              !detectedAnchors.contains(imageAnchor.identifier) else {
            return
        }

        detectedAnchors.insert(imageAnchor.identifier)

        // Buscar el jugador detectado
        if let player = detectablePlayers.first(where: { $0.playerName == playerName }) {
            print("🎯 [PLAYER SCANNER] PLAYER DETECTED: \(player.playerName)")
            print("   📄 Opening album at page: \(player.albumPage + 1)")

            DispatchQueue.main.async {
                self.detectedPlayer = player
                self.albumTargetPage = player.albumPage
                self.showPlayerInfo = true

                // Calcular posición de la imagen en pantalla para animación
                self.calculateImageFrame(for: imageAnchor)

                // Trigger haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)

                // Abrir álbum después de 1.5 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.showTransitionAnimation = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.shouldOpenAlbum = true
                    }
                }
            }
        }
    }

    // MARK: - Animation Helpers
    private func calculateImageFrame(for imageAnchor: ARImageAnchor) {
        guard let arView = arView else { return }

        // Obtener la posición 3D del anchor
        let position = imageAnchor.transform.columns.3
        let position3D = SIMD3<Float>(position.x, position.y, position.z)

        // Proyectar a 2D en la pantalla
        let center = arView.project(position3D)

        // Tamaño estimado en pantalla (ajustar según sea necesario)
        let size = CGSize(width: 200, height: 260)

        let frame = CGRect(
            x: center!.x - size.width / 2,
            y: center!.y - size.height / 2,
            width: size.width,
            height: size.height
        )

        DispatchQueue.main.async {
            self.capturedImageFrame = frame
        }
    }

    // MARK: - Flash Control

    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else {
            print("⚠️ Flash not available on this device")
            return
        }

        do {
            try device.lockForConfiguration()

            if isFlashOn {
                // Turn off flash
                device.torchMode = .off
                isFlashOn = false
                print("💡 Flash turned OFF")
            } else {
                // Turn on flash
                try device.setTorchModeOn(level: 1.0)
                isFlashOn = true
                print("💡 Flash turned ON")
            }

            device.unlockForConfiguration()
        } catch {
            print("❌ Error toggling flash: \(error.localizedDescription)")
        }
    }

    private func turnOffFlash() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch,
              isFlashOn else {
            return
        }

        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
            isFlashOn = false
            print("💡 Flash turned OFF automatically")
        } catch {
            print("❌ Error turning off flash: \(error.localizedDescription)")
        }
    }

    // MARK: - Reset
    func reset() {
        turnOffFlash()
        detectedAnchors.removeAll()
        detectedPlayer = nil
        showPlayerInfo = false
        shouldOpenAlbum = false
        showTransitionAnimation = false
        capturedImageFrame = .zero
    }

    // MARK: - Stop Session
    func stopSession() {
        turnOffFlash()
        arView?.session.pause()
    }
}
