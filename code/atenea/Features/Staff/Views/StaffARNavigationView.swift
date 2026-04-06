//
//  StaffARNavigationView.swift
//  atenea
//
//  Vista AR para que el staff navegue hacia un cliente en emergencia
//

import SwiftUI
import RealityKit
import ARKit
import NearbyInteraction

struct StaffARNavigationView: View {
    @Binding var isPresented: Bool
    @ObservedObject var niManager: NearbyInteractionManager

    var body: some View {
        ZStack {
            // Vista AR de fondo
            EmergencyARViewContainer(nearbyObject: niManager.nearbyObject)
                .edgesIgnoringSafeArea(.all)

            // Overlay con información
            VStack {
                // Header
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4)
                        }
                        .padding()
                    }

                    Spacer()
                }

                Spacer()

                // Información de distancia
                if let distance = niManager.nearbyObject?.distance {
                    VStack(spacing: 12) {
                        Text("CLIENTE EN EMERGENCIA")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)

                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.red)

                            Text("\(String(format: "%.1f", distance))m")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Text("Sigue la flecha para llegar al cliente")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.6))
                            .shadow(color: .black.opacity(0.3), radius: 10)
                    )
                    .padding(.bottom, 40)
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)

                        Text("Calculando ubicación...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.6))
                    )
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Emergency AR View Container
struct EmergencyARViewContainer: UIViewRepresentable {
    var nearbyObject: NINearbyObject?

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Start a basic AR world-tracking session
        let config = ARWorldTrackingConfiguration()
        arView.session.run(config)

        // Create an anchor for the camera
        // We will attach our arrow to this
        let cameraAnchor = AnchorEntity(.camera)
        cameraAnchor.name = "cameraAnchor"
        arView.scene.addAnchor(cameraAnchor)

        // Create the arrow model (a cone pointing forward)
        let arrowEntity = createArrowEntity()
        arrowEntity.name = "arrow"
        arrowEntity.position = [0, -0.3, -1.5] // Place 1.5m in front, slightly below eye level
        arrowEntity.isEnabled = false // Hidden by default

        cameraAnchor.addChild(arrowEntity)

        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        // This function is called every time 'nearbyObject' changes

        // Find our arrow in the scene
        guard let cameraAnchor = arView.scene.anchors.first(where: { $0.name == "cameraAnchor" }),
              let arrowEntity = cameraAnchor.findEntity(named: "arrow") else {
            return
        }

        if let object = nearbyObject {
            // We have a valid object!

            guard let niDirection = object.direction else {
                arrowEntity.isEnabled = false
                return
            }

            // Make arrow visible
            arrowEntity.isEnabled = true

            // The NI direction is relative to the *device*.
            // We must transform it into ARKit's *world space*.
            guard let cameraTransform = arView.session.currentFrame?.camera.transform else { return }

            // Create a 4x4 matrix from the NI direction
            var directionTransform = matrix_identity_float4x4
            directionTransform.columns.3.x = niDirection.x
            directionTransform.columns.3.y = niDirection.y
            directionTransform.columns.3.z = niDirection.z

            // Combine the camera and direction transforms
            let worldTransform = cameraTransform * directionTransform

            // Make the arrow entity look at the target's position
            let targetPosition = SIMD3<Float>(worldTransform.columns.3.x,
                                              worldTransform.columns.3.y,
                                              worldTransform.columns.3.z)

            // Position the arrow in front and make it point to target
            arrowEntity.look(at: targetPosition, from: [0, -0.3, -1.5], relativeTo: cameraAnchor)

        } else {
            // No object, hide the arrow
            arrowEntity.isEnabled = false
        }
    }

    // MARK: - Create Arrow Entity
    private func createArrowEntity() -> ModelEntity {
        // Create a cone that will act as our arrow
        let cone = MeshResource.generateCone(height: 0.3, radius: 0.1)

        // Create a glowing red material for emergency
        var material = SimpleMaterial()
        material.color = .init(tint: .red, texture: nil)
        material.metallic = .init(floatLiteral: 0.8)
        material.roughness = .init(floatLiteral: 0.2)

        let arrowEntity = ModelEntity(mesh: cone, materials: [material])

        // Rotate the cone to point forward (by default it points up)
        arrowEntity.transform.rotation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])

        // Add a pulsing animation
        var transform = arrowEntity.transform
        transform.scale = SIMD3<Float>(1.2, 1.2, 1.2)

        arrowEntity.move(
            to: transform,
            relativeTo: arrowEntity.parent,
            duration: 0.8,
            timingFunction: .easeInOut
        )

        return arrowEntity
    }
}

#Preview {
    StaffARNavigationView(
        isPresented: .constant(true),
        niManager: NearbyInteractionManager(role: .staff)
    )
}
