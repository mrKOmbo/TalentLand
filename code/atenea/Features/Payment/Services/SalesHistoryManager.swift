import Foundation
internal import Combine

class SalesHistoryManager: ObservableObject {

    static let shared = SalesHistoryManager()

    @Published var sales: [SaleRecord] = []

    private let storageKey = "atenea_sales_history"

    private init() {
        loadSales()
        loadVouchers()
    }

    // MARK: - Public

    func addSale(_ sale: SaleRecord) {
        sales.insert(sale, at: 0)
        saveSales()
    }

    func todaySales() -> [SaleRecord] {
        let calendar = Calendar.current
        return sales.filter { calendar.isDateInToday($0.createdAt) }
    }

    func todayTotal() -> Double {
        let cents = todaySales().reduce(0) { $0 + $1.amount }
        return Double(cents) / 100.0
    }

    func salesForMerchant(_ merchantId: UUID) -> [SaleRecord] {
        sales.filter { $0.merchantId == merchantId }
    }

    func totalForMerchant(_ merchantId: UUID, days: Int = 30) -> Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let cents = salesForMerchant(merchantId)
            .filter { $0.createdAt > cutoff }
            .reduce(0) { $0 + $1.amount }
        return Double(cents) / 100.0
    }

    // MARK: - BLE Vouchers (pagos offline pendientes de reconciliación)

    @Published var pendingVouchers: [PaymentVoucher] = []
    private let voucherStorageKey = "atenea_pending_vouchers"

    func addPendingVoucher(_ voucher: PaymentVoucher) {
        pendingVouchers.insert(voucher, at: 0)
        saveVouchers()
        print("💰 [Sales] Voucher guardado: \(voucher.clientName) → \(voucher.formattedAmount) (pendientes: \(pendingVouchers.count))")
    }

    var pendingVoucherCount: Int { pendingVouchers.count }

    var pendingVoucherTotal: Double {
        Double(pendingVouchers.reduce(0) { $0 + $1.amount }) / 100.0
    }

    /// Placeholder: cuando haya internet, envía vouchers al backend
    func reconcilePending() {
        guard !pendingVouchers.isEmpty else { return }
        print("💰 [Sales] Reconciliando \(pendingVouchers.count) vouchers pendientes...")
        // TODO: Enviar a AppSync/DynamoDB cuando el backend esté listo
        // Por ahora, marcarlos como reconciliados (moverlos a sales)
        for voucher in pendingVouchers {
            let sale = SaleRecord(
                amount: voucher.amount,
                currency: voucher.currency,
                description: "BLE Offline: \(voucher.clientName) — \(voucher.description)",
                status: .completed,
                paymentLinkId: voucher.id.uuidString,
                merchantId: voucher.merchantID
            )
            sales.insert(sale, at: 0)
        }
        pendingVouchers.removeAll()
        saveSales()
        saveVouchers()
        print("💰 [Sales] ✅ Reconciliación completada")
    }

    private func saveVouchers() {
        guard let data = try? JSONEncoder().encode(pendingVouchers) else { return }
        UserDefaults.standard.set(data, forKey: voucherStorageKey)
    }

    private func loadVouchers() {
        guard let data = UserDefaults.standard.data(forKey: voucherStorageKey),
              let decoded = try? JSONDecoder().decode([PaymentVoucher].self, from: data) else { return }
        pendingVouchers = decoded
    }

    // MARK: - Persistence

    private func saveSales() {
        guard let data = try? JSONEncoder().encode(sales) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func loadSales() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([SaleRecord].self, from: data) else { return }
        sales = decoded
    }
}
