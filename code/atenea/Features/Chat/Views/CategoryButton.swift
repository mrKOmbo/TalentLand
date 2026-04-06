//
//  CategoryButton.swift
//  Atenea
//
//  Componente de botón de categoría para quick actions
//

import SwiftUI

struct CategoryButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    var isWorldCupDay: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, isWorldCupDay ? 16 : 14)
            .padding(.vertical, isWorldCupDay ? 10 : 8)
            .background(
                RoundedRectangle(cornerRadius: isWorldCupDay ? 20 : 16, style: .continuous)
                    .fill(
                        isWorldCupDay ?
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [color, color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: color.opacity(isWorldCupDay ? 0.5 : 0.3), radius: isWorldCupDay ? 8 : 4, x: 0, y: isWorldCupDay ? 4 : 2)
            .overlay(
                Group {
                    if isWorldCupDay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
                }
            )
            .scaleEffect(isWorldCupDay ? CGFloat(1.05) : CGFloat(1.0))
        }
    }
}

#Preview {
    HStack {
        CategoryButton(
            title: "Chat Claude",
            icon: "message.badge.waveform.fill",
            color: Color.purple,
            isSelected: false,
            action: {}
        )

        CategoryButton(
            title: "UltraThink",
            icon: "brain.head.profile",
            color: Color.cyan,
            isSelected: false,
            action: {}
        )
    }
    .padding()
    .background(Color.black)
}
