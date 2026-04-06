//
//  ARStickerScannerView.swift
//  Atenea
//
//  Created by Claude on 10/15/25.
//

import SwiftUI
import ARKit
import RealityKit

// MARK: - AR Sticker Scanner View
struct ARStickerScannerView: View {
    @Binding var isPresented: Bool
    @ObservedObject var arService: ARStickerCollectionService
    @ObservedObject var collectionManager: StickerCollectionManager
    var onNavigateToAlbum: (() -> Void)? = nil

    @State private var showInstructions = true
    @State private var scanningProgress: Double = 0.0
    @State private var isScanning = false

    var body: some View {
        ZStack {
            // AR View con cámara
            ARViewContainer(
                arService: arService,
                isScanning: $isScanning,
                scanProgress: $scanningProgress
            )
            .ignoresSafeArea()

            // Overlay UI
            VStack {
                // Header
                headerView

                Spacer()

                // Center scanning indicator
                if isScanning {
                    scanningIndicator
                }

                Spacer()

                // Bottom UI
                bottomUIView
            }

            // Instrucciones iniciales
            if showInstructions {
                instructionsOverlay
            }

            // Animación de colección exitosa
            if arService.showCollectionAnimation {
                collectionSuccessOverlay
            }

            // Botón "Agregar al Album" cuando se detecta stickerCOPA
            if arService.showAddToAlbumButton {
                addToAlbumButton
            }

            // Animación de voltear sticker (después de agregar al álbum)
            if arService.showFlipAnimation {
                FlipStickerAnimationView()
            }

            // Botón de navegación al álbum (solo cuando se detectan ambas imágenes)
            if arService.canNavigateToAlbum {
                navigateToAlbumButton
            }
        }
        .onDisappear {
            arService.resetDetection()
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                withAnimation {
                    isPresented = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: CGFloat(20), weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .blur(radius: 10)
                    )
            }

            Spacer()

            if let venue = arService.currentVenue {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(venue.name)
                        .font(.system(size: CGFloat(16), weight: .bold))
                        .foregroundColor(.white)

                    Text(arService.distanceString(to: venue))
                        .font(.system(size: CGFloat(14)))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.5))
                        .blur(radius: 10)
                )
            }
        }
        .padding(20)
        .padding(.top, 50)
    }

    // MARK: - Scanning Indicator
    private var scanningIndicator: some View {
        VStack(spacing: 20) {
            // Círculo de escaneo animado
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: scanningProgress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#00D084"), Color(hex: "#C8FF00")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: scanningProgress)

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: CGFloat(60)))
                    .foregroundColor(.white)
            }

            Text("Escaneando...")
                .font(.system(size: CGFloat(18), weight: .semibold))
                .foregroundColor(.white)

            Text("\(Int(scanningProgress * 100))%")
                .font(.system(size: CGFloat(32), weight: .bold))
                .foregroundColor(.white)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.6))
                .blur(radius: 20)
        )
    }

    // MARK: - Bottom UI
    private var bottomUIView: some View {
        VStack(spacing: 16) {
            if let venue = arService.currentVenue {
                // Info de la sede
                VStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: CGFloat(32)))
                        .foregroundColor(venue.primaryColor)

                    Text(venue.name)
                        .font(.system(size: CGFloat(20), weight: .bold))
                        .foregroundColor(.white)

                    Text("\(venue.city), \(venue.country)")
                        .font(.system(size: CGFloat(16)))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.6))
                        .blur(radius: 10)
                )

                // Botón de escanear
                if arService.canCollectSticker {
                    Button(action: {
                        startScanning()
                    }) {
                        HStack(spacing: 12) {
                            if isScanning {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: CGFloat(20)))
                            }

                            Text(isScanning ? "Escaneando..." : "Coleccionar Stickers")
                                .font(.system(size: CGFloat(18), weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#00D084"),
                                    Color(hex: "#00A067")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .disabled(isScanning)
                    .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "location.slash")
                            .font(.system(size: CGFloat(24)))
                            .foregroundColor(.orange)

                        Text("Acércate más a la sede")
                            .font(.system(size: CGFloat(16), weight: .semibold))
                            .foregroundColor(.white)

                        Text("Debes estar a menos de 100m")
                            .font(.system(size: CGFloat(14)))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.6))
                            .blur(radius: 10)
                    )
                }
            } else {
                // No hay sedes cerca
                VStack(spacing: 12) {
                    Image(systemName: "map")
                        .font(.system(size: CGFloat(40)))
                        .foregroundColor(.white.opacity(0.6))

                    Text("No hay sedes cerca")
                        .font(.system(size: CGFloat(18), weight: .semibold))
                        .foregroundColor(.white)

                    Text("Visita una sede del Mundial 2026")
                        .font(.system(size: CGFloat(14)))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.6))
                        .blur(radius: 10)
                )
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Instructions Overlay
    private var instructionsOverlay: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Image(systemName: "camera.metering.center.weighted")
                    .font(.system(size: CGFloat(80)))
                    .foregroundColor(Color(hex: "#00D084"))

                Text("Colecciona Stickers con AR")
                    .font(.system(size: CGFloat(28), weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                VStack(spacing: 20) {
                    ARInstructionRow(
                        icon: "location.fill",
                        text: "Visita una sede del Mundial 2026"
                    )

                    ARInstructionRow(
                        icon: "camera.fill",
                        text: "Abre el escáner AR cuando estés cerca"
                    )

                    ARInstructionRow(
                        icon: "photo.on.rectangle.angled",
                        text: "Colecciona 1 sticker por cada sede"
                    )
                }
                .padding(.horizontal, 30)

                Button(action: {
                    withAnimation {
                        showInstructions = false
                    }
                }) {
                    Text("Comenzar")
                        .font(.system(size: CGFloat(18), weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#00D084"),
                                    Color(hex: "#00A067")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
        }
    }

    // MARK: - Collection Success Overlay
    private var collectionSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // Animación de éxito
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#00D084").opacity(0.3),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .scaleEffect(arService.showCollectionAnimation ? CGFloat(1.5) : CGFloat(0.5))
                        .opacity(arService.showCollectionAnimation ? 0 : 1)
                        .animation(.easeOut(duration: 1.5), value: arService.showCollectionAnimation)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: CGFloat(100)))
                        .foregroundColor(Color(hex: "#00D084"))
                        .scaleEffect(arService.showCollectionAnimation ? CGFloat(1) : CGFloat(0.3))
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: arService.showCollectionAnimation)
                }

                VStack(spacing: 12) {
                    Text("¡Stickers Coleccionados!")
                        .font(.system(size: CGFloat(28), weight: .bold))
                        .foregroundColor(.white)

                    if let venue = arService.currentVenue {
                        Text(venue.name)
                            .font(.system(size: CGFloat(20)))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Text("+1 Sticker")
                        .font(.system(size: CGFloat(18), weight: .semibold))
                        .foregroundColor(Color(hex: "#C8FF00"))
                }
            }
        }
    }

    // MARK: - Add to Album Button
    private var addToAlbumButton: some View {
        VStack {
            Spacer()

            VStack(spacing: 20) {
                // Indicador de detección
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: CGFloat(24)))
                        .foregroundColor(Color(hex: "#00D084"))

                    Text("Sticker COPA Detectado")
                        .font(.system(size: CGFloat(18), weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.7))
                        .blur(radius: 10)
                )

                // Botón de agregar al álbum
                Button(action: {
                    withAnimation {
                        arService.addStickerToAlbum()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: CGFloat(20)))

                        Text("Agregar al Album")
                            .font(.system(size: CGFloat(18), weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#00D084"),
                                Color(hex: "#00A067")
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 60)
        }
    }

    // MARK: - Navigate to Album Button
    private var navigateToAlbumButton: some View {
        VStack {
            Spacer()

            VStack(spacing: 20) {
                // Indicador de éxito
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: CGFloat(28)))
                        .foregroundColor(Color(hex: "#C8FF00"))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("¡Sticker Registrado!")
                            .font(.system(size: CGFloat(18), weight: .bold))
                            .foregroundColor(.white)

                        Text("Reverso detectado correctamente")
                            .font(.system(size: CGFloat(14)))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.7))
                        .blur(radius: 10)
                )

                // Botón de ir al álbum
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                    // Navegar al álbum
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onNavigateToAlbum?()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: CGFloat(20)))

                        Text("Ir al Álbum")
                            .font(.system(size: CGFloat(18), weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#C8FF00"),
                                Color(hex: "#00D084")
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 60)
        }
    }

    // MARK: - Start Scanning
    private func startScanning() {
        guard let venue = arService.currentVenue else { return }

        isScanning = true
        scanningProgress = 0.0

        // Simular progreso de escaneo
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if scanningProgress < 1.0 {
                scanningProgress += 0.02
            } else {
                timer.invalidate()

                // Coleccionar stickers
                arService.collectStickerForVenue(venue, collectionManager: collectionManager)

                // Resetear estado
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isScanning = false
                    scanningProgress = 0.0
                }
            }
        }
    }
}

