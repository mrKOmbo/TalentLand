//
//  StreetCredManager.swift
//  atenea
//
//  Motor de cálculo del Street Cred Score
//  Modelo: 6 dimensiones ponderadas → Score 0-1000 → 6 niveles
//
//  Inspirado en:
//  - M-Pesa/M-Shwari (scoring por transacciones móviles)
//  - Square Capital (volumen + consistencia → elegibilidad)
//  - Airbnb Superhost (criterios transparentes + evaluación periódica)
//

import Foundation
internal import Combine

class StreetCredManager: ObservableObject {
    static let shared = StreetCredManager()

    @Published var currentScore: StreetCredScore?
    @Published var scoreHistory: [StreetCredSnapshot] = []

    private let storageKey = "atenea_street_cred"
    private let historyKey = "atenea_street_cred_history"
    private let activityLogKey = "atenea_activity_log"

    // Log de actividad diaria (persistido)
    @Published var activityLog: [DailyActivity] = []

    private init() {
        DispatchQueue.main.async { [self] in
            loadActivityLog()
            loadHistory()
        }
    }

    // MARK: - Cálculo Principal

    func calculateScore(for merchant: Merchant) -> StreetCredScore {
        let activity = calculateActivity(for: merchant)
        let volume = calculateVolume(for: merchant)
        let consistency = calculateConsistency(for: merchant)
        let reputation = calculateReputation(for: merchant)
        let diversification = calculateDiversification(for: merchant)
        let coverage = calculateCoverage(for: merchant)

        let dimensions = [activity, volume, consistency, reputation, diversification, coverage]

        // Score total: suma ponderada (cada dimensión ya tiene su maxPoints)
        let totalScore = min(dimensions.reduce(0) { $0 + $1.points }, 1000)

        // Aplicar decay por inactividad
        let daysSinceLastActive = daysSinceLastActivity(for: merchant.id)
        let decayFactor = max(0.5, 1.0 - Double(daysSinceLastActive) * 0.02)
        let adjustedScore = Int(Double(totalScore) * decayFactor)

        // Determinar nivel
        let level = levelForScore(adjustedScore)

        // Badges
        let badges = calculateBadges(for: merchant, score: adjustedScore, dimensions: dimensions)

        // Streak
        let streak = calculateStreak(for: merchant.id)

        let score = StreetCredScore(
            merchantId: merchant.id,
            totalScore: adjustedScore,
            level: level,
            dimensions: dimensions,
            badges: badges,
            streak: streak,
            lastCalculated: Date()
        )

        currentScore = score
        saveSnapshot(score)
        return score
    }

    // MARK: - Dimensión 1: ACTIVIDAD (25% → 250 pts max)

    private func calculateActivity(for merchant: Merchant) -> ScoreDimension {
        let log = activityLog.filter { $0.merchantId == merchant.id }
        let last30 = log.filter { $0.date > Calendar.current.date(byAdding: .day, value: -30, to: Date())! }

        let daysActive = Double(last30.count)
        let avgHours = last30.isEmpty ? 0 : last30.reduce(0.0) { $0 + $1.hoursActive } / Double(last30.count)
        let sessionsPerDay = last30.isEmpty ? 0 : last30.reduce(0.0) { $0 + Double($1.sessions) } / Double(last30.count)
        let streak = Double(calculateStreak(for: merchant.id))

        let score = 0.35 * min(daysActive / 30.0, 1.0) +
                    0.25 * min(avgHours / 12.0, 1.0) +
                    0.20 * min(sessionsPerDay / 3.0, 1.0) +
                    0.20 * min(streak / 30.0, 1.0)

        return ScoreDimension(
            id: "actividad",
            name: "Actividad",
            value: min(max(score, 0), 1),
            maxPoints: 250,
            details: "\(Int(daysActive)) días activo · \(String(format: "%.1f", avgHours))h promedio"
        )
    }

    // MARK: - Dimensión 2: VOLUMEN (20% → 200 pts max)

