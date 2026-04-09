//
//  StreetCredDetailView.swift
//  atenea
//
//  Vista detallada del Street Cred con radar chart, desglose y badges
//

import SwiftUI

private enum CoppelColors {
    static let blue = Color(red: 0.110, green: 0.259, blue: 0.910)
    static let yellow = Color(red: 0.941, green: 0.824, blue: 0.141)
    static let darkBlue = Color(red: 0.031, green: 0.090, blue: 0.329)
    static let lightBlue = Color(red: 0.110, green: 0.659, blue: 0.969)
    static let green = Color(red: 0.039, green: 0.749, blue: 0.310)
    static let orange = Color(red: 1.0, green: 0.682, blue: 0.263)
    static let red = Color(red: 1.0, green: 0.349, blue: 0.302)
    static let beige = Color(red: 0.933, green: 0.910, blue: 0.890)
    static let darkGrey = Color(red: 0.290, green: 0.290, blue: 0.290)
}

struct StreetCredDetailView: View {
    let score: StreetCredScore
    @Environment(\.dismiss) private var dismiss
    @State private var animateChart = false
    @State private var selectedDimension: ScoreDimension?

    private func levelColor(_ level: StreetCredLevel) -> Color {
        switch level {
        case .nuevo: return CoppelColors.darkGrey
        case .bronce: return CoppelColors.orange
        case .plata: return Color(red: 0.660, green: 0.710, blue: 0.773)
        case .oro: return CoppelColors.yellow
        case .platino: return CoppelColors.blue
        case .diamante: return Color(red: 0.094, green: 0.353, blue: 0.859)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoppelColors.beige
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        mainScoreSection
                        radarChartSection
                        dimensionBreakdown
                        creditSection
                        badgesSection

                        if !StreetCredManager.shared.scoreHistory.isEmpty {
                            historySection
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Street Cred")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LocalizedString("streetcred.done")) { dismiss() }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(CoppelColors.blue)
                }
            }
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                animateChart = true
            }
        }
    }

    // MARK: - Main Score

    private var mainScoreSection: some View {
        VStack(spacing: 16) {
            // Gran gauge
            ZStack {
                Circle()
                    .stroke(CoppelColors.beige, lineWidth: 10)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: animateChart ? CGFloat(score.totalScore) / 1000.0 : 0)
                    .stroke(
                        levelColor(score.level),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(score.totalScore)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(CoppelColors.darkBlue)

                    HStack(spacing: 4) {
                        Image(systemName: score.level.icon)
                            .font(.system(size: 12, weight: .bold))
                        Text(score.level.displayName)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(levelColor(score.level))
                }
            }

            // Streak
            if score.streak > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(CoppelColors.orange)
                    Text(String(format: LocalizedString("streetcred.consecutiveDays"), score.streak))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(CoppelColors.orange)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(CoppelColors.orange.opacity(0.10)))
            }

            // Progreso
            if let next = score.level.nextLevel {
                VStack(spacing: 6) {
                    HStack {
                        Text(score.level.displayName)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(levelColor(score.level))
                        Spacer()
                        Text(next.displayName)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(levelColor(next))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(CoppelColors.beige)
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(levelColor(score.level))
                                .frame(width: geo.size.width * score.progressToNextLevel, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text(String(format: LocalizedString("streetcred.pointsFor"), score.pointsToNextLevel, next.displayName))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(CoppelColors.darkGrey)
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: CoppelColors.darkBlue.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - Radar Chart

    private var radarChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("streetcred.competenceProfile"))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(CoppelColors.darkGrey)
                .kerning(1.0)

            RadarChartView(dimensions: score.dimensions, animated: animateChart)
                .frame(height: 220)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: CoppelColors.darkBlue.opacity(0.06), radius: 8, x: 0, y: 2)
                )
        }
    }

    // MARK: - Dimension Breakdown

    private var dimensionBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("streetcred.breakdown"))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(CoppelColors.darkGrey)
                .kerning(1.0)

            ForEach(score.dimensions) { dim in
                DimensionRow(dimension: dim)
            }
        }
    }

    // MARK: - Credit Section

    private var creditSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("streetcred.coppelCredit"))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(CoppelColors.darkGrey)
                .kerning(1.0)

            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    Image(systemName: score.isCreditEligible ? "checkmark.seal.fill" : "lock.fill")
                        .font(.system(size: 28))
                        .foregroundColor(score.isCreditEligible ? CoppelColors.green : CoppelColors.darkGrey)
                        .frame(width: 48, height: 48)
                        .background(
                            (score.isCreditEligible ? CoppelColors.green : CoppelColors.darkGrey).opacity(0.10)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(score.isCreditEligible ? LocalizedString("streetcred.eligibleForFinancing") : LocalizedString("streetcred.keepBuilding"))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(CoppelColors.darkBlue)
                        Text(score.isCreditEligible
                             ? "\(score.creditTier) · \(score.estimatedCreditAmount)"
                             : LocalizedString("streetcred.needSilver"))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(CoppelColors.darkGrey)
                    }
                }

                if score.isCreditEligible {
                    Text(LocalizedString("streetcred.creditHistory"))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(CoppelColors.darkGrey)
                        .padding(.top, 2)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: CoppelColors.darkBlue.opacity(0.06), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(score.isCreditEligible ? CoppelColors.green.opacity(0.20) : Color.clear, lineWidth: 1)
            )
        }
    }

    // MARK: - Badges

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("streetcred.achievements"))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(CoppelColors.darkGrey)
                .kerning(1.0)

            let columns = [GridItem(.adaptive(minimum: 80), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(score.badges) { badge in
                    VStack(spacing: 6) {
                        Image(systemName: badgeSFSymbol(badge.id))
                            .font(.system(size: 22))
                            .foregroundColor(badge.isEarned ? CoppelColors.blue : CoppelColors.darkGrey.opacity(0.3))
                            .frame(width: 52, height: 52)
                            .background(
                                Circle()
                                    .fill(badge.isEarned ? CoppelColors.blue.opacity(0.08) : CoppelColors.beige)
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        badge.isEarned ? CoppelColors.blue.opacity(0.20) : CoppelColors.darkGrey.opacity(0.08),
                                        lineWidth: 1
                                    )
                            )
                            .opacity(badge.isEarned ? 1 : 0.5)

                        Text(badge.name)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(badge.isEarned ? CoppelColors.darkBlue : CoppelColors.darkGrey.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(width: 80)
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

    private func badgeSFSymbol(_ id: String) -> String {
        switch id {
        case "primera_venta": return "bag.fill"
        case "primera_semana": return "calendar"
        case "racha_7": return "flame.fill"
        case "racha_30": return "flame.circle.fill"
        case "zona_nueva": return "map.fill"
        case "top_ventas": return "star.fill"
        case "madrugador": return "sunrise.fill"
        case "nocturno": return "moon.stars.fill"
        case "diversificado": return "square.grid.3x3.fill"
        case "mundial": return "sportscourt.fill"
        default: return "star.circle.fill"
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("streetcred.evolution"))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(CoppelColors.darkGrey)
                .kerning(1.0)

            let history = StreetCredManager.shared.scoreHistory.suffix(30)
            if !history.isEmpty {
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(Array(history.enumerated()), id: \.element.id) { index, snapshot in
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(levelColor(levelForScore(snapshot.score)))
                                .frame(height: max(CGFloat(snapshot.score) / 1000.0 * 60, 4))
                        }
                    }
                }
                .frame(height: 60)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: CoppelColors.darkBlue.opacity(0.06), radius: 8, x: 0, y: 2)
                )
            }
        }
    }

    private func levelForScore(_ score: Int) -> StreetCredLevel {
        switch score {
        case 900...1000: return .diamante
        case 800..<900: return .platino
        case 600..<800: return .oro
        case 400..<600: return .plata
        case 200..<400: return .bronce
        default: return .nuevo
        }
    }
}

