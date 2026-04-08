//
//  MerchantDetailSheet.swift
//  atenea
//
//  Sheet de detalle de un merchant con productos y timbre
//

import SwiftUI

struct MerchantDetailSheet: View {
    let merchant: Merchant
    let presence: MerchantPresence?
    let onViewOnMap: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection

                // Street Cred Badge
                streetCredBadge

                // Estado
                statusSection

                // Productos
                if !merchant.products.isEmpty {
                    productsSection
                }

                // Horario
                if let schedule = merchant.schedule {
                    scheduleSection(schedule)
                }

                // Acciones
                actionsSection

                Spacer(minLength: 40)
            }
            .padding(.top, 24)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(merchant.emoji)
                .font(.system(size: 56))

            Text(merchant.businessName)
                .font(.system(size: 22, weight: .bold))

            HStack(spacing: 8) {
                Text(merchant.category.displayName)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                if let presence = presence {
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(presence.formattedDistance)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }

            if !merchant.description.isEmpty {
                Text(merchant.description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }

    private var statusSection: some View {
        HStack(spacing: 12) {
            // Actividad
            HStack(spacing: 4) {
                Circle()
                    .fill(merchant.isActive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(merchant.isActive ? "Activo" : "Inactivo")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(merchant.isActive ? .green : .gray)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(merchant.isActive ? Color.green.opacity(0.1) : Color.gray.opacity(0.1)))

            // Tipo
            HStack(spacing: 4) {
                Image(systemName: merchant.isStatic ? "mappin.circle.fill" : "figure.walk")
                    .font(.system(size: 10))
                Text(merchant.isStatic ? "Puesto fijo" : "Ambulante")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(merchant.isStatic ? .blue : .orange)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(merchant.isStatic ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1)))

            // Presencia
            if let presence = presence {
                HStack(spacing: 4) {
                    Circle()
                        .fill(presence.activityStatus.color)
                        .frame(width: 8, height: 8)
                    Text(presenceText(presence.activityStatus))
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(presence.activityStatus.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(presence.activityStatus.color.opacity(0.1)))
            }
        }
    }

    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PRODUCTOS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .kerning(1.2)

            ForEach(merchant.products) { product in
                HStack {
                    Text(product.emoji)
                        .font(.system(size: 18))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(product.name)
                            .font(.system(size: 14, weight: .medium))
                        if let desc = product.description {
                            Text(desc)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Text(product.formattedPrice)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.orange)

                    if !product.isAvailable {
                        Text("Agotado")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 24)
    }

    private func scheduleSection(_ schedule: MerchantSchedule) -> some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.secondary)
            Text("\(schedule.openTime) - \(schedule.closeTime)")
                .font(.system(size: 14))
            Spacer()
            Text(schedule.isOpenNow ? "Abierto" : "Cerrado")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(schedule.isOpenNow ? .green : .red)
        }
        .padding(.horizontal, 24)
    }

    private var actionsSection: some View {
        VStack(spacing: 10) {
            // Timbre
            TimbreButtonView(merchant: merchant)

            // Ver en mapa
            Button {
                onViewOnMap()
            } label: {
                HStack {
                    Image(systemName: "map.fill")
                    Text("Ver en mapa")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Street Cred

    @ViewBuilder
    private var streetCredBadge: some View {
        let score = StreetCredManager.shared.calculateScore(for: merchant)
        StreetCredBadgeView(score: score)
            .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private func presenceText(_ status: MerchantPresence.ActivityStatus) -> String {
        switch status {
        case .active: return "Ahora"
        case .recent: return "Reciente"
        case .stale: return "Inactivo"
        }
    }
}