    private func calculateVolume(for merchant: Merchant) -> ScoreDimension {
        let sales = SalesHistoryManager.shared.salesForMerchant(merchant.id)
        let last30 = sales.filter { $0.createdAt > Calendar.current.date(byAdding: .day, value: -30, to: Date())! }

        let totalRevenue = last30.reduce(0) { $0 + $1.amount }
        let avgTicket = last30.isEmpty ? 0 : totalRevenue / last30.count
        let transactionCount = last30.count

        // Normalización relativa (benchmarks para vendedor ambulante promedio)
        let revenueNorm = min(Double(totalRevenue) / 15000_00, 1.0) // $15,000 MXN/mes = 1.0
        let ticketNorm = min(Double(avgTicket) / 150_00, 1.0) // $150 MXN promedio = 1.0
        let countNorm = min(Double(transactionCount) / 200.0, 1.0) // 200 transacciones/mes = 1.0

        // Tendencia (comparar últimos 15 días vs anteriores 15)
        let mid = Calendar.current.date(byAdding: .day, value: -15, to: Date())!
        let recent = last30.filter { $0.createdAt > mid }.reduce(0) { $0 + $1.amount }
        let previous = last30.filter { $0.createdAt <= mid }.reduce(0) { $0 + $1.amount }
        let trend = previous > 0 ? min(max(Double(recent) / Double(previous) - 1.0, -1.0), 1.0) : 0.0
        let trendNorm = (trend + 1.0) / 2.0 // normalizar de [-1,1] a [0,1]

        let score = 0.35 * revenueNorm +
                    0.25 * ticketNorm +
                    0.25 * countNorm +
                    0.15 * trendNorm

        let formattedRevenue = String(format: "$%.0f", Double(totalRevenue) / 100.0)

        return ScoreDimension(
            id: "volumen",
            name: "Volumen",
            value: min(max(score, 0), 1),
            maxPoints: 200,
            details: "\(transactionCount) ventas · \(formattedRevenue) MXN"
        )
    }

    // MARK: - Dimensión 3: CONSISTENCIA (20% → 200 pts max)

    private func calculateConsistency(for merchant: Merchant) -> ScoreDimension {
        let log = activityLog.filter { $0.merchantId == merchant.id }
        let last30 = log.filter { $0.date > Calendar.current.date(byAdding: .day, value: -30, to: Date())! }

        // Coeficiente de variación de ingresos diarios
        let dailyRevenues = last30.map { $0.revenue }
        let cv = coefficientOfVariation(dailyRevenues)
        let cvNorm = 1.0 - min(cv, 1.0)

        // Regularidad de horario (consistencia en hora de inicio)
        let startTimes = last30.compactMap { $0.startHour }
        let hourCV = coefficientOfVariation(startTimes.map { Double($0) })
        let regularityNorm = 1.0 - min(hourCV, 1.0)

        // Gaps (días sin actividad)
        let gapDays = 30 - last30.count
        let gapNorm = 1.0 - (Double(gapDays) / 30.0)

        // Antigüedad
        let monthsActive = Calendar.current.dateComponents([.month], from: merchant.createdAt, to: Date()).month ?? 0
        let tenureNorm = min(Double(monthsActive) / 12.0, 1.0)

        let score = 0.30 * cvNorm +
                    0.25 * regularityNorm +
                    0.25 * max(gapNorm, 0) +
                    0.20 * tenureNorm

        return ScoreDimension(
            id: "consistencia",
            name: "Consistencia",
            value: min(max(score, 0), 1),
            maxPoints: 200,
            details: "\(30 - gapDays)/30 días · \(monthsActive) meses en Atenea"
        )
    }

    // MARK: - Dimensión 4: REPUTACIÓN (15% → 150 pts max)