// MARK: - Radar Chart

struct RadarChartView: View {
    let dimensions: [ScoreDimension]
    let animated: Bool

    private func dimColor(_ id: String) -> Color {
        switch id {
        case "actividad": return Color(red: 1.0, green: 0.349, blue: 0.302)  // red
        case "volumen": return Color(red: 0.039, green: 0.749, blue: 0.310)  // green
        case "consistencia": return Color(red: 0.110, green: 0.659, blue: 0.969) // lightBlue
        case "reputacion": return Color(red: 0.941, green: 0.824, blue: 0.141)  // yellow
        case "diversificacion": return Color(red: 1.0, green: 0.682, blue: 0.263) // orange
        case "cobertura": return Color(red: 0.110, green: 0.259, blue: 0.910)   // blue
        default: return Color(red: 0.290, green: 0.290, blue: 0.290)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 30
            let count = dimensions.count

            ZStack {
                // Grid lines
                ForEach(1...4, id: \.self) { ring in
                    RadarPolygon(sides: count, radius: radius * CGFloat(ring) / 4.0)
                        .stroke(Color(red: 0.031, green: 0.090, blue: 0.329).opacity(0.08), lineWidth: 0.5)
                        .offset(x: center.x - radius, y: center.y - radius)
                }

                // Axis lines
                ForEach(0..<count, id: \.self) { i in
                    let angle = angleForIndex(i, total: count)
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: pointOnCircle(center: center, radius: radius, angle: angle))
                    }
                    .stroke(Color(red: 0.031, green: 0.090, blue: 0.329).opacity(0.08), lineWidth: 0.5)
                }

                // Data shape fill
                Path { path in
                    for (i, dim) in dimensions.enumerated() {
                        let angle = angleForIndex(i, total: count)
                        let r = animated ? radius * CGFloat(dim.value) : 0
                        let point = pointOnCircle(center: center, radius: r, angle: angle)
                        if i == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                    path.closeSubpath()
                }
                .fill(
                    Color(red: 0.110, green: 0.259, blue: 0.910).opacity(0.10)
                )

                // Data border
                Path { path in
                    for (i, dim) in dimensions.enumerated() {
                        let angle = angleForIndex(i, total: count)
                        let r = animated ? radius * CGFloat(dim.value) : 0
                        let point = pointOnCircle(center: center, radius: r, angle: angle)
                        if i == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                    path.closeSubpath()
                }
                .stroke(Color(red: 0.110, green: 0.259, blue: 0.910).opacity(0.50), lineWidth: 1.5)

                // Dots + Labels
                ForEach(0..<count, id: \.self) { i in
                    let dim = dimensions[i]
                    let angle = angleForIndex(i, total: count)
                    let r = animated ? radius * CGFloat(dim.value) : 0
                    let point = pointOnCircle(center: center, radius: r, angle: angle)
                    let labelPoint = pointOnCircle(center: center, radius: radius + 20, angle: angle)

                    Circle()
                        .fill(dimColor(dim.id))
                        .frame(width: 8, height: 8)
                        .position(point)

                    VStack(spacing: 1) {
                        Image(systemName: dim.icon)
                            .font(.system(size: 10))
                        Text("\(dim.points)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(dimColor(dim.id))
                    .position(labelPoint)
                }
            }
        }
    }

    private func angleForIndex(_ index: Int, total: Int) -> Double {
        let segment = 360.0 / Double(total)
        return segment * Double(index) - 90
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        let rad = angle * .pi / 180
        return CGPoint(
            x: center.x + radius * CGFloat(cos(rad)),
            y: center.y + radius * CGFloat(sin(rad))
        )
    }
}

struct RadarPolygon: Shape {
    let sides: Int
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: radius, y: radius)
        for i in 0...sides {
            let angle = (360.0 / Double(sides) * Double(i) - 90) * .pi / 180
            let point = CGPoint(
                x: center.x + radius * CGFloat(cos(angle)),
                y: center.y + radius * CGFloat(sin(angle))
            )
            if i == 0 { path.move(to: point) }
            else { path.addLine(to: point) }
        }
        return path
    }
}

