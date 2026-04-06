//
//  OnboardingView.swift
//  Atenea
//
//  Onboarding screen following Apple HIG with beautiful animations
//

import SwiftUI

// MARK: - Onboarding Page Model
struct OnboardingPage: Identifiable {
    let id = UUID()
    let systemIcon: String
    let title: String
    let description: String
    let accentColor: Color
    let secondaryColor: Color
}

// MARK: - Floating Particle Model
struct FloatingParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var color: Color
    var delay: Double
}

// MARK: - Soccer Ball Model
struct SoccerBall: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var rotation: Double
    var opacity: Double
}

// MARK: - Pass Trajectory Model
struct PassTrajectory: Identifiable {
    let id = UUID()
    var startPoint: CGPoint
    var endPoint: CGPoint
    var progress: CGFloat
    var color: Color
}

// MARK: - Confetti Model
struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var color: Color
    var scale: CGFloat
}

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    @State private var isAnimating = false
    @State private var particles: [FloatingParticle] = []
    @State private var backgroundOffset: CGFloat = 0
    @State private var soccerBalls: [SoccerBall] = []
    @State private var passTrajectories: [PassTrajectory] = []
    @State private var confetti: [ConfettiPiece] = []
    @State private var showConfetti = false
    @State private var celebrationScale: CGFloat = 1.0

    // Onboarding pages
    let pages: [OnboardingPage] = [
        OnboardingPage(
            systemIcon: "map.fill",
            title: LocalizedString("onboarding.feature1"),
            description: LocalizedString("onboarding.page1.description"),
            accentColor: .blue,
            secondaryColor: .cyan
        ),
        OnboardingPage(
            systemIcon: "sparkles",
            title: LocalizedString("onboarding.feature2"),
            description: LocalizedString("onboarding.page2.description"),
            accentColor: .purple,
            secondaryColor: .pink
        ),
        OnboardingPage(
            systemIcon: "person.3.fill",
            title: LocalizedString("onboarding.feature3"),
            description: LocalizedString("onboarding.page3.description"),
            accentColor: .green,
            secondaryColor: .mint
        )
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated gradient background
                AnimatedGradientBackground(
                    colors: [
                        pages[currentPage].accentColor.opacity(0.3),
                        pages[currentPage].secondaryColor.opacity(0.2),
                        Color(.systemBackground)
                    ],
                    offset: backgroundOffset
                )
                .ignoresSafeArea()

                // Floating particles (subtle background)
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color.opacity(particle.opacity * 0.5))
                        .frame(width: particle.size, height: particle.size)
                        .blur(radius: particle.size / 3)
                        .position(x: particle.x, y: particle.y)
                }

                // Soccer balls floating
                ForEach(soccerBalls) { ball in
                    SoccerBallView(size: ball.size)
                        .opacity(ball.opacity)
                        .rotationEffect(.degrees(ball.rotation))
                        .position(x: ball.x, y: ball.y)
                }

                // Pass trajectories (curved lines)
                ForEach(passTrajectories) { trajectory in
                    PassTrajectoryView(
                        startPoint: trajectory.startPoint,
                        endPoint: trajectory.endPoint,
                        progress: trajectory.progress,
                        color: trajectory.color
                    )
                }

                // Confetti celebration (last page only)
                if showConfetti {
                    ForEach(confetti) { piece in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(piece.color)
                            .frame(width: 8, height: 12)
                            .scaleEffect(piece.scale)
                            .rotationEffect(.degrees(piece.rotation))
                            .position(x: piece.x, y: piece.y)
                    }
                }

                VStack(spacing: 0) {
                    // Page content
                    TabView(selection: $currentPage) {
                        ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                            OnboardingPageView(
                                page: page,
                                isAnimating: isAnimating,
                                isCurrentPage: currentPage == index
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    .onChange(of: currentPage) { oldValue, newValue in
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                            backgroundOffset = CGFloat(newValue) * 100
                        }

                        // Haptic feedback
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()

                        // Show confetti on last page
                        if newValue == pages.count - 1 {
                            showConfetti = true
                            initializeConfetti()
                            startConfettiAnimation()
                        } else {
                            showConfetti = false
                        }

                        // Animate pass trajectories when changing pages
                        createPassTrajectory(in: geometry.size)
                    }

                    // Bottom section with glassmorphism
                    VStack(spacing: 16) {
                        // Primary button with animation
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()

                            if currentPage < pages.count - 1 {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    currentPage += 1
                                }
                            } else {
                                // Goal celebration!
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                    celebrationScale = 1.3
                                }

                                // Explosion effect
                                let notificationGenerator = UINotificationFeedbackGenerator()
                                notificationGenerator.notificationOccurred(.success)

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showOnboarding = false
                                    }
                                }
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(currentPage < pages.count - 1 ?
                                     LocalizedString("action.continue") :
                                     LocalizedString("action.start"))
                                    .font(.body.weight(.semibold))

                                Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                                    .font(.body.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                ZStack {
                                    // Animated gradient
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            pages[currentPage].accentColor,
                                            pages[currentPage].secondaryColor
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )

                                    // Shimmer effect
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0),
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .offset(x: backgroundOffset * 2)
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(
                                color: pages[currentPage].accentColor.opacity(0.4),
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())

                        // Skip button (only show if not on last page)
                        if currentPage < pages.count - 1 {
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()

                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showOnboarding = false
                                }
                            }) {
                                Text(LocalizedString("action.skip"))
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
                    .background(.ultraThinMaterial)
                }
            }
        }
        .onAppear {
            initializeParticles()
            initializeSoccerBalls()

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                isAnimating = true
            }

            startParticleAnimation()
            startSoccerBallAnimation()
        }
    }

    // MARK: - Animation Functions
    private func initializeParticles() {
        particles = (0..<20).map { index in
            FloatingParticle(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                size: CGFloat.random(in: 20...60),
                opacity: Double.random(in: 0.1...0.3),
                color: [Color.blue, Color.purple, Color.green, Color.cyan, Color.pink].randomElement() ?? .blue,
                delay: Double.random(in: 0...2)
            )
        }
    }

    private func startParticleAnimation() {
        for index in particles.indices {
            animateParticle(at: index)
        }
    }

    private func animateParticle(at index: Int) {
        let duration = Double.random(in: 3...6)
        let delay = particles[index].delay

        withAnimation(
            .easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            particles[index].y += CGFloat.random(in: -50...50)
            particles[index].x += CGFloat.random(in: -30...30)
            particles[index].opacity = Double.random(in: 0.05...0.25)
        }
    }

    // MARK: - Soccer Ball Functions
    private func initializeSoccerBalls() {
        soccerBalls = (0..<8).map { _ in
            SoccerBall(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: -100...UIScreen.main.bounds.height),
                size: CGFloat.random(in: 30...60),
                rotation: Double.random(in: 0...360),
                opacity: Double.random(in: 0.15...0.35)
            )
        }
    }

    private func startSoccerBallAnimation() {
        for index in soccerBalls.indices {
            animateSoccerBall(at: index)
        }
    }

    private func animateSoccerBall(at index: Int) {
        let duration = Double.random(in: 4...8)
        let delay = Double.random(in: 0...2)

        withAnimation(
            .easeInOut(duration: duration)
            .repeatForever(autoreverses: false)
            .delay(delay)
        ) {
            soccerBalls[index].y = UIScreen.main.bounds.height + 100
            soccerBalls[index].rotation += 360
        }

        // Reset position when ball goes off screen
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + delay) {
            soccerBalls[index].y = -100
            soccerBalls[index].x = CGFloat.random(in: 0...UIScreen.main.bounds.width)
            animateSoccerBall(at: index)
        }
    }

    // MARK: - Pass Trajectory Functions
    private func createPassTrajectory(in size: CGSize) {
        let startPoint = CGPoint(
            x: CGFloat.random(in: 0...size.width),
            y: CGFloat.random(in: size.height * 0.3...size.height * 0.7)
        )
        let endPoint = CGPoint(
            x: CGFloat.random(in: 0...size.width),
            y: CGFloat.random(in: size.height * 0.3...size.height * 0.7)
        )

        let trajectory = PassTrajectory(
            startPoint: startPoint,
            endPoint: endPoint,
            progress: 0,
            color: pages[currentPage].accentColor
        )

        passTrajectories.append(trajectory)

        // Animate trajectory
        if let index = passTrajectories.firstIndex(where: { $0.id == trajectory.id }) {
            withAnimation(.easeInOut(duration: 1.0)) {
                passTrajectories[index].progress = 1.0
            }

            // Remove after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                passTrajectories.removeAll { $0.id == trajectory.id }
            }
        }
    }

    // MARK: - Confetti Functions
    private func initializeConfetti() {
        let screenWidth = UIScreen.main.bounds.width
        confetti = (0..<50).map { _ in
            ConfettiPiece(
                x: CGFloat.random(in: 0...screenWidth),
                y: -50,
                rotation: Double.random(in: 0...360),
                color: [
                    pages[currentPage].accentColor,
                    pages[currentPage].secondaryColor,
                    .yellow,
                    .orange,
                    .red
                ].randomElement() ?? .blue,
                scale: CGFloat.random(in: 0.5...1.5)
            )
        }
    }

    private func startConfettiAnimation() {
        for index in confetti.indices {
            let delay = Double(index) * 0.02
            let duration = Double.random(in: 2...4)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: duration)) {
                    confetti[index].y = UIScreen.main.bounds.height + 100
                    confetti[index].rotation += 720
                }
            }
        }
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    let isAnimating: Bool
    let isCurrentPage: Bool

    @State private var iconRotation: Double = 0
    @State private var iconScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Icon with gradient background and animations
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                page.accentColor.opacity(0.3),
                                page.secondaryColor.opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 60,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(isAnimating && isCurrentPage ? CGFloat(1.2) : CGFloat(0.8))
                    .blur(radius: 20)

                // Middle circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                page.accentColor.opacity(0.2),
                                page.secondaryColor.opacity(0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(isAnimating && isCurrentPage ? CGFloat(1.0) : CGFloat(0.7))

                // Icon container with glassmorphism
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)

                    Image(systemName: page.systemIcon)
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    page.accentColor,
                                    page.secondaryColor
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce, options: .speed(0.5), value: isAnimating && isCurrentPage)
                        .scaleEffect(iconScale)
                        .rotationEffect(.degrees(iconRotation))
                }
                .shadow(
                    color: page.accentColor.opacity(0.3),
                    radius: 20,
                    x: 0,
                    y: 10
                )
            }
            .padding(.bottom, 20)
            .onChange(of: isCurrentPage) { oldValue, newValue in
                if newValue {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                        iconScale = 1.1
                    }
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                        iconScale = 1.0
                    }
                }
            }

            // Title with gradient
            Text(page.title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            page.accentColor,
                            page.secondaryColor
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 30)
                .padding(.horizontal, 32)

            // Description
            Text(page.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .padding(.horizontal, 40)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 30)

            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Animated Gradient Background