    private func calculateReputation(for merchant: Merchant) -> ScoreDimension {
        let timbres = TimbreManager.shared.timbresForMerchant(merchant.id)
        let totalTimbres = timbres.count
        let respondedTimbres = timbres.filter { $0.isResponded }.count

        // Tasa de respuesta a timbres
        let responseRate = totalTimbres > 0 ? Double(respondedTimbres) / Double(totalTimbres) : 0.5

        // Demanda (timbres recibidos como proxy de popularidad)
        let demandNorm = min(Double(totalTimbres) / 50.0, 1.0)

        // Rating simulado (basado en tasa de respuesta + demanda)
        let ratingProxy = (responseRate * 0.6 + demandNorm * 0.4)

        // Clientes únicos
        let uniqueClients = Set(timbres.map { $0.clientId }).count
        let clientDiversity = min(Double(uniqueClients) / 30.0, 1.0)

        let score = 0.35 * ratingProxy +
                    0.25 * responseRate +
                    0.25 * demandNorm +
                    0.15 * clientDiversity

        return ScoreDimension(
            id: "reputacion",
            name: "Reputacion",
            value: min(max(score, 0), 1),
            maxPoints: 150,
            details: "\(totalTimbres) timbres · \(Int(responseRate * 100))% respondidos"
        )
    }

    // MARK: - Dimensión 5: DIVERSIFICACIÓN (10% → 100 pts max)

    private func calculateDiversification(for merchant: Merchant) -> ScoreDimension {
        let productCount = merchant.products.count
        let productNorm = min(Double(productCount) / 10.0, 1.0)

        // Categorías únicas en productos
        let categories = Set(merchant.products.map { $0.name.prefix(3) }).count
        let catNorm = min(Double(categories) / 3.0, 1.0)

        // Métodos de pago (verificar si tiene ventas con diferentes métodos)
        let sales = SalesHistoryManager.shared.salesForMerchant(merchant.id)
        let hasQR = sales.contains { !$0.paymentLinkId.isEmpty }
        let hasCash = sales.contains { $0.paymentLinkId == "cash" }
        let hasTapToPay = sales.contains { $0.paymentLinkId == "tap-to-pay" }
        let methodCount = [hasQR, hasCash, hasTapToPay].filter { $0 }.count
        let methodNorm = Double(methodCount) / 3.0

        // Horario amplio
        let scheduleNorm: Double
        if let schedule = merchant.schedule {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            if let open = formatter.date(from: schedule.openTime),
               let close = formatter.date(from: schedule.closeTime) {
                let hours = close.timeIntervalSince(open) / 3600.0
                scheduleNorm = min(hours / 14.0, 1.0)
            } else {
                scheduleNorm = 0.5
            }
        } else {
            scheduleNorm = 0.3
        }

        let score = 0.30 * productNorm +
                    0.25 * catNorm +
                    0.25 * methodNorm +
                    0.20 * scheduleNorm

        return ScoreDimension(
            id: "diversificacion",
            name: "Diversificacion",
            value: min(max(score, 0), 1),
            maxPoints: 100,
            details: "\(productCount) productos · \(methodCount) formas de pago"
        )
    }

    // MARK: - Dimensión 6: COBERTURA (10% → 100 pts max)

    private func calculateCoverage(for merchant: Merchant) -> ScoreDimension {
        let log = activityLog.filter { $0.merchantId == merchant.id }

        // Zonas únicas operadas (geohashes únicos)
        let uniqueZones = Set(log.compactMap { $0.geohash }).count
        let zoneNorm = min(Double(uniqueZones) / 10.0, 1.0)

        // Presencia en zonas de alta demanda
        let demandZones = DemandZoneManager.shared.topZones(limit: 5)
        let demandGeohashes = Set(demandZones.map { $0.geohash })
        let merchantGeohashes = Set(log.compactMap { $0.geohash })
        let demandOverlap = Double(demandGeohashes.intersection(merchantGeohashes).count)
        let demandNorm = demandGeohashes.isEmpty ? 0.5 : min(demandOverlap / Double(demandGeohashes.count), 1.0)

        // Distancia total recorrida (proxy por número de ubicaciones diferentes)
        let locations = log.count
        let mobilityNorm = min(Double(locations) / 60.0, 1.0) // 2 ubicaciones/día × 30 días

        let score = 0.35 * zoneNorm +
                    0.35 * demandNorm +
                    0.30 * mobilityNorm

        return ScoreDimension(
            id: "cobertura",
            name: "Cobertura",
            value: min(max(score, 0), 1),
            maxPoints: 100,
            details: "\(uniqueZones) zonas cubiertas"
        )
    }

