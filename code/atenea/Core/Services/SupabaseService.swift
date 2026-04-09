//
//  SupabaseService.swift
//  atenea
//
//  Servicio para sincronizar merchants con Supabase (komiia.com)
//

import Foundation

class SupabaseService {
    static let shared = SupabaseService()

    private let baseURL = "https://fkkddxibqlmunuqzdrsm.supabase.co/rest/v1"
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZra2RkeGlicWxtdW51cXpkcnNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3MDI4OTUsImV4cCI6MjA5MTI3ODg5NX0.smyrNinvVQ_RwaKpekXzZ4Xo8O5a5DbNuVZcwcuLjeg"

    private init() {}

    private var headers: [String: String] {
        [
            "apikey": apiKey,
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        ]
    }

    // MARK: - Save Merchant

    /// Guarda un merchant en Supabase. Si ya existe (por business_name), lo actualiza.
    func saveMerchant(_ merchant: Merchant) async throws -> String {
        let payload = merchantToPayload(merchant)
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        // Upsert: si ya existe un merchant con el mismo id, actualiza
        var request = URLRequest(url: URL(string: "\(baseURL)/merchants")!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        // Enable upsert on id conflict
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SupabaseError.saveFailed(errorBody)
        }

        // Parse response to get the ID
        if let results = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let first = results.first,
           let id = first["id"] as? String {
            print("☁️ Merchant saved to Supabase: \(merchant.businessName) (id: \(id))")
            return id
        }

        return merchant.id.uuidString
    }

    // MARK: - Fetch All Merchants

    func fetchMerchants() async throws -> [[String: Any]] {
        var request = URLRequest(url: URL(string: "\(baseURL)/merchants?select=*&order=created_at.desc")!)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.fetchFailed
        }

        guard let merchants = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw SupabaseError.decodeFailed
        }

        return merchants
    }

    // MARK: - Get Web URL for merchant

    func webURL(for merchant: Merchant) -> String {
        return "https://komiia.com/biz/\(merchant.id.uuidString)"
    }

    // MARK: - Payload Conversion

    private func merchantToPayload(_ merchant: Merchant) -> [String: Any] {
        var payload: [String: Any] = [
            "business_name": merchant.businessName,
            "category": merchant.category.rawValue,
            "emoji": merchant.emoji,
            "description": merchant.description,
            "is_active": merchant.isActive,
            "is_static": merchant.isStatic
        ]

        if let location = merchant.currentLocation {
            payload["latitude"] = location.latitude
            payload["longitude"] = location.longitude
        }

        if let schedule = merchant.schedule {
            payload["schedule_open"] = schedule.openTime
            payload["schedule_close"] = schedule.closeTime
            payload["schedule_days"] = schedule.daysOfWeek
        }

        let products: [[String: Any]] = merchant.products.map { product in
            var p: [String: Any] = [
                "name": product.name,
                "price": product.price,
                "emoji": product.emoji,
                "available": product.isAvailable
            ]
            if let desc = product.description {
                p["desc"] = desc
            }
            return p
        }
        payload["products"] = products

        return payload
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case saveFailed(String)
    case fetchFailed
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed(let detail): return "Failed to save merchant: \(detail)"
        case .fetchFailed: return "Failed to fetch merchants"
        case .decodeFailed: return "Failed to decode response"
        }
    }
}
