//
//  TimbreNotificationView.swift
//  atenea
//
//  Banner de notificación de timbre para el merchant
//

import SwiftUI

struct TimbreNotificationView: View {
    let timbre: TimbreEvent
    let onRespond: (TimbreResponseType) -> Void
    let onDismiss: () -> Void

    @State private var pulseOpacity: Double = 0.6

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Icono tipo
                Text(timbre.type.emoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(timbre.clientName) te timbró")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)

                    HStack(spacing: 4) {
                        Text(timbre.type.displayName)
                            .font(.system(size: 13))
                            .foregroundColor(.orange)

                        if let msg = timbre.message {
                            Text("· \"\(msg)\"")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                    }

                    Text(timbre.timeAgo)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Dismiss
                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(14)

            // Botones de respuesta rápida
            HStack(spacing: 8) {
                ForEach([TimbreResponseType.onMyWay, .waitHere, .busy], id: \.self) { responseType in
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onRespond(responseType)
                    } label: {
                        HStack(spacing: 4) {
                            Text(responseType.emoji)
                                .font(.system(size: 14))
                            Text(responseType.displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(responseButtonColor(responseType))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.orange.opacity(0.1))
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.orange.opacity(pulseOpacity * 0.5), lineWidth: 1)
            }
        )
        .shadow(color: .orange.opacity(0.2), radius: 16, y: 4)
        .padding(.horizontal, 16)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseOpacity = 1.0
            }
        }
    }

    private func responseButtonColor(_ type: TimbreResponseType) -> Color {
        switch type {
        case .onMyWay: return .green.opacity(0.3)
        case .waitHere: return .blue.opacity(0.3)
        case .busy: return .gray.opacity(0.3)
        case .closed: return .red.opacity(0.3)
        }
    }
}