    // MARK: - Badges

    private func calculateBadges(for merchant: Merchant, score: Int, dimensions: [ScoreDimension]) -> [StreetCredBadge] {
        var badges: [StreetCredBadge] = []
        let sales = SalesHistoryManager.shared.salesForMerchant(merchant.id)
        let streak = calculateStreak(for: merchant.id)
        let timbres = TimbreManager.shared.timbresForMerchant(merchant.id)

        // Primera venta
        badges.append(StreetCredBadge(
            id: "first_sale", name: "Primera Venta", emoji: "🎉",
            description: "Completaste tu primera venta en Atenea",
            earnedAt: sales.last?.createdAt
        ))

        // 50 ventas
        badges.append(StreetCredBadge(
            id: "50_sales", name: "Medio Centenar", emoji: "💪",
            description: "50 ventas completadas",
            earnedAt: sales.count >= 50 ? Date() : nil
        ))

        // 100 ventas
        badges.append(StreetCredBadge(
            id: "100_sales", name: "Centenario", emoji: "🏆",
            description: "100 ventas completadas",
            earnedAt: sales.count >= 100 ? Date() : nil
        ))

        // Racha de 7 días
        badges.append(StreetCredBadge(
            id: "streak_7", name: "Constante", emoji: "🔥",
            description: "7 días consecutivos operando",
            earnedAt: streak >= 7 ? Date() : nil
        ))

        // Racha de 30 días
        badges.append(StreetCredBadge(
            id: "streak_30", name: "Marathonista", emoji: "🏃",
            description: "30 días consecutivos operando",
            earnedAt: streak >= 30 ? Date() : nil
        ))

        // Respondedor rápido (>90% de timbres respondidos)
        let responseRate = timbres.isEmpty ? 0 : Double(timbres.filter { $0.isResponded }.count) / Double(timbres.count)
        badges.append(StreetCredBadge(
            id: "fast_responder", name: "Atento", emoji: "⚡",
            description: "Responde a más del 90% de los timbres",
            earnedAt: timbres.count >= 5 && responseRate > 0.9 ? Date() : nil
        ))

        // Multi-pago
        let hasMultiplePayments = Set(sales.map { $0.paymentLinkId.hasPrefix("cash") ? "cash" : $0.paymentLinkId.hasPrefix("tap") ? "tap" : "qr" }).count >= 2
        badges.append(StreetCredBadge(
            id: "multi_pay", name: "Multi-Pago", emoji: "💳",
            description: "Acepta 2+ formas de pago",
            earnedAt: hasMultiplePayments ? Date() : nil
        ))

        // Elegible para crédito Coppel
        badges.append(StreetCredBadge(
            id: "credit_eligible", name: "Coppel Emprende", emoji: "🏦",
            description: "Elegible para microcrédito Coppel Emprende",
            earnedAt: score >= 400 ? Date() : nil
        ))

        return badges
    }

    // MARK: - Activity Log

