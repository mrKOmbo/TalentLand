import Foundation
internal import Combine

class SalesHistoryManager: ObservableObject {

    static let shared = SalesHistoryManager()

    @Published var sales: [SaleRecord] = []

    private let storageKey = "atenea_sales_history"

    private init() {
        loadSales()
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
