//
//  StreetCredBadgeView.swift
//  atenea
//
//  Badge compacta de Street Cred para MerchantDetailSheet (vista del cliente)
//

import SwiftUI

struct StreetCredBadgeView: View {
    let score: StreetCredScore

    var body: some View {
        HStack(spacing: 10) {
            // Mini gauge
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3)
                    .frame(width: 32, height: 32)

                Circle()
                    .trim(from: 0, to: CGFloat(score.totalScore) / 1000.0)
                    .stroke(
                        LinearGradient(colors: score.level.gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))

                Text("\(score.totalScore)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: score.level.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text("Street Cred \(score.level.displayName)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(score.level.color)

                if score.isCreditEligible {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 8))
                        Text("Verificado por Atenea")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.green.opacity(0.8))
                }
            }

            Spacer()

            if score.streak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                    Text("\(score.streak)d")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.orange)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(score.level.color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(score.level.color.opacity(0.15), lineWidth: 0.5)
                )
        )
    }
}