    func logActivity(merchantId: UUID, hoursActive: Double, sessions: Int, revenue: Double, geohash: String?, startHour: Int?) {
        let today = Calendar.current.startOfDay(for: Date())

        // Actualizar o crear entrada de hoy
        if let index = activityLog.firstIndex(where: { $0.merchantId == merchantId && Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            activityLog[index].hoursActive += hoursActive
            activityLog[index].sessions += sessions
            activityLog[index].revenue += revenue
            if let gh = geohash { activityLog[index].geohash = gh }
        } else {
            activityLog.append(DailyActivity(
                merchantId: merchantId,
                date: today,
                hoursActive: hoursActive,
                sessions: sessions,
                revenue: revenue,
                geohash: geohash,
                startHour: startHour
            ))
        }

        saveActivityLog()
    }

    // MARK: - Mock Data (para demo)

    func generateMockData(for merchant: Merchant) {
        let calendar = Calendar.current
        let today = Date()

        // Generar 45 días de actividad simulada
        for dayOffset in 0..<45 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            // Algunos días sin actividad (realismo)
            let isActive = Double.random(in: 0...1) > 0.15 // 85% de días activo
            guard isActive else { continue }

            let hours = Double.random(in: 4...10)
            let sessions = Int.random(in: 1...4)
            let revenue = Double.random(in: 500...3500)
            let geohashes = ["9q8yy", "9q8yz", "9q8yw", "9q8yx", "9q8yv"]
            let geohash = geohashes.randomElement()
            let startHour = Int.random(in: 7...12)

            activityLog.append(DailyActivity(
                merchantId: merchant.id,
                date: date,
                hoursActive: hours,
                sessions: sessions,
                revenue: revenue,
                geohash: geohash,
                startHour: startHour
            ))
        }

        // Generar ventas mock asociadas al merchant
        for i in 0..<65 {
            guard let date = calendar.date(byAdding: .day, value: -Int.random(in: 0...30), to: today) else { continue }
            let methods = ["link_", "cash", "tap-to-pay"]
            let sale = SaleRecord(
                id: UUID(),
                amount: Int.random(in: 25_00...250_00),
                currency: "mxn",
                description: "Venta #\(i + 1)",
                status: .completed,
                createdAt: date,
                paymentLinkId: methods.randomElement()!,
                merchantId: merchant.id
            )
            SalesHistoryManager.shared.addSale(sale)
        }

        saveActivityLog()
    }

    // MARK: - Helpers

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

    private func calculateStreak(for merchantId: UUID) -> Int {
        let calendar = Calendar.current
        let log = activityLog
            .filter { $0.merchantId == merchantId }
            .sorted { $0.date > $1.date }

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        for _ in 0..<365 {
            if log.contains(where: { calendar.isDate($0.date, inSameDayAs: checkDate) }) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    private func daysSinceLastActivity(for merchantId: UUID) -> Int {
        let log = activityLog
            .filter { $0.merchantId == merchantId }
            .sorted { $0.date > $1.date }

        guard let lastDate = log.first?.date else { return 30 }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 30
    }

    private func coefficientOfVariation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        guard mean > 0 else { return 0 }
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        return sqrt(variance) / mean
    }

    // MARK: - Persistence

    private func saveActivityLog() {
        guard let data = try? JSONEncoder().encode(activityLog) else { return }
        UserDefaults.standard.set(data, forKey: activityLogKey)
    }

    private func loadActivityLog() {
        guard let data = UserDefaults.standard.data(forKey: activityLogKey),
              let decoded = try? JSONDecoder().decode([DailyActivity].self, from: data) else { return }
        activityLog = decoded
    }

    private func saveSnapshot(_ score: StreetCredScore) {
        let snapshot = StreetCredSnapshot(date: Date(), score: score.totalScore, level: score.level)
        scoreHistory.append(snapshot)
        // Mantener solo últimos 90 días
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        scoreHistory.removeAll { $0.date < cutoff }
        guard let data = try? JSONEncoder().encode(scoreHistory) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([StreetCredSnapshot].self, from: data) else { return }
        scoreHistory = decoded
    }
}

// MARK: - Supporting Types

struct DailyActivity: Codable, Identifiable {
    var id: String { "\(merchantId)-\(date.timeIntervalSince1970)" }
    let merchantId: UUID
    let date: Date
    var hoursActive: Double
    var sessions: Int
    var revenue: Double
    var geohash: String?
    var startHour: Int?
}

struct StreetCredSnapshot: Codable, Identifiable {
    var id: String { "\(date.timeIntervalSince1970)" }
    let date: Date
    let score: Int
    let level: StreetCredLevel
}
