//
//  StreetCredBadgeView.swift
//  atenea
//
//  Badge compacta de Street Cred para MerchantDetailSheet (vista del cliente)
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

struct StreetCredBadgeView: View {
    let score: StreetCredScore

    private func levelColor(_ level: StreetCredLevel) -> Color {
        switch level {
        case .nuevo: return CoppelColors.darkGrey
        case .bronce: return CoppelColors.orange
        case .plata: return Color(red: 0.660, green: 0.710, blue: 0.773)
        case .oro: return CoppelColors.yellow
        case .platino: return CoppelColors.blue
        case .diamante: return Color(red: 0.094, green: 0.353, blue: 0.859)
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            // Mini gauge
            ZStack {
                Circle()
                    .stroke(CoppelColors.beige, lineWidth: 3)
                    .frame(width: 32, height: 32)

                Circle()
                    .trim(from: 0, to: CGFloat(score.totalScore) / 1000.0)
                    .stroke(
                        levelColor(score.level),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))

                Text("\(score.totalScore)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(CoppelColors.darkBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: score.level.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text("Street Cred \(score.level.displayName)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundColor(levelColor(score.level))

                if score.isCreditEligible {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 8))
                        Text(LocalizedString("streetcred.verifiedByAtenea"))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(CoppelColors.green)
                }
            }

            Spacer()

            if score.streak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                    Text("\(score.streak)d")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
                .foregroundColor(CoppelColors.orange)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white)
                .shadow(color: CoppelColors.darkBlue.opacity(0.06), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(levelColor(score.level).opacity(0.15), lineWidth: 1)
        )
    }
}
