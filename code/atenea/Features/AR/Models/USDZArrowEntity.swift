//
//  USDZArrowEntity.swift
//  atenea
//
//  Placeholder para la flecha USDZ
//  (La carga real se hace en AnimatedArrowView)
//

import Foundation
import RealityKit

/// Placeholder para entidad de flecha USDZ
class USDZArrowEntity: ARObjectEntity {

    init() {
        super.init(
            name: "Direction_Arrow",
            modelName: "Direction_Arrow",
            position: .zero,
            isInteractive: false,
            isVisible: true
        )
    }
}
