//
//  OnboardingWelcomeView.swift
//  atenea
//
//  Vista de bienvenida personalizada después del login exitoso
//  Basada en diseño Coppel con efecto liquid glass
//

import SwiftUI

struct OnboardingWelcomeView: View {
    let userName: String
    let onContinue: () -> Void

    @State private var isAnimating = false
    @State private var particles: [FloatingParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient con colores Coppel
                backgroundGradient

                // Floating particles
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color.opacity(particle.opacity * 0.5))
                        .frame(width: particle.size, height: particle.size)
                        .blur(radius: particle.size / 3)
                        .position(x: particle.x, y: particle.y)
                }

                VStack(spacing: 0) {
                    Spacer()

                    // Hero section
                    heroSection

                    Spacer()

                    // Action button
                    actionButton
                        .padding(.horizontal, 32)
                        .padding(.bottom, 60)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            initializeParticles()

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                isAnimating = true
            }

            startParticleAnimation()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            // Primary gradient
            LinearGradient(
                colors: [
                    Color.coppelBlue,
                    Color.coppelMediumBlue,
                    Color.coppelDarkBlue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative circles (liquid glass effect)
            decorativeCircles
        }
    }

    private var decorativeCircles: some View {
        ZStack {
            // Top-right yellow accent
            Circle()
                .fill(Color.coppelYellow.opacity(0.12))
                .frame(width: UIScreen.main.bounds.width * 1.2)
                .blur(radius: 100)
                .offset(x: UIScreen.main.bounds.width * 0.4, y: -UIScreen.main.bounds.height * 0.3)

            // Bottom-left light accent
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: UIScreen.main.bounds.width * 1.4)
                .blur(radius: 120)
                .offset(x: -UIScreen.main.bounds.width * 0.5, y: UIScreen.main.bounds.height * 0.3)

            // Floating glass orb
            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 250, height: 250)
                .blur(radius: 2)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .offset(x: -100, y: -250)

            Circle()
                .fill(Color.coppelYellow.opacity(0.06))
                .frame(width: 180, height: 180)
                .blur(radius: 2)
                .overlay(
                    Circle()
                        .stroke(Color.coppelYellow.opacity(0.12), lineWidth: 1)
                )
                .offset(x: 120, y: 350)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 24) {
            // Brand icon
            brandIcon

            // Personalized greeting
            VStack(spacing: 8) {
                Text("¡Bienvenido")
                    .font(.system(size: 40, weight: .black, design: .default))
                    .foregroundColor(.white)
                    .tracking(-1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(userName)!")
                    .font(.system(size: 40, weight: .black, design: .default))
                    .foregroundColor(.white)
                    .tracking(-1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Tagline
            Text("Tu camino al éxito continúa aquí")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .tracking(-0.3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
        }
        .padding(.horizontal, 32)
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 50)
    }

    private var brandIcon: some View {
        HStack {
            ZStack {
                // Background with rocket
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.coppelYellow)
                    .frame(width: 64, height: 64)
                    .shadow(
                        color: Color.coppelYellow.opacity(0.4),
                        radius: 16,
                        x: 0,
                        y: 8
                    )

                // Rocket icon
                Image(systemName: "rocket.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.coppelBlue)
            }

            Spacer()
        }
        .padding(.bottom, 32)
    }

    // MARK: - Action Button

    private var actionButton: some View {
        VStack(spacing: 24) {
            // Primary button
            Button(action: onContinue) {
                HStack(spacing: 10) {
                    Image(systemName: "touchid")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.coppelBlue)

                    Text("Ingresar")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.coppelBlue)
                        .tracking(-0.3)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: CoppelTheme.CornerRadius.full, style: .continuous)
                        .fill(Color.coppelYellow)
                        .shadow(
                            color: Color.coppelYellow.opacity(0.4),
                            radius: 20,
                            x: 0,
                            y: 10
                        )
                )
            }
            .buttonStyle(ScaleButtonStyle())

            // Secondary link
            Button(action: {
                // TODO: Handle switch account
            }) {
                Text("Quiero entrar con otra cuenta")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .underline(true, color: .white.opacity(0.3))
                    .tracking(0.5)
            }
        }
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 30)
    }

    // MARK: - Animation Functions

    private func initializeParticles() {
        particles = (0..<15).map { index in
            FloatingParticle(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                size: CGFloat.random(in: 20...50),
                opacity: Double.random(in: 0.1...0.25),
                color: [Color.coppelYellow, Color.white, Color.coppelLightBlue].randomElement() ?? .white,
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
            particles[index].opacity = Double.random(in: 0.05...0.2)
        }
    }
}

#Preview {
    OnboardingWelcomeView(userName: "Gummy") {
        print("Continue tapped")
    }
}