// MARK: - Dimension Row

struct DimensionRow: View {
    let dimension: ScoreDimension

    private func dimColor(_ id: String) -> Color {
        switch id {
        case "actividad": return Color(red: 1.0, green: 0.349, blue: 0.302)
        case "volumen": return Color(red: 0.039, green: 0.749, blue: 0.310)
        case "consistencia": return Color(red: 0.110, green: 0.659, blue: 0.969)
        case "reputacion": return Color(red: 0.941, green: 0.824, blue: 0.141)
        case "diversificacion": return Color(red: 1.0, green: 0.682, blue: 0.263)
        case "cobertura": return Color(red: 0.110, green: 0.259, blue: 0.910)
        default: return Color(red: 0.290, green: 0.290, blue: 0.290)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: dimension.icon)
                .font(.system(size: 16))
                .foregroundColor(dimColor(dimension.id))
                .frame(width: 36, height: 36)
                .background(dimColor(dimension.id).opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(dimension.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.031, green: 0.090, blue: 0.329))
                    Spacer()
                    Text("\(dimension.points)/\(dimension.maxPoints)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(dimColor(dimension.id))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.933, green: 0.910, blue: 0.890))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(dimColor(dimension.id))
                            .frame(width: geo.size.width * dimension.value)
                    }
                }
                .frame(height: 5)

                Text(dimension.details)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.290, green: 0.290, blue: 0.290))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color(red: 0.031, green: 0.090, blue: 0.329).opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }
}