// MARK: - Flip Sticker Animation View
struct FlipStickerAnimationView: View {
    @State private var arrowOffset: CGFloat = 0
    @State private var arrowOpacity: Double = 1.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                // Título
                VStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: CGFloat(60)))
                        .foregroundColor(Color(hex: "#C8FF00"))
                        .rotationEffect(.degrees(360))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: arrowOpacity)

                    Text("Voltea el Sticker")
                        .font(.system(size: CGFloat(28), weight: .bold))
                        .foregroundColor(.white)

                    Text("Escanea el reverso para ir al álbum")
                        .font(.system(size: CGFloat(16)))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                // Animación de flechas curvas
                ZStack {
                    // Flecha superior curva
                    Image(systemName: "arrow.turn.up.right")
                        .font(.system(size: CGFloat(80), weight: .bold))
                        .foregroundColor(Color(hex: "#00D084"))
                        .offset(y: arrowOffset)
                        .opacity(arrowOpacity)

                    // Flecha inferior curva
                    Image(systemName: "arrow.turn.down.right")
                        .font(.system(size: CGFloat(80), weight: .bold))
                        .foregroundColor(Color(hex: "#C8FF00"))
                        .offset(y: -arrowOffset)
                        .opacity(1.0 - arrowOpacity)
                }
                .frame(height: 200)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            arrowOffset = 30
        }

        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            arrowOpacity = 0.3
        }
    }
}

