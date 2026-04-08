import Foundation
internal import Combine

@MainActor
class SaleViewModel: ObservableObject {

    // MARK: - Published State

    @Published var amountString: String = ""
    @Published var saleDescription: String = ""
    @Published var currentStep: SaleStep = .enterAmount
    @Published var paymentLinkURL: String?
    @Published var paymentLinkId: String?
    @Published var isGenerating: Bool = false
    @Published var paymentStatus: PaymentStatus = .pending
    @Published var errorMessage: String?
    @Published var cashReceivedString: String = ""

    private let stripeService = StripeService.shared
    private var pollingTimer: AnyCancellable?

    // MARK: - Computed

    var amountInCents: Int {
        let cleaned = amountString.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned) else { return 0 }
        return Int(value * 100)
    }

    var formattedAmount: String {
        guard !amountString.isEmpty else { return "$0.00" }
        let cleaned = amountString.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned) else { return "$\(amountString)" }
        return String(format: "$%.2f", value)
    }

    var canGenerate: Bool {
        amountInCents > 0 && !isGenerating
    }

    var amountValue: Double {
        Double(amountInCents) / 100.0
    }

    var cashReceivedValue: Double {
        let cleaned = cashReceivedString.replacingOccurrences(of: ",", with: ".")
        return Double(cleaned) ?? 0
    }

    var changeAmount: Double {
        max(cashReceivedValue - amountValue, 0)
    }

    var formattedChange: String {
        String(format: "$%.2f", changeAmount)
    }

    // MARK: - Cash Payment

    func startCashPayment() {
        cashReceivedString = ""
        currentStep = .cashPayment
    }

    func confirmCashPayment() {
        paymentStatus = .completed
        currentStep = .confirmed
    }

    // MARK: - Keypad Actions

    func appendDigit(_ digit: String) {
        if digit == "." {
            if amountString.contains(".") { return }
            if amountString.isEmpty { amountString = "0" }
        }
        // Limitar a 2 decimales
        if let dotIndex = amountString.firstIndex(of: ".") {
            let decimals = amountString[amountString.index(after: dotIndex)...]
            if decimals.count >= 2 { return }
        }
        // Limitar longitud total
        if amountString.count >= 10 { return }
        amountString += digit
    }

    func deleteLastDigit() {
        guard !amountString.isEmpty else { return }
        amountString.removeLast()
    }

    // MARK: - Stripe Integration

    func generatePaymentLink() async {
        guard canGenerate else { return }

        isGenerating = true
        errorMessage = nil

        do {
            let response = try await stripeService.createPaymentLink(
                amount: amountInCents,
                description: saleDescription.isEmpty ? "Venta Atenea" : saleDescription
            )
            paymentLinkURL = response.url
            paymentLinkId = response.id
            currentStep = .showQR
            startPolling()
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }

    // MARK: - Payment Polling

    func startPolling() {
        stopPolling()

        pollingTimer = Timer.publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                Task {
                    await self.checkStatus()
                }
            }

        // Timeout: parar después de 10 minutos
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000_000)
            stopPolling()
        }
    }

    func stopPolling() {
        pollingTimer?.cancel()
        pollingTimer = nil
    }

    private func checkStatus() async {
        guard let linkId = paymentLinkId else { return }

        do {
            let status = try await stripeService.checkPaymentStatus(paymentLinkId: linkId)
            if status == .completed {
                paymentStatus = .completed
                currentStep = .confirmed
                stopPolling()
            }
        } catch {
            // Silenciar errores de polling — seguir intentando
        }
    }

    // MARK: - Reset

    func reset() {
        amountString = ""
        saleDescription = ""
        currentStep = .enterAmount
        paymentLinkURL = nil
        paymentLinkId = nil
        isGenerating = false
        paymentStatus = .pending
        errorMessage = nil
        cashReceivedString = ""
        stopPolling()
    }

    deinit {
        pollingTimer?.cancel()
    }
}
