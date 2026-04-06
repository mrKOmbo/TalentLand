//
//  ShakeDetector.swift
//  atenea
//
//  Detector de agitación del dispositivo para activar emergencias
//

import SwiftUI
import UIKit

// MARK: - Shake Detection Window

/// Window personalizado que detecta el gesto de agitar el dispositivo
class ShakeDetectingWindow: UIWindow {
    var onShake: (() -> Void)?

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)

        if motion == .motionShake {
            print("🔔 Dispositivo agitado - Activando emergencia")
            onShake?()
        }
    }
}

// MARK: - Shake Detector ViewModifier

/// ViewModifier para detectar agitación del dispositivo en SwiftUI
struct ShakeDetectorModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .background(
                ShakeDetectorView(action: action)
            )
    }
}

// MARK: - Shake Detector UIViewControllerRepresentable

/// Vista UIKit que detecta el shake gesture
struct ShakeDetectorView: UIViewControllerRepresentable {
    let action: () -> Void

    func makeUIViewController(context: Context) -> ShakeDetectorViewController {
        let controller = ShakeDetectorViewController()
        controller.onShake = action
        return controller
    }

    func updateUIViewController(_ uiViewController: ShakeDetectorViewController, context: Context) {
        uiViewController.onShake = action
    }
}

/// ViewController que detecta el shake gesture
class ShakeDetectorViewController: UIViewController {
    var onShake: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)

        if motion == .motionShake {
            print("🔔 Dispositivo agitado - Activando emergencia")

            // Haptic feedback fuerte para indicar que se detectó el shake
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)

            onShake?()
        }
    }
}

// MARK: - SwiftUI Extension

extension View {
    /// Detecta cuando el usuario agita el dispositivo
    /// - Parameter action: Acción a ejecutar cuando se detecte la agitación
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeDetectorModifier(action: action))
    }
}
