import Foundation
internal import Combine

// WARNING: Demo only — API key in client is NOT safe for production. Move to backend.

class StripeService: ObservableObject {

    static let shared = StripeService()

    private let baseURL = "https://api.stripe.com/v1"

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var apiKey: String {
        APIConfiguration.shared.stripeSecretKey
    }

    private init() {}

    // MARK: - Create Payment Link

    func createPaymentLink(amount: Int, currency: String = "mxn", description: String) async throws -> PaymentLinkResponse {
        guard !apiKey.isEmpty else { throw StripeError.noAPIKey }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        // Paso 1: Crear un Price on-the-fly
        let price = try await createPrice(amount: amount, currency: currency, description: description)

        // Paso 2: Crear Payment Link con ese Price
        let paymentLink = try await createPaymentLinkWithPrice(priceId: price.id)

        return paymentLink
    }

    // MARK: - Check Payment Status

    func checkPaymentStatus(paymentLinkId: String) async throws -> PaymentStatus {
        guard !apiKey.isEmpty else { throw StripeError.noAPIKey }

        let url = URL(string: "\(baseURL)/checkout/sessions?payment_link=\(paymentLinkId)&limit=1")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)

        let sessions = try JSONDecoder().decode(CheckoutSessionList.self, from: data)

        guard let session = sessions.data.first else {
            return .pending
        }

        switch session.paymentStatus {
        case "paid":
            return .completed
        case "unpaid":
            return .pending
        default:
            return .failed
        }
    }

    // MARK: - Private Helpers

    private func createPrice(amount: Int, currency: String, description: String) async throws -> StripePrice {
        let url = URL(string: "\(baseURL)/prices")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let productName = description.isEmpty ? "Venta Atenea" : description
        let body = "unit_amount=\(amount)&currency=\(currency)&product_data[name]=\(productName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? productName)"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)

        do {
            return try JSONDecoder().decode(StripePrice.self, from: data)
        } catch {
            throw StripeError.decodingError
        }
    }

    private func createPaymentLinkWithPrice(priceId: String) async throws -> PaymentLinkResponse {
        let url = URL(string: "\(baseURL)/payment_links")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "line_items[0][price]=\(priceId)&line_items[0][quantity]=1"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)

        do {
            return try JSONDecoder().decode(PaymentLinkResponse.self, from: data)
        } catch {
            throw StripeError.decodingError
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StripeError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            var message: String?
            if let errorResponse = try? JSONDecoder().decode(StripeErrorResponse.self, from: data) {
                message = errorResponse.error.message
            }
            throw StripeError.httpError(httpResponse.statusCode, message)
        }
    }
}
