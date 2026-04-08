//
//  StreetCredCardView.swift
//  atenea
//
//  Card compacta de Street Cred para el MerchantHomeView
//

import SwiftUI

struct StreetCredCardView: View {
    let score: StreetCredScore
    let onTap: () -> Void

    @State private var animateRing = false
    @State private var animateScore = false
    @State private var displayedScore = 0

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Gauge circular
                scoreGauge
                    .frame(width: 72, height: 72)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: score.level.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(score.level.color)
                        Text("Street Cred")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text(score.level.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(score.level.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(score.level.color.opacity(0.15)))
                    }

                    // Progreso al siguiente nivel
                    if let next = score.level.nextLevel {
                        VStack(alignment: .leading, spacing: 3) {
                            ProgressView(value: score.progressToNextLevel)
                                .tint(score.level.color)
                                .scaleEffect(y: 1.5, anchor: .center)

                            Text("\(score.pointsToNextLevel) pts para \(next.displayName)")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    } else {
                        Text("Nivel maximo alcanzado")
                            .font(.system(size: 11))
                            .foregroundColor(score.level.color)
                    }

                    // Beneficio crediticio
                    if score.isCreditEligible {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                            Text(score.creditTier)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(score.level.color.opacity(0.08))
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(score.level.color.opacity(0.2), lineWidth: 0.5)
                }
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animateRing = true
            }
            animateScoreCount()
        }
    }

    // MARK: - Score Gauge

    private var scoreGauge: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 6)

            // Progress ring
            Circle()
                .trim(from: 0, to: animateRing ? CGFloat(score.totalScore) / 1000.0 : 0)
                .stroke(
                    LinearGradient(
                        colors: score.level.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Score number
            VStack(spacing: 0) {
                Text("\(displayedScore)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())

                // Streak flame
                if score.streak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.orange)
                        Text("\(score.streak)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }

    private func animateScoreCount() {
        let target = score.totalScore
        let duration = 1.0
        let steps = 30
        let stepDuration = duration / Double(steps)

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.none) {
                    displayedScore = Int(Double(target) * Double(i) / Double(steps))
                }
            }
        }
    }
}

// MARK: - Mini Badge (para listas y chips)

struct StreetCredMiniBadge: View {
    let level: StreetCredLevel
    let score: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
                .font(.system(size: 9, weight: .bold))
            Text("\(score)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .foregroundColor(level.color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(level.color.opacity(0.15)))
    }
}
