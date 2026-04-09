import SwiftUI

// MARK: - Models

struct SaleEntry: Identifiable {
    let id = UUID()
    let time: String
    let amount: Double
    let date: Date
}

struct DaySummary {
    let label: String
    let total: Double
}

// MARK: - Main View

struct MerchantStatsView: View {

    @State private var selectedPeriod: Period = .week
    @State private var animateBars = false

    enum Period: String, CaseIterable {
        case today = "today"
        case week  = "week"
        case month = "month"

        var displayName: String {
            switch self {
            case .today: return LocalizedString("merchantStats.today")
            case .week: return LocalizedString("merchantStats.week")
            case .month: return LocalizedString("merchantStats.month")
            }
        }
    }

    // Mock data
    private let weekData: [DaySummary] = [
        .init(label: "L",  total: 520),
        .init(label: "M",  total: 780),
        .init(label: "M",  total: 1240),
        .init(label: "J",  total: 960),
        .init(label: "V",  total: 430),
        .init(label: "S",  total: 1100),
        .init(label: "D",  total: 340),
    ]

    private let todayData: [DaySummary] = [
        .init(label: "9am",  total: 310),
        .init(label: "10am", total: 190),
        .init(label: "11am", total: 200),
        .init(label: "12pm", total: 450),
        .init(label: "1pm",  total: 150),
        .init(label: "2pm",  total: 80),
        .init(label: "3pm",  total: 0),
    ]

    private let monthData: [DaySummary] = [
        .init(label: "S1", total: 4200),
        .init(label: "S2", total: 5800),
        .init(label: "S3", total: 7370),
        .init(label: "S4", total: 3900),
    ]

    private let recentSales: [SaleEntry] = [
        .init(time: "2:30pm", amount: 80,  date: Date()),
        .init(time: "1:15pm", amount: 150, date: Date()),
        .init(time: "12:40pm", amount: 45, date: Date()),
        .init(time: "11:00am", amount: 200, date: Date()),
        .init(time: "10:30am", amount: 120, date: Date()),
        .init(time: "9:45am",  amount: 95,  date: Date()),
    ]

    private var currentData: [DaySummary] {
        switch selectedPeriod {
        case .today:  return todayData
        case .week:   return weekData
        case .month:  return monthData
        }
    }

    private var periodTotal: Double {
        currentData.reduce(0) { $0 + $1.total }
    }

    private var bestDay: DaySummary? {
        currentData.max(by: { $0.total < $1.total })
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0A0A1A"), Color(hex: "#0D1B2A")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    periodPicker
                    totalCard
                    barChart
                    if let best = bestDay {
                        bestDayBanner(best)
                    }
                    salesList
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.15)) {
                animateBars = true
            }
        }
        .onChange(of: selectedPeriod) { _ in
            animateBars = false
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.05)) {
                animateBars = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(LocalizedString("merchantStats.title"))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            Spacer()
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(Period.allCases, id: \.self) { period in
                Button {
                    selectedPeriod = period
                } label: {
                    Text(period.displayName)
                        .font(.system(size: 14, weight: selectedPeriod == period ? .semibold : .regular))
                        .foregroundColor(selectedPeriod == period ? .white : .white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            selectedPeriod == period
                                ? RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.25))
                                : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.07))
        )
    }

    // MARK: - Total Card

    private var totalCard: some View {
        VStack(spacing: 4) {
            Text(periodTotal, format: .currency(code: "MXN"))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(periodLabel)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(glassCard(color: .orange.opacity(0.08)))
    }

    private var periodLabel: String {
        switch selectedPeriod {
        case .today:  return LocalizedString("merchantStats.earnedToday")
        case .week:   return LocalizedString("merchantStats.thisWeek")
        case .month:  return LocalizedString("merchantStats.thisMonth")
        }
    }

    // MARK: - Bar Chart

    private var barChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            let maxVal = currentData.map(\.total).max() ?? 1

            GeometryReader { geo in
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(currentData.enumerated()), id: \.offset) { idx, day in
                        let ratio = day.total / maxVal
                        let isBest = day.total == maxVal && day.total > 0
                        let barH = max(4, (geo.size.height - 24) * ratio)

                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    isBest
                                    ? LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                                )
                                .frame(
                                    width: (geo.size.width - CGFloat(currentData.count - 1) * 6) / CGFloat(currentData.count),
                                    height: animateBars ? barH : 4
                                )
                                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(idx) * 0.05), value: animateBars)

                            Text(day.label)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.45))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
            }
            .frame(height: 130)
        }
        .padding(16)
        .background(glassCard(color: .clear))
    }

    // MARK: - Best Day Banner

    private func bestDayBanner(_ day: DaySummary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 18))
                .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                .frame(width: 40, height: 40)
                .background(Color.yellow.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(periodDayLabel): \(day.label)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(day.total, format: .currency(code: "MXN"))
                    .font(.system(size: 13))
                    .foregroundColor(.orange)
            }
            Spacer()
        }
        .padding(12)
        .background(glassCard(color: .yellow.opacity(0.06)))
    }

    private var periodDayLabel: String {
        switch selectedPeriod {
        case .today:  return LocalizedString("merchantStats.bestHour")
        case .week:   return LocalizedString("merchantStats.bestDay")
        case .month:  return LocalizedString("merchantStats.bestWeek")
        }
    }

    // MARK: - Sales List

    private var salesList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedString("merchantStats.recentSales"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .kerning(1.5)

            VStack(spacing: 1) {
                ForEach(recentSales) { sale in
                    HStack {
                        Text(sale.time)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.55))
                            .frame(width: 72, alignment: .leading)

                        Spacer()

                        Text(sale.amount, format: .currency(code: "MXN"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color.white.opacity(0.03))

                    if sale.id != recentSales.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.06))
                            .padding(.horizontal, 14)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
            )
        }
    }
}

// MARK: - Helpers

private func glassCard(color: Color) -> some View {
    ZStack {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(color)
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
    }
}
