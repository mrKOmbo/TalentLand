//
//  StreetCredDetailView.swift
//  atenea
//
//  Vista detallada del Street Cred con radar chart, desglose y badges
//

import SwiftUI

struct StreetCredDetailView: View {
    let score: StreetCredScore
    @Environment(\.dismiss) private var dismiss
    @State private var animateChart = false
    @State private var selectedDimension: ScoreDimension?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#0A0A1A"), Color(hex: "#0D1B2A")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Score principal
                        mainScoreSection

                        // Radar Chart
                        radarChartSection

                        // Desglose por dimensión
                        dimensionBreakdown

                        // Crédito Coppel
                        creditSection

                        // Badges
                        badgesSection

                        // Historial
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
                    Button("Listo") { dismiss() }
                        .foregroundColor(score.level.color)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
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
                // Track exterior
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 10)
                    .frame(width: 140, height: 140)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animateChart ? CGFloat(score.totalScore) / 1000.0 : 0)
                    .stroke(
                        AngularGradient(
                            colors: score.level.gradient + [score.level.gradient.first ?? .white],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(score.totalScore)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    HStack(spacing: 4) {
                        Image(systemName: score.level.icon)
                            .font(.system(size: 12, weight: .bold))
                        Text(score.level.displayName)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(score.level.color)
                }
            }

            // Streak
            if score.streak > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(score.streak) dias consecutivos")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.orange.opacity(0.12)))
            }

            // Progreso
            if let next = score.level.nextLevel {
                VStack(spacing: 6) {
                    HStack {
                        Text(score.level.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(score.level.color)
                        Spacer()
                        Text(next.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(next.color)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: score.level.gradient,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * score.progressToNextLevel, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(score.pointsToNextLevel) puntos para \(next.displayName)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(score.level.color.opacity(0.05))
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(score.level.color.opacity(0.15), lineWidth: 0.5)
            }
        )
    }

    // MARK: - Radar Chart

    private var radarChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PERFIL DE COMPETENCIAS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .kerning(1.5)

            RadarChartView(dimensions: score.dimensions, animated: animateChart)
                .frame(height: 220)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Dimension Breakdown

    private var dimensionBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DESGLOSE")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .kerning(1.5)

            ForEach(score.dimensions) { dim in
                DimensionRow(dimension: dim)
            }
        }
    }

    // MARK: - Credit Section

    private var creditSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CRÉDITO COPPEL EMPRENDE")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .kerning(1.5)

            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    Image(systemName: score.isCreditEligible ? "checkmark.seal.fill" : "lock.fill")
                        .font(.system(size: 28))
                        .foregroundColor(score.isCreditEligible ? .green : .gray)
                        .frame(width: 48, height: 48)
                        .background(
                            (score.isCreditEligible ? Color.green : Color.gray).opacity(0.12)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(score.isCreditEligible ? "Elegible para financiamiento" : "Sigue construyendo tu historial")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text(score.isCreditEligible
                             ? "\(score.creditTier) · \(score.estimatedCreditAmount)"
                             : "Necesitas nivel Plata (400+ pts) para acceder")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                if score.isCreditEligible {
                    Text("Tu historial de ventas en Atenea respalda tu solicitud de microcrédito con Coppel Emprende")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.top, 2)
                }
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(score.isCreditEligible ? Color.green.opacity(0.05) : Color.gray.opacity(0.03))
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                }
            )
        }
    }

    // MARK: - Badges

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LOGROS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .kerning(1.5)

            let columns = [GridItem(.adaptive(minimum: 80), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(score.badges) { badge in
                    VStack(spacing: 6) {
                        Text(badge.emoji)
                            .font(.system(size: 28))
                            .frame(width: 52, height: 52)
                            .background(
                                Circle()
                                    .fill(badge.isEarned ? Color.white.opacity(0.08) : Color.white.opacity(0.02))
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        badge.isEarned ? score.level.color.opacity(0.3) : Color.white.opacity(0.05),
                                        lineWidth: 1
                                    )
                            )
                            .opacity(badge.isEarned ? 1 : 0.3)

                        Text(badge.name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(badge.isEarned ? .white : .white.opacity(0.3))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(width: 80)
                }
            }
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EVOLUCIÓN")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .kerning(1.5)

            let history = StreetCredManager.shared.scoreHistory.suffix(30)
            if !history.isEmpty {
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(Array(history.enumerated()), id: \.element.id) { index, snapshot in
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: levelForScore(snapshot.score).gradient,
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(height: max(CGFloat(snapshot.score) / 1000.0 * 60, 4))
                        }
                    }
                }
                .frame(height: 60)
                .padding(16)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.02))
                    }
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

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 30
            let count = dimensions.count

            ZStack {
                // Grid lines
                ForEach(1...4, id: \.self) { ring in
                    RadarPolygon(sides: count, radius: radius * CGFloat(ring) / 4.0)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                        .offset(x: center.x - radius, y: center.y - radius)
                }

                // Axis lines
                ForEach(0..<count, id: \.self) { i in
                    let angle = angleForIndex(i, total: count)
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: pointOnCircle(center: center, radius: radius, angle: angle))
                    }
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                }

                // Data shape
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
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.2), Color.blue.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
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
                .stroke(Color.cyan.opacity(0.6), lineWidth: 1.5)

                // Dots + Labels
                ForEach(0..<count, id: \.self) { i in
                    let dim = dimensions[i]
                    let angle = angleForIndex(i, total: count)
                    let r = animated ? radius * CGFloat(dim.value) : 0
                    let point = pointOnCircle(center: center, radius: r, angle: angle)
                    let labelPoint = pointOnCircle(center: center, radius: radius + 20, angle: angle)

                    Circle()
                        .fill(dim.color)
                        .frame(width: 8, height: 8)
                        .position(point)

                    VStack(spacing: 1) {
                        Image(systemName: dim.icon)
                            .font(.system(size: 10))
                        Text("\(dim.points)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(dim.color)
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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: dimension.icon)
                .font(.system(size: 16))
                .foregroundColor(dimension.color)
                .frame(width: 36, height: 36)
                .background(dimension.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(dimension.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(dimension.points)/\(dimension.maxPoints)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(dimension.color)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.06))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(dimension.color.opacity(0.7))
                            .frame(width: geo.size.width * dimension.value)
                    }
                }
                .frame(height: 5)

                Text(dimension.details)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.02))
            }
        )
    }
}
