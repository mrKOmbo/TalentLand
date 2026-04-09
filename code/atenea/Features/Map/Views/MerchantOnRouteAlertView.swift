//
//  MerchantOnRouteAlertView.swift
//  atenea
//
//  Banner in-app que aparece al cliente cuando un comerciante cercano inicia su ruta.
//

import SwiftUI

struct MerchantOnRouteAlertView: View {
    let merchant: Merchant
    let onNavigate: () -> Void
    let onDismiss: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    private var distanceText: String {
        guard merchant.currentLocation != nil else { return "" }
        return "cerca de ti"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Emoji pulsante del comerciante
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 46, height: 46)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulseScale)

                Text(merchant.emoji)
                    .font(.system(size: 22))
            }

            // Texto
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    Text("En ruta ahora")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                }

                Text(merchant.businessName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("\(merchant.category.displayName) · \(distanceText)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Acciones
            VStack(spacing: 6) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onNavigate()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.system(size: 11))
                        Text("Ir al encuentro")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.blue))
                }
                .buttonStyle(.plain)

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThickMaterial)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.green.opacity(0.06))
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.green.opacity(0.25), lineWidth: 0.5)
            }
            .shadow(color: Color.green.opacity(0.15), radius: 16, y: 6)
        )
        .padding(.horizontal, 16)
        .onAppear { pulseScale = 1.2 }
    }
}
