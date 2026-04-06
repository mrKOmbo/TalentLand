//
//  TextOverlayView.swift
//  atenea
//
//  Vista que muestra overlays de texto detectado sobre la cámara AR
//

import SwiftUI

/// Vista que muestra cuadritos con texto detectado sobre la vista AR
struct TextOverlayView: View {
    @ObservedObject var textDetectionManager: TextDetectionManager
    let viewSize: CGSize

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Renderizar cada texto detectado como un cuadrito
                ForEach(textDetectionManager.detectedTexts) { detectedText in
                    TextBoxView(
                        detectedText: detectedText,
                        viewSize: geometry.size
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Vista individual para cada cuadrito de texto detectado
struct TextBoxView: View {
    let detectedText: DetectedTextBox
    let viewSize: CGSize

    @State private var isVisible: Bool = false

    var body: some View {
        let screenRect = detectedText.screenRect(for: viewSize)

        ZStack {
            // Borde del cuadrito
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(borderColor, lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(backgroundColor)
                )

            // Texto detectado
            Text(detectedText.text)
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .minimumScaleFactor(0.5)
        }
        .frame(width: screenRect.width, height: screenRect.height)
        .position(x: screenRect.midX, y: screenRect.midY)
        .opacity(isVisible ? 1.0 : 0.0)
        .scaleEffect(x: isVisible ? 1.0 : 0.8, y: isVisible ? 1.0 : 0.8)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
        .accessibilityLabel("Texto detectado: \(detectedText.text)")
        .accessibilityHint("Confianza: \(Int(detectedText.confidence * 100))%")
    }

    // MARK: - Computed Properties

    /// Color del borde según la confianza
    private var borderColor: Color {
        switch detectedText.confidence {
        case 0.9...1.0:
            return .green
        case 0.7..<0.9:
            return .blue
        default:
            return .orange
        }
    }

    /// Color de fondo según la confianza
    private var backgroundColor: Color {
        switch detectedText.confidence {
        case 0.9...1.0:
            return .green.opacity(0.3)
        case 0.7..<0.9:
            return .blue.opacity(0.3)
        default:
            return .orange.opacity(0.3)
        }
    }

    /// Tamaño de fuente dinámico basado en el tamaño del cuadrito
    private var fontSize: CGFloat {
        let screenRect = detectedText.screenRect(for: viewSize)
        let minDimension = min(screenRect.width, screenRect.height)

        // Tamaño de fuente proporcional al tamaño del cuadrito
        let baseFontSize = minDimension * 0.2

        // Limitar entre 12 y 24 puntos
        return max(12, min(24, baseFontSize))
    }
}

// MARK: - Preview

#Preview {
    let manager = TextDetectionManager()

    // Simular algunos textos detectados
    manager.detectedTexts = [
        DetectedTextBox(
            text: "CALLE PRINCIPAL",
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.1),
            confidence: 0.95,
            timestamp: Date()
        ),
        DetectedTextBox(
            text: "123",
            boundingBox: CGRect(x: 0.6, y: 0.5, width: 0.15, height: 0.08),
            confidence: 0.85,
            timestamp: Date()
        ),
        DetectedTextBox(
            text: "STOP",
            boundingBox: CGRect(x: 0.4, y: 0.7, width: 0.2, height: 0.1),
            confidence: 0.92,
            timestamp: Date()
        )
    ]

    return ZStack {
        // Simular fondo de cámara
        Color.black

        TextOverlayView(
            textDetectionManager: manager,
            viewSize: CGSize(width: 390, height: 844)
        )
    }
    .edgesIgnoringSafeArea(.all)
}
