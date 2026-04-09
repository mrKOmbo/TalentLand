//
//  SupabaseService.swift
//  atenea
//
//  Servicio para sincronizar datos con Supabase (komiia.com)
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

    // MARK: - Save User

    func saveUser(_ user: User) async throws {
        let payload: [String: Any] = [
            "id": user.id.uuidString,
            "email": user.email,
            "name": user.name,
            "role": user.role.rawValue,
            "age": user.age ?? "",
            "country": user.country ?? "",
            "phone_number": user.phoneNumber ?? "",
            "accessibility_option": user.accessibilityOption.rawValue,
            "is_verified": user.isVerified,
            "trust_level": user.trustLevel.rawValue
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: URL(string: "\(baseURL)/users")!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("return=representation,resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SupabaseError.saveFailed(errorBody)
        }

        print("☁️ User saved to Supabase: \(user.name) (\(user.email))")
    }

    // MARK: - Save Merchant

    func saveMerchant(_ merchant: Merchant) async throws -> String {
        var payload = merchantToPayload(merchant)
        payload["id"] = merchant.id.uuidString

        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: URL(string: "\(baseURL)/merchants")!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("return=representation,resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SupabaseError.saveFailed(errorBody)
        }

        if let results = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let first = results.first,
           let id = first["id"] as? String {
            print("☁️ Merchant saved to Supabase: \(merchant.businessName) (id: \(id))")
            return id
        }

        return merchant.id.uuidString
    }

    // MARK: - Update Merchant Location

    func updateMerchantLocation(merchantId: UUID, latitude: Double, longitude: Double) async throws {
        let payload: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "is_active": true
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: URL(string: "\(baseURL)/merchants?id=eq.\(merchantId.uuidString)")!)
        request.httpMethod = "PATCH"
        request.httpBody = jsonData
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SupabaseError.saveFailed(errorBody)
        }

        print("☁️ Location updated in Supabase for merchant: \(merchantId)")
    }

    // MARK: - Update Merchant Active Status

    func updateMerchantStatus(merchantId: UUID, isActive: Bool) async throws {
        let payload: [String: Any] = ["is_active": isActive]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: URL(string: "\(baseURL)/merchants?id=eq.\(merchantId.uuidString)")!)
        request.httpMethod = "PATCH"
        request.httpBody = jsonData
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.saveFailed("Status update failed")
        }

        print("☁️ Status updated in Supabase: \(merchantId) → \(isActive ? "active" : "inactive")")
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

    // MARK: - Update Route Status

    /// Marca al comerciante como "en ruta" o "no en ruta" en Supabase
    func updateMerchantRouteStatus(merchantId: UUID, isOnRoute: Bool) async throws {
        let payload: [String: Any] = ["is_on_route": isOnRoute]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: URL(string: "\(baseURL)/merchants?id=eq.\(merchantId.uuidString)")!)
        request.httpMethod = "PATCH"
        request.httpBody = jsonData
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "?"
            throw SupabaseError.saveFailed(body)
        }
        print("☁️ isOnRoute=\(isOnRoute) → merchant \(merchantId)")
    }

    // MARK: - Sync All Mock Merchants (run once on first launch)

    func syncAllMerchants(_ merchants: [Merchant]) async {
        for merchant in merchants {
            do {
                _ = try await saveMerchant(merchant)
            } catch {
                print("⚠️ Failed to sync merchant \(merchant.businessName): \(error.localizedDescription)")
            }
        }
        print("☁️ Synced \(merchants.count) merchants to Supabase")
    }

    // MARK: - Upload Product Image

    /// Sube una imagen de producto a Supabase Storage y devuelve la URL pública
    func uploadProductImage(_ imageData: Data, merchantId: String, productId: String) async throws -> String {
        let fileName = "\(merchantId)/\(productId).jpg"
        let storageURL = "https://fkkddxibqlmunuqzdrsm.supabase.co/storage/v1/object/products/\(fileName)"

        var request = URLRequest(url: URL(string: storageURL)!)
        request.httpMethod = "POST"
        request.httpBody = imageData
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "x-upsert")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SupabaseError.saveFailed("Image upload failed: \(errorBody)")
        }

        let publicURL = "https://fkkddxibqlmunuqzdrsm.supabase.co/storage/v1/object/public/products/\(fileName)"
        print("📸 Image uploaded: \(publicURL)")
        return publicURL
    }

    // MARK: - Payload Conversion

    private func merchantToPayload(_ merchant: Merchant) -> [String: Any] {
        var payload: [String: Any] = [
            "business_name": merchant.businessName,
            "category": merchant.category.rawValue,
            "emoji": merchant.emoji,
            "description": merchant.description,
            "is_active": merchant.isActive,
            "is_static": merchant.isStatic,
            "is_verified": merchant.isVerified,
            "trust_level": merchant.trustLevel.rawValue
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

        if let route = merchant.route {
            let waypoints: [[String: Any]] = route.sortedWaypoints.map { wp in
                var w: [String: Any] = [
                    "id": wp.id.uuidString,
                    "latitude": wp.latitude,
                    "longitude": wp.longitude,
                    "order": wp.order
                ]
                if let name = wp.name {
                    w["name"] = name
                }
                return w
            }
            var routePayload: [String: Any] = [
                "id": route.id.uuidString,
                "merchant_id": route.merchantId.uuidString,
                "waypoints": waypoints,
                "is_active": route.isActive,
                "created_at": ISO8601DateFormatter().string(from: route.createdAt),
                "updated_at": ISO8601DateFormatter().string(from: route.updatedAt)
            ]
            if let geometry = route.routeGeometry {
                routePayload["route_geometry"] = geometry
            }
            if let duration = route.estimatedDuration {
                routePayload["estimated_duration"] = duration
            }
            if let distance = route.estimatedDistance {
                routePayload["estimated_distance"] = distance
            }
            payload["route"] = routePayload
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
            if let imageURL = product.imageURL {
                p["imageURL"] = imageURL
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
