//
//  TutorialSpotlightView.swift
//  Atenea
//
//  Spotlight overlay for in-app tutorial hints
//

import SwiftUI

struct TutorialSpotlightView: View {
    let hint: TutorialHint
    let onNext: () -> Void
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark overlay with hole
                SpotlightShape(spotlightRect: hint.position)
                    .fill(Color.black.opacity(0.85))
                    .ignoresSafeArea()
                    .allowsHitTesting(true)
                    .onTapGesture {
                        // Tapping outside advances
                        onNext()
                    }

                // Spotlight circle with glow
                Circle()
                    .stroke(Color.white.opacity(0.8), lineWidth: 3)
                    .frame(width: hint.position.width + 20, height: hint.position.height + 20)
                    .position(
                        x: hint.position.midX,
                        y: hint.position.midY
                    )
                    .scaleEffect(pulseScale)
                    .shadow(color: Color.white.opacity(0.5), radius: 20)

                // Hint card
                HintCard(
                    hint: hint,
                    geometry: geometry,
                    onNext: onNext,
                    onDismiss: onDismiss
                )
                .scaleEffect(scale)
                .opacity(opacity)
            }
        }
        .transition(.opacity)
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Entry animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            scale = 1.0
            opacity = 1.0
        }

        // Pulse animation for spotlight
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
    }
}

// MARK: - Spotlight Shape (Hole in Overlay)

struct SpotlightShape: Shape {
    let spotlightRect: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Full screen rectangle
        path.addRect(rect)

        // Create circular hole
        let circlePath = Path(ellipseIn: spotlightRect.insetBy(dx: -10, dy: -10))

        // Subtract the circle from the full rect
        return path.subtracting(circlePath)
    }
}

// MARK: - Hint Card

struct HintCard: View {
    let hint: TutorialHint
    let geometry: GeometryProxy
    let onNext: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Arrow pointing to feature (if applicable)
            if hint.arrowDirection != .none {
                ArrowPointer(direction: hint.arrowDirection)
                    .fill(Color(hex: "#FFD700"))
                    .frame(width: 30, height: 30)
                    .offset(y: getArrowOffset())
            }

            // Card content
            VStack(spacing: 12) {
                // Title
                Text(hint.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Description
                Text(hint.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                // Buttons
                HStack(spacing: 12) {
                    // Skip button
                    Button(action: onDismiss) {
                        Text(LocalizedString("action.skip"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }

                    // Next button
                    Button(action: onNext) {
                        HStack(spacing: 6) {
                            Text(LocalizedString("action.next"))
                                .font(.system(size: 16, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "#1a1a1a"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#FFD700"),
                                    Color(hex: "#FFC72C")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color(hex: "#FFD700").opacity(0.4), radius: 8)
                    }
                }
                .padding(.top, 4)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#1a1a2e"))
                    .shadow(color: Color.black.opacity(0.3), radius: 20)
            )
            .padding(.horizontal, 32)
        }
        .position(getCardPosition())
    }

    private func getCardPosition() -> CGPoint {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height

        // Position card based on spotlight location
        switch hint.textPosition {
        case .top:
            return CGPoint(
                x: screenWidth / 2,
                y: hint.position.minY - 150
            )
        case .bottom:
            return CGPoint(
                x: screenWidth / 2,
                y: hint.position.maxY + 150
            )
        case .left:
            return CGPoint(
                x: screenWidth / 4,
                y: screenHeight / 2
            )
        case .right:
            return CGPoint(
                x: screenWidth * 0.75,
                y: screenHeight / 2
            )
        }
    }

    private func getArrowOffset() -> CGFloat {
        switch hint.arrowDirection {
        case .up:
            return -15
        case .down:
            return 15
        case .left, .right:
            return 0
        case .none:
            return 0
        }
    }
}

// MARK: - Arrow Pointer Shape

struct ArrowPointer: Shape {
    let direction: ArrowDirection

    func path(in rect: CGRect) -> Path {
        var path = Path()

        switch direction {
        case .down:
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        case .up:
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))

        case .left:
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))

        case .right:
            path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))

        case .none:
            break
        }

        path.closeSubpath()
        return path
    }
}

#Preview {
    TutorialSpotlightView(
        hint: TutorialHint(
            id: "test",
            title: "Tap on Markers",
            description: "Tap on any stadium marker to see details and collect stickers!",
            position: CGRect(x: 100, y: 200, width: 80, height: 80),
            arrowDirection: .down,
            textPosition: .bottom
        ),
        onNext: {},
        onDismiss: {}
    )
}
