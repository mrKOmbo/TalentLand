//
//  MerchantTimbresPanel.swift
//  atenea
//
//  Panel flotante inferior para comerciantes: muestra timbres recibidos de clientes
//

import SwiftUI
import CoreLocation

struct MerchantTimbresPanel: View {
    let timbres: [TimbreEvent]
    let merchantLocation: CLLocationCoordinate2D?
    let onTimbreTap: (TimbreEvent) -> Void

    private var sortedTimbres: [TimbreEvent] {
        timbres.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        VStack(spacing: 0) {
            if !sortedTimbres.isEmpty {
                timbresList
            } else {
                emptyState
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThickMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -5)
        )
    }

    // MARK: - Timbres List

    private var timbresList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(sortedTimbres) { timbre in
                    Button {
                        onTimbreTap(timbre)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        TimbreCard(
                            timbre: timbre,
                            distance: merchantLocation.map { distanceToClient(from: $0, timbre: timbre) }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 8) {
            Image(systemName: "bell.slash")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Text(LocalizedString("merchant.noTimbres"))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
    }

    private func distanceToClient(from merchantLoc: CLLocationCoordinate2D, timbre: TimbreEvent) -> Double {
        MerchantManager.haversineDistance(
            lat1: merchantLoc.latitude, lon1: merchantLoc.longitude,
            lat2: timbre.clientLatitude, lon2: timbre.clientLongitude
        )
    }
}

// MARK: - Timbre Card

struct TimbreCard: View {
    let timbre: TimbreEvent
    let distance: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: tipo emoji + estado
            HStack(spacing: 6) {
                Text(timbre.type.emoji)
                    .font(.system(size: 26))

                Spacer()

                if !timbre.isRead {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                } else if timbre.isResponded {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                }
            }

            // Nombre del cliente
            Text(timbre.clientName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            // Tipo + distancia
            HStack(spacing: 4) {
                Text(timbre.type.displayName)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                if let dist = distance, dist < .infinity {
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(formatDistance(dist))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue)
                }
            }

            // Tiempo
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                Text(timbre.timeAgo)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.secondary.opacity(0.1)))
        }
        .padding(10)
        .frame(width: 140, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            !timbre.isRead ? Color.red.opacity(0.4) : Color.white.opacity(0.15),
                            lineWidth: !timbre.isRead ? 1.5 : 0.5
                        )
                )
        )
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }
}
