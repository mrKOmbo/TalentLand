//
//  ARMenuCardView.swift
//  atenea
//
//  Card de menú flotante para AR Street Menu
//  Muestra productos con precios convertidos al idioma/moneda del turista
//

import SwiftUI

struct ARMenuCardView: View {
    let merchant: Merchant
    let distance: Double // metros
    let languageCode: String
    let onTimbre: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header con triángulo apuntando abajo (como tooltip)
            VStack(spacing: 10) {
                // Nombre del negocio
                HStack(spacing: 8) {
                    Text(merchant.emoji)
                        .font(.system(size: 22))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(merchant.businessName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        HStack(spacing: 6) {
                            Text(merchant.category.displayName)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))

                            Text("·")
                                .foregroundColor(.white.opacity(0.3))

                            Text("\(Int(distance))m")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.cyan)
                        }
                    }

                    Spacer()

                    // Badge de distancia
                    VStack(spacing: 2) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text("\(Int(distance))m")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.cyan)
                    .padding(6)
                    .background(Color.cyan.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Productos (máximo 4)
                VStack(spacing: 6) {
                    ForEach(Array(merchant.products.filter(\.isAvailable).prefix(4))) { product in
                        productRow(product)
                    }
                }

                // Botón de timbre
                Button(action: onTimbre) {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 12))
                        Text("Timbrar")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.orange, .red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.black.opacity(0.5))
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                }
            )

            // Triángulo apuntando abajo
            ARMenuTriangle()
                .fill(Color.black.opacity(0.5))
                .frame(width: 16, height: 8)
        }
        .frame(width: 220)
    }

    // MARK: - Product Row

    private func productRow(_ product: Product) -> some View {
        HStack(spacing: 8) {
            Text(product.emoji)
                .font(.system(size: 16))

            Text(product.name)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            // Precio convertido
            let prices = CurrencyConverter.dualPrice(product.price, languageCode: languageCode)
            VStack(alignment: .trailing, spacing: 1) {
                Text(prices.local)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.green)

                if !prices.mxn.isEmpty {
                    Text(prices.mxn)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
    }
}

// MARK: - ARMenuTriangle Shape

struct ARMenuTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - rect.width / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
