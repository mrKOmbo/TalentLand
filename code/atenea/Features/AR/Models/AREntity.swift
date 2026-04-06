//
//  AREntity.swift
//  atenea
//
//  Modelos base para entidades de realidad aumentada
//

import Foundation
import RealityKit
import ARKit
internal import Combine

// MARK: - AREntity Protocol

/// Protocolo base para todas las entidades AR de la aplicación
protocol AREntityProtocol: AnyObject {
    var identifier: UUID { get }
    var name: String { get }
    var position: SIMD3<Float> { get set }
    var rotation: simd_quatf { get set }
    var scale: SIMD3<Float> { get set }
}

// MARK: - Base AR Entity

/// Entidad base de AR que representa un objeto en el mundo virtual
class AREntity: AREntityProtocol {
    let identifier: UUID
    let name: String
    var position: SIMD3<Float>
    var rotation: simd_quatf
    var scale: SIMD3<Float>

    // Referencia opcional al ModelEntity de RealityKit
    weak var modelEntity: ModelEntity?

    init(
        name: String,
        position: SIMD3<Float> = .zero,
        rotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0]),
        scale: SIMD3<Float> = [1, 1, 1]
    ) {
        self.identifier = UUID()
        self.name = name
        self.position = position
        self.rotation = rotation
        self.scale = scale
    }
}

// MARK: - 3D Object Entity

/// Representa un objeto 3D colocado en el mundo AR
class ARObjectEntity: AREntity {
    let modelName: String
    var isInteractive: Bool
    var isVisible: Bool

    // Metadatos opcionales
    var metadata: [String: Any] = [:]

    init(
        name: String,
        modelName: String,
        position: SIMD3<Float>,
        rotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0]),
        scale: SIMD3<Float> = [1, 1, 1],
        isInteractive: Bool = true,
        isVisible: Bool = true
    ) {
        self.modelName = modelName
        self.isInteractive = isInteractive
        self.isVisible = isVisible

        super.init(
            name: name,
            position: position,
            rotation: rotation,
            scale: scale
        )
    }
}

// MARK: - Transform Helper

extension simd_float4x4 {
    /// Extrae la posición de la matriz de transformación
    var translation: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }

    /// Extrae la rotación de la matriz de transformación
    var rotation: simd_quatf {
        return simd_quatf(self)
    }

    /// Extrae la escala de la matriz de transformación
    var scale: SIMD3<Float> {
        let scaleX = simd_length(SIMD3<Float>(columns.0.x, columns.0.y, columns.0.z))
        let scaleY = simd_length(SIMD3<Float>(columns.1.x, columns.1.y, columns.1.z))
        let scaleZ = simd_length(SIMD3<Float>(columns.2.x, columns.2.y, columns.2.z))
        return SIMD3<Float>(scaleX, scaleY, scaleZ)
    }
}
