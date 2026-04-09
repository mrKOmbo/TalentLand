//
//  ARPlayerScannerView.swift//  Atenea
//
//  Created by Claude on 10/15/25.
//

import SwiftUI
import RealityKit
import ARKit

struct ARPlayerScannerView: View {
    @StateObject private var viewModel = ARPlayerScannerViewModel()
    @Binding var isPresented: Bool
    @State private var showAlbum = false

    var body: some View {
        ZStack {
            // AR Camera View
            PlayerARViewContainer(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)

            // Overlay UI
            VStack {
                // Header
                HStack {
                    Button(action: {
                        viewModel.stopSession()
                        isPresented = false
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 44, height: 44)

                            Image(systemName: "xmark")
                                .font(.system(size: CGFloat(18), weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()

                    // Scanner Icon
                    Image(systemName: "viewfinder")
                        .font(.system(size: CGFloat(24)))
                        .foregroundColor(.white)
                        .shadow(radius: 10)

                    Spacer()

                    // Flash toggle button
                    Button(action: {
                        viewModel.toggleFlash()
                    }) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isFlashOn ? Color.black.opacity(0.7) : Color.black.opacity(0.6))
                                .frame(width: 44, height: 44)

                            Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: CGFloat(20), weight: .semibold))
                                .foregroundColor(viewModel.isFlashOn ? .yellow : .white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                // Instructions
                if !viewModel.showPlayerInfo {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: CGFloat(60)))
                            .foregroundColor(.white)
                            .shadow(radius: 10)

                        VStack(spacing: 8) {
                            Text(LocalizedString("ar.player.scanCard"))
                                .font(.system(size: CGFloat(24), weight: .bold))
                                .foregroundColor(.white)
                                .shadow(radius: 10)

                            Text(LocalizedString("ar.player.pointCamera"))
                                .font(.system(size: CGFloat(16)))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(radius: 10)
                        }
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.6))
                            .blur(radius: 20)
                    )
                }

                Spacer()

                // Tracking Status
                if viewModel.isTrackingReady {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)

                        Text(LocalizedString("ar.player.arReady"))
                            .font(.system(size: CGFloat(14), weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                    )
                    .padding(.bottom, 40)
                }
            }

            // Player Detected Overlay
            if viewModel.showPlayerInfo, let player = viewModel.detectedPlayer {
                PlayerDetectedOverlay(
                    player: player,
                    showTransitionAnimation: $viewModel.showTransitionAnimation,
                    imageFrame: viewModel.capturedImageFrame
                )
            }
        }
        .onChange(of: viewModel.shouldOpenAlbum) { shouldOpen in
            if shouldOpen {
                showAlbum = true
            }
        }
        .fullScreenCover(isPresented: $showAlbum) {
            PaniniAlbumView(
                isPresented: $showAlbum,
                initialPage: viewModel.albumTargetPage
            )
            .onDisappear {
                viewModel.reset()
            }
        }
    }
}

// MARK: - Player AR View Container
struct PlayerARViewContainer: UIViewRepresentable {
    let viewModel: ARPlayerScannerViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        viewModel.setupARView(arView)

        // Check tracking state
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            viewModel.isTrackingReady = true
        }

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

// MARK: - Player Detected Overlay
struct PlayerDetectedOverlay: View {
    let player: DetectablePlayer
    @Binding var showTransitionAnimation: Bool
    let imageFrame: CGRect

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            // Background dimmer
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 24) {
                // Player Image with Animation
                if let image = UIImage(named: player.imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 260)
                        .cornerRadius(12)
                        .shadow(radius: 30)
                        .scaleEffect(showTransitionAnimation ? CGFloat(0.3) : scale)
                        .opacity(showTransitionAnimation ? 0 : opacity)
                        .offset(y: showTransitionAnimation ? -300 : 0)
                }

                // Player Info
                VStack(spacing: 12) {
                    Text(LocalizedString("ar.playerFound"))
                        .font(.system(size: CGFloat(28), weight: .bold))
                        .foregroundColor(.white)

                    Text(player.playerName)
                        .font(.system(size: CGFloat(22), weight: .semibold))
                        .foregroundColor(.yellow)

                    Text(String(format: LocalizedString("ar.openingAlbum"), player.albumPage + 1))
                        .font(.system(size: CGFloat(16)))
                        .foregroundColor(.white.opacity(0.9))
                }
                .opacity(showTransitionAnimation ? 0 : 1)
            }
        }
        .onAppear {
            // Pulse animation
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                scale = 1.1
            }

            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                opacity = 0.8
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ARPlayerScannerView(isPresented: .constant(true))
}
