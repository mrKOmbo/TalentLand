//
//  PredictionView.swift
//  atenea
//
//  Vista de predicción "Atenea Predict" para el comerciante
//

import SwiftUI

// MARK: - Prediction Card (para HomeView)

struct PredictionCardView: View {
    let prediction: MatchPrediction
    let merchantCategory: MerchantCategory?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header del partido
                HStack(spacing: 10) {
                    Text("⚽")
                        .font(.system(size: 24))
                        .frame(width: 40, height: 40)
                        .background(Color.green.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("ATENEA PREDICT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.cyan)
                            .kerning(1.5)
                        Text(prediction.match.teams)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("\(prediction.venue.name) · \(prediction.match.date)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }

                // Recomendación personalizada
                if let category = merchantCategory,
                   let rec = PredictionEngine.shared.recommendPosition(
                    for: category,
                    match: prediction.match,
                    venue: prediction.venue
                   ) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                            Text("Posiciónate en: \(rec.zone.name)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.green)
                        }

                        Text(rec.reason)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(2)

                        HStack(spacing: 12) {
                            Label("Llega a las \(rec.arriveBy)", systemImage: "clock.fill")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.orange)

                            Label("Score: \(Int(rec.zone.demandScore))", systemImage: "chart.bar.fill")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.cyan)
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.green.opacity(0.15), lineWidth: 0.5)
                            )
                    )
                } else {
                    // Sin categoría, mostrar resumen general
                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text("\(prediction.estimatedFootTraffic / 1000)K")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.cyan)
                            Text("personas")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                        }

                        VStack(spacing: 2) {
                            Text("\(prediction.zones.filter { $0.intensity == .veryHigh || $0.intensity == .high }.count)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.orange)
                            Text("zonas top")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                        }

                        VStack(spacing: 2) {
                            if let top = prediction.topCategories.first {
                                Text(top.0.emoji)
                                    .font(.system(size: 18))
                                Text("top ventas")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.cyan.opacity(0.05))
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.cyan.opacity(0.15), lineWidth: 0.5)
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Prediction Detail View

struct PredictionDetailView: View {
    let prediction: MatchPrediction
    @State private var selectedWeather: WeatherCondition = .sunny
    @State private var livePrediction: MatchPrediction?
    @Binding var selectedTab: Int
    @Environment(\.dismiss) private var dismiss

    private var activePrediction: MatchPrediction {
        livePrediction ?? prediction
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#0A0A1A"), Color(hex: "#0D1B2A")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        matchHeader
                        weatherSelector
                        timelineSection
                        topZonesSection
                        categoryRankingSection
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Atenea Predict")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") { dismiss() }
                        .foregroundColor(.cyan)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }

    // MARK: - Match Header

    private var matchHeader: some View {
        VStack(spacing: 12) {
            Text("⚽")
                .font(.system(size: 40))

            Text(activePrediction.match.teams)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("\(activePrediction.venue.name) · \(activePrediction.match.stage)")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 20) {
                StatPill(icon: "person.3.fill", value: "\(activePrediction.estimatedFootTraffic / 1000)K", label: "personas")
                StatPill(icon: "clock.fill", value: activePrediction.peakDemandWindow, label: "pico")
                StatPill(icon: "mappin.and.ellipse", value: "\(activePrediction.zones.count)", label: "zonas")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.cyan.opacity(0.05))
            }
        )
    }

    // MARK: - Weather Selector

    private var weatherSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SIMULAR CLIMA")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .kerning(1.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WeatherCondition.allCases, id: \.rawValue) { weather in
                        Button {
                            selectedWeather = weather
                            livePrediction = PredictionEngine.shared.predict(
                                for: prediction.match,
                                at: prediction.venue,
                                weather: weather
                            )
                        } label: {
                            VStack(spacing: 4) {
                                Text(weather.emoji)
                                    .font(.system(size: 20))
                                Text(weather.displayName)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(selectedWeather == weather ? .white : .white.opacity(0.5))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedWeather == weather ? Color.cyan.opacity(0.2) : Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(selectedWeather == weather ? Color.cyan.opacity(0.4) : Color.clear, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FLUJO TEMPORAL")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .kerning(1.5)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(MatchTimeWindow.allCases, id: \.label) { window in
                    VStack(spacing: 6) {
                        Text("\(Int(window.spendingShare * 100))%")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.6), .blue.opacity(0.3)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(height: CGFloat(window.spendingShare) * 200)

                        Image(systemName: window.icon)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))

                        Text(window.label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.02))
                }
            )
        }
    }

    // MARK: - Top Zones

    private var topZonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ZONAS RECOMENDADAS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .kerning(1.5)

            ForEach(Array(activePrediction.zones.prefix(6).enumerated()), id: \.element.id) { index, zone in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                        .frame(width: 20)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(zone.intensity.color)
                        .frame(width: 4, height: 36)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(zone.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        HStack(spacing: 8) {
                            Text("Score: \(Int(zone.demandScore))")
                                .font(.system(size: 11))
                                .foregroundColor(.cyan)
                            Text("·")
                                .foregroundColor(.white.opacity(0.2))
                            Text(zone.peakTime)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                            Text("·")
                                .foregroundColor(.white.opacity(0.2))
                            Text("\(Int(zone.distanceFromStadium))m")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }

                        // Productos recomendados
                        HStack(spacing: 4) {
                            ForEach(zone.recommendedProducts.prefix(5), id: \.rawValue) { cat in
                                Text(cat.emoji)
                                    .font(.system(size: 14))
                            }
                        }
                    }

                    Spacer()

                    Button {
                        NavigationStateManager.shared.pendingDemandZoneCoord = zone.coordinate
                        selectedTab = 1
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.cyan.opacity(0.7))
                    }
                }
                .padding(12)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.02))
                    }
                )
            }
        }
    }

    // MARK: - Category Ranking

    private var categoryRankingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PRODUCTOS CON MÁS DEMANDA")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .kerning(1.5)

            let maxMult = activePrediction.topCategories.first?.1 ?? 1.0

            ForEach(activePrediction.topCategories.prefix(6), id: \.0.rawValue) { (cat, mult) in
                HStack(spacing: 12) {
                    Text(cat.emoji)
                        .font(.system(size: 22))
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(cat.displayName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Text("x\(String(format: "%.1f", mult))")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(mult > 1.5 ? .green : mult > 1.0 ? .cyan : .orange)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.06))
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(mult > 1.5 ? Color.green.opacity(0.6) : Color.cyan.opacity(0.4))
                                    .frame(width: geo.size.width * (mult / maxMult))
                            }
                        }
                        .frame(height: 5)
                    }
                }
            }
        }
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.cyan)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}
