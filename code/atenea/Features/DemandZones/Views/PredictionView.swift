//
//  PredictionView.swift
//  atenea
//
//  Vista de predicción "Atenea Predict" para el comerciante
//

import SwiftUI

// MARK: - Coppel Brand Colors

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
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(CoppelColors.blue)
                        .frame(width: 40, height: 40)
                        .background(CoppelColors.blue.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedString("prediction.title"))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(CoppelColors.blue)
                            .kerning(1.0)
                        Text(prediction.match.teams)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(CoppelColors.darkBlue)
                            .lineLimit(1)
                        Text("\(prediction.venue.name) · \(prediction.match.date)")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(CoppelColors.darkGrey)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(CoppelColors.darkGrey.opacity(0.4))
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
                                .foregroundColor(CoppelColors.green)
                            Text(String(format: LocalizedString("prediction.positionAt"), rec.zone.name))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(CoppelColors.green)
                        }

                        Text(rec.reason)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(CoppelColors.darkGrey)
                            .lineLimit(2)

                        HStack(spacing: 12) {
                            Label(String(format: LocalizedString("prediction.arriveBy"), rec.arriveBy), systemImage: "clock.fill")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(CoppelColors.orange)

                            Label("Score: \(Int(rec.zone.demandScore))", systemImage: "chart.bar.fill")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(CoppelColors.blue)
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(CoppelColors.green.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(CoppelColors.green.opacity(0.20), lineWidth: 1)
                            )
                    )
                } else {
                    // Sin categoría, mostrar resumen general
                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text("\(prediction.estimatedFootTraffic / 1000)K")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(CoppelColors.blue)
                            Text(LocalizedString("prediction.people"))
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(CoppelColors.darkGrey)
                        }

                        VStack(spacing: 2) {
                            Text("\(prediction.zones.filter { $0.intensity == .veryHigh || $0.intensity == .high }.count)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(CoppelColors.orange)
                            Text(LocalizedString("prediction.topZones"))
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(CoppelColors.darkGrey)
                        }

                        VStack(spacing: 2) {
                            if let top = prediction.topCategories.first {
                                Image(systemName: top.0.sfSymbol)
                                    .font(.system(size: 18))
                                    .foregroundColor(CoppelColors.orange)
                                Text(LocalizedString("prediction.topSales"))
                                    .font(.system(size: 10, design: .rounded))
                                    .foregroundColor(CoppelColors.darkGrey)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: CoppelColors.darkBlue.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(CoppelColors.blue.opacity(0.10), lineWidth: 1)
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
                CoppelColors.beige
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
            .navigationTitle(LocalizedString("prediction.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LocalizedString("prediction.done")) { dismiss() }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(CoppelColors.blue)
                }
            }
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Match Header

    private var matchHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "sportscourt.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(CoppelColors.yellow)

            Text(activePrediction.match.teams)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(CoppelColors.darkBlue)
                .multilineTextAlignment(.center)

            Text("\(activePrediction.venue.name) · \(activePrediction.match.stage)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(CoppelColors.darkGrey)

            HStack(spacing: 20) {
                StatPill(icon: "person.3.fill", value: "\(activePrediction.estimatedFootTraffic / 1000)K", label: "personas", color: CoppelColors.blue)
                StatPill(icon: "clock.fill", value: activePrediction.peakDemandWindow, label: "pico", color: CoppelColors.orange)
                StatPill(icon: "mappin.and.ellipse", value: "\(activePrediction.zones.count)", label: "zonas", color: CoppelColors.green)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: CoppelColors.darkBlue.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - Weather Selector

    private var weatherSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedString("prediction.simulateWeather"))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(CoppelColors.darkGrey)
                .kerning(1.0)

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
                                Image(systemName: weather.sfSymbol)
                                    .font(.system(size: 20))
                                    .foregroundColor(selectedWeather == weather ? CoppelColors.blue : CoppelColors.darkGrey)
                                Text(weather.displayName)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(selectedWeather == weather ? CoppelColors.darkBlue : CoppelColors.darkGrey)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(selectedWeather == weather ? CoppelColors.blue.opacity(0.10) : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(selectedWeather == weather ? CoppelColors.blue.opacity(0.30) : CoppelColors.darkGrey.opacity(0.10), lineWidth: 1)
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
            Text(LocalizedString("prediction.timeline"))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(CoppelColors.darkGrey)
                .kerning(1.0)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(MatchTimeWindow.allCases, id: \.label) { window in
                    VStack(spacing: 6) {
                        Text("\(Int(window.spendingShare * 100))%")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(CoppelColors.blue)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(CoppelColors.blue.opacity(0.70))
                            .frame(height: CGFloat(window.spendingShare) * 200)

                        Image(systemName: window.icon)
                            .font(.system(size: 12))
                            .foregroundColor(CoppelColors.darkGrey)

                        Text(window.label)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(CoppelColors.darkGrey)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: CoppelColors.darkBlue.opacity(0.06), radius: 8, x: 0, y: 2)
            )
        }
    }

    // MARK: - Top Zones

    private var topZonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("prediction.recommendedZones"))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(CoppelColors.darkGrey)
                .kerning(1.0)

            ForEach(Array(activePrediction.zones.prefix(6).enumerated()), id: \.element.id) { index, zone in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(CoppelColors.darkGrey.opacity(0.5))
                        .frame(width: 20)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(intensityColor(zone.intensity))
                        .frame(width: 4, height: 36)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(zone.name)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(CoppelColors.darkBlue)

                        HStack(spacing: 8) {
                            Text("Score: \(Int(zone.demandScore))")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(CoppelColors.blue)
                            Text("·")
                                .foregroundColor(CoppelColors.darkGrey.opacity(0.3))
                            Text(zone.peakTime)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(CoppelColors.darkGrey)
                            Text("·")
                                .foregroundColor(CoppelColors.darkGrey.opacity(0.3))
                            Text("\(Int(zone.distanceFromStadium))m")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(CoppelColors.darkGrey)
                        }

                        // Productos recomendados
                        HStack(spacing: 4) {
                            ForEach(zone.recommendedProducts.prefix(5), id: \.rawValue) { cat in
                                Image(systemName: cat.sfSymbol)
                                    .font(.system(size: 12))
                                    .foregroundColor(CoppelColors.orange)
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
                            .foregroundColor(CoppelColors.blue)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: CoppelColors.darkBlue.opacity(0.05), radius: 6, x: 0, y: 2)
                )
            }
        }
    }

    // MARK: - Category Ranking

    private var categoryRankingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("prediction.topDemandProducts"))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(CoppelColors.darkGrey)
                .kerning(1.0)

            let maxMult = activePrediction.topCategories.first?.1 ?? 1.0

            ForEach(activePrediction.topCategories.prefix(6), id: \.0.rawValue) { (cat, mult) in
                HStack(spacing: 12) {
                    Image(systemName: cat.sfSymbol)
                        .font(.system(size: 18))
                        .foregroundColor(CoppelColors.orange)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(cat.displayName)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(CoppelColors.darkBlue)
                            Spacer()
                            Text("x\(String(format: "%.1f", mult))")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(mult > 1.5 ? CoppelColors.green : mult > 1.0 ? CoppelColors.blue : CoppelColors.orange)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(CoppelColors.beige)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(mult > 1.5 ? CoppelColors.green : CoppelColors.blue)
                                    .frame(width: geo.size.width * (mult / maxMult))
                            }
                        }
                        .frame(height: 5)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: CoppelColors.darkBlue.opacity(0.05), radius: 6, x: 0, y: 2)
            )
        }
    }

    // MARK: - Helpers

    private func intensityColor(_ intensity: DemandIntensity) -> Color {
        switch intensity {
        case .low: return CoppelColors.green
        case .medium: return CoppelColors.yellow
        case .high: return CoppelColors.orange
        case .veryHigh: return CoppelColors.red
        }
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = CoppelColors.blue

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(CoppelColors.darkBlue)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(CoppelColors.darkGrey)
        }
    }
}

// MARK: - SF Symbol helper for MerchantCategory

extension MerchantCategory {
    var sfSymbol: String {
        switch self {
        case .tacos: return "fork.knife"
        case .tamales: return "takeoutbag.and.cup.and.straw.fill"
        case .helados: return "snowflake"
        case .jugos: return "cup.and.saucer.fill"
        case .elotes: return "leaf.fill"
        case .frutas: return "carrot.fill"
        case .antojitos: return "fork.knife.circle.fill"
        case .bebidas: return "mug.fill"
        case .postres: return "birthday.cake.fill"
        case .otro: return "bag.fill"
        }
    }
}

// MARK: - SF Symbol helper for WeatherCondition

extension WeatherCondition {
    var sfSymbol: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .lightRain: return "cloud.drizzle.fill"
        case .heavyRain: return "cloud.rain.fill"
        case .hot: return "thermometer.sun.fill"
        case .cool: return "thermometer.snowflake"
        }
    }
}
