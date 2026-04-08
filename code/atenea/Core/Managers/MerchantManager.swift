//
//  MerchantManager.swift
//  atenea
//
//  Gestor de comerciantes y sus productos
//

import Foundation
internal import Combine
import CoreLocation

class MerchantManager: ObservableObject {
    static let shared = MerchantManager()

    @Published var merchants: [Merchant] = []
    @Published var currentMerchantProfile: Merchant?

    private init() {
        DispatchQueue.main.async { [self] in
            loadMockMerchants()
        }
    }

    // MARK: - Queries

    func merchantForUser(_ userId: UUID) -> Merchant? {
        merchants.first { $0.userId == userId }
    }

    func activeMerchants() -> [Merchant] {
        merchants.filter { $0.isActive }
    }

    func merchant(byId id: UUID) -> Merchant? {
        merchants.first { $0.id == id }
    }

    func merchantsNear(latitude: Double, longitude: Double, radiusMeters: Double = 1000) -> [Merchant] {
        activeMerchants().filter { merchant in
            guard let loc = merchant.currentLocation else { return false }
            let distance = Self.haversineDistance(
                lat1: latitude, lon1: longitude,
                lat2: loc.latitude, lon2: loc.longitude
            )
            return distance <= radiusMeters
        }
        .sorted { a, b in
            guard let locA = a.currentLocation, let locB = b.currentLocation else { return false }
            let distA = Self.haversineDistance(lat1: latitude, lon1: longitude, lat2: locA.latitude, lon2: locA.longitude)
            let distB = Self.haversineDistance(lat1: latitude, lon1: longitude, lat2: locB.latitude, lon2: locB.longitude)
            return distA < distB
        }
    }

    // MARK: - Mutations

    func toggleActive(merchantId: UUID) {
        guard let index = merchants.firstIndex(where: { $0.id == merchantId }) else { return }
        merchants[index].isActive.toggle()
        if merchants[index].id == currentMerchantProfile?.id {
            currentMerchantProfile?.isActive = merchants[index].isActive
        }
    }

    func updateLocation(merchantId: UUID, latitude: Double, longitude: Double) {
        guard let index = merchants.firstIndex(where: { $0.id == merchantId }) else { return }
        merchants[index].currentLocation = MerchantLocation(latitude: latitude, longitude: longitude)
        if merchants[index].id == currentMerchantProfile?.id {
            currentMerchantProfile?.currentLocation = merchants[index].currentLocation
        }
    }

    // MARK: - Convenience

    func distanceFrom(latitude: Double, longitude: Double, to merchant: Merchant) -> Double? {
        guard let loc = merchant.currentLocation else { return nil }
        return Self.haversineDistance(lat1: latitude, lon1: longitude, lat2: loc.latitude, lon2: loc.longitude)
    }

    func formattedDistance(meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }

    /// Convierte merchants a NearbyMerchant para display en HomeView
    func nearbyMerchantsList(fromLatitude lat: Double, longitude lon: Double, radius: Double = 5000) -> [NearbyMerchant] {
        merchantsNear(latitude: lat, longitude: lon, radiusMeters: radius).map { merchant in
            let dist = distanceFrom(latitude: lat, longitude: lon, to: merchant) ?? 0
            return NearbyMerchant(
                emoji: merchant.emoji,
                name: merchant.businessName,
                distance: formattedDistance(meters: dist),
                isActive: merchant.isActive,
                isStatic: merchant.isStatic,
                category: merchant.category.displayName,
                coordinate: merchant.currentLocation?.coordinate ?? CLLocationCoordinate2D()
            )
        }
    }

    // MARK: - Haversine

