/*
//
//  DemandInsightsView.swift
//  atenea
//
//  Vista de insights de demanda para el merchant
//

import SwiftUI
import CoreLocation

// MARK: - Coppel Brand Colors (local)

private enum CoppelColors {
    static let blue = Color(red: 0.110, green: 0.259, blue: 0.910)       // #1C42E8
    static let yellow = Color(red: 0.941, green: 0.824, blue: 0.141)     // #F0D224
    static let darkBlue = Color(red: 0.031, green: 0.090, blue: 0.329)   // #081754
    static let lightBlue = Color(red: 0.110, green: 0.659, blue: 0.969)  // #1CA8F7
    static let green = Color(red: 0.039, green: 0.749, blue: 0.310)      // #0ABF4F
    static let orange = Color(red: 1.0, green: 0.682, blue: 0.263)       // #FFAE43
    static let red = Color(red: 1.0, green: 0.349, blue: 0.302)          // #FF594D
    static let beige = Color(red: 0.933, green: 0.910, blue: 0.890)      // #EEE8E3
    static let darkGrey = Color(red: 0.290, green: 0.290, blue: 0.290)   // #4A4A4A
}

struct DemandInsightsView: View {
    @ObservedObject private var demandManager = DemandZoneManager.shared
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int

    var body: some View {
        ZStack {
            CoppelColors.beige
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    summaryCard
                    topZonesSection
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
                Text(LocalizedString("demand.title"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(CoppelColors.darkBlue)
                Text(LocalizedString("demand.lastHour"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(CoppelColors.darkGrey)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(CoppelColors.darkGrey.opacity(0.5))
            }
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        HStack(spacing: 12) {
            DemandStatBox(
                value: "\(demandManager.totalDemandLastHour())",
                label: LocalizedString("demand.searches"),
                icon: "magnifyingglass",
                color: CoppelColors.blue
            )
            DemandStatBox(
                value: "\(demandManager.demandZones.count)",
                label: LocalizedString("demand.activeZones"),
                icon: "mappin.and.ellipse",
                color: CoppelColors.orange
            )
            DemandStatBox(
                value: topCategorySymbol(),
                label: LocalizedString("demand.topCategory"),
                icon: "star.fill",
                color: CoppelColors.yellow,
                isSymbolValue: true
            )
        }
    }

    private func topCategorySymbol() -> String {
        demandManager.topZones(limit: 1).first?.topCategory?.sfSymbol ?? "questionmark"
    }

    // MARK: - Top Zones

    private var topZonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("demand.topZones"))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(CoppelColors.darkGrey)
                .kerning(1.0)

            ForEach(Array(demandManager.topZones(limit: 5).enumerated()), id: \.element.id) { index, zone in
                DemandZoneRow(zone: zone, rank: index + 1) {
                    NavigationStateManager.shared.pendingDemandZoneCoord = CLLocationCoordinate2D(
                        latitude: zone.center.lat,
                        longitude: zone.center.lon
                    )
                    dismiss()
                    selectedTab = 1
                }
            }

            if demandManager.demandZones.isEmpty {
                Text(LocalizedString("demand.noDataYet"))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(CoppelColors.darkGrey)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("demand.byCategory"))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(CoppelColors.darkGrey)
                .kerning(1.0)

            let categories = categoryData()

            VStack(spacing: 0) {
                ForEach(Array(categories.enumerated()), id: \.element.category) { idx, item in
                    HStack(spacing: 10) {
                        Image(systemName: item.category.sfSymbol)
                            .font(.system(size: 16))
                            .foregroundColor(categoryColor(item.category))
                            .frame(width: 28)

                        Text(item.category.displayName)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(CoppelColors.darkBlue)

                        Spacer()

                        // Barra de progreso
                        let maxCount = categories.first?.count ?? 1
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(categoryColor(item.category))
                                .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(max(maxCount, 1)))
                        }
                        .frame(width: 80, height: 6)

                        Text("\(item.count)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(CoppelColors.darkBlue)
                            .frame(width: 30, alignment: .trailing)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)

                    if idx < categories.count - 1 {
                        Divider()
                            .padding(.leading, 50)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: CoppelColors.darkBlue.opacity(0.06), radius: 8, x: 0, y: 2)
            )
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

    private func categoryColor(_ category: MerchantCategory) -> Color {
        switch category {
        case .tacos, .antojitos, .tamales: return CoppelColors.orange
        case .bebidas, .jugos: return CoppelColors.green
        case .helados, .frutas: return CoppelColors.lightBlue
        case .elotes: return CoppelColors.yellow
        case .postres: return CoppelColors.red
        case .otro: return CoppelColors.darkGrey
        }
    }
}

// MARK: - Components

private struct DemandStatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    var isSymbolValue: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            if isSymbolValue {
                Image(systemName: value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(CoppelColors.darkBlue)
            } else {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(CoppelColors.darkBlue)
            }

            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(CoppelColors.darkGrey)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .shadow(color: CoppelColors.darkBlue.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(color.opacity(0.15), lineWidth: 1)
        )
    }
}

private struct DemandZoneRow: View {
    let zone: DemandZone
    let rank: Int
    let onGoThere: () -> Void

    private func intensityColor(_ intensity: DemandIntensity) -> Color {
        switch intensity {
        case .low: return CoppelColors.green
        case .medium: return CoppelColors.yellow
        case .high: return CoppelColors.orange
        case .veryHigh: return CoppelColors.red
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("#\(rank)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(intensityColor(zone.intensity))
                .frame(width: 30)

            // Intensidad
            RoundedRectangle(cornerRadius: 4)
                .fill(intensityColor(zone.intensity))
                .frame(width: 4, height: 36)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if let cat = zone.topCategory {
                        Image(systemName: cat.sfSymbol)
                            .font(.system(size: 12))
                            .foregroundColor(CoppelColors.orange)
                    }
                    Text(String(format: LocalizedString("demand.zonePrefix"), String(zone.geohash.prefix(5))))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(CoppelColors.darkBlue)
                }
                Text("\(zone.demandScore) búsquedas · \(zone.intensity.displayName)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(CoppelColors.darkGrey)
            }

            Spacer()

            Button {
                onGoThere()
            } label: {
                Text(LocalizedString("demand.go"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(CoppelColors.blue)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .shadow(color: CoppelColors.darkBlue.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }
}
*/
