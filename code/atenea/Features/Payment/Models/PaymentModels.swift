import Foundation

// MARK: - Sale Flow Step

enum SaleStep: Int {
    case enterAmount
    case showQR
    case cashPayment
    case confirmed
}

// MARK: - Payment Status

enum PaymentStatus: String, Codable {
    case pending
    case completed
    case failed
}

// MARK: - Stripe API Responses

struct StripePrice: Codable {
    let id: String
    let active: Bool
    let currency: String
    let unitAmount: Int

    enum CodingKeys: String, CodingKey {
        case id, active, currency
        case unitAmount = "unit_amount"
    }
}

struct PaymentLinkResponse: Codable {
    let id: String
    let url: String
    let active: Bool
}

struct CheckoutSession: Codable {
    let id: String
    let paymentStatus: String
    let amountTotal: Int?
    let currency: String?

    enum CodingKeys: String, CodingKey {
        case id
        case paymentStatus = "payment_status"
        case amountTotal = "amount_total"
        case currency
    }
}

struct CheckoutSessionList: Codable {
    let data: [CheckoutSession]
}

// MARK: - Sale Record

struct SaleRecord: Identifiable, Codable {
    let id: UUID
    let amount: Int // centavos
    let currency: String
    let description: String
    let status: PaymentStatus
    let createdAt: Date
    let paymentLinkId: String

    var formattedAmount: String {
        let value = Double(amount) / 100.0
        return String(format: "$%.2f MXN", value)
    }
}

// MARK: - Stripe Errors

enum StripeError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, String?)
    case noAPIKey
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL de Stripe inválida"
        case .invalidResponse:
            return "Respuesta inválida de Stripe"
        case .httpError(let code, let message):
            return message ?? "Error HTTP: \(code)"
        case .noAPIKey:
            return "Configura tu Stripe API key en Settings"
        case .decodingError:
            return "Error al procesar respuesta de Stripe"
        }
    }
}

// MARK: - Stripe Error Response

struct StripeErrorResponse: Codable {
    let error: StripeErrorDetail
}

struct StripeErrorDetail: Codable {
    let type: String
    let message: String
}
