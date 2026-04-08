//
//  DemandInsightsView.swift
//  atenea
//
//  Vista de insights de demanda para el merchant
//

import SwiftUI

struct DemandInsightsView: View {
    @ObservedObject private var demandManager = DemandZoneManager.shared
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0A0A1A"), Color(hex: "#0D1B2A")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    header

                    // Resumen
                    summaryCard

                    // Top zonas
                    topZonesSection

                    // Demanda por categoría
                    categoryBreakdown

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Zonas de demanda")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text("Última hora")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        HStack(spacing: 16) {
            DemandStatBox(
                value: "\(demandManager.totalDemandLastHour())",
                label: "Búsquedas",
                icon: "magnifyingglass",
                color: .blue
            )
            DemandStatBox(
                value: "\(demandManager.demandZones.count)",
                label: "Zonas activas",
                icon: "mappin.and.ellipse",
                color: .orange
            )
            DemandStatBox(
                value: demandManager.topZones(limit: 1).first?.topCategory?.emoji ?? "—",
                label: "Top categoría",
                icon: "star.fill",
                color: .yellow
            )
        }
    }

    // MARK: - Top Zones

    private var topZonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TOP ZONAS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .kerning(1.5)

            ForEach(Array(demandManager.topZones(limit: 5).enumerated()), id: \.element.id) { index, zone in
                DemandZoneRow(zone: zone, rank: index + 1) {
                    dismiss()
                    selectedTab = 1
                }
            }

            if demandManager.demandZones.isEmpty {
                Text("Sin datos de demanda aún")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("POR CATEGORÍA")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .kerning(1.5)

            let categories = categoryData()
            ForEach(categories, id: \.category) { item in
                HStack(spacing: 10) {
                    Text(item.category.emoji)
                        .font(.system(size: 20))
                    Text(item.category.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()

                    // Barra de progreso
                    let maxCount = categories.first?.count ?? 1
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(item.category.barColor)
                            .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(max(maxCount, 1)))
                    }
                    .frame(width: 80, height: 6)

                    Text("\(item.count)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Helpers

    private func categoryData() -> [(category: MerchantCategory, count: Int)] {
        var counts: [MerchantCategory: Int] = [:]
        for zone in demandManager.demandZones {
            if let cat = zone.topCategory {
                counts[cat, default: 0] += zone.demandScore
            }
        }
        return counts
            .map { (category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
}

// MARK: - Components

private struct DemandStatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(color.opacity(0.08))
            }
        )
    }
}

private struct DemandZoneRow: View {
    let zone: DemandZone
    let rank: Int
    let onGoThere: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("#\(rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(zone.intensity.color)
                .frame(width: 30)

            // Intensidad
            RoundedRectangle(cornerRadius: 4)
                .fill(zone.intensity.color)
                .frame(width: 4, height: 36)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if let cat = zone.topCategory {
                        Text(cat.emoji)
                    }
                    Text("Zona \(zone.geohash.prefix(5))…")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("\(zone.demandScore) búsquedas · \(zone.intensity.displayName)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Button {
                onGoThere()
            } label: {
                Text("Ir")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(zone.intensity.color.opacity(0.3)))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.02))
            }
        )
    }
}

// MARK: - Category Color Helper

private extension MerchantCategory {
    var barColor: Color {
        switch self {
        case .tacos: return .orange
        case .tamales: return .brown
        case .helados: return .cyan
        case .jugos: return .green
        case .elotes: return .yellow
        case .frutas: return .pink
        case .antojitos: return .purple
        case .bebidas: return .blue
        case .postres: return .mint
        case .otro: return .gray
        }
    }
}