    static func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371000.0 // Radio de la Tierra en metros
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }

    // MARK: - Mock Data

    private func loadMockMerchants() {
        // userId del usuario "Don Taco" en UserManager
        let donTacoUserId = UserManager.shared.getAllUsers()
            .first(where: { $0.email == "don.taco@atenea.com" })?.id ?? UUID()

        merchants = [
            Merchant(
                userId: donTacoUserId,
                businessName: "Don Taco",
                category: .tacos,
                description: "Los mejores tacos al pastor de la zona del Azteca. Receta familiar desde 1985.",
                products: [
                    Product(name: "Taco al Pastor", price: 18, emoji: "🌮"),
                    Product(name: "Taco de Suadero", price: 20, emoji: "🌮"),
                    Product(name: "Quesadilla", price: 25, emoji: "🧀"),
                    Product(name: "Agua Fresca", price: 15, emoji: "🥤"),
                ],
                schedule: MerchantSchedule(openTime: "10:00", closeTime: "22:00", daysOfWeek: [1, 2, 3, 4, 5, 6, 7]),
                isStatic: true,
                currentLocation: MerchantLocation(latitude: 19.3029, longitude: -99.1506)
            ),
            Merchant(
                userId: UUID(),
                businessName: "Paletas Doña Mary",
                category: .helados,
                emoji: "🍦",
                description: "Paletas artesanales de Michoacán. Frutas naturales, sin conservadores.",
                products: [
                    Product(name: "Paleta de Fresa", price: 20, emoji: "🍓"),
                    Product(name: "Paleta de Mango", price: 20, emoji: "🥭"),
                    Product(name: "Paleta de Limón", price: 18, emoji: "🍋"),
                    Product(name: "Bolis de Coco", price: 12, emoji: "🥥"),
                ],
                schedule: MerchantSchedule(openTime: "09:00", closeTime: "20:00", daysOfWeek: [1, 2, 3, 4, 5, 6, 7]),
                isStatic: false,
                currentLocation: MerchantLocation(latitude: 19.3492, longitude: -99.1617)
            ),
            Merchant(
                userId: UUID(),
                businessName: "Jugos Mary",
                category: .jugos,
                emoji: "🥤",
                description: "Jugos y licuados naturales. Mixtos, verdes y detox.",
                products: [
                    Product(name: "Jugo de Naranja", price: 25, emoji: "🍊"),
                    Product(name: "Licuado de Plátano", price: 30, emoji: "🍌"),
                    Product(name: "Jugo Verde", price: 35, emoji: "🥬"),
                ],
                schedule: MerchantSchedule(openTime: "07:00", closeTime: "15:00", daysOfWeek: [1, 2, 3, 4, 5, 6]),
                isStatic: true,
                currentLocation: MerchantLocation(latitude: 19.4185, longitude: -99.1654)
            ),
            Merchant(
                userId: UUID(),
                businessName: "Tamales Oaxaqueños",
                category: .tamales,
                emoji: "🫔",
                description: "Tamales de mole negro, rajas y dulce. Hechos cada madrugada.",
                products: [
                    Product(name: "Tamal de Mole", price: 20, emoji: "🫔"),
                    Product(name: "Tamal de Rajas", price: 18, emoji: "🌶️"),
                    Product(name: "Tamal Dulce", price: 15, emoji: "🍬"),
                    Product(name: "Atole", price: 15, emoji: "☕"),
                ],
                schedule: MerchantSchedule(openTime: "06:00", closeTime: "12:00", daysOfWeek: [1, 2, 3, 4, 5, 6, 7]),
                isStatic: false,
                currentLocation: MerchantLocation(latitude: 19.4326, longitude: -99.1332)
            ),
            Merchant(
                userId: UUID(),
                businessName: "Elotes Don Chuy",
                category: .elotes,
                emoji: "🌽",
                description: "Elotes y esquites preparados. Con todo: mayonesa, queso, chile y limón.",
                products: [
                    Product(name: "Elote preparado", price: 25, emoji: "🌽"),
                    Product(name: "Esquites", price: 20, emoji: "🥤"),
                    Product(name: "Esquites con Flamin' Hot", price: 30, emoji: "🔥"),
                ],
                schedule: MerchantSchedule(openTime: "14:00", closeTime: "22:00", daysOfWeek: [1, 2, 3, 4, 5, 6, 7]),
                isStatic: false,
                currentLocation: MerchantLocation(latitude: 19.4204, longitude: -99.1895)
            ),
        ]
    }
}