// MARK: - AR Instruction Row
struct ARInstructionRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: CGFloat(24)))
                .foregroundColor(Color(hex: "#00D084"))
                .frame(width: 40)

            Text(text)
                .font(.system(size: CGFloat(16)))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)

            Spacer()
        }
    }
}

// MARK: - AR View Container (UIViewRepresentable)
struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var arService: ARStickerCollectionService
    @Binding var isScanning: Bool
    @Binding var scanProgress: Double

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configurar delegado
        arView.session.delegate = context.coordinator

        // Configurar sesión AR
        let configuration = arService.createARConfiguration()
        arView.session.run(configuration)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Actualizar vista si es necesario
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(arService: arService)
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
    }

    class Coordinator: NSObject, ARSessionDelegate {
        var arService: ARStickerCollectionService

        init(arService: ARStickerCollectionService) {
            self.arService = arService
        }

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                if let imageAnchor = anchor as? ARImageAnchor {
                    let imageName = imageAnchor.referenceImage.name ?? "unknown"
                    arService.handleImageDetection(imageName, transform: imageAnchor.transform)
                }
            }
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                if let imageAnchor = anchor as? ARImageAnchor {
                    let imageName = imageAnchor.referenceImage.name ?? "unknown"
                    // Actualizar tracking si es necesario
                }
            }
        }
    }
}

#Preview {
    ARStickerScannerView(
        isPresented: .constant(true),
        arService: ARStickerCollectionService.shared,
        collectionManager: StickerCollectionManager.shared
    )
}
