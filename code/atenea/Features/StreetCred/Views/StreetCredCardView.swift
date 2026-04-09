//
//  StreetCredCardView.swift
//  atenea
//
//  Card compacta de Street Cred para el MerchantHomeView
//

import SwiftUI

private enum CoppelColors {
    static let blue = Color(red: 0.110, green: 0.259, blue: 0.910)
    static let yellow = Color(red: 0.941, green: 0.824, blue: 0.141)
    static let darkBlue = Color(red: 0.031, green: 0.090, blue: 0.329)
    static let green = Color(red: 0.039, green: 0.749, blue: 0.310)
    static let orange = Color(red: 1.0, green: 0.682, blue: 0.263)
    static let beige = Color(red: 0.933, green: 0.910, blue: 0.890)
    static let darkGrey = Color(red: 0.290, green: 0.290, blue: 0.290)
}

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
                            .foregroundColor(levelColor(score.level))
                        Text("Street Cred")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(CoppelColors.darkBlue)
                        Text(score.level.displayName)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(levelColor(score.level))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(levelColor(score.level).opacity(0.12)))
                    }

                    // Progreso al siguiente nivel
                    if let next = score.level.nextLevel {
                        VStack(alignment: .leading, spacing: 3) {
                            ProgressView(value: score.progressToNextLevel)
                                .tint(levelColor(score.level))
                                .scaleEffect(y: 1.5, anchor: .center)

                            Text(String(format: LocalizedString("streetcred.ptsFor"), score.pointsToNextLevel, next.displayName))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(CoppelColors.darkGrey)
                        }
                    } else {
                        Text(LocalizedString("streetcred.maxLevel"))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(levelColor(score.level))
                    }

                    // Beneficio crediticio
                    if score.isCreditEligible {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundColor(CoppelColors.green)
                            Text(score.creditTier)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(CoppelColors.green)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(CoppelColors.darkGrey.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: CoppelColors.darkBlue.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(levelColor(score.level).opacity(0.15), lineWidth: 1)
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
                .stroke(CoppelColors.beige, lineWidth: 6)

            // Progress ring
            Circle()
                .trim(from: 0, to: animateRing ? CGFloat(score.totalScore) / 1000.0 : 0)
                .stroke(
                    levelColor(score.level),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Score number
            VStack(spacing: 0) {
                Text("\(displayedScore)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(CoppelColors.darkBlue)
                    .contentTransition(.numericText())

                // Streak flame
                if score.streak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                            .foregroundColor(CoppelColors.orange)
                        Text("\(score.streak)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(CoppelColors.orange)
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

    private func levelColor(_ level: StreetCredLevel) -> Color {
        switch level {
        case .nuevo: return CoppelColors.darkGrey
        case .bronce: return CoppelColors.orange
        case .plata: return Color(red: 0.660, green: 0.710, blue: 0.773) // #A8B5C5
        case .oro: return CoppelColors.yellow
        case .platino: return CoppelColors.blue
        case .diamante: return Color(red: 0.094, green: 0.353, blue: 0.859) // #185ADB
        }
    }
}

// MARK: - Mini Badge (para listas y chips)

struct StreetCredMiniBadge: View {
    let level: StreetCredLevel
    let score: Int

    private func levelColor(_ level: StreetCredLevel) -> Color {
        switch level {
        case .nuevo: return Color(red: 0.290, green: 0.290, blue: 0.290)
        case .bronce: return Color(red: 1.0, green: 0.682, blue: 0.263)
        case .plata: return Color(red: 0.660, green: 0.710, blue: 0.773)
        case .oro: return Color(red: 0.941, green: 0.824, blue: 0.141)
        case .platino: return Color(red: 0.110, green: 0.259, blue: 0.910)
        case .diamante: return Color(red: 0.094, green: 0.353, blue: 0.859)
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
                .font(.system(size: 9, weight: .bold))
            Text("\(score)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .foregroundColor(levelColor(level))
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(levelColor(level).opacity(0.12)))
    }
}