struct AnimatedGradientBackground: View {
    let colors: [Color]
    let offset: CGFloat

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .hueRotation(.degrees(Double(offset)))
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? CGFloat(0.96) : CGFloat(1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Soccer Ball View
struct SoccerBallView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // White base
            Circle()
                .fill(.white)
                .frame(width: size, height: size)

            // Black pentagons pattern
            ForEach(0..<5) { index in
                SoccerPentagonShape()
                    .fill(.black)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .offset(y: -size * 0.25)
                    .rotationEffect(.degrees(Double(index) * 72))
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
    }
}

// MARK: - Soccer Pentagon Shape
struct SoccerPentagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2

        for i in 0..<5 {
            let angle = (Double(i) * 72.0 - 90.0) * .pi / 180
            let point = CGPoint(
                x: center.x + radius * CGFloat(cos(angle)),
                y: center.y + radius * CGFloat(sin(angle))
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Pass Trajectory View
struct PassTrajectoryView: View {
    let startPoint: CGPoint
    let endPoint: CGPoint
    let progress: CGFloat
    let color: Color

    var body: some View {
        Path { path in
            path.move(to: startPoint)

            // Create curved path (bezier curve)
            let controlHeight = min(startPoint.y, endPoint.y) - 100
            let controlPoint = CGPoint(
                x: (startPoint.x + endPoint.x) / 2,
                y: controlHeight
            )

            path.addQuadCurve(to: endPoint, control: controlPoint)
        }
        .trim(from: 0, to: progress)
        .stroke(
            LinearGradient(
                gradient: Gradient(colors: [
                    color.opacity(0.8),
                    color.opacity(0.3),
                    color.opacity(0)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [10, 5])
        )
        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}
