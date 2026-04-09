//
//  NearbyMerchantsPanel.swift
//  atenea
//
//  Panel flotante inferior que muestra comerciantes cercanos activos al usuario
//

import SwiftUI
import CoreLocation

// MARK: - Nearby Merchants Panel

struct NearbyMerchantsPanel: View {
    let merchants: [Merchant]
    let userLocation: CLLocationCoordinate2D?
    let onMerchantTap: (Merchant) -> Void

    @State private var selectedCategoryFilter: MerchantCategory? = nil

    /// Radio máximo para considerar un merchant como "cercano" (5km)
    private let maxRadiusMeters: Double = 5000

    private var nearbyActiveMerchants: [Merchant] {
        let active = merchants.filter { $0.isActive && $0.currentLocation != nil }
        guard let userLoc = userLocation else { return active }
        return active.filter { distance(from: userLoc, to: $0) <= maxRadiusMeters }
    }

    private var filteredMerchants: [Merchant] {
        if let cat = selectedCategoryFilter {
            return nearbyActiveMerchants.filter { $0.category == cat }
        }
        return nearbyActiveMerchants
    }

    private var sortedMerchants: [Merchant] {
        guard let userLoc = userLocation else { return filteredMerchants }
        return filteredMerchants.sorted { a, b in
            let distA = distance(from: userLoc, to: a)
            let distB = distance(from: userLoc, to: b)
            return distA < distB
        }
    }

    private var activeCategories: [MerchantCategory] {
        let cats = Set(nearbyActiveMerchants.map { $0.category })
        return MerchantCategory.allCases.filter { cats.contains($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Categorias activas
            if !activeCategories.isEmpty {
                categoryChips
            }

            // Lista de comerciantes
            if !sortedMerchants.isEmpty {
                merchantsList
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

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Chip "Todos"
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedCategoryFilter = nil
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 11))
                        Text("Todos")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(selectedCategoryFilter == nil ? Color.blue : Color.clear)
                    )
                    .foregroundColor(selectedCategoryFilter == nil ? .white : .secondary)
                    .overlay(
                        Capsule().strokeBorder(selectedCategoryFilter == nil ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)

                ForEach(activeCategories, id: \.self) { cat in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedCategoryFilter = selectedCategoryFilter == cat ? nil : cat
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack(spacing: 4) {
                            Text(cat.emoji)
                                .font(.system(size: 13))
                            Text(cat.displayName)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(selectedCategoryFilter == cat ? Color.orange : Color.clear)
                        )
                        .foregroundColor(selectedCategoryFilter == cat ? .white : .secondary)
                        .overlay(
                            Capsule().strokeBorder(selectedCategoryFilter == cat ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 10)
    }

    // MARK: - Merchants List

    private var merchantsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(sortedMerchants) { merchant in
                    Button {
                        onMerchantTap(merchant)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        MerchantCard(
                            merchant: merchant,
                            distance: userLocation.map { distance(from: $0, to: merchant) }
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
            Image(systemName: "mappin.slash")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Text("No hay comerciantes activos cerca")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func distance(from userLoc: CLLocationCoordinate2D, to merchant: Merchant) -> Double {
        guard let loc = merchant.currentLocation else { return .infinity }
        return MerchantManager.haversineDistance(
            lat1: userLoc.latitude, lon1: userLoc.longitude,
            lat2: loc.latitude, lon2: loc.longitude
        )
    }
}

// MARK: - Merchant Card

struct MerchantCard: View {
    let merchant: Merchant
    let distance: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: emoji + verificacion
            HStack(spacing: 6) {
                Text(merchant.emoji)
                    .font(.system(size: 26))

                Spacer()

                // Badge de verificacion verde
                if merchant.trustLevel.isGreen {
                    Image(systemName: merchant.trustLevel.icon)
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                        .symbolEffect(.pulse, options: .repeat(1))
                }

                // Status indicator
                Circle()
                    .fill(merchant.isCurrentlyOpen ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
            }

            // Nombre
            Text(merchant.businessName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            // Categoria + distancia
            HStack(spacing: 4) {
                Text(merchant.category.displayName)
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

            // Badge "En Ruta" si está activo, si no muestra tipo fijo/ambulante
            if merchant.isOnRoute {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .modifier(PulsingDot())
                    Text("En Ruta")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.green.opacity(0.12)))
            } else {
                HStack(spacing: 4) {
                    Image(systemName: merchant.isStatic ? "mappin.circle.fill" : "figure.walk")
                        .font(.system(size: 10))
                    Text(merchant.isStatic ? "Fijo" : "Ambulante")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(merchant.isStatic ? .blue : .orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule().fill(merchant.isStatic ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1))
                )
            }
        }
        .padding(10)
        .frame(width: 140, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            merchant.trustLevel.isGreen
                                ? Color.green.opacity(0.4)
                                : Color.white.opacity(0.15),
                            lineWidth: merchant.trustLevel.isGreen ? 1.5 : 0.5
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

// MARK: - Pulsing Dot Animation

private struct PulsingDot: ViewModifier {
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: scale)
            .onAppear { scale = 1.6 }
    }
}
