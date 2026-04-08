//
//  NearbyMerchantsListView.swift
//  atenea
//
//  Lista horizontal de merchants cercanos con indicador de presencia
//

import SwiftUI

struct NearbyMerchantsListView: View {
    @ObservedObject private var presenceManager = PresenceManager.shared
    let onMerchantTap: (Merchant) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(presenceManager.activeMerchantPresences.filter { !$0.isStale }) { presence in
                    Button {
                        onMerchantTap(presence.merchant)
                    } label: {
                        PresenceMerchantChip(presence: presence)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Presence Chip

struct PresenceMerchantChip: View {
    let presence: MerchantPresence

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                Text(presence.merchant.emoji)
                    .font(.system(size: 28))
                    .frame(width: 52, height: 52)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())

                // Indicador de actividad con color por estado
                Circle()
                    .fill(presence.activityStatus.color)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().strokeBorder(Color(hex: "#0A0A1A"), lineWidth: 1.5))
            }

            Text(presence.merchant.businessName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(presence.formattedDistance)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))

            // Badge fijo/nómada
            Text(presence.merchant.isStatic ? "Fijo" : "Nómada")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(presence.merchant.isStatic ? .blue : .orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(presence.merchant.isStatic ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                )
        }
        .frame(width: 72)
    }
}
